class c_rankings extends component {
    private var rset_key:String = null;

    private var got_data :Boolean = false;

    public var current_teams:Array;
    public var new_teams:Array;

    public var field_text:MovieClip;

    public var last_box :MovieClip = null;
    public var last_team:Number    = null;
    public var entities :Array;
    public var pane     :MovieClip;

    public function c_rankings() {
	super();
	this.current_teams = [];
	this.new_teams     = [];
	this.entities      = [];
	trace("c_rankings: made");
    }
    public function enter() {
	var self:c_rankings = this;
	this.field_text.set_data("Battlecry 9 @WPI", "RANKINGS");
	this.exit();
	this.req();
    }
    public function exit() {
	delete this.onEnterFrame;
	this.got_data = false;
	if (this.rset_key) {
	    this.d.cc.unwatch_rset("participant_results", this.rset_key);
	    this.rset_key = null;
	}
    }
    public function req() {
	trace("rankings req: " + this.got_data);
	var self:c_rankings = this;
	if (this.got_data) {
	    trace("rankings req got all, readying");
	    this.fill_data();
	    this.am_ready();
	    this.onEnterFrame = function() {
		self.update();
	    }
	    return;
	}
	if (not this.rset_key) {
	    trace("requesting rankings rset");
	    this.rset_key = this.d.cc.watch_rset("participant_results",
						 function(a,b) { self.watch_rset(a,b); });
	}
    }

    public function watch_rset(key, rset) {
	if (key == "participant_results") {
	    var teams = [];

	    var rows = rset.rows;

	    for (var i = 0; i < rows.length; i++) {
		var r = rows[i].by_name;
		teams.push({rank: i+1, team: r.team, name: r['team name'], rec: "" + r.wins + "-" + r.losses + "-" + r.ties, avg: r['record']});
	    }

	    this.set_teams(teams);

	    this.got_data = true;
	    this.req();
	}
    }

    public function fill_data() {

    }

    public function set_teams(teams:Array) {
	trace("setting teams (" + teams.length + ")");
	this.new_teams = teams;
    }

    public function new_id() {	    
	    for (var i = 0; i < this.entities.length; i++) {
		if (this.entities[i] == null) {
		    return i;
		}
	    }
	    this.entities[i] = null;
	    return i
	}

    public function new_entity() {
	    //trace("making new entity");
	    if (this.last_team == null) {
		this.last_team = -1;
		this.new_team();
	    } else {
		this.new_team();
	    }
	}

    public function new_team() {
	    //trace("making new team");
	    this.last_team++;
	    if (this.last_team >= this.current_teams.length) {
		this.last_team = null;
		this.current_teams = this.new_teams;
		return;
	    }
	    var id = new_id();
	    this.pane.attachMovie("c_rankings_team", "t" + id, this.pane.getNextHighestDepth()); 
	    var td = this.current_teams[this.last_team];
	    var tr = this.pane["t" + id];
	    this.last_box = tr;
	    this.entities[id] = tr;
	    tr._x = 5;
	    tr._y = 300;
	    //trace("making " + id);
	    //trace("td = " + td);
	    tr.onEnterFrame = function() {
		//trace("entering on " + this);
		//trace("td = " + td);
		this.rank_text.set_data(td.rank);
		this.team_text.set_data(td.team);
		this.name_text.set_data(td.name);
		this.rec_text.set_data(td.rec);
		this.avg_text.set_data(td.avg);
		delete this.onEnterFrame;
	    }
	}

    public function update() {
	//	trace("updating [" + this.entities.length + "]");

	var has = false;

	for (var i = 0; i < this.entities.length; i++) {
	    if (this.entities[i] != null) {
		has = true;
		var e = this.entities[i];
		e._y -= 1;
		if (e == this.last_box) {
		    if (e._y < 255) {
			this.new_entity();
		    }
		}
		if (e._y < -40) {
		    e.removeMovieClip();
		    this.entities[i] = null;
		}
	    }
	}

	if (not has) {
	    this.new_entity();
	}

    }

}
