class rbox extends MovieClip {
    public static var TYPE_BLANK     :Number = 0;
    public static var TYPE_ONE_LINE  :Number = 1;
    public static var TYPE_TWO_LINE  :Number = 2;
    public static var TYPE_THREE_LINE:Number = 3;
    public static var TYPE_WHAMMY    :Number = 4;

    private var text_main:TextField;
    private var text_sub :TextField;
    private var text_mid :TextField;

    private var line_main:String;
    private var line_sub :String;
    private var line_mid :String;

    private var decal_whammy   :MovieClip;
    private var decal_highlight:MovieClip;

    private var size = [160,120];
    private var type = rbox.TYPE_BLANK;

    private var worth_score    = 0;
    private var worth_spins    = 0;
    private var worth_whammies = 0;

    private var color      :Number  = null;
    private var highlighted:Boolean = null;

    public function rbox() {
	super();
	stop();
	this.set_color(1);
	this.set_highlight(false);
	this.set_type(rbox.TYPE_BLANK);
    }

    public function set_worth(score, spins, whammies) {
	if (whammies == 1) {
	    this.set_type(rbox.TYPE_WHAMMY);
	} else if (whammies < 0) {
	    var text = "WHAMMY";
	    if (whammies < -1) {
		text = "WHAMMIES";
	    }
	    this.set_type(rbox.TYPE_THREE_LINE);
	    this.set_data("$" + score, "LOSE-" + (-1 * whammies) + "-" + text, "or");
	    this.text_sub._y = 90;
	} else if (spins > 0) {
	    this.set_type(rbox.TYPE_THREE_LINE);
	    var text  = "spin";
	    var text2 = "one";
	    if (spins > 1) {
		text = "spins";
		text2 = "two";
	    }
	    this.set_data("$" + score, text2 + " " + text, "+");
	} else {
	    this.set_type(rbox.TYPE_ONE_LINE);
	    this.set_data("$" + score, "", "");
	}
    }

    public function set_highlight(h:Boolean, loop:Boolean):Void {
	this.highlighted              = h;
	this.decal_highlight._visible = h;
	if (loop) {
	    this.decal_highlight.gotoAndPlay(2);
	} else {
	    this.decal_highlight.gotoAndStop(1);
	}
    }

    public function set_color(col:Number):Void {
	this.color = col;
	this.gotoAndStop(col);
    }

    public function set_type(type:Number):Void {
	this.type = type;

	if (type == rbox.TYPE_BLANK) {
	    this.text_main._visible    = false;
	    this.text_sub._visible     = false;
	    this.text_mid._visible     = false;
	    this.decal_whammy._visible = false;

	} else if (type == rbox.TYPE_ONE_LINE) {
	    this.text_main._visible    = true;
	    this.text_sub._visible     = false;
	    this.text_mid._visible     = false;
	    this.decal_whammy._visible = false;
	    this.text_main._y = 23.5;

	} else if (type == rbox.TYPE_TWO_LINE) {
	    this.text_main._visible    = true;
	    this.text_sub._visible     = true;
	    this.text_mid._visible     = false;
	    this.decal_whammy._visible = false;
	    this.text_main._y = 18.5;
	    this.text_sub._y  = 75.5;

	} else if (type == rbox.TYPE_THREE_LINE) {
	    this.text_main._visible    = true;
	    this.text_sub._visible     = true;
	    this.text_mid._visible     = true;
	    this.decal_whammy._visible = false;
	    this.text_main._y = 8.5;
	    this.text_sub._y  = 80.5;
	    this.text_mid._y  = 54;

	} else if (type == rbox.TYPE_WHAMMY) {
	    this.text_main._visible    = false;
	    this.text_sub._visible     = false;
	    this.text_mid._visible     = false;
	    this.decal_whammy._visible = true;
	}
    }

    public function set_data(l1:String, l2:String, l3:String):Void {
	this.line_main = l1;
	this.line_sub  = l2;
	this.line_mid  = l3;

	this.text_main.text = l1;
	this.text_sub.text  = l2;
	this.text_mid.text  = l3;

    }
}
