/*
 *	db.c - generic database interface & routines
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
 * $Id: db.c,v 1.3 2004/04/01 23:18:57 rick Exp $
 */

#include "db.h"
#include <kiwi/errno.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/time.h>
#include <unistd.h>

uint8_t db_num_connections = 0;
uint8_t	db_max_connections = DB_MAXIMUM_CONNECT;

// internal use only:
db_connection*	db_connections = NULL;
uint8_t	db_avail_connections = 0;
const char* DB_CONNECTION_STATES[] =
{
  "connect (w)", "connect (r)", "reconnect (w)", "reconnect (r)",
  "available", "ready", "query (w)", "query (r)", "query result",
};


int	db_init(void)
{
  int i, nfds;
  struct timeval stop, timeout = {};
  fd_set r, w;

  for (i = 0; i < DB_INITIAL_CONNECT; i++)
  {
    int err = _db_new_connection();
    if (err)
    {
      db_free();
      return err;
    }
  }
  if (gettimeofday(&stop, NULL))
  {
    db_free();
    return errno;
  }
  stop.tv_sec += DB_INITIALIZE_TIMEOUT;
  while (!gettimeofday(&timeout, NULL) && timercmp(&timeout, &stop, <))
  {
    timersub(&stop, &timeout, &timeout);
    FD_ZERO(&r);
    FD_ZERO(&w);
    nfds = 0;
    db_fd_set(&nfds, &r, &w);
    i = select(nfds, &r, &w, NULL, &timeout);
    if (0 == i)
      errno = ETIMEDOUT;
    if (i < 1)
      break;
    db_pollall();
    if (db_avail_connections >= DB_INITIAL_CONNECT)
      return 0;
    if (NULL == db_connections)
      return -1;
  }
  db_free();
  return errno;
}
int	db_free(void)
{
  while (NULL != db_connections)
  {
    _db_drop_connection(db_connections);
  }
  return 0;
}


