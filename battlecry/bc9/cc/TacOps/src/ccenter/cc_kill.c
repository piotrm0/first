#include "cc.h"
#include <errno.h>


int	cc_kill(buffer_t* out, command_t* cmd, uint8_t argc, char** argv)
{
  connection_t* c;
  unsigned int session_id;
  char* endp = NULL;

  if (NULL == argv)
    return EFAULT;
  if (argc != 2)
    return EUSAGE;
  errno = 0;
  session_id = strtol(argv[1], &endp, 0);
  if (errno || NULL == endp || '\0' != *endp)
    return EUSAGE;
  c = connect_findbybuffer(out);
  if (NULL == c)
    return EDOOFUS;
  if (!c->info.has_admin)
    return EACCES;
  c = connect_findbyid(session_id);
  if (NULL == c)
    return ENOSESSION;
  connect_free(c);
  return ENONE;
}
