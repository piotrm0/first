import sys
from db import dbm, result
from match import alliances, matches

temp = dbm()
temp.init_db(dbm.DB_MAIN)

res_matches   = temp.db[dbm.DB_MAIN].query("SELECT * FROM game_match    WHERE match_level > -1;")
res_alliances = temp.db[dbm.DB_MAIN].query("SELECT * FROM alliance_team WHERE match_level > -1;")    

if res_matches.flag & result.FAIL or res_alliances.flag & result.FAIL:
    sys.exit(1);

ms = matches(res_matches.rows)
as = alliances(res_alliances.rows)

def print_side(teams, color, is_first):
    for t in teams:
        if not is_first:
            print "  <tr>"
            is_first = 0
        print "   <td class='%s'>%s</td>" % (color, color)
        print "   <td class='%s'>%d</td>" % (color, t[0])
        print "   <td class='%s'>%d</td>" % (color, t[1])
        print "  </tr>"

def print_match(m, teams):
    cols = []
    cols.append(m.name_short)
    #cols += [str(x) for x in m.match_id]
    cols += [str(x[0]) for x in teams[1]]
    cols += [str(x[0]) for x in teams[2]]
    cols.append(str(teams[1][0][1]))
    cols.append(str(teams[2][0][1]))
    cols.append("END")

    print ",".join(cols)

def cmp_match_id(match_a,match_b):
    a = match_a.match_id
    b = match_b.match_id
    if a[0] < b[0]: return -1
    if a[0] > b[0]: return  1

    if a[1] < b[1]: return -1
    if a[1] > b[1]: return  1

    if a[2] < b[2]: return -1
    if a[2] > b[2]: return  1

    return 0

def print_matches(name, matches, alliances):
    matches.sort(cmp_match_id)
    for m in matches:
        teams = alliances.get_team_results(m.match_id)
        print_match(m, teams)

print ",".join(["Match", "Red1", "Red2", "Red3", "Blue1", "Blue2", "Blue3", "RedScore", "BlueScore", "The word \"END\""])
ms_by_level = ms.get_by_level()
if ms_by_level.has_key(0): print_matches("Qualifications", ms_by_level[0], as)
if ms_by_level.has_key(1): print_matches("8th Finals",     ms_by_level[1], as)
if ms_by_level.has_key(2): print_matches("Quarter Finals", ms_by_level[2], as)
if ms_by_level.has_key(3): print_matches("Semi Finals",    ms_by_level[3], as)
if ms_by_level.has_key(4): print_matches("Finals",         ms_by_level[4], as)