void	db_fd_set(int* nfds, fd_set* readfds, fd_set* writefds)
{
  db_connection* conn;
  int max_id = 0;

  if (NULL == nfds)
    nfds = &max_id;
  else
    max_id = *nfds;

  for (conn = db_connections; NULL != conn; conn = conn->next)
  {
    int fd = -1;

    switch (conn->connection_state)
    {
    case DB_CONN_CONNECT_SEND:
    case DB_CONN_RECONN_SEND:
    case DB_CONN_QUERY_SEND:
      if (NULL == writefds)
	break;
      fd = PQsocket(conn->connection);
      FD_SET(fd, writefds);
      break;
    case DB_CONN_CONNECT_RECV:
    case DB_CONN_RECONN_RECV:
    case DB_CONN_QUERY_RECV:
    case DB_CONN_QUERY_READY:	/* to handle async notifies */
      if (NULL == readfds)
	break;
      fd = PQsocket(conn->connection);
      FD_SET(fd, readfds);
      break;
    }
    if (fd >= 0 && fd + 1 > max_id)
      max_id = fd + 1;
  }
  *nfds = max_id;
}
void	db_pollfds(int nfds, fd_set* readfds, fd_set* writefds)
{
  db_connection* conn;

  for (conn = db_connections; NULL != conn; conn = conn->next)
  {
    int fd = PQsocket(conn->connection);
    if (fd < 0 || (0 && !conn->in_use && conn->connection_state > DB_CONN_AVAILABLE))
    {
      db_poll(conn);
      continue;
    }
    if (FD_ISSET(fd, readfds) || FD_ISSET(fd, writefds))
    {
      db_poll(conn);
      FD_CLR(fd, readfds);
      FD_CLR(fd, writefds);
    }
  }
}
void	db_pollfd(int fd)
{
  db_connection* conn;

  for (conn = db_connections; conn != NULL; conn = conn->next)
  {
    if (fd == PQsocket(conn->connection))
    {
      db_poll(conn);
      return;
    }
  }
}
void	db_pollall(void)
{
  db_connection* conn;

  for (conn = db_connections; conn != NULL; conn = conn->next)
  {
    db_poll(conn);
  }
}
void	db_poll(db_connection* conn)
{
  ConnStatusType conn_status;
  PostgresPollingStatusType poll_status;
  PGTransactionStatusType tran_status;
  int reconnect = 0, ret;
  char* query = "END; UNLISTEN *;";
  char* str;

  if (NULL == conn)
    return;
  switch (conn->connection_state)
  {
  case DB_CONN_RECONN_SEND:
  case DB_CONN_RECONN_RECV:
    reconnect = 1;
  case DB_CONN_CONNECT_SEND:
  case DB_CONN_CONNECT_RECV:
    conn_status = PQstatus(conn->connection);
    if (CONNECTION_BAD == conn_status)
    {
      _db_drop_connection(conn);
      return;
    }
    if (CONNECTION_OK != conn_status)
    {
      poll_status = reconnect ?
	PQresetPoll(conn->connection) : PQconnectPoll(conn->connection);
      switch (poll_status)
      {
      case PGRES_POLLING_FAILED:
	_db_drop_connection(conn);
	return;
      case PGRES_POLLING_OK:
	break;
      case PGRES_POLLING_READING:
	conn->connection_state = reconnect ?
		DB_CONN_RECONN_RECV : DB_CONN_CONNECT_RECV;
	return;
      case PGRES_POLLING_WRITING:
	conn->connection_state = reconnect ?
		DB_CONN_RECONN_SEND : DB_CONN_CONNECT_SEND;
      default:
	return;
      }
    } /* connection established */
    conn->connection_state = DB_CONN_AVAILABLE;
    db_avail_connections++;
  case DB_CONN_AVAILABLE:
    /*
     * NOTE: This only fixes part of the problem.  We also do a
     *   "UNLISTEN *" before we get here.
     */
    while (NULL != (str = db_notified(conn)))
      free(str);
#if 0
    if (conn->is_use)
      // do what?
#endif
    return;
  case DB_CONN_QUERY_READY:
    /* get transaction state */
    tran_status = PQtransactionStatus(conn->connection);
    conn->in_transaction = PQTRANS_IDLE != tran_status;
    if (conn->in_use)
      return;
    _db_drop_result(conn);
    /* act appropriately to transaction state */
    switch (tran_status)
    {
    default:
      _db_set_error(conn);
      _db_reconnect(conn);
      return;
    case PQTRANS_IDLE:
      conn->connection_state = DB_CONN_AVAILABLE;
      db_avail_connections++;
      return;
    case PQTRANS_INERROR:
      query = "ROLLBACK; UNLISTEN *;";
    case PQTRANS_INTRANS:
      if (!PQsendQuery(conn->connection, query))
      {
	_db_set_error(conn);
	_db_reconnect(conn);
	return;
      }
    case PQTRANS_ACTIVE:
      conn->in_transaction = 0;
      conn->connection_state = DB_CONN_QUERY_SEND;
    }
  case DB_CONN_QUERY_SEND:
    ret = PQflush(conn->connection);
    if (ret < 0)
    {
      _db_set_error(conn);
      _db_reconnect(conn);
      return;
    }
    if (ret)
      return;
    conn->connection_state = DB_CONN_QUERY_RECV;
  case DB_CONN_QUERY_RECV:
    ret = PQconsumeInput(conn->connection);
    if (!ret)
    {
      _db_set_error(conn);
      _db_reconnect(conn);
      return;
    }
    ret = PQisBusy(conn->connection);
    if (ret)
      return;
    _db_drop_result(conn);
    conn->result = PQgetResult(conn->connection);
    if (NULL == conn->result)
    {
      conn->connection_state = DB_CONN_QUERY_READY;
      db_poll(conn);	/* recurse to next results */
      return;
    }
    _db_set_errormsg(conn, PQresultErrorMessage(conn->result));
    if (NULL != conn->error_msg)
    {
      conn->has_result = 1;
      conn->connection_state = DB_CONN_QUERY_RESULT;
      db_poll(conn);
      return;
    }

    conn->has_result = 1;
    conn->num_cols = PQnfields(conn->result);
    conn->num_rows = PQntuples(conn->result);
    if (!conn->num_rows && !conn->num_cols)
    {
      str = PQcmdTuples(conn->result);
      if (NULL != str)
	conn->num_rows = atoi(str);
    }
    conn->connection_state = DB_CONN_QUERY_RESULT;
  case DB_CONN_QUERY_RESULT:
    /* get transaction state */
    tran_status = PQtransactionStatus(conn->connection);
    // conn->in_transaction = PQTRANS_IDLE != tran_status;
    if (conn->in_use)
      return;
    conn->connection_state = DB_CONN_QUERY_RECV;
    db_poll(conn);	/* recurse to next results */
    return;
  }
  // NOTE: instead of the recursion, we could encapsulate in a while loop
}


