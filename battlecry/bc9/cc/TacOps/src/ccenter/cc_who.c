#include "cc.h"
#include <errno.h>
#include <kiwi/string.h>


int	cc_who(buffer_t* out, command_t* cmd, uint8_t argc, char** argv)
{
  unsigned int show_from = 0, reverse_order = 0;
  enum {
	SHOW_DEFAULT,
	SHOW_TERM,
	SHOW_CMD,
  } show = SHOW_DEFAULT;
  enum {
	SORT_SESSION,
	SORT_LOGIN,
	SORT_IDLE,
  } sort = SORT_SESSION;
  const char* nick = NULL;
  int ch, col, rec, row, row_last, row_inc;
  connection_t* c;
  rset_t* rset;
  char* str = NULL,* eol_cmd;
  char fmt[128], seq[8], size_idle[16], eol[8], db[2];
  struct timeval now, diff;

  if (!strcasecmp("w", argv[0]))
  {
    show_from = 1;
    show = SHOW_CMD;
  }
  while ((ch = getopt(argc, argv, "frctdi")) != -1)
  {
    switch (ch)
    {
    case 'f':
      show_from = 1;
      break;
    case 'r':
      reverse_order = 1;
      break;
    case 'c':
      show = SHOW_CMD;
      break;
    case 't':
      show = SHOW_TERM;
      break;
    case 'd':
      sort = SORT_LOGIN;
      break;
    case 'i':
      sort = SORT_IDLE;
      break;
    default:
      return EUSAGE;
    }
  }
  argc -= optind;
  argv += optind;
  if (argc > 1)
    return EUSAGE;
  if (argc > 0)
    nick = argv[0];


  /* compute the number of rows */
  row = connection_count;
  if (NULL != nick)
    for (row = 0, c = connections; NULL != c; c = c->next)
      if (NULL != c->info.nickname &&
	  !strcmp(nick, c->info.nickname))
	row++;
  /* compute the number of cols */
  switch (show)
  {
  case SHOW_CMD:
    gettimeofday(&now, NULL);
  case SHOW_TERM:
    col = 6;
    break;
  default:
    col = 4;
  }
  if (show_from)
    col++;
  rset = rset_new(NULL, col, row);
  if (NULL == rset)
    return errno;

  /* fill in the field names */
  asprintf(&str, "NICK\tSEQ\tDB\tSESSION%s\tDATE CONNECTED/LOGGED IN%s%s",
	   show_from ? "\tREMOTE ADDR" : "",
	   SHOW_TERM == show ? "\tSIZE\tEOL" : "",
	   SHOW_CMD == show ? "\tIDLE\tCMD" : "");
  if (NULL == str)
  {
    rset_free(rset);
    return errno;
  }
  rset_setfields(rset, str, '\t');
  free(str);
  str = NULL;

  /* fill in the records */
  if (!reverse_order)
  {
    row = 0;
    row_last = connection_count - 1;
    row_inc = +1;
  } else
  {
    row = connection_count - 1;
    row_last = 0;
    row_inc = -1;
  }
  strcpy(fmt, "%s\t%s\t%s\t%6d%s\t%s%s%s");
  if (SHOW_DEFAULT != show)
    strcat(fmt, "\t%s");
  for (rec = 0, c = connections;
       NULL != c && (reverse_order ? row >= row_last : row <= row_last);
       row += row_inc, c = c->next)
  {
    int has_id = c->info.connection_sequence;
    int len = strlength(c->info.remote_addr);
    const char* id_modifier;
    char addr[len + 1];

    if (NULL != nick)
      if (NULL == c->info.nickname || strcmp(nick, c->info.nickname))
        continue;
    if (NULL == c->db)
      strcpy(db, c->info.in_transaction ? "?" : "");
    else
      strcpy(db, c->info.in_transaction ? "+" : "-");
    if (has_id)
      sprintf(seq, "%d", has_id);
    else
      *seq = '\0';
    id_modifier = connect_idmodifier(c);
    if (!show_from)
      *addr = '\0';
    else
    if (!len)
      strcpy(addr, "-");
    else
    {
      char* p;

      strcpy(addr, c->info.remote_addr);
      if (NULL != (p = strrchr(addr, ':')))
	*p = '\0';
    }
    switch (show)
    {
    case SHOW_TERM:
      if (0 == c->terminal.width && 0 == c->terminal.height)
	strcpy(size_idle, "-");
      else
	sprintf(size_idle, "%dx%d", c->terminal.width, c->terminal.height);
      sprintf(eol, "%s%s%s", c->terminal.CR ? "CR" : "",
	      c->terminal.LF ? "LF" : "", c->terminal.NUL ? "NUL" : "");
      eol_cmd = eol;
      break;
    case SHOW_CMD:
      if (c->stats.num_commands)
	timersub(&now, &c->history_list[0].stamp, &diff);
      else
	timersub(&now, &c->info.connect_time, &diff);
      strcpy(size_idle, timeval2minutes(&diff));
      eol_cmd = c->history_list->cmdstr;
      if (NULL == eol_cmd)
	eol_cmd = "-";
      break;
    default:
      eol_cmd = "";
    }
    asprintf(&str, fmt, NULL == c->info.nickname ? "" : c->info.nickname,
	     seq, db, c->info.connection_id, id_modifier, addr,
	     show_from ? "\t" : "", timeval2datestr(&c->info.connect_time),
	     size_idle);
    if (NULL == str)
    {
      free(rset);
      return errno;
    }
    rset_setrec(rset, rec, str, '\t');
    free(str);
    str = NULL;
    if (SHOW_DEFAULT != show &&
	NULL == (rset->records[rec][col - 1] = strdup(eol_cmd)))
    {
      free(rset);
      return errno;
    }
    rec++;
  }

  output_rset(out, NULL, "who", rset);
  rset_free(rset);
  return ENONE;
}
