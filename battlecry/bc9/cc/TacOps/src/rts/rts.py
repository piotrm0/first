#!/usr/bin/env python

import gobject
import sys
import select
import cc_client
from hosts import *

import debug_util; debug_util.debug = 1

def on_state(key, old_value, value):
    if value == 'running' and old_value == 'paused':
        serial.write('E\n')
    elif value == 'reset' and old_value != 'reset':
        serial.write('C\n')
	serial.write('Q\n')

serial = open('/dev/cuad0', 'r+')
cc = cc_client.cc_client('rts')
cc.connect(HOST_CCENTER)
cc.env_watch('match_state', on_state)

while True:
    reads = [serial, cc.net.sock]
    writes = []

    if cc.net.need_write():
        writes.append(cc.net.sock)

    (can_read, can_write, other) = select.select(reads, writes, [])

    for handle in can_read:
        if handle == serial:
            line = serial.readline().strip()
            if line == '':
                continue
            stuff = line.split('=')
            if stuff[0] == 'bn':
                stuff[0] = 'blue_near'
            if stuff[0] == 'bc':
                stuff[0] = 'blue_center'
            if stuff[0] == 'bf':
                stuff[0] = 'blue_far'
            if stuff[0] == 'rn':
                stuff[0] = 'red_near'
            if stuff[0] == 'rc':
                stuff[0] = 'red_center'
            if stuff[0] == 'rf':
                stuff[0] = 'red_far'
            if stuff[0] == 'as':
                stuff[0] = 'all_submitted'
		serial.write('Q\n')
            if len(stuff) == 2:
                command = ''.join(['ENV ', stuff[0], '=', stuff[1]])
                cc.command(command)
        elif handle == cc.net.sock:
            cc.net.sock_recv()

    for handle in can_write:
        if handle == cc.net.sock:
            cc.net.sock_send()

serial.close()
