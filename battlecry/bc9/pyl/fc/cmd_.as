
cmd.pack = 0;

cmd.commands = new Object();

cmd.process = function(data) {
  //  trace("processing [" + data + "]");

  if (cmd.pack != 0) {
    xml = new XML();
    xml.ignoreWhite = true;
    xml.parseXML(data);
    //    trace("got xml:");
    //    trace(xml.toString());
    cmd.got_pack(cmd.pack, xml);
    cmd.pack = 0;
    return;
  }

  if (data.substring(0, 1) == "!") {
    var words = get_opts(data);
    var temp = words.shift();
    var command = temp.substring(1, temp.length);
    if (cmd.commands[command]) {
      cmd.commands[command](words);
    } else {
      trace("unknown command [" + command + "]");
    }
    return;
  }
  trace("got misc data [" + data + "]");
  return;
};

cmd.commands['pack'] = function(data) {
  cmd.pack = data[0];
  //  trace("getting pack [" + cmd.pack + "]");
};

cmd.commands['hello'] = function(data) {
  
};

cmd.commands['msg'] = function(data) {
  for (msg in data) {
    net.log_connect(data[msg], "blue");
  }
};

cmd.commands['mod'] = function(data) {
  var obj_name = data.shift();
  var obj = eval(obj_name);
  trace("moding [" + obj_name + "]/[" + obj + "] with [" + data + "]");
  obj.mod(data);
}

cmd.pack_handlers = new Object();

cmd.got_pack = function(pack, data) {
  //  trace("got pack [" + pack  + "]");
  if (cmd.pack_handlers[pack]) {
    cmd.pack_handlers[pack](data);
  } else {
    trace("don't know what to do with pack [" + pack + "]");
  }
};

cmd.pack_handlers['sets'] = function(data) {
  //  trace("filling in [" + ui.windows["sets"].content.tree + "]");
  //  trace("with:");
  //  trace(data.toString());
  ui.windows["sets"].content.tree.dataProvider = data;
  jep.data = data;
  jep.set_active(1);
}

