import time

FILE = '/usr/share/dict/words'

time_begin = time.time()

fh = open(FILE, "r")

words = []

num_words = 0
num_chars = 0

for line in fh:
    line = line.rstrip()
    l = len(line)
    if (l <= 3):
        continue
    if (line < 'a'):
        continue
    words.append(line)
    num_words += 1
    num_chars += l

print "loaded %d words, %d chars" % (num_words, num_chars)

smash = " ".join(words)

time_end = time.time()

print "initializiation complete, took %f" % (time_end - time_begin)
