#include "cc.h"
#include "command.h"
#include "connection.h"
#include <kiwi/string.h>
#include <db.h>
#include <rset.h>
#include <var.h>

#include <arpa/telnet.h>
#include <assert.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/select.h>
#include <sys/time.h>
#include <time.h>


socket_t	_listen_sock = SOCKET_INVALID;
varset_t*	vars = NULL;
rset_t*		rsetpool_ready = NULL;
rset_t*		rsetpool_pending = NULL;
db_connection*	db_notification = NULL;
buffer_t*	db_notify_queries = NULL;
char*		db_pending_name = NULL;


#define	log_exit(error, fmt...) \
		do { \
		  log_msg(error, fmt); \
		  log_msg(0, "Exiting..."); \
		  exit(EXIT_FAILURE); \
		} while(0)
void	log_msg(int error, const char* fmt, ...);
int	main(int argc, const char* argv[]);
void	mexit(void);
void	server(void);
void	process_command(connection_t* c);
int	process_telnet(connection_t* c, unsigned int i);
void	process_notifies(connection_t* c);
void	process_results(connection_t* c);
void	do_notify(const char* msg);
void	process_notify_rset(void);
void	reregister_notifies(void);


void	log_msg(int error, const char* fmt, ...)
{
  va_list ap;

  if (NULL != fmt)
  {
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    if (error)
      fprintf(stderr, ": ");
  }
  if (error)
    fprintf(stderr, "%s", strerror(error));
  fprintf(stderr, "\n");
}
int	main(int argc, const char* argv[])
{
  int error;
  sockaddr_t* addr;
  char* listen_addr = NULL;

  if (argc > 1)
    log_msg(0, "warning: extra arguments specified, ignored");
  if (atexit(mexit))
    log_exit(errno, "Unable to setup atexit()");
  vars = var_new();
  if (NULL == vars)
    log_exit(errno, "Unable to initialize local variables");
  error = db_init();
  if (error)
    log_exit(error, "Unable to connect to database");
  if (NULL == (db_notify_queries = buf_new(0)))
    log_exit(errno, "Unable to setup notify query buffer");
  _listen_sock = network_socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (SOCKET_INVALID == _listen_sock)
    log_exit(errno, "Unable to setup listening socket");
  error = network_ascii2addr("0.0.0.0:7070", &addr);
  if (error)
    log_exit(error, "Unable to setup address for listening socket");
  error = network_bind(_listen_sock, addr);
  if (error)
    log_exit(error, "Unable to bind listening socket");
  if (NULL != addr)
    free(addr);
  error = network_listen(_listen_sock, 2);
  if (error)
    log_exit(error, "Unable to listen on socket");
  network_sockaddr(_listen_sock, &listen_addr);
  log_msg(0, "Command Center listening on %s",
	  NULL == listen_addr ? "<UNKNOWN>" : listen_addr);
  free(listen_addr);

  server();

  return 0;
}
void	mexit(void)
{
  if (SOCKET_INVALID != _listen_sock)
    network_close(_listen_sock);
  _listen_sock = SOCKET_INVALID;
  buf_free(db_notify_queries);
  db_free();
  db_notification = NULL;
  var_free(vars);
}
void	server(void)
{
  int sock_fd, nfds;
  struct timeval tv = { 0, 0 };
  unsigned int i;
  sockaddr_t* sockaddr;
  char* addr,* msg;
  fd_set rfds, wfds;
  connection_t* c,* cp;

  while (1)
  {
    FD_ZERO(&rfds);
    FD_ZERO(&wfds);

    /* collect a list of file descriptors to wait upon */
    sock_fd = _listen_sock;
    FD_SET(sock_fd, &rfds);
    nfds = sock_fd + 1;
    db_fd_set(&nfds, &rfds, &wfds);
    connect_fd_set(&nfds, &rfds, &wfds);

    if (select(nfds, &rfds, &wfds, NULL, timerisset(&tv) ? &tv : NULL) < 0)
    {
      if (EINTR == errno)
	continue;
      log_exit(errno, "Problem in server's select()");
    }
    /* first handle database connections & notifications */
    db_pollfds(nfds, &rfds, &wfds);
    while (NULL != db_notification &&
	   NULL != (msg = db_notified(db_notification)))
    {
      notify_all(NOTIFY_DB, msg);
      do_notify(msg);
      free(msg);
    }
    process_notify_rset();
    if (NULL == db_notification &&
	NULL != (db_notification = db_connect()))
      reregister_notifies();
    for (c = connections; NULL != c; c = c->next)
      if (NULL == c->db)
	process_notifies(c);
      else
	process_results(c);

    /* then handle new connections */
    if (FD_ISSET(sock_fd, &rfds))
    {
      FD_CLR(sock_fd, &rfds);
      sock_fd = network_accept(sock_fd, &sockaddr);
      if (sock_fd < 0)
	log_msg(errno, "WARNING: connection not accepted");
      else
      {
	addr = NULL;
	network_addr2ascii(sockaddr, &addr);
	if (NULL != sockaddr)
	  free(sockaddr);
	if (NULL == connect_new(sock_fd, addr))
	  log_msg(errno, "WARNING: connection forcibly dropped");
	free(addr);
      }
    }

    /* next handle waiting connection streams */
    for (i = 0; i < nfds; i++)
    {
      if (FD_ISSET(i, &wfds))
	connect_flush(i);
      if (FD_ISSET(i, &rfds))
	connect_slurp(i);
    }

    /* finally handle any pending commands */
    for (c = connections; NULL != c; )
      if ((NULL == c->db || c->info.in_transaction) && c->in->len > 0)
      {
	process_command(cp = c);
	if (c->info.will_disconnect)
	{
	  c = c->next;
	  connect_free(cp);
	} else
	  c = c->next;
      } else
	c = c->next;
  } /* loop forever */
}
void	process_command(connection_t* c)
{
  int i = 0, eol_start, eol_stop;
  unsigned char ch;

next_line:
  eol_start = eol_stop = -1;
  for ( ; i < c->in->len; i++)
  {
    ch = c->in->ptr[i];
    while (ch >= 0xFE)
    {
      if (IAC != ch)
	buf_consume(c->in, 1, i);
      else
      if (process_telnet(c, i))
	return;		/* don't process this line */
      if (i >= c->in->len)
	break;
      ch = c->in->ptr[i];
    }
    if (i >= c->in->len)
      break;

    if ('\r' != ch && '\n' != ch && '\0' != ch)
    {
      if (eol_start < 0)
        continue;
      break;
    }
    /* found EOL character, look at sequence */
    if (eol_start < 0)	
    {
      eol_start = i;
      continue;
    }
  }

  /* determine if legitimate command line */
  if (eol_start < 0)
    return;	/* nope, don't consume */
  /* allow multi-line commands */
  if (eol_start > 0 && '\\' == c->in->ptr[eol_start - 1])
    goto next_line;
  if (eol_stop < 0)
    eol_stop = i - 1;

  /* grab & mark EOL sequence */
  i = eol_start;
  if ('\r' == c->in->ptr[i])
  {
    c->terminal.CR = 1;
    i++;
  } else
    c->terminal.CR = 0;
  if (i <= eol_stop && '\n' == c->in->ptr[i])
  {
    c->terminal.LF = 1;
    i++;
  } else
    c->terminal.LF = 0;
  if (i <= eol_stop && '\0' == c->in->ptr[i])
  {
    c->terminal.NUL = 1;
    i++;
  } else
    c->terminal.NUL = 0;
  eol_stop = i;
  c->in->ptr[eol_start] = '\0';

  /* process command */
  if (eol_start > 0)
  {
    make_history(c, (const char*) c->in->ptr);
    command_doline(c->out,
		   c->info.has_admin ? cc_commands : cc_std_cmds,
		   (const char*) c->in->ptr);
  }
  buf_consume(c->in, eol_stop, 0);
}
#define TELNET_NEXTCHAR(c, i) \
		((i) < (c)->in->len ? (c)->in->ptr[(i)++] : -1)
