#include "connection.h"
#include <arpa/telnet.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <sys/uio.h>
#include <unistd.h>


#define HISTORY_SIZE 100

unsigned int	connection_count = 0;
connection_t*	connections = NULL;


connection_t*	connect_new(int sock_fd, const char* remote_addr)
{
  static unsigned int new_id = 1;
  int error;
  connection_t* c;

  c = malloc(sizeof(connection_t));
  if (NULL == c)
    return NULL;
  bzero(c, sizeof(*c));
  c->next = connections;
  connections = c;
  connection_count++;

  c->info.sock_fd = sock_fd;
  c->info.connection_id = new_id;
  gettimeofday(&c->info.connect_time, NULL);
  if (NULL != remote_addr)
    c->info.remote_addr = strdup(remote_addr);
  c->terminal.CR = 1;
  c->terminal.LF = 1;
  c->in = buf_new(0);
  c->out = buf_new(0);
  if (NULL == c->in || NULL == c->out)
    goto connect_error;
  /* point back so window size & EOL chars are known */
  c->in->term = &c->terminal;
  c->out->term = &c->terminal;
  /*
   * Assume non-interactive, but if we get any valid response to this,
   * set as interactive.  If valid response to this occers before any
   * commands are sent, immediately show prompt.  On first command
   * received, if not interactive, send a PING.
   */
  buf_appendf(c->out, "%c%c%c%c%c%c",
	      IAC, DO, TELOPT_NAWS, IAC, DO, TELOPT_TTYPE);
	/* we need 5 chars after IAC because Flash is dumb */

  c->history_list = malloc(sizeof(cmdinfo_t) * HISTORY_SIZE);
  if (NULL == c->history_list)
    goto connect_error;
  bzero(c->history_list, sizeof(cmdinfo_t) * HISTORY_SIZE);
  c->history_size = HISTORY_SIZE;

  new_id++;
  return c;
connect_error:
  error = errno;
  connect_free(c);
  errno = error;
  return NULL;
}
void		connect_free(connection_t* c)
{
  unsigned int i;
  connection_t* parent;

  if (NULL == c)
    return;
  close(c->info.sock_fd);
  free(c->info.remote_addr);
  free(c->info.nickname);
  // here: dump stats into log?
  buf_free(c->in);
  buf_free(c->out);
  if (NULL != c->db)
    db_release(c->db);
  if (NULL != c->notify_list)
  {
    for (i = c->notify_count; i > 0; i--)
      notify_del(c, c->notify_list[i - 1].type, c->notify_list[i - 1].name);
    free(c->notify_list);
  }
  for (i = 0; i < c->history_size; i++)
  {
    free(c->history_list[i].cmdstr);
  }
  free(c->history_list);

  if (connections == c)
    connections = c->next; 
  else
  {
    for (parent = connections; NULL != parent; parent = parent->next)
      if (c == parent->next)
	break;
    if (NULL == parent)
      return;
    parent->next = c->next;
  }
  free(c);
  connection_count--;
  errno = 0;
}
connection_t*	connect_findbybuffer(buffer_t* buf)
{
  connection_t* c;

  if (NULL == buf)
  {
    errno = EFAULT;
    return NULL;
  }
  for (c = connections; NULL != c; c = c->next)
  {
    if (buf == c->in || buf == c->out)
      return c;
  }
  errno = ENOENT;
  return NULL;
}
connection_t*	connect_findbyfd(int sock_fd)
{
  connection_t* c;

  for (c = connections; NULL != c; c = c->next)
  {
    if (sock_fd == c->info.sock_fd)
      return c;
  }
  errno = ENOENT;
  return NULL;
}
connection_t*	connect_findbyid(unsigned int id)
{
  connection_t* c;

  for (c = connections; NULL != c; c = c->next)
    if (id == c->info.connection_id)
      return c;
  errno = ENOENT;
  return NULL;
}


void		connect_fd_set(int* nfds, fd_set* rfds, fd_set* wfds)
{
  connection_t* c;
  int max_id = 0, fd;

  if (NULL == nfds)
    nfds = &max_id;
  else
    max_id = *nfds;

  for (c = connections; NULL != c; c = c->next)
  {
    fd = c->info.sock_fd;
    FD_SET(fd, rfds);
    if (c->out->len > 0)
      FD_SET(fd, wfds);
    if (fd + 1 > max_id)
      max_id = fd + 1;
  }
  *nfds = max_id;
}
void		connect_flush(int sock_fd)
{
  ssize_t bytes;
  connection_t* c = connect_findbyfd(sock_fd);

  if (NULL == c || c->out->len < 1)
    return;
  bytes = write(sock_fd, c->out->ptr, c->out->len);
  if (bytes < 0)
  {
    if (EAGAIN == errno)
      return;
    // TODO: log the error
    connect_free(c);
    return;
  }
  if (bytes > 0)
  {
    buf_consume(c->out, bytes, 0);
    c->stats.bytes_out += bytes;
  }
}
void		connect_slurp(int sock_fd)
{
  ssize_t bytes;
  char buffer[1024];		/* max per-attempt read */
  connection_t* c = connect_findbyfd(sock_fd);

  if (NULL == c)
    return;
  bytes = read(sock_fd, buffer, sizeof(buffer));
  if (bytes < 0 && EAGAIN == errno)
    return;
  if (bytes <= 0)
  {
    // TODO: log the error
    connect_free(c);
    return;
  }
  if (bytes > 0)
  {
    c->stats.bytes_in += bytes;
    buf_appendx(c->in, buffer, bytes);
    if (c->in->size > 65536)	/* max unprocessed read buffer */
    {
      // TODO: log the error
      connect_free(c);
      return;
    }
  }
}


