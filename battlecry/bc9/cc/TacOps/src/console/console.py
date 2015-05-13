#!/usr/bin/env python

from gtk_utils import *;
import cc_client;
import socket;
from display import *;
from finals import *;
from navigator import *;
from rankings import *;
from rules import *;
from splash import *;

#import debug_util; debug_util.debug = 1;

TacOps = obj();

def ccenter_handle(source, condition):
    if condition & gobject.IO_ERR or condition & gobject.IO_HUP:
	gtk.main_quit();		##  RCP
    if condition & gobject.IO_OUT or condition & gobject.IO_PRI:
	TacOps.ccenter.net.sock_send();
	if not TacOps.ccenter.net.need_write():
	    print "****   Unregister";
	    return False;
	return True;
    if condition & gobject.IO_IN:
	TacOps.ccenter.net.sock_recv();
	return True;
    return False;

def ccenter_connect():
    try:
	TacOps.ccenter.connect(HOST_CCENTER);
    except socket.error, (value, message):
	ccenter_connect_error(message);
	return;
    TacOps.ccenter_out = gobject.io_add_watch(TacOps.ccenter.net.sock,
				gobject.IO_OUT, ccenter_connect_handle);
    TacOps.ccenter_timeout = gobject.timeout_add(5000, ccenter_timeout);

def ccenter_disconnect():
    msg = ("Console has been disconnected from CommandCenter!");
    gtk_alert_warning(msg);
    ccenter_connect();

def ccenter_connect_handle(source, condition):
    TacOps.ccenter.net.sock_send();
    if TacOps.ccenter.net.connected:
	gobject.source_remove(TacOps.ccenter_timeout);
	TacOps.ccenter_timeout = None;
	TacOps.ccenter_out = None;
	TacOps.ccenter_in = gobject.io_add_watch(TacOps.ccenter.net.sock,
	    gobject.IO_IN | gobject.IO_HUP | gobject.IO_ERR, ccenter_handle);
	TacOps.ccenter.net.set_notify('need_write', gobject.io_add_watch,
				TacOps.ccenter.net.sock, gobject.IO_OUT,
				ccenter_handle);
	TacOps.ccenter.net.set_notify('disconnect', ccenter_disconnect);
	progress.do_progress(None, "Initializing...");
	return False;	# not waiting for output
    return True;

def ccenter_timeout():
    gobject.source_remove(TacOps.ccenter_out);
    TacOps.ccenter_out = None;
    if TacOps.ccenter.net.connected:
	return False;
    ccenter_connect_error("Timed out waiting for connection.");
    return False;

def ccenter_init():
    TacOps.ccenter = cc_client("gui");
    ccenter_connect();

def ccenter_connect_error(error_msg):
    gtk_alert_error("<b>Unable to connect to CommandCenter:</b>\n\n" +
		    error_msg);
    gtk.main_quit();

def console_setup():
    TacOps.main = gtk.Window(gtk.WINDOW_TOPLEVEL);
    TacOps.main.set_title("TacOps 2006 Console");
    TacOps.main.set_size_request(1024, 752);
    TacOps.main.set_resizable(False);
    TacOps.main.set_border_width(4);
    TacOps.main.connect("destroy", gtk.main_quit);
    vbox = gtk.VBox();
    hbox = gtk.HBox();
    sep = gtk.VSeparator();
    hbox.pack_start(sep, expand=True, fill=True);
    label = gtk.Label();
    hbox.pack_start(label, expand=True, fill=True);
    markup = ("<span size=\"24000\" weight=\"heavy\">TacOps " +
	      "<span color=\"#F22\">2006</span></span>");
    label = gtk_label_from_markup(markup);
    hbox.pack_start(label, expand=False, fill=False);
    sep = gtk.VSeparator();
    hbox.pack_start(sep, expand=True, fill=True);
    icon = gtk.image_new_from_stock(gtk.STOCK_SELECT_COLOR, gtk.ICON_SIZE_DIALOG);
    hbox.pack_start(icon, expand=False, fill=False);
    label = gtk.Label("Set Main\ndisplay to: ");
    hbox.pack_start(label, expand=False, fill=False);
    TacOps.display.connect(TacOps.ccenter);
    hbox.pack_start(TacOps.display.container, expand=False, fill=False, padding=4);
    hbox.show_all();
    vbox.pack_start(hbox, expand=False, fill=False, padding=1);

    notebook = gtk.Notebook();
    notebook.show();
    notebook.set_show_border(True);
    notebook.set_show_tabs(True);
    notebook.set_tab_pos(gtk.POS_TOP);
    notebook.set_scrollable(False);
    notebook.popup_disable();

    markup = "<span size=\"16000\" weight=\"bold\">Scoring</span>";
    label = gtk_label_from_markup(markup);
    TacOps.card.connect(TacOps.ccenter);
    hbox = gtk.HBox();
    hbox.pack_start(TacOps.card.container, expand=False, fill=False);
    hbox.show();
    notebook.append_page(hbox, label);

    markup = "<span size=\"16000\" weight=\"bold\">Rankings</span>";
    label = gtk_label_from_markup(markup);
    TacOps.rankings.connect(TacOps.ccenter);
    hbox = gtk.HBox();
    hbox.pack_start(TacOps.rankings.container, expand=True, fill=True);
    hbox.show();
    notebook.append_page(hbox, label);

    markup = "<span size=\"16000\" weight=\"bold\">Finals</span>";
    label = gtk_label_from_markup(markup);
    TacOps.finals.connect(TacOps.ccenter);
    hbox = gtk.HBox();
    hbox.pack_start(TacOps.finals.container, expand=True, fill=True);
    hbox.show();
    notebook.append_page(hbox, label);

    vbox.pack_start(notebook, expand=True, fill=True);
    TacOps.nav.connect(TacOps.ccenter);
    vbox.pack_start(TacOps.nav.container, expand=False, fill=False);
    TacOps.card.nav = TacOps.nav;
    vbox.show();
    TacOps.main.add(vbox);

def console_ready():
    TacOps.card.on_save = TacOps.finals.ladder.build_ladder;
    TacOps.splash.window.hide();
    TacOps.main.show();

def navigate_changed(number):
    TacOps.card.change(number);
    TacOps.display.match_changed(number);

TacOps.splash = splash_window("Connecting to CommandCenter...");
progress.register(10, ccenter_init);
progress.register(5, None);
TacOps.card = scorecard();
TacOps.display = display();
TacOps.nav = match_navigator(navigate_changed);
TacOps.card.nav = TacOps.nav;
TacOps.rankings = rankings();
TacOps.finals = finals(TacOps.nav);
progress.register(5, console_setup);
progress.register(0, console_ready);

gtk.main();
