import pymssql
import pgdb

import sys

import thread
import time

class conf:
    def __init__(self, host=None, user=None, passwd=None, dbname=None, dbinit=None):
        self.host   = host
        self.user   = user
        self.passwd = passwd
        self.dbname = dbname
        self.dbinit = dbinit

class db:
    def __init__(self, conf=None):
        self.conf = conf
        self.dbi = None
        self.con = None
        self.cur = None
        self.thread = None
        self.lock   = thread.allocate_lock()
        self.cur    = None

    def connect(self):
        if (self.con is not None): return

        self.lock.acquire()

        if (self.con is not None):
            self.lock.release()
            return

        sys.stderr.write("db\t: attempting connect via [%s] to host [%s], database [%s]\n" % (self.__class__.__name__, self.conf.host, self.conf.dbname))

        self.con = self.dbi.connect(host = self.conf.host,
                                    user = self.conf.user,
                                    password = self.conf.passwd,
                                    database = self.conf.dbname)

        self.cur = self.con.cursor()

        self.lock.release()

    def query(self, qstring):
        if (self.con is None):
            self.connect()
            while(self.con is None):
                time.sleep(1)

        self.lock.acquire()

        sys.stderr.write("db\t: query [%s]\n" % (qstring))

        try:
            self.cur.execute(qstring)
            if self.cur.description is None:
                ret = result(rows = [],
                             desc = self.cur.description)
            else:
                ret = result(rows = self.cur.fetchall(),
                             desc = self.cur.description)
            
        except self.dbi.DatabaseError, e:
            print e
            ret = result(flag = result.FAIL)

        self.lock.release()
        
        return ret

    def commit(self):
        self.con.commit()

    def observe_start(self):
        if (self.thread is not None):
            return

        #self.thread = thread.start_new_thread(self.observe_loop, ())

    def observe_loop(self):
        self.check()
        while (1):
            self.check()
            time.sleep(1)

    def check(self):
        self.connect()
        # self.lock.acquire()
        # stuff
        # self.lock.release()

def quotestring(s):
    s = s.replace('\'', '\'\'')
    return '\'' + s + '\''

class pg (db):
    def __init__(self, conf=None):
        db.__init__(self, conf)
        self.dbi = pgdb

class pgn (db):
    def __init__(self, conf=None):
        db.__init__(self, conf)

class ms (db):
    def __init__(self, conf=None):
        db.__init__(self, conf)
        self.dbi = pymssql

class mysql (db):
    def __init__(self, conf=None):
        db.__init__(self, conf)

class result:
    FAIL    = 1
    SUCCESS = 2
    
    def __init__(self, flag=None, rows=None, desc=None):
        self.rows = rows
        if (rows is None):
            self.rows = []
        self.desc = desc
        self.flag = flag
        if (rows is not None):
            self.num_rows = len(rows)
        if (desc is not None):
            self.num_cols = len(desc)
        if (self.flag is None):
            self.flag = result.SUCCESS

    def failed(self):
        return self.flag & result.FAIL

class dbm:
    DB_MAIN = 0
    DB_AUX1 = 1
    DB_AUX2 = 2
    DB_LAST = 2
    
    def __init__(self):
        self.db   = [None] * (dbm.DB_LAST + 1)
        self.conf = [None] * (dbm.DB_LAST + 1)

        #self.conf[dbm.DB_MAIN] = conf(host   = 'ccenter',
        self.conf[dbm.DB_MAIN] = conf(host   = 'localhost',
                                      user   = 'postgres',
                                      passwd = '',
                                      dbname = 'tacops',
                                      dbinit = pg)
        #self.conf[dbm.DB_AUX1] = conf(host   = 'cmwerner.dyndns.org:2301',
        #                              user   = 'sa',
        #                              passwd = 'FIRSTpass#1',
        #                              dbname = 'FMS_Demo',
        #                              dbinit = ms)
        # 1433 is official port, 2301 is what cris used
        self.conf[dbm.DB_AUX1] = conf(host   = 'first:2301',
                                      user   = 'sa',
                                      passwd = 'FIRSTpass#1',
                                      dbname = 'FMS_Prod',
                                      dbinit = ms)

    def init_db(self, dbi):
        self.db[dbi] = self.conf[dbi].dbinit(self.conf[dbi])
        self.db[dbi].observe_start()

    def init_all(self):
        self.init_db(dbm.DB_MAIN)        
        self.init_db(dbm.DB_AUX1)

    def query(self, qstring):
        return self.db[dbm.DB_MAIN].query(qstring)
