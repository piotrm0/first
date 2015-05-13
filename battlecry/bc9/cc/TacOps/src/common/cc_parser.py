import sys
import shlex
import debug_util

# debug message disables:
# parser error
# parser status

class parse_error(Exception):
    def __init__(self, value):
        self.value = value

    def __str__(self):
        return repr(self.value)

class compose_error(Exception):
    def __init__(self, value):
        self.value = value

    def __str__(self):
        return repr(self.value)

class cc_parser:
    TELNET_IAC = 0xff
    TELNET_DO  = 0xfd
    
    STATE_NONE      = 0
    STATE_RSET_HEAD = 1
    STATE_RSET_ROW  = 2

    RSET_MODE_WATCH = 0
    RSET_MODE_QUERY = 1

    WATCH_MODE_OFF  = 0
    WATCH_MODE_ON   = 1
    WATCH_TYPE_ENV  = 0
    WATCH_TYPE_RSET = 1
    
    def __init__(self):
        self.state = cc_parser.STATE_NONE

        self.query = None

        self.rset_rows = []
        self.rset_head = []
        self.rset_mode = None
        self.rset_name = None
        self.rset_msg  = None
        self.rset_num_rows = 0
        self.rset_num_cols = 0

        self.delim = "\n"

        self.notify = {}

        self.handle_state = [self.parse_root,
                             self.parse_rset_head,
                             self.parse_rset_row]

        self.handle_root = {'ENV'    : self.parse_env,
                            'OK'     : self.parse_ok,
                            'PING'   : self.parse_ping,
                            'NICK'   : self.parse_nick,
                            'QUERY'  : self.parse_query,
                            'SQL'    : self.parse_sql,
                            'NOTICE' : self.parse_notice,
                            'TRAN'   : self.parse_tran}

        self.handle_env = None
        
        return

    def cant_handle(func, line):
        debug_util.d_print("parser error", "%s: cannot handle [%s] [%s]" % (func, line, line.encode('hex_codec')))
        #    raise parse_error("%s: cannot handle [%s] [%s]" % (func, line, line.encode('hex_codec')))
    cant_handle = staticmethod(cant_handle)

    def parse_eq(pair):
        temp = pair.rsplit('=')
        if len(temp) != 2:
            cant_handle("parse_eq", pair)
        return (temp[0], temp[1])
    parse_eq = staticmethod(parse_eq)

    def call_notify(self, key, *args, **kw):
        if self.notify.has_key(key):
            self.notify[key](*args, **kw)

    def parse(self, data):
        #        print "parsing [%s]" % (data)

        eaten = 0

        while len(data) > 0 and ord(data[0]) == cc_parser.TELNET_IAC:
            if len(data) > 1 and ord(data[1]) == cc_parser.TELNET_DO:
                if len(data) > 2:
                    data = data[3:]
                    eaten = eaten + 3
                else:
                    data = data[2:]
                    eaten = eaten + 2
            else:
                data = data[1:]
                eaten = eaten + 1

        if len(data) == 0: return eaten
        
        lines = data.split("\n");
        num_lines = 0

        if len(lines[len(lines)-1]) == 0:
            num_lines = len(lines)-1
        else:
            num_lines = len(lines)-2

        for i in range(num_lines):
            line = lines[i]
            eaten = eaten + len(line) + 1
            self.parse_line(line)
        
        return eaten

    def parse_line(self, line):
        debug_util.d_print("parser status", "parsing line [%s]" % (line))
        words = []
        try:
            words = shlex.split(line)
        except ValueError, (text):
            debug_util.d_print("parser error", "parse_line: cannot parse line (%s)" % (text))
            return []
        
        self.handle_state[self.state](line, words)

    def parse_env(self, line, words):
        (key, value) = cc_parser.parse_eq(words[1])
        self.call_notify("env", key, value)

    def parse_ok(self, line, words):
        return

    def parse_ping(self, line, words):
        self.call_notify("ping")

    def parse_nick(self, line, words):
        if len(words) == 1:
            self.call_notify("nick", name=None, sequence=None)
        if len(words) == 2:
            self.call_notify("nick", name=words[1], sequence=None)
        if len(words) == 3:
            self.call_notify("nick", name=words[1], sequence=int(words[2]))

    def parse_tran(self, line, words):
        if words[1] == "BEGIN":
            self.call_notify("query", query_result(query_result.TYPE_TRAN_BEGIN,
                                                   rset=None,
                                                   effect=None,
                                                   msg=line))
        elif words[1] == "END":
            self.call_notify("query", query_result(query_result.TYPE_TRAN_END,
                                                   rset=None,
                                                   effect=None,
                                                   msg=line))

    def parse_query(self, line, words):
        if words[1] == "affected":
            
