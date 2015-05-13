class mini_team extends MovieClip {
    public var handle_over:Function = null;
    public var handle_out:Function  = null;

    public var handle_drop:Function = null;

    private var bg:MovieClip;

    public var holder = null;

    private var text_team:TextField;
    public  var team:Number;

    public function mini_team() {
	super();
	//trace("mini_team: made");
	this.init();
    }

    private function init() {
	var self = this;

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
	    self.handle_drop(self.team);
	}
    }

    public function set_data(team:Number) {
	this.team = team
	this.text_team.text = String(team);
    }
}
