
//test = get_opts("opt1 opt2 \"opt three\" opt4");
//trace("words:");
//for (word in test) {
//  trace(" word: \"" + test[word] + "\"");
//}

function get_opts(string) {
  var words = string.split(" ");

  var ret = new Array();

  var current = "";
  var quoted  = 0;

  for (var word_num = 0; word_num < words.length; word_num++) {
    var word = words[word_num];

    var first_char = word.charAt(0);
    var last_char  = word.charAt(word.length - 1);

//    trace("word is [" + word + "]");
//    trace("first char is [" + first_char + "]");
//    trace("last  char is [" + last_char + "]");

    if (quoted == 1) {
      if (last_char == '"') {
	current += word.substring(0, word.length-1);
	ret.push(current);
	quoted = 0;
	current = "";
      } else {
	current += word + " ";
      }
    } else {
      if (first_char == '"') {
	if (last_char == '"') {
	  ret.push(word.substring(1, word.length-1));
	} else {
	  quoted = 1;
	  current += word.substring(1, word.length) + " ";
	}
      } else {
	ret.push(word);
      }
    }
  }

  //  return ret.reverse();
  return ret;
}

function text2bool(text) {
    //trace("converting [" + text + "] to boolean");
  if (text == "true") {
    return true;
  } else {
    return false;
  }
}

function cmp(a,b) {
  if (a > b) { return -1 };
  if (b > a) { return 1 };
  return 0;
}

