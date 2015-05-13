#include "cc.h"

int	cc_send(buffer_t* out, command_t* cmd, uint8_t argc, char** argv)
{
  unsigned int session_id = 0;
  connection_t* c,* my_c;
  const char* nickname = NULL;
  char* endp = NULL,* msg;

  if (NULL == argv)
    return EFAULT;
  if (argc < 3)
    return EUSAGE;
  if (strcmp(argv[1], "-a"))
  {
    errno = 0;
    session_id = strtol(argv[1], &endp, 0);
    if (!session_id || errno || NULL == endp || '\0' != *endp)
    {
      nickname = argv[1];
      session_id = 0;
    }
  }
  my_c = connect_findbybuffer(out);
  if (NULL == my_c)
    return EDOOFUS;
  if (!my_c->info.has_admin)
    return EACCES;
  argv += 2;
  msg = command_sjoin(" ", (const char**)argv);
  if (NULL == msg)
    return errno;

  for (c = connections; NULL != c; c = c->next)
  {
    if (session_id && c->info.connection_id != session_id)
      continue;
    if (NULL != nickname)
      if (NULL == c->info.nickname || strcmp(nickname, c->info.nickname))
	continue;
    if (!session_id && c == my_c)
      continue;		/* don't send to self, unless explicitly */
    if (session_id)
      session_id = 0;	/* mark as sent */
    buf_appendf(c->out, "%s\n", msg);
  }
  if (session_id)
    return ENOSESSION;
  return ENONE;
}
