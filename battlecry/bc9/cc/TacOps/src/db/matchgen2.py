#!/usr/bin/env python

import random
import sys

match_number = 0

lines = sys.stdin.readlines();
lineno = 0;

#print "DELETE FROM game_match WHERE match_level = 0 AND match_number >= %s;" % (match_number)
#print "DELETE FROM alliance_team WHERE match_level = 0 AND match_number >= %s;" % (match_number)

index = -1

teams = [[0,0,0],
         [0,0,0]]

lines = lines[0].split("\r")
lines.append("0,0,");

#print "got %s lines" % (len(lines))

for line in lines:
#    print "line: %s (len=%s)" % (line, len(line))
    lineno += 1;
    index += 1;
    line = line.strip();
    numbers = line.split(",");

    teams[0][index % 3] = int(numbers[0])
    teams[1][index % 3] = int(numbers[1])

    if ((index % 3 == 2) and
        (index != 0)):
        match_number += 1

        query = "INSERT INTO game_match (match_level, match_number, match_index, status_id) VALUES (0, %s, 0, 0);" % (match_number);
        print query;

        for c in range(2):
            for i in range(3):
                query = ("INSERT INTO alliance_team (match_level, match_number, match_index, alliance_color_id, position, team_number)" +
                         " VALUES (0, %s, 0, %s, %s, %s);") % (match_number, c+1, i+1, teams[c][i]);
                print query;

