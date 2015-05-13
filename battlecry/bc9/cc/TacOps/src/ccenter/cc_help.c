#include "cc.h"
#include <errno.h>


int	cc_help(buffer_t* out, command_t* cmd, uint8_t argc, char** argv)
{
  connection_t* c;

  if (NULL == argv)
    return EFAULT;
  if (argc > 2)
    return EUSAGE; 
  /* determine command set */
  c = connect_findbybuffer(out);

  if (NULL == c)
    return EDOOFUS;
  cmd = c->info.has_admin ? cc_commands : cc_std_cmds;
  if (argc < 2)
  {
    command_list(out, cmd);
    return ENONE;
  }
  cmd = command_find(cmd, argv[1]);
  if (NULL == cmd)
    return ENOCMD;
  command_help(out, cmd);
  return ENONE;
}
