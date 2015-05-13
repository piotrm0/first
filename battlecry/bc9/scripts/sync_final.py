import sys
import sync_conf
import match
from db    import dbm, quotestring, result
from match import matches, alliances, get_mins

temp = dbm()
temp.init_all()

ms = matches()
res = temp.db[dbm.DB_MAIN].query("SELECT * FROM game_match;")
ms.read(res.rows)

as = alliances()
res = temp.db[dbm.DB_MAIN].query("SELECT * FROM alliance_team;")
as.read(res.rows)

res = temp.db[dbm.DB_AUX1].query("SELECT " +
                                 "m.MatchID, m.EventID, m.ScheduleID, m.TournamentLevel, m.MatchStatus, " +
                                 "m.RedTeam1ID, m.RedTeam2ID, m.RedTeam3ID, " +
                                 "m.BlueTeam1ID, m.BlueTeam2ID, m.BlueTeam3ID, " +
                                 "m.RedFinalScore, m.BlueFinalScore, m.AutoWinner, m.Winner, d.Description, d.StartTime, d.EndTime " +
                                 "FROM Match m, ScheduleDetail d " +
                                 "WHERE m.EventID = %s AND d.EventID = m.EventID AND m.ScheduleID = d.ScheduleID AND m.TournamentLevel = 3" % (sync_conf.EVENT_ID_EIGHT))

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
    ms.mod(m)
for a in ms_alliances:
    a.offset_number(mins)
    as.mod(a)

print mins
#sys.exit(0)

for q in ms.queries():
    #print q
    #continue
    res = temp.db[dbm.DB_MAIN].query(q)
    if res.failed():
        print "query failed [%s]" % (q)
        sys.exit(1)
    #temp.db[dbm.DB_MAIN].commit()


for q in as.queries():
    #print q
    #continue
    res = temp.db[dbm.DB_MAIN].query(q)
    if res.failed():
        print "query failed [%s]" % (q)
        sys.exit(1)
    #temp.db[dbm.DB_MAIN].commit()

temp.db[dbm.DB_MAIN].commit()

sys.exit(0)

