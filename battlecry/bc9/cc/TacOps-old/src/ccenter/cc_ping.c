#include "cc.h"

int	cc_ping(buffer_t* out, command_t* cmd, uint8_t argc, char** argv)
{
  connection_t* c;
  struct timeval tv;

  if (NULL == argv)
    return EFAULT;
  if (!strcasecmp(*argv, "pong"))
  {
    c = connect_findbybuffer(out);
    if (NULL == c)
      return EDOOFUS;
    gettimeofday(&c->stats.last_ping_in, NULL);
    c->stats.num_pings_in++;
    if (timercmp(&c->stats.last_ping_out, &c->stats.last_ping_in, <))
    {
      c->stats.num_pings_responded++;
      timersub(&c->stats.last_ping_in, &c->stats.last_ping_out, &tv);
      c->stats.last_ping_in = tv;	/* save difference here */
      timeradd(&tv, &c->stats.total_ping_response_times,
		&c->stats.total_ping_response_times);
    }
    return ENONE;
  }
  // TODO: how should this work?
  return ENOSYS;
}
