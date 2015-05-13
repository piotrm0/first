class cc_parser {
    public var state:Number = 0;

    static public var QUERY_RSET   = 1;
    static public var QUERY_EFFECT = 2;
    static public var QUERY_ERROR  = 4;

    public var STATE_NONE:Number = 0;

    public var STATE_RSET_HEAD:Number = 5;
    public var STATE_RSET_ROW :Number = 6;

    public var STATE_HELP:Number = 2;
    public var STATE_ENV :Number = 3;
    public var STATE_NICK:Number = 4;

    public var RSET_MODE_WATCH:Number = 0;
    public var RSET_MODE_QUERY:Number = 1;
    public var rset_mode:Number = null;

    private var handle_state:Array;

    public var handle_root_cmd:Object;

    public var handle_env :Function       = null;
    public var handle_ping:Function       = null;
    public var handle_nick:Function       = null;
    public var handle_rset:Function       = null;
    public var handle_help:Function       = null;
    public var handle_rset_watch:Function = null;

    private var build_rset:Object;
    private var build_row :Number;
    private var build_rows:Number;
    private var build_cols:Number;

    function cc_parser() {
	//trace("cc_parser: made");

	var self:cc_parser = this;
      
	this.handle_root_cmd = {
	    ENV  : function(line:String, words:Array) {
		var temp:Array = self.parse_eq(words[1]);
		self.handle_env(temp[0], temp[1]);
	    },
	    OK   : function(line:String, words:Array) {
		// ignore
	    },
	    PING : function(line:String, words:Array) {
		if (null != self.handle_ping) {
		    self.handle_ping();
		}
	    },
	    NICK : function(line:String, words:Array) {
		if (null != self.handle_ping) {           // bug ?
		    self.handle_nick(words[1],words[2]);
		}
	    },
	    NOTICE : function(line:String, words:Array) {
		self.state     = self.STATE_RSET_HEAD;
		self.rset_mode = self.RSET_MODE_WATCH;
		self.build_rset = {name: words[1]};
		self.build_row  = 0;
		self.build_rows = Number(words[3]);
		self.build_cols = Number(words[5]);
		//trace("QUERY: expecting " + self.build_rows + " rows and " + self.build_cols + " cols");
	    },
	    QUERY : function(line:String, words:Array) {
		if (words[1] == "returned") {
		    self.state = self.STATE_RSET_HEAD;
		    self.rset_mode = self.RSET_MODE_QUERY;
		    self.build_rset = new Object();
		    self.build_row  = 0;
		    self.build_rows = Number(words[2]);
		    self.build_cols = Number(words[4]);
		    //trace("QUERY: expecting " + self.build_rows + " rows and " + self.build_cols + " cols");
		} else if (words[1] == "affected") {
		    self.state = self.STATE_NONE
		    self.handle_rset(cc_parser.QUERY_EFFECT, null, Number(words[2]))
		} else {
		    self.state = self.STATE_NONE
		    trace("QUERY ??? [" + line + "]");
		}
	    },
	    SQL : function(line:String, words:Array) {
		if (words[1] == "error:") {
		    self.handle_rset(cc_parser.QUERY_ERROR, null, 0);
		    return;
		}
		// unknown
	    }
	};
	
	handle_state = new Array();
	handle_state[this.STATE_NONE] = function(line:String, words:Array) {
	    //	    trace("handle state " + self.STATE_NONE + " with " + words.join(","));
	    if (self.handle_root_cmd.hasOwnProperty(words[0])) {
		self.handle_root_cmd[words[0]](line, words);
	    } else {
		trace("cc_parser: don't know how to handle \"" + line + "\""); 
	    }
	};

	/*
	handle_state[this.STATE_RSET] = function(line:String, words:Array) {
	    if (words[0] == "RSET") {
		self.state = self.STATE_RSET_HEAD;
		return;
	    }
	    // something broke, back to no state
	    self.state = self.STATE_NONE;
	};
	*/

	handle_state[this.STATE_RSET_HEAD] = function(line:String, words:Array) {
	    var cols:Array = line.split("\t");
	    if(cols.length != self.build_cols) {
		trace("!!! RSET_HEAD: expected " + self.build_cols + " cols but got " + cols.length);
	    }
	    self.build_rset.head = cols;
	    self.build_rset.rows = new Array();
	    self.state = self.STATE_RSET_ROW;
	};

	handle_state[this.STATE_RSET_ROW] = function(line:String, words:Array) {
	    if (self.build_row == self.build_rows) {
		if (words[0] == "DONE") {
		    // read success
		    if (self.rset_mode == self.RSET_MODE_QUERY) {
			self.handle_rset(cc_parser.QUERY_RSET, self.build_rset, 0);
			self.state = self.STATE_NONE;
			return;
		    } else if (self.rset_mode == self.RSET_MODE_WATCH) {
			self.handle_rset_watch(self.build_rset);
			self.state = self.STATE_NONE;
			return;
		    }
		} else {
		    trace("!!! RSET_ROW: read all rows but did not get DONE, got: " + line);
		    self.handle_rset(cc_parser.QUERY_ERROR, null, 0);
		    self.state = self.STATE_NONE;
		    return;
		}
	    }

	    var row_num:Array = line.split("\t");
	    var row_name:Object = new Object;

	    var row:Object = {by_name: row_name,
			      by_num: row_num};

	    if(row_num.length != self.build_cols) {
		trace("!!! RSET_ROW: expected " + self.build_cols + " cols but got " + row_num + " in: " + line);
	    }

	    for (var i:Number = 0; i < self.build_cols; i++) {
		row_name[self.build_rset.head[i]] = row_num[i];
	    }

	    self.build_rset.rows.push(row);
	    self.build_row++;
	};

	handle_state[this.STATE_HELP] = function(line:String, words:Array) {
	};
	handle_state[this.STATE_ENV] = function(line:String, words:Array) {
	    // simple command
	};
	handle_state[this.STATE_NICK] = function(line:String, words:Array) {
	    // simple command
	};
    }

    function parse_line(line:String) {
	//trace("parse_line: parsing \"" + line + "\"");
	var words: Array = this.parse_words(line);
	this.handle_state[state](line, words);
    }

    function parse_eq(pair:String):Array {
	//	trace("parse_eq: parsing \"" + pair + "\"");
	var temp:Array = pair.split("=");
	return temp;
    }

    function parse_words(line:String):Array {
	//	trace("parse_words: parsing \"" + line + "\"");
	var words:Array = line.split(" ");

	var ret:Array = new Array();

	var current:String = "";
	var quoted:Boolean = false;

	var words_length:Number = words.length;

	for (var word_num:Number = 0; word_num < words_length; word_num++) {
	    var word:String = words[word_num];

	    var first_char:String = word.charAt(0);
	    var last_char:String  = word.charAt(word.length - 1);

	    //    trace("word is [" + word + "]");
	    //    trace("first char is [" + first_char + "]");
	    //    trace("last  char is [" + last_char + "]");
	    
	    if (quoted) {
		if (last_char == '"') {
		    current += word.substring(0, word.length-1);
		    ret.push(current);
		    quoted = false;
		    current = "";
		} else {
		    current += word + " ";
		}
	    } else {
		if (first_char == '"') {
		    if (last_char == '"') {
			ret.push(word.substring(1, word.length-1));
		    } else {
			quoted = true;
			current += word.substring(1, word.length) + " ";
		    }
		} else {
		    ret.push(word);
		}
	    }
	}

	return ret;
    }
}
