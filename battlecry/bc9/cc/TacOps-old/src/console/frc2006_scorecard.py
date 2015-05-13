#!/usr/bin/env python

from copy import copy;
import gtk;
from gtk_helper import *;
from cc_client import cc_client;
from frc2006_tables import *;
from frc2006_rules import *;


class scorecard:
    def __init__(self, cc = None, container = None):
#	if not isinstance(cc, cc_client):
#	    raise Exception("scorecard currently requires a cc_client");
	self.current = game_match();
	self.saved = None;
	self.last = None;
	if None == container:
	    container = gtk.Window(gtk.WINDOW_TOPLEVEL);
	    container.set_border_width(4);
	    container.set_title("FRC 2006 ScoreCard");
	    container.show();
	self.container = container;
	self.frame = gtk.Frame("");
	label = self.frame.get_label_widget();
	label.set_markup("<span size=\"16000\" color=\"#FF3333\"><i>Aim High</i></span>");
	self.frame.set_label_align(0.5, 0.5);
	card = gtk.Table(rows=11, columns=7);
	card.set_row_spacings(2);
	self.frame.add(card);
	self.alliance = {COLOR_BLUE: obj(), COLOR_RED: obj()};
	self.alliance[COLOR_BLUE].COLUMN = 0;
	self.alliance[COLOR_RED].COLUMN = 5;
	OPTS = gtk.EXPAND | gtk.FILL;
	HEAVY_LABEL10 = "<span weight=\"heavy\" variant=\"smallcaps\" size=\"10000\">";
	theme = gtk.IconTheme();
	for color in [COLOR_NONE, COLOR_BLUE, COLOR_RED]:
	    if COLOR_NONE != color:
		column = self.alliance[color].COLUMN;
		self.alliance[color].scores = {};
		self.alliance[color].team_num = {};
		self.alliance[color].team_DQ = {};
	    else:
		for row in range(1, 8):
		    arrow = gtk.Arrow(gtk.ARROW_LEFT, gtk.SHADOW_OUT);
		    arrow.set_size_request(20, 20);
		    card.attach(arrow, 2, 3, row, row + 1, xoptions=OPTS, yoptions=OPTS);
		    arrow = gtk.Arrow(gtk.ARROW_RIGHT, gtk.SHADOW_OUT);
		    arrow.set_size_request(20, 20);
		    card.attach(arrow, 4, 5, row, row + 1, xoptions=OPTS, yoptions=OPTS);
	    row = 0;	## labels
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
		card.attach(label, column, column + 2, row, row + 1, xoptions=OPTS, yoptions=OPTS);

	    row += 1;	## goals
	    if COLOR_NONE == color:
		label = gtk.Label();
		label.set_markup(HEAVY_LABEL10 + "goals</span>");
		card.attach(label, 3, 4, row, row + 1, xoptions=OPTS, yoptions=OPTS);
	    else:
		frame = gtk.Frame();
		card.attach(frame, column, column + 2, row, row + 1, xoptions=OPTS, yoptions=OPTS,
				ypadding=4);
		table = gtk.Table(rows=2, columns=2);
		frame.add(table);
		if column < 3:
		    col = 1;
		else:
		    col = 0;
		label = gtk.Label("center");
		table.attach(label, col, col + 1, 0, 1);
		label = gtk.Label("side");
		table.attach(label, col, col + 1, 1, 2);
		col = 1 - col;
		spin = gtk.SpinButton(climb_rate=1.0);
		spin.set_increments(1, 10);
		spin.set_numeric(True);
		spin.set_range(0, 999);
		spin.set_update_policy(gtk.UPDATE_IF_VALID);
		table.attach(spin, col, col + 1, 0, 1);
		spin.connect("value-changed", self.changed, color, SCORE_CENTER_GOAL);
		self.alliance[color].scores[SCORE_CENTER_GOAL] = spin;
		spin = gtk.SpinButton(climb_rate=1.0);
		spin.set_increments(1, 10);
		spin.set_numeric(True);
		spin.set_range(0, 999);
		spin.set_update_policy(gtk.UPDATE_IF_VALID);
		table.attach(spin, col, col + 1, 1, 2);
		spin.connect("value-changed", self.changed, color, SCORE_SIDE_GOAL);
		self.alliance[color].scores[SCORE_SIDE_GOAL] = spin;

	    row += 1;	## platforms
	    if COLOR_NONE == color:
		label = gtk.Label();
		label.set_markup(HEAVY_LABEL10 + "on platforms</span>");
		card.attach(label, 3, 4, row, row + 1, xoptions=OPTS, yoptions=OPTS);
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
		card.attach(label, col, col + 1, row, row + 1, xoptions=OPTS, yoptions=OPTS);
		if column < 3:
		    col = 1;
		else:
		    col = 5;
		cbox = gtk.combo_box_new_text();
		for n in range(0, 4):
		    cbox.append_text(str(n));
		cbox.set_active(0);
		card.attach(cbox, col, col + 1, row, row + 1, xoptions=OPTS, yoptions=OPTS);
		cbox.connect("changed", self.changed, color, SCORE_ROBOTS);
		self.alliance[color].scores[SCORE_ROBOTS] = cbox;

	    row += 1;	## autonomous bonus
	    if COLOR_NONE == color:
		label = gtk.Label();
		label.set_markup(HEAVY_LABEL10 + "autonomous bonus</span>");
		ebox = gtk.EventBox();
		ebox.add(label);
		card.attach(ebox, 3, 4, row, row + 1, xoptions=OPTS, yoptions=OPTS);
		self.no_auton_bonus = gtk.RadioButton();
		ebox.connect("button-press-event", self.bonus_reset, SCORE_AUTON_BONUS);
	    else:
		radio = gtk.RadioButton(group=self.no_auton_bonus, label="10");
		card.attach(radio, column, column + 2, row, row + 1, xoptions=0, yoptions=OPTS);
		radio.connect("clicked", self.changed, color, SCORE_AUTON_BONUS);
		self.alliance[color].scores[SCORE_AUTON_BONUS] = radio;

	    row += 1;	## toggle bonus
	    if COLOR_NONE == color:
		label = gtk.Label();
		label.set_markup(HEAVY_LABEL10 + "toggle bonus</span>");
		ebox = gtk.EventBox();
		ebox.add(label);
		card.attach(ebox, 3, 4, row, row + 1, xoptions=OPTS, yoptions=OPTS);
		self.no_toggle_bonus = gtk.RadioButton();
		ebox.connect("button-press-event", self.bonus_reset, SCORE_TOGGLE_BONUS);
	    else:
		radio = gtk.RadioButton(group=self.no_toggle_bonus, label="15");
		card.attach(radio, column, column + 2, row, row + 1, xoptions=0, yoptions=OPTS);
		self.alliance[color].scores[SCORE_TOGGLE_BONUS] = radio;
		radio.connect("clicked", self.changed, color, SCORE_TOGGLE_BONUS);

	    row += 1;	## penalties
	    if COLOR_NONE == color:
		label = gtk.Label();
		label.set_markup(HEAVY_LABEL10 + "penalties</span>");
		card.attach(label, 3, 4, row, row + 1, xoptions=OPTS, yoptions=OPTS);
	    else:
		spin = gtk.SpinButton(climb_rate=1.0);
		spin.set_increments(1, 10);
		spin.set_numeric(True);
		spin.set_range(0, 99);
		spin.set_update_policy(gtk.UPDATE_IF_VALID);
		card.attach(spin, column, column + 2, row, row + 1, xoptions=OPTS, yoptions=OPTS);
		self.alliance[color].scores[SCORE_PENALTY] = spin;
		spin.connect("value-changed", self.changed, color, SCORE_PENALTY);

	    row += 1;	## DQs
	    if COLOR_NONE == color:
		label = gtk.Label();
		label.set_markup(HEAVY_LABEL10 + "DQs</span>");
		card.attach(label, 3, 4, row, row + 1, xoptions=OPTS, yoptions=OPTS);
	    else:
		buttons = gtk.HBox(homogeneous=True);
		icon = theme.load_icon("stock_not", 20, 0);
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
		card.attach(buttons, column, column + 2, row, row + 1, xoptions=OPTS, yoptions=OPTS);

	    row += 1;	## horizontal divider
	    if COLOR_NONE == color:
		sep = gtk.HSeparator();
		card.attach(sep, 2, 5, row, row + 1, xoptions=OPTS, yoptions=OPTS, ypadding=4);

	    row += 1;	## (net) scores
	    if COLOR_NONE == color:
		label = gtk.Label();
		label.set_markup(HEAVY_LABEL10 + "Scores</span>");
		card.attach(label, 2, 5, row, row + 1, xoptions=OPTS, yoptions=OPTS);
	    else:
		frame = gtk.Frame();
		frame.set_shadow_type(gtk.SHADOW_ETCHED_OUT);
		label = gtk.Label("");
		frame.add(label);
		self.alliance[color].net_score = label;
		card.attach(frame, column, column + 2, row, row + 1, xoptions=OPTS, yoptions=OPTS);

	    row += 1;	## raw scores
	    if COLOR_NONE == color:
		label = gtk.Label();
		markup = ("<span weight=\"heavy\" size=\"8000\" variant=\"smallcaps\">" +
			"(raw score)</span>");
		label.set_markup(markup);
		card.attach(label, 2, 5, row, row + 1, xoptions=OPTS, yoptions=OPTS);
	    else:
		label = gtk.Label("");
		self.alliance[color].raw_score = label;
		card.attach(label, column, column + 2, row, row + 1, xoptions=OPTS, yoptions=OPTS);

	    row += 1;	## winner
	    if COLOR_NONE == color:
		label = gtk.Label();
		self.tie = label;
		card.attach(label, 2, 5, row, row + 1, xoptions=OPTS, yoptions=OPTS);
	    else:
		label = gtk.Label();
		self.alliance[color].winner = label;
		card.attach(label, column, column + 2, row, row + 1, xoptions=OPTS, yoptions=OPTS);

	vbox = gtk.VBox(spacing=4);
	vbox.set_border_width(4);
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
	label.set_markup(HEAVY_LABEL10 + "save\nscores</span>");
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
	container.add(vbox);
	vbox.show_all();
	self.refresh();

    def update_buttons(self):
	flag = bool(self);
	self.buttons["save"].set_sensitive(flag);
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
	self.no_auton_bonus.set_active(True);
	self.no_toggle_bonus.set_active(True);
	for color in COLORS:
	    for el in [SCORE_CENTER_GOAL, SCORE_SIDE_GOAL, SCORE_PENALTY]:
		spin = self.alliance[color].scores[el];
		spin.set_value(self.current.alliance[color].scores[el]);
	    el = SCORE_ROBOTS;
	    cbox = self.alliance[color].scores[el];
	    cbox.set_active(self.current.alliance[color].scores[el]);
	    for el in [SCORE_AUTON_BONUS, SCORE_TOGGLE_BONUS]:
		radio = self.alliance[color].scores[el];
		if color == self.current.alliance[color].scores[el]:
		    radio.set_active(True);
	    for position in POSITIONS:
		label = self.alliance[color].team_num[position];
		num = self.current.alliance[color].team[position].team_number;
		text = "<tt>%5d</tt>" % (num);
		label.set_markup(text);
		button = self.alliance[color].team_DQ[position];
		flag = self.current.alliance[color].team[position].flags;
		button.set_active(flag & FLAG_DQ);
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
	if (position > 0):
	    attrib = "DQ #" + str(position);
#	print "changed " + COLORS_NAMES[color] + "." + str(attrib);
	if attrib in [SCORE_CENTER_GOAL, SCORE_SIDE_GOAL, SCORE_PENALTY]:
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
	self.saved = copy(self.current);
	self.refresh();

    def revert(self, widget, data = None):
	self.current = copy(self.saved);
	self.refresh();

    def clear(self, widget, data = None):
	self.current.clear();
	self.refresh();

    def unscore(self, widget, data = None):
	self.current.match_status = STATUS_PLAYED;
	self.saved = copy(self.current);
	self.refresh();
