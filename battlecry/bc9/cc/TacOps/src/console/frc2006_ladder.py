#!/usr/bin/env python

from gtk_utils import *;
from ladder_utils import *;
from frc2006_rules import *;


#
#  This implementation of a finals ladder is applicable only for
#  single-elimination, two-alliance finals.
#
class ladder:
    def __init__(self, alliance_store, navigator):
	self.cc = None;
	self.nav = navigator;
	self.alliance_store = alliance_store;
	self.finals_navigator = None;
	self.matches = [];
	self.buttons = {};
	progress.register(8 + 4 + 2 + 1, self.setup_navigator);

    def setup_navigator(self):
	self.finals_navigator = gtk.Window();
	self.finals_navigator.set_title("finals match navigator");
	self.finals_navigator.set_position(gtk.WIN_POS_CENTER_ALWAYS);
	self.finals_navigator.set_resizable(False);
	self.finals_navigator.set_size_request(1024, 512);
	self.finals_navigator.set_modal(True);
	self.finals_navigator.hide();
	vbox = gtk.VBox();
	buttons = gtk.HButtonBox();
	button = gtk.Button();
	hbox = gtk.HBox(spacing=2);
	icon = gtk.image_new_from_stock(gtk.STOCK_CANCEL, gtk.ICON_SIZE_DND)
	hbox.pack_start(icon, expand=False, fill=False);
	label = gtk_label_from_markup("<b>Cancel</b>");
	hbox.pack_start(label, expand=True, fill=True);
	button.add(hbox);
	buttons.add(button);
	button.connect("clicked", self.hide_navigator);
	vbox.pack_end(buttons, expand=True, fill=True, padding=4);
	frame = gtk.Frame("Finals Matches");
	frame.set_label_align(0.5, 0.5);
	frame.set_shadow_type(gtk.SHADOW_ETCHED_IN);
	fixed = gtk.Fixed();
	frame.add(fixed);
	vbox.pack_end(frame, expand=True, fill=True);
	self.finals_navigator.add(vbox);

	label = gtk_label_from_markup("<b><i>Championship</i></b>");
	label.set_alignment(0.5, 1.0);
	label.set_size_request(172, 40);
	fixed.put(label, 420, 0);
	frame = gtk.Frame();
	frame.set_shadow_type(gtk.SHADOW_ETCHED_IN);
	hbox = gtk.HBox();
	level = LEVEL_F;
	for n in (1, 2, 3):
	    label = str(n);
	    button = gtk.Button(label);
	    button.set_size_request(48, 48);
	    button.connect("clicked", self.navigate, (level, n, 0));
	    hbox.pack_start(button, expand=False, fill=False);
	    self.buttons[(level, n, 0)] = button;
	frame.add(hbox);
	fixed.put(frame, 432, 40);
	self.put_arrow(fixed, 336, 64, "red");
	self.put_arrow(fixed, 592, 64, "blue");

	for number in (1, 2):
	    offset = (number - 1) << 9;		# times 512
	    label = gtk_label_from_markup("<b>Semi-finals</b>");
	    label.set_alignment(0.0, 1.0);
	    label.set_size_request(148, 48);
	    fixed.put(label, offset + 192, 80);
	    self.put_buttons(fixed, offset + 192, 128, LEVEL_SF, number);
	    self.put_arrow(fixed, offset + 104, 152, "red");
	    self.put_arrow(fixed, offset + 320, 152, "blue");

	for number in (1, 2, 3, 4):
	    offset = (number - 1) << 8;		# times 256
	    label = gtk.Label("Quarter-finals");
	    label.set_alignment(0.0, 1.0);
	    label.set_size_request(148, 48);
	    fixed.put(label, offset + 64, 208);
	    self.put_buttons(fixed, offset + 64, 256, LEVEL_QF, number);
	    self.put_arrow(fixed, offset + 24, 296, "red");
	    self.put_arrow(fixed, offset + 144, 296, "blue");
	    label = gtk.Label("Eighth-finals");
	    label.set_alignment(0.0, 1.0);
	    label.set_size_request(148, 48);
	    fixed.put(label, offset + 64, 336);

	for number in (1, 2, 3, 4, 5, 6, 7, 8):
	    offset = (number - 1) << 7;		# times 128
	    self.put_buttons(fixed, offset, 384, LEVEL_EF, number);

	vbox.show_all();

    def put_buttons(self, fixed, x, y, level, number):
	frame = gtk.Frame();
	frame.set_shadow_type(gtk.SHADOW_ETCHED_IN);
	hbox = gtk.HBox();
	for index in (1, 2, 3):
	    label = str(number) + "." + str(index);
	    button = gtk.Button(label);
	    button.set_size_request(40, 40);
	    button.connect("clicked", self.navigate, (level, number, index));
	    hbox.pack_start(button, expand=False, fill=False);
	    self.buttons[(level, number, index)] = button;
	frame.add(hbox);
	fixed.put(frame, x, y);

    def put_arrow(self, fixed, x, y, colorstr):
	image = gtk.Image();
	filename = colorstr + "-arrow45.png";
	icon = gtk.gdk.pixbuf_new_from_file(PIX_DIR + filename);
	image.set_from_pixbuf(icon);
	fixed.put(image, x, y + 4);

    def connect(self, cc):
	if not isinstance(cc, cc_client):
	    raise Exception("ladder requires a cc_client");
	self.cc = cc;
