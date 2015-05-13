import sys

e_map = dict()
#e_map[1] = [1,16]
#e_map[3] = [2,15]
#e_map[5] = [3,14]
#e_map[7] = [4,13]
#e_map[2] = [8,9]
#e_map[4] = [7,10]
#e_map[6] = [6,11]
#e_map[8] = [5,12]

e_map[1] = [1,16]
e_map[2] = [8,9]
e_map[3] = [4,13]
e_map[4] = [5,12]
e_map[5] = [2,15]
e_map[6] = [7,10]
e_map[7] = [3,14]
e_map[8] = [6,11]

class pair:
    def __init__(self, pos_id, team_number):
        self.pos_id      = pos_id
        self.team_number = team_number

class pairs:
    def __init__(self, source=None):
        self.data = dict()
        if not source is None:
            self.read(source)

    def add(self, p):
        self.data[p.pos_id] = p

    def read(self, rows):
        for row in rows:
            p = pair((row[0], row[1]), row[2])
            self.add(p)

class match:
    short_names = dict()
    short_names[-1] = 'P'
    short_names[0]  = 'Q'
    short_names[1]  = 'EF'
    short_names[2]  = 'QF'
    short_names[3]  = 'SF'
    short_names[4]  = 'F'

    long_names = dict()
    long_names[-1] = 'Practice'
    long_names[0]  = 'Qualification'
    long_names[1]  = 'Eight-Final'
    long_names[2]  = 'Quarter-Final'
    long_names[3]  = 'Semi-Final'
    long_names[4]  = 'Final'

    def __init__(self, match_id, status_id, time_scheduled, winner_color_id):
        self.ms_MatchID = None
        self.ms_EventID = None
        self.ms_teams   = [[],[]]
        
        self.match_id        = match_id
        self.status_id       = status_id
        self.time_scheduled  = time_scheduled
        self.winner_color_id = winner_color_id

        self.level_name_short = match.short_names[match_id[0]]
        self.level_name_long  = match.long_names[match_id[0]]

        self.render_names()
        
        self.new     = 0
        self.changed = 0

        self.from_ms = 0

    def render_names(self):
        self.name_short = self.level_name_short + " - "
        self.name_long  = self.level_name_long  + " - "

        if self.match_id[0] == 4:
            self.name_short += "%d" % (self.match_id[1])
            self.name_long  += "%d" % (self.match_id[1])
        elif self.match_id[0] > 0:
            self.name_short += "%d.%d" % (self.match_id[1], self.match_id[2])
            self.name_long  += "%d.%d" % (self.match_id[1], self.match_id[2])
        else:
            self.name_short += str(self.match_id[1])
            self.name_long  += str(self.match_id[1])

    def check_ms_teams(self, as):
        print "check_ms_teams:\tchecking match %s" % (str(self.match_id))
        
        if not as.data.has_key(self.match_id):
            print "check_ms_teams:\t!!! match %s has no teams present" % (str(self.match_id))
            sys.exit(1)

        temp_as = as.data[self.match_id]

        for a in temp_as:
            ms_team = self.ms_teams[a.alliance_color_id][a.position]
            to_team = a.team_number
            if ms_team != to_team:
                print "check_ms_teams:\t!!! match %s, position %d.%d has team %d in ms, but %d in tacops" % (str(self.match_id),a.alliance_color_id,a.position,ms_team, to_team)
                sys.exit(1)

    def map_eight(self):
        self.match_id = map_eight(self.match_id)

    def offset_number(self, mins):
        i = (self.match_id[0], self.match_id[1] - mins[self.match_id[0]] + 1, self.match_id[2])
        if self.match_id[0] == 4:
            i = (self.match_id[0], self.match_id[2], 0)

        self.match_id = i

    def query(self):
        #i = [self.match_id[0], self.match_id[1], self.match_id[2]]
        #i[1] -= (mins[i[0]] - 1)
        i = self.match_id
        if self.new:
            return "INSERT INTO game_match VALUES (%d,%d,%d,%d,%s,%d);" % (i[0], i[1], i[2], self.status_id, "'" + self.time_scheduled.isoformat(" ") + "'", self.winner_color_id)
        else:
            return "UPDATE game_match SET (match_level, match_number, match_index, status_id, time_scheduled, winner_color_id) = (%d,%d,%d,%d,%s,%d) WHERE match_level=%d AND match_number=%d AND match_index=%d;" % (i[0], i[1], i[2], self.status_id, "'" + self.time_scheduled.isoformat(" ") + "'", self.winner_color_id, i[0], i[1], i[2])

    def __str__(self):
        return "<match %s, status=[%s] scheduled=[%s] winner=[%s]>" % (self.match_id,self.status_id,self.time_scheduled,self.winner_color_id)

    def __repr__(self):
        return self.__str__()

