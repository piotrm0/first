import mx.containers.Window;
import mx.controls.DataGrid;

class window_displays extends Window {
    public var handle_new       :Function = null;
    public var handle_delete    :Function = null;
    public var handle_set_select:Function = null;
    public var handle_set_active:Function = null;

    public var click;

    public var selected_display:Number = null;

    public function window_displays() {
	super();
	//	this.init();
	// trace("window_displays: made");
    }

    private function init() {
	super.init();
	this.setSize(610,200);
	this.title = "Displays";
	this.contentPath = "window_displays_content";
    }

    public function init_gui() {
	var self:window_displays = this;
	var c:MovieClip = this.content;

	//	trace("init_gui: content is " + c);
	this.update_enables();

	c.checkbox_confirm.addEventListener("click", {click: function(evt:Object) {
	    trace("checkbox clicked");
	    if (c.checkbox_confirm.selected) {
		c.button_delete.enabled = true;
	    } else {
		c.button_delete.enabled = false;
	    }
	}});

	c.button_delete.onPress = function() {
	    self.handle_delete(self.selected_display);
	    self.selected_display = null;
	    self.update_enables();
	};

	c.button_set_active.onPress = function() {
	    self.handle_set_active(self.selected_display);
	};

	c.button_new.onPress = function() {
	    self.handle_new();
	};

	var d:DataGrid = c.datagrid_displays;
	d.columnNames = ["id", "type", "host", "port", "quality", "fullscreen", "status"];

	d.addEventListener("cellPress", {cellPress: function(evt:Object) {
	    trace("item " + evt.itemIndex + " pressed");
	    if (d.dataProvider.length <= evt.itemIndex) {
		self.selected_display = null;
	    } else {
		self.selected_display = d.getItemAt(evt.itemIndex).id;
		self.handle_set_select(self.selected_display);
	    }
	    self.update_enables();
	}});

	this._parent.init_window_displays();
    }

    private function update_enables() {
	var c:MovieClip = this.content;
	if (null != this.selected_display) {
	    c.checkbox_confirm.enabled  = true;
	    c.button_set_active.enabled = true;
	    if (c.checkbox_confirm.selected) {
		c.button_delete.enabled = true;
	    } else {
		c.button_delete.enabled = false;
	    }
	} else {
	    c.checkbox_confirm.selected = false;
	    c.checkbox_confirm.enabled  = false;
	    c.button_delete.enabled     = false;
	    c.button_set_active.enabled = false;
	}
    }

    public function set_data(displays:Array) {
	var c:MovieClip = this.content;
	var d:DataGrid  = c.datagrid_displays;
	d.dataProvider = displays;
    }
}