#	self.build_ladder();

    def show_navigator(self, widget = None):
	self.finals_navigator.show();

    def hide_navigator(self, widget = None):
	self.finals_navigator.hide();

    def navigate(self, widget, number):
	self.nav.nav_set(number);
	self.hide_navigator();

    def generate_finals_matches(self, callback = None):
	queries = [ "BEGIN",
		"DELETE FROM alliance_team WHERE match_level > 0",
		"DELETE FROM game_match WHERE match_level > 0" ];
	level_matches = 16;
	for level in range(LEVEL_QUAL + 1, LEVEL_F + 1):
	    level_matches >>= 1;
	    if level_matches > 4:
		index_matches = 2;
	    else:
		index_matches = 3;
	    index_range = range(1, index_matches + 1);
	    if LEVEL_F == level:
		index_range = [0];
		level_matches = 3;
	    for number in range(1, level_matches + 1):
		for index in index_range:
		    queries.append("INSERT INTO game_match " +
			"(match_level, match_number, match_index, " +
			" status_id) VALUES (" + str(level) + ", " +
			str(number) + ", " + str(index) + ", " +
			str(STATUS_SCHED) + ")");
		    for color in COLORS:
			for position in POSITIONS:
			  queries.append("INSERT INTO alliance_team " +
			    "(match_level, match_number, match_index," +
			    " alliance_color_id, position, team_number)" +
			    " VALUES (" + str(level) + ", " + str(number) +
			    ", " + str(index) + ", " + str(color) + ", " +
			    str(position) + ", 0)");
	queries.append("COMMIT");
	self.cc.query(queries, self.generate_finals_matches_done, callback);

    def generate_finals_matches_done(self, results, callback = None):
	for result in results:
	    if result.type == query_result.TYPE_ERROR:
		gtk_alert_error("<b>Unable to generate finals matches:</b>"
				+ "\n\n" + result.msg);
		break;
	self.build_ladder();
	if callable(callback):
	    callback();


    def build_ladder(self, ignore = None):
	print "building ladder..."
	queries = ("SELECT * FROM alliance_team WHERE match_level > 0" +
	     " ORDER BY match_level, match_number, match_index",
		   "SELECT * FROM game_match WHERE match_level > 0" +
	     " ORDER BY match_level, match_number, match_index");
	self.cc.query(queries, self.load_finals_matches);

    def load_finals_matches(self, results):
        result = None;
	for result in results:
	    if result.type == query_result.TYPE_ERROR:
		gtk_alert_error("<b>Unable to load finals matches:</b>\n\n" +
				result.msg);
	last_number = None;
	match = None;
	self.matches = [];
	result = results[0];
	rset = result.rset;
	i_level = rset.index_by_name["match_level"];
	i_number = rset.index_by_name["match_number"];
	i_index = rset.index_by_name["match_index"];
	i_color = rset.index_by_name["alliance_color_id"];
	i_position = rset.index_by_name["position"];
	i_team_num = rset.index_by_name["team_number"];
	for row in rset:
	    match_level = int(row[i_level]);
	    match_number = int(row[i_number]);
	    match_index = int(row[i_index]);
	    color = int(row[i_color]);
	    position = int(row[i_position]);
	    team_number = int(row[i_team_num]);
	    number = (match_level, match_number, match_index);
	    if last_number != number:
		last_number = number;
		match = game_match(number);
		self.matches.append(match);
	    match.alliance[color].team[position].team_number = team_number;
	result = results[1];
	rset = result.rset;
	i_level = rset.index_by_name["match_level"];
	i_number = rset.index_by_name["match_number"];
	i_index = rset.index_by_name["match_index"];
	i_winner = rset.index_by_name["winner_color_id"];
	for row in rset:
	    match_level = int(row[i_level]);
	    match_number = int(row[i_number]);
	    match_index = int(row[i_index]);
	    winner = int(row[i_winner]);
	    number = (match_level, match_number, match_index);
	    match = match_lookup(self.matches, number);
	    if None == match:
		continue;
	    match.winner = winner;
	self.changed_winners = [];
	self.changed_teams = [];
	self.ladder_fill_match(None, (LEVEL_F, 1, 0));
	self.save_finals_matches();

    def ladder_fill_match(self, win_alliance, number):
	(match_level, match_number, match_index) = number;
	matches = [];
	if LEVEL_F == match_level:
	    for n in (3, 2, 1):
		match = match_lookup(self.matches, (match_level, n, 0));
		if None == match:
		    print "NONE match", match_level, n;
		matches.insert(0, match);
	else:
	    index_matches = (3, 2, 1);
	    if LEVEL_EF == match_level:
		index_matches = (2, 1);
		self.update_ladder_button((match_level, match_number, 3), False);
	    for index in index_matches:
		match = match_lookup(self.matches, (match_level, match_number, index));
		if None == match:
		    print "NONE match", match_level, match_number, index;
		matches.insert(0, match);
	if match_level > LEVEL_QUAL + 1:
	    child_level = match_level - 1;
	    child_number = match_number;
