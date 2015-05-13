import mx.containers.Window;
import mx.controls.DataGrid;

class window_display extends Window {
    private var h:Number = 400;

    private var rsets;

    private var selected_type:String = "nothing";

    private var substate_buttons:Object;
    private var state_buttons   :Object;

    public var handle_set_substate:Function;
    public var handle_set_state   :Function;

    public var types:Object;
    public var state:String;

    public function window_display() {
	super();
	//trace("window_display: made");
    }

    private function init() {
	super.init();
	this.setSize(600, this.h);
	this.title = "Control Display";
	this.contentPath = "window_display_content";

	this.substate_buttons = new Object();
	this.state_buttons    = new Object();

	this.types            = new Object();
	this.state            = "nothing";

    }

    public function init_gui() {
	var c:MovieClip = this.content;
    }

    public function fill_gui(d) {
	this.rsets = d;

	var self = this;
	
	var dt          = d.display_type;
	var ds          = d.game_state;
	var dss         = d.display_substate;
	var c:MovieClip = this.content;

	// create substate buttons

	var x = 10;
	var y = 110;

	for (var label in dss) {
	    var desc  = dss[label].description;

	    c.attachMovie("mini_substate", "substate_" + label, c.getNextHighestDepth());
	    var temp = c["substate_" + label];
	    temp.disable();
	    this.substate_buttons[label] = temp;
	    temp._x = x;
	    temp._y = y;
	    y += 25;

	    if (y + 100 > this.h) {
		y = 110;
		x +=  125;
	    }

	    temp.set_data(label);
	    temp.handle_go = function(sub) {
		self.handle_go(sub);
	    }
	    temp.handle_over = function(sub) {
		self.set_status("Substate <b>" + sub + "</b>: " + self.rsets.display_substate[sub].description);
	    }
	    temp.handle_out = function(sub) {
		self.set_status("");
	    }

	}

	var x = 415;
	var y = 27;

	// create state buttons
	for (var label in ds) {
	    var desc = ds[label].description;
	    
	    c.attachMovie("mini_substate", "state_" + label, c.getNextHighestDepth());

	    var temp = c["state_" + label];
	    temp._xscale = 120;
	    temp._yscale = 120;
	    temp._x = x;
	    temp._y = y;

	    y += 25 * 1.2;

	    this.state_buttons[label] = temp;

	    temp.set_data(label);
	    temp.handle_go = function(sub) {
		self.handle_go_state(sub);
	    }
	    temp.handle_over = function(sub) {
		self.set_status("State <b>" + sub + "</b>: " + self.rsets.game_state[sub].description);
	    }
	    temp.handle_out = function(sub) {
		self.set_status("");
	    }
	}
	

	// fill subtypes and descriptions
	var dat:Array = new Array();
	for (var k in d.display_type) {
	    dat.push(k);
	    self.types[k] = "";
	}
	c.list_type.dataProvider = dat;

	c.list_type.addEventListener("change", {change: function(evt:Object) {
	    self.select_type(evt.target.value);
	}
	});

    }

    private function select_type(s:String) {
	var c:MovieClip = this.content;
	c.text_description.text = this.rsets.display_type[s].description;

	var old_selected   = this.selected_type;
	this.selected_type = s;

	if (s) {
	    for (var b in this.substate_buttons) {
		this.substate_buttons[b].enable();
	    }
	} else {
	    for (var b in this.substate_buttons) {
		this.substate_buttons[b].disable();
	    }
	}

	if (old_selected != s) {
	    this.substate_buttons[this.types[old_selected]].focus(1);
	    this.substate_buttons[this.types[s]].focus(2);
	}

	if ((this.state != "env") && 
	    (this.state != "nothing")) {
	    var temp  = this.rsets["display_state"][old_selected][this.state].substate_label;
	    var temp2 = this.rsets["display_state"][s][this.state].substate_label;

	    this.substate_buttons[temp].focus(1);
	    this.substate_buttons[temp2].focus(3);
	}

    }

    public function set_status(s:String) {
	var c:MovieClip = this.content;
	c.text_status.htmlText = s;
    }

    private function handle_go(s:String) {
	if (! this.selected_type) {
	    return;
	}
	this.handle_set_substate(this.selected_type, s);
    }

    private function handle_go_state(s:String) {
	this.handle_set_state(s);
    }

    public function set_substate(type:String, st:String) {
	var old_substate = this.types[type];
	this.types[type] = st;
	
	if ((type == this.selected_type) && 
	    (old_substate != st)) {
	    this.substate_buttons[old_substate].focus(1);
	    this.substate_buttons[st].focus(2);
	}

	if ((this.state != "env") && 
	    (this.state != "nothing") &&
	    (this.selected_type == type)) {
	    var temp2 = this.rsets["display_state"][type][this.state].substate_label;
	    this.substate_buttons[temp2].focus(3);
	}

    }

    public function set_state(st:String) {
	var old_state = this.state;
	this.state = st;
	
	if (old_state != st) {
	    this.state_buttons[old_state].focus(1);
	    this.state_buttons[st].focus(3);
	}

	if ((this.state == "env") &&
	    (old_state != "env")) {
	    var temp1 = this.rsets["display_state"][this.selected_type][old_state].substate_label;
	    if (this.types[this.selected_type] == temp1) {
		this.substate_buttons[temp1].focus(2);
	    } else {
		this.substate_buttons[temp1].focus(1);
	    }
	}

	if ((this.state != "env") && 
	    (this.state != "nothing") &&
	    (this.selected_type != "nothing")) {
	    var temp1 = this.rsets["display_state"][this.selected_type][old_state].substate_label;
	    var temp2 = this.rsets["display_state"][this.selected_type][this.state].substate_label;
	    if (this.types[this.selected_type] == temp1) {
		this.substate_buttons[temp1].focus(2);
	    } else {
		this.substate_buttons[temp1].focus(1);
	    }
	    this.substate_buttons[temp2].focus(3);
	}

    }
}
