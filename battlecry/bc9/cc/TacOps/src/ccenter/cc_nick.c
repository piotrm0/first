#include "cc.h"
#include <errno.h>


int	cc_nick(buffer_t* out, command_t* cmd, uint8_t argc, char** argv)
{
  connection_t* c;
  int seq;
  char* endp = NULL;

  if (NULL == argv)
    return EFAULT;
  if (argc > 3)
    return EUSAGE;
  c = connect_findbybuffer(out);
  if (NULL == c)
    return EDOOFUS;
  if (argc > 2)
  {
    errno = 0;
    seq = strtol(argv[2], &endp, 0);
    if (errno || NULL == endp || '\0' != *endp)
      return EUSAGE;
    c->info.connection_sequence = seq;
  }
  if (argc > 1)
  {
    if (NULL != strchr(argv[1], '\t'))
    {
      buf_appendf(out, "ERR: nickname cannot contain a tab character\n");
      return EIGNORE;
    }
    c->info.nickname = strdup(argv[1]);
  }
  buf_appendf(out, "NICK %s %d\n",
	      NULL == c->info.nickname ? "NULL" : c->info.nickname,
	      c->info.connection_sequence);
  return ENONE;
}