class alliance:
    def __init__(self, match_id, alliance_color_id, position, team_number, flags, score, points):
        self.match_id = match_id
        self.alliance_color_id = alliance_color_id
        self.position          = position
        self.team_number       = team_number
        self.flags             = flags
        self.score             = score
        self.points            = points

        self.new     = 0
        self.changed = 0

        self.from_ms = 0

    def map_eight(self, pairs):
        global e_map
        
        self.match_id = map_eight(self.match_id)

        rank  = e_map[self.match_id[1]][self.alliance_color_id - 1]
        
        team = pairs.data[(rank, self.position)].team_number
        self.team_number = team

    def offset_number(self, mins):
        i = (self.match_id[0], self.match_id[1] - mins[self.match_id[0]] + 1, self.match_id[2])
        if self.match_id[0] == 4:
            i = (self.match_id[0], self.match_id[2], 0)

        self.match_id = i

    def query(self):
        i = self.match_id
        #i = [self.match_id[0], self.match_id[1], self.match_id[2]]
        #i[1] -= (mins[i[0]] - 1)

        if self.new:
            return "INSERT INTO alliance_team VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s);" % (i[0], i[1], i[2], self.alliance_color_id, self.position, self.team_number, self.flags, self.score, self.points)
        else:
            return "UPDATE alliance_team SET (match_level, match_number, match_index, alliance_color_id, position, team_number, flags, score, points) = (%d,%d,%d,%d,%d,%d,%d,%d,%d) WHERE match_level=%d AND match_number=%d AND match_index=%d AND alliance_color_id=%d AND position=%d;" % (i[0], i[1], i[2], self.alliance_color_id, self.position, self.team_number, self.flags, self.score, self.points, i[0], i[1], i[2], self.alliance_color_id, self.position)

    def __str__(self):
        return "\n<alliance pos=[%s,%s] team=[%s] score=[%s]>" % (self.alliance_color_id,self.position,self.team_number,self.score)

    def __repr__(self):
        return self.__str__()

class matches:
    def __init__(self, source=None):
        self.data = dict()
        if not source is None:
            self.read(source)

    def mod(self, m):
        print "modding %s" % (str(m.match_id))
        m.from_ms = 1
        if not self.data.has_key(m.match_id):
            m.new     = 1

        m.changed = 1
        self.data[m.match_id] = m

    def add(self, m):
        self.data[m.match_id] = m

    def read(self, rows):
        for row in rows:
            m = match((row[0], row[1], row[2]), row[3], row[4], row[5])
            self.add(m)

    def get_by_level(self):
        ret = dict()

        for match_id in self.data:
            m = self.data[match_id]
            match_level = match_id[0]
            if not ret.has_key(match_level):
                ret[match_level] = []
            ret[match_level].append(m)

        return ret

    def queries(self):
        ret = []
        for m in self.data.values():
            if m.new or m.changed:
                ret.append(m.query())
        return ret

class alliances:
    def __init__(self, source=None):
        self.data = dict()
        if (source is not None):
            self.read(source)

    def mod(self, m):
        m.from_ms = 1
        if not self.data.has_key(m.match_id):
            m.new = 1
            self.data[m.match_id] = []

        for i in range(len(self.data[m.match_id])):
            a = self.data[m.match_id][i]
            if a.alliance_color_id == m.alliance_color_id and a.position == m.position:
                self.data[m.match_id][i] = m
                m.new     = 0
                m.changed = 1
                return

        self.data[m.match_id].append(m)
        m.new     = 1
        m.changed = 1

    def add(self, m):
        if not self.data.has_key(m.match_id):
            self.data[m.match_id] = []
        self.data[m.match_id].append(m)

    def read(self, rows):
        for row in rows:
            m = alliance((row[0], row[1], row[2]), row[3], row[4], row[5], row[6], row[7], row[8])
            self.add(m)

    def get_team_results(self, match_id):
        ret = dict()
        ret[1] = []
        ret[2] = []

        if not self.data.has_key(match_id):
            return ret

        for m in self.data[match_id]:
            ret[m.alliance_color_id].append((m.team_number, m.score, m.position))

        ret[1].sort(lambda a,b: cmp(a[2],b[2]))
        ret[2].sort(lambda a,b: cmp(a[2],b[2]))

        return ret

    def get_team_numbers(self, match_id):
        ret = dict()
        ret[1] = []
        ret[2] = []
        
        if not self.data.has_key(match_id):
            return ret

        for a in self.data[match_id]:
            ret[a.alliance_color_id].append(a.team_number)
            
        return ret

    def queries(self):
        ret = []
        for ms in self.data.values():
            for m in ms:
                if (m.new or m.changed) and m.team_number != 0:
                    ret.append(m.query())
        return ret