#            self.call_notify("query", 1, effect=int(words[2]), msg=line)
            self.call_notify("query", query_result(query_result.TYPE_EFFECT,
                                                   rset=None,
                                                   effect=int(words[2]),
                                                   msg=line))
            self.state = cc_parser.STATE_NONE
            return
        
        elif words[1] == "returned":
            self.rset_head = []
            self.rset_rows = []
            self.state = cc_parser.STATE_RSET_HEAD

            self.rset_num_rows = int(words[2])
            self.rset_num_cols = int(words[4])
            self.rset_name     = None
            self.rset_mode     = cc_parser.RSET_MODE_QUERY
            self.rset_msg      = line

            temp = rset(name=words[1],
                        cc=None)

            self.query = query_result(query_result.TYPE_RSET,
                                      rset=temp,
                                      effect=None,
                                      msg=line)

    def parse_sql(self, line, words):
        if words[1] == "ERROR:":
            self.state = cc_parser.STATE_NONE
            self.call_notify("query",query_result(query_result.TYPE_ERROR,
                                                  rset=None,
                                                  effect=None,
                                                  msg=line))

    def parse_notice(self, line, words):
        self.state = cc_parser.STATE_RSET_HEAD
        self.rset_head = []
        self.rset_rows = []
        self.rset_num_rows = int(words[3])
        self.rset_num_cols = int(words[5])
        self.rset_name     = words[1]
        self.rset_mode     = cc_parser.RSET_MODE_WATCH
        self.rset_msg      = line

        temp = rset(name=words[1],
                    cc=None)
        
        self.query = query_result(query_result.TYPE_RSET,
                                  rset=temp,
                                  msg=line)
    
    def parse_root(self, line, words):
        if len(words) == 0:
            cc_parser.cant_handle("parse_root", line)
            return
            
        if not self.handle_root.has_key(words[0]):
            cc_parser.cant_handle("parse_root", line)
            return

        self.handle_root[words[0]](line, words)

    def parse_rset_head(self, line, words):
        cols = line.split("\t")

        if len(cols) != self.rset_num_cols:
            raise "expected %s columns but got %s in head" % (self.rset_num_cols, len(cols))

        self.rset_head = cols
        
        self.state = cc_parser.STATE_RSET_ROW
        
        return

    def parse_rset_row(self, line, words):
        if len(self.rset_rows) == self.rset_num_rows:
            if line != "DONE":
                raise "expected DONE after %s rows" % (len(self.rset_rows))

            temp = self.query.rset
            temp.set_data(self.rset_head, self.rset_rows)

            if self.rset_mode == cc_parser.RSET_MODE_WATCH:
                self.call_notify("rset", self.query)
            elif self.rset_mode == cc_parser.RSET_MODE_QUERY:
                self.call_notify("query", self.query)
                
            self.state = cc_parser.STATE_NONE
            return

        row = line.split("\t")

        if len(row) != self.rset_num_cols:
            raise "expected %s columns but got %s in head" % (self.rset_num_cols, len(cols))

        self.rset_rows.append(rset_row(row, self.rset_head))

    ### composition methods ###

    def compose_watch(self,
                      key,
                      status = WATCH_MODE_ON,
                      type   = WATCH_TYPE_ENV):
        ret = "WATCH "        
        if   status == cc_parser.WATCH_MODE_ON:  ret = ret + "ON "
        elif status == cc_parser.WATCH_MODE_OFF: ret = ret + "OFF "
        else: raise compose_error("unknown WATCH_MODE %s" % (status))
        if   type == cc_parser.WATCH_TYPE_ENV:  ret = ret + "ENV "
        elif type == cc_parser.WATCH_TYPE_RSET: ret = ret + "RSET "
        else: raise compose_error("unknown WATCH_TYPE %s" % (type))
        ret = ret + "%s%s" % (key, self.delim)
        return ret
    
    def compose_nick(self,
                     nick,
                     sequence=None):
        ret = "NICK %s" % (nick)
        if not sequence is None:
            ret = ret + " %s" % (sequence)
        ret = ret + self.delim
        return ret

    def compose_query(self, query):
        return query + self.delim

    def compose_command(self, cmd):
        return cmd + self.delim

