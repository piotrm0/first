#!/usr/bin/env python

import random;
import gtk;
from rules import *;


class rankings:
    def __init__(self):
	self.container = None;
	self.num_rankings_columns = 0;
	self.rankings_store = None;
	self.rankings_view = None;
	progress.register(1, self.setup_rankings);

    def setup_rankings(self):
	frame = gtk.Frame("Current Rankings");
	frame.set_label_align(0.5, 0.5);
	frame.set_shadow_type(gtk.SHADOW_ETCHED_IN);
	label = frame.get_label_widget();
	label.set_padding(2, 0);
	self.rankings_store = gtk.ListStore(gobject.TYPE_STRING);
	self.rankings_view = gtk.TreeView(self.rankings_store);
	renderer = gtk.CellRendererText();
	renderer.set_property("xalign", 1.0);
	column = gtk.TreeViewColumn("Rank", renderer, text=0);
	column.set_sort_column_id(0);
	self.rankings_view.append_column(column);
	self.rankings_view.set_headers_clickable(True);
	self.rankings_view.set_rules_hint(True);
	self.rankings_view.set_reorderable(False);
	self.rankings_view.set_enable_search(True);
	scroller = gtk.ScrolledWindow();
	scroller.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC);
	scroller.add(self.rankings_view);
	frame.add(scroller);
	self.container = frame;
	self.container.show_all();

    def connect(self, cc = None):
	if not isinstance(cc, cc_client):
	    raise Exception("rankings requires a cc_client");
	cc.rset_watch("participant_results", self.update_rankings);

    def update_rankings(self, rset):
	self.rankings_store.clear();
	self.rankings_row = None;
	new_columns = len(rset.fields);
	if new_columns > self.num_rankings_columns:
	    col_types = [gobject.TYPE_STRING] * (new_columns + 1);
	    self.rankings_store = gtk.ListStore(*col_types);
	    self.rankings_view.set_model(self.rankings_store);
	    for col in range(0, self.num_rankings_columns):
		align = gtk_rset_guess_xalign(rset, col);
		column = self.rankings_view.get_column(col);
		renderers = column.get_cell_renderers();
		for renderer in renderers:
		    renderer.set_property("xalign", align);
	    for col in range(self.num_rankings_columns, new_columns):
		renderer = gtk.CellRendererText();
		# "auto-detect" the alignment
		align = gtk_rset_guess_xalign(rset, col);
		renderer.set_property("xalign", align);
		renderer.set_property("editable", False);
		column = gtk.TreeViewColumn(None, renderer, text=(col + 1));
		column.set_sort_column_id(col + 1);
		self.rankings_view.append_column(column);
	elif new_columns < self.num_rankings_columns:
	    for col in range(self.num_rankings_columns, new_columns, -1):
		column = self.rankings_view.get_column(col);
		self.rankings_view.remove_column(column);
	self.num_rankings_columns = new_columns;
	for col in range(0, new_columns):
	    column = self.rankings_view.get_column(col + 1);
	    title = rset.fields[col];
	    column.set_title(title);
	row_number = 0;
	for row in rset:
	    new_row = [str(row_number + 1)];
	    for col in range(0, new_columns):
		new_row.append(row[col]);
	    self.rankings_store.append(new_row);
	    row_number += 1;
	self.rankings_view.columns_autosize();
