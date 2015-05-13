#!/usr/bin/env python

import random;
import sys;
#from frc2006_tables import *;

teams = [40,  88,   121,  125,  126,  131,  151,  157,  166,  173,
        175,  176,  177,  181,  190,  195,  228,  230,  234,  237,
        238,  246,  271,  348,  350,  467,  562,  571,  663,  809,
        811,  839,  1027, 1058, 1100, 1103, 1124, 1126, 1276, 1289,
        1307, 1405, 1474, 1519, 1685, 1725, 1733, 1735]

COLOR_RED  = 1
COLOR_BLUE = 2

num_teams = len(teams);
max_team = 0;
match_number = 50;

random.seed(0);
random.shuffle(teams);
print "-- ", teams;
print;

lines = sys.stdin.readlines();
lineno = 0;

print "DELETE FROM game_match WHERE match_level = 0 AND match_number >= %s;" % (match_number)
print "DELETE FROM alliance_team WHERE match_level = 0 AND match_number >= %s;" % (match_number)

for line in lines:
    lineno += 1;
    line = line.strip();
    numbers = line.split("\t");
    if 6 != len(numbers):
	print "-- error on line", lineno, ": requires 6 numbers";
	continue;
    numbers = map(int, numbers);
    for number in numbers:
	if number > max_team:
	    max_team = number;
	if number < 0:
	    print "-- team index (" + number + ") out of range (0,", num_teams, ")";
	    sys.exit();
	if max_team >= num_teams:
	    print "-- team index (" + max_team + ") out of range (0,", num_teams, ")";
	    sys.exit();

    query = "INSERT INTO game_match (match_level, match_number, match_index, status_id) VALUES (0, %s, 0, 0);" % (match_number);
    print query;
    
    position = 0;
    color = COLOR_RED;
    
    for number in numbers:
	position += 1;
	if position > 3:
	    position = 1;
	    color = COLOR_BLUE;
        query = ("INSERT INTO alliance_team (match_level, match_number, match_index, alliance_color_id, position, team_number)" +
                 " VALUES (0, %s, 0, %s, %s, %s);") % (match_number, color, position, teams[number]);
	print query;
        
    match_number += 1

print;
print "-- ", max_team + 1, "of", len(teams), "teams";
