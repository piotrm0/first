class component extends MovieClip {
    public var ready:Boolean       = false;
    public var d:display           = null;
    public var on_ready:Function   = null;
    public var keyframes:Array     = null;
    public var target_keyframe:Number = -1;

    public var name:String = null;

    public function component() {
	trace("component: made");
    }

    public function am_ready() {
	trace("am ready! " + this.name);
	var old = this.ready;
	this.ready = true;
	if (not old) {
	    this.on_ready();
	}
    }

    public function go_keyframe(num:Number) {
	// trace("go_keyframe: going keyframe " + num);
	// trace("go_keyframe: frames = " + this.keyframes);
	// trace("go_keyframe: have " + this.keyframes.length + " keyframes");
	this.target_keyframe = num;
	for (var i = 0; i < this.keyframes.length; i++) {
	    if (i != num) {
		this.keyframes[i].clean();
	    } else {
		this.keyframes[i].start();
	    }
	}
    }
}
