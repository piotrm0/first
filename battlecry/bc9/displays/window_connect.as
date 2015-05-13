import mx.containers.Window;

class window_connect extends Window {
    public var handle_connect       :Function = null;
    public var handle_disconnect    :Function = null;
    public var handle_cancel        :Function = null;
    public var handle_set_type      :Function = null;
    public var handle_select_type   :Function = null;
    public var handle_set_remote    :Function = null;
    public var handle_set_quality   :Function = null;
    public var handle_set_fullscreen:Function = null;

    public var click;

    public var connected :Boolean = false;
    public var connecting:Boolean = false;

    public function window_connect() {
	super();
	// this.init();
	// trace("window_connect: made");
    }

    private function init() {
	super.init();
	this.setSize(290,350);
	this.title = "Connection";
	this.contentPath = "window_connect_content";
    }

    public function init_gui() {
	var self:window_connect = this;
	var c:MovieClip = this.content;

	this.update_enables();

	c.button_set_type.enabled = false;

	c.checkbox_reconnect.addEventListener("click", {click: function(evt:Object) {
	    var c:MovieClip = self.content;

	    self.handle_set_remote(self.content.text_host.text,
				   self.content.text_port.text,
				   self.content.checkbox_reconnect.selected);
	}});

	c.button_connect.onPress = function() {
	    var c:MovieClip = self.content;

	    if (c.button_connect.label == "Connect") {
		self.handle_connect();
	    } else if (c.button_connect.label == "Cancel") {
		self.handle_cancel();
	    } else if (c.button_connect.label == "Disconnect") {
		self.handle_disconnect();
	    }
	};

	c.button_set_type.onPress = function() {
	    //trace("selected was " + c.list_type.selectedItem);
	    if (not c.list_type.selectedItem) {
		return;
	    }
	    self.handle_set_type(c.list_type.selectedItem);
	};

	var temp:Function = function(evt:Object) {
	    self.handle_set_remote(self.content.text_host.text,
				   self.content.text_port.text,
				   self.content.checkbox_reconnect.selected);
	};

	c.text_host.addEventListener("change", {change: temp});
	c.text_port.addEventListener("change", {change: temp});

	this._parent.init_window_connect();

	var d = c.list_type;

	d.addEventListener("change", {change: function(evt:Object) {
	    c.button_set_type.enabled = true;
	    self.handle_select_type(evt.target.value);
	}});

	var temp = [['low',    0],
		    ['medium', 1],
		    ['high',   2],
		    ['best',   3]];

	c["radio_quality_low"].addEventListener("click", {click: function(evt:Object) {
	    self.handle_set_quality(0);
	}});
	c["radio_quality_medium"].addEventListener("click", {click: function(evt:Object) {
	    self.handle_set_quality(1);
	}});
	c["radio_quality_high"].addEventListener("click", {click: function(evt:Object) {
	    self.handle_set_quality(2);
	}});
	c["radio_quality_best"].addEventListener("click", {click: function(evt:Object) {
	    self.handle_set_quality(3);
	}});

	c["check_fullscreen"].addEventListener("click", {click: function(evt:Object) {
	    //trace("fullscreen " + c.check_fullscreen.selected);
	    self.handle_set_fullscreen(c.check_fullscreen.selected);
	}});	
    }

    public function update_enables() {
	var c:MovieClip = this.content;

	if (this.connected) {
	    c.text_host.enabled = false;
	    c.text_port.enabled = false;
	    c.button_connect.label = "Disconnect";
	} else if (this.connecting) {
	    c.text_host.enabled = false;
	    c.text_port.enabled = false;
	    c.button_connect.label = "Cancel";
	} else {
	    c.text_host.enabled = true;
	    c.text_port.enabled = true;
	    c.button_connect.label = "Connect";
	}
    }

    public function populate_types(rset:Object) {
	var c:MovieClip = this.content;
	var dat:Array = new Array();
	for (var k in rset) {
	    dat.push(k);
	}
	c.list_type.dataProvider = dat;
    }
}