uint16_t	_notify_findcmp(connection_t* c, enum notify_type type,
				const char* name, int* cmp)
{
  uint16_t index;
  int mycmp, first, last;

  if (NULL == cmp)
    cmp = &mycmp;
  *cmp = mycmp = -1;
  index = 0;
  if (NULL == c->notify_list || NULL == c)
    return index;
  first = 0;
  last = c->notify_count - 1;
  while (last >= first)
  {
    index = (first + last) >> 1;
    mycmp = type - c->notify_list[index].type;
    if (!mycmp)
    {
      mycmp = strcmp(name, c->notify_list[index].name);
      if (!mycmp)
      {
	*cmp = mycmp;
	return index;
      }
    }
    if (mycmp < 0)
      last = index - 1;
    else
      first = index + 1;
  }
  if (mycmp > 0)
    index++;
  *cmp = mycmp;
  return index;
}
void		notify_all(enum notify_type type, const char* name)
{
  connection_t* c;
  int cmp;
  uint16_t index;

  if (NULL == name)
    return;
  for (c = connections; NULL != c; c = c->next)
  {
    if (NULL == c->notify_list)
      continue;
    index = _notify_findcmp(c, type, name, &cmp);
    if (!cmp)
    {
      c->notify_list[index].activate = 1;
      c->notify_list[index].num_activations++;
    }
  }
}
void		notify_add(connection_t* c, enum notify_type type,
			   const char* name, const char* pref_name)
{
  int cmp = -1;
  uint16_t index = 0;
  notify_t* n;

  if (NULL == c || NULL == name)
    return;
  if (NULL != c->notify_list)
  {
    index = _notify_findcmp(c, type, name, &cmp);
#if 0
    /* replace current notification */
    if (!cmp)
      goto _notify_set;
#else
    /* silently ignore, but don't reset stats, but update alias */
    if (!cmp)
    {
      n = c->notify_list + index;
      goto _notify_set;
    }
#endif
  }
  n = realloc(c->notify_list, sizeof(notify_t) * (c->notify_count + 1));
  if (NULL == n)
    return;
  c->notify_list = n;
  memmove(c->notify_list + index + 1, c->notify_list + index,
	  sizeof(notify_t) * (c->notify_count - index));
  c->notify_count++;
  bzero(c->notify_list + index, sizeof(notify_t));
  n = c->notify_list + index;
  n->type = type;
  n->name = strdup(name);  // fail?
_notify_set:
  free(n->preferred_name);
  if (NULL != pref_name)
    n->preferred_name = strdup(pref_name);
  n->activate = 1;	/* don't increment counter */
}
void		notify_del(connection_t* c,
			   enum notify_type type, const char* name)
{
  int cmp = -1;
  uint16_t index = 0;

  if (NULL == c || NULL == name || NULL == c->notify_list)
    return;
  index = _notify_findcmp(c, type, name, &cmp);
  if (cmp)
    return;
  free(c->notify_list[index].name);
  free(c->notify_list[index].preferred_name);
  memmove(c->notify_list + index, c->notify_list + index + 1,
	  sizeof(notify_t) * (c->notify_count - index - 1));
  c->notify_count--;
}
notify_t*	notify_get(connection_t* c,
			   enum notify_type type, const char* name)
{
  int cmp = -1;
  uint16_t index = 0;

  if (NULL == c || NULL == name || NULL == c->notify_list)
    return NULL;
  index = _notify_findcmp(c, type, name, &cmp);
  if (cmp)
    return NULL;
  return c->notify_list + index;
}


void		make_history(connection_t* c, const char* cmd)
{
  if (NULL == c || NULL == cmd)
    return;
  free(c->history_list[c->history_size - 1].cmdstr);
  memmove(c->history_list + 1, c->history_list,
	  sizeof(cmdinfo_t) * (c->history_size - 1));
  gettimeofday(&c->history_list->stamp, NULL);
  c->history_list->cmdstr = strdup(cmd);
  c->stats.num_commands++;
}
