from net_client import net_client
from cc_parser  import *

class cc_client:
    def __init__(self, nick = None):
        self.net    = net_client()
        self.parser = cc_parser()
        
        self.sequence = 0
        self.nick     = nick

        self.net.notify['data']       = self.parser.parse
        self.net.notify['connect']    = self.handle_connect
        self.net.notify['disconnect'] = self.handle_disconnect

        self.parser.notify['env']   = self.process_env
        self.parser.notify['rset']  = self.process_rset
        self.parser.notify['ping']  = self.process_ping
        self.parser.notify['query'] = self.process_query

        self.notify = {}

        self.env  = {}
        self.rset = {}
        self.req  = []

    def call_notify(self, key, *args, **kw):
        if self.notify.has_key(key):
            self.notify[key](*args, **kw)

    def connect(self, remote_host, remote_port=7070):
        self.net.remote_host = remote_host
        self.net.remote_port = remote_port
        self.sequence = self.sequence + 1
        self.net.connect()

    def handle_connect(self, *args, **kw):
        self.send_greet()
        self.env_send_watches()
        self.rset_send_watches()
        self.send_querys()
        self.call_notify("connect")

    def handle_disconnect(self, *args, **kw):
        self.sequence = self.sequence + 1
        self.call_notify("disconnect")

    def send_greet(self):
        if not self.nick is None:
            self.net.send(self.parser.compose_nick(self.nick, self.sequence))

    def env_send_watches(self):
        for key in self.env:
            self.env[key].send_watch()

    def rset_send_watches(self):
        for name in self.rset:
            self.rset[name].send_watch()            

    def env_watch(self, key, callback, *args, **kw):
        if not self.env.has_key(key):
            self.env[key] = env(key=key, cc=self)
        return self.env[key].watch(callback, args, kw)

    def env_unwatch(self, key, watch_id):
        if not self.env.has_key(key):
            return
        return self.env[key].unwatch(watch_id)

    def process_env(self, key, value):
        if not self.env.has_key(key):
            self.env[key] = env(key=key, cc=self.net)
        self.env[key].set_value(value)

    def rset_watch(self, name, callback):
        if not self.rset.has_key(name):
            self.rset[name] = rset(name=name, cc=self)
        return self.rset[name].watch(callback)

    def rset_unwatch(self, name, watch_id):
        if not self.rset.has_key(name):
            return
        return self.rset[name].unwatch(watch_id)

    def process_rset(self, query):
        rset = query.rset
        name = rset.name
        if not self.rset.has_key(name):
            self.rset[name] = rset(key=name, cc=self)
        self.rset[name].set_data(rset.fields, rset.rows)

    def process_ping(self):
        self.net.send(self.parser.compose_ping())

    def process_query(self, temp_res):
        if len(self.req) == 0:
            self.call_notify("query", temp_res)
            return

        row = self.req[0]
        row[3] = row[3] + 1
        
        (query, callback, results, received, built, args, kw) = row

        built.append(temp_res)
        
        if results == received:
            debug_util.d_print("cc query", "calling callback %s for query [%s] with args %s, kw %s" % (callback, query, args, kw))
            self.req = self.req[1:]
            callback(built, *args, **kw)
    
    def do_query(self, query, callback, results, *args, **kw):
        self.req.append([query, callback, results, 0, [], args, kw])
        if self.net.connected:
            self.net.send(self.parser.compose_query(query))

    def query(self, query, callback, *args, **kw):
        if isinstance(query, str):
            self.do_query(query, callback, 1, *args, **kw)
        elif ((isinstance (query, list)) or
              (isinstance (query, tuple))):
            query_str = self.parser.delim.join(query)
            self.do_query(query_str, callback, len(query), *args, **kw)

    def send_querys(self):
        for temp in self.req:
            self.net.send(self.parser.compose_query(temp[0]))

    def command(self, cmd):
        if isinstance(cmd, str):
            self.net.send(self.parser.compose_command(cmd))
        elif ((isinstance (cmd, list)) or
              (isinstance (cmd, tuple))):
            for c in cmd:
                self.net.send(self.parser.compose_command(c))

