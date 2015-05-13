import time
from db import dbm

temp = dbm()
temp.init_all()

rows = temp.db[dbm.DB_AUX1].query("SELECT TeamID, ShortName, NickName, RobotName, Location, RookieYear, TeamName FROM Team WHERE TeamID = 190;")
print rows

rows = temp.db[dbm.DB_MAIN].query("SELECTs * FROM display_component_effect;")
print rows
