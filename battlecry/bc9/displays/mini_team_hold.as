class mini_team_hold extends MovieClip {
    public var handle_over:Function = null;
    public var handle_out:Function  = null;

    private var bg:MovieClip;

    public var hitbox:MovieClip;

    public var team   :Number;
    public var subteam:Number;

    public var holding       = null;
    public var valid:Boolean = false;

    public var alliance_number = null;

    public function mini_team_hold() {
	super();
	//trace("mini_team_hold: made");
	this.init();
    }

    private function init() {
	var self = this;

	/*
	this.bg.onRollOver = function() {
	    self.handle_over(self.team, self.subteam);
	}
	this.bg.onRollOut = function() {
	    self.handle_out(self.team, self.subteam);
	}
	this.bg.onPress = function() {
	    self.startDrag(false);
	}
	this.bg.onRelease = function() {
	    self.stopDrag();
	}
	*/
    }

    public function set_data(i, team, subteam) {
	this.alliance_number = i;
	this.team            = team;
	this.subteam         = subteam;
    }
}
