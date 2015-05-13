#!/usr/bin/env python

import gtk;
import gobject;

f = open("/tmp/testfile", "r+", 1);
f2 = open("/dev/zero", "r", 0);

print f.fileno(), f2.fileno();

def h(source, condition):
	if condition & gobject.IO_IN:
		line = f.readline();
		print "read", len(line), "bytes";
	if condition & gobject.IO_OUT:
		R = gobject.io_add_watch(source, gobject.IO_IN, h);
		print "write", R;
	return False;

R = gobject.io_add_watch(f.fileno(), gobject.IO_IN, h);
W = gobject.io_add_watch(f.fileno(), gobject.IO_OUT, h);

print "R=", R, "W=", W;

gtk.main();
