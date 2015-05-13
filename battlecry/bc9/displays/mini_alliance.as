class mini_alliance extends MovieClip {
    public var handle_over:Function = null;
    public var handle_out:Function  = null;

    private var bg:MovieClip;

    public var team   :Number;
    public var subteam:Number;

    public var text_team:TextField;

    public function mini_hold() {
	super();
	//trace("mini_alliance: made");
	this.init();
    }

    private function init() {
	var self = this;

	/*
	this.bg.onRollOver = function() {
	    self.handle_over(self.team);
	}
	this.bg.onRollOut = function() {
	    self.handle_out(self.team);
	}

	this.bg.onPress = function() {
	    self.startDrag(false);
	}

	this.bg.onRelease = function() {
	    self.stopDrag();
	}
	*/
    }

    function set_data(num) {
	text_team.text = num;
    }
}
