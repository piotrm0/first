class stage_spin extends MovieClip {
    private static var rbox_scale    :Number = 55;
    private        var rbox_positions:Array  = null;

    private static var num_rboxes = 18;

    private static var rbox_pos_delta_x = [ 1, 1, 1, 1, 1, 0, 0, 0, 0,-1,-1,-1,-1,-1, 0, 0, 0, 0];
    private static var rbox_pos_delta_y = [ 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0,-1,-1,-1,-1];

    private var rboxes = null;

    private var state:Array = null;

    private var int_spin           = null;

    private static var rbox_config = [[250,  0, 0, 1],
				      [500,  0, 0, 1],
				      [750,  0, 0, 1],
				      [1000, 0, 0, 2],
				      [1250, 0, 0, 2],
				      [1500, 0, 0, 2],
				      [1750, 0, 0, 2],
				      [2000, 0, 0, 3],
				      [2250, 0, 0, 3],
				      [2500, 0, 0, 3],
				      [2750, 0, 0, 3],
				      [3000, 0, 0, 4],
				      [2000, 1, 0, 4],
				      [1000, 2, 0, 4],
				      [1000, 0,-1 ,5],
				      [0,    0, 1, 6],
				      [0,    0, 1, 6],
				      [0,    0, 1, 6]];

    public function is_spinning():Boolean {
	return (null != this.int_spin);
    }

    public function switch_spin():Void {
	if (this.is_spinning()) {
	    this.stop_spin();
	} else {
	    this.start_spin();
	}
    }

    public function start_spin():Void {
	if (null != this.int_spin) { // already spinning
	    return;
	}
	var self = this;
	this.int_spin = setInterval(function() { self.update_spin(); }, 500);

	var temp_type = this.state[this.state[0]];
	var temp_rbox = this.rboxes[temp_type];
	temp_rbox.set_highlight(true, false);
    }

    public function stop_spin():Void {
	if (null == this.int_spin) { // not spinning
	    return;
	}

	clearInterval(this.int_spin);
	this.int_spin = null;

	var temp_type = this.state[this.state[0]];
	var temp_rbox = this.rboxes[temp_type];
	temp_rbox.set_highlight(true, true);
    }

    public function get_res():Array {
	var temp_type = this.state[this.state[0]];
	return stage_spin.rbox_config[temp_type];
    }

    public function stop_live():Array {
	this.stop_spin();
	// todo: do some animation and sound stuff here
	// todo: transmit final state if needed, not sure

	var ret = this.get_res();

	if (ret[2] > 0) {
	    _root.ui.click_play_whammy();
	} else if ((ret[1] > 1) ||
		   (ret[0] >= 2500) ||
		   (ret[2] < 0)) {
	    _root.ui.click_play_win_big();
	} else {
	    _root.ui.click_play_win();
	}

	return ret;
    }

    public function update_spin():Void {
	this.mark();
    }

    public function mark():Void {
	this.set_state(stage_spin.gen_state());
    }

    private static function gen_state():Array {
	var high = random(stage_spin.num_rboxes) + 1;

	var temp = Array();
	temp.push(high);
	for (var i = 1; i <= stage_spin.num_rboxes; i++) {
	    temp.push(i-1);
	}
	for (var i = 1; i <= stage_spin.num_rboxes; i++) {
	    var temp_index = random(stage_spin.num_rboxes) + 1;
	    var temp_val   = temp[i];
	    temp[i] = temp[temp_index];
	    temp[temp_index] = temp_val;
	}

	return temp;
    }

    public function get_state():Array {
	return this.state;
    }

    public function set_state(state:Array):Void {
	var spinning:Boolean = this.is_spinning();
	var temp_highlight = state[state[0]];
	this.state = state;
	for (var i = 1; i <= stage_spin.num_rboxes; i++) {
	    var temp_type = state[i];
	    var temp_rbox = this.rboxes[temp_type];
	    temp_rbox._x = this.rbox_positions[i-1][0];
	    temp_rbox._y = this.rbox_positions[i-1][1];
	    temp_rbox._xscale = stage_spin.rbox_scale;
	    temp_rbox._yscale = stage_spin.rbox_scale;
	    temp_rbox.set_highlight(temp_type == temp_highlight, ! spinning);
	}
    }

    public function stage_spin() {
	super();
	this.rbox_positions = new Array();
	this.rboxes         = new Array();
	this.compute_rbox_positions();
	this.create_rboxes();
    }

    private function compute_rbox_positions():Void {
	var xd = 104;
	var yd = 82;
	var x = 16;
	var y = 16;
	for (var i = 0; i < stage_spin.rbox_pos_delta_x.length; i++) {
	    this.rbox_positions.push([x,y]);
	    x += xd * stage_spin.rbox_pos_delta_x[i];
	    y += yd * stage_spin.rbox_pos_delta_y[i];
	}
    }

    private function create_rboxes():Void {
	for (var i = 0; i < stage_spin.rbox_pos_delta_x.length; i++) {
	    this.attachMovie("rbox", "rbox_" + i, this.getNextHighestDepth());
	    var b = this['rbox_' + i];
	    this.rboxes.push(b);

	    //b.set_type(rbox.TYPE_ONE_LINE);
	    //b.set_data(i+1, "", "");
	    b.set_worth(stage_spin.rbox_config[i][0],
			stage_spin.rbox_config[i][1],
			stage_spin.rbox_config[i][2]);
	    b.set_color(stage_spin.rbox_config[i][3]);

	    b._x = this.rbox_positions[i][0];
	    b._y = this.rbox_positions[i][1];
	    b._xscale = stage_spin.rbox_scale;
	    b._yscale = stage_spin.rbox_scale;
	}
    }
}