#	    if 0 == match_number:	# why would this happen?
#		print "zero match number!";
#		child_number += 1;
	    child_number = ((child_number - 1) << 1) + 1;
	    child_index = 1;		# was match_index
	    child_match = (child_level, child_number, child_index);
	    alliance = match.alliance[COLOR_RED];
	    self.ladder_fill_match(alliance, child_match);
	    child_number += 1;
	    child_match = (child_level, child_number, child_index);
	    alliance = match.alliance[COLOR_BLUE];
	    self.ladder_fill_match(alliance, child_match);
	else:
	    for color in COLORS:
		if COLOR_RED == color:
		    offset = 0;
		elif COLOR_BLUE == color:
		    offset = 1;
		else:
		    break;
		path = ((match_number - 1) << 1) + offset;
		rev = path_reverse(path, 4);
		alliance = grey_find(rev);
		for position in POSITIONS:
		    if alliance < FINALS_ALLIANCES:
			team = self.alliance_store[alliance][position];
			if None == team or len(team) < 1:
			    team = 0;
			else:
			    team_number = int(team);
		    else:
			team_number = 0;
		    team = match.alliance[color].team[position];
		    if team.team_number != team_number:
			team.team_number = team_number;
			change = [number, color, position];
			self.changed_teams.append(change);

	enable = False;
	winner = COLOR_NONE;
	for position in POSITIONS:
	    team = {};
	    for color in COLORS:
		team[color] = match.alliance[color].team[position].team_number;
	    if 0 != team[COLOR_RED] or 0 != team[COLOR_BLUE]:
		enable = True;
		break;
	if not enable and LEVEL_EF == level:
	    print "yo";
	    for i in (1, 2, 3):
		self.update_ladder_button((level, match_number, i), False, COLOR_BLUE);
	if (0 != match.alliance[COLOR_RED].team[1].team_number and
	    0 == match.alliance[COLOR_BLUE].team[1].team_number):
	    if ((match_number - 1) & 1) > 0:
		winner = COLOR_BLUE;
	    else:
		winner = COLOR_RED;
	    for match in matches:
		self.update_ladder_button(match.match_number, False, winner);
	    winner = COLOR_RED;
	    enable = False;

	### determine winner
	if COLOR_NONE == winner and enable:
	    if match_level > LEVEL_EF:
		red_wins = 0;
		blue_wins = 0;
		for match in matches:
		    if COLOR_RED == match.winner:
			red_wins += 1;
		    if COLOR_BLUE == match.winner:
			blue_wins += 1;
		    self.update_ladder_button(match.match_number, True, match.winner);
	 	if 2 == blue_wins + red_wins:
		    enable = False;
		else:
		    enable = True;
		if red_wins > 1:
		    winner = COLOR_RED;
		elif blue_wins > 1:
		    winner = COLOR_BLUE;
		self.update_ladder_button(matches[-1].match_number, enable, winner);
	    else:
		red_score = 0;
		blue_score = 0;
		for match in matches:
		    red_score += match.alliance[COLOR_RED].net_score;
		    blue_score += match.alliance[COLOR_BLUE].net_score;
		if red_score > blue_score:
		    winner = COLOR_RED;
		elif blue_score > red_score:
		    winner = COLOR_BLUE;
		for match in matches:
		    self.update_ladder_button(match.match_number, True, winner);

	### propagate winner up
	if None == winner or None == win_alliance:
	    return;
	if COLOR_BLUE == winner:
	    alliance = match.alliance[COLOR_BLUE];
	elif COLOR_RED == winner:
	    alliance = match.alliance[COLOR_RED];
	else:
	    return;
	for position in POSITIONS:
	    team_number = alliance.team[position].team_number;
	    win_alliance.team[position].team_number = team_number;

    def save_finals_matches(self):
	queries = [];
	for number in self.changed_winners:
	    match = match_lookup(self.matches, number);
	    queries.append("UPDATE game_match SET"
			" winner_color_id = " + str(match.winner) +
			" WHERE match_level = " + str(match.match_level) +
			" AND match_number = " + str(match.match_number) +
			" AND match_index = " + str(match.match_index));
	self.changed_winners = [];
	for change in self.changed_teams:
	    (number, color, position) = change;
	    match = match_lookup(self.matches, number);
	    (match_level, match_number, match_index) = match.match_number;
	    team_number = match.alliance[color].team[position].team_number;
	    queries.append("UPDATE alliance_team SET" +
			" team_number = " + str(team_number) +
			" WHERE match_level = " + str(match_level) +
			" AND match_number = " + str(match_number) +
			" AND match_index = " + str(match_index) +
			" AND alliance_color_id = " + str(color) +
			" AND position = " + str(position));
	if len(queries) > 0:
	    self.cc.query(queries, self.save_finals_matches_done);
	else:
	    pass;
#	    self.update_nav_ladder();

    def save_finals_matches_done(self, results):
	for result in results:
	    if result.type == query_result.TYPE_ERROR:
		gtk_alert_error("<b>Unable to save finals matches:</b>"
				+ "\n\n" + result.msg);
		break;

    def update_ladder_button(self, number, enable, winner = COLOR_NONE):
	widget = self.buttons[number];
	if not isinstance(widget, gtk.Widget):
	    return;
	widget.set_sensitive(enable);
	rgb = COLORS_RGB[winner];
	if enable:
	    rgb = map(lambda x: x | 0x88, rgb);
	elif COLOR_NONE != winner:
	    rgb = map(lambda x: x & 0x7F, rgb);
	else:
	    rgb = (0x44, 0x44, 0x44);

	if COLOR_NONE == winner and enable:
	    color = None;
	else:
	    rgb = map(lambda x: (x << 8) | x, rgb);
	    color = gtk.gdk.Color(*rgb);
	states = (gtk.STATE_NORMAL, gtk.STATE_ACTIVE, gtk.STATE_SELECTED,
		  gtk.STATE_INSENSITIVE);
	for state in states:
	    widget.modify_bg(state, color);