class rset_row:
    def __init__(self, row, head):
        self.iter_index = 0
        self.data = []
        self.index_by_name = {}
        self.fill(row, head)

    def get_index(self, key):
        if isinstance(key, str):
            return self.index_by_name[key]
        elif isinstance(key, int):
            return key

    def __len__(self):
        return len(self.data)

    def __iter__(self):
        self.iter_index = 0
        return self

    def next(self):
        if self.iter_index == len(self.data):
            raise StopIteration()
        else:
            self.iter_index = self.iter_index + 1
            return self.data[self.iter_index-1]

    def __getitem__(self, key):
        return self.data[self.get_index(key)]

    def __setitem__(self, key, value):
        self.data[self.get_index(key)] = value

    def __delitem__(self, key):
        del self.data[self.get_index(key)]

    def __getslice__(self, low, high):
        return self.data[self.get_index(low):self.get_index(high)]

    def __setslice__(self, low, high, seq):
        self.data[self.get_index(low):self.get_index(high)] = seq

    def __delslice__(self, low, high):
        del self.data[self.get_index(low):self.get_index(high)]

    def __repr__(self):
        return self.__str__()
    
    def __str__(self):
        return "<rset row %s>" % (self.data)

    def fill(self, row, head):
        self.data = row
        for i in range(len(head)):
            self.index_by_name[head[i]] = i

class rset:
    def __init__(self, name=None, cc=None):
        self.iter_row = 0
        self.fields = []
        self.rows = []
        self.name = name
        self.cc = cc

        self.index_by_name = {}

        self.callbacks = []

    def __len__(self):
        return len(self.rows)

    def __iter__(self):
        self.iter_row = 0
        return self

    def next(self):
        if self.iter_row == len(self.rows):
            raise StopIteration()
        else:
            self.iter_row = self.iter_row + 1
            return self.rows[self.iter_row-1]

    def get_index(self, key):
        return key

    def __getitem__(self, key):
        return self.rows[self.get_index(key)]

    def __setitem__(self, key, value):
        self.rows[self.get_index(key)] = value

    def __delitem__(self, key):
        del self.rows[self.get_index(key)]

    def __getslice__(self, low, high):
        return self.rows[self.get_index(low):self.get_index(high)]

    def __setslice__(self, low, high, seq):
        self.rows[self.get_index(low):self.get_index(high)] = seq

    def __delslice__(self, low, high):
        del self.rows[self.get_index(low):self.get_index(high)]

    def __repr__(self):
        return self.__str__()

    def __str__(self):
        return "<rset %s with %s rows %s columns>" % (self.name, len(self.rows), len(self.fields))
    
    def add(self, row):
        self.rows.append(row)

    def send_watch(self):
        if len(self.callbacks) != 0:
            self.cc.net.send(self.cc.parser.compose_watch(self.name,
                                                          status = cc_parser.WATCH_MODE_ON,
                                                          type   = cc_parser.WATCH_TYPE_RSET))
    def send_unwatch(self):
        if len(self.callbacks) == 0:
            self.cc.net.send(self.cc.parser.compose_watch(self.name,
                                                          status = cc_parser.WATCH_MODE_OFF,
                                                          type   = cc_parser.WATCH_TYPE_RSET))

    def watch(self, callback):
        watch_id = self.new_id()
        self.callbacks[watch_id] = callback

        if len(self.callbacks) == 1:
            self.send_watch()

        return watch_id

    def unwatch(self, watch_id):
        if ((len(self.callbacks) <= watch_id) or
            (self.callbacks[watch_id] is None)):
            return
        self.callbacks[watch_id] = None

        i = watch_id
        while ((i >= 0) and
               (self.callbacks[i] == None)):
            self.callbacks.pop(i)
            i = i - 1

        if len(self.callbacks) == 0:
            self.send_unwatch()
            
    def new_id(self):
        for i in range(len(self.callbacks)):
            if self.callbacks[i] is None:
                return i
        self.callbacks.append(None)
        return len(self.callbacks)-1

    def set_data(self, head, rows):
        self.fields = head
        self.rows = []

        for i in range(len(head)):
            self.index_by_name[head[i]] = i

        for row in rows:
            self.add(row)

        for i in range(len(self.callbacks)):
            if not self.callbacks[i] is None:
                self.callbacks[i](self)

