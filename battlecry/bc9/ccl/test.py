import pymssql

con = pymssql.connect(host='cmwerner.dyndns.org:2301',user='sa',password='FIRSTpass#1',database='FMS_Demo')
cur = con.cursor()

#query = "SELECT TeamID, ShortName, NickName, RobotName, Location, RookieYear, TeamName from Team WHERE TeamID = 190;"
#query = "SELECT * from Alliance;"
#query = "SELECT * from TeamRanking ORDER BY Ranking;"
query = "SELECT * from Match;"

cur.execute(query)

rows = cur.fetchall()

for row in rows:
    print row
    
