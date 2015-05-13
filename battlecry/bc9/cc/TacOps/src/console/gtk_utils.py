#!/usr/bin/env python

from copy import copy;
import gobject;
import gtk;
import sys;
import os;

class obj:
    pass;


PIX_DIR=os.path.join(os.path.dirname(sys.path[0]), "share") + os.sep;

def gtk_label_from_markup(text):
    label = gtk.Label();
    label.set_markup(text);
    return label;

def gtk_alert_error(error_msg):
	dialog = gtk.MessageDialog(None, gtk.DIALOG_MODAL,
				   gtk.MESSAGE_ERROR, gtk.BUTTONS_CLOSE);
	dialog.set_markup(error_msg);
	dialog.run();
	dialog.destroy();

def gtk_alert_question(question_msg):
	dialog = gtk.MessageDialog(None, gtk.DIALOG_MODAL,
				   gtk.MESSAGE_QUESTION,
				   gtk.BUTTONS_OK_CANCEL);
	dialog.set_markup(question_msg);
	response = dialog.run();
	dialog.destroy();
	return (gtk.RESPONSE_OK == response);

def gtk_alert_warning(warning_msg):
	dialog = gtk.MessageDialog(None, gtk.DIALOG_MODAL,
				   gtk.MESSAGE_WARNING, gtk.BUTTONS_CLOSE);
	dialog.set_markup(warning_msg);
	dialog.run();
	dialog.destroy();

def gtk_rset_guess_xalign(rset, column):
    if len(rset) < 1:
	return 0.5;
    row = rset[0];
    element = row[column];
    if len(element) < 1:
	return 0.5;
    c = element[0];
    if c >= '0' and c <= '9':
	return 1.0;
    return 0.0;

def gtk_tree_view_get_selected_rows(treeview):
    if None == treeview:
	return None;
    selection = treeview.get_selection();
    return gtk_tree_selection_get_rows(selection);

def gtk_tree_selection_get_rows(selection):
    if None == selection:
	return None;
    selected = selection.get_selected_rows();
    if None == selected:
	return None;
    paths = selected[1];
    if None == paths:
	return None;
    rows = [];
    for path in paths:
	if None != path:
	    rows.append(path[0]);
    if len(rows) > 0:
	return rows;
    return None;

class progress_bar:
    def __init__(self):
	self.callbacks = [];
	self.progress_ticks = 0;
	self.total_progress_ticks = 0;

    def register(self, progress_ticks, callback_fn, * args):
	if None != callback_fn and not callable(callback_fn):
	    raise Exception("callback_fn is not callable or None");
	if None == progress_ticks:
	    progress_ticks = 1;
	params = (progress_ticks, callback_fn, args);
	self.callbacks.append(params);
	self.total_progress_ticks += progress_ticks;

    def do_progress(self, ProgressBar = None, next_text = None):
	if None != ProgressBar:
	    self.ProgressBar = ProgressBar;
	if not isinstance(self.ProgressBar, gtk.ProgressBar):
	    raise Exception("progress_bar requries a gtk.ProgressBar");
	if None != next_text:
	    self.ProgressBar.set_text(next_text);
	# register ourselves to run in the idle time (e.g. during startup)
	self.idle_source = gobject.idle_add(self.do_idle);
	
    def do_idle(self):
	if len(self.callbacks) > 0:
	    (ticks, callback_fn, args) = self.callbacks.pop(0);
	    fraction = float(self.progress_ticks);
	    fraction /= float(self.total_progress_ticks);
	    self.ProgressBar.set_fraction(fraction);
	    self.progress_ticks += ticks;
	    if None == callback_fn:
		return False;
	    callback_fn(* args);
	    return True;
	return False;

progress = progress_bar();

def gtk_register_timeout_for_query():
	pass;