class env:
    def __init__(self, key, cc):
        self.key       = key
        self.old_value = None
        self.value     = None
        self.callbacks = []
        self.cc        = cc

    def send_watch(self):
        if len(self.callbacks) != 0:
            self.cc.net.send(self.cc.parser.compose_watch(self.key,
                                                          status = cc_parser.WATCH_MODE_ON,
                                                          type   = cc_parser.WATCH_TYPE_ENV))
    def send_unwatch(self):
        if len(self.callbacks) == 0:
            self.cc.net.send(self.cc.parser.compose_watch(self.key,
                                                          status = cc_parser.WATCH_MODE_OFF,
                                                          type   = cc_parser.WATCH_TYPE_ENV))

    def watch(self, callback, args, kw):
        watch_id = self.new_id()
        self.callbacks[watch_id] = [callback, args, kw]

        if len(self.callbacks) == 1:
            self.send_watch()

        return watch_id

    def unwatch(self, watch_id):
        if ((len(self.callbacks) <= watch_id) or
            (self.callbacks[watch_id] is None)):
            return
        self.callbacks[watch_id] = None

        i = watch_id
        while ((i >= 0) and
               (self.callbacks[i] == None)):
            self.callbacks.pop(i)
            i = i - 1

        if len(self.callbacks) == 0:
            self.send_unwatch()
            
    def new_id(self):
        for i in range(len(self.callbacks)):
            if self.callbacks[i] is None:
                return i
        self.callbacks.append(None)
        return len(self.callbacks)-1

    def set_value(self, value):
        if value == self.value:
            return
        for i in range(len(self.callbacks)):
            if not self.callbacks[i] is None:
                self.callbacks[i][0](self.key, self.value, value, *self.callbacks[i][1], **self.callbacks[i][2])
        self.old_value = self.value
        self.value = value

class query_result:
    TYPE_ERROR      = 0
    TYPE_RSET       = 1
    TYPE_EFFECT     = 2
    TYPE_TRAN_BEGIN = 3
    TYPE_TRAN_END   = 4

    type_name = ['TYPE_ERROR', 'TYPE_RSET', 'TYPE_EFFECT', 'TYPE_TRANS_BEGIN', 'TYPE_TRANS_END']
    
    def __init__(self, type=0, rset=None, effect=None, msg=None):
        self.type   = type
        self.rset   = rset
        self.effect = effect
        self.msg    = msg

    def __repr__(self):
        return self.__str__()

    def __str__(self):
        return "<query_result (%s) \"%s\" with effect %s rset %s>" % (self.type_name[self.type], self.msg, self.effect, self.rset)
