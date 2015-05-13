#include "cc.h"
#include <errno.h>


int	cc_history(buffer_t* out, command_t* cmd, uint8_t argc, char** argv)
{
  int cflag = 0, dflag = 0, rflag = 0, nflag = 0, limit = 0;
  int ch, value, rows, cols, row, col, row_last, rec;
  char* endp = NULL,* str;
  const char* timestr = "";
  connection_t* c;
  rset_t* rset;

  if (NULL == argv)
    return EFAULT;
  while (optind < argc)
  {
    ch = argv[optind][0];
    if ('-' == ch || '+' == ch)
    {
      errno = 0;
      value = strtol(argv[optind] + 1, &endp, 0);
      if (!errno && value >= 0 && NULL != endp && '\0' == *endp)
      {
	if ('-' == ch)
	  value = -value;
	limit = value;
	argv++;
	argc--;
	continue;
      }
    }
    ch = getopt(argc, argv, "cdrn");
    if (-1 == ch)
      break;
    switch (ch)
    {
    case 'c':
      cflag = 1;
      break;
    case 'd':
      dflag = 1;
      break;
    case 'r':
      rflag = 1;
      break;
    case 'n':
      nflag = 1;
      break;
    default:
      return EUSAGE;
    }
  }
  argc -= optind;
  argv += optind;
  if (argc > 1)
    return EUSAGE;
  c = connect_findbybuffer(out);
  if (NULL == c)
    return EDOOFUS;
  if (cflag && !c->info.has_admin)
    return EACCES;
  if (argc > 0)
  {
    unsigned int id;

    errno = 0;
    id = strtol(argv[0], &endp, 0);
    if (errno || NULL == endp || '\0' != *endp)
      return EUSAGE;
    if (!c->info.has_admin)
      return EACCES;
    c = connect_findbyid(id);
    if (NULL == c)
      return ENOSESSION;
  }

  /* prepare the RSET */
  cols = (nflag > 0) + (dflag > 0) + 1;
  rows = limit > 0 ? limit : (limit < 0 ? -limit : c->history_size);
  rset = rset_new(NULL, cols, rows);
  if (NULL == rset)
    return errno;
  str = NULL;
  col = 0;
  if (nflag)
    rset_setfield(rset, col++, "NUMBER");
  if (dflag)
    rset_setfield(rset, col++, "WHEN");
  rset_setfield(rset, col++, "CMD");
  row = limit > 0 ? c->history_size - limit : 0;
  row_last = (limit < 0 ? -limit : c->history_size) - 1;
  if (!rflag)
  {
    rflag = row_last;
    row_last = row;
    row = rflag;

    rflag = -1;		/* incrementor */
  }
  for (	rec = 0;
	rflag > 0 ? (row <= row_last) : (row >= row_last);
	row += rflag)
  {
    if (NULL == c->history_list[row].cmdstr ||
        strlen(c->history_list[row].cmdstr) < 1)
      continue;
    col = 0;
    if (nflag)
      rset_setval(rset, rec, col++, "%d", c->stats.num_commands - row);
    if (dflag)
    {
      timestr = timeval2datestr(&c->history_list[row].stamp);
      if (NULL != timestr)
	rset_setval(rset, rec, col, "%s", timestr);
      col++;
    }
    rset_setval(rset, rec++, col++, "%s", c->history_list[row].cmdstr);
  }
  rset->num_records = rec;
  output_rset(out, NULL, NULL, rset);
  rset->num_records = rows;
  rset_free(rset);

  /* clear history */
  if (cflag)
    bzero(c->history_list, sizeof(cmdinfo_t) * c->history_size);

  return ENONE;
}
