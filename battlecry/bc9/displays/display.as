class display extends MovieClip {
    public var cc:cc_client;

    public var id:Number;

    public var quality_map:Array = ["LOW", "MEDIUM", "HIGH", "BEST"];

    public var handle_connect   :Function = null;
    public var handle_disconnect:Function = null;
    public var handle_pre_ready :Function = null;
    public var handle_full_ready:Function = null;

    public var stage   :MovieClip;
    public var controls:MovieClip;

    private var dcs:Object;

    private var data_ready:Object;

    public var pre_ready:Boolean;
    public var full_ready:Boolean;

    private var req_data_int:Number;

    public var rsets:Object;

    public var type:String = "not set";

    public var quality   :Number  = 1;
    public var fullscreen:Boolean = false;

    public  var state       :String = null;
    private var state_key   :String = null;
    private var substate_key:String = null;

    public var error_message:String = "everything is fine";

    public var color_key:String = null;

    public function display() {
	super();
	//trace("display: made");
	this.cc = new cc_client();

	this.dcs      = new Object();

	var self:display = this;

	this.rsets = new Object();

	this.attachMovie("display_controls", "controls", this.getNextHighestDepth());

	this.data_ready = {display_state:            false,
			   display_effect_option:    false,
			   display_component_effect: false,
			   display_type:             false,
			   display_substate:         false,
			   game_state:               false,
			   match_level:              false};
	this.pre_ready  = false;
	this.full_ready = false;

	this.cc.handle_connect = function() {
	    self.handle_connect();
	    self.req_data();
	}

	this.cc.handle_disconnect = function() {
	    self.handle_disconnect();
	}

	this.controls._visible = false;

	this.controls.onEnterFrame = function() {
	    this.onEnterFrame = null;
	    this.label_id.text = self.id;
	    this.bg.onPress = function() {
		self.controls.startDrag();
		this.onMouseMove = function() {
		    self.stage._x = self.controls._x;
		    self.stage._y = self.controls._y;
		}
	    }
	    this.bg.onRelease = function() {
		self.controls.stopDrag();
		delete this.onMouseMove;
		self.stage._x = self.controls._x;
		self.stage._y = self.controls._y;
	    }
	}

	this.controls.button_zoom_in.onPress = function() {
	    self.stage._xscale *= 1.5;
	    self.stage._yscale *= 1.5;
	}

	this.controls.button_zoom_out.onPress = function() {
	    self.stage._xscale *= 0.8;
	    self.stage._yscale *= 0.8;
	}

	this.stage.onPress = function() {
	    self.controls._visible = not self.controls._visible;
	}
    }

    public function set_quality(qn:Number) {
	this.quality = qn;
	//trace("set_quality: setting to " + qn + "(" + this.quality_map[qn] + ") from " + this._quality);
	this._quality = this.quality_map[qn];
    }

    public function set_fullscreen(f:Boolean) {
	this.fullscreen = f;
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
	var self:display = this;

	if (! self.color_key) {
	    self.color_key = self.cc.watch_env("overlay", function(a,b,c) { self.watch_env(a,b,c) });
	}

	if (this.pre_ready) {
	    return;
	}
	var all_ready = true;
	for (var key in this.data_ready) {
	    if (not this.data_ready[key]) {
		//trace("rset " + key + " not ready, requesting");
		all_ready = false;
		this.cc.query("SELECT * FROM " + key, function(a,b) { self.got_db_req(a,b) }, 1, {rset: key});
	    }
	}
	if (all_ready) {
	    this.pre_ready = true;
	    clearInterval(this.req_data_int);
	    this.req_data_int = null;
	    this.handle_pre_ready();
	} else {
	    if (not this.req_data_int) {
		this.req_data_int = setInterval(function() { self.req_data() } , 1000);
	    }
	}
    }

    public function set_scale(xs:Number, ys:Number) {
	this.stage._xscale = xs;
	this.stage._yscale = ys;
    }

    public function set_id(num:Number) {
	this.id = num;
	this.controls.label_id.text = num;
    }

    public function dc_add(type:String) {
	var self:display = this;
	//trace("adding dc " + type);
	if (this.dcs.hasOwnKey(type)) {
	    //trace("already on stage");
	    return;
	}
	this.stage.masked.attachMovie("c_" + type, type, this.stage.masked.getNextHighestDepth());
	this.dcs[type] = this.stage.masked[type];
	this.dcs[type]._visible = false;
	this.dcs[type].onEnterFrame = function() {
	    delete this.onEnterFrame;
	    this.d = self;
	    this.name = type;
	    this.enter();
	}
	return this.dcs[type];
    }

    public function dc_remove(type:String) {
	this.dcs[type].exit();
	this.dcs[type].removeMovieClip();
	 delete this.dcs[type];
     }

     public function format_rset(rset:Object) {
	 var name = rset.name;
	 if (name == "display_type") {
	     return this.cc.format_rset(rset, ['display_type_label']);
	 } else if (name == "display_component_effect") {
	     return this.cc.format_rset(rset, ['substate_label', 'component_label', 'keyframe_index']);
	 } else if (name == "display_state") {
	     return this.cc.format_rset(rset, ['display_type_label', 'state_label']);
	 } else if (name == "match_level") {
	     return this.cc.format_rset(rset, ['match_level']);
	 }

	 trace("!!! format_rset: don't know how to handle " + name);
	 return rset;
     }

     public function got_db_req(ress, options:Object) {
	 //trace("got_db_req: got query results:")
	 for (var i = 0; i < ress.length; i++) {
	     var res = ress[i];
	     res.rset.name = options.rset;
	     this.rsets[options.rset] = this.format_rset(res.rset);
	     //trace([options.rset, res.type, res.rset, res.effect].join("\t"));
	     //trace("options.rset = " + options.rset + " and cc_parser.QUERY_RSET = " + cc_parser.QUERY_RSET);
	     if ((options.rset) and
		 (res.type == cc_parser.QUERY_RSET)) {
		 this.data_ready[options.rset] = true
	     }

	 }
     }

     public function got_env(key:String, old_val:String, new_val:String) {
	 //trace("got_env: " + [key, old_val, new_val].join(","));
	 if ((key == "game_state") ||
	     (key == "display_state_" + this.type)) {
	     this.update_state();
	 }
     }

     public function update_state() {
	 var state = this.cc.env['game_state'];
	 var substate = this.cc.env['display_state_' + this.type];

	 var temp = this.rsets['display_state'];
	 var active = temp[this.type][state].substate_label;

	 if (not active) {
	     this.error_message = "bad state/substate (" + state + "/" + substate + ")";
	     this.set_state("error");
	     return
	 }

	 if (active == "env") {
	     this.set_state(substate);
	 } else {
	     this.set_state(active);
	 }
     }

     public function set_state(state:String) {
	 //trace("set_state: setting state to " + state);

	 var self:display = this;

	 var data = this.rsets['display_component_effect'][state];

	 var used = new Object();

	 for (var dc in data) {
	     used[dc] = true;

	     var dc_movie:MovieClip;
	     if (this.dcs[dc]) {
		 //trace("set_state: already present");
		 dc_movie = this.dcs[dc];
		 dc_movie.go_keyframe(-1);
	     } else {
		 //trace("set_state: not yet present");
		 dc_movie = this.dc_add(dc);
		 dc_movie.on_ready = function() {
		     //trace("ready 2: " + this.name);
		     self.dc_on_ready(this.name);
		 }
	     }

	     //trace("set_state: need component " + dc);
	     var dc_data = data[dc];
	     var keyframes = [dc_data[0],
			      dc_data[1],
			      dc_data[2]];
	     for (var i = 0; i < keyframes.length; i++) {
		 var keyframe_data = dc_data[i];
		 var class_name = "effect_" + keyframes[i].effect_label;
		 var class_ref = eval(class_name);
		 //		trace("set_state: creating " + class_name + "(" + class_ref + ")");
		 keyframes[i] = new class_ref (dc_movie, keyframe_data);
	     }
	     dc_movie.keyframes = keyframes;

	     for (var i = 0; i < keyframes.length; i++) {
		 keyframes[i].on_done = function() {
		     self.effect_on_done(this.target.name, Number(this.params.keyframe_index));
		 }
	     }

	     if (dc_movie.ready) {
		 dc_movie.enter();
		 dc_movie.go_keyframe(1);
	     }
	 }
	 for (var dc in this.dcs) {
	     if (! used[dc]) {
		 //trace("removing " + dc);
		 this.dcs[dc].go_keyframe(2);
	     }
	 }
     }

     public function dc_on_ready(dc:String) {
	 var dc_movie = this.dcs[dc];
	 //trace("dc_on_ready: dc " + dc + " is ready");
	 //trace("dc_on_ready: current target keyframe is " + dc_movie.target_keyframe);
	 //trace("dc_on_ready: movie is " + dc_movie);
	 if (dc_movie.target_keyframe == -1) {
	     dc_movie.go_keyframe(0);
	     //	    dc_movie._visible = true;
	 }
     }

     public function effect_on_done(dc:String, keyframe:Number) {
	 //trace("effect_on_done: " + dc + ", " + keyframe);
	 var dc_movie = this.dcs[dc];
	 if (keyframe == 0) {
	     dc_movie.keyframes[1].start();
	 } else if (keyframe == 1) {
	     // nothing to do
	 } else if (keyframe == 2) {
	     // remove the movie clip
	     this.dc_remove(dc);
	 }
     }

     public function set_type(type:String) {
	 var self = this;
	 this.cc.unwatch_env("display_state_" + this.type, this.substate_key);
	 this.cc.unwatch_env("game_state", this.state_key);
	 this.type = type;
	 this.state_key = this.cc.watch_env('game_state',
					    function(a,b,c) { self.got_env(a,b,c); });
	 this.substate_key = this.cc.watch_env("display_state_" + this.type,
					       function(a,b,c) { self.got_env(a,b,c); });

	var f = false;

	if (this.rsets['display_type'][type].default_fullscreen == "t") {
	    f = true;
	}

	this.set_fullscreen(f);
	this.set_quality(Number(this.rsets['display_type'][type].default_quality));
    }

    public function watch_env(key:String, old_val, new_val) {
	if (key == "overlay") {
	    //trace("setting color to " + new_val);
	    this.stage.bg.set_color(new_val);
	}
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

    public function format_match_full(level, number, index) {
	var temp = this.rsets['match_level'];
	var text = temp[level].description;
	text += " " + number;
	if (index) {
	    text += "." + index;
	}
	return text;
    }

    public function format_match(level, number, index) {
	var temp = this.rsets['match_level'];
	var text = temp[level].abbreviation;
	text += " " + number;
	if (index) {
	    text += "." + index;
	}
	return text;
    }
}
