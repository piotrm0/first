#!/usr/bin/env python

import random;
from gtk_utils import *;
from cc_client import cc_client;
from frc2006_tables import *;
from frc2006_rules import *;

class scorecard:
    OPTS = gtk.EXPAND | gtk.FILL;
    HEAVY_LABEL10 = "<span weight=\"heavy\" variant=\"smallcaps\" size=\"10000\">";

    def __init__(self):
	self.ccenter = None;
	self.nav = None;
	self.match_state = "";
	self.on_save = None;
	progress.register(2, self.setup_frame);
	progress.register(2, self.setup_arrows);
	for row in range(0, 11):
	    progress.register(2, self.setup_iter);
	progress.register(5, self.setup_match_info);
	progress.register(1, self.refresh);
	self.alliance = {COLOR_BLUE: obj(), COLOR_RED: obj()};
	self.alliance[COLOR_BLUE].COLUMN = 0;
	self.alliance[COLOR_RED].COLUMN = 5;
	self.current = game_match();
	self.saved = copy(self.current);
	self.last = None;
	self.row = 0;

    def setup_frame(self):
	self.container = gtk.VBox(spacing=4);
	self.container.set_border_width(4);
	self.container.set_sensitive(False);
	self.frame = gtk.Frame("");

	label = self.frame.get_label_widget();
	label.set_markup("<span size=\"16000\" color=\"#FF3333\"><i>Aim High</i></span>");
	self.frame.set_label_align(0.5, 0.5);
	self.card = gtk.Table(rows=11, columns=7);
	self.card.set_row_spacings(2);
	self.frame.add(self.card);
	self.theme = gtk.IconTheme();

	for color in [COLOR_BLUE, COLOR_RED]:
	    self.alliance[color].scores = {};
	    self.alliance[color].team_num = {};
	    self.alliance[color].team_DQ = {};

    def setup_arrows(self):
	for row in range(1, 7):
	    arrow = gtk.Arrow(gtk.ARROW_LEFT, gtk.SHADOW_OUT);
	    arrow.set_size_request(20, 20);
	    self.card.attach(arrow, 2, 3, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
	    arrow = gtk.Arrow(gtk.ARROW_RIGHT, gtk.SHADOW_OUT);
	    arrow.set_size_request(20, 20);
	    self.card.attach(arrow, 4, 5, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);

    def setup_iter(self):
	row = self.row;
	self.row += 1;
	for color in [COLOR_NONE, COLOR_BLUE, COLOR_RED]:
	    if COLOR_NONE != color:
		column = self.alliance[color].COLUMN;

	    if 0 == row:	## labels
	      if COLOR_NONE != color:
		label = gtk.Label();
		markup = ("<span size=\"12000\" color=\"" + COLORS_NAMES[color].lower() +
			"\"><b>" + COLORS_NAMES[color].upper() + "</b></span>");
		label.set_markup(markup);
		if column < 3:
			xalign = 0.0;
		else:
			xalign = 1.0;
		label.set_alignment(xalign, 1.0);
		self.card.attach(label, column, column + 2, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
	      continue;

	    if 1 == row:	## goals
	      if COLOR_NONE == color:
		label = gtk.Label();
		label.set_markup(self.HEAVY_LABEL10 + "goals</span>");
		self.card.attach(label, 3, 4, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
	      else:
		frame = gtk.Frame();
		self.card.attach(frame, column, column + 2, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS,
				ypadding=4);
		table = gtk.Table(rows=3, columns=2);
		frame.add(table);
		if column < 3:
		    col = 1;
		else:
		    col = 0;
		label = gtk.Label("far");
		table.attach(label, col, col + 1, 0, 1);
		label = gtk.Label("center");
		table.attach(label, col, col + 1, 1, 2);
		label = gtk.Label("near");
		table.attach(label, col, col + 1, 2, 3);
		col = 1 - col;
		spin = gtk.SpinButton(climb_rate=1.0);
		spin.set_alignment(1.0);
		spin.set_increments(1, 10);
		spin.set_numeric(True);
		spin.set_range(0, 99);
		spin.set_update_policy(gtk.UPDATE_IF_VALID);
		table.attach(spin, col, col + 1, 0, 1);
		spin.connect("value-changed", self.changed, color, SCORE_FAR_GOAL);
		self.alliance[color].scores[SCORE_FAR_GOAL] = spin;
		spin = gtk.SpinButton(climb_rate=1.0);
		spin.set_alignment(1.0);
		spin.set_increments(1, 10);
		spin.set_numeric(True);
		spin.set_range(0, 99);
		spin.set_update_policy(gtk.UPDATE_IF_VALID);
		table.attach(spin, col, col + 1, 1, 2);
		spin.connect("value-changed", self.changed, color, SCORE_CENTER_GOAL);
		self.alliance[color].scores[SCORE_CENTER_GOAL] = spin;
		spin = gtk.SpinButton(climb_rate=1.0);
		spin.set_alignment(1.0);
		spin.set_increments(1, 10);
		spin.set_numeric(True);
		spin.set_range(0, 99);
		spin.set_update_policy(gtk.UPDATE_IF_VALID);
		table.attach(spin, col, col + 1, 2, 3);
		spin.connect("value-changed", self.changed, color, SCORE_NEAR_GOAL);
		self.alliance[color].scores[SCORE_NEAR_GOAL] = spin;
	      continue;

	    if 2 == row:	## platforms
	      if COLOR_NONE == color:
		label = gtk.Label();
		label.set_markup(self.HEAVY_LABEL10 + "on platforms</span>");
		self.card.attach(label, 3, 4, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
	      else:
		if column < 3:
		    col = 0;
		else:
		    col = 6;
		label = gtk.Label();
		rgb = COLORS_RGB[color];
		rgb = color2hex(map(lambda x: x | 0x88, rgb));
		markup = ("<span background=\"#" + rgb + "\" weight=\"heavy\" size=\"10000\">" +
			" B<span size=\"8000\">OTS</span> </span>");
		label.set_markup(markup);
		self.card.attach(label, col, col + 1, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
		if column < 3:
		    col = 1;
		else:
		    col = 5;
		cbox = gtk.combo_box_new_text();
		for n in range(0, 4):
		    cbox.append_text(str(n));
		cbox.set_active(0);
		self.card.attach(cbox, col, col + 1, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
		cbox.connect("changed", self.changed, color, SCORE_ROBOTS);
		self.alliance[color].scores[SCORE_ROBOTS] = cbox;
	      continue;

	    if 3 == row:	## autonomous bonus
	      if COLOR_NONE == color:
		label = gtk.Label();
		label.set_markup(self.HEAVY_LABEL10 + "autonomous bonus</span>");
		ebox = gtk.EventBox();
		ebox.add(label);
		self.card.attach(ebox, 3, 4, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
		self.no_auton_bonus = gtk.RadioButton();
		ebox.connect("button-press-event", self.bonus_reset, SCORE_AUTON_BONUS);
	      else:
		radio = gtk.RadioButton(group=self.no_auton_bonus, label=None);
		self.card.attach(radio, column, column + 2, row, row + 1, xoptions=0, yoptions=self.OPTS);
		radio.connect("clicked", self.changed, color, SCORE_AUTON_BONUS);
		self.alliance[color].scores[SCORE_AUTON_BONUS] = radio;
	      continue;

	    if 4 == row:	## toggle bonus
	      if COLOR_NONE == color:
		label = gtk.Label();
		label.set_markup(self.HEAVY_LABEL10 + "toggle bonus</span>");
		ebox = gtk.EventBox();
		ebox.add(label);
		self.card.attach(ebox, 3, 4, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
		self.no_toggle_bonus = gtk.RadioButton();
		ebox.connect("button-press-event", self.bonus_reset, SCORE_TOGGLE_BONUS);
	      else:
		radio = gtk.RadioButton(group=self.no_toggle_bonus, label=None);
		self.card.attach(radio, column, column + 2, row, row + 1, xoptions=0, yoptions=self.OPTS);
		self.alliance[color].scores[SCORE_TOGGLE_BONUS] = radio;
		radio.connect("clicked", self.changed, color, SCORE_TOGGLE_BONUS);
	      continue;

	    if 5 == row:	## penalties
	      if COLOR_NONE == color:
		label = gtk.Label();
		label.set_markup(self.HEAVY_LABEL10 + "penalties</span>");
		self.card.attach(label, 3, 4, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
	      else:
		spin = gtk.SpinButton(climb_rate=1.0);
		spin.set_alignment(1.0);
		spin.set_increments(1, 10);
		spin.set_numeric(True);
		spin.set_range(0, 99);
		spin.set_update_policy(gtk.UPDATE_IF_VALID);
		self.card.attach(spin, column, column + 2, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
		self.alliance[color].scores[SCORE_PENALTY] = spin;
		spin.connect("value-changed", self.changed, color, SCORE_PENALTY);
	      continue;

	    if 6 == row:	## DQs
	      if COLOR_NONE == color:
		label = gtk.Label();
		label.set_markup(self.HEAVY_LABEL10 + "DQs</span>");
		self.card.attach(label, 3, 4, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
	      else:
		buttons = gtk.HBox(homogeneous=True);
		icon = self.theme.load_icon("stock_not", 20, 0);
		for position in POSITIONS:
		    button = gtk.ToggleButton();
		    hbox = gtk.HBox();
		    image = gtk.Image();
		    image.set_from_pixbuf(icon);
		    hbox.pack_start(image, expand=False, fill=False);
		    label = gtk.Label("9999");
		    hbox.pack_start(label, expand=False, fill=False);
		    self.alliance[color].team_num[position] = label;
		    button.add(hbox);
		    buttons.pack_start(button, expand=False);
		    self.alliance[color].team_DQ[position] = button;
		    button.connect("toggled", self.changed, color, None, position);
		self.card.attach(buttons, column, column + 2, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
	      continue;

	    if 7 == row:	## horizontal divider
	      if COLOR_NONE == color:
		sep = gtk.HSeparator();
		self.card.attach(sep, 2, 5, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS, ypadding=4);
	      continue;

	    if 8 == row:	## (net) scores
	      if COLOR_NONE == color:
		label = gtk.Label();
		label.set_markup(self.HEAVY_LABEL10 + "Scores</span>");
		self.card.attach(label, 2, 5, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
	      else:
		frame = gtk.Frame();
		frame.set_shadow_type(gtk.SHADOW_ETCHED_OUT);
		label = gtk.Label("");
		frame.add(label);
		self.alliance[color].net_score = label;
		self.card.attach(frame, column, column + 2, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
	      continue;

	    if 9 == row:	## raw scores
	      if COLOR_NONE == color:
		label = gtk.Label();
		markup = ("<span weight=\"heavy\" size=\"8000\" variant=\"smallcaps\">" +
			"(raw score)</span>");
		label.set_markup(markup);
		self.card.attach(label, 2, 5, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
	      else:
		label = gtk.Label("");
		self.alliance[color].raw_score = label;
		self.card.attach(label, column, column + 2, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
	      continue;

	    if 10 == row:	## winner
	      if COLOR_NONE == color:
		label = gtk.Label();
		self.tie = label;
		self.card.attach(label, 2, 5, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
	      else:
		label = gtk.Label();
		self.alliance[color].winner = label;
		self.card.attach(label, column, column + 2, row, row + 1, xoptions=self.OPTS, yoptions=self.OPTS);
	      continue;

    def setup_match_info(self):
	vbox = self.container;
	vbox.pack_start(self.frame, expand=True, fill=True);

	# match info
	hbox = gtk.HBox(homogeneous=True, spacing=16);
	frame = gtk.Frame(label="Match");
	label = frame.get_label_widget();
	label.set_padding(4, 0);
	frame.set_shadow_type(gtk.SHADOW_ETCHED_OUT);
	self.match_label = gtk.Label();
	frame.add(self.match_label);
	hbox.pack_start(frame, expand=True, fill=True);
	frame = gtk.Frame(label="status");
	label = frame.get_label_widget();
	label.set_padding(4, 0);
	frame.set_shadow_type(gtk.SHADOW_ETCHED_OUT);
	self.status_label = gtk.Label();
	frame.add(self.status_label);
	hbox.pack_start(frame, expand=True, fill=True);
	vbox.pack_start(hbox, expand=True, fill=True);

	# buttons
	self.buttons = {};
	buttons = gtk.HButtonBox();
	buttons.set_border_width(4);
	button = gtk.Button();
	hbox = gtk.HBox(spacing=2);
	icon = gtk.image_new_from_stock(gtk.STOCK_FLOPPY, gtk.ICON_SIZE_DND);
	hbox.pack_start(icon, expand=False, fill=False);
	label = gtk.Label();
	label.set_markup(self.HEAVY_LABEL10 + "save\nscores</span>");
	hbox.pack_start(label, expand=True, fill=True);
	button.add(hbox);
	buttons.add(button);
	self.buttons["save"] = button;
	button.connect("clicked", self.save, None);
	button = gtk.Button();
	hbox = gtk.HBox(spacing=2);
	icon = gtk.image_new_from_stock(gtk.STOCK_UNDELETE, gtk.ICON_SIZE_DND);
	hbox.pack_start(icon, expand=False, fill=False);
	label = gtk.Label();
	label.set_markup("<span size=\"10000\">revert\nscores</span>");
	hbox.pack_start(label, expand=True, fill=True);
	button.add(hbox);
	buttons.add(button);
	self.buttons["revert"] = button;
	button.connect("clicked", self.revert, None);
	button = gtk.Button();
	hbox = gtk.HBox(spacing=2);
	icon = gtk.image_new_from_stock(gtk.STOCK_CLEAR, gtk.ICON_SIZE_DND);
	hbox.pack_start(icon, expand=False, fill=False);
	label = gtk.Label();
	label.set_markup("<span size=\"10000\">clear\nscores</span>");
	hbox.pack_start(label, expand=True, fill=True);
	button.add(hbox);
	buttons.add(button);
	self.buttons["clear"] = button;
	button.connect("clicked", self.clear, None);
	button = gtk.Button();
	hbox = gtk.HBox(spacing=2);
	icon = gtk.image_new_from_stock(gtk.STOCK_CANCEL, gtk.ICON_SIZE_DND);
	hbox.pack_start(icon, expand=False, fill=False);
	label = gtk.Label();
	label.set_markup("<span size=\"10000\">unscore\nmatch</span>");
	hbox.pack_start(label, expand=True, fill=True);
	button.add(hbox);
	buttons.add(button);
	self.buttons["unscore"] = button;
	button.connect("clicked", self.unscore, None);
	vbox.pack_start(buttons, expand=True, fill=True);

	# widget creation done
	vbox.show_all();

    def connect(self, cc = None):
	if not isinstance(cc, cc_client):
	    raise Exception("scorecard currently requires a cc_client");
	self.ccenter = cc;
	self.ccenter.env_watch("match_state", self.status_changed);
#	self.ccenter.env_watch("all_submitted", self.rts_submitted);
#	for color in ["red", "blue"]:
#	    for goal in ["near", "center", "far"]:
#		self.ccenter.env_watch(color + "_" + goal, self.rts_update);

    def update_buttons(self):
	flag = bool(self);
	if None != self.nav and None != self.nav.container:
	    self.nav.container.set_sensitive(True);
#	    self.nav.container.set_sensitive(not flag);
#	self.buttons["save"].set_sensitive(flag);
	self.buttons["save"].set_sensitive(True);
	self.buttons["revert"].set_sensitive(flag);
	flag = bool(self.current);
	self.buttons["clear"].set_sensitive(flag);
	flag = STATUS_SCORED == self.current.match_status;
	self.buttons["unscore"].set_sensitive(flag);

    def __nonzero__(self):
	return not (self.current == self.saved);

    def refresh(self):
	if not isinstance(self.current, game_match):
	    return;
	(match_level, match_number, match_index) = self.current.match_number;
	level = LEVEL_NAMES[match_level];
	text = level[1] + " " + str(match_number);
	if match_level > LEVEL_QUAL:
	    text += "." + str(match_index);
	self.match_label.set_text(text);
#	self.no_auton_bonus.set_active(True);
#	self.no_toggle_bonus.set_active(True);
	for color in COLORS:
	    for el in [SCORE_FAR_GOAL, SCORE_CENTER_GOAL, SCORE_NEAR_GOAL,
			SCORE_PENALTY]:
		spin = self.alliance[color].scores[el];
		spin.set_value(self.current.alliance[color].scores[el]);
	    el = SCORE_ROBOTS;
	    cbox = self.alliance[color].scores[el];
	    cbox.set_active(self.current.alliance[color].scores[el]);
	    for el in [SCORE_AUTON_BONUS, SCORE_TOGGLE_BONUS]:
#		print color, el, self.current.alliance[color].scores[el];
		radio = self.alliance[color].scores[el];
###		if color == self.current.alliance[color].scores[el]:
		if bool(self.current.alliance[color].scores[el]):
		    radio.set_active(True);
	    for position in POSITIONS:
		label = self.alliance[color].team_num[position];
		num = self.current.alliance[color].team[position].team_number;
		text = "<tt>%5d</tt>" % (num);
		label.set_markup(text);
		button = self.alliance[color].team_DQ[position];
		flag = self.current.alliance[color].team[position].flags;
		button.set_active(flag & FLAG_DQ);
		if None != self.ccenter:
		    var = COLORS_NAMES[color].lower() + "_team" + str(position);
		    self.ccenter.command("ENV " + var + "=" + str(num));
	self.update();
	self.update_buttons();

    def update(self):
	for color in COLORS:
	    label = self.alliance[color].net_score;
	    label.set_text(str(self.current.alliance[color].net_score));
	    label = self.alliance[color].raw_score;
	    label.set_text(str(self.current.alliance[color].raw_score));
	    label = self.alliance[color].winner;
	    text = "";
	    if color == self.current.winner:
		text = ("<span color=\"" + COLORS_NAMES[color].lower() +
			"\"><b>winner</b></span>");
	    label.set_markup(text);
	label = self.tie;
	text = "";
	if bool(self.current) and COLOR_NONE == self.current.winner:
	    text = "<span color=\"#474\"  weight=\"heavy\">  *   tie   *  </span>";
	label.set_markup(text);
	text = STATUS_TEXTS[self.current.match_status];
	self.status_label.set_text(text);
	

    def bonus_reset(self, widget, event, attrib = None):
	if not isinstance(event, gtk.gdk.Event):
	    return;
	radio = None;
	if attrib in [SCORE_AUTON_BONUS]:
	    radio = self.no_auton_bonus;
	if attrib in [SCORE_TOGGLE_BONUS]:
	    radio = self.no_toggle_bonus;
	if None == radio:
	    return;
	t = event.get_time();
	if None == self.last or (t - self.last > 250):
	    self.last = t;
	    return;
	radio.set_active(True);
	for color in COLORS:
	    self.changed(widget, color=color, attrib=attrib);

    def changed(self, widget, color = COLOR_NONE, attrib = None, position = 0):
#	if (position > 0):
#	    attrib = "DQ #" + str(position);
#	print "changed " + COLORS_NAMES[color] + "." + str(attrib);
	if attrib in [SCORE_FAR_GOAL, SCORE_CENTER_GOAL, SCORE_NEAR_GOAL,
			SCORE_PENALTY]:
	    spin = self.alliance[color].scores[attrib];
	    self.current.alliance[color].scores[attrib] = spin.get_value_as_int();
	if attrib in [SCORE_ROBOTS]:
	    cbox = self.alliance[color].scores[attrib];
	    self.current.alliance[color].scores[attrib] = cbox.get_active();
	if attrib in [SCORE_AUTON_BONUS, SCORE_TOGGLE_BONUS]:
	    radio = self.alliance[color].scores[attrib];
	    self.current.alliance[color].scores[attrib] = int(radio.get_active());
	if position > 0:
	    button = self.alliance[color].team_DQ[position];
	    flags = self.current.alliance[color].team[position].flags;
	    flags &= ~FLAG_DQ;
	    if button.get_active():
		flags |= FLAG_DQ;
	    self.current.alliance[color].team[position].flags = flags;
	self.current.score();
#	print self.current.__repr__();
	self.update();
	self.update_buttons();

    def save(self, widget, data = None):
	self.current.match_status = STATUS_SCORED;
	cc_save_match(self.ccenter, self.current, self.save_ack);

    def save_ack(self):
	self.saved = copy(self.current);
	if callable(self.on_save):
	    self.on_save(self.current.match_number);
	self.refresh();

    def revert(self, widget, data = None):
	text = "Are you sure you wish to revert to saved scores?";
	if gtk_alert_question(text):
	    self.current = copy(self.saved);
	    self.refresh();

    def clear(self, widget, data = None):
	text = "Are you sure you wish to clear all the scores?";
	if gtk_alert_question(text):
	    self.current.clear();
	    self.refresh();

    def unscore(self, widget, data = None):
	text = "Are you sure you wish to unscore this match?";
	if gtk_alert_question(text):
	    self.current.match_status = STATUS_RESCHED;
	    cc_save_match(self.ccenter, self.current, self.save_ack);
	    self.refresh();

    def change(self, number):
	self.container.set_sensitive(False);
	if None == number:
	    return;
	cc_load_match(self.ccenter, number, self.load_ack);

    def rts_update(self, key, old_value, new_value):
	if self.current.match_status >= STATUS_SCORED:
	    return;
	attrib = SCORE_UNKNOWN;
	[c_str, a_str] = key.split("_", 1);
	if c_str == COLORS_NAMES[COLOR_BLUE].lower():
	    color = COLOR_BLUE;
	elif c_str == COLORS_NAMES[COLOR_RED].lower():
	    color = COLOR_RED;
	else:
	    return;
	if a_str == "near":
	    attrib = SCORE_NEAR_GOAL;
	elif a_str == "center":
	    attrib = SCORE_CENTER_GOAL;
	elif a_str == "far":
	    attrib = SCORE_FAR_GOAL;
	else:
	    return;
	value = int(new_value);
	spin = self.alliance[color].scores[attrib];
	self.current.alliance[color].scores[attrib] = value;
	self.current.score();
	rts = self.current.alliance[color].rts;
	self.ccenter.command("ENV " + c_str + "_score=" + str(rts));
	spin.set_value(value);
	self.update();
	self.update_buttons();

    def rts_submitted(self, key, old_value, new_value):
	if self.current.match_status >= STATUS_SCORED:
	    return;
	if 1 != int(new_value):
	    return;
	if "paused" == self.match_state:
	    red_score = self.current.alliance[COLOR_RED].rts;
	    blue_score = self.current.alliance[COLOR_BLUE].rts;
	    if blue_score > red_score:
		winner = COLOR_BLUE;
	    elif red_score > blue_score:
		winner = COLOR_RED;
	    else:
		winner = random.choice(COLORS);
	    radio = self.alliance[winner].scores[SCORE_AUTON_BONUS];
	    radio.set_active(True);
	    winner = COLORS_NAMES[winner].lower();
	    self.ccenter.command("ENV autonomous_winner=" + winner);

    def status_changed(self, key, old_value, new_value):
	self.match_state = new_value;
	if "stopped" == new_value:
	    self.container.set_sensitive(True);
	elif "reset":
	    self.ccenter.command("ENV autonomous_winner=");
#	else:
#	    self.container.set_sensitive(False);
#	    self.nav.container.set_sensitive(False);

    def load_ack(self, match):
	self.saved = match;
	self.current = copy(self.saved);
	self.container.set_sensitive(True);
	self.refresh();
