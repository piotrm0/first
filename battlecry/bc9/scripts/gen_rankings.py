import sys
from xml.sax.saxutils import escape
from db import dbm, result

temp = dbm()
temp.init_db(dbm.DB_MAIN)

res = temp.db[dbm.DB_MAIN].query("SELECT * FROM participant_results;")

if res.flag & result.FAIL:
    sys.exit(1);

print "<Rankings>"

rank = 0;

for row in res.rows:
    rank += 1
    
    print " <Team>"

    (team, wins, losses, ties, record, ave_points, max_score, total_points, team_name) = row

    print "  <Rank>%d</Rank>"              % (rank)
    print "  <TeamNumber>%d</TeamNumber>"  % (team)
    print "  <TeamName>%s</TeamName>"      % (escape(team_name))
    print "  <WLT>%d-%d-%d</WLT>"          % (wins, losses, ties)
    print "  <AverageQP>%0.2f</AverageQP>" % (record)
    print "  <AverageRP>%0.2f</AverageRP>" % (ave_points)

    print " </Team>"

print "</Rankings>"
