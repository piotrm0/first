import mx.containers.Window;

class window_match extends Window {
    public var handle_set_match:Function;
    public var handle_set_source:Function;

    public var match_id:Array;
    public var match_id_view:Array;

    public var match_id_min:Array = [-1,0,0];
    public var match_id_max:Array = [4,999,3];

    private var match_id_boxes:Array;
    private var match_id_buttons_up:Array;
    private var match_id_buttons_down:Array;

    public function window_match() {
	super();
	//trace("window_match: made");
        this.match_id      = [0,0,0];
	this.match_id_view = [0,0,0];
    }

    private function init() {
	super.init();
	this.setSize(185,150);
	this.title = "Control Current Match";
	this.contentPath = "window_match_content";
    }

    public function init_gui() {
	var self = this;
	var c:MovieClip = this.content;

	this.match_id_boxes        = [c.box_level,         c.box_number,         c.box_index];
	this.match_id_buttons_up   = [c.button_level_up,   c.button_number_up,   c.button_index_up];
	this.match_id_buttons_down = [c.button_level_down, c.button_number_down, c.button_index_down];

	for (var i = 0; i < this.match_id_boxes.length; i++) {
	    this.match_id_buttons_up[i].i   = i; // gawd dynamic scoping or what ?
	    this.match_id_buttons_down[i].i = i;

	    this.match_id_buttons_up[i].onPress = function() {
		if (self.match_id_view[this.i] < self.match_id_max[this.i]) {
		    self.match_id_view[this.i] += 1;
		}
		self.update_gui();
	    }
	    this.match_id_buttons_down[i].onPress = function() {
		if (self.match_id_view[this.i] > self.match_id_min[this.i]) {
		    self.match_id_view[this.i] -= 1;
		}
		self.update_gui();
	    }
	}

	c.button_set.onPress = function() {
	    for (var i = 0; i < self.match_id_boxes.length; i++) {
		self.match_id_view[i] = Number(self.match_id_boxes[i].text);
	    }
	    self.handle_set_match(self.match_id_view);
	    self.update_gui();
	}

	this._parent.controler.init_window_match();
	this.update_gui();
    }

    private function update_gui() {
	var self = this;
	var c:MovieClip = this.content;

	for (var i = 0; i < this.match_id_boxes.length; i++) {
	    this.match_id_boxes[i].text = this.match_id_view[i];
	    this.match_id_buttons_up[i].enabled   = (this.match_id_view[i] < this.match_id_max[i]);
	    this.match_id_buttons_down[i].enabled = (this.match_id_view[i] > this.match_id_min[i]);
	}
    }

    public function set_match(match_id:Array) {
	this.match_id = match_id;
	this.match_id_view = match_id;
	this.update_gui();
    }

    public function set_source(source:String) {
	var self = this;
	var c:MovieClip = this.content;

	if (source == "rts") {
	    c.source_rts.selected = true;
	} else if (source == "db") {
	    c.source_db.selected = true;
	} else {
	    trace("!!! unknown score source [" + source + "]");
	}
    }
}
