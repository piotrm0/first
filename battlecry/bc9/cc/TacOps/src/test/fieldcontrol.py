import pygtk
pygtk.require( '2.0' )
import gtk
import gobject
import errno
import winsound
import cc_client
from net_client import net_client
from select import select
from sys import stdin, exit

import debug_util
debug_util.debug = 0

class FieldInterface:
    def cc_connect_handle( self, source, condition ):
        self.cc.net.sock_send()
        if self.cc.net.connected:
            gobject.io_add_watch( self.cc.net.sock, gobject.IO_IN | gobject.IO_HUP | gobject.IO_ERR, self.cc_handle )
            self.cc.net.set_notify( 'need_write', gobject.io_add_watch, self.cc.net.sock, gobject.IO_OUT, self.cc_handle )
            return False
        return True

    def cc_handle( self, source, condition ):
        if condition & gobject.IO_ERR or condition & gobject.IO_HUP:
            gtk.main_quit()
        if condition & gobject.IO_IN:
            self.cc.net.sock_recv()
            return True
        if condition & gobject.IO_OUT or condition & gobject.IO_PRI:
            self.cc.net.sock_send()
            if not self.cc.net.need_write():
                return False
            return True
        return False

    def delete_event( self, widget, event, data = None ):
        gtk.main_quit()
        return False

    def register_click( self, widget, data = None ):
        self.field[0].register_session()
        self.field[1].register_session()

    def stop_match_click( self, widget, data = None ):
        self.field[0].stop_match()
        self.field[1].stop_match()

    def reset_field_click( self, widget, data = None ):
        self.blueteam1label.set_markup( ''.join( ['<span color="#0000ff" size="30000">', self.blueteam1, '</span>'] ) )
        self.blueteam2label.set_markup( ''.join( ['<span color="#0000ff" size="30000">', self.blueteam2, '</span>'] ) )
        self.blueteam3label.set_markup( ''.join( ['<span color="#0000ff" size="30000">', self.blueteam3, '</span>'] ) )
        self.redteam1label.set_markup( ''.join( ['<span color="#ff0000" size="30000">', self.redteam1, '</span>'] ) )
        self.redteam2label.set_markup( ''.join( ['<span color="#ff0000" size="30000">', self.redteam2, '</span>'] ) )
        self.redteam3label.set_markup( ''.join( ['<span color="#ff0000" size="30000">', self.redteam3, '</span>'] ) )
        self.field[0].stop_match()
        self.field[1].stop_match()
        self.field[0].reset_field()
        self.field[1].reset_field()
        self.field[0].number_tm( 0, int( self.blueteam1 ) )
        self.field[1].number_tm( 0, int( self.redteam1 ) )
        self.field[0].number_tm( 1, int( self.blueteam2 ) )
        self.field[1].number_tm( 1, int( self.redteam2 ) )
        self.field[0].number_tm( 2, int( self.blueteam3 ) )
        self.field[1].number_tm( 2, int( self.redteam3 ) )
        self.cc.command( 'ENV match_state=reset' )

    def station_enable_click( self, widget, data = None ):
        ( field, team ) = data
        self.field[field].tm_en_bypass( team )

    def tm_bypass_click( self, widget, data = None ):
        ( field, team ) = data
        self.field[field].tm_bypass( team )
    
    def tm_stop_bypass_click( self, widget, data = None ):
        ( field, team ) = data
        self.field[field].tm_stop_bypass( team )

    def disable_all_click( self, widget, data = None ):
        self.field[0].disable_all()
        self.field[1].disable_all()

    def start_match_click( self, widget, data = None ):
#        winsound.PlaySound( 'StartMatch.wav', winsound.SND_FILENAME | winsound.SND_ASYNC )
        self.field[0].reset_match()
        self.field[1].reset_match()
        self.field[0].start_match()
        self.field[1].start_match()

    def pause_match_click( self, widget, data = None ):
#        winsound.PlaySound( 'EndAuton.wav', winsound.SND_FILENAME | winsound.SND_ASYNC )
        self.field[data].lowest_score()
        self.field[0].pause_match()
        self.field[1].pause_match()

    def clock_change( self, clock ):
