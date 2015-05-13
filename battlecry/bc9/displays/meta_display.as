//import window_displays;
//import window_connect;

import mx.controls.Menu;
import mx.controls.MenuBar;

class meta_display extends MovieClip {
    private var w_displays:window_displays;
    private var w_connect :window_connect;

    private var w_connection:window_connection;
    private var w_display   :window_display;
    private var w_clock     :window_clock;
    private var w_match     :window_match;
    private var w_pairings  :window_pairings;
    private var w_config    :window_config;
    private var w_scripts   :window_scripts;

    private var STATE_GUI     :Number = 0;
    private var STATE_VIEW_GUI:Number = 1;
    private var STATE_VIEW    :Number = 2;

    private var state:Number;

    private var m_windows:Menu;
    private var m_control:Menu;
    private var menu_bar:MenuBar;

    private var displays:MovieClip;
    private var displays_data:Array;
    private var displays_by_id:Object;

    private var display_active:display   = null;
    private var display_active_id:Number = 0;

    private var new_num:Number = 1;

    public var defaults:Object;

    public var back_x:Number;
    public var back_y:Number;
    public var back_scale:Number;

    public var back_vis_d:Boolean;
    public var back_vis_c:Boolean;

    public var key_handler:Object;

    public var controler:control;

    public function meta_display() {
	super();

	this.state = this.STATE_GUI;

	this.controler = new control();

	this.init_keys();
	this.init_windows();
	this.init_menu();
    }

    public function init_keys() {
	var self:meta_display = this;

	this.key_handler = new Object();
	this.key_handler[32] = function() {
	    self.toggle_active();
	};

	var key_listen = new Object();
	key_listen.onKeyDown = function() {
	    var key = Key.getAscii();

	    //trace("key [" + key + "] pressed");

	    if (self.key_handler.hasOwnProperty(key)) {
		self.key_handler[key]();
	    }
	}

	Key.addListener(key_listen);
    }

    public function init_windows() {
	this.displays = this.createEmptyMovieClip("display", this.getNextHighestDepth());
	this.displays_data  = new Array();
	this.displays_by_id = new Object();

	this.attachMovie("window_displays",   "w_displays",   this.getNextHighestDepth());
	this.attachMovie("window_connect",    "w_connect",    this.getNextHighestDepth());
	this.attachMovie("window_connection", "w_connection", this.getNextHighestDepth());
	this.attachMovie("window_display",    "w_display",    this.getNextHighestDepth());
	this.attachMovie("window_clock",      "w_clock",      this.getNextHighestDepth());
	this.attachMovie("window_match",      "w_match",      this.getNextHighestDepth());
	this.attachMovie("window_pairings",   "w_pairings",   this.getNextHighestDepth());
	this.attachMovie("window_config",     "w_config",     this.getNextHighestDepth());
	this.attachMovie("window_scripts",    "w_scripts",    this.getNextHighestDepth());

	this.w_displays._visible   = false;
	this.w_connect._visible    = false;
	//this.w_connection._visible = false;
	this.w_display._visible    = false;
	this.w_clock._visible      = false;
	this.w_match._visible      = false;
	//this.w_pairings._visible   = false;
	this.w_config._visible     = false;
	this.w_scripts._visible    = false;

	this.controler.w_connection = this.w_connection;
	this.controler.w_display    = this.w_display;
	this.controler.w_clock      = this.w_clock;
	this.controler.w_match      = this.w_match;
	this.controler.w_pairings   = this.w_pairings;
	this.controler.w_config     = this.w_config;
	this.controler.w_scripts    = this.w_scripts;

	var listen_close:Object = new Object();
	listen_close.click = function(obj) {
	    var target = obj.target;
	    if (target) {
		target._visible = false;
	    } else {
		trace("no click handler defined for " + target);
	    }
	}

	this.w_displays.closeButton   = true;
	this.w_connect.closeButton    = true;
	this.w_connection.closeButton = true;
	this.w_display.closeButton    = true;
	this.w_clock.closeButton      = true;
	this.w_match.closeButton      = true;
	this.w_pairings.closeButton   = true;
	this.w_config.closeButton     = true;
	this.w_scripts.closeButton    = true;

	this.w_displays.addEventListener(  "click", listen_close);
	this.w_connect.addEventListener(   "click", listen_close);
	this.w_connection.addEventListener("click", listen_close);
	this.w_display.addEventListener(   "click", listen_close);
	this.w_clock.addEventListener(     "click", listen_close);
	this.w_match.addEventListener(     "click", listen_close);
	this.w_pairings.addEventListener(  "click", listen_close);
	this.w_config.addEventListener(    "click", listen_close);
	this.w_scripts.addEventListener(   "click", listen_close);
    }

