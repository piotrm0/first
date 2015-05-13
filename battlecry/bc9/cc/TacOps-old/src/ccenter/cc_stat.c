#include "cc.h"

int	cc_stat(buffer_t* out, command_t* cmd, uint8_t argc, char** argv)
{
  unsigned int show_all = 0, show_cmd = 0;
  unsigned int show_bufs = 0, show_long = 0, show_net = 0, show_ping = 0;
  unsigned int show_times = 0, verbose = 0;
  unsigned int j, rec, col, cols, recs, session_id;
  int ch;
  connection_t* c;
  rset_t* rset;
  struct timeval now, diff;
  
  if (NULL == argv)
    return EFAULT;
  while ((ch = getopt(argc, argv, "abcflnptv")) != -1)
    switch (ch)
    {
    case 'a':
      show_all = 1;
      break;
    case 'b':
      show_bufs = 1;
      break;
    case 'c':
      show_cmd = 1;
      break;
    case 'f':
      show_cmd = show_bufs = show_long = show_net = show_ping = 1;
      show_times = verbose = 1;
      break;
    case 'l':
      show_long = 1;
      break;
    case 'n':
      show_net = 1;
      break;
    case 'p':
      show_ping = 1;
      break;
    case 't':
      show_times = 1;
      break;
    case 'v':
      verbose = 1;
      break;
    default:
      return EUSAGE;
    }
  if (optind <= 1)
    show_cmd = 1;
  argc -= optind;
  argv += optind;
  if (show_all && argc > 0)
    return EUSAGE;

  /* compute number of fields */
  cols = 1;
  if (show_long)
    cols += 2 + verbose + show_times;
  cols += show_cmd + (show_net << 1);
  if (show_ping)
    cols += 2 + verbose + (show_times << 1);
  cols += (show_bufs << 1);

  /* compute number of records */
  if (show_all)
    recs = connection_count;
  else
  if (!argc)
    recs = 1;
  else
    for (j = 0, recs = 0; j < argc; j++)
    {
      session_id = strtol(argv[j], NULL, 0);
      for (c = connections; NULL != c; c = c->next)
      {
	if (session_id)
	{
	  if (session_id == c->info.connection_id)
	    recs++;
	  continue;
	}
	if (NULL == c->info.nickname)
	  continue;
	if (!strcmp(argv[j], c->info.nickname))
	  recs++;
      }
    }

  /* fill in fields */
  rset = rset_new(NULL, cols, recs);
  if (NULL == rset)
    return errno;
  col = 0;
  rset_setfield(rset, col++, "SESSION");
  if (show_long)
  {
    rset_setfield(rset, col++, "NICK");
    rset_setfield(rset, col++, "SEQ");
    if (verbose)
      rset_setfield(rset, col++, "SOCK FD");
    if (show_times)
      rset_setfield(rset, col++, "CONNECT");
  }
  if (show_cmd)
    rset_setfield(rset, col++, "# CMDS");
  if (show_net)
  {
    rset_setfield(rset, col++, "NET IN");
    rset_setfield(rset, col++, "OUT");
  }
  if (show_ping)
  {
    rset_setfield(rset, col++, "PING IN");
    rset_setfield(rset, col++, "OUT");
    if (verbose)
      rset_setfield(rset, col++, "%% LOSS");
    if (show_times)
    {
      rset_setfield(rset, col++, "AVE");
      rset_setfield(rset, col++, "LAST");
    }
  }
  if (show_bufs)
  {
    rset_setfield(rset, col++, "BUF IN");
    rset_setfield(rset, col++, "OUT");
  }

  /* fill in records */
  if (show_long && show_times)
    gettimeofday(&now, NULL);
  for (rec = 0, c = connections; NULL != c; c = c->next)
  {
    if (!show_all)
    {
      if (!argc)
      {
	if (out != c->out)
	  continue;
      } else
      {
	for (j = 0; j < argc; j++)
	{
	  session_id = strtol(argv[j], NULL, 0);
	  if (session_id)
	  {
	    if (session_id == c->info.connection_id);
	      break;
	    continue;
	  }
	  if (NULL != c->info.nickname &&
	      !strcmp(argv[j], c->info.nickname))
	    break;
	}
      }
    }
    col = 0;
    rset_setval(rset, rec, col++, "%d%s", c->info.connection_id,
		connect_idmodifier(c));
    if (show_long)
    {
      if (NULL != c->info.nickname)
	rset_setval(rset, rec, col++, "%s", c->info.nickname);
      else
	rset_setval(rset, rec, col++, "");
      if (c->info.connection_sequence)
	rset_setval(rset, rec, col++, "%d", c->info.connection_sequence);
      else
	rset_setval(rset, rec, col++, "");
      if (verbose)
	rset_setval(rset, rec, col++, "%d", c->info.sock_fd);
      if (show_times)
      {
	timersub(&c->info.connect_time, &now, &diff);
	rset_setval(rset, rec, col++, "%s", timeval2minutes(&diff));
      }
    }
    if (show_cmd)
      rset_setval(rset, rec, col++, "%d", c->stats.num_commands);
    if (show_net)
    {
      rset_setval(rset, rec, col++, "%s",
		   canonical_bytes(c->stats.bytes_in));
      rset_setval(rset, rec, col++, "%s",
		   canonical_bytes(c->stats.bytes_out));
    }
    if (show_ping)
    {
      float f = 0.0;
      unsigned int in, out;

      in = c->stats.num_pings_in;
      out = c->stats.num_pings_out;

      rset_setval(rset, rec, col++, "%u", in);
      rset_setval(rset, rec, col++, "%u", out);
      if (verbose)
      {
	if (out)
	{
	  f = in;
	  if (in + 1 == out)
	    f += 1.0;
	  f /= out;
	  f *= 100.0;	/* a percentage */
	  rset_setval(rset, rec, col++, "%5.1", f);
	} else
	  rset_setval(rset, rec, col++, "");
      }
      if (show_times && in)
      {
	diff = c->stats.total_ping_response_times;
	diff.tv_usec += diff.tv_sec % in;
	diff.tv_sec /= in;
	diff.tv_usec /= in;
	rset_setval(rset, rec, col++, "%s", timeval2millis(&diff));
	rset_setval(rset, rec, col++, "%s",
			timeval2millis(&c->stats.last_ping_in));
      }
      if (show_times && !in)
      {
	rset_setval(rset, rec, col++, "");
	rset_setval(rset, rec, col++, "");
      }
    }
    if (show_bufs)
    {
      rset_setval(rset, rec, col++, "%s", canonical_bytes(c->in->size));
      rset_setval(rset, rec, col++, "%s", canonical_bytes(c->out->size));
    }
    rec++;
  }

  output_rset(out, NULL, "stat", rset);
  rset_free(rset);

  return ENONE;
}
