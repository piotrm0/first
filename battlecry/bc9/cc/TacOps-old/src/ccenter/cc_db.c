#include "cc.h"

int	cc_db(buffer_t* out, command_t* cmd, uint8_t argc, char** argv)
{
  char* query;
  connection_t* c;

  if (NULL == argv)
    return EFAULT;
  c = connect_findbybuffer(out);
  if (NULL == c)
    return EDOOFUS;
  if (NULL != c->db && !c->info.in_transaction)
    return EALREADY;
  if (NULL == c->db)
  {
    c->db = db_connect();
    if (NULL == c->db)
      return errno;
  }
  query = command_sjoin(" ", (const char**)argv);
  if (NULL == query || db_query(c->db, query))
  {
    free(query);
    db_release(c->db);
    c->db = NULL;
    return errno;
  }
  return ENONE;
}