def from_ms_row(row):
    return from_ms(row[0], row[1], row[2], row[3], row[4],
                   row[5], row[6], row[7], row[8], row[9],
                   row[10], row[11], row[12], row[13], row[14],
                   row[15], row[16], row[17])

def from_ms(MatchID, EventID, ScheduleID, TournamentLevel, MatchStatus,
            RedTeam1ID,  RedTeam2ID,  RedTeam3ID,
            BlueTeam1ID, BlueTeam2ID, BlueTeam3ID,
            RedScore, BlueScore, AutoWinner, Winner, Description, StartTime, EndTime):
    
    match_id = [0,0,0]
    
    if (TournamentLevel == 1):   # practice
        match_id[0] = -1
        match_id[1] = MatchID
        match_id[2] = 0
    elif (TournamentLevel == 2): # qualification
        match_id[0] = 0
        match_id[1] = MatchID
        match_id[2] = 0
    elif (TournamentLevel == 3): # elimination
        if (Description[0] == 'E'):  # probably not supported
            match_id[0] = 1
            match_id[1] = int(Description[6])
            match_id[2] = int(Description[8])
        elif (Description[0] == 'Q'):
            match_id[0] = 2
            match_id[1] = int(Description[4])
            match_id[2] = int(Description[6])
        elif (Description[0] == 'S'):
            match_id[0] = 3
            match_id[1] = int(Description[5])
            match_id[2] = int(Description[7])
        elif (Description[0] == 'F'):
            match_id[0] = 4
            match_id[1] = int(Description[6])
            match_id[2] = int(Description[8])

        else:
            print "unknown Description = %s" % (Description)
            sys.exit(1)
    else:
        print "unknown TournamentLevel = %s" % (TournamentLevel)
        sys.exit(1)

    status_id = 0
    
    if (MatchStatus[0:3] == "Not"):
        status_id = 1
    elif (MatchStatus[0:3] == "Com"):
        status_id = 4
    elif (MatchStatus[0:3] == "Can"):
        status_id = 9

    winner_color_id = 0
    if (Winner[0:3] == "Red"):
        winner_color_id = 1
    elif (Winner[0:4] == "Blue"):
        winner_color_id = 2

    match_id = (match_id[0], match_id[1], match_id[2])

    ret_match       = match(match_id, status_id, StartTime, winner_color_id)
    ret_match.from_ms    = 1
    ret_match.ms_MatchID = MatchID
    ret_match.ms_EventID = EventID
    ret_match.ms_teams   = [[None, None,        None,        None],
                            [None, RedTeam1ID,  RedTeam2ID,  RedTeam3ID],
                            [None, BlueTeam1ID, BlueTeam2ID, BlueTeam3ID]];
    ret_alliances = []
    ret_alliances.append(alliance(match_id, 1, 1, RedTeam1ID, 0, RedScore, RedScore))
    ret_alliances.append(alliance(match_id, 1, 2, RedTeam2ID, 0, RedScore, RedScore))
    ret_alliances.append(alliance(match_id, 1, 3, RedTeam3ID, 0, RedScore, RedScore))
    ret_alliances.append(alliance(match_id, 2, 1, BlueTeam1ID, 0, BlueScore, BlueScore))
    ret_alliances.append(alliance(match_id, 2, 2, BlueTeam2ID, 0, BlueScore, BlueScore))
    ret_alliances.append(alliance(match_id, 2, 3, BlueTeam3ID, 0, BlueScore, BlueScore))

    return (ret_match, ret_alliances)

def get_mins(matches):
    ret = dict()
        
    for match in matches:
        if not ret.has_key(match.match_id[0]):
            ret[match.match_id[0]] = 999
            
        if ret[match.match_id[0]] > match.match_id[1]:
            ret[match.match_id[0]] = match.match_id[1]

    return ret

def map_eight(match_id):
    if match_id[0] != 0 or match_id[1] > 16:
        print "trying to map out of range match %s" % (match_id)
        sys.exit(1)

    new_level  = 1
    new_index  = 0
    if match_id[1] <= 8:
        new_index = 1
    else:
        new_index = 2
    new_number = ((match_id[1]-1) % 8) + 1

    return (new_level, new_number, new_index)

