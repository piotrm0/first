class effect {
    public var params:Object    = null;
    public var target:MovieClip = null;

    public var done:Boolean     = false;
    public var on_done:Function = null;
    
    public var x       :Number = null;
    public var y       :Number = null;
    public var xscale  :Number = null;
    public var yscale  :Number = null;
    public var alpha   :Number = null;
    public var rotation:Number = null;

    private var update_int:Number = null;

    public function effect(target:MovieClip, params:Object) {
	//	trace("effect: created for keyframe " + params.keyframe_index);
	this.target = target;
	this.params = params;
	this.x        = Number(params.x_position);
	this.y        = Number(params.y_position);
	this.xscale   = Number(params.x_scale);
	this.yscale   = Number(params.y_scale);
	this.alpha    = Number(params.alpha);
	this.rotation = Number(params.rotation);
    }

    public function start() {
	var self:effect = this;
	//	trace("start: on frame " + this.params.keyframe_index);
	this.done = false;
	if (not this.update_int) {
	    //	    trace("start: creating interval");
	    this.update_int = setInterval(function(){ self.update()}, 50);
	}
    }

    public function finalize() {
	//	trace("finalize: on frame " + this.params.keyframe_index);
	this.clean();

	var t = this.target;
	t._x = this.x;
	t._y = this.y;
	t._xscale   = this.xscale;
	t._yscale   = this.yscale;
	t._alpha    = this.alpha;
	t._rotation = this.rotation;

	this.on_done(Number(this.params.keyframe_index));
    }

    public function update() {
	//	trace("update: on frame " + this.params.keyframe_index);
	if (this.is_in_place()) {
	    this.done = true;
	    this.finalize();
	}
    }

    public function is_in_place() {
	var t:MovieClip = this.target;
	if ((Math.abs(t._x - this.x) < 3) &&
	    (Math.abs(t._y - this.y) < 3) &&
	    (Math.abs(t._xscale - this.xscale) < 3) &&
	    (Math.abs(t._yscale - this.yscale) < 3) &&
	    (Math.abs(t._alpha - this.alpha) < 5) &&
	    (Math.abs(t._rotation - this.rotation) < 3)) {
	    //	    trace("is_in_place: yes");
	    return true;
	} else {
	    //	    trace("is_in_place: no");
	    return false;
	}
    }

    public function clean() {
	//	trace("clean: on frame " + this.params.keyframe_index);
	if (this.update_int) {
	    clearInterval(this.update_int);
	    this.update_int = null;
	}
    }
}
