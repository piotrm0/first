import cc_parser

head = ['c1', 'c2', 'c3']

temp_row  = cc_parser.rset_row(['v0', 'v1', 'v2'], head)
temp_row2 = cc_parser.rset_row(['v0b', 'v1b', 'v2b'], head)
temp_rset = cc_parser.rset(name="some_row", cc=None)

temp_rset.set_data(head, [temp_row] * 10)

# examples

print temp_rset[5]                                   # get row indexed 5
print temp_rset[5].index_by_name['c1']               # gets the index of the column labeled 'c1' in that row
print temp_rset[5]['c1']                             # get value in column labaled 'c1' in that row
print temp_rset[5][temp_rset[5].index_by_name['c1']] # same as above
print temp_rset[5][2]                                # get the value index by 2 in that row

for val in temp_row:  # iterate through row elements
    print val

print temp_rset       # print a string representation of the rset
print str(temp_rset)  # same as above but allows you to get the string representation

print temp_row        # print a string representation of the row
print str(temp_row)   # same as above but allows you to get the string representation

for row in temp_rset: # iterate through rows
    print row

temp_rset[3] = temp_row2 # change row indexed by 3

del temp_rset[2:4]       # delete rows indexed by 2,3

class Exn:
    def __init__(self, **kw):
        self.kw = kw
    def __getattr__(self, key):
        return self.kw[key]
    def __repr__(self):
        return self.__str__();
    def __str__(self):
        return self.kw.__str__()

try:
    raise Exn(code=42,msg='this is a message')
except Exn, exn:
    print "caught %s" % (exn)

try:
    raise Exception(42, "this is a message")
except Exception, (code, message):
    print "caught %s:%s" % (code, message)

try:
    raise Exception("this is a message")
except Exception, (message):
    print "caught %s" % (message)

try:
    raise Exception("this is a message", "this is more stuff", "and some more")
except Exception, values:
    print "caught %s" % (values)

for x in range(10):
    if x % 2: continue
    print x

test = ("1" +
        "2")
print test
print type(test)

def hexcolor(color):
    return ''.join(map(chr, color)).encode("hex_codec")

print hexcolor((1,2,255))

