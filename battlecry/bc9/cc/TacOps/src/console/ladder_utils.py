#!/usr/bin/env python

###  Grey Code

def _grey_base(power):
    if power < 1:
	return 1;
    return 3 << (power - 1);

def grey_code(index):
    code = 0;
    power = 0;
    while index > 0:
	if (index & 1):
	    code ^= _grey_base(power);
	index >>= 1;
	power += 1;
    return code;

def grey_find(gcode):
    index = 0;
    while gcode != grey_code(index):
	index += 1;
    return index;


def path_reverse(path, bits):
    reverse = 0;
    bit = 0;
    while bit < bits:
	reverse <<= 1;
	reverse |= path & 1;
	path >>= 1;
	bit += 1;
    return reverse;


def match_lookup(matches, number):
    for match in matches:
	if number == match.match_number:
	    return match;
    return None;
