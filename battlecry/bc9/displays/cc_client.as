import net_client;
import cc_parser;

class cc_client {
    public var env:Object;
    public var env_opt:Object;

    public var handle_connect   :Function = null;
    public var handle_disconnect:Function = null;

    public var rsets:Object;

    public var rset:Object;
    public var rset_opt:Object;

    public var db_req_queue:Array;

    public var net:net_client;

    public var sequence:Number = 0;

    private var parser:cc_parser;

    function cc_client() {
	//trace("cc_client: made");
	this.net    = new net_client();
	this.parser = new cc_parser();

	this.db_req_queue = new Array();

	this.env     = new Object();
	this.env_opt = new Object();

	this.rset     = new Object();
	this.rset_opt = new Object();

	this.rsets = new Object();

	var self:cc_client = this;

	this.net.handle_data = function(data:String) {
	    //trace("in cc_client handle data: " + data);
	    self.parser.parse_line(data);
	};

	this.net.handle_connect = function() {
	    self.net.send("NICK display " + self.sequence);
	    self.sequence++;
	    self.send_all_watches();
	    self.handle_connect();
	};

	this.net.handle_disconnect = function() {
	    //	    self.handle_connect(); // hmm...
	    self.handle_disconnect();
	};

	this.parser.handle_env = function(key:String, value:String) {
	    var eo:Object;

	    var old_value:String = null;

	    //trace("handle_env: " + [key, value].join(","));

	    if (! self.env_opt.hasOwnProperty(key)) {
		self.env[key] = value;
		self.env_opt[key] = new Object();
		self.env_opt[key].new_id = 0;
		eo = self.env_opt[key];
		eo.watched = false;
		eo.callbacks = new Object();
	    } else {
		eo = self.env_opt[key];
		old_value = self.env[key];
		self.env[key] = value;
	    }

	    if (eo.num_callbacks != 0) {
		for (var callback_key:String in eo.callbacks) {
		    eo.callbacks[callback_key](key, old_value, value);
		}
	    }
	};

	this.parser.handle_rset_watch = function(rset:Object) {
	    //trace("got notice for rset " + rset.name);

	    var key = rset.name;

	    var eo:Object;

	    if (! self.rset_opt.hasOwnProperty(key)) {
		self.rset[key] = rset;
		self.rset_opt[key] = new Object();
		self.rset_opt[key].new_id = 0;
		eo = self.rset_opt[key];
		eo.watched = false;
		eo.callbacks = new Object();
	    } else {
		eo = self.rset_opt[key];
		self.rset[key] = rset;
	    }

	    if (eo.num_callbacks != 0) {
		for (var callback_key:String in eo.callbacks) {
		    eo.callbacks[callback_key](key, rset);
		}
	    }
	}

	this.parser.handle_rset = function(type:Number, rset:Object, effect:Number) {
	    if (self.db_req_queue.length == 0) {
		trace("!!! did not request an rset but got one");
		return;
	    }

	    var req:Object = self.db_req_queue[0];

	    var temp_res = {type: type,
			    rset: rset,
			    effect: effect};
	    req.received.push(temp_res);

	    if (req.received.length == req.results) {
		req.callback(req.received, req.options);
		self.db_req_queue.shift();
	    }
	}
    }

    public function set_env(key:String, val:String) {
	this.net.send("ENV " + key + "=" + val);
    }

    function send_all_watches() {
	//trace("send_all_watches: sending all");
	for (var key:String in this.env_opt) {
	    var eo:Object = this.env_opt[key];
	    if (eo.num_callbacks != 0) {
		this.net.send("WATCH ENV " + key);
	    }
	}
	for (var key:String in this.rset_opt) {
	    var eo:Object = this.rset_opt[key];
	    if (eo.num_callbacks != 0) {
		this.net.send("WATCH RSET " + key);
	    }
	}
    }

    function query(query:String, callback:Function, results:Number, options:Object) {
	var req:Object = {query:query, callback:callback, results:results, received:[], options:options};
	this.db_req_queue.push(req);
	this.net.send(query);
    }

