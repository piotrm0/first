import sys
import sync_conf
import match
from db    import dbm, quotestring, result
from match import matches, alliances, get_mins

temp = dbm()
temp.init_db(dbm.DB_AUX1)

#res = temp.db[dbm.DB_AUX1].query("SELECT MatchID, MatchStatus, RedScore, BlueScore, Winner, RedFinalScore, BlueFinalScore FROM Match;")
res = temp.db[dbm.DB_AUX1].query("SELECT * FROM Match;")

for desc in res.desc:
    print desc[0]

sys.exit(1)

for row in res.rows:
    print row
