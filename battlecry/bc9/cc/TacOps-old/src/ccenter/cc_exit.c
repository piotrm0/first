#include "cc.h"

int	cc_exit(buffer_t* out, command_t* cmd, uint8_t argc, char** argv)
{
  connection_t* c;

  if (argc > 1)
    return EUSAGE;
  c = connect_findbybuffer(out);
  if (NULL == c)
    return EDOOFUS;
  if (!c->info.has_admin)
  {
    c->info.will_disconnect = 1;
    return ENONE;
  }
  c->info.has_admin = 0;
  return ENONE;
}
