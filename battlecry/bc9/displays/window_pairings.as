import mx.containers.Window;

class window_pairings extends Window {
    private var rsets = null;

    private var teams;
    private var holders:Array;

    public var handle_drop :Function;
    public var handle_join :Function;
    public var handle_move :Function;
    public var handle_teams:Function;

    public var handle_moveup:Function;
    public var handle_clear :Function;

    public function window_pairings() {
	super();
	//trace("window_pairings: made");

	this.holders = new Array();
	this.teams   = new Object();
    }

    private function init() {
	super.init();
	this.setSize(440,440);
	this.title = "Control Pairings";
	this.contentPath = "window_pairings_content";
    }

    private function get_next_highest(pos:Number) {
	var c = this.content;
	var self = this;

	var dr  = this.rsets.participant_results;
	var drw = this.rsets.participant_results_raw;

	for (var i = 0; i < drw.length; i++) {
	    var team = drw[i].by_name.team;
	    var team_box = this.teams[team];
	    if ((null == team_box.holder) ||
		(team_box.holder.alliance_number > pos)) {
		return team;
	    }
	}

	return null;
    }
    
    private function get_first_empty_index() {
	for (var i = 0; i < 16; i++) {
	    if (null == this.holders[3*i].holding) {
		return i;
	    }
	}

	return null;
    }

    private function moveup() {
	var i = this.get_first_empty_index();

	//trace("first empty = " + (i+1));

	if (null == i) {
	    return;
	}

	for (var j = i; j < 16; j++) {
	    //trace("filling alliance spot " + (j+1));
	    if (null != this.holders[j*3].holding) {
		trace("!!! spot " + (j+1) + " already filled, someone was out of place, consider resetting selections !");
		continue;
	    }
	    var team = this.get_next_highest(j+1);
	    var team_box = this.teams[team];
	    //trace("with team " + team);
	    this.drop(team, this.holders[j*3]);
	}
    }

    public function init_gui() {
	var self = this;
	var c    = this.content;

	c.button_teams.onPress = function() {
	    self.handle_teams();
	}

	c.button_clear.onPress = function() {
	    self.handle_clear();
	}

	c.button_moveup.onPress = function() {
	    self.moveup();
	}

	this._parent.controler.init_window_pairings();
    }

    public function fill_gui(d) {
	var self = this;
	var c    = this.content;

	this.rsets = d;

	var dr = d.participant_results;

	this.create_holders(16);
	this.update_teams();
    }

    private function create_holders(num) {
	var self = this;
	var c = this.content;

	for (var i = 1; i <= 16; i++) {
	    c.attachMovie("mini_alliance", "all_" + i, c.getNextHighestDepth());
	    c.attachMovie("mini_team_hold", "team_" + i + "_1", c.getNextHighestDepth());
	    c.attachMovie("mini_team_hold", "team_" + i + "_2", c.getNextHighestDepth());
	    c.attachMovie("mini_team_hold", "team_" + i + "_3", c.getNextHighestDepth());
	    var aa = c["all_" + i];
	    var ta = c["team_" + i + "_1"];
	    var tb = c["team_" + i + "_2"];
	    var tc = c["team_" + i + "_3"];

	    aa._y = ta._y = tb._y = tc._y = (i-1) * 22 + 27;
	    aa._x = 210;
	    ta._x = 250;
	    tb._x = 310;
	    tc._x = 370;

	    aa.set_data(i);
	    ta.set_data(i, i, 1);
	    tb.set_data(i, i, 2);
	    tc.set_data(i, i, 3);

	    this.holders.push(ta);
	    this.holders.push(tb);
	    this.holders.push(tc);
	}
    }

    public function update_new_teams(rset, raw) {
	this.rsets.participant_results        = rset;
	this.rsets['participant_results_raw'] = raw;
	this.update_teams();
    }

