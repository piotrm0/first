import mx.containers.Window;
import mx.controls.DataGrid;

class window_clock extends Window {
    public var handle_set_clock:Function;
    public var handle_set_state:Function;

    public var clock_begin = 120;
    public var clock_end   = 0;

    private var clock_state:String;
    private var clock_num  :Number;

    public function window_clock() {
	super();
	//trace("window_clock: made");

	this.clock_state = "stop";
	this.clock_num   = 120;
    }

    private function init() {
	super.init();
	this.setSize(180,150);
	this.title = "Control Clock";
	this.contentPath = "window_clock_content";
    }

    public function init_gui() {
	var self = this;
	var c:MovieClip = this.content;

	c.button_play.onPress = function() {
	    self.handle_set_state("run");
	}
	c.button_stop.onPress = function() {
	    self.handle_set_state("stop");
	}
	c.button_begin.onPress = function() {
	    self.handle_set_clock(self.clock_begin);
	}
	c.button_end.onPress = function() {
	    self.handle_set_clock(self.clock_end);
	}
	c.button_set.onPress = function() {
	    var temp = Number(c.text_set.text);
	    if (temp) {
		self.handle_set_clock(temp);
	    }
	}

	this._parent.controler.init_window_clock();
	this.update_gui();
    }

    public function set_clock(num:Number) {
	this.clock_num = num;
	this.update_gui();
    }

    public function set_state(state:String) {
	this.clock_state = state;
	this.update_gui();
    }

    private function update_gui() {
	var c = this.content;

	var minutes = int(this.clock_num / 60);
	if (minutes < 10) {
	    minutes = "0" + minutes;
	}
	var seconds = this.clock_num % 60;
	if (seconds < 10) {
	    seconds = "0" + seconds;
	}

	c.text_clock_num.text = minutes + ":" + seconds;

	if ("run" == this.clock_state) {
	    c.button_play.enabled = false;
	    c.button_stop.enabled = true;
	    c.button_begin.enabled = false;
	    c.button_end.enabled = false;

	    c.button_set.enabled = false;
	} else {
	    c.button_play.enabled = true;
	    c.button_stop.enabled = false;
	    c.button_begin.enabled = true;
	    c.button_end.enabled = true;

	    c.button_set.enabled = true;
	}
    }

}
