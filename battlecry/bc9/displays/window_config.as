import mx.containers.Window;

class window_config extends Window {
    public var handle_set_overlay:Function;

    public function window_config() {
	super();
	trace("window_config: made");
    }

    private function init() {
	super.init();
	this.setSize(305,90);
	this.title = "Control Config";
	this.contentPath = "window_config_content";
    }

    public function init_gui() {
	var self = this;
	var c:MovieClip = this.content;

	c.button_set_overlay.onPress = function() {
	    self.handle_set_overlay(c.box_overlay.text);
	}

	this._parent.controler.init_window_config();
	this.update_gui();

	c.color_overlay = new Color(c.block_overlay);
    }

    private function update_gui() {
	var self = this;
	var c:MovieClip = this.content;
    }

    public function set_overlay(overlay:String) {
	var self = this;
	var c:MovieClip = this.content;
	c.box_overlay.text = overlay;
	c.color_overlay.setRGB(Number(overlay));
    }
}
