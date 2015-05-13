#include <db.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


db_connection* conn = NULL;


void	pexit(int error, const char* fmt, ...)
{
  va_list ap;
  const char* str = NULL;

  va_start(ap, fmt);
  if (NULL != fmt)
  {
    vfprintf(stderr, fmt, ap);
    if (error)
      fprintf(stderr, ": ");
  }
  if (error > 0)
    str = strerror(error);
  if (NULL != str)
    fprintf(stderr, "%s (%d)", str, error);
  if (error < 0)
    fprintf(stderr, "error %d", error);
  if (NULL != fmt || error)
    fprintf(stderr, "\n");
  exit(EXIT_FAILURE);
}
void	mexit(void)
{
  if (NULL != conn)
    db_release(conn);
  conn = NULL;
  db_free();
}
int	main(void)
{
  int error, i;
  char buffer[1024],* str;

  error = db_init();
  if (error)
    pexit(error, "Unable to initialize database");
  if (atexit(mexit))
    pexit(errno, "Unable to setup atexit()");
  for (i = 0; i < 10; i++)
  {
    db_pollall();
    usleep(100000);
  }
  conn = db_connect();
  if (NULL == conn)
    pexit(errno, "Unable to connect to database");

  while (NULL != fgets(buffer, 1024, stdin))
  {
    fprintf(stdout, "executing query: %s", buffer);
    fflush(stdout);
    error = db_query(conn, buffer);
    usleep(100000);
    db_pollall();
    while (NULL != conn->result)
    {
      int i, j;

      printf("result:\t%d rows\t%d columns\n",
	     conn->num_rows, conn->num_cols);
      if (conn->num_cols)
      {
	for (i = 0; i < conn->num_cols; i++)
	  printf("%s\t", db_getfield(conn, i));
	for (i = 0; i < conn->num_rows; i++)
	{
	  printf("\n");
	  for (j = 0; j < conn->num_cols; j++)
	    printf("%s\t", db_getvalue(conn, i, j));
	}
	printf("\n");
      }
      db_nextresult(conn);
    }
    while (NULL != (str = db_notified(conn)))
    {
      printf("notified:\t%s\n", str);
    }
    printf("\n");
    fflush(stdout);
  }
  return 0;
}
