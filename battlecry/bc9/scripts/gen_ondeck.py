import sys
from xml.sax.saxutils import escape
from db import dbm, result
from match import alliances

temp = dbm()
temp.init_db(dbm.DB_MAIN)

#res = temp.db[dbm.DB_MAIN].query("SELECT * FROM ondeck_match;")
res = temp.db[dbm.DB_MAIN].query("SELECT m.match_level, m.match_number, m.match_index, m.status_id, d.description FROM ondeck_match m, match_level d WHERE m.match_level = d.match_level ORDER BY m.time_scheduled, m.match_level, m.match_number, m.match_index;")

if res.flag & result.FAIL:
    sys.exit(1);

print "<ondeck>"

for row in res.rows:
    print " <match>"

    (match_level, match_number, match_index, status_id, description) = row
    #(match_level, match_number, match_index, status_id, time_scheduled, winner_color_id) = row
    
    match_id = (match_level, match_number, match_index)

    temp_rows = temp.db[dbm.DB_MAIN].query("SELECT * FROM alliance_team WHERE match_level=%d AND match_number=%d AND match_index=%d ORDER BY position;" % (match_level, match_number, match_index)).rows
    als   = alliances(temp_rows)
    teams = als.get_team_numbers(match_id)
    reds  = teams[1]
    blues = teams[2]

    print "  <type>%s</type>"      % (description)
    print "  <number>%d</number>"  % (match_number)

    i = 0
    for red in reds:
        i += 1
        print "  <red%d>%d</red%d>" % (i, red, i)

    i = 0
    for blue in blues:
        i += 1
        print "  <blue%d>%d</blue%d>" % (i, blue, i)

    print " </match>"

print "</ondeck>"
