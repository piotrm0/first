/*
 *	db.h - generic database interface & routines
 *	Project:	TacOps, FIRST scoring, etc. software
 *	Authors:	Rick C. Petty
 *
 * Copyright (C) 1993-2004 KIWI Computer.  All rights reserved.
 *
 * Please read the enclosed COPYRIGHT notice and LICENSE agreements, if
 * available.  All software and documentation in this file is protected
 * under applicable law as stated in the aforementioned files.  If not
 * included with this distribution, you can obtain these files, this
 * package, and source code for this and related projects from:
 *
 * http://www.kiwi-computer.com/
 *
 * $Id: db.h,v 1.2 2004/03/25 21:20:00 rick Exp $
 */

#ifndef __DB_H__
#define __DB_H__

#include <libpq-fe.h>
#include <sys/select.h>
#include <kiwi/types.h>
#include <rset.h>

//#define	DATABASE	"TacOps"
#define	DATABASE	"tacops"
#define DB_USERNAME	DATABASE
#define DB_PASSWORD	DATABASE
#define DB_DATABASE	DATABASE

#define DB_MAXIMUM_CONNECT	16
#define DB_INITIAL_CONNECT	4
#define DB_INITIALIZE_TIMEOUT	2	// in seconds

extern uint8_t db_max_connections;


enum {	/* Connection States */
	DB_CONN_CONNECT_SEND,	// establishing connection, sending
	DB_CONN_CONNECT_RECV,	// establishing connection, receiving
	DB_CONN_RECONN_SEND,	// reestablishing connection
	DB_CONN_RECONN_RECV,
	DB_CONN_AVAILABLE,	// ready & in waiting pool
	DB_CONN_QUERY_READY,	// ready for another query command
	DB_CONN_QUERY_SEND,	// query being sent
	DB_CONN_QUERY_RECV,	// results being received
	DB_CONN_QUERY_RESULT,	// result ready & loaded, maybe more results

	DB_CONN_NUM_STATES
};
typedef struct db_connection_s
{
  // internal use only:
  struct db_connection_s* next; 

  unsigned int connection_state : 4;
  unsigned int in_use : 1;		// pulled out of waiting pool
  unsigned int has_result : 1;		// result arrived and is valid
  unsigned int in_transaction : 1;
  unsigned int num_cols, num_rows;
  char* error_msg;		// last error message

  // internal use only:
  PGconn* connection;
  PGresult* result;
} db_connection;


int	db_init(void);
int	db_free(void);

void	db_fd_set(int* nfds, fd_set* readfds, fd_set* writefds);
void	db_pollfds(int nfds, fd_set* readfds, fd_set* writefds);
void	db_pollfd(int fd);
void	db_pollall(void);
void	db_poll(db_connection* conn);

int	_db_new_connection(void);
void	_db_reconnect(db_connection* conn);
int	_db_drop_connection(db_connection* conn);
db_connection*	db_connect(void);
void	db_release(db_connection* conn);
void	_db_set_errormsg(db_connection* conn, const char* msg);
void	_db_set_error(db_connection* conn);
int	db_isready(db_connection* conn);

char*	db_strescape(const char* str);
int	db_query(db_connection* conn, const char* cmd);
char*	db_getfield(db_connection* conn, unsigned int column);
char*	db_getvalue(db_connection* conn, unsigned int row, unsigned int col);
rset_t*	db_make_rset(db_connection* conn, const char* name);
int	db_fill_rset(db_connection* conn, rset_t* rset);
int	db_nextresult(db_connection* conn);
void	_db_drop_result(db_connection* conn);

char*	db_notified(db_connection* conn);

#endif /* __DB_H__ */
