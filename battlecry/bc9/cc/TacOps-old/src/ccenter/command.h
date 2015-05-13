#ifndef __COMMAND_H__
#define __COMMAND_H__

#include <kiwi/errno.h>
#include <kiwi/types.h>
#include <buffer.h>
#include <stdlib.h>
#include <sysexits.h>


struct command_s;
typedef int (*command_fn)(buffer_t* out, struct command_s* cmd,
			  uint8_t argc, char** argv);
#define COMMAND_FN(fn_name) \
		int fn_name(buffer_t* out, struct command_s* cmd, \
			    uint8_t argc, char** argv)

/*
 *  NOTE: aliases are unique command names whose remaining structure
 *  is empty (NULL pointers).  Hence, the command list must end with
 *  a completely empty structure.  Care must also be taken with order
 *  of commands, particularly if some but not all of brief, usage,
 *  detail, and function are non-NULL!  When searching for the
 *  relevant field, the first non-NULL item will be used.  Thus, all
 *  fields are required (at some point).
 */
typedef struct command_s
{
  char*		name;		/* unique name of command */
  char*		brief;		/* one-line description */
  char*		usage;		/* usage string */
  char*		detail;		/* remaining help on command */
  command_fn	function;	/* handles the command */
  void*		private;	/* application-dependent */
} command_t;


/*
 *  help = display a cmd, its brief, usage, and its detailed
 *  list = display all commands followed by brief descriptions
 *  usage = display just one command and its usage
 */
void	command_help(buffer_t* out, const command_t* command);
void	command_list(buffer_t* out, const command_t* commands);
void	command_usage(buffer_t* out, const command_t* command);

/*
 *  split properly handles quotations & un-escaping
 */
uint8_t	command_split(const char* line, char*** argv);
char*	command_sjoin(const char* sep, const char** argv);
void	command_sfree(char*** argv);

enum {
  //	ENONE = 0,	/* no error occurred */
	EIGNORE = -1,	/* don't report the error, just ignore it */
	ENOCMD = -2,	/* command not found */
	ENOSESSION = -3,
	EUSAGE = -EX_USAGE,	/* display command usage */
};
void	command_report_error(buffer_t* out, const command_t* cmd, int error);
command_t* command_find(command_t* commands, const char* argv0);
int	command_do(buffer_t* out, command_t* command,
		   uint8_t argc, char** argv);
int	command_doline(buffer_t* out, command_t* commands,
		       const char* line);

#endif /* __COMMAND_H__ */
