#include "command.h"
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


void	command_help(buffer_t* out, const command_t* command)
{
  unsigned int cmd_len;
  win_fmt_params_t win_fmt = {};

  if (NULL == out || NULL == command)
    return;
  /* translate alias into real command */
  while (NULL != command->name)
  {
    if (NULL != command->brief && NULL != command->usage &&
	NULL != command->detail)
      break;
    command++;
  }
  if (NULL == command->name)
    return;

  cmd_len = strlen(command->name);
  win_fmt.min_width = 40;	/* give detail extra room */
  win_fmt.lmargin = 4;
  win_fmt.rmargin = 4;
  win_fmt.indent = 4 + cmd_len + 4;
  buf_appendf_wrap(out, &win_fmt, "%s -- %s\n\n",
		   command->name, command->brief);
  win_fmt.lmargin = 0;
  win_fmt.rmargin = 2;
  win_fmt.indent = 12;
  buf_appendf_wrap(out, &win_fmt, "Usage:\t%s %s\n",
		   command->name, command->usage);
  win_fmt.lmargin = 4;
  win_fmt.indent = 4;
  buf_appendf_wrap(out, &win_fmt, "\n%s\n\n", command->detail);
}
void	command_list(buffer_t* out, const command_t* commands)
{
  unsigned int i, max_cmd_width = 0, width;
  win_fmt_params_t win_fmt = {};

  if (NULL == out || NULL == commands)
    return;
  /* determine maximum command width */
  for (i = 0; NULL != commands[i].name; i++)
    if ((width = strlen(commands[i].name)) > max_cmd_width)
      max_cmd_width = width;
  buf_appendf_wrap(out, NULL, "\nAvailable commands are as follows:\n\n");
  win_fmt.min_width = 40;	/* matched with help */
  win_fmt.lmargin = 4;
  win_fmt.rmargin = 4;
  win_fmt.indent = 4 + max_cmd_width + 3;
  for (i = 0; NULL != commands[i].name; i++)
  {
    if (NULL == commands[i].brief)
      continue;
    width = strlen(commands[i].name);
    if (!width)
    {
      buf_appendf_wrap(out, &win_fmt, "\n%s\n\n", commands[i].brief);
      continue;
    }
    buf_appendf_wrap(out, &win_fmt, "%s%*.*s - %s\n", commands[i].name,
		     max_cmd_width - width + 1, max_cmd_width - width + 1,
		     "", commands[i].brief);
  }
  buf_append_eol(out);
}
void	command_usage(buffer_t* out, const command_t* command)
{
  win_fmt_params_t win_fmt = {};

  if (NULL == out || NULL == command)
    return;
  /* translate alias into real command */
  while (NULL != command->name)
  {
    if (NULL != command->usage)
      break;
    command++;
  }
  if (NULL == command->name)
    return;

  win_fmt.lmargin = 0;
  win_fmt.rmargin = 2;
  win_fmt.indent = 12;
  buf_appendf_wrap(out, &win_fmt, "Usage:\t%s %s\n",
		   command->name, command->usage);
}