#        if clock == 0:
#            winsound.PlaySound( 'EndMatch.wav', winsound.SND_FILENAME | winsound.SND_ASYNC )
        self.toplabel.set_markup( ''.join( ['<span size="40000">', str( clock / 1000 ), '</span>'] ) )
        if self.old_time != clock / 1000:
            self.cc.command( ''.join( ['ENV clock=', str( clock / 1000 )] ) )
            self.old_time = clock / 1000

    def port_blue_change( self ):
        if self.field[0].automode:
            self.cc.command( 'ENV match_state=auto' )
        elif self.field[0].manualmode:
            self.cc.command( 'ENV match_state=running' )

        if self.field[0].fieldready:
            self.bluefieldready.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.bluefieldready.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )

        if self.field[0].stationenable1:
            self.blueteam1enabled.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.blueteam1enabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        if self.field[0].nothere1:
            self.blueteam1nothere.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.blueteam1nothere.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        if self.field[0].stopactive1:
            self.blueteam1disabled.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.blueteam1disabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )

        if self.field[0].stationenable2:
            self.blueteam2enabled.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.blueteam2enabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        if self.field[0].nothere2:
            self.blueteam2nothere.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.blueteam2nothere.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        if self.field[0].stopactive2:
            self.blueteam2disabled.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.blueteam2disabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )

        if self.field[0].stationenable3:
            self.blueteam3enabled.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.blueteam3enabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        if self.field[0].nothere3:
            self.blueteam3nothere.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.blueteam3nothere.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        if self.field[0].stopactive3:
            self.blueteam3disabled.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.blueteam3disabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )

    def port_red_change( self ):
        if self.field[1].fieldready:
            self.redfieldready.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.redfieldready.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )

        if self.field[1].stationenable1:
            self.redteam1enabled.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.redteam1enabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        if self.field[1].nothere1:
            self.redteam1nothere.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.redteam1nothere.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        if self.field[1].stopactive1:
            self.redteam1disabled.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.redteam1disabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )

        if self.field[1].stationenable2:
            self.redteam2enabled.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.redteam2enabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        if self.field[1].nothere2:
            self.redteam2nothere.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.redteam2nothere.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        if self.field[1].stopactive2:
            self.redteam2disabled.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.redteam2disabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )

        if self.field[1].stationenable3:
            self.redteam3enabled.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.redteam3enabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        if self.field[1].nothere3:
            self.redteam3nothere.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.redteam3nothere.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        if self.field[1].stopactive3:
            self.redteam3disabled.set_from_stock( gtk.STOCK_YES, gtk.ICON_SIZE_SMALL_TOOLBAR )
        else:
            self.redteam3disabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )

    def on_teams( self, key, old_value, value ):
        if key == 'blue_team1':
            self.blueteam1 = value
        elif key == 'blue_team2':
            self.blueteam2 = value
        elif key == 'blue_team3':
            self.blueteam3 = value
        elif key == 'red_team1':
            self.redteam1 = value
        elif key == 'red_team2':
            self.redteam2 = value
        elif key == 'red_team3':
            self.redteam3 = value

    def __init__( self ):
        self.blueteam1 = '0'
        self.blueteam2 = '0'
        self.blueteam3 = '0'
        self.redteam1 = '0'
        self.redteam2 = '0'
        self.redteam3 = '0'
        self.old_time = 0

        self.cc = cc_client.cc_client( 'Control' )
        self.cc.connect( '130.215.136.247' )
        gobject.io_add_watch( self.cc.net.sock, gobject.IO_OUT, self.cc_connect_handle )
        self.cc.env_watch('blue_team1', self.on_teams)
        self.cc.env_watch('blue_team2', self.on_teams)
        self.cc.env_watch('blue_team3', self.on_teams)
        self.cc.env_watch('red_team1', self.on_teams)
        self.cc.env_watch('red_team2', self.on_teams)
        self.cc.env_watch('red_team3', self.on_teams)

        self.field = []
        self.field.append( FieldControl( '192.168.0.57', 44818 ) )
        self.field.append( FieldControl( '192.168.0.54', 44818 ) )
        self.field[0].notify['clock'] = self.clock_change
        self.field[0].notify['port10'] = self.port_blue_change
        self.field[1].notify['port10'] = self.port_red_change

        self.window = gtk.Window( gtk.WINDOW_TOPLEVEL )
        self.window.set_title( '2006 Field Control' )
        self.window.set_size_request( 800, 600 )
        self.window.connect( 'delete_event', self.delete_event )

        vbox = gtk.VBox()

        hbox = gtk.HBox()

        self.toplabel = gtk.Label()
        self.toplabel.set_markup( '<span size="40000">Time not set</span>' )
        hbox.pack_start( self.toplabel, padding = 2 )

        vbox.pack_start( hbox, padding = 2 )

        hbox = gtk.HBox( homogeneous = True )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="20000">Register</span>' )
        button.add( label )
        button.connect( 'clicked', self.register_click, None )
        hbox.pack_start( button, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="20000">Start</span>' )
        button.add( label )
        button.connect( 'clicked', self.start_match_click, None )
        hbox.pack_start( button, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="20000">Stop</span>' )
        button.add( label )
        button.connect( 'clicked', self.stop_match_click, None )
        hbox.pack_start( button, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="20000">Reset</span>' )
        button.add( label )
        button.connect( 'clicked', self.reset_field_click, None )
        hbox.pack_start( button, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="20000">Disable all</span>' )
        button.add( label )
        button.connect( 'clicked', self.disable_all_click, None )
        hbox.pack_start( button, padding = 2 )

        vbox.pack_start( hbox, padding = 2 )

        hbox = gtk.HBox( homogeneous = True )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="20000">Blue won auto</span>' )
        button.add( label )
        button.connect( 'clicked', self.pause_match_click, 0 )
        hbox.pack_start( button, padding = 2 )

        vbox2 = gtk.VBox()
        label = gtk.Label()
        label.set_markup( '<span size="12000">Blue field ready</span>' )
        vbox2.pack_start( label, padding = 2 )
        self.bluefieldready = gtk.Image()
        self.bluefieldready.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.bluefieldready, padding = 2 )
        hbox.pack_start( vbox2, padding = 2 )

        vbox2 = gtk.VBox()
        label = gtk.Label()
        label.set_markup( '<span size="12000">Red field ready</span>' )
        vbox2.pack_start( label, padding = 2 )
        self.redfieldready = gtk.Image()
        self.redfieldready.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.redfieldready, padding = 2 )
        hbox.pack_start( vbox2, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="20000">Red won auto</span>' )
        button.add( label )
        button.connect( 'clicked', self.pause_match_click, 1 )
        hbox.pack_start( button, padding = 2 )

        vbox.pack_start( hbox, padding = 2 )

        hbox = gtk.HBox( homogeneous = True )

        self.blueteam1label = gtk.Label()
        self.blueteam1label.set_markup( ''.join( ['<span color="#0000ff" size="30000">', self.blueteam1, '</span>'] ) )
        hbox.pack_start( self.blueteam1label, padding = 2 )

        vbox2 = gtk.VBox()

        self.blueteam1enabled = gtk.Image()
        self.blueteam1enabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.blueteam1enabled, padding = 2 )

        self.blueteam1nothere = gtk.Image()
        self.blueteam1nothere.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.blueteam1nothere, padding = 2 )

        self.blueteam1disabled = gtk.Image()
        self.blueteam1disabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.blueteam1disabled, padding = 2 )

        hbox.pack_start( vbox2, padding = 2 )

        vbox2 = gtk.VBox()

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Station enable</span>' )
        button.add( label )
        button.connect( 'clicked', self.station_enable_click, [0, 0] )
        vbox2.pack_start( button, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Not here</span>' )
        button.add( label )
        button.connect( 'clicked', self.tm_bypass_click, [0, 0] )
        vbox2.pack_start( button, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Disable</span>' )
        button.add( label )
        button.connect( 'clicked', self.tm_stop_bypass_click, [0, 0] )
        vbox2.pack_start( button, padding = 2 )

        hbox.pack_start( vbox2, padding = 2 )

        vbox2 = gtk.VBox()

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Station enable</span>' )
        button.add( label )
        button.connect( 'clicked', self.station_enable_click, [1, 2] )
        vbox2.pack_start( button, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Not here</span>' )
        button.add( label )
        button.connect( 'clicked', self.tm_bypass_click, [1, 2] )
        vbox2.pack_start( button, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Disable</span>' )
        button.add( label )
        button.connect( 'clicked', self.tm_stop_bypass_click, [1, 2] )
        vbox2.pack_start( button, padding = 2 )

        hbox.pack_start( vbox2, padding = 2 )

        vbox2 = gtk.VBox()

        self.redteam3enabled = gtk.Image()
        self.redteam3enabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.redteam3enabled, padding = 2 )

        self.redteam3nothere = gtk.Image()
        self.redteam3nothere.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.redteam3nothere, padding = 2 )

        self.redteam3disabled = gtk.Image()
        self.redteam3disabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.redteam3disabled, padding = 2 )

        hbox.pack_start( vbox2, padding = 2 )

        self.redteam3label = gtk.Label()
        self.redteam3label.set_markup( ''.join( ['<span color="#ff0000" size="30000">', self.redteam3, '</span>'] ) )
        hbox.pack_start( self.redteam3label, padding = 2 )

        vbox.pack_start( hbox, padding = 2 )

        hbox = gtk.HBox( homogeneous = True )

        self.blueteam2label = gtk.Label()
        self.blueteam2label.set_markup( ''.join( ['<span color="#0000ff" size="30000">', self.blueteam2, '</span>'] ) )
        hbox.pack_start( self.blueteam2label, padding = 2 )

        vbox2 = gtk.VBox()

        self.blueteam2enabled = gtk.Image()
        self.blueteam2enabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.blueteam2enabled, padding = 2 )

        self.blueteam2nothere = gtk.Image()
        self.blueteam2nothere.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.blueteam2nothere, padding = 2 )

        self.blueteam2disabled = gtk.Image()
        self.blueteam2disabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.blueteam2disabled, padding = 2 )

        hbox.pack_start( vbox2, padding = 2 )

        vbox2 = gtk.VBox()

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Station enable</span>' )
        button.add( label )
        button.connect( 'clicked', self.station_enable_click, [0, 1] )
        vbox2.pack_start( button, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Not here</span>' )
        button.add( label )
        button.connect( 'clicked', self.tm_bypass_click, [0, 1] )
        vbox2.pack_start( button, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Disable</span>' )
        button.add( label )
        button.connect( 'clicked', self.tm_stop_bypass_click, [0, 1] )
        vbox2.pack_start( button, padding = 2 )

        hbox.pack_start( vbox2, padding = 2 )

        vbox2 = gtk.VBox()

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Station enable</span>' )
        button.add( label )
        button.connect( 'clicked', self.station_enable_click, [1, 1] )
        vbox2.pack_start( button, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Not here</span>' )
        button.add( label )
        button.connect( 'clicked', self.tm_bypass_click, [1, 1] )
        vbox2.pack_start( button, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Disable</span>' )
        button.add( label )
        button.connect( 'clicked', self.tm_stop_bypass_click, [1, 1] )
        vbox2.pack_start( button, padding = 2 )

        hbox.pack_start( vbox2, padding = 2 )

        vbox2 = gtk.VBox()

        self.redteam2enabled = gtk.Image()
        self.redteam2enabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.redteam2enabled, padding = 2 )

        self.redteam2nothere = gtk.Image()
        self.redteam2nothere.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.redteam2nothere, padding = 2 )

        self.redteam2disabled = gtk.Image()
        self.redteam2disabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.redteam2disabled, padding = 2 )

        hbox.pack_start( vbox2, padding = 2 )

        self.redteam2label = gtk.Label()
        self.redteam2label.set_markup( ''.join( ['<span color="#ff0000" size="30000">', self.redteam2, '</span>'] ) )
        hbox.pack_start( self.redteam2label, padding = 2 )

        vbox.pack_start( hbox, padding = 2 )

        hbox = gtk.HBox( homogeneous = True )

        self.blueteam3label = gtk.Label()
        self.blueteam3label.set_markup( ''.join( ['<span color="#0000ff" size="30000">', self.blueteam3, '</span>'] ) )
        hbox.pack_start( self.blueteam3label, padding = 2 )

        vbox2 = gtk.VBox()

        self.blueteam3enabled = gtk.Image()
        self.blueteam3enabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.blueteam3enabled, padding = 2 )

        self.blueteam3nothere = gtk.Image()
        self.blueteam3nothere.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.blueteam3nothere, padding = 2 )

        self.blueteam3disabled = gtk.Image()
        self.blueteam3disabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.blueteam3disabled, padding = 2 )

        hbox.pack_start( vbox2, padding = 2 )

        vbox2 = gtk.VBox()

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Station enable</span>' )
        button.add( label )
        button.connect( 'clicked', self.station_enable_click, [0, 2] )
        vbox2.pack_start( button, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Not here</span>' )
        button.add( label )
        button.connect( 'clicked', self.tm_bypass_click, [0, 2] )
        vbox2.pack_start( button, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Disable</span>' )
        button.add( label )
        button.connect( 'clicked', self.tm_stop_bypass_click, [0, 2] )
        vbox2.pack_start( button, padding = 2 )

        hbox.pack_start( vbox2, padding = 2 )

        vbox2 = gtk.VBox()

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Station enable</span>' )
        button.add( label )
        button.connect( 'clicked', self.station_enable_click, [1, 0] )
        vbox2.pack_start( button, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Not here</span>' )
        button.add( label )
        button.connect( 'clicked', self.tm_bypass_click, [1, 0] )
        vbox2.pack_start( button, padding = 2 )

        button = gtk.Button()
        label = gtk.Label()
        label.set_markup( '<span size="14000">Disable</span>' )
        button.add( label )
        button.connect( 'clicked', self.tm_stop_bypass_click, [1, 0] )
        vbox2.pack_start( button, padding = 2 )

        hbox.pack_start( vbox2, padding = 2 )

        vbox2 = gtk.VBox()

        self.redteam1enabled = gtk.Image()
        self.redteam1enabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.redteam1enabled, padding = 2 )

        self.redteam1nothere = gtk.Image()
        self.redteam1nothere.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.redteam1nothere, padding = 2 )

        self.redteam1disabled = gtk.Image()
        self.redteam1disabled.set_from_stock( gtk.STOCK_NO, gtk.ICON_SIZE_SMALL_TOOLBAR )
        vbox2.pack_start( self.redteam1disabled, padding = 2 )

        hbox.pack_start( vbox2, padding = 2 )

        self.redteam1label = gtk.Label()
        self.redteam1label.set_markup( ''.join( ['<span color="#ff0000" size="30000">', self.redteam1, '</span>'] ) )
        hbox.pack_start( self.redteam1label, padding = 2 )

        vbox.pack_start( hbox, padding = 2 )

        self.window.add( vbox )

        self.window.show_all()

class FieldControl:
    def __init__( self, server = '192.168.0.54', port = 44818 ):
        self.registered = False
        self.session = ''
        self.autoclock = 0
        self.clock = 0
        self.automode = False
        self.manualmode = False
        self.notify = {}
        self.registersession = '\x65\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x05\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00'
        self.stopmatch = '\x6f\x00\x4e\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x3e\x00\x52\x02\x20\x06\x24\x01\x05\x99\x30\x00\x4d\x14\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x10\x48\x4d\x49\x5f\x57\x5fSTOP_MATCH\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00'
        self.resetfield = '\x6f\x00\x50\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x40\x00\x52\x02\x20\x06\x24\x01\x05\x99\x32\x00\x4d\x15\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x11\x48\x4d\x49\x5f\x57\x5fRESET_FIELD\x00\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00'
        self.numbertm = []
        self.numbertm.append( '\x6f\x00\x50\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x40\x00\x52\x02\x20\x06\x24\x01\x05\x99\x32\x00\x4d\x14\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x10\x48\x4d\x49\x5f\x57\x5fNUMBER_TM1\xc4\x00\x01\x00\xff\xff\x00\x00\x01\x00\x01\x00' )
        self.numbertm.append( '\x6f\x00\x50\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x40\x00\x52\x02\x20\x06\x24\x01\x05\x99\x32\x00\x4d\x14\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x10\x48\x4d\x49\x5f\x57\x5fNUMBER_TM2\xc4\x00\x01\x00\xff\xff\x00\x00\x01\x00\x01\x00' )
        self.numbertm.append( '\x6f\x00\x50\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x40\x00\x52\x02\x20\x06\x24\x01\x05\x99\x32\x00\x4d\x14\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x10\x48\x4d\x49\x5f\x57\x5fNUMBER_TM3\xc4\x00\x01\x00\xff\xff\x00\x00\x01\x00\x01\x00' )
        self.tmbypass = []
        self.tmbypass.append( '\x6f\x00\x4e\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x3e\x00\x52\x02\x20\x06\x24\x01\x05\x99\x30\x00\x4d\x14\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x10\x48\x4d\x49\x5f\x57\x5fTM1_BYPASS\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00' )
        self.tmbypass.append( '\x6f\x00\x4e\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x3e\x00\x52\x02\x20\x06\x24\x01\x05\x99\x30\x00\x4d\x14\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x10\x48\x4d\x49\x5f\x57\x5fTM2_BYPASS\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00' )
        self.tmbypass.append( '\x6f\x00\x4e\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x3e\x00\x52\x02\x20\x06\x24\x01\x05\x99\x30\x00\x4d\x14\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x10\x48\x4d\x49\x5f\x57\x5fTM3_BYPASS\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00' )
        self.tmenbypass = []
        self.tmenbypass.append( '\x6f\x00\x52\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x42\x00\x52\x02\x20\x06\x24\x01\x05\x99\x34\x00\x4d\x16\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x13\x48\x4d\x49\x5f\x57\x5fTM1_EN_BYPASS\x00\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00' )
        self.tmenbypass.append( '\x6f\x00\x52\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x42\x00\x52\x02\x20\x06\x24\x01\x05\x99\x34\x00\x4d\x16\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x13\x48\x4d\x49\x5f\x57\x5fTM2_EN_BYPASS\x00\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00' )
        self.tmenbypass.append( '\x6f\x00\x52\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x42\x00\x52\x02\x20\x06\x24\x01\x05\x99\x34\x00\x4d\x16\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x13\x48\x4d\x49\x5f\x57\x5fTM3_EN_BYPASS\x00\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00' )
        self.tmctrlokbypass = []
        self.tmctrlokbypass.append( '\x6f\x00\x56\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x46\x00\x52\x02\x20\x06\x24\x01\x05\x99\x38\x00\x4d\x18\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x18\x48\x4d\x49\x5f\x57\x5fTM1_CTRL_OK_BYPASS\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00' )
        self.tmctrlokbypass.append( '\x6f\x00\x56\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x46\x00\x52\x02\x20\x06\x24\x01\x05\x99\x38\x00\x4d\x18\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x18\x48\x4d\x49\x5f\x57\x5fTM2_CTRL_OK_BYPASS\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00' )
        self.tmctrlokbypass.append( '\x6f\x00\x56\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x46\x00\x52\x02\x20\x06\x24\x01\x05\x99\x38\x00\x4d\x18\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x18\x48\x4d\x49\x5f\x57\x5fTM3_CTRL_OK_BYPASS\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00' )
        self.tmstopbypass = []
        self.tmstopbypass.append( '\x6f\x00\x54\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x44\x00\x52\x02\x20\x06\x24\x01\x05\x99\x36\x00\x4d\x17\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x15\x48\x4d\x49\x5f\x57\x5fTM1_STOP_BYPASS\x00\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00' )
        self.tmstopbypass.append( '\x6f\x00\x54\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x44\x00\x52\x02\x20\x06\x24\x01\x05\x99\x36\x00\x4d\x17\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x15\x48\x4d\x49\x5f\x57\x5fTM2_STOP_BYPASS\x00\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00' )
        self.tmstopbypass.append( '\x6f\x00\x54\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x44\x00\x52\x02\x20\x06\x24\x01\x05\x99\x36\x00\x4d\x17\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x15\x48\x4d\x49\x5f\x57\x5fTM3_STOP_BYPASS\x00\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00' )
        self.disableall = '\x6f\x00\x50\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x40\x00\x52\x02\x20\x06\x24\x01\x05\x99\x32\x00\x4d\x15\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x11\x48\x4d\x49\x5f\x57\x5fDISABLE_ALL\x00\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00'
        self.resetmatch = '\x6f\x00\x50\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x40\x00\x52\x02\x20\x06\x24\x01\x05\x99\x32\x00\x4d\x15\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x11\x48\x4d\x49\x5f\x57\x5fRESET_MATCH\x00\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00'
        self.startmatch = '\x6f\x00\x50\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x40\x00\x52\x02\x20\x06\x24\x01\x05\x99\x32\x00\x4d\x15\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x11\x48\x4d\x49\x5f\x57\x5fSTART_MATCH\x00\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00'
        self.pausematch = '\x6f\x00\x50\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x40\x00\x52\x02\x20\x06\x24\x01\x05\x99\x32\x00\x4d\x15\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x11\x48\x4d\x49\x5f\x57\x5fPAUSE_MATCH\x00\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00'
        self.lowestscore = '\x6f\x00\x50\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x40\x00\x52\x02\x20\x06\x24\x01\x05\x99\x32\x00\x4d\x15\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x12\x48\x4d\x49\x5f\x57\x5fLOWEST_SCORE\xc1\x00\x01\x00\x01\x00\x01\x00\x01\x00'
        self.port9 = '\x6f\x00\x46\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x36\x00\x52\x02\x20\x06\x24\x01\x05\x99\x28\x00\x4c\x12\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x09\x48\x4d\x49\x5f\x52\x5f\x49\x4e\x54\x00\x28\x00\x0b\x00\x01\x00\x01\x00'
        self.port10 = '\x6f\x00\x46\x00\xff\xff\xff\xff\x00\x00\x00\x00\x02\x00\x00\x00\xa0\xc6\xfa\x01\x00\x00\x00\x00\x00\x00\x00\x00\x05\x00\x02\x00\x00\x00\x00\x00\xb2\x00\x36\x00\x52\x02\x20\x06\x24\x01\x05\x99\x28\x00\x4c\x12\x91\x13\x50\x52\x4f\x47\x52\x41\x4d\x3a\x4d\x41\x49\x4e\x50\x52\x4f\x47\x52\x41\x4d\x00\x91\x0a\x48\x4d\x49\x5f\x52\x5f\x42\x4f\x4f\x4c\x28\x00\x01\x00\x01\x00\x01\x00'

        self.net = net_client( server, port )
        self.net.notify['connect'] = self.on_connect
        self.net.notify['disconnect'] = self.on_disconnect
        self.net.notify['data'] = self.on_data

        self.net.connect()
        gobject.io_add_watch( self.net.sock, gobject.IO_OUT, self.net_connect_handle )
        gobject.timeout_add( 250, self.port_check )

    def register_session( self ):
        self.net.send( self.registersession )

    def stop_match( self ):
        self.net.send( self.stopmatch )

    def reset_field( self ):
        self.net.send( self.resetfield )

    def number_tm( self, position, number ):
        reversenumber = ''.join( [chr( number & 0xff ), chr( ( number >> 8 ) & 0xff )] )
        self.net.send( self.numbertm[position].replace( '\xff\xff', reversenumber, 1 ) )

    def tm_bypass( self, team ):
        self.net.send( self.tmbypass[team] )

    def tm_en_bypass( self, team ):
        self.net.send( self.tmenbypass[team] )

    def tm_stop_bypass( self, team ):
        self.net.send( self.tmstopbypass[team] )

    def disable_all( self ):
        self.net.send( self.disableall )

    def reset_match( self ):
        self.net.send( self.resetmatch )

    def start_match( self ):
        self.net.send( self.startmatch )

    def pause_match( self ):
        self.net.send( self.pausematch )

    def lowest_score( self ):
        self.net.send( self.lowestscore )

    def on_connect( self, *args, **kw ):
        self.register_session()

    def on_disconnect( self ):
        self.registered = False
        self.net.connect()

    def net_connect_handle( self, source, condition ):
        self.net.sock_send()
        if self.net.connected:
            gobject.io_add_watch( self.net.sock, gobject.IO_IN | gobject.IO_HUP | gobject.IO_ERR, self.net_handle )
            self.net.set_notify( 'need_write', gobject.io_add_watch, self.net.sock, gobject.IO_OUT, self.net_handle )
            return False
        return True

    def net_handle( self, source, condition ):
        if condition & gobject.IO_IN:
            self.net.sock_recv()
            return True

        if condition & gobject.IO_OUT or condition & gobject.IO_PRI:
            self.net.sock_send()
            if not self.net.need_write():
                return False
            return True
        return False

    def port_check( self ):
        if self.registered:
            self.net.send( self.port9 )
            self.net.send( self.port10 )
        return True

    def on_data( self, the_data ):
        lengthstr = the_data[2:4]
        length = ( ord( lengthstr[1] ) << 8 ) + ord( lengthstr[0] )
        length += 24
        the_data = the_data[0:length]
        print len( the_data )
        if the_data[0] == '\x65':
            self.on_reg_data( the_data )
        elif len( the_data ) == 90 or len( the_data ) == 50:
            self.on_port_data( the_data )
        return len( the_data )

    def on_reg_data( self, the_data ):
        self.session = the_data[4:8]
        self.resetfield = self.resetfield.replace( '\xff\xff\xff\xff', self.session, 1 )
        self.stopmatch = self.stopmatch.replace( '\xff\xff\xff\xff', self.session, 1 )
        self.numbertm[0] = self.numbertm[0].replace( '\xff\xff\xff\xff', self.session, 1 )
        self.numbertm[1] = self.numbertm[1].replace( '\xff\xff\xff\xff', self.session, 1 )
        self.numbertm[2] = self.numbertm[2].replace( '\xff\xff\xff\xff', self.session, 1 )
        self.tmbypass[0] = self.tmbypass[0].replace( '\xff\xff\xff\xff', self.session, 1 )
        self.tmbypass[1] = self.tmbypass[1].replace( '\xff\xff\xff\xff', self.session, 1 )
        self.tmbypass[2] = self.tmbypass[2].replace( '\xff\xff\xff\xff', self.session, 1 )
        self.tmenbypass[0] = self.tmenbypass[0].replace( '\xff\xff\xff\xff', self.session, 1 )
        self.tmenbypass[1] = self.tmenbypass[1].replace( '\xff\xff\xff\xff', self.session, 1 )
        self.tmenbypass[2] = self.tmenbypass[2].replace( '\xff\xff\xff\xff', self.session, 1 )
        self.tmctrlokbypass[0] = self.tmctrlokbypass[0].replace( '\xff\xff\xff\xff', self.session, 1 )
        self.tmctrlokbypass[1] = self.tmctrlokbypass[1].replace( '\xff\xff\xff\xff', self.session, 1 )
        self.tmctrlokbypass[2] = self.tmctrlokbypass[2].replace( '\xff\xff\xff\xff', self.session, 1 )
        self.tmstopbypass[0] = self.tmstopbypass[0].replace( '\xff\xff\xff\xff', self.session, 1 )
        self.tmstopbypass[1] = self.tmstopbypass[1].replace( '\xff\xff\xff\xff', self.session, 1 )
        self.tmstopbypass[2] = self.tmstopbypass[2].replace( '\xff\xff\xff\xff', self.session, 1 )
        self.disableall = self.disableall.replace( '\xff\xff\xff\xff', self.session, 1 )
        self.resetmatch = self.resetmatch.replace( '\xff\xff\xff\xff', self.session, 1 )
        self.startmatch = self.startmatch.replace( '\xff\xff\xff\xff', self.session, 1 )
        self.pausematch = self.pausematch.replace( '\xff\xff\xff\xff', self.session, 1 )
        self.lowestscore = self.lowestscore.replace( '\xff\xff\xff\xff', self.session, 1 )
        self.port9 = self.port9.replace( '\xff\xff\xff\xff', self.session, 1 )
        self.port10 = self.port10.replace( '\xff\xff\xff\xff', self.session, 1 )
        self.registered = True

    def on_port_data( self, the_data ):
        if len( the_data ) == 90:
            autoclock = the_data[50:54]
            self.autoclock = ( ord( autoclock[3] ) << 24 ) + ( ord( autoclock[2] ) << 16 ) + ( ord( autoclock[1] ) << 8 ) + ord( autoclock[0] )
            if self.autoclock > 10000:
                self.autoclock = 0
            clock = the_data[58:62]
            self.clock = ( ord( clock[3] ) << 24 ) + ( ord( clock[2] ) << 16 ) + ( ord( clock[1] ) << 8 ) + ord( clock[0] )
            if self.clock > 120000:
                self.clock = 0
            if self.notify.has_key( 'clock' ):
                self.notify['clock']( self.autoclock + self.clock )
        elif len( the_data ) == 50:
            data = (ord( the_data[45:49][3] ) << 24 ) + (ord( the_data[45:49][2] ) << 16 ) + ( ord( the_data[45:49][1] ) << 8 ) + ord( the_data[45:49][0] )
            self.fieldready = bool( data & 0x00008000 )
            self.automode = bool( data & 0x00000100 )
            self.manualmode = bool( data & 0x00080000)
            self.stationenable1 = bool( data & 0x00001000 )
            self.stationenable2 = bool( data & 0x00002000 )
            self.stationenable3 = bool( data & 0x00004000 )
            self.nothere1 = bool( data & 0x00100000 )
            self.nothere2 = bool( data & 0x00200000 )
            self.nothere3 = bool( data & 0x00400000 )
            self.stopactive1 = bool( data & 0x20010000 )
            self.stopactive2 = bool( data & 0x40020000 )
            self.stopactive3 = bool( data & 0x80040000 )
            if self.notify.has_key( 'port10' ):
                self.notify['port10']()

def main():
    gtk.main()

if __name__ == '__main__':
    interface = FieldInterface()
    main()
