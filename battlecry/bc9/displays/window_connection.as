import mx.containers.Window;
import mx.controls.DataGrid;

class window_connection extends Window {
    public var click;

    public var handle_connect       :Function = null;
    public var handle_disconnect    :Function = null;
    public var handle_cancel        :Function = null;
    public var handle_set_remote    :Function = null;
    public var handle_set_pass      :Function = null;

    public var connected :Boolean = false;
    public var connecting:Boolean = false;

    public function window_connection() {
	super();
	//trace("window_connection: made");
    }

    private function init() {
	super.init();
	this.setSize(290,150);
	this.title = "Control Connection";
	this.contentPath = "window_connection_content";
    }

    public function init_gui() {
	var self:window_connection = this;
	var c:MovieClip = this.content;

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

	var updated_host:Function = function(evt:Object) {
	    self.handle_set_remote(self.content.text_host.text,
				   self.content.text_port.text,
				   self.content.checkbox_reconnect.selected);
	};

	c.text_host.addEventListener("change", {change: updated_host});
	c.text_port.addEventListener("change", {change: updated_host});

	var updated_pass:Function = function(evt:Object) {
	    self.handle_set_pass(self.content.text_pass.text);
	};

	c.text_pass.addEventListener("change", {change: updated_pass});

	this.update_enables();

	this._parent.controler.init_window_connection();
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
}
