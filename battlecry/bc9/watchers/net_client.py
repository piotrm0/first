import socket
import sys
import errno

import debug_util
# debug message disables:
# net status
# net error
# net debug

class net_client:
      def __init__(self,
                   remote_host   = 'localhost',
                   remote_port   = 20,
                   pack_size     = 1024):
            
            self.remote_host   = remote_host
            self.remote_port   = remote_port
            self.pack_size     = pack_size

            self.connected  = 0
            self.connecting = 0

            self.notify      = {}
            self.notify_args = {}
            self.notify_kw   = {}

            self.buffer_in  = None
            self.buffer_out = None

      def need_write(self):
            if ((not self.connecting) and
                (not self.connected)):
                  return 0
            return ((self.connecting) or
                    (not self.buffer_out.is_empty()))

      def set_notify(self, key, callback, *args, **kw):
            self.notify[key]      = callback
            self.notify_args[key] = args
            self.notify_kw[key]   = kw

      def call_notify(self, key, *args, **kw):
            temp_args = []
            temp_kw   = {}

            debug_util.d_print("net status", "notifying %s with %s and %s" % (key, str(args), str(kw)))

            for a in args: temp_args.append(a)
            for k in kw: temp_kw[k] = kw[k]
            
            if self.notify_args.has_key(key):
                  for a in self.notify_args[key]: temp_args.append(a)
            if self.notify_kw.has_key(key):
                  for k in self.notify_kw[key]: temp_kw[k] = self.notify_kw[key][k]
            if self.notify.has_key(key):
                  return self.notify[key](*temp_args, **temp_kw)

      def connect(self):
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.sock.setblocking(0)
            
            self.buffer_in  = buffer(pack_size=self.pack_size)
            self.buffer_out = buffer(pack_size=self.pack_size)
            
            debug_util.d_print("net status", "connecting to %s:%s" % (self.remote_host, self.remote_port))

            try:
                  self.sock.connect((self.remote_host, self.remote_port))
                  self.connecting = 1
            except socket.error, (value, message):  # not sure if this is right
                  debug_util.d_print("net error", "socket.error(%s,%s)" % (value, message))
                  if ((value != errno.EAGAIN) and
		      (value != errno.EINPROGRESS) and
                      (value != errno.EWOULDBLOCK)):
                        self.connected = 0
                        raise
                  else:
                        self.connecting = 1
                        return 0

      def disconnect(self):
            debug_util.d_print("net status", "disconnected")
            
            self.connected  = 0
            self.connecting = 0

            self.buffer_in  = None
            self.buffer_out = None

            self.sock.shutdown(socket.SHUT_RDWR)
            self.sock.close()

            self.call_notify("disconnect")

      def send(self, data):
            if not self.connected:
                  return

            need_notify = 1
            if self.need_write():
                  need_notify = 0
            
            self.buffer_out.add(data)
            self.sock_send()

            if ((need_notify) and
                (self.need_write())):
                  self.call_notify("need_write")

      def disconnected(self):
            self.connected  = 0
            self.connecting = 0
            self.call_notify("disconnect")

      def sock_recv(self):
            temp = ""
            more = 1

            while more:
                  try:
                        part = ""
                        part = self.sock.recv(self.pack_size)
                        temp = temp + part

                        if len(part) == 0:
                              self.disconnected()
                              return
                        
                  except socket.error, (value, message):
                        temp = temp + part
                        if ((errno.EAGAIN == value) or
                            (errno.EWOULDBLOCK == value)): # 35 = EAGAIN = resource temporarily unavailable
                              more = 0
                        elif errno.ECONNRESET == value: # 54 = ECONNRESET = connection reset by peer
                              self.disconnected()
                              return
                        else:
                              raise

            self.buffer_in.add(temp)

            processed = self.call_notify("data", self.buffer_in.take_all())
            self.buffer_in.eat(processed)

      def sock_send(self):
            if ((not self.connected) and
                (self.connecting)):
                  debug_util.d_print("net status", "connected")
                  self.connecting = 0
                  self.connected = 1
                  self.call_notify("connect", self.sock)
                  return

            if not self.connected:
                  debug_util.d_print("net error", "not connected")
                  return

            if self.buffer_out.is_empty():
                  return 0

            sending = self.buffer_out.content
            sent = self.sock.send(sending)
            debug_util.d_print("net debug", "sent (%s bytes): %s" % (sent, sending[0:sent]))
            
            if sent != len(sending):
                  self.buffer_out.content = sending[sent:len(out)]
            else:
                  self.buffer_out.content = ""

            return sent

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

      def uneat(self, data):
            self.content = data + self.content

      def take(self, amount):
            return self.content[0:amount]

      def take_all(self):
            return self.content
      
      def next(self):
            if self.is_empty(): raise StopIteration
            return self.eat(self.pack_size)
