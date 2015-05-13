from cc_client import cc_client
import sys
import time
import select

class clock:
    def __init__(self, host="localhost", port=7070):
        self.cc = cc_client()
        self.cc.notify['connect']    = self.connected
        self.cc.notify['disconnect'] = self.disconnected

        self.clock_started_secs = 0
        self.clock_started_time = 0
        self.clock_state = None
        self.clock_secs  = 0
        self.clock_last_secs = 0

        self.host = host
        self.port = port

        self.cc.env_watch("clock",       self.handle_clock)
        self.cc.env_watch("clock_state", self.handle_clock_state)

        self.connect()

    def connect(self):
        self.cc.connect(self.host, self.port)

    def handle_clock_state(self, key, old, new):
        #print "got clock state %s from %s" % (new, old)
        if (new == "run") and (old != "run"):
            self.start_clock()
        if (new == "stop") and (old != "stop"):
            self.stop_clock()

    def handle_clock(self, key, old, new):
        #print "got clock %s" % (new)
        if (self.clock_state == "run"):
            self.clock_secs = int(new)
        else:
            self.clock_secs = int(new)

    def update_clock(self):
        if (self.clock_state != "run"):
            pass
        else:
            temp = int(self.clock_started_secs - (time.time() - self.clock_started_time))
            if (temp != self.clock_last_secs):
                self.clock_last_secs = temp
                self.cc.command("ENV clock=%d" % (temp))
            if (temp <= 0):
                self.cc.command("ENV clock=0")
                self.cc.command("ENV clock_state=stop")
                self.stop_clock()

    def start_clock(self):
        self.clock_started_secs = self.clock_secs
        self.clock_started_time = time.time()
        self.clock_state = "run"

    def stop_clock(self):
        self.clock_state = "stop"

    def connected(self):
        print "connected"

    def disconnected(self):
        print "disconnected, reconnecting in 3"
        time.sleep(3)
        self.connect()

    def loop(self):
        while(1):
            self.update_clock()
            rh = [self.cc.net.sock]
            wh = []
            if (self.cc.net.need_write()):
                wh.append(self.cc.net.sock)
            (reads, writes, whatever) = select.select(rh, wh, [], 1)
            for r in reads:
                if (r == self.cc.net.sock):
                    self.cc.net.sock_recv()
            for r in writes:
                if (r == self.cc.net.sock):
                    self.cc.net.sock_send()

c = clock()
c.loop()
