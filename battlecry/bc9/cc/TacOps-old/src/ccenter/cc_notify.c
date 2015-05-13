#include "cc.h"

int	cc_notify(buffer_t* out, command_t* cmd, uint8_t argc, char** argv)
{
  unsigned int session_id = 0, i;
  connection_t* c;
  char* endp = NULL;
  uint8_t arg = 1;
  unsigned int on_off = 1, valid;
  enum notify_type type;
  const char* name,* alias_name = NULL;

  if (NULL == argv)
    return EFAULT;
  c = connect_findbybuffer(out);
  if (NULL == c)
    return EDOOFUS;
  if (arg < argc)
  {
    session_id = strtol(argv[arg], &endp, 0);
    if (session_id)
    {
      if (errno || NULL == endp || '\0' != *endp)
	return EUSAGE;
      if (!c->info.has_admin)
	return EACCES;
      c = connect_findbyid(session_id);
      if (NULL == c)
	return ENOSESSION;
      arg++;
    }
  }
  if (!(arg < argc))
  {
    rset_t* rset;
    char* typestr;

    /* display a list of notifications for this client and exit */
    rset = rset_new(NULL, 2, c->notify_count);
    if (NULL == rset || rset->num_fields < 2 ||
	rset->num_records < c->notify_count ||
	NULL == (rset->fields[0] = strdup("type")) ||
	NULL == (rset->fields[1] = strdup("name")))
    {
      rset_free(rset);
      return errno;
    }
    for (i = 0; i < c->notify_count; i++)
    {
      switch (c->notify_list[i].type)
      {
      case NOTIFY_VAR:
	typestr = "env";
	break;
      case NOTIFY_DB:
	typestr = "rset";
	break;
      default:
	typestr = NULL;
	break;
      }
      if (NULL != typestr)
	rset_setval(rset, i, 0, typestr);
      rset_setval(rset, i, 1, c->notify_list[i].name);
    }
    output_rset(out, NULL, NULL, rset);
    rset_free(rset);
    return ENONE;
  }
  if (!strcasecmp(argv[arg], "on"))
    on_off = 1;
  else
  if (!strcasecmp(argv[arg], "off"))
    on_off = 0;
  else
  if (session_id)
    return EUSAGE;
  else
    arg--;
  arg++;
  do
  {
    if (!(arg < argc))
    {
      if (on_off)
	return EUSAGE;
      for (i = c->notify_count; i > 0; i--)
	notify_del(c, c->notify_list[i - 1].type, c->notify_list[i - 1].name);
      return ENONE;
    }
    if (!strcasecmp(argv[arg], "env"))
    {
      arg++;
      type = NOTIFY_VAR;
    } else
    if (!strcasecmp(argv[arg], "rset"))
    {
      arg++;
      type = NOTIFY_DB;
    } else
      type = NOTIFY_VAR;
    if (!(arg < argc))
      return EUSAGE;
    if (NULL == (name = argv[arg++]))
      return EINVAL;
    valid = NOTIFY_DB == type ? rset_validname(name) : var_validname(name);
    if (!valid)
    {
      buf_append(out, "ERR: name cannot contain illegal chars\n");
      return EIGNORE;
    }

    if (on_off)
    {
      if (arg < argc)
      {
	if (arg + 2 != argc || strcasecmp(argv[arg++], "as"))
	  return EUSAGE;
	alias_name = argv[arg];
	valid = NOTIFY_DB == type ?
		rset_validname(name) : var_validname(name);
	if (!valid)
	{
	  buf_append(out, "ERR: alias name cannot contain illegal chars\n");
	  return EIGNORE;
	}
	if (!strcmp(name, alias_name))
	  alias_name = NULL;
      }
      notify_add(c, type, name, alias_name);
      if (NOTIFY_DB == type)
	server_listen4rset(name);
      return ENONE;
    }
    /* loop on "off" names */
    notify_del(c, type, name);
  } while (arg < argc);

  return ENOSYS;
}
