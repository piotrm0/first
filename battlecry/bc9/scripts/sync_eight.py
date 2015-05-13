## get teams numbers from the finals_alliance_partner
## get scores from ms
## get time scheduled from ms
## get winner from ms

import sys
import sync_conf
import match
from db    import dbm, quotestring, result
from match import matches, alliances, pairs, get_mins

temp = dbm()
temp.init_all()

res = temp.db[dbm.DB_MAIN].query("SELECT * FROM game_match WHERE match_level=1;")
ms = matches(source = res.rows)

res = temp.db[dbm.DB_MAIN].query("SELECT * FROM alliance_team WHERE match_level=1;")
as = alliances(source = res.rows)

res = temp.db[dbm.DB_MAIN].query('SELECT * FROM finals_alliance_partner;')
ps = pairs(source = res.rows)

res = temp.db[dbm.DB_AUX1].query("SELECT " +
                                 "m.MatchID, m.EventID, m.ScheduleID, m.TournamentLevel, m.MatchStatus, " +
                                 "m.RedTeam1ID, m.RedTeam2ID, m.RedTeam3ID, " +
                                 "m.BlueTeam1ID, m.BlueTeam2ID, m.BlueTeam3ID, " +
                                 "m.RedFinalScore, m.BlueFinalScore, m.AutoWinner, m.Winner, d.Description, d.StartTime, d.EndTime " +
                                 "FROM Match m, ScheduleDetail d " +
                                 "WHERE m.EventID = %s AND d.EventID = m.EventID AND m.ScheduleID = d.ScheduleID AND m.TournamentLevel = 2;" % (sync_conf.EVENT_ID_EIGHT))

mins = None

ms_matches   = []
ms_alliances = []

for row in res.rows:
    print row
    (temp_match, temp_alliances) = match.from_ms_row(row)

    ms_matches.append(temp_match)
    
    for a in temp_alliances:
        ms_alliances.append(a)

    #print temp_alliances

mins = get_mins(ms_matches)

for m in ms_matches:
    m.offset_number(mins)
    if m.match_id[1] <= 16:
        m.map_eight()
        ms.mod(m)

for a in ms_alliances:
    a.offset_number(mins)
    if a.match_id[1] <= 16:
        a.map_eight(ps)
        as.mod(a)

for m in ms_matches:
    if not m.from_ms: continue
    m.check_ms_teams(as)

#sys.exit(1);

for q in ms.queries():
    #print q
    res = temp.db[dbm.DB_MAIN].query(q)
    if res.failed():
        print "query failed [%s]" % (q)
        sys.exit(1)
    #temp.db[dbm.DB_MAIN].commit()
    
for q in as.queries():
    #print q
    res = temp.db[dbm.DB_MAIN].query(q)
    if res.failed():
        print "query failed [%s]" % (q)
        sys.exit(1)
    #temp.db[dbm.DB_MAIN].commit()

#sys.exit(1)

temp.db[dbm.DB_MAIN].commit()

sys.exit(0)
