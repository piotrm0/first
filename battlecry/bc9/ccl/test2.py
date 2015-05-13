import pgdb

con = pgdb.connect(host='localhost',user='postgres',password='',database='tacops')
cur = con.cursor()

query = "SELECT * from display_component_effect;"

cur.execute(query)

rows = cur.fetchall()

for row in rows:
    print row
    
