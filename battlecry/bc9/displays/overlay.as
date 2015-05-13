class overlay extends MovieClip {
    public var area:MovieClip;
    public var color:Color;

    public function overlay() {
	//trace("overlay: made");
    }
    public function set_color(new_color:String) {
	//trace("set_color: " + new_color);
	this.color = new Color(this.area);
	this.color.setRGB(Number(new_color));
    }
}
