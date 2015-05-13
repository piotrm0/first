#include "cc.h"
#include <errno.h>


int	cc_su(buffer_t* out, command_t* cmd, uint8_t argc, char** argv)
{
  connection_t* c;

  if (NULL == argv)
    return EFAULT;
  if (argc > 2)
    return EUSAGE;
  c = connect_findbybuffer(out);
  if (NULL == c)
    return EDOOFUS;
  if (argc > 1)
  {
    if (!c->info.has_admin)
      return EACCES;
    // TODO
    return ENOSYS;
  }
  if (c->info.has_admin)
  {
    buf_append(out, "IGNORED: You are already a super-user\n");
    return EIGNORE;
  }
  // TODO: check password
  c->info.has_admin = 1;
  return ENONE;
}
