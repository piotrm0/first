class c_pairings extends component {
    private var rset_key:String;
    private var got_data :Boolean;
    public var field_text:MovieClip;
    private var teams:Object;
    private var map:Array;
    private var c1:MovieClip;
    private var c2:MovieClip;
    private var c3:MovieClip;
    private var c4:MovieClip;
    private var page:MovieClip;

    public function c_pairings() {
	super();
	this.rset_key = null;
	this.got_data = false;
	this.teams    = null;
	this.map = [this.c1, this.c2, this.c3, this.c4];
	//trace("this.c1 = " + this.c1);
	//trace("c_pairings: made");
    }
    public function enter() {
	var self:c_pairings = this;
	this.field_text.set_data("Battlecry 9 @WPI", "PAIRINGS");
	this.exit();

	this.page.pane.onEnterFrame = function() {
	    self.update();
	}

	this.req();
    }
    public function exit() {
	delete this.page.pane.onEnterFrame;
	this.got_data = false;
	if (this.rset_key) {
	    this.d.cc.unwatch_rset("finals_alliance_partner", this.rset_key);
	    this.rset_key = null;
	}
    }
    public function req() {
	//trace("pairings req: " + this.got_data);
	var self:c_pairings = this;
	if (this.got_data) {
	    //trace("pairings req got all, readying");
	    this.fill_data();
	    this.am_ready();
	    return;
	}
	if (not this.rset_key) {
	    //trace("requesting pairings rset");
	    this.rset_key = this.d.cc.watch_rset("finals_alliance_partner",
						 function(a,b) { self.watch_rset(a,b); });
	}
	if (not this.got_data) {
	    self.d.cc.query("SELECT team FROM participant_results",
			    function(a,b) { self.on_data(a,b); }, 1, {rset: 'participant_results'});
	}
    }

    public function on_data(ress, options) {
	//	trace("on_data: got rset " + options.rset);
	if (options.rset == "participant_results") {
	    this.teams = new Object();
	    var temp = ress[0].rset.rows;

	    for (var i = 0; i < temp.length; i++) {
		//		trace("on_data: recording row " + i + " team " + row['team']);
		var row = temp[i].by_name;
		this.teams[row['team']] = false;
	    }

	    this.got_data = true;
	    this.req();
	}
    }

    public function watch_rset(key, rset) {
	//trace("got rset " + key);
	if (key == "finals_alliance_partner") {
	    var used = new Object();

	    var first_a = -1;
	    var last_a  = -1;
	    var last_o  = -1;

	    for (var team in this.teams) {
		this.teams[team] = false;
	    }

	    var rows = rset.rows;

	    for (var i = 0; i < rows.length; i++) {
		var row      = rows[i].by_name;
		var number   = Number(row['team_number']);
		var alliance = Number(row['finals_alliance_number']);
		var order    = Number(row['recruit_order']);
		//		trace("team " + number + " is present");

		if (not used.hasOwnProperty(alliance)) {
		    used[alliance] = new Object();
		}
		
		if (number == "0") {
		    used[alliance][order] = false;
		} else {
		    if (order > last_o) {
			first_a = alliance;
			last_a  = alliance;
			last_o  = order;
		    }
		    if ((order == last_o) &&
			(alliance > last_a)) {
			last_a = alliance;
		    }
		    if ((order == last_o) &&
			(alliance < first_a)) {
			first_a = alliance;
		    }

		    used[alliance][order] = true;
		    this.teams[number] = true;
		    var t = this.page.pane["alliance" + alliance];
		    //		    trace("is selected on " + t);
		    t.set_number(alliance);
		    t.set_team(Number(order), number);
		}
	    }

	    for (var a = 1; a <= 16; a++) {
		for (var o = 1; o <= 3; o++) {
		    if (not used[a][o]) {
			var t = this.page.pane["alliance" + a];
			t.set_team(o, "-");
		    }
		}
	    }

	    //trace(" *** " + last_o + " / " + last_a + " *** ");

	    //if ((last_o == 3) &&
	    //(last_a == 16)) {
	    //this.retarget(-1);



	    if ((last_o == 3) &&         // everything filled, scroll
		(first_a == 1) &&
		(last_a  == 16)) {
		this.retarget(-1);
	    } else if ((last_o == 2) &&  // picks not complete, show last picked
		       (last_a != 16)) {
		this.retarget(last_a);   
	    } else if ((last_o == 2) &&  // picks complete, don't know direction of draft, so lets just scroll
		       (last_a == 16)) {
		this.retarget(-1);
	    } else if ((last_o == 3) &&  // forward draft, show first filled spot
		       (last_a != 16)) {
		this.retarget(last_a);
	    } else if ((last_o == 3) &&  // backward draft, show last filled draft
		       (first_a != 1)) {
		this.retarget(first_a);
	    } else if ((last_o == 1) &&  // (custom?) ranking order not complete, show last filled captain
		       (last_a != 16)) {
		this.retarget(last_a);
	    } else if ((last_o == 1) &&  // show first pick
		       (last_a == 16)) {
		this.retarget(1);
	    }  else if ((last_a == -1) && // nothing filled, scroll
			(last_o == -1)) {
		this.retarget(-1);
	    } else {
		trace("!!! do not know how to retarget last_o=" + last_o + " first_a=" + first_a + " last_a=" + last_a);
	    }

	    this.req();
	}
    }

    public function fill_data() {
	var cols = [[], [], [], []];
	var col = 0;

	var keys = new Array();

	for (var t in this.teams) {
	    keys.push(Number(t));
	}

	/*
	keys.sort(function(a,b) {
	    //trace("compare " + a + " and " + b);
	    if (Number(a) < Number(b)) {
		return -1;
	    } else if (Number(b) > Number(a)) {
		return 1;
	    } else {
		return 0;
	    }
	});
	*/
	keys.sort(Array.NUMERIC);

	for (var i = 0; i < keys.length; i++) {
	    var team = keys[i];
	    if (this.teams[team]) {
		
	    } else {
		//		trace("adding team " + team + " to sides");
		cols[col].push(team);
		if (cols[col].length == 15) {
		    col++;
		}
	    }
	}
	for (var i = 0; i < 4; i++) {
	    var temp = cols[i].join("\n");
	    this.map[i].set_data(temp);
	    //	    trace("adding " + temp + " to " + this.map[i]);
	}
    }

    public function retarget(alliance) {
	var p = this.page.pane;
	//trace("targeting on " + t);
	
	if (alliance == -1) {
	    p.mode = "go_down";
	    //trace(" *** going down ***");
	} else {
	    p.mode = "target";
	   
	    var t = this.page.pane['alliance' + alliance];

	    p.ty = -(alliance - 1) * 45 + 3.5 * 45;
	    if (p.ty > 0) {
		p.ty = 0;
	    } else if (p.ty < -8 * 45) {
		p.ty = -8 * 45;
	    }
	}
    }

    public function update() {
	var p = this.page.pane;
	if (p.mode == "target") {
	    //	    p._x += (p.tx - p._x) / 5;
	    p._y += (p.ty - p._y) / 5;
	    //	    p._xscale += (p.txscale - p._xscale) / 5;
	    //	    p._yscale += (p.tyscale - p._yscale) / 5;
	} else if (p.mode == "wait_down") {
	    p.count--;
	    if (p.count < 0) {
		p.mode = "go_down";
	    }
	} else if (p.mode == "wait_up") {
	    p.count--;
	    if (p.count < 0) {
		p.mode = "go_up";
	    }
	} else if (p.mode == "go_down") {
	    p._y += 1;
	    if (p._y > 0) {
		p.count = 100;
		p.mode = "wait_up";
	    }

	} else if (p.mode == "go_up") {
	    p._y -= 1;
	    if (p._y < -360) {
		p.count = 100;
		p.mode = "wait_down";
	    }
	}
    }
}
