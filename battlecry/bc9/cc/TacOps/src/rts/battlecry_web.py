#!/usr/bin/env python

import frc2006_tables;

#printMatchRow will printout(the row of the table for the match
# match- A tuple the match in the format (match_level, MATCH_NUM) where MATCH_NUM is a string including the match_number and match_index 
# status - The status code
# team1..6 - the team number teams 1-3 are blue
# score1..6 - the score for the corresponding team
TINT = 0;
LASTMATCHTYPE = None;
RANK = 0;

output_file = None;

def printout(*args):
    global output_file;
    msg = "";
    for arg in args:
	msg += str(arg) + " ";
    output_file.write(msg);

def set_output(file):
    global output_file;
    output_file = file;

def printMatchRow(match_level, match_number, time, status, team1, score1, team2, score2, team3, score3, team4, score4, team5, score5, team6, score6):
	global TINT, LASTMATCHTYPE;
	if match_level != LASTMATCHTYPE:
		printMatchColumnHeaders(match_level);
	LASTMATCHTYPE = match_level;

	if TINT == 1:
		tintclass = ' class="tint"';
	else :
		tintclass = '';

	printout('<tr',tintclass,'>\n');
	printout('\t<td rowspan="6">',match_level[0],' ',match_number,' [',frc2006_tables.STATUS_TEXTS[int(status)],']');
	printout('</td>\n');
	printout('\t<td rowspan="6">',time,'</td>\n');
	printout('\t<td class="red">red</td>\n');
	printout('\t<td class="red">',team1,'</td>\n');
	printout('\t<td class="red">',score1,'</td>\n');
	printout('</tr>\n');

	printout('<tr',tintclass,'>\n');
	printout('\t<td class="red">red</td>\n');
	printout('\t<td class="red">',team2,'</td>\n');
	printout('\t<td class="red">',score2,'</td>\n');
	printout('</tr>\n');

	printout('<tr',tintclass,'>\n');
	printout('\t<td class="red">red</td>\n');
	printout('\t<td class="red">',team3,'</td>\n');
	printout('\t<td class="red">',score3,'</td>\n');
	printout('</tr>\n');

	printout('<tr',tintclass,'>\n');
	printout('\t<td class="blue">blue</td>\n');
	printout('\t<td class="blue">',team4,'</td>\n');
	printout('\t<td class="blue">',score4,'</td>\n');
	printout('</tr>\n');

	printout('<tr',tintclass,'>\n');
	printout('\t<td class="blue">blue</td>\n');
	printout('\t<td class="blue">',team5,'</td>\n');
	printout('\t<td class="blue">',score5,'</td>\n');
	printout('</tr>\n');

	printout('<tr',tintclass,'>\n');
	printout('\t<td class="blue">blue</td>\n');
	printout('\t<td class="blue">',team6,'</td>\n');
	printout('\t<td class="blue">',score6,'</td>\n');
	printout('</tr>\n');


def printMatchColumnHeaders(match_level):
	global TINT;
	printout('<tr>\n');
	printout('\t<th class="main" colspan="5">',match_level[1],'</th>\n');
	printout('</tr>\n');
	printout('<tr>\n');
	printout('\t<th>Match</th>\n');
	printout('\t<th>Scheduled</th>\n');
	printout('\t<th>Alliance</th>\n');
	printout('\t<th>Team</th>\n');
	printout('\t<th>Score</th>\n');
	printout('</tr>\n');
	TINT = 0;

def printHeader():
	global TINT, LASTMATCHTYPE, RANK;
	printout('<table class="center" cellspacing="1">\n');
	RANK = 0;
	TINT = 0;
	LASTMATCHTYPE = None;

def printFooter():
	printout('</table>\n');


# printTeamRow prints the row of the table for the standings
# rankinginfo is a dictionary of info
def printTeamRow(rankinginfo):
	global RANK;
	RANK += 1;
	if RANK % 2 == 1:
		tintclass = ' class="tint"';
	else:
		tintclass = '';
	printout('<tr',tintclass,'>\n');
	printout('\t<td>',RANK,'</td>\n');
	printout('\t<td>',rankinginfo['team'],'</td>\n');
	printout('\t<td>',rankinginfo['team name'],'</td>\n');
	printout('\t<td>',rankinginfo['wins'],'-',rankinginfo['losses'],'-',rankinginfo['ties'],'</td>\n');
	printout('\t<td>',rankinginfo['record'],'</td>\n');
	printout('\t<td>',rankinginfo['ave points'],'</td>\n');
	printout('</tr>\n');

def printStandingsColumnHeading():
	printout('<tr>\n');
	printout('\t<th>Rank</th>\n');
	printout('\t<th>Team #</th>\n');
	printout('\t<th>Team Name</th>\n');
	printout('\t<th>W-L-T</th>\n');
	printout('\t<th>Avg. QP</th>\n');
	printout('\t<th>RP</th>\n');
	printout('</tr>\n');
