# cc lite
# pm, april 2008

from db import dbm, result

import signal
import thread


import socket
import select
import string
import sys
import os
import re
import csv
import shlex

import xml.dom.minidom
from xml.dom.minidom import Document, Node

VERSION = "0.1";
NAME    = "ccl " + VERSION

PORT = 7070
DLEN = 1024

CLIENT_TYPE_NONE    = 0
CLIENT_TYPE_DISPLAY = 1
CLIENT_TYPE_CONTROL = 2

class server:
    def __init__(self, port):
        self.port = port;
#        self.hostname = str(socket.INADDR_ANY)
        self.hostname = ""
        self.address = (self.hostname, self.port)
        self.clients = []
        self.serve = serve()
        return None;
        
    def start(self):
        print "serve\t: creating server at [%s:%s]" % (str(self.address[0]), str(self.address[1]))
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1) 
        self.s.bind(self.address)
        self.s.listen(5)
        while (1):
            need_read  = self.need_read()
            need_write = self.need_write()
            #                print "select [%d] reads and [%d] writes" % (len(need_read), len(need_write))
            (rlist, wlist, xlist) = select.select(need_read,
                                                  need_write,
                                                  [],
                                                  0.01)
            for s in rlist:
                #                    print "got read from %s" % s
                if (s == self.s):
                    self.make_client()
                else:
                    client = self.s2c(s)
                    self.handle_data(client)

            for s in wlist:
                client = self.s2c(s)
                self.feed(client)

    def feed(self, client):
        if client is None:
            return
        
        out = client.qout.next(DLEN)
        print "sending [%s] %s bytes" % (out, len(out))
        client.socket.send(out)
        return len(out)

    def s2c(self, s):
        for c in self.clients:
            if (c == None): continue
            if (c.socket == s): return c
        return None

    def make_client(self):
        (c_socket, c_address) = self.s.accept()
        new_id = self.new_id()
        new_client = client(c_socket,c_address, self.new_id())
        self.clients[new_id] = new_client
        self.handle_connect(new_client)
        return new_client
            
    def handle_connect(self, client):
        print "serve\t: new connection from %s:%s" % client.address
        return self

    def handle_data(self, client):
        # print "receiving data from cid %d" % (client.id)
        data = client.socket.recv(DLEN)
        if data == '':
            self.handle_disconnect(client)
            return None
        # print "adding [%s]" % (data)
        client.qin.add(data)
        line = client.qin.next()
        while(line != None and line != ""):
            # print "processing [%s]" % (line)
            send_to_client = lambda data: self.send_to_client(client, data)
            send_to_rest   = lambda data: self.send_to_rest(client, data)
            self.serve.process(line, client, sender(send_to_client, send_to_rest, self.send_to_all))
            line = client.qin.next()
                        
        return self

    def send_to_client(self, client, data):
        if (data.__class__ == str):
            client.qout.add(data)
        elif (data.__class__ == list):
            client.qout.add_multiple(data)
        else:
            print "unknown data type %s" % (str(data.__class__))
            sys.exit(0)

        return None
    
    def send_to_all(self, data):
        for client in self.clients:
            if (client == None): continue
            client.qout.add(data)
        return None

    def send_to_rest(self, not_client, data):
        for client in self.clients:
            if (client == not_client): continue
            if (client == None): continue
            client.qout.add(data)
        return None

    def handle_disconnect(self, client):
        print "serve\t: client disconnected %s:%s" % client.address
        self.clients[client.id] = None
        return self

    def new_id(self):
        i = 0;
        while ((i < len(self.clients)) and
               (self.clients[i] != None)):
            i = i + 1
        if (i >= len(self.clients)):
            self.clients.append(None)
        return i

    def need_write(self):
        ret = []
        for c in self.clients:
            if (c == None): continue
            if (not c.qout.is_empty()):
                ret.append(c.socket)
        return ret
    
    def need_read(self):
        ret = []
        for c in self.clients:
            if (c == None): continue
            ret.append(c.socket)
        ret.append(self.need_connect())
        return ret

    def need_connect(self):
        return self.s

class client:
    def __init__(self, socket, address, id):
#        print "created new client at id %d" % (id)
        self.id = id
        self.socket = socket
        self.address = address
        self.qin  = rqueue()
        self.qout = wqueue()
        self.type = CLIENT_TYPE_NONE;
        return None

class queue:
    def __init__(self):
        self.fragment = ''
        self.packets = []
        self.lock = thread.allocate_lock()
        return None
    
    def is_empty(self):
#        print "# packets = %s / len fragment = %s" % (len(self.packets), len(self.fragment))
        return (len(self.packets) + len(self.fragment) == 0)

class wqueue(queue):
    def next(self, mlen):
        self.lock.acquire()
        
        ret = ''
        olen = len(ret)
        ret = ret + self.fragment[0:mlen-olen]
        self.fragment = self.fragment[mlen-olen:]
        
        while ((len(ret) < mlen) and
               ((len(self.fragment) > 0) or
                (len(self.packets) > 0))):
            
            if (len(self.fragment) == 0):
#                print "getting new packet"
                self.fragment = self.packets.pop(0)
#            else:
#                print "not getting new packet"

            olen = len(ret)
                
            ret = ret + self.fragment[0:mlen-olen]
            self.fragment = self.fragment[mlen-olen:]

        self.lock.release()
        
        return ret

    def add_multiple(self, packets):
        self.lock.acquire()

        for packet in packets:
            self.packets.append(packet + "\0")

        ret = len(self.packets)

        self.lock.release()

        #thread.interrupt_main()

        return ret

    def add(self, packet):
        self.lock.acquire()
        
        self.packets.append(packet + "\0")
        ret = len(self.packets)

        self.lock.release()

        #thread.interrupt_main()
        
        return ret

