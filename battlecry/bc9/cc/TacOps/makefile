#
#	makefile - specific makefile for TacOps package
#	Project:	TacOps, FIRST scoring, etc. software
#	Authors:	Rick C. Petty
#
# Copyright (C) 1993-2004 KIWI Computer.  All rights reserved.
#
# Please read the enclosed COPYRIGHT notice and LICENSE agreements, if
# available.  All software and documentation in this file is protected
# under applicable law as stated in the aforementioned files.  If not
# included with this distribution, you can obtain these files, this
# package, and source code for this and related projects from:
#
# http://www.kiwi-computer.com/
#
# $Id: makefile,v 1.24 2004/03/25 21:20:00 rick Exp $
#

.if !defined(LOCALBASE)
LOCALBASE=	/usr/local
.endif
.if defined(PREFIX)
SHARE?=	$(PREFIX)/share/TacOps/
.else
PREFIX?= $(LOCALBASE)
SHARE?=	$(LOCALBASE)/share/TacOps/
.endif
APPNAME?=	TacOps
APPVERS?=	3


PGSQL_INCDIR!=	pg_config --includedir
PGSQL_LIBDIR!=	pg_config --libdir
PGSQL_CFLAGS=	-I$(PGSQL_INCDIR)
PGSQL_LDFLAGS=	-L$(PGSQL_LIBDIR) -lpq

###
###  additions to standard variables
###
BIN_LDFLAGS +=	-L$(LOCALBASE)/lib
#CFLAGS +=	-pthread -Wall -Werror -I$(LOCALBASE)/include
CFLAGS +=	-Wall -Werror -I$(LOCALBASE)/include
.if defined(DEBUG)
CFLAGS +=	-g -DDEBUG -O0
.endif
CFLAGS +=	-DSHARE=\"$(SHARE)\" -DPREFIX=\"$(PREFIX)/\"
CFLAGS +=	$(GNOME_CFLAGS) $(PGSQL_CFLAGS)
CFLAGS +=	-DAPPNAME=\"$(APPNAME)\" -DAPPVERS=\"$(APPVERS)\"
NO_WIN32=
IDIR+=		../inc

###
###  common stuff
###
COMMON_SOURCES=	db.c greycode.c \
		glade.c gpref.c gtk-clist.c gtk-container.c \
		gtk-notebook.c gtk-option-menu.c gtk-widget.c

###
###  target: dbtest
###
DBTEST_IDIR=	../src/test
DBTEST_SDIR=	../src/test ../src/common
DBTEST_SRCS=	db.c dbtest.c
DBTEST_LDFLAGS=	$(PGSQL_LDFLAGS)

###
###  target: vartest
###
VARTEST_IDIR=	../inc
VARTEST_SDIR=	../src/test ../src/common
VARTEST_SRCS=	var.c vartest.c

###
###  target: rsettest
###
RSETTEST_IDIR=	../inc ../src/test
RSETTEST_SDIR=	../src/test ../src/common
RSETTEST_SRCS=	string.c rset.c rsettest.c

###
###  target: ccenter
###
CCENTER_IDIR=	../inc ../src/ccenter
CCENTER_SDIR=	../src/common ../src/ccenter
CCENTER_SRCS=	network.c network_addr.c string.c \
		buffer.c db.c rset.c var.c \
		connection.c command.c server.c cc-commands.c \
		cc_db.c cc_env.c cc_exit.c cc_help.c cc_history.c \
		cc_kill.c cc_nick.c cc_notify.c cc_ping.c cc_send.c \
		cc_stat.c cc_su.c cc_sys.c cc_version.c cc_who.c
CCENTER_LDFLAGS=	$(PGSQL_LDFLAGS)

###
###  target:  plctest
###
PLCTEST_IDIR=	../src/arena
PLCTEST_SDIR=	../src/arena
PLCTEST_SRCS=	ecom.c ecom_util.c ether.c plctest.c plcutil.c
ARENA_IDIR=	../src/arena
ARENA_SDIR=	../src/common ../src/arena
ARENA_SRCS=	arena-2004.c arena.c command.c ecom.c ecom_util.c \
		ether.c sound.c
ARENA_NAME=	TacOps-arena
ARENA_LDFLAGS=	-lesd

###
###  target:  console (main GUI)
###
CONSOLE_IDIR=	../src/arena
CONSOLE_SDIR=	../src/common ../src/console
CONSOLE_SRCS=	$(COMMON_SOURCES) console.c gui-console.c gui-dialog.c \
		gui-display.c gui-event.c gui-extra.c gui-field.c \
		gui-finals.c gui-generate.c gui-nav.c gui-reports.c \
		gui-schedule.c gui-scoring.c gui-setup.c gui-status.c \
		gui-teams.c \
		rules.c scores.c
CONSOLE_NAME=	TacOps-console
CONSOLE_LDFLAGS= $(GNOME_LDFLAGS)
GENTEST_IDIR=	../src/console
GENTEST_SDIR=	../src/console
GENTEST_SRCS=	gen.c gentest.c


###
###  list of all targets
###
#LIBRARIES =
BINARIES = ccenter #dbtest vartest rsettest ##arena console #plctest gentest
all: ccenter
test: dbtest vartest rsettest


###  and finally, include our wrappers
.include "$(.CURDIR)/makefile.kiwi"

###
###  data files
###
SHARE_DATA=	console.glade

###
###  scripts
###
ADMIN_FILES=	create-database.sql
PRINT_FILES=	

.if defined(PREFIX) && defined(BSD_INSTALL_DATA)
install: install-hook
install-hook:
	env PREFIX=$(PREFIX) SHARE=$(SHARE) perl ../install.pl
	$(BSD_INSTALL_DATA) -m 0775 -d $(SHARE)
	$(BSD_INSTALL_DATA) -m 0775 -d $(SHARE)/gui
.for share in $(SHARE_DATA)
	$(BSD_INSTALL_DATA) ../src/share/$(share) $(SHARE)/gui/
.endfor share
	$(BSD_INSTALL_SCRIPT) -m 0775 -d $(SHARE)config
#.for script in $(SCRIPTS_CONFIG)
#	$(BSD_INSTALL_SCRIPT) ../src/config/$(script) $(SHARE)config/
#.endfor script
	$(BSD_INSTALL_DATA) -m 0775 -d $(SHARE)admin
.for file in $(ADMIN_FILES)
	$(BSD_INSTALL_DATA) ../src/admin/$(file) $(SHARE)/admin/
.endfor file
	$(BSD_INSTALL_DATA) -m 0775 -d $(SHARE)/print/reportdata
.for file in $(PRINT_FILES)
	$(BSD_INSTALL_DATA) ../src/print/reportdata/$(file) \
				$(SHARE)/print/reportdata/
.endfor
.endif
