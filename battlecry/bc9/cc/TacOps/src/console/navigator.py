#!/usr/bin/env python

from copy import copy;
import gtk;
from rules import *;

class match_navigator:
    def __init__(self, on_change_callback = None):
	self.on_change = on_change_callback;
	progress.register(1, self.setup_frame);
	progress.register(4, self.setup_buttons);
	progress.register(1, self.setup_complete);
	self.cc = None;
	self.container = None;
	self.current = None;
	self.buttons = {};
	self.levels = {};
	self.number_ranges = {};
	self.index_ranges = {};
	self.levels = [LEVEL_DEFAULT];
	self.number_ranges[LEVEL_DEFAULT] = (0, 0);
	self.index_ranges = copy(LEVEL_INDEX_RANGES);

    def setup_frame(self):
	text = "Match Navigator: choose match to score or play";
	self.frame = self.container = gtk.Frame(text);
	self.frame.set_sensitive(False);
	self.frame.set_label_align(0.5, 0.5);
	self.frame.set_shadow_type(gtk.SHADOW_IN);
	label = self.frame.get_label_widget();
	label.set_padding(4, 0);

    def setup_buttons(self):
	buttons = gtk.HBox();
	buttons.set_border_width(8);
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
	buttons.pack_start(button, expand=False, fill=False, padding=4);
	self.frame.add(buttons);

    def setup_complete(self):
	self.frame.show_all();
	self.update_navigator();

    def connect(self, cc = None):
	if not isinstance(cc, cc_client):
	    raise Exception("match_navigator requires a cc_client");
	self.ccenter = cc;
	self.get_ranges();

    def get_ranges(self):
	query = ("SELECT min(match_number) AS min_number, " +
		 	"max(match_number) AS max_number, match_level " +
		 "FROM game_match GROUP BY match_level");
	self.ccenter.query(query, self.update_ranges);

    def update_ranges(self, results):
	if len(results) < 1:
	    gtk_alert_error("<b>Unable to determine matchlist:</b>\n\n" +
			    "No result returned.");
	    return;
	result = results[0];
	if result.type != query_result.TYPE_RSET:
	    gtk_alert_error("<b>Unable to determine matchlist:</b>\n\n" +
			    rset.msg);
	    return;
	rset = result.rset;
	i_min = rset.index_by_name['min_number'];
	i_max = rset.index_by_name['max_number'];
	i_lev = rset.index_by_name['match_level'];
	for row in rset:
	    level = int(row[i_lev]);
	    try:
		self.levels.remove(level);
	    except:
		pass;	
	    self.levels.append(level);
	    self.number_ranges[level] = (int(row[i_min]), int(row[i_max]));
#	    print level, self.number_ranges[level];
	self.levels.sort();
	self.nav_scheduled(None);

    def validate_number(self):
	if None == self.current:
	    return;
	(match_level, match_number, match_index) = self.current;
	if not match_level in self.levels:
	    match_level = min(self.levels);
	number_range = self.number_ranges[match_level];
	if match_number > number_range[1]:
	    match_number = number_range[1];
	if match_number < number_range[0]:
	    match_number = number_range[0];
	index_range = self.index_ranges[match_level];
	if match_index > index_range[1]:
	    match_index = index_range[1];
	if match_index < index_range[0]:
	    match_index = index_range[0];
	self.current = (match_level, match_number, match_index);

    def update_navigator(self):
	if None == self.current:
	    self.container.set_sensitive(False);
	    return;
	self.validate_number();
	self.container.set_sensitive(True);
	(match_level, match_number, match_index) = self.current;
	numbers = self.number_ranges[match_level];
	indexes = self.index_ranges[match_level];
	enable = (match_number > numbers[0] or match_index > indexes[0]);
	self.buttons["first"].set_sensitive(enable);
	self.buttons["back"].set_sensitive(enable);
	enable = not (match_level == max(self.levels));
	self.buttons["up"].set_sensitive(enable);
	self.match_level.set_text(LEVEL_NAMES[match_level][1])
	enable = not (match_level == min(self.levels));
	self.buttons["down"].set_sensitive(enable);
	text = str(match_number);
	if match_index > 0:
	    text += "." + str(match_index);
	self.match_number.set_text(text);
	enable = (match_number < numbers[1] or match_index < indexes[1]);
	self.buttons["next"].set_sensitive(enable);
	self.buttons["last"].set_sensitive(enable);

    def nav_set(self, *number):
	if 1 == len(number):
	    number = number[0];
	self.current = number;
	self.update_navigator();
	self.on_change(self.current);

    def nav_first(self, widget):
	(match_level, match_number, match_index) = self.current;
	match_number = self.number_ranges[match_level][0];
	self.nav_set(match_level, match_number, match_index);

    def nav_back(self, widget):
	(match_level, match_number, match_index) = self.current;
	match_number -= 1;
# index ?
	self.nav_set(match_level, match_number, match_index);

    def nav_up(self, widget):
	(match_level, match_number, match_index) = self.current;
	match_level += 1;
	self.nav_set(match_level, match_number, match_index);

    def nav_down(self, widget):
	(match_level, match_number, match_index) = self.current;
	match_level -= 1;
	self.nav_set(match_level, match_number, match_index);

    def nav_next(self, widget):
	(match_level, match_number, match_index) = self.current;
	match_number += 1;
# index?
	self.nav_set(match_level, match_number, match_index);

    def nav_last(self, widget):
	(match_level, match_number, match_index) = self.current;
	match_number = self.number_ranges[match_level][1];
	self.nav_set(match_level, match_number, match_index);

    def nav_scheduled(self, widget):
	query = ("SELECT match_level, match_number, match_index " +
		 "FROM ondeck_match LIMIT 1");
	self.ccenter.query(query, self.found_scheduled);

    def found_scheduled(self, results):
	if len(results) < 1:
	    gtk_alert_error("<b>Unable to determine matchlist:</b>\n\n" +
			    "No result returned.");
	    return;
	result = results[0];
	if result.type != query_result.TYPE_RSET:
	    gtk_alert_error("<b>Unable to determine matchlist:</b>\n\n" +
			    rset.msg);
	    return;
	rset = result.rset;
	if len(rset) < 1:
	    self.number = None;
	    self.update_navigator();
	    self.on_change(self.number);
	    return;
	row = rset[0];
	match_level = int(row['match_level']);
	match_number = int(row['match_number']);
	match_index = int(row['match_index']);
	self.nav_set(match_level, match_number, match_index);
