import pygtk;
pygtk.require('2.0');
import gtk;
from gtk_utils import *;
import cc_parser;
import rules;

class FinalsAlliancesView:

    def edited_team(self, cell, path, new_team, column):
        self.liststore[path][column] = new_team;
        return;

    def delete_event(self, widget, event, data=None):
        gtk.main_quit();
        return False;

    def __init__(self):
        columns = ['event_id', 'finals_alliance_number', 'recruit_order', 'team_number'];

        allrows = [];
        teamnum = 1;

        for alliancenum in range(0, rules.FINALS_ALLIANCES):
            for recruitnum in range(0, rules.FINALS_ALLIANCE_TEAMS):
                allrows.append(cc_parser.rset_row(['1', str(alliancenum + 1), str(recruitnum + 1), str(teamnum)], columns));
                teamnum += 1;

        allrset = cc_parser.rset(name="Finals Alliances", cc=None);

        allrset.set_data(columns, allrows);

        self.window = gtk.Window(gtk.WINDOW_TOPLEVEL);
        self.window.set_title("Result Set to Tree View");
        self.window.connect("delete_event", self.delete_event);

        self.liststore = gtk.ListStore(*([gobject.TYPE_STRING] * (rules.FINALS_ALLIANCE_TEAMS + 1)));

        for num in range(0, rules.FINALS_ALLIANCES):
            self.liststore.append([str(num + 1), '', '', '']);

        for row in allrset:
            self.liststore[int(row['finals_alliance_number']) - 1][int(row['recruit_order'])] = row['team_number'];

        self.treeview = gtk.TreeView(self.liststore);

        alliancecell = gtk.CellRendererText();
        self.alliancecolumn = gtk.TreeViewColumn('Alliance Number');
        self.treeview.append_column(self.alliancecolumn);
        self.alliancecolumn.pack_start(alliancecell, True);
        self.alliancecolumn.add_attribute(alliancecell, 'text', 0);
        self.alliancecolumn.set_sort_column_id(0);

        teamcells = [];
	self.teamcolumns = [];
        teamcells.append(gtk.CellRendererText());
	self.teamcolumns.append(gtk.TreeViewColumn('Captain', teamcells[0]));
        for num in range(1, rules.FINALS_ALLIANCE_TEAMS):
            teamcells.append(gtk.CellRendererText());
            self.teamcolumns.append(gtk.TreeViewColumn('Recruit', teamcells[num]));

        for num in range(0, rules.FINALS_ALLIANCE_TEAMS):
            self.treeview.append_column(self.teamcolumns[num]);
            self.teamcolumns[num].add_attribute(teamcells[num], 'text', num + 1);
            teamcells[num].set_property('editable', True);
            teamcells[num].connect('edited', self.edited_team, num + 1);

        for num in range(0, rules.FINALS_ALLIANCE_TEAMS):
            self.teamcolumns[num].set_sort_column_id(-1);

        self.treeview.set_reorderable(False);

        self.window.add(self.treeview);
        self.window.show_all();

def main():
    gtk.main();

if __name__ == "__main__":
    tvtest = FinalsAlliancesView();
    main();