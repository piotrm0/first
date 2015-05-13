class effect_slide extends effect {
    public function effect_slide(target:MovieClip, params:Object) {
	super(target, params);
    }

    public function start() {
	super.start();
	this.target._visible = true;
    }

    public function update() {
	super.update();
	if (this.done) {
	    return;
	}
	var t:MovieClip = this.target;
	t._x        += (this.x        - t._x)/5;
	t._y        += (this.y        - t._y)/5;
	t._xscale   += (this.xscale   - t._xscale)/5;
	t._yscale   += (this.yscale   - t._yscale)/5;
	t._alpha    += (this.alpha    - t._alpha)/5;
	t._rotation += (this.rotation - t._rotation)/5;
    }
}