    public function init_menu() {
	var self:meta_display = this;

	this.attachMovie("MenuBar", "menu_bar", this.getNextHighestDepth());
	this.menu_bar.setSize(640);

	_root.resize_handler = function(r) {
	    self.menu_bar.setSize(Stage.width);
	    self.menu_bar._x = (640 - Stage.width) / 2;
	    self.menu_bar._y = (480 - Stage.height) / 2;
	}

	this.m_windows = this.menu_bar.addMenu("Display");
	this.m_control = this.menu_bar.addMenu("Control");

	this.m_windows.addMenuItem({label:"Connection", instanceName:"connection"});
	this.m_windows.addMenuItem({label:"Displays",   instanceName:"displays"});

	this.m_windows['displays'].target_window   = this.w_displays;
	this.m_windows['connection'].target_window = this.w_connect;

	this.m_control.addMenuItem({label:"Connection", instanceName:"connection"});
	this.m_control.addMenuItem({label:"Display",    instanceName:"display"});
	this.m_control.addMenuItem({label:"Clock",      instanceName:"clock"});
	this.m_control.addMenuItem({label:"Match",      instanceName:"match"});
	this.m_control.addMenuItem({label:"Pairings",   instanceName:"pairings"});
	this.m_control.addMenuItem({label:"Config",     instanceName:"config"});
	this.m_control.addMenuItem({label:"Scripts",    instanceName:"scripts"});

	this.m_control['connection'].target_window = this.w_connection;
	this.m_control['display'].target_window    = this.w_display;
	this.m_control['clock'].target_window      = this.w_clock;
	this.m_control['match'].target_window      = this.w_match;
	this.m_control['pairings'].target_window   = this.w_pairings;
	this.m_control['config'].target_window     = this.w_config;
	this.m_control['scripts'].target_window    = this.w_scripts;

	var listen_menu:Object = new Object();
	listen_menu.change = function(evt) {
	    var menu = evt.menu;
	    var item = evt.menuItem;
	    if (item.target_window) {
		with(item.target_window) {
		    if (_visible) {
			_visible = false;
		    } else {
			//_x = 320 - _width / 2;
			//_y = 240 - _height / 2;
			_visible = true;
		    }
		}
	    } else {
		trace("no click handler defined for " + item);
	    }
	}

	this.m_windows.addEventListener("change", listen_menu);
	this.m_control.addEventListener("change", listen_menu);
    }

    public function init_window_displays() {
	var self:meta_display = this;

	this.w_displays.set_data(this.displays_data);

	this.w_displays.handle_new = function() {
	    //trace("creating new " + self.new_num);

	    self.displays.attachMovie("display", "d" + self.new_num, self.new_num+1);

	    var d:MovieClip = self.displays["d" + self.new_num];

	    if (self.state != self.STATE_GUI) {
		d._visible = false;
	    }

	    var temp:Object = {id        : self.new_num,
			       type      : d.type,
			       status    : "disconnected",
			       host      : d.cc.net.server_host,
			       port      : d.cc.net.server_port,
			       quality   : d.quality,
			       fullscreen: d.fullscreen};

	    self.displays_data.push(temp);
	    self.displays_by_id[self.new_num] = temp;

	    d.set_scale(50,50);

	    self.w_displays.set_data(self.displays_data);

	    d.set_id(self.new_num);

	    d.handle_pre_ready = function() {
		//trace("handle_pre_ready")
		if (this.id = self.display_active_id) {
		    self.update_active_status();
		}
	    };

	    d.handle_full_ready = function() {
		//trace("handle_full_ready")
		if (this.id = self.display_active_id) {
		    self.update_active_status();
		}
	    };

	    d.handle_connect = function() {
		var w:window_connect = self.w_connect;
		var c:MovieClip      = w.content;
		var d:display        = self.display_active;

		self.update_display_status(this.id);

		if (this.id = self.display_active_id) {
		    w.connecting = d.cc.net.connecting;
		    w.connected  = d.cc.net.connected;
		    w.update_enables();
		} else {
		    
		}
	    };

	    d.handle_disconnect = function() {
		var w:window_connect = self.w_connect;
		var c:MovieClip      = w.content;
		var d:display        = self.display_active;

		if (this.id = self.display_active_id) {
		    w.connecting = d.cc.net.connecting;
		    w.connected  = d.cc.net.connected;
		    w.update_enables();
		} else {
		    
		}
	    };

	    self.new_num++;
	};
	this.w_displays.handle_delete = function(num:Number) {
	    //trace("deleting " + num);
	    self.delete_display(num);
	    self.w_displays.set_data(self.displays_data);
	    if (num == self.display_active_id) {
		self.display_active_id = null;
		self.display_active    = null;
		self.update_active_status();
	    }
	};
	this.w_displays.handle_set_active = function(num:Number) {
	    if (self.state != self.STATE_GUI) {
		self.toggle_active();
	    }
	    self.w_displays.handle_set_select(num);
	    self.toggle_active();
	    self.w_displays.setFocus();
	}
	this.w_displays.handle_set_select = function(num:Number) {
	    if (self.state == self.STATE_GUI) {
		self.display_active    = self.displays["d" + num];
		self.display_active_id = num;
		self.update_active_status();
	    }
	};

	this.w_displays.handle_new();
	this.w_displays.handle_set_select(1);
    }

