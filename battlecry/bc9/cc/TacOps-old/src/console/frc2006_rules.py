#!/usr/bin/env python

from copy import copy;
from frc2006_tables import *;
from cc_client import cc_client;


class alliance_team:
    def __init__(self, position = 0):
	self.position = position;
	self.team_number = 0;
	self.clear();

    def clear(self):
	self.flags = FLAG_NONE;
	self.score = 0;
	self.points = 0;

    def __copy__(self):
	ret = alliance_team(self.position);
	ret.team_number = self.team_number;
	ret.flags = self.flags;
	ret.score = self.score;
	ret.points = self.points;
	return ret;

    def __eq__(self, other):
	if (not isinstance(other, alliance_team) or self.position != other.position or
	    self.team_number != other.team_number or self.flags != other.flags or
	    self.score != other.score or self.points != other.points):
	    return False;
	return True;

    def __ne__(self, other):
	return not self.__eq__(other);

    def __repr__(self):
	text = "<team [" + str(self.position) + "] #" + str(self.team_number);
	if self.flags:
	    text += " (";
	    if self.flags & FLAG_DQ:
		text += "DQ";
	    if self.flags & FLAG_DONT_COUNT:
		text += "null";
	    text += ")";
	text += " = " + str(self.score) + " (" + str(self.points) + ")>";
	return text;

class match_alliance:
    ROBOTS_SCORES = [0, 5, 10, 25];

    def __init__(self, color = COLOR_NONE):
	self.color = color;
	self.team = {};
	for position in POSITIONS:
	    self.team[position] = alliance_team(position);
	self.clear();

    def clear(self):
	# scoring elements
	self.scores = {};
	for el in SCORES:
	    self.scores[el] = 0;
	for position in POSITIONS:
	    self.team[position].clear();
	self.raw_score = 0;
	self.net_score = 0;

    def __copy__(self):
	ret = match_alliance(self.color);
	for position in POSITIONS:
	    ret.team[position] = copy(self.team[position]);
	for el in SCORES:
	    ret.scores[el] = self.scores[el];
	ret.raw_score = self.raw_score;
	ret.net_score = self.net_score;
	return ret;

    def __eq__(self, other):
	if (not isinstance(other, match_alliance) or self.color != other.color or
	    self.raw_score != other.raw_score or self.net_score != other.net_score):
	    return False;
	for el in SCORES:
	    if self.scores[el] != other.scores[el]:
		return False;
	for position in POSITIONS:
	    if self.team[position] != other.team[position]:
		return False;
	return True;

    def __ne__(self, other):
	return not self.__eq__(other);

    def __nonzero__(self):
	for el in SCORES:
	    if self.scores[el]:
		return True;
	for position in POSITIONS:
	    if self.team[position].flags & FLAG_DQ:
		return True;
	return False;

    def __repr__(self):
	text = "<" + COLORS_NAMES[self.color] + ":";
	for position in POSITIONS:
	    text += " " + self.team[position].__repr__() + ",";
	text += "\n...";
	for el in SCORES:
	    text += " " + str(el) + "=" + str(self.scores[el]) + ",";
	text += "\n... raw = " + str(self.raw_score) + ", net = ";
	text += str(self.net_score) + ">";
	return text;

    def was_alliance_disqualified(self):
	num_DQs = 0;
	for position in POSITIONS:
	    if (self.team[position].flags & FLAG_DQ):
		num_DQs += 1;
	return (3 == num_DQs);

    def compute_score(self):
	self.raw_score = 3 * self.scores[SCORE_CENTER_GOAL] + self.scores[SCORE_SIDE_GOAL];
	if self.scores[SCORE_AUTON_BONUS]:
	    self.raw_score += 10;
	if self.scores[SCORE_TOGGLE_BONUS]:
	    self.raw_score += 15;
	self.raw_score += self.ROBOTS_SCORES[self.scores[SCORE_ROBOTS]];
	self.net_score = self.raw_score - 5 * self.scores[SCORE_PENALTY];
	if (self.net_score < 0):
	    self.net_score = 0;
	for position in POSITIONS:
	    score = self.net_score;
	    if (self.team[position].flags & FLAG_DQ):
		score = 0;
	    self.team[position].score = score;

    def set_points(self, points = 0):
	for position in POSITIONS:
	    if (self.team[position].flags & FLAG_DQ):
		self.team[position].points = 0;
	    else:
		self.team[position].points = points;

class game_match:
    def __init__(self, number = (LEVEL_PRAC, 0, 0)):
	self.match_number = number;
	self.alliance = {};
	for color in COLORS:
	    self.alliance[color] = match_alliance(color);
	self.clear();
 
    def clear(self):
	self.match_status = STATUS_NONE;
	self.winner = COLOR_NONE;
	for color in COLORS:
	    self.alliance[color].clear();

    def __copy__(self):
	ret = game_match(number=self.match_number);
	for color in COLORS:
	    ret.alliance[color] = copy(self.alliance[color]);
	ret.match_status = self.match_status;
	ret.winner = self.winner;
	return ret;

    def __eq__(self, other):
	if (not isinstance(other, game_match) or self.match_number != other.match_number or
	    self.match_status != other.match_status or self.winner != other.winner):
	    return False;
	for color in COLORS:
	    if self.alliance[color] != other.alliance[color]:
		return False;
	return True;

    def __ne__(self, other):
	return not self.__eq__(other);

    def __nonzero__(self):
	for color in COLORS:
	    if bool(self.alliance[color]):
		return True;
	return False;

    def __repr__(self):
	(level, number, index) = self.match_number;
	text = "<match " + LEVEL_NAMES[level][0] + " " + str(number);
	if index > 0:
	    text += "." + str(index);
	text += "\twinner = " + COLORS_NAMES[self.winner] + ">\n";
	for color in COLORS:
	    text += self.alliance[color].__repr__() + "\n";
	return text;

    # call this to compute the raw/net match scores
    def score(self):
	self.winner = COLOR_NONE;
