#!/usr/bin/env python

import gtk;
from rules import *;

class display:
    def __init__(self):
	self.cc = None;
	self.container = None;
	self.display_menu = display_menu();
	progress.register(2, self.setup_menu);

    def connect(self, cc):
	self.cc = cc;
	self.display_menu.connect(cc);

    def setup_menu(self):
	menu = gtk.combo_box_new_text();
	self.container = menu;
	for item in self.display_menu.MENUS:
	    (label, callback) = item;
	    menu.append_text(label);
#	menu.set_active(0);
	menu.connect("changed", self.do_menu);
	menu.show_all();

    def do_menu(self, widget = None):
	index = self.container.get_active();
	item = self.display_menu.MENUS[index];
	(label, callback) = item;
	callback(widget);

    def match_changed(self, number):
	if None == number:
	    return;
	number = map(str, number);
	current_match = ".".join(number);
	self.cc.command("ENV current_match=" + current_match);
	self.display_menu.match_changed(number);
