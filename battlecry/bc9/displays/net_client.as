class net_client {
    public var server_host:String  = "localhost";
    public var server_port:Number  = 7070;
    public var retry      :Boolean = true;
    public var connected  :Boolean = false;
    public var connecting :Boolean = false;
    public var attempt    :Number  = 0;

    public var handle_data      :Function = null;
    public var handle_connect   :Function = null;
    public var handle_disconnect:Function = null;

    private var socket     :XMLSocket;
    private var int_connect:Number = 0;
    private var int_send   :Number = 0;
    private var queue_send :Array;

    function net_client() {
	this.socket = new XMLSocket();
	this.queue_send = new Array();

	var self = this;

	//trace("net_client: made");

	this.socket.onClose = function() {
	    self.connected = false;
	    self.attempt = 0;
	    
	    trace("disconnected");

	    if (self.retry) {
		self.connecting = true;
		self.connect();
		self.handle_disconnect();
		return;
	    }

	    self.attempt = 0;

	    self.handle_disconnect();
	}
	this.socket.onConnect = function(res) {
	    if (res) {
		clearInterval(self.int_connect);
		self.int_connect = 0;

		self.connected = true;
		self.connecting = false;

		trace("connected");

		if (null != self.handle_connect) {
		    self.handle_connect();
		}

		return
	    }
	    if (! self.retry) {
		self.connecting = false;
		clearInterval(self.int_connect);
		self.int_connect = 0;
		self.attempt = 0;

		return
	    }
	    if (! self.int_connect) {
		self.int_connect = setInterval(connect, 3000);
	    }
	}
	this.socket.onData = function(src:String) {
	    if (src.charCodeAt(0) == 65533) { // see telnet
		//trace("received telnet command, NOT sending IAC WONT NAWS and ignoring");
		src = src.substring(1);
		// self.send(String.fromCharCode(255,252,49));
		//		return;
	    }
	    //	    trace("received \"" + src + "\"");
	    //	    trace("raw " + self.raw_text(src));
	    if (null != self.handle_data) {
		self.handle_data(src);
	    }
	}
    }

    function raw_text(test:String):String {
	//	trace("raw_text: processing \"" + test + "\"");
	var ret:String = "";
	for (var i:Number = 0; i < test.length; i++) {
	    ret = ret + test.charAt(i) + "[" + test.charCodeAt(i) + "]";
	}
	//	trace("raw_text: returning \"" + ret + "\"");
	return ret;
    }

    function connect() {
	if (this.connected) {
	    trace("connect: already connected");
	    return;
	}

	var self = this;

	this.attempt++;
	this.connecting = true;

	trace("connect: connecting to " + this.server_host + ":" + this.server_port + " (attempt " + this.attempt + ")");

	var res = socket.connect(this.server_host, this.server_port);

	if ((! this.connecting) &&
	    (! this.connected)) {
	    trace("connect: already connected or connecting");
	    return;
	}

	if (! res) {
	    trace("connect: bad address");
	    this.attempt = 0;
	    this.connecting = false;
	}

	if (! this.int_connect) {
	    this.int_connect = setInterval(function(){self.connect()}, 3000);
	}
	
    }
    function disconnect() {
	this.socket.close();
	this.connected = false;
	this.attempt = 0;
	this.handle_disconnect();
    }

    function cancel() {
	if (! this.connecting) {
	    trace("cancel: not connecting");
	    return;
	}

	clearInterval(this.int_connect);
	this.int_connect = 0;
	this.attempt = 0;
	this.connected  = false;
	this.connecting = false;
    }

    function send(data:String) {
	if (! this.connected) { 
	    //	    trace("send: not connected");
	    return;
	}

	//	trace("send: queueing:" + data);

	this.queue_send.push(data);

	if(this.int_send) {
	    //	    trace("send: already waiting to send");
	    return;
	}

	this.int_send = setInterval(this.send_queue, 100, this);
    }

    function send_queue(self) {
	if(self.queue_send.length == 0) {
	    //	    trace("send_queue: empty queue");
	    clearInterval(self.int_send);
	    self.int_send = 0;
	    return;
	}

	for (var i:Number = 0; i < self.queue_send.length; i++) {
	    self.socket.send(self.queue_send[i]);
	    trace("send_queue: sending \"" + self.queue_send[i] + "\"");
	}
	//	var msg:String = self.queue_send.join(String.fromCharCode(0));
	self.queue_send = new Array();
	//	self.socket.send(msg);

	//trace("send_queue: sending:" + msg);
	
	if (! self.int_send) {
	    self.int_send = setInterval(self.send_queue, 1000, self);
	}
    }
}