    private function update_teams() {
	var c = this.content;
	var self = this;

	var dr  = this.rsets.participant_results;
	var drw = this.rsets.participant_results_raw;

	//var temp_index = Array();
	//for (var i in drw) {
	//    temp_index.push(Number(i));
	//	}
	//temp_index.sort();
	
	//trace(" === dr === ");
	//_root.md.controler.tracer(dr,   " ", " ");
	//trace(" === drw === ");
	//_root.md.controler.tracer(drw, " ", " ");
	//trace(temp_index);
	//trace("len = " + drw.length);

	for (var i in this.teams) {
	    var team = this.teams[i];
	    if (! dr[team.team]) {
		trace("removing " + team.team);
		team.removeMovieClip();
		this.teams.splice(i, 1);
	    }
	}

	var x = 6;
	var y = 6;

	function inc_pos() {
	    y += 25;
	    if (y > 330) {
		y = 6;
		x += 45;
	    }
	}	

	for (var j = 0; j < drw.length; j++) {
	    //var i = String(j);
	    var i = j;
	    var team = drw[i].by_name.team;

	    if (this.teams[team]) {
		if (! this.teams[team].holder) {
		    this.teams[team]._x = x;
		    this.teams[team]._y = y;
		    //trace("moving " + team);
		} else {
		    //trace("leaving " + team);
		}
	    } else {
		//trace("creating " + team);
		c.attachMovie("mini_team", "team_" + team, c.getNextHighestDepth());
		var temp = c["team_" + team];
		this.teams[team] = temp;
		temp._x = x;
		temp._y = y;
		temp.set_data(team);
		temp.handle_over = function(num) {
		    self.set_status("Team <b>" + num + "</b>: " + self.rsets.participant_results[num]["team name"]);
		}
		temp.handle_out = function(num) {
		    self.set_status("");
		}
		temp.handle_drop = function(num) {
		    self.drop(num, null);
		}
	    }
	    inc_pos();
	}
    }

    private function find_over(t) {
	for (var i = 0; i < this.holders.length; i++) {
	    if (t.hitTest(this.holders[i].hitbox)) {
		return this.holders[i];
	    }
	}
	return null;
    }

    private function get_holder(team, subteam) {
	return this.content["team_" + team + "_" + subteam];
    }
    private function get_team(team) {
	return this.teams[team];
    }

    private function place(h, t) {
	if (h.holding) {
	    h.holding.holder = null;
	    h.holding        = null;
	}
	if (t.holder) {
	    t.holder.holding = null;
	    t.holder         = null;
	}

	t._x = h._x;
	t._y = h._y;
	h.holding = t;
	t.holder  = h;
    }

    private function drop(num, over) {
	var self = this;
	var c    = this.content;

	var t = this.teams[num];

	var h = over;
	if (null == over) {
	    h = this.find_over(t);
	}

	//trace("dropping " + t + " onto " + h);

	if (! h) {
	    if (t.holder) {
		var temp = t.holder;
		t.holder     = null;
		temp.holding = null;
		this.handle_drop(t.team, temp.team, temp.subteam);
	    }
	} else {
	    if (h.holding) {
		trace("!!! cannot hold more than one team");
		return 
	    }
	    if ((t.holder) && 
		(t.holder != h)) {
		var temp = t.holder;
		t.holder.holding = null;
		t.holder         = null;
		this.place(h,t);
		this.handle_move(t.team, temp.team, temp.subteam, h.team, h.subteam);
	    } else {
		this.place(h,t);
		this.handle_join(t.team, h.team, h.subteam);
	    }
	}
    }

    public function set_data(rset) {
	var rows = rset.rows;

	for (var i in this.holders) {
	    var holder = this.holders[i];
	    holder.valid = false;
	}

	for (var i = 0; i < rows.length; i++) {
	    var row = rows[i].by_name;
	    var number   = Number(row['team_number']);
	    var alliance = Number(row['finals_alliance_number']);
	    var order    = Number(row['recruit_order']);
	    
	    var team   = this.get_team(number);
	    var holder = this.get_holder(alliance, order);

	    holder.valid = true;

	    this.place(holder, team);
	}

	for (var i in this.holders) {
	    var holder = this.holders[i];
	    
	    if ((! holder.valid) &&
		(holder.holding)) {
		holder.holding.holder = null;
		holder.holding = null;
	    }

	}

	this.update_teams();
    }

    public function set_status(s:String) {
	var c:MovieClip = this.content;
	c.text_status.htmlText = s;
    }

}
