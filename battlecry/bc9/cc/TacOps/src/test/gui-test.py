#!/usr/bin/env python

from rules import *;
from navigator import *;
from splash import *;

splash = splash_window("Loading...");

window = gtk.Window(gtk.WINDOW_TOPLEVEL);
card = scorecard(container=window, ProgressBar=splash.ProgressBar);

card.saved = copy(card.current);
card.update_buttons();
window.connect("destroy", gtk.main_quit);
window.show();
#window = gtk.Window(gtk.WINDOW_TOPLEVEL);
#nav = match_navigator(container=window, number=card.current.match_number);
#window.connect("destroy", gtk.main_quit);
#window.show();
def nothing():
    return True;

for i in range(0, 100):
    splash.progress.register(None, nothing);
gtk.main();
