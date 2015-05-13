from cc_client import cc_client
from select    import select
from sys       import stdin        

import debug_util

debug_util.debug = 1

class example:
    def __init__(self):
        self.cc   = cc_client('test') 

        ###
        
        # Arrange for a callback for a change on env "x".
        #  Note the callback occurs when the data changed and
        #  not necessarily when the cc server notifies.
#        self.watch_id  = self.cc.env_watch('x', self.on_env)

        # Arrange for a callback for changes on table "test".
        #  Note that the system doesn't actually check if anything changed
        #  but rather callbacks if the notification from cc server arrives
#        self.watch_id2 = self.cc.rset_watch('test', self.on_rset)

        # Arrange for a general query callback to be called
        #  whenver any query is received.
#        self.cc.notify['query'] = self.on_all_querys

        # Arrange for a callback to a specific query.
#        self.cc.query("select * from test", callback=self.on_query, results=1)

        # Arrange for a callback to a specific query. Note that the number
        #  of results must be provided. The callback is called when all
        #  results arrived.
#        self.cc.query("select * from test; select * from test",
#                      callback=self.on_query,
#                      results=2)

        # Lets try a bad query.
#        self.cc.query("select * from test_not_really",
#                      callback=self.on_query,
#                      stuff="this is extra",
#                      more_stuff="this is also extra and anything else you want, but they have to be named args")

        # Let us try an "effect" query.
#        self.cc.query("update test set id=5 where id=7",
#                      callback=self.on_query,
#                      results=1)

        # Let us try a tran sequence.
#        self.cc.query("BEGIN ; select * from test; select * from test; commit",
#                      callback=self.on_query,
#                      results=4)

        # Let us try a tran sequence with error
        self.cc.query("BEGIN ; select * from test; select * from test_error; select * from test; commit",
                      callback=self.on_query,
                      results=4)

        # Arrange for a callback on a connection.
        #self.cc.net.set_notify('connect', self.on_connect, 0,1,2,3, named1 = "a1", named2 = "a2")
        self.cc.notify['connect'] = self.on_connect

        # Arrange for a callback on a disconnection.
        self.cc.notify['disconnect'] = self.on_disconnect

        # Arrange for a connect.
        self.cc.connect('localhost')

    def main_loop(self):
        while 1:
            reads  = [stdin, self.cc.net.sock]
            writes = []
            if self.cc.net.need_write():
                writes.append(self.cc.net.sock)

#            print "r%s w%s" % (reads, writes)
                
            (can_read, can_write, whatever) = select(reads, writes, [])

            for handle in can_read:
                if stdin == handle:
                    self.cc.net.send(stdin.readline())
                elif self.cc.net.sock == handle:
                    self.cc.net.sock_recv()

            for handle in can_write:
                if self.cc.net.sock == handle:
                    self.cc.net.sock_send()

    ###

    # define a test callback for an ENV notification
    def on_env(self, key, old_value, value):
        print "got an env! (%s=%s (was %s))" % (key, value, old_value)

    def on_rset(self, rset):
        print "got an rset: %s" % (rset)

    def on_query(self, ress, **kw): # kw are the named parameters that are not mentioned here
        print "got query results (extra=%s):" % (kw)
        for res in ress:
            print "\t: %s" % (res)

    def on_all_querys(self, res):
        print "got a query result: %s" % (res)

    def on_connect(self, *args, **kw):
#        self.cc.command("help")
        print "connected!"
        print args
        print "args: %s" % (repr(args))
        print "kw  : %s" % (kw)
        
    def on_disconnect(self):
        print "disconnected!"

#############

my_example = example()
my_example.main_loop()
