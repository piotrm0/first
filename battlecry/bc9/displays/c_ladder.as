class c_ladder extends component {
    public var match_level :Number;
    public var match_number:Number;
    public var match_index :Number;

    public var last_level:Number;
    public var last_number:Number;

    private var got_id   :Boolean;
    private var got_data :Boolean;

    private var id_key:String;

    public var field_text:MovieClip;
    public var pane     :MovieClip;

    private var target:MovieClip;

    public function c_ladder() {
	super();
	trace("c_ladder: made");
	this.target = null;
	this.match_level  = null;
	this.match_number = null;
	this.match_index  = null;
	this.got_id   = false;
	this.got_data = false;
	this.id_key   = null;

	this.last_level  = null;
	this.last_number = null;
    }
    public function enter() {
	var self:c_ladder = this;
	this.field_text.set_data("Battlecry 9 @WPI", "LADDER");

	this.pane.onEnterFrame = function() {
	    self.update();
	}

	for (var level in this.pane.map) {
	    var level_data = this.pane.map[level];
	    for (var number in level_data) {
		var number_data = level_data[number];
		for (var index in number_data) {
		    var t = number_data[index];
		    //		    trace("set_name " + level + "/" + number + "/" + index);
		    t.set_name(this.d.rsets['match_level'][level].abbreviation,
			       number);
		}
	    }
	}
	this.exit();
	this.req();
    }
    public function exit() {
	delete this.pane.onEnterFrame;
	this.got_id   = false;
	this.got_data = false;
	if (this.id_key) {
	    this.d.cc.unwatch_env("current_match", this.id_key);
	    this.id_key = null;
	}
    }
    public function req() {
	trace("ladder req: " + this.got_data);
	var self:c_ladder = this;
	if (this.got_data) {
	    trace("rankings req got all, readying");
	    this.fill_data();
	    this.am_ready();
	    this.onEnterFrame = function() {
		self.update();
	    }
	    return;
	} else if (this.got_id) {
	    this.d.cc.query("SELECT * FROM alliance_team" +
			    " WHERE match_level > 0" + 
			    " AND ((match_level = 4 AND match_index = 0) OR (match_level < 4 AND match_index = 1))",
			    function(a,b) { self.on_data(a,b)}, 1, {rset: "alliance_team"});
	} else {
	    if (not this.id_key) {
		this.id_key = this.d.cc.watch_env("current_match", function(a,b,c) { self.watch_current_match(a,b,c); });
	    }    
	}
    }

    public function on_data(ress, options) {
	trace("on_data: got rset " + options.rset);
	if (options.rset == "alliance_team") {
	    var temp = ress[0].rset.rows;
	    for (var i = 0; i < temp.length; i++) {
		var row = temp[i].by_name;
		var t = this.pane.map[row.match_level][row.match_number][row.match_index];
		t.set_data_target(row.alliance_color_id,
				  row.position,
				  row.team_number);
	    }
	    this.got_data = true;
	    this.req();
	}
    }

    public function watch_current_match(key, old_val, new_val) {
	trace("watch_current_match: " + old_val + " / " + new_val);
	var temp = new_val.split(".");
	this.match_level  = Number(temp[0]);
	this.match_number = Number(temp[1]);
	this.match_index  = Number(temp[2]);
	this.got_id   = true;
	this.got_data = false;
	this.retarget(match_level, match_number);
	this.req();
    }

    public function fill_data() {

    }

    public function update() {
	var p = this.pane;
	if (p.t < 1) {
	    p.t+= 0.05;
	    //	p._x += (p.tx - p._x) / 5;
	    //	p._y += (p.ty - p._y) / 5;
	    //	p._xscale += (p.txscale - p._xscale) / 5;
	    //	p._yscale += (p.tyscale - p._yscale) / 5;
	    p._x = p.sx + (p.tx - p.sx) * p.t;
	    p._y = p.sy + (p.ty - p.sy) * p.t;

	    var z = (-(p.t*2-1)*(p.t*2-1)+1) * 0.5;
	    
	    p._xscale = (p.sxscale + (p.txscale - p.sxscale) * p.t) / (1+z);
	    p._yscale = (p.syscale + (p.tyscale - p.syscale) * p.t) / (1+z);

	} else {
	    
	}
    }

    public function retarget(level, number) {
	if ((level == 4) &&
	    (this.last_level == 4)) {
	    return;
	}
	if ((level < 1) &&
	    (this.last_level < 1)) {
	    return;
	}
	if ((level  == this.last_level) &&
	    (number == this.last_number)) {
	    return;
	}

	this.last_level  = level;
	this.last_number = number;

	var p = this.pane;
	if (level > 0) {
	    var t = p.map[level][number];
	    if (level == 4) {
		t = t[0];
	    } else {
		t = t[1];
	    }

	    trace("retarget: p=" + p + " t=" + t);

	    if (target) {
		// target._xscale = target.txscale;
		// target._yscale = target.tyscale;
		// target._alpha  = target.talpha;
		target.halo._visible = false;
	    }

	    target = t;

	    t.txscale = t._xscale;
	    t.tyscale = t._yscale;
	    t.talpha  = t._alpha;

	    /*
	    t._xscale += 20;
	    t._yscale += 20;
	    t._alpha   = 100;
	    */
	    t.halo._visible = true;

	    trace("moving");
	    if (true) {
		p.t = 0;

		p.sy = p._y;
		p.sx = p._x;
		p.syscale = p._yscale;
		p.sxscale = p._xscale;

		p.ty = - t._y / 4 - 20;
		p.tx = - t._x / 2;
		p.txscale = 150 - t.txscale;
		p.tyscale = 150 - t.tyscale;
	    } else {
		p.ty = -t._y / 4 + 20;
		p.tx = -t._x / 1.5;
		p.txscale = 180 - t.txscale * 1.2;
		p.tyscale = 180 - t.tyscale * 1.2;
	    }
	} else {
	    trace("showing all");

	    if (target) {
		// target._xscale = target.txscale;
		// target._yscale = target.tyscale;
		// target._alpha  = target.talpha;
		target.halo._visible = false;
	    }

	    p.t = 0;

	    p.sy = p._y;
	    p.sx = p._x;
	    p.syscale = p._yscale;
	    p.sxscale = p._xscale;

	    p.tx = 0;
	    p.ty = 15;
	    p.txscale = 60;
	    p.tyscale = 75;
	}
    }

}
