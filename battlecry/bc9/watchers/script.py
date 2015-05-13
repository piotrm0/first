from cc_client import cc_client
import sys
import time
import select
import dircache
import os

import subprocess

import config

class script:
    def __init__(self, name, dir=None, scripts=None):
        if dir is None:
            dir = config.SCRIPT_DIR

        self.scripts = scripts
            
        self.name     = name
        self.dir      = dir
        self.filename     = os.path.join(self.dir, self.name + ".sh")
        self.filename_log = os.path.join(self.dir, self.name + ".log")

        self.last_run        = 0
        self.last_run_string = "never"
        self.since_last      = -1

        self.last_ret = 0

        self.proc = None
        self.out  = None

        self.log  = open(self.filename_log, "a")

        self.rate = 0

        self.running = False

    def time_since_last(self):
        if self.last_run == 0:
            self.since_last = 9999
            return self.since_last

        self.since_last = int(time.time()) - self.last_run

        return self.since_last

    def run(self):
        print "running [%s]" % (self.name)

        self.last_run        = int(time.time())
        self.last_run_string = time.strftime("%H:%M:%S", time.localtime())
        self.time_since_last()

        self.log.write("--- starting [%s] at [%s] ---\n" % (self.name, self.last_run_string))
        self.log.flush()

        self.proc = subprocess.Popen(self.filename,
                                     stdout = subprocess.PIPE,
                                     stderr = self.log)

        self.out = self.proc.stdout

        self.running = True

        self.scripts.update_conf()

        return self.out

    def poll(self):
        if not self.running:
            print "not running"
            return None

        self.proc.poll()
        
        print "checking [%s] (%s,%s)" % (self.name, self.proc.pid, self.proc.returncode)
        
        if self.out is not None:
            data = self.out.read()
            self.log.write(data)

        if self.proc.returncode is None:
            #print "no return code"
            return None

        self.running = False
        self.out     = None
        self.err     = None
        self.last_ret = self.proc.returncode

        self.log.write("--- stopped [%s] at [%s] with return [%s] ---\n" % (self.name, time.asctime(), self.last_ret))
        self.log.flush()

        print "script [%s] return [%d]" % (self.name, self.last_ret)

        self.scripts.update_conf()
        
        return self.last_ret

    def __str__(self):
        return "<stript [%s] last run [%s]>" % (self.name, self.last_run_string)

    def __repr__(self):
        return self.__str__()

class scripts:
    def __init__(self, host=config.HOST_CCENTER, port=config.PORT_CCENTER):
        self.cc = cc_client()
        self.cc.notify['connect']    = self.connected
        self.cc.notify['disconnect'] = self.disconnected

        self.host = host
        self.port = port

        self.scripts = dict()

        self.index_scripts()

        self.outs    = dict()

        self.args    = dict()

        self.conf    = []

        self.last_update = time.time()

        self.cc.env_watch("script_conf", self.handle_script_conf)
        self.cc.env_watch("script_arg1", self.handle_script_arg)
        self.cc.env_watch("script_arg2", self.handle_script_arg)
        self.cc.env_watch("script_arg3", self.handle_script_arg)
        self.cc.env_watch("script_op",   self.handle_script_op)
        self.cc.env_watch("script_run",  self.handle_script_run)

        self.connect()

    def update_conf(self):
        self.create_conf()
        conf_string = "+".join(self.conf)
        self.cc.command("ENV script_conf=%s" % (conf_string))

        self.last_update = time.time()

    def create_conf(self):
        temp = self.scripts.keys()
        temp.sort()

        ret = []

        for script_name in temp:
            script = self.scripts[script_name]
            ret.append(script_name)
            ret.append(str(script.running))
            ret.append(str(script.rate))
            ret.append(str(script.last_ret))
            ret.append(str(script.last_run))
            ret.append(script.last_run_string)
            ret.append(str(script.since_last))

        self.conf = ret

        return ret

    def check_rates(self):
        for script_name in self.scripts:
            script = self.scripts[script_name]

            if 0 == script.rate: continue
            if script.running  : continue

            since_last = script.time_since_last()

            if since_last == -1 or since_last > script.rate:
                self.outs[script.run()] = script

        if time.time() - self.last_update > 5:
            self.update_conf()

    def connect(self):
        self.cc.connect(self.host, self.port)

    def handle_script_conf(self, key, old, new):
        cmd = new.split("+")

        i = 0

        while len(cmd) > i+6:
            script_name            = cmd[i]
            
            try: script_running    = bool(cmd[i+1])
            except: script_running = False
            
            try: script_rate       = int(cmd[i+2])
            except: script_rate    = 0
            
            try: script_ret        = int(cmd[i+3])
            except: script_ret     = 0
            
            try: script_last       = int(cmd[i+4])
            except: script_last    = -1
            
            script_lasts           = cmd[i+5]
            
            try: script_since      = int(cmd[i+6])
            except: script_since   = 0.0
            
            i += 7

            if not self.scripts.has_key(script_name):
                continue

            script = self.scripts[script_name]

            if script_rate == 0 or script_rate > 30:
                script.rate = script_rate

            script.last_ret = script_ret

            script.last_run        = script_last
            script.last_run_string = script_lasts
            script.time_since_last()

    def handle_script_run(self, key, old, new):
        if new == "none":
            pass
        elif self.scripts.has_key(new):
            self.run_script(self.scripts[new])
        else:
            print "unknown script [%s]" % (new)

    def handle_script_arg(self, key, old, new):
        self.args[key] = new

    def handle_script_op(self, key, old, new):
        if new == "none":
            return
        elif new == "set_rate":
            self.set_rate()
            self.cc.command("ENV script_op=none")
        elif new == "index":
            self.index_scripts()
            self.cc.command("ENV script_op=none")
        else:
            print "unknown operation [%s]" % (new)

    def set_rate(self):
        if not self.args.has_key("script_arg1"):
            return
        script_name = self.args['script_arg1']
        if not self.args.has_key("script_arg2"):
            return
        try:    script_rate = int(self.args['script_arg2'])
        except: script_rate = 0
        if not self.scripts.has_key(script_name):
            return
        
        print "setting rate of %s to %d" % (script_name, script_rate)
        
        script = self.scripts[script_name]
        script.rate = script_rate

    def connected(self):
        print "connected"

    def disconnected(self):
        print "disconnected, reconnecting in 3"
        time.sleep(3)
        self.connect()

    def run_script(self, script):
        if script.running:
            return
        
        out = script.run()

        self.outs[out] = script

        self.cc.command("ENV script_run=none")

    def check_run(self, out):
        if not self.outs.has_key(out):
            return

        script = self.outs[out]

        res = script.poll()

        if res is None:
            return

        del self.outs[out]

    def index_scripts(self):
        files = dircache.listdir(config.SCRIPT_DIR)
        for file in files:
            (f, e) = os.path.splitext(file)
            if e != ".sh": continue

            if not self.scripts.has_key(f):
                self.scripts[f] = script(f, scripts=self)
                
            print self.scripts[f]
            
    def loop(self):
        while(1):
            rh = self.outs.keys() + [self.cc.net.sock]
            wh = []
            if (self.cc.net.need_write()):
                wh.append(self.cc.net.sock)
            (reads, writes, whatever) = select.select(rh, wh, [], 1)
            for r in reads:
                if (r == self.cc.net.sock):
                    self.cc.net.sock_recv()
                else:
                    self.check_run(r)
            for r in writes:
                if (r == self.cc.net.sock):
                    self.cc.net.sock_send()

            self.check_rates()
            time.sleep(1)

s = scripts()
s.loop()
