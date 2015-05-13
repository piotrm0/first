#!/usr/bin/env python

import gtk;

class match_navigator:
    def __init__(self, cc = None, container = None, number = None):
#	if not isinstance(cc, cc_client):
#	    raise Exception("match_navigator requires a cc_client");
	if None == container:
	    raise Exception("match_navigator requires a container");
	if None == number:
	    raise Exception("match_navigator requires a match number");
	frame = gtk.Frame("Match Navigator: choose match to score or play");
	frame.set_label_align(0.5, 0.5);
	frame.set_shadow_type(gtk.SHADOW_IN);
	label = frame.get_label_widget();
	label.set_padding(4, 0);
	buttons = gtk.HBox();
	buttons.set_border_width(8);

	self.buttons = {};
	self.current = number;
	self.level_range = (0, 1);
	self.number_range = (0, 1);
	self.index_range = (0, 1);

	button = gtk.Button();
	hbox = gtk.HBox(spacing=2);
	icon = gtk.image_new_from_stock(gtk.STOCK_GOTO_FIRST, gtk.ICON_SIZE_DIALOG);
	hbox.pack_start(icon, expand=False, fill=False);
	label = gtk.Label("First");
	hbox.pack_start(label, expand=False, fill=False);
	button.add(hbox);
	self.buttons["first"] = button;
	button.connect("clicked", self.nav_first);
	buttons.pack_start(button, expand=False, fill=False, padding=4);

	button = gtk.Button();
	hbox = gtk.HBox(spacing=2);
	icon = gtk.image_new_from_stock(gtk.STOCK_GO_BACK, gtk.ICON_SIZE_DIALOG);
	hbox.pack_start(icon, expand=False, fill=False);
	label = gtk.Label("Prev.");
	hbox.pack_start(label, expand=False, fill=False);
	button.add(hbox);
	self.buttons["back"] = button;
	button.connect("clicked", self.nav_back);
	buttons.pack_start(button, expand=False, fill=False, padding=4);

	button = gtk.Button();
	icon = gtk.image_new_from_stock(gtk.STOCK_GO_UP, gtk.ICON_SIZE_DIALOG);
	button.add(icon);
	self.buttons["up"] = button;
	button.connect("clicked", self.nav_up);
	buttons.pack_start(button, expand=False, fill=False, padding=4);

	label = gtk.Label("");
	self.match_level = label;
	buttons.pack_start(label, expand=True, fill=True, padding=4);

	button = gtk.Button();
	icon = gtk.image_new_from_stock(gtk.STOCK_GO_DOWN, gtk.ICON_SIZE_DIALOG);
	button.add(icon);
	self.buttons["down"] = button;
	button.connect("clicked", self.nav_down);
	buttons.pack_start(button, expand=False, fill=False, padding=4);

	label = gtk.Label("");
	self.match_number = label;
	buttons.pack_start(label, expand=True, fill=True, padding=4);

	button = gtk.Button();
	icon = gtk.image_new_from_stock(gtk.STOCK_GO_FORWARD, gtk.ICON_SIZE_DIALOG);
	button.add(icon);
	self.buttons["next"] = button;
	button.connect("clicked", self.nav_next);
	buttons.pack_start(button, expand=False, fill=False, padding=4);

	button = gtk.Button();
	icon = gtk.image_new_from_stock(gtk.STOCK_GOTO_LAST, gtk.ICON_SIZE_DIALOG);
	button.add(icon);
	self.buttons["last"] = button;
	button.connect("clicked", self.nav_last);
	buttons.pack_start(button, expand=False, fill=False, padding=4);

	button = gtk.Button();
	icon = gtk.image_new_from_stock(gtk.STOCK_REDO, gtk.ICON_SIZE_DIALOG);
	button.add(icon);
	self.buttons["scheduled"] = button;
	button.connect("clicked", self.nav_scheduled);
	buttons.pack_start(button, expand=False, fill=False, padding=4)=

	frame.add(buttons);
	frame.show_all();

    def update(self):
	

    def nav_first(self, widget):

    def nav_back(self, widget):

    def nav_up(self, widget):

    def nav_down(self, widget):

    def nav_next(self, widget):

    def nav_last(self, widget):

    def nav_scheduled(self, widget):

