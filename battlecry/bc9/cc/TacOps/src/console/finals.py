#!/usr/bin/env python

import random;
import gtk;
from rules import *;


class finals:
    def __init__(self, navigator):
	self.cc = None;
	self.nav = navigator;
	self.ladder = None;
	self.buttons = {};
	self.container = None;
	self.alliances_seeded = False;
	self.alliance_store = None;
	self.alliance_view = None;
	self.alliance_row = None;
	self.alliance_sel = None;
	self.alliance_teams = [];
	self.alliance_next_empty = (-1, -1);
	self.alliance_last_filled = (-1, -1);
	self.teampool_store = None;
	self.teampool_view = None;
	self.teampool_row = None;
	self.teampool_sel = None;
	self.team_pool = [];
	progress.register(1, self.setup_alliances);
	progress.register(6, self.setup_buttons);
	progress.register(1, self.setup_teampool);

    def setup_alliances(self):
	self.container = gtk.HBox();
	frame = gtk.Frame("finals alliances");
	frame.set_label_align(0.5, 0.5);
	frame.set_shadow_type(gtk.SHADOW_ETCHED_IN);
	label = frame.get_label_widget();
	label.set_padding(2, 0);
	col_types = [gobject.TYPE_STRING] * (FINALS_ALLIANCE_TEAMS + 1);
	self.alliance_store = gtk.ListStore(*col_types);
	self.ladder = ladder(self.alliance_store, self.nav);

	# setup view
	self.alliance_view = gtk.TreeView(self.alliance_store);
	self.alliance_sel = self.alliance_view.get_selection();
	self.alliance_sel.connect("changed", self.selection_changed);
	renderer = gtk.CellRendererText();
	renderer.set_property("xalign", 1.0);
	column = gtk.TreeViewColumn("#", renderer, text=0);
	column.set_sort_column_id(0);
	self.alliance_view.append_column(column);
	for recruit_order in range(0, FINALS_ALLIANCE_TEAMS):
	    if 0 == recruit_order:
		name = "Captain";
		editable = False;
	    else:
		name = "Recruit";
		editable = True;
	    renderer = gtk.CellRendererText();
	    renderer.set_property("editable", editable);
	    renderer.connect("edited", self.ally_edited, recruit_order + 1);
	    column = gtk.TreeViewColumn(name, renderer,
					text=(recruit_order + 1));
	    column.set_sizing(gtk.TREE_VIEW_COLUMN_AUTOSIZE);
	    column.set_sort_column_id(-1);
	    self.alliance_view.append_column(column);
	self.alliance_view.set_headers_clickable(False);
	self.alliance_view.set_rules_hint(True);
	self.alliance_view.set_reorderable(False);
	self.alliance_view.set_enable_search(False);

	scroller = gtk.ScrolledWindow();
	scroller.set_policy(gtk.POLICY_NEVER, gtk.POLICY_AUTOMATIC);
	scroller.add(self.alliance_view);
	frame.add(scroller);
	self.container.pack_start(frame, expand=False, fill=True);

    def setup_buttons(self):
	vbox = gtk.VBox();
	sep = gtk.HSeparator();
	vbox.pack_start(sep, expand=False, fill=False, padding=8);
	button = gtk.Button();
	hbox = gtk.HBox(spacing=2);
	icon = gtk.image_new_from_stock(gtk.STOCK_GOTO_FIRST, gtk.ICON_SIZE_DND);
	hbox.pack_start(icon, expand=False, fill=False);
	label = gtk.Label("(re)seed alliances");
	hbox.pack_start(label, expand=False, fill=False);
	label = gtk.Label();
	hbox.pack_start(label, expand=True, fill=True);
	button.add(hbox);
	vbox.pack_start(button, expand=False, fill=False, padding=2);
	self.buttons["seed"] = button;
	button.connect("clicked", self.reseed);
	sep = gtk.HSeparator();
	vbox.pack_start(sep, expand=False, fill=False, padding=4);
	button = gtk.Button();
	hbox = gtk.HBox(spacing=2);
	icon = gtk.image_new_from_stock(gtk.STOCK_GO_BACK, gtk.ICON_SIZE_DND);
	hbox.pack_start(icon, expand=False, fill=False);
	label = gtk.Label("\"recruit\" (add)\nteam from team pool");
	hbox.pack_start(label, expand=True, fill=True);
	icon = gtk.image_new_from_stock(gtk.STOCK_GO_BACK, gtk.ICON_SIZE_DND);
	hbox.pack_start(icon, expand=False, fill=False);
	button.add(hbox);
	vbox.pack_start(button, expand=False, fill=False, padding=2);
	self.buttons["recruit"] = button;
	button.connect("clicked", self.recruit);
	button = gtk.Button();
	hbox = gtk.HBox(spacing=2);
	icon = gtk.image_new_from_stock(gtk.STOCK_GO_FORWARD, gtk.ICON_SIZE_DND);
	hbox.pack_start(icon, expand=False, fill=False);
	label = gtk.Label("\"discharge\" (remove)\nteam from alliance");
	hbox.pack_start(label, expand=True, fill=True);
	icon = gtk.image_new_from_stock(gtk.STOCK_GO_FORWARD, gtk.ICON_SIZE_DND);
	hbox.pack_start(icon, expand=False, fill=False);
	button.add(hbox);
	vbox.pack_start(button, expand=False, fill=False, padding=2);
	self.buttons["discharge"] = button;
	button.connect("clicked", self.discharge);
	button = gtk.Button();
	hbox = gtk.HBox(spacing=2);
	icon = gtk.image_new_from_stock(gtk.STOCK_GO_BACK, gtk.ICON_SIZE_DND);
	hbox.pack_start(icon, expand=False, fill=False);
	label = gtk.Label("\"draft\" (random)\nteam from team pool");
	hbox.pack_start(label, expand=True, fill=True);
	icon = gtk.image_new_from_stock(gtk.STOCK_OK, gtk.ICON_SIZE_DND);
	hbox.pack_start(icon, expand=False, fill=False);
	button.add(hbox);
	vbox.pack_start(button, expand=False, fill=False, padding=2);
	self.buttons["draft"] = button;
	button.connect("clicked", self.draft);
	button = gtk.Button();
	hbox = gtk.HBox(spacing=2);
	icon = gtk.image_new_from_stock(gtk.STOCK_UNDO, gtk.ICON_SIZE_DND);
	hbox.pack_start(icon, expand=False, fill=False);
	label = gtk.Label("\"promote\" (captain)\nteam from team pool");
	hbox.pack_start(label, expand=False, fill=False);
	label = gtk.Label();
	hbox.pack_start(label, expand=True, fill=True);
	button.add(hbox);
	vbox.pack_start(button, expand=False, fill=False, padding=2);
	self.buttons["promote"] = button;
	button.connect("clicked", self.promote);
	sep = gtk.HSeparator();
	vbox.pack_start(sep, expand=False, fill=False, padding=8);
	button = gtk.Button();
	hbox = gtk.HBox(spacing=2);
	icon = gtk.image_new_from_stock(gtk.STOCK_CLEAR, gtk.ICON_SIZE_DND);
	hbox.pack_start(icon, expand=False, fill=False);
	label = gtk.Label("clear all alliances");
	hbox.pack_start(label, expand=False, fill=False, padding=2);
	label = gtk.Label();
	hbox.pack_start(label, expand=True, fill=True);
	button.add(hbox);
	vbox.pack_start(button, expand=False, fill=False, padding=2);
	self.buttons["clear"] = button;
	button.connect("clicked", self.clear);
	button = gtk.Button();
	hbox = gtk.HBox(spacing=2);
	icon = gtk.image_new_from_stock(gtk.STOCK_EXECUTE, gtk.ICON_SIZE_DND);
	hbox.pack_start(icon, expand=False, fill=False);
	label = gtk.Label("generate finals matches");
	hbox.pack_start(label, expand=True, fill=True);
	button.add(hbox);
	vbox.pack_start(button, expand=False, fill=False, padding=2);
	self.buttons["generate"] = button;
	button.connect("clicked", self.generate);
	self.container.pack_start(vbox, expand=False, fill=False, padding=8);
	sep = gtk.HSeparator();
	vbox.pack_start(sep, expand=False, fill=False, padding=8);
	button = gtk.Button();
	hbox = gtk.HBox(spacing=2);
	icon = gtk.image_new_from_stock(gtk.STOCK_INDEX, gtk.ICON_SIZE_DND);
	hbox.pack_start(icon, expand=False, fill=False);
	label = gtk_label_from_markup("finals match\nnavigator...");
	hbox.pack_start(label, expand=True, fill=True);
	button.add(hbox);
	vbox.pack_start(button, expand=False, fill=False, padding=2);
	self.buttons["navigate"] = button;
	button.connect("clicked", self.ladder.show_navigator);

    def setup_teampool(self):
	frame = gtk.Frame("Team Pool");
	frame.set_label_align(0.5, 0.5);
	frame.set_shadow_type(gtk.SHADOW_ETCHED_IN);
	label = frame.get_label_widget();
	label.set_padding(2, 0);
	columns = [gobject.TYPE_STRING] * 3;
	self.teampool_store = gtk.ListStore(*columns);
	self.teampool_view = gtk.TreeView(self.teampool_store);
	self.teampool_sel = self.teampool_view.get_selection();
	self.teampool_sel.connect("changed", self.selection_changed);
	col = 0;
	for head in [("Rank", 1.0), ("Team", 1.0), ("Team Name", 0.0)]:
	    (heading, align) = head;
	    renderer = gtk.CellRendererText();
	    renderer.set_property("xalign", align);
	    renderer.set_property("editable", False);
	    column = gtk.TreeViewColumn(heading, renderer, text=col);
	    column.set_sort_column_id(col);
	    self.teampool_view.append_column(column);
	    col += 1;
	self.teampool_filter = self.teampool_store.filter_new();
	self.teampool_filter.set_visible_func(self.is_team_visible);
	self.teampool_view.set_model(self.teampool_filter);
	self.teampool_view.set_headers_clickable(True);
	self.teampool_view.set_rules_hint(True);
	self.teampool_view.set_reorderable(False);
	self.teampool_view.set_enable_search(True);
	self.teampool_view.connect("row-activated", self.row_activated);
	scroller = gtk.ScrolledWindow();
	scroller.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC);
	scroller.add(self.teampool_view);
	frame.add(scroller);
	self.container.pack_start(frame, expand=True, fill=True);
	self.container.show_all();

    def connect(self, cc = None):
	self.cc = cc;
	if not isinstance(self.cc, cc_client):
	    raise Exception("finals requires a cc_client");
	self.cc.rset_watch("finals_alliance_partner", self.update_alliances);
	self.cc.rset_watch("participant_results", self.update_teampool);
	self.ladder.connect(self.cc);

    def update_alliances(self, rset):
	self.alliance_store.clear();
	self.alliance_row = None;
	self.alliance_teams = [];
	no_allies = [""] * FINALS_ALLIANCE_TEAMS;
	for alliance in range(0, FINALS_ALLIANCES):
	    self.alliance_store.append([str(alliance + 1)] + no_allies);
	i_alliance_num = rset.index_by_name['finals_alliance_number'];
	i_recruit = rset.index_by_name['recruit_order'];
	i_team_num = rset.index_by_name['team_number'];
	for row in rset:
	    alliance_num = int(row[i_alliance_num]);
	    recruit = int(row[i_recruit]);
	    team_number = row[i_team_num];
	    self.alliance_teams.append(int(team_number));
	    self.alliance_store[alliance_num - 1][recruit] = team_number;
	self.alliance_view.columns_autosize();
	self.team_pool = [];
	for row in self.teampool_store:
	    team = row[1];
	    if None != team and len(team) > 0 and 0 != int(team):
		team_number = int(team);
		if not team_number in self.alliance_teams:
		    self.team_pool.append(team_number);
	self.teampool_filter.refilter();
	self.alliance_next_empty = self.find_next_empty_ally();
	self.alliance_last_filled = self.find_last_filled_ally();
	self.update_buttons();

    def update_teampool(self, rset):
	self.teampool_store.clear();
	self.teampool_row = None;
	self.team_pool = [];
	row_number = 0;
	for row in rset:
	    new_row = [str(row_number + 1)];
	    team = row[RANKINGS_TEAM_COLUMN];
	    new_row.append(row[RANKINGS_TEAM_COLUMN]);
	    new_row.append(row[RANKINGS_TEAMNAME_COLUMN]);
	    self.teampool_store.append(new_row);
	    if None != team and len(team) > 0 and 0 != int(team):
		team_number = int(team);
		if not team_number in self.alliance_teams:
		    self.team_pool.append(team_number);
	    row_number += 1;
	self.teampool_view.columns_autosize();
	self.teampool_filter.refilter();
	self.update_buttons();

    def is_team_visible(self, model, iter):
	team = model.get_value(iter, 1);
	if None == team or len(team) < 1:
	    return False;
	team_number = int(team);
	return 0 != team_number and (team_number in self.team_pool);

    def selection_changed(self, selection):
	rows = gtk_tree_selection_get_rows(selection);
	if None == rows:
	    row = None;
	else:
	    row = rows[0];
	if selection == self.alliance_sel:
	    self.alliance_row = row;
	if selection == self.teampool_sel:
	    self.teampool_row = row;
	self.update_buttons();

    def find_next_empty_ally(self):
	for recruit in range(0, FINALS_ALLIANCE_TEAMS):
	    for alliance in range(0, FINALS_ALLIANCES):
		team = self.alliance_store[alliance][recruit + 1];	
		if None == team or len(team) < 1 or 0 == int(team):
		    return (alliance, recruit);
	return (-1, -1);

    def find_last_filled_ally(self):
	for recruit in range(FINALS_ALLIANCE_TEAMS, 0, -1):
	    for alliance in range(FINALS_ALLIANCES, 0, -1):
		team = self.alliance_store[alliance - 1][recruit];
		if None != team and len(team) > 0 and 0 != int(team):
		    return (alliance - 1, recruit - 1);
	return (-1, -1);

    def update_buttons(self):
	(ally, recruit) = self.alliance_next_empty;
	able = 0 == recruit or (1 == recruit and 0 == ally);
	self.buttons["seed"].set_sensitive(able);
	able = recruit >= 0 and None != self.teampool_row;
	self.buttons["recruit"].set_sensitive(able);
	able = None != self.alliance_row;
	self.buttons["discharge"].set_sensitive(able);
	able = recruit >= 0;
	self.buttons["draft"].set_sensitive(able);
	self.buttons["generate"].set_sensitive(not able);
	self.buttons["navigate"].set_sensitive(not able);
	able = (None != self.alliance_row and 1 == recruit and
		self.alliance_row > ally);
	self.buttons["promote"].set_sensitive(able);
	(ally, recruit) = self.alliance_last_filled;
	able = recruit >= 0 or ally >= 0;
	self.buttons["clear"].set_sensitive(able);

    def ally_edited(self, renderer, path, new_text, column):
	if None == path or None == new_text:
	    return;
	row = int(path);
	if len(new_text) > 0:
	    team_number = int(new_text);
	else:
	    team_number = 0;
	if 0 == team_number:
	    self.delete((row, column - 1));
	    return;
	if not team_number in self.team_pool:
	    return;
	self.add("change team number", team_number, (row, column - 1));

    def row_activated(self, treeview, path, col):
	if None == path:
	    return;
	row = path[0];
	team = self.teampool_store[row][1];
	if None == team or len(team) < 1:
	    return;
	team_number = int(team);
	if 0 == team_number:
	    return;
	self.add("recruit team", team_number);

    def reseed(self, widget = None):
	(ally, recruit) = self.alliance_next_empty;
	if 0 != recruit and (1 != recruit or 0 != ally):
	    return;
	if recruit > 0 or ally > 0:
	    text = ("Are you sure you wish to reseed the alliances?  " +
		"This will erase the current alliances!");
	    if not gtk_alert_question(text):
		return;
	self.alliances_seeded = True;
	queries = ["BEGIN", "DELETE FROM finals_alliance_partner"];
	for rank in range(0, FINALS_ALLIANCES):
	    if rank >= len(self.teampool_store):
		break;
	    team = self.teampool_store[rank][1];
	    queries.append("INSERT INTO finals_alliance_partner " +
		"(finals_alliance_number, recruit_order, team_number)" +
		" VALUES (" + str(rank + 1) + ", 1, " + team + ")");
	queries.append("COMMIT");
	self.cc.query(queries, self.query_done, "seed teems");

    def recruit(self, widget = None):
	row = self.teampool_row;
	if None == row:
	    return;
	team = self.teampool_store[row][1];
	if None == team or len(team) < 1 or 0 == int(team):
	    return;
	self.add("recruit team", int(team));

    def add(self, message, team_number, position = None):
	if team_number <= 0:
	    return;
	if team_number in self.alliance_teams:
	    return;
	if None == position:
	    (ally, recruit) = self.alliance_next_empty;
	else:
	    (ally, recruit) = position;
	if (ally < 0 or ally >= FINALS_ALLIANCES or
	    recruit < 0 or recruit >= FINALS_ALLIANCE_TEAMS):
	    return;
	queries = ("BEGIN",
		   "DELETE FROM finals_alliance_partner WHERE" +
		   " finals_alliance_number = " + str(ally + 1) +
		   " AND recruit_order = " + str(recruit + 1),
		   "INSERT INTO finals_alliance_partner" +
		   " (finals_alliance_number, recruit_order, team_number)" +
		   " VALUES (" + str(ally + 1) + ", " + str(recruit + 1) +
		   ", " + str(team_number) + ")",
		   "COMMIT");
	self.cc.query(queries, self.query_done, message);

    def delete(self, position = None):
	if None == position:
	    (ally, recruit) = self.alliances_last_filled;
	else:
	    (ally, recruit) = position;
	if (ally < 0 or ally >= FINALS_ALLIANCES or
	    recruit < 0 or recruit >= FINALS_ALLIANCE_TEAMS):
	    return;
	team = self.alliance_store[ally][recruit + 1];
	if None == team or len(team) < 1:
	    return;
	team_number = int(team);
	if 0 == team_number:
	    return;
	query = ("DELETE FROM finals_alliance_partner WHERE" +
		 " finals_alliance_number = " + str(ally + 1) +
		 " AND recruit_order = " + str(recruit + 1));
	self.cc.query(query, self.query_done, "delete team");

    def discharge(self, widget = None):
	row = self.alliance_row;
	if None == row:
	    return;
	(ally, recruit) = self.alliance_last_filled;
	self.delete((row, recruit));

    def draft(self, widget = None):
	if 0 == len(self.team_pool):
	    return;
	team_number = random.choice(self.team_pool);
	self.add("draft team", team_number);

    def promote(self, widget = None):
	(ally, recruit) = self.alliance_next_empty;
	if (None == self.alliance_row or 1 != recruit or
	    self.alliance_row <= ally):
	    return;
	team = self.alliance_store[self.alliance_row][1];
	if None == team or len(team) < 1 or 0 == int(team):
	    return;
	new_captain = None;
	for row in self.teampool_store:
	    team = row[1];
	    if None == team or len(team) < 1:
		break;
	    team_number = int(team);
	    if team_number < 1:
		break;
	    if team_number in self.team_pool:
		new_captain = team_number;
		break;
	row = str(self.alliance_row + 1);
	queries = ["BEGIN",
		"UPDATE finals_alliance_partner SET" +
		 " finals_alliance_number = " + str(ally + 1) +
		 ", recruit_order = 2 WHERE finals_alliance_number =" +
		row + " AND recruit_order = 1",
		"UPDATE finals_alliance_partner SET" +
		" finals_alliance_number = finals_alliance_number - 1" +
		" WHERE finals_alliance_number > " + row
		];
	if None != new_captain:
	    queries.append("INSERT INTO finals_alliance_partner" +
		" (finals_alliance_number, recruit_order, team_number)" +
		" VALUES (" + str(FINALS_ALLIANCES) + ", 1, " +
		str(new_captain) + ")");
	queries.append("COMMIT");
	self.cc.query(queries, self.query_done, "promote team");

    def clear(self, widget = None):
	(ally, recruit) = self.alliance_last_filled;
	if ally >= 0 or recruit >= 0:
	    text = ("Are you sure you wish to clear the alliances?  " +
		"This operation cannot be undone!");
	    if not gtk_alert_question(text):
		return;
	self.alliances_seeded = False;
	query = "DELETE FROM finals_alliance_partner";
	self.cc.query(query, self.query_done, "clear alliances");

    def generate(self, widget = None):
	text = ("Are you sure you wish to (re)generate all the finals " +
		"matches?  This operation will erase all (if any) " +
		"current finals matches!");
	if not gtk_alert_question(text):
	    return;
	self.ladder.generate_finals_matches(self.nav.get_ranges);

    def query_done(self, results, message):
	for result in results:
	    if result.type == query_result.TYPE_ERROR:
		gtk_alert_error("<b>Unable to " + message +
				":</b>\n\n" + result.msg);
		break;

    def save_match_callback(self, number):
	if None != self.ladder:
	    self.ladder.build_ladder();
