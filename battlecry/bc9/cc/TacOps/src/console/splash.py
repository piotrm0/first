#!/usr/bin/env python

from gtk_utils import *;

class about_splash:
    def __init__(self, vbox_container=None):
	if None == vbox_container:
	    raise Exception("about_splash requires a container");
	self.vbox = vbox = vbox_container;
	image = gtk.Image();
	icon = gtk.gdk.pixbuf_new_from_file(PIX_DIR + "logo-robot.png");
	image.set_from_pixbuf(icon);
	vbox.pack_start(image, expand=False, fill=False);
	markup = ("<span size=\"24000\" weight=\"heavy\">TacOps " +
		"<span color=\"#F22\">2006</span></span>");
	label = gtk_label_from_markup(markup);
	vbox.pack_start(label, expand=False, fill=False);
	markup = "<i>Professional scoring and competition software.</i>";
	label = gtk_label_from_markup(markup);
	vbox.pack_start(label, expand=False, fill=False);
	markup = ("<span size=\"8000\">Copyright (C) 2005, KIWI Computer."
		+ "  All rights reserved.</span>");
	label = gtk_label_from_markup(markup);
	vbox.pack_start(label, expand=False, fill=False);
	sep = gtk.HSeparator();
	vbox.pack_start(sep, expand=True, fill=True, padding=8);
	label = gtk.Label("Developers / Credits :");
	vbox.pack_start(label, expand=False, fill=False);

	hbox = gtk.HBox();
	vbox = gtk.VBox();
	image = gtk.Image();
	image.set_alignment(0.5, 1.0);
	icon = gtk.gdk.pixbuf_new_from_file(PIX_DIR + "logo-KIWI.png");
	image.set_from_pixbuf(icon);
	vbox.pack_start(image, expand=True, fill=True);
	markup = ("<span size=\"16000\" face=\"Helvetica\"><b>Computer" +
		"</b></span>");
	label = gtk_label_from_markup(markup);
	vbox.pack_start(label, expand=False, fill=False);
	markup = ("<span size=\"6000\">5109 Nolan Drive\n" +
		"Minnetonka, MN 55343</span>");
	label = gtk_label_from_markup(markup);
	vbox.pack_start(label, expand=False, fill=False);
	label = gtk.Label("(877) KIWI-COM");
	label.set_alignment(0.5, 0.0);
	vbox.pack_start(label, expand=True, fill=True);
	hbox.pack_start(vbox, expand=True, fill=True);
	markup = ("<span size=\"8000\">\n" +
		"<b>    &#8226; Rick C. Petty</b>\n" +
		"\t&#8227; principal engineer\n" +
		"\t&#8227; database, server, UI\n" +
		"<b>    &#8226; Piotr Mardziel</b>\n" +
		"\t&#8227; graphics designer\n" +
		"\t&#8227; displays, scripting\n" +
		"<b>    &#8226; Nathan Gronda</b>\n" +
		"\t&#8227; print engineer\n" +
		"</span>");
	label = gtk_label_from_markup(markup);
	label.set_padding(4, 0);
	hbox.pack_start(label, expand=False, fill=False);

	self.vbox.pack_start(hbox, expand=True, fill=True);

class splash_window:
    def __init__(self, progressbar_text = None):
	self.window = gtk.Window();
	self.window.set_title("TacOps splash");
	self.window.set_border_width(2);
	self.window.set_position(gtk.WIN_POS_CENTER_ALWAYS);
	self.window.set_resizable(False);
	self.window.set_gravity(gtk.gdk.GRAVITY_CENTER);
	self.window.set_decorated(True);
	self.window.set_modal(False);
	self.window.set_type_hint(gtk.gdk.WINDOW_TYPE_HINT_SPLASHSCREEN);
	vbox = gtk.VBox();
	self.ProgressBar = gtk.ProgressBar();
	progress.do_progress(self.ProgressBar, progressbar_text);
	vbox.pack_end(self.ProgressBar, expand=False, fill=True);
	self.about = about_splash(vbox);
	self.window.add(vbox);
	self.window.show_all();
