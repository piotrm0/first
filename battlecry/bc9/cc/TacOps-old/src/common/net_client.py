import socket

class net_client:
      def __init__(self,
                   remote_host   = 'localhost',
                   remote_port   = 20,
                   pack_size     = 1024):
            
            self.remote_host   = remote_host
            self.remote_port   = remote_port
            self.pack_size     = pack_size

            self.notify = {}

            self.connected  = 0
            self.connecting = 0

            self.init()

      def init(self):
            self.buffer_in  = None
            self.buffer_out = None
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.sock.setblocking(0)

      def need_write(self):
            return ((self.connecting) or
                    (not self.buffer_out.is_empty()))

      def call_notify(self, key, *args, **kw):
            if self.notify.has_key(key):
                  return self.notify[key](*args, **kw)

      def connect(self):
            self.buffer_in  = buffer(pack_size=self.pack_size)
            self.buffer_out = buffer(pack_size=self.pack_size)
            
            print "connect: connecting to %s:%s" % (self.remote_host, self.remote_port)

            try:
                  self.sock.connect((self.remote_host, self.remote_port))
                  self.connecting = 1
            except socket.error, (value, message):  # not sure if this is right
                  if value != 36:
                        print "socket.error(%s,%s)" % (value, message)
                        self.connected = 0
                  else:
                        self.connecting = 1

      def disconnect(self):
            print "disconnected"
            
            self.connected  = 0
            self.connecting = 0

            self.buffer_in  = None
            self.buffer_out = None

            #self.sock.shutdown(socket.SHUT_RDWR)
            self.sock.close()

            self.init()

            self.call_notify("disconnect")

      def send(self, data):
            if not self.connected:
                  return
            
            self.buffer_out.add(data)
            self.call_notify("data_ready")

      def disconnected(self):
            self.connected = 0
            self.disconnect()
            #self.call_notify("disconnect")

      def sock_recv(self):
            temp = ""
            more = 1

#            print "buffer[%s]" % (self.buffer_in.content)

            while more:
#                  print "while buffer[%s]" % (temp)
                  try:
                        part = ""
                        part = self.sock.recv(self.pack_size)
                        temp = temp + part

                        if len(part) == 0:
                              self.disconnected()
                              return
                        
                  except socket.error, (value, message):
                        temp = temp + part
                        if 35 == value: # 35 = resource temporarily unavailable
                              more = 0
                        elif 54 == value: # 54 = connection reset by peer
                              self.disconnected()
                              return
                        elif 61 == value: # 61 = connection refused
                              self.disconnected()
                              return
                        else: raise

#            print "pre end buffer[%s]" % (self.buffer_in.content)

            self.buffer_in.add(temp)

#            print "post end buffer[%s]" % (self.buffer_in.content)

            processed = self.call_notify("data", self.buffer_in.take_all())
            self.buffer_in.eat(processed)

      def sock_send(self):
            if ((not self.connected) and
                (self.connecting)):
                  print "connected"
                  self.connecting = 0
                  self.connected = 1
                  self.call_notify("connect")
                  return
                  
            if self.buffer_out.is_empty():
                  return 0

            for out in self.buffer_out:
                  print "sending %s" % (out),
                  self.sock.send(out)

class buffer:
      def __init__(self, pack_size = 1024):
            self.content   = ""
            self.pack_size = pack_size

      def __iter__(self):
            return self

      def add(self, data):
            self.content = self.content + data

      def is_empty(self):
            return len(self.content) == 0

      def eat(self, amount):
            ret = self.content[0:amount]
            self.content = self.content[amount:]
            return ret

      def take(self, amount):
            return self.content[0:amount]

      def take_all(self):
            return self.content
      
      def next(self):
            if self.is_empty(): raise StopIteration
            return self.eat(self.pack_size)
