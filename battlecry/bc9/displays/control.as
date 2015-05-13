class control {
    public var cc:cc_client;

    private var secret:String = "lol";
    private var auth:Boolean  = true; // !!! todo: change this event version if accessible in public spot

    public var handle_connect   :Function = null;
    public var handle_disconnect:Function = null;
    public var handle_pre_ready :Function = null;
    public var handle_full_ready:Function = null;

    private var data_ready:Object;

    public var pre_ready:Boolean;
    public var full_ready:Boolean;

    public var init_done:Boolean;

    private var req_data_int:Number;

    public var rsets:Object;

    public  var state       :String = null;
    private var state_key   :String = null;
    private var substate_key:String = null;

    public var error_message:String = "everything is fine";

    public var w_connection:window_connection;
    public var w_display   :window_display;
    public var w_clock     :window_clock;
    public var w_match     :window_match;
    public var w_pairings  :window_pairings;
    public var w_config    :window_config;
    public var w_scripts   :window_scripts;

    public function control() {
	// trace("control: made");
	this.cc = new cc_client();

	this.rsets = new Object();

	var self:control = this;

	this.data_ready = {display_state:       false,
			   display_type:        false,
			   display_substate:    false,
			   game_state:          false,
			   match_level:         false,
			   participant_results: false
	};
	this.pre_ready  = false;
	this.full_ready = false;

	this.init_done = false;

	this.cc.handle_connect = function() {
	    self.handle_connect();
	    self.req_data();
	    self.update_window_connection();
	}

	this.cc.handle_disconnect = function() {
	    self.handle_disconnect();
	    self.update_window_connection();
	}
    }

    public function connect() {
	this.cc.net.connect();
    }

    public function disconnect() {
	this.cc.net.disconnect();
	if (this.req_data_int) {
	    clearInterval(this.req_data_int);
	    this.req_data_int = 0;
	}
	this.pre_ready  = false;
	this.full_ready = false;
	//	this.rsets = new Object();
    }

    public function cancel() {
	this.cc.net.cancel();
    }

    public function req_data() {
	var self:control = this;

	if (this.pre_ready) {
	    return;
	}

	var all_ready = true;
	for (var key in this.data_ready) {
	    if (not this.data_ready[key]) {
		trace("rset " + key + " not ready, requesting");
		all_ready = false;
		this.cc.query("SELECT * FROM " + key, function(a,b) { self.got_db_req(a,b) }, 1, {rset: key});
	    }
	}
	if (all_ready) {
	    this.pre_ready = true;
	    clearInterval(this.req_data_int);
	    this.req_data_int = null;
	    this.handle_pre_ready();
	    this.init_pre_ready();
	} else {
	    if (not this.req_data_int) {
		this.req_data_int = setInterval(function() { self.req_data() } , 1000);
	    }
	}
    }

    public function format_rset(rset:Object) {
	 var name = rset.name;
	 if (name == "display_type") {
	     return this.cc.format_rset(rset, ['display_type_label']);
	 } else if (name == "display_component_effect") {
	     return this.cc.format_rset(rset, ['substate_label', 'component_label', 'keyframe_index']);
	 } else if (name == "display_state") {
	     return this.cc.format_rset(rset, ['display_type_label', 'state_label']);
	 } else if (name == "game_state") {
	     return this.cc.format_rset(rset, ['state_label']);
	 } else if (name == "display_substate") {
	     return this.cc.format_rset(rset, ['substate_label']);
	 } else if (name == "match_level") {
	     return this.cc.format_rset(rset, ['match_level']);
	 } else if (name == "participant_results") {
	     return this.cc.format_rset(rset, ['team']);
	 }

	 trace("!!! format_rset: don't know how to handle " + name);
	 return rset;
     }

    public function got_db_req(ress, options:Object) {
	//trace("got_db_req: got query results:");
	for (var i = 0; i < ress.length; i++) {
	    var res = ress[i];
	    res.rset.name = options.rset;
	    this.rsets[options.rset] = this.format_rset(res.rset);
	    //trace([options.rset, res.type, res.rset, res.effect].join("\t"));
	    //trace("options.rset = " + options.rset + " and cc_parser.QUERY_RSET = " + cc_parser.QUERY_RSET);
	    if (res.rset.name == "participant_results") {
		this.rsets['participant_results_raw'] = res.rset.rows;
	    }
	    if ((options.rset) and
		(res.type == cc_parser.QUERY_RSET)) {
		this.data_ready[options.rset] = true;
	    }
	}
    }

    public function got_env(key:String, old_val:String, new_val:String) {
	//trace("got_env: " + [key, old_val, new_val].join(","));
	 /*
	   if ((key == "game_state") ||
	     (key == "display_state_" + this.type)) {
	     this.update_state();
	     }
	 */
     }

    public function update_state() {
	/*
	 var state    = this.cc.env['game_state'];
	 var substate = this.cc.env['display_state_' + this.type];
	 var temp = this.rsets['display_state'];
	*/

	 // update the display window here
    }

    public function watch_env(key:String, old_val, new_val) {
	if (key == "overlay") {
	    //trace("setting color to " + new_val);
	    //this.stage.bg.set_color(new_val);
	}
    }

    public function got_env_substate(key:String, old_val:String, new_val:String) {
	var temp = key.split("_state_");
	var type = temp[1];
	this.w_display.set_substate(type, new_val);
    }

    public function got_env_state(key:String, old_val:String, new_val:String) {
	this.w_display.set_state(new_val);
    }

    public function got_env_clock_state(key:String, old_val:String, new_val:String) {
	this.w_clock.set_state(new_val);
    }

    public function got_env_clock_num(key:String, old_val:String, new_val:String) {
	this.w_clock.set_clock(Number(new_val));
    }

    public function got_env_current_match(key:String, old_val:String, new_val:String) {
	var vals = new_val.split(".");
	this.w_match.set_match([Number(vals[0]),
				Number(vals[1]),
				Number(vals[2])]);
    }

    public function got_env_scores_source(key:String, old_val:String, new_val:String) {
	this.w_match.set_source(new_val);
    }

    public function got_env_overlay(key:String, old_val:String, new_val:String) {
	this.w_config.set_overlay(new_val);
    }

    public function got_env_script_conf(key:String, old_val:String, new_val:String) {
	this.w_scripts.set_conf(new_val);
    }

    public function got_rset_pairings(key, rset) {
	this.w_pairings.set_data(rset);
    }

    public function tracer(o, tabs:String, pre:String) {
	if (typeof(o) == "object") {
	    for (var k in o) {
		trace(tabs + pre + "." + k);
		this.tracer(o[k], "\t" + tabs, pre + "." + k);
	    }
	} else if (typeof(o) == "array") {
	    for (var i in o) {
		trace(tabs + pre + "[" + i + "]");
		this.tracer(o[i], "\t" + tabs, pre + "[" + i + "]");
	    }
	} else {
	    trace(tabs + pre + "=" + o);
	}
    }

    public function init_window_pairings() {
	var w = this.w_pairings;
	var self = this;

	w.handle_moveup = function() {
	    
	};

	w.handle_clear = function() {
	    self.cc.query("DELETE FROM finals_alliance_partner;");
	}

	w.handle_drop = function(num, team, subteam) {
	    if (! self.auth) {
		return;
	    }
	    self.cc.query("DELETE FROM finals_alliance_partner WHERE team_number=" + num + ";");
	}

	w.handle_join = function(num, team, subteam) {
	    if (! self.auth) {
		return;
	    }
	    self.cc.query("INSERT INTO finals_alliance_partner VALUES (" + team + "," + subteam + "," + num + ");");
	}

	w.handle_move = function(num, team, subteam, new_team, new_subteam) {
	    if (! self.auth) {
		return;
	    }
	    self.cc.query("UPDATE finals_alliance_partner SET finals_alliance_number=" + new_team + ", recruit_order=" + new_subteam + " WHERE " +
			  "team_number=" + num + ";");
	}

	w.handle_teams = function() {
	    if (! self.auth) {
		return;
	    }
	    self.cc.query("SELECT * FROM participant_results;", function(ress, options) {
		var res  = ress[0];
		res.rset.name = options.rset;

		//self.tracer(res, " ", " ");

		var temp = self.cc.format_rset(res.rset, ['team']);
		self.rsets.participant_results = temp;

		//self.w_pairings.update_new_teams(temp);

		self.w_pairings.update_new_teams(temp, res.rset.rows);
	    }, 1, {rset: "participant_results"});
	}
    }

    public function init_window_config() {
	var w = this.w_config;
	var self = this;

	w.handle_set_overlay = function(overlay:String):Void {
	    self.cc.set_env("overlay", overlay);
	}
    }

    public function init_window_scripts() {
	var w = this.w_scripts;
	var self = this;

	w.handle_run = function(script:String):Void {
	    self.cc.set_env("script_run", script);
	}

	w.handle_set = function(script:String, rate:Number):Void {
	    self.cc.set_env("script_arg1", script);
	    self.cc.set_env("script_arg2", rate);
	    self.cc.set_env("script_op", "set_rate");
	}
    }

    public function init_window_match() {
	var w = this.w_match;
	var self = this;

	w.handle_set_match = function(match_id:Array):Void {
	    self.cc.set_env("current_match", match_id.join("."));
	}

	w.handle_set_source = function(source:String):Void {
	    self.cc.set_env("scores_source", source);
	}
    }

    public function init_window_clock() {
	var w = this.w_clock;
	var self = this;

	w.handle_set_clock = function(num:Number) {
	    if (self.auth) {
		self.cc.set_env("clock", num);
	    }
	}

	w.handle_set_state = function(state:String) {
	    if (self.auth) {
		self.cc.set_env("clock_state", state);
	    }
	}
    }

    public function update_window_connection() {
	var w: window_connection = this.w_connection;

	w.connecting = this.cc.net.connecting;
	w.connected  = this.cc.net.connected;
	w.update_enables();
    }

    public function init_window_connection() {
	var w:window_connection = this.w_connection;
	var self = this;

	w.content.text_host.text = this.cc.net.server_host;
	w.content.text_port.text = this.cc.net.server_port;

	w.handle_connect = function() {
	    var c:MovieClip      = w.content;

	    if (! self.auth) { return; }

	    self.connect();
	    self.update_window_connection();

	};
	w.handle_disconnect = function() {
	    var c:MovieClip      = w.content;

	    if (! self.auth) { return; }

	    self.disconnect();
	    self.update_window_connection();

	};
	w.handle_cancel = function() {
	    var c:MovieClip      = w.content;

	    if (! self.auth) { return; }

	    self.cancel();
	    self.update_window_connection();

	};
	w.handle_set_remote = function(host:String, port:String, retry:Boolean) {
	    var c:MovieClip      = w.content;

	    self.cc.net.server_host = host;
	    self.cc.net.server_port = Number(port);
	    self.cc.net.retry = retry;

	}
	w.handle_set_pass = function(pass:String) {
	    var c:MovieClip = w.content;
	    if (pass != self.secret) {
		self.auth = false;
	    } else {
		self.auth = true;
	    }
	}
    }

    public function init_pre_ready() {
	var self = this;

	if (! this.init_done) {
	    this.w_display.handle_set_substate = function(type:String, substate:String) {
		self.cc.set_env("display_state_" + type, substate);
	    }
	    this.w_display.handle_set_state = function(state:String) {
		self.cc.set_env("game_state", state);
	    }
	    this.w_display.fill_gui(this.rsets);
	    this.w_pairings.fill_gui(this.rsets);
	    this.init_done = true;
	}

	for (var k in this.rsets.display_type) {
	    this.cc.watch_env("display_state_" + k,
			      function(a,b,c) { self.got_env_substate(a,b,c); });
	}

	this.cc.watch_env("game_state",
			  function(a,b,c) { self.got_env_state(a,b,c); });

	this.cc.watch_env("clock_state",
			  function(a,b,c) { self.got_env_clock_state(a,b,c);});

	this.cc.watch_env("clock",
			  function(a,b,c) { self.got_env_clock_num(a,b,c);});

	this.cc.watch_env("current_match",
			  function(a,b,c) { self.got_env_current_match(a,b,c); });

	this.cc.watch_env("scores_source",
			  function(a,b,c) { self.got_env_scores_source(a,b,c); });

	this.cc.watch_env("overlay",
			  function(a,b,c) { self.got_env_overlay(a,b,c); });

	this.cc.watch_env("script_conf",
			  function(a,b,c) { self.got_env_script_conf(a,b,c); });

	this.cc.watch_rset("finals_alliance_partner",
			   function(a,b) { self.got_rset_pairings(a,b); });


    }

}
