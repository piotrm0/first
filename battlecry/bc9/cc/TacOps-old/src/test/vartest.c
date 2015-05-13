#include <var.h>
#include <stdio.h>
#include <string.h>


varset_t*	vars = NULL;

void	dump_var(const char* key, const char* value)
{
  printf("%s=%s\n", key, value);
  fflush(stdout);
}
void	dump_vars(void)
{
  uint16_t i;

  if (NULL == vars || NULL == vars->keys || NULL == vars->values)
    return;
  for (i = 0; i < vars->count; i++)
    dump_var(vars->keys[i], vars->values[i]);
}


int	main(void)
{
  char buffer[1024];

  vars = var_new();
  while (NULL != fgets(buffer, 1024, stdin))
  {
    char c;
    int len;
    char* equals = strchr(buffer, '=');

    for (len = strlen(buffer); len > 0; len--)
    {
      c = buffer[len - 1];
      if ('\n' != c && '\r' != c)
	break;
      buffer[len - 1] = '\0';
    }
    if (len)
    {
      if (NULL == equals)
      {
	const char* val = var_get(vars, buffer);
	dump_var(buffer, val);
	continue;
      }
      *equals++ = '\0';
      var_set(vars, buffer, equals);
    }
    dump_vars();
  }
  var_free(vars);
  return 0;
}
