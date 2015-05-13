#!/usr/bin/env python


t = 17 * 60 + 30;

for match_number in range(1, 11):
    h = t / 60;
    m = t % 60;
    q = "UPDATE game_match SET time_scheduled = '2006-06-23 %02d:%02d:00'" % (h, m);
    q += " WHERE match_level = 0 AND match_number = " + str(match_number) + ";";
    print q;
    t += 6;

t += 60;

for match_number in range(11, 26):
    h = t / 60;
    m = t % 60;
    q = "UPDATE game_match SET time_scheduled = '2006-06-23 %02d:%02d:00'" % (h, m);
    q += " WHERE match_level = 0 AND match_number = " + str(match_number) + ";";
    print q;
    t += 6;