#	if self.match_status < STATUS_PLAYED:
#	    return;
	for color in COLORS:
	    self.alliance[color].compute_score();
	if (self.alliance[COLOR_RED].net_score > self.alliance[COLOR_BLUE].net_score):
		self.winner = COLOR_RED;
	if (self.alliance[COLOR_RED].net_score < self.alliance[COLOR_BLUE].net_score):
		self.winner = COLOR_BLUE;
#	self.match_status = STATUS_SCORED;
	# determine points
	if COLOR_NONE == self.winner:
	    for color in COLORS:
		points = self.alliance[color].net_score;
		self.alliance[color].set_points(points);
	    return;
	lose_alliance = COLOR_RED + COLOR_BLUE - self.winner;
	lose_points = self.alliance[lose_alliance].net_score;
	if self.alliance[lose_alliance].was_alliance_disqualified():
	    win_points = self.alliance[self.winner].net_score;
	else:
	    win_points = min(self.alliance[self.winner].raw_score, self.alliance[lose_alliance].raw_score);
	for color in COLORS:
	    if color == self.winner:
		self.alliance[color].set_points(win_points);
	    else:
		self.alliance[color].set_points(lose_points);


# passed back as callback_fn(match)
def cc_load_match(cc, number, callback_fn):
    if not callable(callback_fn):
	raise Exception("argument #3 to cc_load_match is not a callback");
    (match_level, match_number, match_index) = number;
    match = game_match(number);
    match.on_load = callback_fn;
    where = (" WHERE match_level = " + str(match_level) +
	" AND match_number = " + str(match_number) +
	" AND match_index = " + str(match_index));
    cc.query("SELECT * FROM game_match" + where + ";\n" +
	     "SELECT * FROM alliance_team" + where + ";\n" +
	     "SELECT * FROM team_score" + where + " AND position = 0;\n",
	callback = cc_load_match_done, match = match, results = 3);

def cc_load_match_done(results, match = None):
    if not isinstance(match, game_match) or not hasattr(match, on_load) or not callable(match.on_load):
	raise Exception("cc_load_match_done called improperly");
    if len(results) < 3:
	raise Exception("unable to load match: did not have 3 results");
    if results[0].type != TYPE_RSET:
	raise Exception(results[0].msg);
    else:
	if len(results[0].rset.row) > 0:
	    row = results[0].rset.row[0];
	    match.match_number = (int(row['match_level']), int(row['match_number']), int(row['match_index']));
	    match.match_status = int(row['status_id']);
	    match.winner = int(row['winner_color_id']);
    if results[1].type != TYPE_RSET:
	raise Exception(results[1].msg);
    else:
	for row in results[1].rset:
	    color = int(row['alliance_color_id']);
	    if not color == COLOR_RED and not color == COLOR_BLUE:
		continue;
	    position = int(row['position']);
	    if position < 1 or position > 3:
		continue;
	    match.alliance[color].team[position].team_number = int(row['team_number']);
	    match.alliance[color].team[position].flags = int(row['flags']);
	    match.alliance[color].team[position].score = int(row['score']);
	    match.alliance[color].team[position].points = int(row['points']);
    if results[2].type != TYPE_RSET:
	raise Exception(results[2].msg);
    else:
	for row in results[2].rset:
	    color = int(row['alliance_color_id']);
	    if not color == COLOR_RED and not color == COLOR_BLUE:
		continue;
	    position = int(row['position']);
	    if not position == 0:
		continue;
	    attrib = int(row['score_attribute_id']);
	    match.alliance[color].scores[attrib] = int(row['value']);
    match.on_load(match);

# passed back as callback_fn(match)
def cc_save_match(cc, match, callback_fn):
    if not callable(callback_fn):
	raise Exception("argument #3 to cc_save_match is not a callback");
    (match_level, match_number, match_index) = match.number;
    match.on_save = callback_fn;
    where = (" WHERE match_level = " + str(match_level) +
	" AND match_number = " + str(match_number) +
	" AND match_index = " + str(match_index));
    query = ("BEGIN\n" +
	"DELETE FROM team_score" + where + ";\n" +
	"UPDATE game_match SET status_id = " + str(match.status) + ", winner_color_id = " + str(match.winner) +
		where + ";\n");
    for color in COLORS:
	for position in POSITIONS:
	    query += ("UPDATE alliance_team SET flags = " + str(match.alliance[color].team[position].flags) +
		", score = " + str(match.alliance[color].team[position].score) + ", points = " +
		str(match.alliance[color].team[position].score) + where +
		" AND alliance_color_id = " + str(color) + " AND position = " + str(position) + ";\n");
	for el in SCORES:
	    query += ("INSERT INTO team_score (match_level, match_number, match_index, alliance_color_id, " +
		"position, score_attribute_id, value) VALUES (" + str(match_level) + ", " + str(match_number) +
		", " + str(match_index) + ", " + str(color) + ", " + str(position) + ", " + str(el) + ", " +
		str(match.alliance[color].scores[el]) + ");\n");
    query += "COMMIT\n";
    cc.query(query, callback = cc_save_match_done, match = match);

def cc_save_match(results, match = None):
    if not isinstance(match, game_match) or not hasattr(match, on_save) or not callable(match.on_save):
	raise Exception("cc_save_match_done called improperly");
    for result in results:
	if result.type == TYPE_ERROR:
	    raise Exception(result.msg);
    match.on_save(match);