uint8_t	command_split(const char* line, char*** argv)
{
  uint8_t argc = 0;
  char** new_argv,* arg,* inp,* linedup, quote = 0, c;

  if (NULL == line || NULL == argv)
  {
    errno = EFAULT;
    return 0;
  }
  *argv = NULL;
  if (NULL == (linedup = strdup(line)))
    return 0;
  if (NULL == (*argv = (char**)malloc(sizeof(char*))))
  {
    free(linedup);
    return 0;
  }
  **argv = NULL;	/* always NULL-terminate this list */

  arg = inp = linedup;
  do
  {
    c = *inp++;
    if (quote)
    {
      if ('\0' == c)
	continue;	/* will trigger a parse error */
      if (c == quote)
      {
	/* end quote */
	quote = 0;
	continue;
      }
      if ('\\' == c)
      {
	/* escape sequence */
	c = *inp++;
	if ('\0' == c)
	  continue;	/* i.e. parse error */
      }
      // should we let \r and \n cause a parse error here?
      *arg++ = c;
      continue;
    }
    /* not within a quote, regular parsing resumed */
    if ('\\' == c)
    {
      c = *inp++;
      if ('\0' == c)
	goto parse_error;
    }
    switch (c)
    {
#if 0	// for SQL
    case '\'':
#endif
    case '"':
      quote = c;
      break;
    default:
      *arg++ = c;
      break;
    case ' ':
    case '\t':
    case '\0':
    // these either belong here or should be first translated into '\0'
    case '\n':
    case '\r':
      *arg = '\0';
      if (arg == linedup)
	break;	/* consume multiple sequential delimiters */
      if (NULL == (new_argv = realloc(*argv, (++argc + 1) * sizeof(char*)))
	  || NULL == (new_argv[argc - 1] = strdup(linedup)))
      {
	command_sfree(argv);
	free(linedup);
	return 0;
      }
      *argv = new_argv;
      new_argv[argc] = NULL;	/* always NULL-terminate the list, too */
      arg = linedup;
      break;
    }
  } while ('\0' != c);
  if (quote)
    goto parse_error;
  free(linedup);
  errno = 0;
  return argc;

parse_error:
  command_sfree(argv);
  free(linedup);
  errno = EILSEQ;
  return 0;
}
char*	command_sjoin(const char* sep, const char** argv)
{
  const char** args,* ip;
  char* str,* op;
  unsigned int len = 0, slen;

  if (NULL == sep || NULL == argv)
  {
    errno = EFAULT;
    return NULL;
  }
  slen = strlen(sep);
  for (args = argv; NULL != *args; args++)
  {
    if (args != argv)
      len += slen;
    len += strlen(*args);
  }
  if (NULL == (str = malloc(len + 1)))
    return NULL;
  op = str;
  for (args = argv; NULL != *args; args++)
  {
    if (args != argv)
      for (ip = sep; '\0' != *ip; )
	*op++ = *ip++;
    for (ip = *args; '\0' != *ip; )
      *op++ = *ip++;
  }
  *op = '\0';
  return str;
}
void	command_sfree(char*** argv)
{
  char** argvs;

  if (NULL == argv)
    return;
  argvs = *argv;
  while (NULL != *argvs)
  {
    free(*argvs);
    argvs++;
  }
  free(*argv);
  *argv = NULL;
}


void	command_report_error(buffer_t* out, const command_t* cmd, int error)
{
  int do_eol = 1;

  if (NULL == out || NULL == cmd)
    return;
  switch (error)
  {
  case ENONE:
    buf_append(out, "OK");
    break;
  case EIGNORE:
    do_eol = 0;
    break;
  case ENOCMD:
    buf_appendf(out, "ERR: No such command");
    break;
  case ENOSESSION:
    buf_appendf(out, "ERR: Session not found");
    break;
  case EUSAGE:
    command_usage(out, cmd);
    do_eol = 0;
    break;
  default:
    buf_appendf(out, "ERR: %s", strerror(error));
    break;
  }
  if (do_eol)
    buf_append_eol(out);
}
command_t* command_find(command_t* commands, const char* argv0)
{
  if (NULL == commands || NULL == argv0)
  {
    errno = EFAULT;
    return NULL;
  }
  while (NULL != commands->name)
  {
    if (!strcmp(commands->name, argv0))
      return commands;
    commands++;
  }
  errno = ENOCMD;
  return NULL;
}
int	command_do(buffer_t* out, command_t* command,
		   uint8_t argc, char** argv)
{
  int error;

  if (NULL == command || NULL == argv)
    return EFAULT;
  /* find real function pointer, not alias */
  while (NULL != command->name && NULL == command->function)
    command++;
  if (NULL == command->name || NULL == command->function)
    return EDOOFUS;
  /* reset getopt(3) variables */
  optind = 1;
  optreset = 1;
  error = command->function(out, command, argc, argv);
  command_report_error(out, command, error);
  return error;
}
int	command_doline(buffer_t* out, command_t* commands,
		       const char* line)
{
  uint8_t argc;
  char** argv = NULL;
  int error;
  command_t* command;

  if (NULL == commands || NULL == line)
    return EFAULT;
  argc = command_split(line, &argv);
  if (NULL == argv)
    return errno;
  if (!argc || NULL == (command = command_find(commands, argv[0])))
  {
    command_sfree(&argv);
    command_report_error(out, commands, ENOCMD);
    return ENOCMD;
  }
  error = command_do(out, command, argc, argv);
  command_sfree(&argv);
  return error;
}