int	process_telnet(connection_t* c, unsigned int i)
{
  unsigned int start = i;
  int ch, width = -1, height = -1;

  if (NULL == c || IAC != (ch = TELNET_NEXTCHAR(c, i)))
    return 0;
  switch (ch = TELNET_NEXTCHAR(c, i))
  {
  case WILL:
    ch = TELNET_NEXTCHAR(c, i);
    if (TELOPT_NAWS == ch)
      c->terminal.interactive = 1;
    break;
  case WONT:
    ch = TELNET_NEXTCHAR(c, i);
    if (TELOPT_NAWS == ch)
    {
      c->terminal.interactive = 0;
      c->terminal.width = c->terminal.height = 0;
    }
    break;
  case DO:
  case DONT:
    /* silently consume argument */
    ch = TELNET_NEXTCHAR(c, i);
    break;
  case AYT:
  case SUSP:
  case IP:
  case BREAK:
    /* just ignore these for now */
  case SE:
  case IAC:
    break;
  case SB:
    if (TELOPT_NAWS == (ch = TELNET_NEXTCHAR(c, i)))
    {
      if (-1 == (ch = TELNET_NEXTCHAR(c, i)) ||
	  (IAC == ch && IAC != TELNET_NEXTCHAR(c, i)))
	goto not_NAWS;
      width = (ch & 0xFF) << 8;
      if (-1 == (ch = TELNET_NEXTCHAR(c, i)) ||
	  (IAC == ch && IAC != TELNET_NEXTCHAR(c, i)))
	goto not_NAWS;
      width |= (ch & 0xFF);
      if (-1 == (ch = TELNET_NEXTCHAR(c, i)) ||
	  (IAC == ch && IAC != TELNET_NEXTCHAR(c, i)))
	goto not_NAWS;
      height = (ch & 0xFF) << 8;
      if (-1 == (ch = TELNET_NEXTCHAR(c, i)) ||
	  (IAC == ch && IAC != TELNET_NEXTCHAR(c, i)))
	goto not_NAWS;
      height |= (ch & 0xFF);
    }
not_NAWS:
    /* skip until "IAC SE" */
    i = start + 2;
    while (-1 != (ch = TELNET_NEXTCHAR(c, i)))
      if (IAC == ch && SE == TELNET_NEXTCHAR(c, i))
	break;
    /* not found, don't destroy "IAC SB"; don't process line either */
    if (-1 == ch)
      return 1;
    /* found, consume the entire subnegotiation */
    if (width >= 0 && height >= 0)
    {
      c->terminal.width = width;
      c->terminal.height = height;
    }
    break;
  }

  buf_consume(c->in, i - start, start);
  return 0;
}


