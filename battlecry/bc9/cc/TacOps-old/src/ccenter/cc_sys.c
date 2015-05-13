#include "cc.h"
#include "db.h"

extern db_connection* db_connections;
extern uint8_t db_num_connections, db_avail_connections;
extern const char* DB_CONNECTION_STATES[];


int	cc_sys(buffer_t* out, command_t* cmd, uint8_t argc, char** argv)
{
  db_connection* db;
  uint8_t num_db = 0, num_db_used = 0;

  if (NULL == out)
    return EFAULT;
  buf_appendf(out, "DB connections:\n");
  for (db = db_connections; NULL != db; db = db->next)
  {
    num_db++;
    if (db->in_use)
      num_db_used++;
    buf_appendf(out, "%d\t%s\t%s\t%s%s", num_db,
		DB_CONNECTION_STATES[db->connection_state],
		db->in_use ? "in use" : "",
		db->in_transaction ? "(tran)\t" : "",
		db->has_result ? "result:\t" : "\n");
    if (db->has_result)
      buf_appendf(out, "%d cols\t%d rows\n", db->num_cols, db->num_rows);
  }
  buf_appendf(out, "%d/%d connections available (DB reports %d/%d)\n",
	      num_db - num_db_used, num_db, db_avail_connections,
	      db_num_connections);
  return ENONE;
}
