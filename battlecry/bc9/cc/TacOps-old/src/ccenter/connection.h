#ifndef __CONNECTION_H__
#define __CONNECTION_H__

#include <kiwi/types.h>
#include <buffer.h>
#include <db.h>
#include <rset.h>
#include <var.h>


/* connection information */
typedef struct
{
  int		sock_fd;	/* socket file descriptor */
  unsigned int	connection_id;	/* unique across restarts of server */
  struct timeval connect_time;
  char*		remote_addr;

  char*		nickname;
  int		connection_sequence;	/* inc'd by client on reconnects */

  unsigned int	has_admin : 1;	/* has administrative privileges */
  unsigned int	in_transaction : 1;	/* if DB within transaction */
  unsigned int	will_ping : 1;	/* if PING should occur soon */
  unsigned int	will_disconnect : 1;	/* set if connection to be freed */
} conninfo_t;

/* connection statitics */
typedef struct
{
  unsigned int	num_commands;	/* number of commands executed */
  uint64_t	bytes_in, bytes_out;
	/* responded is used for lag compute, "in" is total rec'd */
  unsigned int	num_pings_out, num_pings_in, num_pings_responded;
  struct timeval last_ping_out, last_ping_in;
  struct timeval total_ping_response_times;
} connstats_t;


/* notification properties */
enum notify_type
{
	NOTIFY_VAR,
	NOTIFY_DB,
};
typedef struct
{
  enum notify_type	type;
  char*			name;
  char*			preferred_name;	/* sent instead of name */
  unsigned int		activate : 1;	/* has this been activated? */
  unsigned int		num_activations;
  unsigned int		num_reports;
} notify_t;

/* command information */
typedef struct
{
  struct timeval stamp;		/* when cmd was processed */
  char*		cmdstr;
} cmdinfo_t;


/* a connection */
typedef struct connection_s
{
  struct connection_s* next;
  conninfo_t	info;
  connstats_t	stats;
  termprop_t	terminal;
  buffer_t*	in,* out;

  db_connection* db;	/* if used, disable I/O handling */
  rset_t*	rset;
  uint16_t	notify_count;
  notify_t*	notify_list;
  uint16_t	history_size;
  cmdinfo_t*	history_list;	/* in reverse-chronological order */
} connection_t;


extern unsigned int	connection_count;
extern connection_t*	connections;


connection_t*	connect_new(int sock_fd, const char* remote_addr);
void		connect_free(connection_t* c);
connection_t*	connect_findbybuffer(buffer_t* buf);
connection_t*	connect_findbyfd(int sock_fd);
connection_t*	connect_findbyid(unsigned int id);

void		connect_fd_set(int* nfds, fd_set* rfds, fd_set* wfds);
void		connect_flush(int sock_fd);
void		connect_slurp(int sock_fd);

/* NOTE: if adding, make sure to inform the server of a rset */
void		notify_all(enum notify_type type, const char* name);
void		notify_add(connection_t* c, enum notify_type type,
			   const char* name, const char* pref_name);
void		notify_del(connection_t* c,
			   enum notify_type type, const char* name);
notify_t*	notify_get(connection_t* c, 
			   enum notify_type type, const char* name);
void		make_history(connection_t* c, const char* cmd);

#endif /* __CONNECTION_H__ */