    public function update_active_status() {
	var w:window_connect = this.w_connect;
	var c:MovieClip      = w.content;
	var d:display        = this.display_active;

	if (null != d) {
	    w.title = "Connect (" + this.display_active_id + ")";
	    w.connecting = d.cc.net.connecting;
	    w.connected  = d.cc.net.connected;
	    c.button_connect.enabled     = true;
	    c.checkbox_reconnect.enabled = true;
	    c.text_host.text = d.cc.net.server_host;
	    c.text_port.text = d.cc.net.server_port;
	    c.checkbox_reconnect.selected = d.cc.net.retry;

	    c.radio_quality_low.enabled    = true;
	    c.radio_quality_medium.enabled = true;
	    c.radio_quality_high.enabled   = true;
	    c.radio_quality_best.enabled   = true;
	    c.check_fullscreen.enabled = true;

	    var qmap = ['radio_quality_low',
			'radio_quality_medium',
			'radio_quality_high',
			'radio_quality_best'];

	    c[qmap[d.quality]].selected = true;

	    c.check_fullscreen.selected = d.fullscreen;

	    if (d.pre_ready) {
		c.list_type.enabled = true;
		w.populate_types(d.rsets["display_type"]);
	    } else {
		c.list_type.enabled       = false;
		c.button_set_type.enabled = false;
	    }

	    w.update_enables();
	} else {
	    w.title = "Connect (no active display)";
	    c.text_host.enabled          = false;
	    c.text_port.enabled          = false;
	    c.button_connect.enabled     = false;
	    c.checkbox_reconnect.enabled = false;
	    c.button_set_active.enabled  = false;
	    c.radio_quality_low.enabled    = false;
	    c.radio_quality_medium.enabled = false;
	    c.radio_quality_high.enabled   = false;
	    c.radio_quality_best.enabled   = false;
	    c.check_fullscreen.enabled = false;
	}
    }

    public function update_display_status(id:Number) {
	var data:Object = this.displays_by_id[id];
	var d:display = this.displays["d" + id];

	//trace("handling connect for data " + data);

	data.type       = d.type;
	data.quality    = d.quality;
	data.fullscreen = d.fullscreen;

	if (d.cc.net.connected) {
	    data.status = "connected";
	} else if (d.cc.net.connecting) {
	    data.status = "connecting";
	} else {
	    data.status = "disconnected";
	}

	data.host = d.cc.net.server_host;
	data.port = d.cc.net.server_port;
    }

    public function delete_display(num:Number) {
	this.displays['d' + num].removeMovieClip();

	for (var i:Number = 0; i < this.displays_data.length; i++) {
	    if (this.displays_data[i].id == num) {
		this.displays_data.splice(i,1);
		continue;
	    }
	}

	delete this.displays_by_id[num];
    }

