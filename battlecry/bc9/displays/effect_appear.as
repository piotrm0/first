class effect_appear extends effect {
    public function effect_appear(target:MovieClip, params:Object) {
	super(target, params);
    }

    public function update() {
	super.update();
	if (this.done) {
	    this.target._visible = true;
	    return;
	}
	var t:MovieClip = this.target;
	t._x        = this.x;
	t._y        = this.y;
	t._xscale   = this.xscale;
	t._yscale   = this.yscale;
	t._alpha    = this.alpha;
	t._rotation = this.rotation;
    }
}
