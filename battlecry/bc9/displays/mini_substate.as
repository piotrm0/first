class mini_substate extends MovieClip {
    public var handle_go:Function = null;

    public var handle_over:Function = null;
    public var handle_out:Function = null;

    private var bg:MovieClip;

    public var button_go:Button;
    private var text_display:TextField;

    public var substate:String;

    public function mini_substate() {
	super();
	//	trace("mini_substate: made");
	this.init();
    }

    private function init() {
	var self = this;
	this.button_go.onPress = function() {
	    self.handle_go(self.substate);
	}

	this.bg.onRollOver = function() {
	    self.handle_over(self.substate);
	}
	this.bg.onRollOut = function() {
	    self.handle_out(self.substate);
	}

	this.bg.onPress = function() {
	    self.startDrag(false);
	}

	this.bg.onRelease = function() {
	    self.stopDrag();
	}

	this.disable();
    }

    public function disable() {
	//	trace("disabling " + this.button_go);
	this.button_go.enabled = false;
	//	this.button_go.redraw(true);
    }
    public function enable() {
	//	trace("enabling");
	this.button_go.enabled = true;
	//	this.button_go.redraw(true);
    }

    public function set_data(substate:String) {
	this.substate = substate;
	this.text_display.text = substate;
    }

    public function focus(is) {
	this.bg.gotoAndStop(is);
    }

}
