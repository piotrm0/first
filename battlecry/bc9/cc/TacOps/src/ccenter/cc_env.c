#include "cc.h"
#include <errno.h>


int	cc_env(buffer_t* out, command_t* cmd, uint8_t argc, char** argv)
{
  unsigned int i;
  connection_t* c;

  if (NULL == argv)
    return EFAULT;
  if (argc <= 1)
  {
    if (NULL == vars || NULL == vars->keys || NULL == vars->values ||
        vars->count < 1)
    {
      buf_appendf(out, "No scalar variables defined\n");
      return ENONE;
    }
    for (i = 0; i < vars->count; i++)
      output_var(out, vars->keys[i], vars->values[i]);
    return ENONE;
  }
  c = connect_findbybuffer(out);
  if (NULL == c)
    return EDOOFUS;
  for (i = 1; i < argc; i++)
  {
    char* equals,* var = NULL;
    const char* name = argv[i],* value;
    notify_t* n;

    if (NULL != (equals = strchr(name, '=')))
    {
      var = strdup(name);
      if (NULL == var)
	continue;
      equals += var - name;
      *equals++ = '\0';
      name = var;
      if (!var_validname(name))
      {
	buf_append(out,
		"ERR: variable name contains illegal chars, ignoring\n");
	goto free_var;
      }
      server_varset(name, equals);
      /* HACK: discard duplicate output if notified */
      n = notify_get(c, NOTIFY_VAR, name);
      if (NULL != n && NULL == n->preferred_name)
	n->activate = 0;
    }
    if (NULL != (value = var_get(vars, name)))
      output_var(out, name, value);
free_var:
    if (NULL != equals)
      free(var);
  }
  return ENONE;
}
