#!/usr/bin/env python

import re;
import os;
import sys;
import select;
import cc_client;
import cc_parser;
import frc2006_tables;
from hosts import *;
from battlecry_web import *;

class web_results:
    def __init__(self):
	self.cc = cc_client.cc_client("web");
	self.cc.rset_watch("participant_results", self.do_rankings);
	self.cc.env_watch("scores_source", self.do_matches);
	self.cc.connect(HOST_CCENTER);

    def do_rankings(self, rset):
	filename = "/tmp/standings.inc";
	file = open(filename, "w");
	set_output(file);
	printHeader();
	printStandingsColumnHeading();
	for row in rset:
	    printTeamRow(row);
	printFooter();
	file.close();
	self.rsync(filename);

    def do_matches(self, key, old_value, new_value):
	if "db" != new_value:
	    return;
	query = ("""
SELECT match_level, match_number, match_index, status_id, time_scheduled,
	t1.team_number AS team1, t1.score AS score1,
	t2.team_number AS team2, t2.score AS score2,
	t3.team_number AS team3, t3.score AS score3,
	t4.team_number AS team4, t4.score AS score4,
	t5.team_number AS team5, t5.score AS score5,
	t6.team_number AS team6, t6.score AS score6
FROM game_match
	INNER JOIN alliance_team t1 USING (match_level, match_number, match_index)
	INNER JOIN alliance_team t2 USING (match_level, match_number, match_index)
	INNER JOIN alliance_team t3 USING (match_level, match_number, match_index)
	INNER JOIN alliance_team t4 USING (match_level, match_number, match_index)
	INNER JOIN alliance_team t5 USING (match_level, match_number, match_index)
	INNER JOIN alliance_team t6 USING (match_level, match_number, match_index)
WHERE
	t1.alliance_color_id = 1 AND t1.position = 1 AND
	t2.alliance_color_id = 1 AND t2.position = 2 AND
	t3.alliance_color_id = 1 AND t3.position = 3 AND
	t4.alliance_color_id = 2 AND t4.position = 1 AND
	t5.alliance_color_id = 2 AND t5.position = 2 AND
	t6.alliance_color_id = 2 AND t6.position = 3
ORDER BY match_level, match_number, match_index
""");
	query = re.sub("\n", " ", query);
	self.cc.query(query, self.got_matches);

    def got_matches(self, results):
	for result in results:
	    if result.type == cc_parser.query_result.TYPE_ERROR:
		raise Exception("Unable to get matchlist: " + result.msg);
	last_level = None;
	rset = results[0].rset;
	filename = "/tmp/matches.inc";
	file = open(filename, "w");
	set_output(file);
	printHeader();
	for row in rset:
	    if last_level != row["match_level"]:
		last_level = row["match_level"];
	    match = row["match_number"];
	    index = int(row["match_index"]);
	    if 0 != index:
		match += "." + row["match_index"];
	    level = frc2006_tables.LEVEL_NAMES[int(last_level)];
	    args = [level, match, row["time_scheduled"], row["status_id"]];
	    for team in (1, 2, 3, 4, 5, 6):
		args.append(row["team" + str(team)]);
		args.append(row["score" + str(team)]);
	    printMatchRow(*args);
	printFooter();
	file.close();
	self.rsync(filename);

    def rsync(self, filename):
	os.system("/usr/local/bin/rsync -avHSP \"" + filename + "\" first@ccc.wpi.edu:public_html/battlecry/");

web = web_results();

while True:
    reads = [web.cc.net.sock];
    writes = [];

    if web.cc.net.need_write():
        writes.append(web.cc.net.sock);

    (can_read, can_write, other) = select.select(reads, writes, [])

    for handle in can_read:
        if handle == web.cc.net.sock:
            web.cc.net.sock_recv();

    for handle in can_write:
        if handle == web.cc.net.sock:
            web.cc.net.sock_send();
