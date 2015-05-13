#include "cc.h"


int	cc_version(buffer_t* out, command_t* cmd, uint8_t argc, char** argv)
{
  if (argc > 1)
    return EUSAGE;
  buf_appendf(out, "VERSION: %s TacOps Command Center\n", TACOPS_VERSION);
  return ENONE;
}
