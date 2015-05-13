
game.set  = 0;
game.data = 0;

game.mod = function(data) {
  game.set_active(data[0]);
}

game.set_active = function(set_num) {
  var old_set = game.set;
  var temp = game.get_set(game.data, set_num);
  //  trace("found this xml as set [" + set_num + "]: " + temp);
  game.pop_stages(temp);
};

game.get_set = function(data, set_num) {
  var children = data.firstChild.childNodes;
  for (var cnum in children) {
    var child = children[cnum];
    if (child.attributes.label == set_num) {
      return child;
    }
  }
  return 0;
};

game.pop_stages = function(node) {
  var c = 1;

  var cats = node.childNodes;
  cats.sort(game.cmp_label);
  cats.reverse();

  for (var cat_num = 0; cat_num < cats.length; cat_num++) {
    var cat = cats[cat_num];
    var cat_name = cat.attributes.label;

    if (cat.childNodes.length == 1) {
      // fill final jeapardy stage
      var ans = cat.firstChild.firstChild.firstChild.attributes.label;
      var que = cat.firstChild.lastChild.firstChild.attributes.label;

      _root.main.stages.final.answer   = ans;
      _root.main.stages.final.question = que;

      _root.main.stages.final.view_handler(_root.main.stages.final.state);
	
      continue;
    } 

    //    trace("category [" + cat_name + "]");

    var cbox = _root.main.stages.normal["cat_" + c];
    cbox.set_data(cat_name);

    var q = 1;

    var qs = cat.childNodes;
    qs.sort(game.cmp_label);
    qs.reverse();

    for (var q_num = 0; q_num < qs.length; q_num++) {
      var question = qs[q_num];

      var worth_data = question.attributes.label;
      var a_data = question.firstChild.firstChild.attributes.label;
      var q_data = question.lastChild.firstChild.attributes.label;

      //      trace("q[" + c + "," + q + "] is w:[" + worth_data + "] a:[" + a_data + "] q:[" + q_data + "]");

      var box = _root.main.stages.normal["box_" + c + "_" + q];
      box.set_data(worth_data, a_data, q_data);
      box.xml_node = question;

      q++;
    }


    c++;
  }
};

game.cmp_label = function(a,b) {
  var temp = _root.cmp(a.attributes.label, b.attributes.label);
  //  trace("cmp [" + a.attributes.label + "] [" + b.attributes.label + "] = [" + temp + "]");
  return temp;
}

