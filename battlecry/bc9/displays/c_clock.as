class c_clock extends component {
    public var text_box:MovieClip;
    public var sub_box:MovieClip;
    public var p_box:MovieClip;

    private var clock_key:String = null;

    public function c_clock() {
	//trace("c_clock: made")
    }

    public function enter() {
	var self:c_clock = this;
	this.clock_key = this.d.cc.watch_env("clock", function(a,b,c) { self.watch_clock(a,b,c)} );
    }

    public function exit() {
	if (this.clock_key) {
	    this.d.cc.unwatch_env("clock", this.clock_key);
	    this.clock_key = null;
	}
    }

    public function watch_clock(key:String, old_value:String, value:String) {
	//trace("watch_clock");

	var minutes:Number;
	var seconds:Number;

	var temp = Number(value);

	minutes = int(temp/60);
	seconds = temp % 60;

	var text_minutes:String = minutes.toString();
	var text_seconds:String = seconds.toString();

	if (minutes < 10) {
	    text_minutes = "0" + text_minutes;
	}
	if (seconds < 10) {
	    text_seconds = "0" + text_seconds;
	}

	this.text_box.set_data(text_minutes + ":" + text_seconds);

	var s2 = 0;
	var p  = "";
	if (temp >= 120) {
	    p = "A";
	    s2 = temp - 120;
	} else if (temp >= 80) {
	    p = "P1";
	    s2 = temp - 80;
	} else if (temp >= 40) {
	    p = "P2";
	    s2 = temp - 40;
	} else {
	    p = "P3";
	    s2 = temp;
	}

	this.sub_box.set_data(":" + s2);
	this.p_box.set_data(p);

	this.am_ready();
    }
}
