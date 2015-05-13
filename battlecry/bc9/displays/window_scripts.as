import mx.containers.Window;

class window_scripts extends Window {
    public var handle_run:Function;
    public var handle_set:Function;

    private var boxes:Object;

    private var last_index:Number;

    public function window_scripts() {
	super();
	//trace("window_scripts: made");
	this.boxes      = new Object();
	this.last_index = 0
    }

    private function init() {
	super.init();
	this.setSize(245,440);
	this.title = "Control Scripts";
	this.contentPath = "window_scripts_content";
    }

    public function init_gui() {
	var self = this;
	var c:MovieClip = this.content;

	this._parent.controler.init_window_scripts();
	this.update_gui();
    }

    private function update_gui() {
	var self = this;
	var c:MovieClip = this.content;
    }

    private function create_or_update(ob:Object) {
	var self = this;
	var c:MovieClip = this.content;

	if (! this.boxes[ob.name]) {
	    c.attachMovie('mini_script', 'script_' + ob.name, c.getNextHighestDepth());
	    var temp = c['script_' + ob.name];
	    temp._x = 10;
	    temp._y = this.last_index * 55 + 10;
	    temp.index = this.last_index;
	    this.last_index ++;
	    this.boxes[ob.name] = temp;

	    temp.handle_run = function(script:String) {
		self.handle_run(script);
	    }

	    temp.handle_set = function(script:String, rate:Number) {
		self.handle_set(script, rate);
	    }

	}

	var temp = this.boxes[ob.name];

	temp.set_data(ob);
    }

    private function text2bool(t:String):Boolean {
	if ("True" == t) {
	    return true;
	} else if ("true" == t) {
	    return true;
	}
	return false;
    }

    public function set_conf(conf:String) {
	var self = this;
	var c:MovieClip = this.content;

	var cmd = conf.split('+');

	var i = 0;
	while (cmd.length > i+6) {
	    var ob = {name   : cmd[i],
		      running: this.text2bool(cmd[i+1]),
		      rate   : Number(cmd[i+2]),
		      ret    : Number(cmd[i+3]),
		      last   : Number(cmd[i+4]),
		      lasts  : cmd[i+5],
		      since  : Number(cmd[i+6])};
	    i += 7;
	    this.create_or_update(ob);
	}

    }    
}