int	_db_new_connection(void)
{
  size_t bytes = sizeof(db_connection);
  db_connection* new;
  char* database,* username,* password;
  char* connstr = NULL;

  if (NULL == (new = malloc(bytes)))
    return errno;
  bzero(new, bytes);
  database = db_strescape(DB_DATABASE);
  username = db_strescape(DB_USERNAME);
  password = db_strescape(DB_PASSWORD);
  if (NULL != database && NULL != username && NULL != password)
    asprintf(&connstr, "dbname='%s'\nuser='%s'\npassword='%s'\n",
	     database, username, password);
  free(database);
  free(username);
  free(password);
  if (NULL != connstr)
    new->connection = PQconnectStart(connstr);
  free(connstr);
  if (NULL == new->connection)
  {
    free(new);
    return errno;
  }
  if (!PQisnonblocking(new->connection))
  {
    if (PQsetnonblocking(new->connection, 1))
    {
	_db_drop_connection(new);
	errno = EOPNOTSUPP;
	return errno;
    }
  }
  new->next = db_connections;
  db_connections = new;
  db_num_connections++;
  return 0;
}
void	_db_reconnect(db_connection* conn)
{
  if (NULL == conn)
    return;
  conn->connection_state = DB_CONN_RECONN_SEND;
  conn->in_use = 0;
  conn->in_transaction = 0;
  _db_drop_result(conn);
  if (!PQresetStart(conn->connection) ||
      !PQsetnonblocking(conn->connection, 1))
  {
    _db_drop_connection(conn);
  }
}
int	_db_drop_connection(db_connection* conn)
{
  db_connection* prev;

  if (NULL == db_connections)
    return EDOOFUS;
  if (NULL == conn)
    return EFAULT;
#ifdef DEBUG
  {
    char* error = PQerrorMessage(conn->connection);
    if (NULL == error || strlen(error) < 1)
      error = "\n";
    fprintf(stderr, "db connection dropped: %s", error);
  }
#endif
  if (conn == db_connections)
    db_connections = conn->next;
  else {
    for (prev = db_connections; NULL != prev->next; prev = prev->next)
    {
      if (conn == prev->next)
      {
	prev->next = conn->next;
	break;
      }
    }
  }
  db_release(conn);	// stop using this pool element
  _db_drop_result(conn);	// erase result, if any
  if (NULL != conn->connection)
    PQfinish(conn->connection);
  bzero(conn, sizeof(*conn));
  db_num_connections--;
  return 0;
}
db_connection*	db_connect(void)
{
  db_connection* conn;

  for (conn = db_connections; NULL != conn; conn = conn->next)
  {
    if (!conn->in_use && DB_CONN_AVAILABLE == conn->connection_state)
    {
      conn->in_use = 1;
      conn->connection_state = DB_CONN_QUERY_READY;
      db_avail_connections--;
      break;
    }
  }
  /* keep plenty of connections on-hand */
  if ((!db_avail_connections || db_avail_connections < DB_INITIAL_CONNECT)
      && db_num_connections < db_max_connections)
    do
    {
      if (_db_new_connection())
	break;	/* to avoid infinite loops */
    } while (db_num_connections < DB_INITIAL_CONNECT);
  return conn;
}
void	db_release(db_connection* conn)
{
  if (NULL == conn)
    return;
  conn->in_use = 0;
  free(conn->error_msg);
  conn->error_msg = NULL;
  _db_drop_result(conn);
  if (DB_CONN_QUERY_RESULT == conn->connection_state)
  {
    conn->connection_state = DB_CONN_QUERY_RECV;
  }
    db_poll(conn);
}
void	_db_set_errormsg(db_connection* conn, const char* msg)
{
  free(conn->error_msg);
  conn->error_msg = NULL;
  if (NULL != msg && strlen(msg) > 0)
    conn->error_msg = strdup(msg);
}
void	_db_set_error(db_connection* conn)
{
  _db_set_errormsg(conn, PQerrorMessage(conn->connection));
}
int	db_isready(db_connection* conn)
{
  return (NULL != conn && conn->in_use &&
	  DB_CONN_QUERY_READY == conn->connection_state);
}


