# this one is for "press your luck" for battlecry 9
# ~piotrm 05-01-2008

import socket
import select
import string
import sys
import os
import re
import csv
import shlex
import errno

import xml.dom.minidom
from xml.dom.minidom import Document, Node

VERSION = "0.2";
NAME    = "game server " + VERSION

PORT = 7000
#PORT = 3389
DLEN = 1024
QSET_DIR = "q"
QSET_FILE = "q.csv"
QSET_PATH = QSET_DIR + "/" + QSET_FILE

CLIENT_TYPE_VIEW    = "view";
CLIENT_TYPE_CONTROL = "control";

MSG = {}
MSG[CLIENT_TYPE_VIEW]    = "Have a good game!";
MSG[CLIENT_TYPE_CONTROL] = "Welcome!";

class server:
    def __init__(self, port):
        self.port = port;
        self.hostname = ""
        self.address = (self.hostname, self.port)
        self.clients = []
        self.game = game()
        return None;
        
    def start(self):
        print "creating server at %s:%s" % (str(self.address[0]), str(self.address[1]))
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1) 
        self.s.bind(self.address)
        self.s.listen(5)
        while (1):
            need_read = self.need_read()
            need_write = self.need_write()
#            print "select [%d] reads and [%d] writes" % (len(need_read), len(need_write))
            (rlist, wlist, xlist) = select.select(need_read,
                                                  need_write,
                                                  [])
            for s in rlist:
#                print "got read from %s" % s
                if (s == self.s):
                    self.make_client()
                else:
                    client = self.s2c(s)
                    self.handle_data(client)

            for s in wlist:
                client = self.s2c(s)
                self.feed(client)

    def feed(self, client):
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
        print "new connection from %s:%s" % client.address
        return self

    def handle_data(self, client):
        #        print "receiving data from cid %d" % (client.id)
        try:
            data = client.socket.recv(DLEN)
        except socket.error, (value, message):
            print (value, message)
            if ((errno.EAGAIN == value) or
                (errno.EWOULDBLOCK == value)): # 35 = EAGAIN = resource temporarily unavailable
                data = ""
            elif errno.ECONNRESET == value: # 54 = ECONNRESET = connection reset by peer
                self.handle_disconnected(client)
                return None
            else:
                self.handle_disconnected(client)
                return None
            
        if data == '':
            self.handle_disconnect(client)
            return None
#        print "adding [%s]" % (data)
        client.qin.add(data)
        line = client.qin.next()
        while(line != None and line != ""):
#            print "processing [%s] first is [%s]" % (line, line[0])
            print "processing [%s]" % (line)
            if (line[0] == "!"):
                send_to_client = lambda data: self.send_to_client(client, data)
                send_to_rest = lambda data: self.send_to_rest(client, data)
                line = line[1:]
                self.game.process(line, client, send_to_client, send_to_rest, self.send_to_all)
            else:
                print "non-command line [%s]" % (line)
                
            line = client.qin.next()
                        
        return self

    def send_to_client(self, client, data):
        client.qout.add(data)
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
        print "client disconnected %s:%s" % client.address
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
        self.qin = rqueue()
        self.qout = wqueue()
        self.type = CLIENT_TYPE_VIEW;
        return None

class queue:
    def __init__(self):
        self.fragment = ''
        self.packets = []
        return None
    
    def is_empty(self):
#        print "# packets = %s / len fragment = %s" % (len(self.packets), len(self.fragment))
        return (len(self.packets) + len(self.fragment) == 0)

class wqueue(queue):
    def next(self, mlen):
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
            
        return ret

    def add(self, packet):
        self.packets.append(packet + "\0")
        return len(self.packets)

class rqueue(queue):
    def next(self):
        if (len(self.packets) > 0):
            return self.packets.pop(0)
        return None

    def add(self, fragment):
        self.fragment = re.sub("\0", "", self.fragment);
        self.fragment = self.fragment + fragment
        added = 0
        while(self.fragment.count("\n") != 0):
            (line, self.fragment) = self.fragment.split("\n", 1)
            self.packets.append(line)
            added = added + 1
        return added

#
# questions and sets, etc..
#

class question:
    def __init__(self, id=0, question=None, answer=None, correct=0):
        self.id      = id
        self.question = question
        self.answers  = answer
        self.correct  = correct

    def read_from_data(self, data):
        self.question = data[0]
        self.answers  = data[1:4]
        self.correct  = int(data[4])

    def render(self):
        return ("question: (%s) a(%s) c(%d)" % (self.question, ",".join(self.answers), self.correct))

    def to_doc(self, doc):
        node = doc.createElement("node")
        
        node.setAttribute("type",     "question")
        node.setAttribute("label",    str(self.id) + ": " + self.question)
        node.setAttribute("id",       str(self.id))
        node.setAttribute("question", self.question)
        node.setAttribute("correct",  str(self.correct))
        node.setAttribute("ans1",     self.answers[0])
        node.setAttribute("ans2",     self.answers[1])
        node.setAttribute("ans3",     self.answers[2])

        return node

