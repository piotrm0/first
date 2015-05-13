import mx.controls.TextInput;

class mini_script extends MovieClip {
    public var handle_run:Function = null;
    public var handle_set:Function = null;

    private var bg:MovieClip;

    public var button_run:Button;
    public var button_set:Button;

    private var text_script     :TextField;
    private var text_since      :TextField;
    private var text_last_string:TextField;
    private var text_ret        :TextField;
    private var box_rate        :TextInput;

    private var box_color:MovieClip;
    private var ret_color:Color;

    public var index:Number;

    private var last_rate:Number;

    private var script:String = ""

    public function mini_script() {
	super();
	//trace("mini_script: made");
	this.init();
    }

    private function init() {
	var self = this;

	this.last_rate = -1;
	this.ret_color = new Color(this.box_color);

	this.button_run.onPress = function() {
	    self.handle_run(self.script);
	}

	this.button_set.onPress = function() {
	    self.handle_set(self.script,
			    Number(self.box_rate.text));
	}

	this.bg.onPress = function() {
	    self.startDrag(false);
	}

	this.bg.onRelease = function() {
	    self.stopDrag();
	}

    }

    private function format_time_field(t:Number) {
	if (t < 10) { return "0" + t; }
	return t;
    }

    public function format_time(t:Number) {
	if (t >= 60 * 60) {
	    var hours   = int(t / (60 * 60));
	    var minutes = int(t / 60) % 60;
	    var seconds = t % 60;

	    return this.format_time_field(hours) + ":" +
		this.format_time_field(minutes) + ":" +
		this.format_time_field(seconds);

	} else if (t >= 60) {
	    var minutes = int(t / 60) % 60;
	    var seconds = t % 60;

	    return "00:" +
		this.format_time_field(minutes) + ":" +
		this.format_time_field(seconds);
	    
	} else {
	    var seconds = t % 60;

	    return "00:00:" +
		this.format_time_field(seconds);
	}
    }

    public function set_data(ob:Object) {
	this.script = ob.name;
	//trace("box = " + this.box_rate + " text = " + this.box_rate.text + " ob.rate = " + ob.rate + ", last_rate = " + this.last_rate);
	if (ob.rate != this.last_rate) {
	//	    trace("setting rate");
	    this.box_rate.text = ob.rate;
	    this.last_rate     = Number(this.box_rate.text);
	}
	this.text_script.text      = ob.name;
	this.text_since.text       = "(" + this.format_time(ob.since) + ")";
	this.text_last_string.text = ob.lasts;
	this.text_ret.text         = ob.ret;
	if (ob.running) {
	    this.text_script.text += " (running)";
	    this.button_run.enabled = false;
	} else {
	    this.button_run.enabled = true;
	}
	if (ob.ret == 0) {
	    this.ret_color.setRGB(0x00ff00);
	} else if (ob.ret == 1) {
	    this.ret_color.setRGB(0xffff00);
	} else {
	    this.ret_color.setRGB(0xff0000);
	}
    }

    public function focus(is) {
	this.bg.gotoAndStop(is);
    }

}