void	process_notifies(connection_t* c)
{
  unsigned int i;
  notify_t* n;
  const char* value;
  rset_t* rset;

  if (NULL == c)
    return;
  /* process a PING first */
  if (c->info.will_ping)
  {
    c->info.will_ping = 0;
    buf_append(c->out, "PING\n");
    c->stats.num_pings_out++;
    gettimeofday(&c->stats.last_ping_out, NULL);
  }
  if (NULL == c->notify_list)
    return;
  for (i = 0, n = c->notify_list; i < c->notify_count; i++, n++)
    if (n->activate)
      switch (n->type)
      {
      case NOTIFY_VAR:
	n->activate = 0;
	value = var_get(vars, n->name);
	if (NULL == value)
	  break;
	n->num_reports++;
	output_var(c->out,
		   NULL == n->preferred_name ? n->name : n->preferred_name,
		   value);
	break;
      case NOTIFY_DB:
	rset = rsetpool_find(&rsetpool_ready, n->name);
	if (NULL == rset)
	  break;	/* not filled yet */
	n->activate = 0;
	if (NULL == rset->fields || NULL == rset->records ||
	    0 == rset->num_fields)
	  break;
	n->num_reports++;
	output_rset(c->out, "NOTICE",
		    NULL == n->preferred_name ? n->name : n->preferred_name,
		    rset);
	break;
      default:
	/* do nothing */
	break;
      }
}
void	process_results(connection_t* c)
{
  rset_t* rset = NULL;
  unsigned int rows, cols;

  if (NULL == c || NULL == c->db)
    return;
  while (c->db->has_result)
  {
    if (!c->db->in_use)
      break;
    rows = cols = 0;
    if (NULL != c->db->error_msg)
    {
      buf_appendf(c->out, "SQL %s", c->db->error_msg);
      db_nextresult(c->db);
      continue;
    }
    rows = c->db->num_rows;
    cols = c->db->num_cols;
    if (cols)
      rset = db_make_rset(c->db, NULL);
    db_nextresult(c->db);
    if (!cols)
    {
      if (c->db->in_transaction == c->info.in_transaction)
	buf_appendf(c->out, "QUERY affected %d rows\n", cols);
      else
      if (c->db->in_transaction)
	buf_appendf(c->out, "TRAN BEGIN\n");
      else
	buf_appendf(c->out, "TRAN END\n");
      c->info.in_transaction = c->db->in_transaction;
    }
    else
    {
      if (NULL == rset)
	buf_appendf(c->out, "SQL result failed: %s\n", strerror(errno));
      else
      {
	output_rset(c->out, "QUERY", NULL, rset);
	rset_free(rset);
      }
    }
  }
  if (!c->db->in_use)
  {
    buf_appendf(c->out, "SQL connection dropped\n");
    if (c->info.in_transaction)
    {
      c->info.in_transaction = 0;
      buf_appendf(c->out, "TRAN aborted\n");
    }
    c->db = NULL;
  }
  if (!c->info.in_transaction && db_isready(c->db))
  {
    db_release(c->db);
    c->db = NULL;
  }
}
void	do_notify(const char* name)
{
  rset_t* rset;

  rset = rsetpool_del(&rsetpool_ready, name);
  if (NULL == rset)
    return;
  rsetpool_add(&rsetpool_pending, rset);
}
void	process_notify_rset(void)
{
  rset_t* rset;

  if (NULL == db_notification)
    return;
  if (!db_notification->in_use)
  {
    db_notification = NULL;
    return;
  }
  /* handle pending rset */
  if (db_notification->has_result)
  {
    if (NULL != db_pending_name)
    {
      rset = rsetpool_del(&rsetpool_pending, db_pending_name);
      if (NULL != rset)
      {
	if (db_fill_rset(db_notification, rset))
	  rset_free(rset);
	else
	  rsetpool_add(&rsetpool_ready, rset);
      }
      free(db_pending_name);
      db_pending_name = NULL;
    }
    db_nextresult(db_notification);
    if (!db_notification->in_use)
      db_notification = NULL;
    return;
  }

  /* do a query on an item in the pool */
  if (!db_isready(db_notification))
    return;
  rset = rsetpool_pending;
  if (NULL == rset)
  {
    if (db_notify_queries->len > 0)
      goto do_query;	/* ensure any pending LISTENs get done */
    return;
  }
  assert(NULL == db_pending_name);
  assert(NULL != rset->name);
  if (NULL == (db_pending_name = strdup(rset->name)))
    return;
#if 0
  /* pull it out of the pool so query isn't accidentally repeated */
  rsetpool_pending = rset->next;
  free(db_pending_name);
  db_pending_name = NULL;
  if (NULL == rset->name ||
      NULL == (db_pending_name = strdup(rset->name)))
  {
    rset_free(rset);
    return;
  }
  rset_free(rset);
#endif
  buf_prependf(db_notify_queries, "SELECT * FROM %s;\n", db_pending_name);
  /* and wait for the result... */
do_query:
  db_query(db_notification, (const char*) db_notify_queries->ptr);
  buf_consume(db_notify_queries, 0, 0);
}
void	reregister_notifies(void)
{
  unsigned int j;
  connection_t* c;
  notify_t* n;
  rset_t* rset;

  if (NULL == db_notification)
    return;
  /* use buffer to store the SQL statements */
  buf_consume(db_notify_queries, 0, 0);
  buf_appendf(db_notify_queries, "UNLISTEN *;\n");	/* just in case */

  /* empty out the finished pool */
  while (NULL != rsetpool_ready)
  {
    rset = rsetpool_ready;
    rsetpool_ready = rset->next;
    rset_free(rset);
  }
  /* empty out the pending pool, to be filled with awaiting results */
  while (NULL != rsetpool_pending)
  {
    rset = rsetpool_pending;
    rsetpool_pending = rset->next;
    rset_free(rset);
  }
  free(db_pending_name);
  db_pending_name = NULL;

  for (c = connections; NULL != c; c = c->next)
    for (j = 0, n = c->notify_list; j < c->notify_count; j++, n++)
    {
      if (NOTIFY_DB != n->type || NULL == n->name)
	continue;
      n->activate = 1;	/* assume it's changed from under us */
      n->num_activations++;	// don't track??
      server_listen4rset(n->name);
    }
#if 0	// should be automatic with process_notify_rset
  error = db_query(db_notification, db_notify_queries->ptr);
  buf_consume(db_notify_queries, 0, 0);
  if (error)
    log_msg(error, "WARNING!  Database did not accept notifications list");
#endif
}