class questions:
    def __init__(self, filename):
        self.questions = []
        self.doc = None
        self.xml = None
        if (filename):
            self.read_from_file(filename)
        return None
    
    def read_from_file(self, filename):
        self.questions = []
        return self.add_from_file(filename)

    def add_from_file(self, filename):
        reader = csv.reader(file(filename), dialect='excel')

        head = reader.next()

        id = 1
        for row in reader:
            q = question(id=id)
            q.read_from_data(row)
            self.questions.append(q)
            id += 1

    def render(self):
        ret = "questions:\n"
        for q in self.questions:
            ret += "  " + q.render() + "\n"
        return ret

    def to_doc(self):
        doc = Document()
        root = doc.createElement("node")
        root.setAttribute("label", "questions");
        root.setAttribute("type",  "questions");
        doc.appendChild(root)

        for q in self.questions:
            root.appendChild(q.to_doc(doc))

        return doc
        
    def make_doc(self):
        self.doc = self.to_doc()
        self.xml = self.doc.toxml()

class game:
    def __init__(self):
        self.mods      = {}
        self.questions = None
        
        self.funcs = {'hello' : self.func_hello,
                      
                      'type'  : self.func_type,
                      
                      'get_sets' : self.func_get_sets,
                      'reload'   : self.func_reload,
                      
                      'mod'       : self.func_mod,
                      'smod'      : self.func_smod,
                      'show_mods' : self.func_show_mods,
                      'get_mods'  : self.func_get_mods,

                      'exit' : self.func_exit,}
        
        self.load_questions()
        return None

    def process(self, line, client, send_to_client, send_to_rest, send_to_all):
#        parts = line.split(" ")
        parts = shlex.split(line)
        cmd = parts[0]
        opts = parts[1:]
        cmd = cmd.lower()
        if not self.funcs.has_key(cmd):
            send_to_client("!err \"%s: no such command\"" % (cmd))
            return None
        return self.funcs[cmd](opts, client, send_to_client, send_to_rest, send_to_all)

    def load_questions(self):
        print "loading question sets"
        self.questions = questions(QSET_PATH)
        self.questions.make_doc()
        return self.questions

    def func_type(self, opts, client, send_to_client, send_to_rest, send_to_all):
        if (len(opts) < 1):
            send_to_client("!err \"no client type provided\"")
            return
        if (not MSG.has_key(opts[0])):
            send_to_client("!err \"%s: unknown client type\"" % (opts[0]))
            return
        
        client.type = opts[0]
        return None

    def func_reload(self, opts, client, send_to_client, send_to_rest, send_to_all):
        send_to_all("!msg \"reloading question sets\"")
        self.load_questions()

    def func_exit(self, opts, client, send_to_client, send_to_rest, send_to_all):
        send_to_all("!msg \"server exiting\"")
        return None

    def func_hello(self, opts, client, send_to_client, send_to_rest, send_to_all):
        send_to_client("!hello")
        send_to_client("!msg \"" + NAME + "\"")
        send_to_client("!msg \"" + MSG[client.type] + "\"")

    def func_list(self, opts, client, send_to_client, send_to_rest, send_to_all):
        return None

    def func_get_sets(self, opts, client, send_to_client, send_to_rest, send_to_all):
        send_to_client("!msg \"sending you question sets\"");
        send_to_client("!pack sets")
        send_to_client(self.questions.xml)

    def func_mod(self, opts, client, send_to_client, send_to_rest, send_to_all):
        if (len(opts) < 1):
            send_to_client("!err \"no mod key provided\"");
            return
        if (len(opts) < 2):
            send_to_client("!err \"no mod data provided\"");
            return

        key = opts.pop(0);
        self.mods[key] = quote_list(opts);
#        self.mods[key] = opts;
#        print "new mod:"
#        print self.mods[key]
        send_to_rest("!mod %s %s" % (key, " ".join(self.mods[key])))
        return

    def func_smod(self, opts, client, send_to_client, send_to_rest, send_to_all):
        if (len(opts) < 1):
            send_to_client("!err \"no mod key provided\"");
            return
        if (len(opts) < 2):
            send_to_client("!err \"no mod data provided\"");
            return

        key = opts.pop(0);
        self.mods[key] = quote_list(opts);
#        self.mods[key] = opts;
#        print "new mod:"
#        print self.mods[key]
        send_to_all("!mod %s %s" % (key, " ".join(self.mods[key])))
        return

    def func_show_mods(self, opts, client, send_to_client, send_to_rest, send_to_all):
        send_to_client("!msg \"showing you mods\"")
        keys = self.mods.keys();
        keys.sort()
        for key in keys:
            data = " ".join(self.mods[key])
            send_to_client("!msg \"%s: %s\"" % (key, data))
        return

    def func_get_mods(self, opts, client, send_to_client, send_to_rest, send_to_all):
        send_to_client("!msg \"sending you mods\"")
        keys = self.mods.keys();
        keys.sort()
        for key in keys:
            data = " ".join(self.mods[key])
            send_to_client("!mod %s %s" % (key, data))
        return

def quote_list(list):
    ret = [];
    for e in list:
        if (re.search(" ", e)):
            ret.append("\"" + e + "\"");
        else:
            ret.append(e);
    return ret;

test = questions(QSET_PATH)
#test.make_doc()
#print test.xml
#print test.render()
#sys.exit()
                
s = server(PORT)
s.start()

