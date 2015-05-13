import time
from array import array

FILE = '/usr/share/dict/words'

time_begin = time.time()

fh = open(FILE, "r")

bytes = fh.read()
length = len(bytes)

words = array('c')
src = 0
dst = 0
ln  = 0

num_words = 0
num_chars = 0

while (src < length):
    if ('\n' != bytes[src]):
        src += 1
        ln  += 1
        continue

    if (ln <= 3):
        src += 1
        ln  = 0
        continue

    c = bytes[src-ln]
    if (c < 'a' or c > 'z'):
        src += 1
        ln = 0
        continue

    src -= ln
    for i in range(0, ln):
        # words[dst] = bytes[src]
        words.append(bytes[src])
        # dst += 1
        src += 1

    words.append(' ')
    # words[dst] = ' '
    # dst += 1
    num_chars += ln
    num_words += 1

    src += 1
    ln = 0
    
print "loaded %d words, %d chars" % (num_words, num_chars)

smash = " ".join(words)

time_end = time.time()

print "initializiation complete, took %f" % (time_end - time_begin)
