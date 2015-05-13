import sys

debug = 0
print_disable = {}

def d_print(type, string):
    if (debug and
        (not print_disable.has_key(type) or (not print_disable[type]))):
        frame = sys._getframe(1)
        print("[%s:%s] %s" % (frame.f_code.co_name, frame.f_lineno, string))
