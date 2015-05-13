class c_team extends component {
    private var mode_key :String;
    private var match_key:String;
    private var score_key:String;

    private var mode:String;

    public var match_level :Number;
    public var match_number:Number;
    public var match_index :Number;

    private var got_mode:Boolean;
    private var got_id  :Boolean;
    private var got_data:Boolean;

    public var flipper   :MovieClip;
    public var score_text:MovieClip;

    public var color:Number;

    public var teams    :Array;
    public var score    :String;
    public var score_rts:String;

    public var color_name:String;

    public function c_team() {
	super();
	trace("c_team: made");

	this.mode_key  = null;
	this.match_key = null;
	this.score_key = null;

	this.mode = null;

	this.match_level  = null;
	this.match_number = null;
	this.match_index  = null;

	this.got_mode = false;
	this.got_id   = false;
	this.got_data = false;

	this.color = null;

	this.teams     = [0,0,0];
	this.score     = null;
	this.score_rts = null;

	this.color_name = "";

    }
    public function enter() {
	trace("*** makind c_team with color " + this.color);
	var self:c_team = this;
	if (this.color == 1) {
	    this.color_name = "red";
	} else if (this.color == 2) {
	    this.color_name = "blue";
	}
	trace("c_team: enter: color_name="+ this.color_name);
	this.flipper.gotoAndStop(2);
	this.exit();
	this.req();
    }
    public function exit() {
	this.got_id   = false;
	this.got_mode = false;
	this.got_data = false;
	if (this.match_key) {
	    this.d.cc.unwatch_env("current_match", this.match_key);
	    this.match_key = null;
	}
	if (this.mode_key) {
	    this.d.cc.unwatch_env("scores_source", this.mode_key);
	    this.mode_key = null;
	}
	if (this.score_key) {
	    this.d.cc.unwatch_env(this.color_name + "_score", this.score_key);
	    this.score_key = null;
	}
    }
    public function req() {
	trace("req: color[" + this.color + "]");
	var self:c_team = this;
	if (this.got_data) {
	    trace("got all, readying");
	    this.fill_data();
	    this.am_ready();
	} else if (this.got_mode) {
		trace("requesting match info");
		self.d.cc.query("SELECT * FROM alliance_team " + 
				"WHERE match_level = " + this.match_level +
				" AND match_number = " + this.match_number +
				" AND match_index  = " + this.match_index +
				" AND alliance_color_id = " + this.color, 
				function(a,b) { self.on_data(a,b); }, 1, {rset: 'alliance_team'});
		if (not this.score_key) {
		    trace("requesting rts score");
		    this.score_key = this.d.cc.watch_env(this.color_name + "_score",
							 function(a,b,c) { self.watch_current_match(a,b,c); });
		}
	} else if (this.got_id) {
	    if (not this.mode_key) {
		trace("requesting mode");
		this.mode_key = this.d.cc.watch_env("scores_source",
						    function(a,b,c) { self.watch_current_match(a,b,c); });
	    }

	} else if (not this.match_key) {
	    trace("requesting match id");
	    this.match_key = this.d.cc.watch_env("current_match",
						 function(a,b,c) { self.watch_current_match(a,b,c); });
	}
    }

    public function on_data(ress, options) {
	trace("on_data: got rset " + options.rset);
	if (options.rset == "alliance_team") {
	    var temp = this.d.cc.format_rset(ress[0].rset, ['position']);
	    this.score = null;
	    for (var i = 1; i <= 3; i++) {
		var team = temp[i];
		trace("on_data: color[" + this.color + "] pos[" + i + "] score[" + team.score + "] team_number[" + team.team_number + "]");
		if (team.score != "0") {
		    this.score = team.score;
		}
		if (this.score == null) {
		    this.score = "0";
		}
		this.teams[i-1] = team.team_number;
	    }
	    this.got_data = true;
	    this.req();
	}
    }

    public function watch_current_match(key, old_val, new_val) {
	trace("c_team: got env " + key);
	if (key == "scores_source") {
	    this.mode = new_val;
	    this.got_mode = true;
	    this.req();
	} else if (key == this.color_name + "_score") {
	    this.score_rts = new_val;
	    this.got_data = true;
	    this.req();
	} else if (key == "current_match") {
	    trace("watch_current_match: color[" + this.color + "] " + old_val + " / " + new_val);
	    var temp = new_val.split(".");
	    this.match_level  = Number(temp[0]);
	    this.match_number = Number(temp[1]);
	    this.match_index  = Number(temp[2]);
	    this.got_data = false;
	    this.got_mode = false;
	    this.got_id   = true;
	    this.req();
	}
    }

    public function fill_data() {
	trace("fill_data: color[" + this.color + "] flipper=[" + this.flipper + "] mode [" + this.mode + "]");
	this.flipper.team0.set_data(this.teams[0]);
	this.flipper.team1.set_data(this.teams[1]);
	this.flipper.team2.set_data(this.teams[2]);
	if (this.mode == "rts") {
	    this.score_text.set_data(this.score_rts);
	} else if (this.mode == "db") {
	    this.score_text.set_data(this.score);
	} else {
	    trace("!!! c_match: unknown score source [" + this.mode + "]");
	    this.score_text.set_data(this.score);
	}
    }
}