const char* connect_idmodifier(connection_t* c)
{
  if (NULL == c)
    return NULL;
  if (c->info.has_admin)
    return "@";
  if (c->terminal.interactive)
    return "+";
  return "";
}
const char* canonical_bytes(uint64_t bytes)
{
  static char buffer[8];
  char suffix[] = "BKMGTP";
  int i;

  for (i = 0; bytes >= 1024L; i++)
    bytes >>= 10;
  sprintf(buffer, "%4jd%c", bytes, suffix[i]);
  return buffer;
}
const char* timeval2datestr(const struct timeval* tv)
{
  time_t t;
  char* str;

  if (NULL == tv)
    return NULL;
  t = tv->tv_sec;
  str = ctime(&t);
  strchomp(str);
  return str;
}
const char* timeval2millis(const struct timeval* tv)
{
  static char buffer[8];
  unsigned long secs;
  unsigned short millis;

  if (NULL == tv)
    return NULL;
  secs = tv->tv_sec >= 0 ? tv->tv_sec : -tv->tv_sec;
  millis = (tv->tv_usec >= 0 ? tv->tv_usec : -tv->tv_usec) / 1000;
  if (secs < 1)
  {
    if (millis < 10)
      sprintf(buffer, "%d.%ldms", millis,
	      (long int) ((tv->tv_usec >= 0 ? tv->tv_usec : -tv->tv_usec) / 100) % 10);
    else
      sprintf(buffer, "%3dms", millis);
  } else
  if (secs < 100)
    sprintf(buffer, "%2lu.%lus", secs, millis / 100L);
  else
  if (secs < 10000)
    sprintf(buffer, "%4lus", secs);
  else
    strcpy(buffer, "NEVER");
  return buffer;
}
const char* timeval2minutes(const struct timeval* tv)
{
  static char buffer[16];
  unsigned long secs;

  if (NULL == tv)
    return NULL;
  secs = tv->tv_sec >= 0 ? tv->tv_sec : -tv->tv_sec;
  if (secs < 60)
    strcpy(buffer, "-");
  else
  if (secs < 3600)
    sprintf(buffer, "%ld", secs / 60);
  else
  if (tv->tv_sec < 360000)
    sprintf(buffer, "%ld:%02ld", secs / 3600, (secs / 60) % 60);
  else
    sprintf(buffer, "%ldh", secs / 3600);
  return buffer;
}
void	server_listen4rset(const char* rset_name)
{
  rset_t* rset;

  if (NULL != rsetpool_find(&rsetpool_ready, rset_name) ||
      NULL != rsetpool_find(&rsetpool_pending, rset_name))
    return;	/* already listening for this */
  rset = rset_new(rset_name, 0, 0);
  if (NULL == rset)
  {
    log_msg(0, "WARNING: not listening for %s", rset_name);
    return;
  }
  rsetpool_add(&rsetpool_pending, rset);
  buf_appendf(db_notify_queries, "LISTEN %s;\n", rset_name);
}
void	server_varset(const char* key, const char* value)
{
  if (NULL == value)
    var_unset(vars, key);
  else
  {
    var_set(vars, key, value);
    notify_all(NOTIFY_VAR, key);
  }
}
void	output_rset(buffer_t* out, const char* prefix,
		    const char* name, const rset_t* rset)
{
  unsigned int r, f;

  if (NULL == out || NULL == rset ||
      NULL == rset->fields || NULL == rset->records ||
      0 == rset->num_fields)
    return;
  buf_appendf(out, "%s%s%s%s %s %d rows %d columns\n",
	      NULL == prefix ? "RSET" : prefix,
	      NULL == name ? "" : " \"",
	      NULL == name ? "" : name,
	      NULL == name ? "" : "\"",
	      NULL == prefix ? "is" : "returned",
	      rset->num_records, rset->num_fields);
  for (f = 0; f < rset->num_fields; f++)
    buf_appendf(out, "%s%s", 0 == f ? "" : "\t", rset->fields[f]);
  buf_append_eol(out);
  for (r = 0; r < rset->num_records; r++)
  {
    if (NULL == rset->records[r])
      continue;
    for (f = 0; f < rset->num_fields; f++)
      buf_appendf(out, "%s%s", 0 == f ? "" : "\t", rset->records[r][f]);
    buf_append_eol(out);
  }
  buf_appendf(out, "DONE\n");
}
void	output_var(buffer_t* out, const char* key, const char* value)
{
  if (NULL == out || NULL == key || NULL == value)
    return;
  buf_appendf(out, "ENV %s=%s", key, value);
  buf_append_eol(out);
}