char*	db_strescape(const char* str)
{
  char* ret;
  size_t len;

  if (NULL == str)
    return NULL;
  len = strlen(str);
  if (NULL == (ret = malloc((len << 1) + 1)))
    return NULL;
  len = PQescapeString(ret, str, len);
  ret[len] = '\0';
  return ret;
}
int	db_query(db_connection* conn, const char* cmd)
{
  if (NULL == conn || NULL == cmd)
    return EFAULT;
  if (NULL == conn->connection)
    return EDOOFUS;
  if (!conn->in_use)
    return ENOPROTOOPT;
  if (conn->connection_state < DB_CONN_QUERY_READY)
    return ENOTCONN;
  if (DB_CONN_QUERY_READY != conn->connection_state)
    return EBUSY;
  if (!PQsendQuery(conn->connection, cmd))
  {
    _db_set_error(conn);
    _db_reconnect(conn);
    return -1;
  }
  conn->connection_state = DB_CONN_QUERY_SEND;
  return 0;
}
char*	db_getfield(db_connection* conn, unsigned int column)
{
  char* ret;

  if (NULL == conn)
  {
    errno = EFAULT;
    return NULL;
  }
  if (conn->connection_state < DB_CONN_QUERY_READY)
  {
    errno = ENOTCONN;
    return NULL;
  }
  if (DB_CONN_QUERY_RESULT != conn->connection_state)
  {
    errno = EBUSY;
    return NULL;
  }
  if (column >= conn->num_cols)
  {
    errno = EDOM;
    return NULL;
  }
  ret = PQfname(conn->result, column);
  if (NULL != ret)
    ret = strdup(ret);
  return ret;
}
char*	db_getvalue(db_connection* conn, unsigned int row, unsigned int col)
{
  char* ret;

  if (NULL == conn)
  {
    errno = EFAULT;
    return NULL;
  }
  if (conn->connection_state < DB_CONN_QUERY_READY)
  {
    errno = ENOTCONN;
    return NULL;
  }
  if (DB_CONN_QUERY_RESULT != conn->connection_state)
  {
    errno = EBUSY;
    return NULL;
  }
  if (col > conn->num_cols)
  {
    errno = EDOM;
    return NULL;
  }
  errno = 0;
  if (PQgetisnull(conn->result, row, col))
    return NULL;
  ret = PQgetvalue(conn->result, row, col);
  if (NULL != ret)
    ret = strdup(ret);
  return ret;
}
rset_t*	db_make_rset(db_connection* conn, const char* name)
{
  rset_t* rset;
  unsigned int error;

  rset = rset_new(name, 0, 0);
  if (NULL == rset)
    return NULL;
  error = db_fill_rset(conn, rset);
  if (!error)
    return rset;
  rset_free(rset);
  errno = error;
  return NULL;
}
int	db_fill_rset(db_connection* conn, rset_t* rset)
{
  unsigned int i, j, error;

  if (NULL == conn || NULL == rset)
    return (errno = EFAULT);
  if (conn->connection_state < DB_CONN_QUERY_READY)
    return (errno = ENOTCONN);
  if (DB_CONN_QUERY_RESULT != conn->connection_state)
    return (errno = EBUSY);
  if (conn->num_cols < 1)
    return (errno = EDOM);
  rset_resize(rset, conn->num_cols, conn->num_rows);
  if (NULL == rset->fields || NULL == rset->records ||
      rset->num_fields < conn->num_cols ||
      rset->num_records < conn->num_rows)
  {
    error = errno;
    rset_empty(rset);
    return (errno = error);
  }
  for (i = 0; i < conn->num_cols; i++)
    rset->fields[i] = db_getfield(conn, i);
  for (j = 0; j < conn->num_rows; j++)
    for (i = 0; i < conn->num_cols; i++)
      rset->records[j][i] = db_getvalue(conn, j, i);
  return (errno = 0);
}
int	db_nextresult(db_connection* conn)
{
  if (NULL == conn)
    return EFAULT;
  free(conn->error_msg);
  conn->error_msg = NULL;
  _db_drop_result(conn);
  if (DB_CONN_QUERY_RESULT == conn->connection_state)
  {
    conn->connection_state = DB_CONN_QUERY_RECV;
    db_poll(conn);
  }
  return 0;
}
void	_db_drop_result(db_connection* conn)
{
  if (NULL != conn->result)
  {
    PQclear(conn->result);
    conn->result = NULL;
  }
  conn->has_result = 0;
  conn->num_cols = conn->num_rows = 0;
}


char*	db_notified(db_connection* conn)
{
  PGnotify* note;
  char* str = NULL;

  if (NULL == conn)
  {
    errno = EFAULT;
    return NULL;
  }
  if (NULL == conn->connection)
  {
    errno = ENOTCONN;
    return NULL;
  }
  PQconsumeInput(conn->connection);
  note = PQnotifies(conn->connection);
  errno = 0;
  if (NULL == note)
    return NULL;
  if (NULL != note->relname)
    str = strdup(note->relname);
  PQfreemem(note);
  return str;
}
