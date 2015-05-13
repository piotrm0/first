#!/usr/bin/env python

from frc2006_tables import *;
from cc_client import *;

class display_menu:
    def __init__(self):
	self.cc = None;
        self.MENUS = [	("Empty Screen", self.do_empty),
			("Current Match", self.do_current),
			("Match Results", self.do_results),
			("Current Rankings", self.do_rankings),
			("Finals Pairings", self.do_pairings),
			("Finals Ladder", self.do_ladder),
		];
	self.number = None;

    def connect(self, cc):
	self.cc = cc;
	self.cc.env_watch("match_state", self.status_changed);

    def match_changed(self, number):
	self.number = number;

    def set_state(self, state_label):
	self.cc.command("ENV game_state=\"" + state_label + "\"");

    def do_empty(self, state_label):
	self.set_state("empty");

    def do_current(self, widget = None):
#	if (None == self.number or len(self.number[0]) < 1 or
#	    int(self.number[0]) < 1):
#	    self.set_state("q_match");
#	else:
	if True:
	    self.set_state("e_match");
	self.cc.command("ENV scores_source=\"rts\"");

    def do_results(self, widget = None):
#	if (None == self.number or len(self.number) < 1 or
#	    int(self.number[0]) <= 1):
#	    self.set_state("q_results");
#	else:
	if True:
	    self.set_state("e_results");
	self.cc.command("ENV scores_source=\"db\"");

    def do_rankings(self, widget = None):
	self.set_state("rankings");

    def do_pairings(self, widget = None):
	self.set_state("pairings");

    def do_ladder(self, widget = None):
	self.set_state("ladder");

    def status_changed(self, key, old_value, new_value):
	if "auto" == new_value:
	    self.do_current();
