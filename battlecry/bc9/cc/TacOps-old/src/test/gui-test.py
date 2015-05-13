#!/usr/bin/env python

from frc2006_scorecard import *;

window = gtk.Window(gtk.WINDOW_TOPLEVEL);
card = scorecard(container=window);
card.saved = copy(card.current);
card.update_buttons();
window.connect("destroy", gtk.main_quit);
window.show();
gtk.main();