    public function init_window_connect() {
	var self:meta_display = this;

	var w = this.w_connect;

	w.handle_connect = function() {
	    var w:window_connect = self.w_connect;
	    var c:MovieClip      = w.content;
	    var d:display        = self.display_active;

	    //trace("connecting");
	    d.connect();

	    w.connecting = d.cc.net.connecting;
	    w.connected  = d.cc.net.connected;
	    w.update_enables();
	};
	w.handle_disconnect = function() {
	    var w:window_connect = self.w_connect;
	    var c:MovieClip      = w.content;
	    var d:display        = self.display_active;

	    //trace("disconnecting");
	    d.disconnect();
	};
	w.handle_cancel = function() {
	    var w:window_connect = self.w_connect;
	    var c:MovieClip      = w.content;
	    var d:display        = self.display_active;

	    //trace("canceling");
	    d.cancel();

	    w.connecting = false;
	    w.connected  = false;
	    w.update_enables();
	};
	w.handle_set_type = function(type:String) {
	    var w:window_connect = self.w_connect;
	    var c:MovieClip      = w.content;
	    var d:display        = self.display_active;	    
	    d.set_type(type);
	    self.update_active_status();
	    self.update_display_status(self.display_active.id);
	};
	w.handle_select_type = function(type:String) {
	    var w:window_connect = self.w_connect;
	    var c:MovieClip      = w.content;
	    var d:display        = self.display_active;	    
	    var temp = d.rsets['display_type'][type];
	    w.content.text_description.text = temp.description + "\n" +
	    "Default Quality: " + temp.default_quality + "\n" +
	    "Default Fullscreen: " + temp.default_fullscreen;
	};
	w.handle_set_quality = function(qn:Number) {
	    var w:window_connect = self.w_connect;
	    var c:MovieClip      = w.content;
	    var d:display        = self.display_active;	    
	    d.set_quality(qn);
	    self.update_active_status();
	    self.update_display_status(self.display_active.id);
	};
	w.handle_set_fullscreen = function(f:Boolean) {
	    var w:window_connect = self.w_connect;
	    var c:MovieClip      = w.content;
	    var d:display        = self.display_active;	    
	    d.set_fullscreen(f);
	    self.update_active_status();
	    self.update_display_status(self.display_active.id);
	};
	w.handle_set_remote = function(host:String, port:String, retry:Boolean) {
	    var w:window_connect = self.w_connect;
	    var c:MovieClip      = w.content;
	    var d:display        = self.display_active;

	    d.cc.net.server_host = host;
	    d.cc.net.server_port = Number(port);
	    d.cc.net.retry = retry;

	    self.update_display_status(self.display_active.id);
	}
    }

    public function toggle_active() {
	//trace("toggle_active: " + this.state);
	//trace("display_active=" + this.display_active);
	//trace("display_active.id=" + this.display_active.id);
	if (this.state == this.STATE_GUI) {
	    if (this.display_active) {
		var d:display  = this.display_active;
		var num:Number = d.id;

		this.back_x = d.stage._x;
		this.back_y = d.stage._y;
		this.back_scale = d.stage._xscale;

		for (var id in this.displays_by_id) {
		    var nid = Number(id);
		    var temp_d = this.displays['d' + nid];
		    if (nid != num) {
			temp_d._visible = false;
		    } else {
			temp_d._visible = true;
		    }
		}

		d.stage._x = 0;
		d.stage._y = 0;
		d.stage._xscale = 100;
		d.stage._yscale = 100;

		d.controls._visible = false;

		this.back_vis_d = this.w_displays._visible;
		this.back_vis_c = this.w_connect._visible;

		this.menu_bar._visible = false;
		this.w_displays._visible = false;
		this.w_connect._visible = false;

		if (d.fullscreen) {
		    fscommand("fullscreen", "true");
		}

		Stage.scaleMode = "showAll";

		d.set_quality(d.quality);

		Mouse.hide();

		this.state = this.STATE_VIEW_GUI;
	    }
	} else if (this.state == this.STATE_VIEW_GUI) {
	    var d:display  = this.display_active;
	    var num:Number = d.id;
	    
	    for (var id in this.displays_by_id) {
		var nid = Number(id);
		var temp_d = this.displays['d' + nid];
		temp_d._visible = true;
	    }

	    d.stage._x = this.back_x;
	    d.stage._y = this.back_y;
	    d.stage._xscale = this.back_scale;
	    d.stage._yscale = this.back_scale;

	    this.state = this.STATE_GUI;

	    this.menu_bar._visible = true;

	    this.w_displays._visible = this.back_vis_d;
	    this.w_connect._visible = this.back_vis_c;

	    Stage.scaleMode = "noScale";

	    Mouse.show();

	} else if (this.state == this.STATE_VIEW) {
	    
	}
    }
}