    function unwatch_env(key:String, callback_key:String) {
	var eo:Object;

	if (! this.env_opt.hasOwnProperty(key)) {
	    return;
	}

	eo = this.env_opt[key];

	if (! eo.callbacks.hasOwnProperty(callback_key)) {
	    return;
	}

	delete eo.callbacks[callback_key];
	eo.num_callbacks--;

	if (eo.num_callbacks == 0) {
	    this.net.send("WATCH OFF ENV " + key);
	}
    }

    function watch_env(key:String, callback:Function) {
	var eo:Object;

	var callback_key:String = null;

	if(! this.env_opt.hasOwnProperty(key)) {
	    this.env_opt[key] = new Object();
	    this.env_opt[key].new_id = 0;
	    eo = this.env_opt[key];

	    this.env[key] = null;

	    callback_key = String(this.env_opt[key].new_id++);

	    eo.callbacks = new Object();
	    eo.callbacks[callback_key] = callback;
	    eo.num_callbacks = 0;
	} else {
	    eo = this.env_opt[key];
	    callback_key = String(this.env_opt[key].new_id++);
	}
	
	eo.callbacks[callback_key] = callback;
	eo.num_callbacks++;

	if (eo.num_callbacks == 1) {
	    this.net.send("WATCH ENV " + key);
	} else if ((eo.num_callbacks > 1) &&
		   (this.env[key] != null)) {
	    //trace("watch_env: " + key + " calling callback now");
	    callback(key, this.env[key], this.env[key]);
	}
	return callback_key;
    }

    function unwatch_rset(key:String, callback_key:String) {
	var eo:Object;

	if (! this.rset_opt.hasOwnProperty(key)) {
	    return;
	}

	eo = this.rset_opt[key];

	if (! eo.callbacks.hasOwnProperty(callback_key)) {
	    return;
	}

	delete eo.callbacks[callback_key];
	eo.num_callbacks--;

	if (eo.num_callbacks == 0) {
	    this.net.send("WATCH OFF RSET " + key);
	}
    }

    function watch_rset(key:String, callback:Function) {
	//trace("watching rset " + key);

	var eo:Object;

	var callback_key:String = null;

	if(! this.rset_opt.hasOwnProperty(key)) {
	    this.rset_opt[key] = new Object();
	    this.rset_opt[key].new_id = 0;
	    eo = this.rset_opt[key];

	    this.rset[key] = null;

	    callback_key = String(this.rset_opt[key].new_id++);

	    eo.callbacks = new Object();
	    eo.callbacks[callback_key] = callback;
	    eo.num_callbacks = 0;
	} else {
	    eo = this.rset_opt[key];
	    callback_key = String(this.rset_opt[key].new_id++);
	}
	
	eo.callbacks[callback_key] = callback;
	eo.num_callbacks++;

	if (eo.num_callbacks == 1) {
	    this.net.send("WATCH RSET " + key);
	} else if ((eo.num_callbacks > 1) &&
		   (this.rset[key] != null)) {
	    //trace("watch_rset: " + key + " calling callback now");
	    callback(key, this.rset[key]);
	}
	return callback_key;
    }

    function format_rset(rset:Object, keys:Array) {
	var ret = new Object();
	var rows = rset.rows;
	var temp;
	for (var j = 0; j < rows.length; j++) {
	    var row = rows[j].by_name;
	    temp = ret;
	    for (var i = 0; i < keys.length; i++) {
		var key = keys[i];
		if (! row.hasOwnProperty(key)) {
		    trace("!!! format_rset: no such key " + key);
		    return new Object()
		}

		if (i == keys.length - 1) {
		    //		    if (! temp.hasOwnProperty(row[key])) {
		    //			temp[row[key]] = new Array();
		    //		    }
		    //		    temp[row[key]].push(row);
		    temp[row[key]] = row;
		} else {
		    if (! temp.hasOwnProperty(row[key])) {
			temp[row[key]] = new Object();
		    }
		    temp = temp[row[key]];
		}
	    }
	}
	return ret;
    }
}