class rqueue(queue):
    def next(self):
        self.lock.acquire()

        ret = None

        if (len(self.packets) > 0):
            ret = self.packets.pop(0)

        self.lock.release()

        return ret

    def add(self, fragment):
        self.lock.acquire()

#        self.fragment = re.sub("\0", "", self.fragment);
        self.fragment = self.fragment + fragment
        added = 0
        while(self.fragment.count("\0") != 0):
            (line, self.fragment) = self.fragment.split("\0", 1)
            self.packets.append(line)
            added = added + 1

        self.lock.release()

        return added

class sender:
    def __init__(self, client, rest, all):
        self.client = client
        self.ret    = rest
        self.all    = all

class syntax(object):
    def rset_row(row):
        return "\t".join(map(syntax.string, row))
    
    def string(o):
        name = o.__class__.__name__
        if (name == "int"):
            return str(o)
        if (name == "float"):
            return str(o)
        if (name == "bool"):
            return str(o)
        if (name == "str"):
            return syntax.quote(o)
        if (name == "NoneType"):
            return "NULL"
        print "unkown type %s" % (name)
        sys.exit(0)

    def quote(s):
        # return "\\'".join("'" + p + "'" for p in s.split("'"))
        s = s.replace('\t', '\\\t"')
        s = s.replace('\\', '\\\\')
        return s

    quote    = staticmethod(quote)
    string   = staticmethod(string)
    rset_row = staticmethod(rset_row)

class serve:
    def __init__(self):
        self.mods  = {}

        self.dbm = dbm()
        self.dbm.init_all()
        
        self.funcs = {'select' : self.func_select,
                      'nick'   : self.func_nick,
                      'watch'  : self.func_watch,
                      }
        
        return None

    def process(self, line, client, s):
        parts = line.split(" ")
        #        parts = shlex.split(line)
        cmd = parts[0].lower()
        #opts = parts[1:]
        if not self.funcs.has_key(cmd):
            s.client("!err \"%s: no such command\"" % (cmd))
            return None
        return self.funcs[cmd](cmd, line, client, s)

    def func_select(self, cmd, line, client, s):
        # QUERY returned x rows y
        # colname, colname, colname, colname
        # data, data, data, data
        # ...
        
        # QUERY affected
        # QUERY error
        thread.start_new_thread(self.func_select_thread, (cmd, line, client, s))

    def func_select_thread(self, cmd, line, client, s):
        print "selecting [%s]" % (line)

        res  = self.dbm.query(line)

        if (res.flag & result.FAIL):
            print "fail"
            s.client("SQL error")

        else:
            packets = []

            packets.append("QUERY returned %d rows %d cols" % (res.num_rows, res.num_cols))
            packets.append(syntax.rset_row(map(lambda x: x[0], res.desc)))
            for row in res.rows:
                packets.append(syntax.rset_row(row))
            packets.append("DONE")
            s.client(packets)

    def func_nick(self, cmd, line, client, s):
        pass

    def func_watch(self, cmd, line, client, s):
        # watch env x
        # watch rset x
        # watch off env x
        # watch off rset x
        pass

#    def func_type(self, opts, client, s):
#        if (len(opts) < 1):
#            s.client("!err \"no client type provided\"")
#            return
#        
#        client.type = opts[0]
#        return None
#
#    def func_exit(self, opts, client, s):
#        sr.all("!msg \"server exiting\"")
#        return None
#
#    def func_hello(self, opts, client, s):
#        s.client("!hello")
#        s.client("!msg \"" + NAME + "\"")
#
#    def func_list(self, opts, client, send_to_client, send_to_rest, send_to_all):
#        return None
#
#    def func_mod(self, opts, client, send_to_client, send_to_rest, send_to_all):
#        if (len(opts) < 1):
#            send_to_client("!err \"no mod key provided\"");
#            return
#        if (len(opts) < 2):
#            send_to_client("!err \"no mod data provided\"");
#            return
#
#        key = opts.pop(0);
#        self.mods[key] = quote_list(opts);
##        self.mods[key] = opts;
##        print "new mod:"
##        print self.mods[key]
#        send_to_rest("!mod %s %s" % (key, " ".join(self.mods[key])))
#        return
#
#    def func_smod(self, opts, client, send_to_client, send_to_rest, send_to_all):
#        if (len(opts) < 1):
#            send_to_client("!err \"no mod key provided\"");
#            return
#        if (len(opts) < 2):
#            send_to_client("!err \"no mod data provided\"");
#            return
#
#        key = opts.pop(0);
#        self.mods[key] = quote_list(opts);
##        self.mods[key] = opts;
##        print "new mod:"
##        print self.mods[key]
#        send_to_all("!mod %s %s" % (key, " ".join(self.mods[key])))
#        return
#
#    def func_show_mods(self, opts, client, send_to_client, send_to_rest, send_to_all):
#        send_to_client("!msg \"showing you mods\"")
#        keys = self.mods.keys();
#        keys.sort()
#        for key in keys:
#            data = " ".join(self.mods[key])
#            send_to_client("!msg \"%s: %s\"" % (key, data))
#        return
#
#    def func_get_mods(self, opts, client, send_to_client, send_to_rest, send_to_all):
#        send_to_client("!msg \"sending you mods\"")
#        keys = self.mods.keys();
#        keys.sort()
#        for key in keys:
#            data = " ".join(self.mods[key])
#            send_to_client("!mod %s %s" % (key, data))
#        return

def quote_list(list):
    ret = [];
    for e in list:
        if (re.search(" ", e)):
            ret.append("\"" + e + "\"");
        else:
            ret.append(e);
    return ret;

#test = qsets(QSET_PATH)
#test.make_doc()
#print test.xml
#sys.exit()
                
s = server(PORT)
s.start()

