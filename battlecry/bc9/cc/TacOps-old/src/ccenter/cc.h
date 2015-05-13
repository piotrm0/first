#ifndef __CC_H__
#define __CC_H__

// Command Center

#include <kiwi/errno.h>
#include <kiwi/types.h>
#include <kiwi/network.h>
#include "command.h"
#include "connection.h"

#define TACOPS_VERSION	"3.0-pre"

extern command_t cc_commands[];		/* all, including admin */
extern command_t* cc_std_cmds;		/* only non-admin cmds */


COMMAND_FN(cc_db);
COMMAND_FN(cc_env);
COMMAND_FN(cc_exit);
COMMAND_FN(cc_help);
COMMAND_FN(cc_history);
COMMAND_FN(cc_kill);
COMMAND_FN(cc_nick);
COMMAND_FN(cc_notify);
COMMAND_FN(cc_ping);
COMMAND_FN(cc_send);
COMMAND_FN(cc_stat);
COMMAND_FN(cc_su);
COMMAND_FN(cc_sys);
COMMAND_FN(cc_version);
COMMAND_FN(cc_who);


extern socket_t		_listen_sock;
extern varset_t*	vars;
extern rset_t*		rsetpool_ready;
extern rset_t*		rsetpool_pending;
extern db_connection*	db_notification;
extern buffer_t*	db_notify_queries;


const char* connect_idmodifier(connection_t* c);
const char* canonical_bytes(uint64_t bytes);
const char* timeval2datestr(const struct timeval* tv);
const char* timeval2millis(const struct timeval* tv);
const char* timeval2minutes(const struct timeval* tv);
void	server_listen4rset(const char* rset_name);
void	server_varset(const char* key, const char* value);
void	output_rset(buffer_t* out, const char* prefix,
		    const char* name, const rset_t* rset);
void	output_var(buffer_t* out, const char* key, const char* value);

#endif /* __CC_H__ */
