#include "cc.h"
#include <errno.h>


char SQL_BRIEF[] = "(SQL passthrough)";

#define CC_NUM_ADMIN_COMMANDS	5
command_t cc_commands[] =
{
  /* super-user only */
  { "", "Super-User (only) commands:" },
  { "kick" },
  { "kill", "forcibly disconnect a client",
    "<session_id>",
    "Terminate the connection of a client, specified by its session id."
    "  Session ids can be listed using the \"ls\" command.",
    cc_kill
  },
  { "send", "send message to a client or clients",
    "<-a | session_id | nickname> <msg ...>",
    "Send a message to a single client (if session_id is specified) or "
    "to multiple clients (if a nickname is specified) or everyone (if "
    "\"-a\" is specified).  Care should be used with this option, as a "
    "client will interpret this message as feedback from the server.  "
    "So the message could pretend to be a response from the server (a "
    "bad use of this option) or to send specific commands to a client "
    "(assuming only the specified clients understand the message).  For "
    "this reason, it is recommended that the message contain a special "
    "form compatible with the rest of CommandCenter's responses.",
    cc_send
  },
  { "db", "display system-wide diagnostics",
    "",
    "Used for debugging purposes only.",
    cc_sys
  },

  /* database commands, available to everyone */
  { "", "Database commands:" },		/* spacer */
  { "begin" },
  { "BEGIN", SQL_BRIEF },
  { "end" },
  { "END" },
  { "commit" },
  { "COMMIT", SQL_BRIEF },
  { "delete" },
  { "DELETE", SQL_BRIEF },
  { "insert" },
  { "INSERT", SQL_BRIEF },
  { "rollback" },
  { "ROLLBACK", SQL_BRIEF },
  { "update" },
  { "UPDATE", SQL_BRIEF },
  { "select" },
  { "SELECT", SQL_BRIEF,
    "...",
    "The Command Center passes a number of commands directly as SQL to "
    "the database back-end.  Because of this pass-through, the command "
    "parser doesn't validate the query.  For correct operation:  use "
    "proper SQL and make sure multi-line queries use the proper command "
    "line termination (a sentinal backslash on each preceeding line).  "
    "Remember to wrap string values inside single-quotes..  to escape "
    "the single quotes themselves, either put two single-quotes back to "
    "back or preceed with a backslash.  "
    "Only the following SQL statements are valid:\n\n"
    "\tBEGIN, COMMIT, ROLLBACK - for transactions\n"
    "\tDELETE, INSERT, UPDATE  - for data alteration\n"
    "\tSELECT",
    cc_db
  },

  /* available to everyone, some have special super-user variants */
  { "", "Command Center commands:" },
  { "environ" },
  { "ENV" },
  { "env", "get or set scalar variables in environment",
    "[name=value | name ...]",
    "The Command Center maintains a global set of scalar variables.  Any"
    " of these can be set or queried by any client/session.  If used "
    "without arguments, a complete list of variables and their values "
    "are shown.  Otherwise show only the specified variables (by name). "
    "If an argument contains \"=\", the variable is first set to the "
    "value specified before the variable is shown.\n\n"
    "Also see the \"notify\" command.",
    cc_env
  },
  { "disconnect" },
  { "logout" },
  { "logoff" },
  { "QUIT" },
  { "quit" },
  { "EXIT" },
  { "exit", "disconnect from the Command Center",
    "",
    "Log off the Command Center and disconnect.\nWhen run as super-user,"
    " resume operations as previous user.",
    cc_exit
  },
  { "man" },
  { "HELP" },
  { "help", "list commands and their descriptions",
    "[<command>]",
    "Welcome to the TacOps Command Center server.  This program "
    "processes commands entered by a number of clients.  Commands are a "
    "whitespace-separated list of words.  The first word is the actual "
    "command to perform, the remaining words comprise its arguments.  "
    "To specify a word which includes whitespace, enclose all or part of"
    " the word in double quotes, inside of which the quotes themselves "
    "can be escaped using a backslash.  To allow a command to span "
    "multiple lines, end the line with a backslash followed "
    "immediately by a newline (CR and/or LF, auto-detected).  \n\n"
    "When \"help\" is without the optional argument, show the complete "
    "list of commands available to this user.  If the (optional) command"
    "  name is specified, show the command's usage and complete "
    "description.",
    cc_help
  },
  { "history", "display command history",
    "[-cdrn] [-# | +#] [<session_id>]",
    "Show the recent command history of the specified session (super-"
    "user only) or the current connection (default).  The following "
    "options may be specified:\n\n"
    "-c\tclear the history (super-user only)\n"
    "-d\tinclude datetime stamps\n"
    "-r\tsort in reverse-chronological order\n"
    "-n\tinclude command sequence numbers\n\n"
    "Sequence numbers start with 1, the first command after the client "
    "(re)connects.  There is a limit to the number of history elements "
    "which are saved per-client, so early commands may not be shown.  If"
    " \"-\" or \"+\" are specified before a number, limit the number of "
    "commands shown to that number (for \"-\", show the most recent; for"
    " \"+\", show the earliest).",
    cc_history
  },
  { "ps" },
  { "stat" },
  { "ls", "list session statistics",
    "[-bcflnptv] [-a | <session_id> | <nickname> ... ]",
    "Given the specified session_id(s) (by default, the current "
    "connection only), print out a summary of statistics.  Multiple "
    "nicknames or session_ids can be specified.  "
    "The following options are available:\n"
    "\n-a\tshow all sessions\n"
    "-b\tinclude I/O buffer sizes\n"
    "-c\tinclude command counter (default if no options specified)\n"
    "-f\tinclude all statistics (same as specifying \"-bclnptv\")\n"
    "-l\tlong format, show extra fields\n"
    "-n\tinclude network statistics (bytes transferred)\n"
    "-p\tinclude ping statistics (counters, etc.)\n"
    "-t\tinclude relevant time information\n"
    "-v\tverbose: include all derived statistics\n\n"
    "Verbosity (\"-v\") and time (\"-t\") augments the the \"-l\" and "
    "\"-p\" statistics only.  Also see the \"who\" command.",
    cc_stat,
  },
  { "nickname" },
  { "name" },
  { "NICK" },
  { "nick", "specify identity / nickname",
    "[<name> [<sequence>]]",
    "When used without options, display current nickname.  Otherwise, "
    "specify identity and (optionally) a sequence number.  For clients "
    "with a known/fixed name, subsequent reconnects (due to connection "
    "difficulties, disconnects, or otherwise failures) should increment "
    "their sequence number, so that the number of disconnects can be "
    "queried and tracked.",
    cc_nick
  },
  { "PING" },
  { "ping", "determine session(s) response time(s)",
    "[-a | <session_id>... ]",
    "Not to be confused with the ICMP \"ping\", this command displays "
    "the most recent ping statistics (also see \"ls\") for the specified"
    " session(s).  If \"-a\" is specified instead of session_ids, all "
    " non-interactive sessions are shown.  This command also triggers "
    "the sending of a new ping to each of these sessions, for future "
    "data collection.  Interactive sessions are not probed because it "
    "is expected that there is no auto-response handler and thus the "
    "lag time is useless.  A session is assumed to be interactive if "
    "there is a valid response to the server's initial telnet request "
    "for terminal window size.  Interactive sessions are sent a prompt "
    "and (in future revisions) support command editing.",
    cc_ping
  },
  { "PONG" },
  { "pong", "respond to the server's ping",
    "",
    "This command is not intended for interactive sessions.",
    cc_ping
  },
  { "su", "substitute session identity",
    "[<session_id>]",
    "Without arguments, become super-user.\n[super-user only] Switch to "
    "the specified session.",
    cc_su
  },
  { "vers" },
  { "VERS" },
  { "VERSION" },
  { "version", "query the Command Center's version",
    "",
    "Show the complete version information for the Command Center.",
    cc_version
  },
  { "trigger" },
  { "WATCH" },
  { "watch" },
  { "notify", "setup data notifications",
    "[<session_id>] [on | off] [<data_source> [as <alias_name>]]\n"
    "where <data_source> is \"[env | rset] <name>\".\n",
    "A data_source can be either a server-wide variable (\"env\", see "
    "the \"env\" command for more details) or a result set (\"rset\").  "
    "Result sets are tabular, like database tables or views.  Its name "
    "is the same name specified to the SQL command \"NOTIFY\".  Please "
    "note that the notification of database tables and views use the "
    "SQL commands \"LISTEN\" and \"NOTIFY\", so ensure against namespace "
    "collisions when using the third form of data_sources.\n\n"
    "If used without arguments, a complete list of data sources being "
    "watched is shown.  If \"off\" is used, the specified data source "
    "is disabled from notifications to this session.  If neither are "
    "used, \"on\" is assumed (except when session_id is specified, then "
    "this argument is required-- NOTE: only a super-user can specify the "
    "session_id).  When enabling notifications, only one data_source can "
    "be specified per command.  When disabling, multiple data_sources "
    "can be specified and the data type (\"env\" or \"rset\") is "
    "required-- NOTE: specifying \"off\" without a list of data_sources "
    "will disable all notifications for this session!!  The \"as\" form "
    "is applicable only when enabling a notification; the resulting "
    "notification will use this alias_name instead of the data_source "
    "name-- use of this form is highly discouraged.\n\n"
    "Notifications happen asynchronously within the server, but they are "
    "serialized out to each client/session individually.  Sessions will "
    "be notified only when idle; notifications will pile up if the "
    "session has pending commands to process.  When a notification takes "
    "place, only one notification for each data_source will be sent to "
    "each client; this notice will include only the most recent value of "
    "the data_source.  If you need to be notified for each change in the "
    "value of a data_source, make sure you limit the time spent sending "
    "commands and that you fully consume all input as quickly as "
    "possible.",
    cc_notify,
  },
  { "w", "alias for \"who -fc\"" },
  { "who", "show a list of who is connected",
    "[-fr] [-c | -t] [-d | -i] [<nickname>]",
    "Show a list of all active sessions (connected clients).  Options "
    "include:\n\n"
    "-c\tshow current command and idle time\n"
    "-d\tsort by LOGIN date instead of session id\n"
    "-f\tinclude FROM field (remote address)\n"
    "-i\tsort by idle time instead of session id\n"
    "-r\tshow sessions in reverse-sorted order\n"
    "-t\tshow terminal information\n\n"
    "If the nickname is specified, only show sessions with that nick."
    "  This command only shows connection information."
    "  For command history, see \"history\"."
    "  For session statistics, see \"ls\"."
    "  For a list of watched resources, see \"notify\" (super-user only).",
    cc_who
  },
  {}
};
command_t* cc_std_cmds = cc_commands + CC_NUM_ADMIN_COMMANDS + 1;


/*
 *  NOTES about command processing
 *
 *  We don't check for NULL buffer because someone could call a command
 *  directly; passing NULL is equivalent to /dev/null.  We don't check
 *  for NULL command unless it's needed by the command.  The same goes
 *  for argv (although a NULL argv should not be possible).
 *
 *  Don't assume the command name is case-sensative.
 */
