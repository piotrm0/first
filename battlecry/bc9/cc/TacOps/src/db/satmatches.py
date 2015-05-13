#!/usr/bin/env python

import sys;

COLOR_RED  = 1
COLOR_BLUE = 2

match_number = 26;

lines = sys.stdin.readlines();
lineno = 0;

for line in lines:
    lineno += 1;
    line = line.strip();
    numbers = line.split("\t");
    if 7 != len(numbers):
	print "-- error on line", lineno, ": requires 6 numbers";
	continue;
    time = int(round(float(numbers[0]) * 24 * 60));
    hour = time / 60;
    minute = time % 60;
    time = "2006-06-24 %02d:%02d:00" % (hour, minute);
    teams = map(int, numbers[1:]);

    query = "INSERT INTO game_match (match_level, match_number, match_index, time_scheduled, status_id) VALUES (0, %d, 0, '%s', 1);" % (match_number, time);
    print query;
    
    position = 0;
    color = COLOR_RED;
    
    for team in teams:
	position += 1;
	if position > 3:
	    position = 1;
	    color = COLOR_BLUE;
        query = ("INSERT INTO alliance_team (match_level, match_number, " +
		"match_index, alliance_color_id, position, team_number)" +
                 " VALUES (0, %d, 0, %d, %d, %d);") % (match_number, color, position, team);
	print query;
        
    match_number += 1
