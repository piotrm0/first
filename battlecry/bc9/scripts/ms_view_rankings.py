import sys
import sync_conf
import match
from db    import dbm, quotestring, result
from match import matches, alliances, get_mins

temp = dbm()
temp.init_db(dbm.DB_AUX1)

res = temp.db[dbm.DB_AUX1].query("SELECT Ranking, QualifyingScore, RankingScore, TeamID, Wins, Losses, Ties, MaxPoint FROM TeamRanking ORDER BY Ranking, QualifyingScore DESC, RankingScore DESC;")

for row in res.rows:
    print row
