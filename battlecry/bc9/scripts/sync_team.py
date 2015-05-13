from db import dbm, quotestring

temp = dbm()
temp.init_all()

res = temp.db[dbm.DB_MAIN].query("SELECT team_number FROM team;")
has_team = dict()
rows = res.rows
for row in rows:
    has_team[row[0]] = 1

res = temp.db[dbm.DB_AUX1].query("SELECT TeamID, ShortName, NickName, RobotName, Location, RookieYear, TeamName FROM Team;")

for row in res.rows:
    team_number = row[0]
    info        = quotestring(row[6]) # maybe ?
    short_name  = quotestring(row[1])
    nickname    = quotestring(row[2])
    robot_name  = quotestring(row[3])
    location    = quotestring(row[4])
    rookie_year = row[5]

#    print "%s" % (team_number),

    if (has_team.has_key(team_number)):
        query = "UPDATE team SET (info, short_name, nickname, robot_name, location, rookie_year) = (%s,%s,%s,%s,%s,%s) WHERE team_number = %s;" % (info, short_name, nickname, robot_name, location, rookie_year, team_number)
        print query
        #print " update"
        res = temp.db[dbm.DB_MAIN].query(query)
    else:
        query = "INSERT INTO team VALUES (%s,%s,%s,%s,%s,%s,%s);" % (team_number, info, short_name, nickname, robot_name, location, rookie_year)
        print query
        #print " new"
        res = temp.db[dbm.DB_MAIN].query(query)

temp.db[dbm.DB_MAIN].commit()



