class c_ondeck extends component {
    private var match_key:String = null;

    public var match_level :Number = null;
    public var match_number:Number = null;
    public var match_index :Number = null;

    private var got_id   :Boolean = false;
    private var got_data :Boolean = false;
    private var got_data2:Boolean = false;

    public var match0:MovieClip;
    public var match1:MovieClip;
    public var match2:MovieClip;

    public var matches:Array;
    public var received:Array;

    public function c_ondeck() {
	super();
	trace("c_team: made");
	this.matches  = [null, null, null];
	this.received = [false, false, false];
    }
    public function enter() {
	var self:c_ondeck = this;
	for (var i = 0; i < 3; i++) {
	    this['match' + i].blue_flipper.gotoAndStop(2);
	    this['match' + i].red_flipper.gotoAndStop(2);
	}
	this.exit();
	this.req();
    }
    public function exit() {
	this.got_id    = false;
	this.got_data  = false;
	this.got_data2 = false;
	if (this.match_key) {
	    this.d.cc.unwatch_env("current_match", this.match_key);
	    this.match_key = null;
	}
    }
    public function req() {
	var self:c_ondeck = this;
	if (this.got_data2) {
	    trace("got all, readying");
	    this.fill_data();
	    this.am_ready();
	    return;
	}
	if (this.got_data) {
	    for (var i = 0; i < 3; i++) {
		var temp = this.matches[i];
		if (temp) {
		    this.d.cc.query("SELECT * FROM alliance_team" +
				    " WHERE match_level = " + temp.level +
				    " AND match_number = " + temp.number +
				    " AND match_index = " + temp.index,
				    function(a,b) { self.on_data(a,b) },
				    1,
		    {rset: 'match_data', match: i});
		}
	    }
	    return;
	}
	if (this.got_id) {
	    trace("requesting match info");
	    self.d.cc.query("SELECT * FROM ondeck_match LIMIT 3",
			    function(a,b) { self.on_data(a,b); }, 1, {rset: 'ondeck_match'});
	    // request match info here
	    return
	}
	if (not this.match_key) {
	    trace("requesting match id");
	    this.match_key = this.d.cc.watch_env("current_match",
						 function(a,b,c) { self.watch_current_match(a,b,c); });
	}
    }

    public function on_data(ress, options) {
	trace("on_data: got rset " + options.rset);
	if (options.rset == "ondeck_match") {
	    var temp = ress[0].rset.rows;
	    //	    var temp = this.d.cc.format_rset(ress[0].rset, ['position']);
	    for (var i = 0; i < temp.length; i++) {
		trace("on_data: recording row " + i);
		var row = temp[i].by_name;
		this.matches[i] = {level:row.match_level,
				   number:row.match_number,
				   index:row.match_index}
		this['match' + i].name.set_data(this.d.format_match(Number(row.match_level),
								    Number(row.match_number),
								    Number(row.match_index)));
		trace("match: " + row.match_level + "." + row.match_number + "." + row.match_index);
	    }
	    for (var i = temp.length; i < 3; i++) {
		this.matches[i] = null;
	    }
	    this.got_data = true;
	    this.req();
	}
	if (options.rset == "match_data") {
	    var i = options.match;
	    
	    trace("ondeck: filling in match " + i);

	    var temp = this.d.cc.format_rset(ress[0].rset, ['alliance_color_id',
							    'position']);
	    
	    // this.d.tracer(temp, "", "temp");

	    for (var c = 1; c <= 2; c++) {
		var color = "red";
		if (c == 2) { color = "blue" };
		var target = this['match' + i][color + "_flipper"];
		for (var t = 1; t <= 3; t++) {
		    var starget = target["t" + t];
		    starget.set_data(temp[c][t].team_number);
		}
	    }

	    if (this.received_all) {
		this.got_data2 = true;
		this.req();
	    }
	}
    }

    public function received_all() {
	for (var i = 0; i < 3; i++) {
	    if (this.matches[i]) {
		if (not this.received[i]) {
		    return false;
		}
	    }
	}
	return true;
    }

    public function watch_current_match(key, old_val, new_val) {
	var temp = new_val.split(".");
	this.match_level  = Number(temp[0]);
	this.match_number = Number(temp[1]);
	this.match_index  = Number(temp[2]);
	this.got_data  = false;
	this.got_data2 = false;
	this.got_id    = true;

	for (var i = 0; i < 3; i++) {
	    this.received[i] = false;
	}

	this.req();
    }

    public function fill_data() {
	//this.flipper.team0.set_data(this.teams[0]);
	//this.flipper.team1.set_data(this.teams[1]);
	//this.flipper.team2.set_data(this.teams[2]);
	//this.score_text.set_data(this.score);
    }
}
