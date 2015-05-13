class c_match extends component {
    private var match_key:String;

    public var match_level :Number;
    public var match_number:Number;
    public var match_index :Number;
    private var got_id  :Boolean;
    public var name_text:MovieClip;

    public function c_match() {
	super();
	this.match_level  = null;
	this.match_number = null;
	this.match_index  = null;
	this.match_key    = null;
	this.got_id       = false;
    }
    public function enter() {
	var self:c_match = this;
	this.req();
    }

    public function exit() {
	this.got_id = false;
	if (this.match_key) {
	    this.d.cc.unwatch_env("current_match", this.match_key);
	    this.match_key = null;
	}
    }
    public function req() {
	var self:c_match = this;
	if (got_id) {
	    this.fill_data();
	    this.am_ready();
	    return;
	}
	if (not this.match_key) {
	    this.match_key = this.d.cc.watch_env("current_match", function(a,b,c) { self.watch_current_match(a,b,c); });
	}
    }

    public function watch_current_match(key, old_val, new_val) {
	trace("watch_current_match: " + old_val + " / " + new_val);
	var temp = new_val.split(".");
	this.match_level  = Number(temp[0]);
	this.match_number = Number(temp[1]);
	this.match_index  = Number(temp[2]);
	this.got_id = true;
	this.req();
    }

    public function fill_data() {
	this.name_text.set_data(this.d.format_match_full(this.match_level, this.match_number, this.match_index));
    }
}
