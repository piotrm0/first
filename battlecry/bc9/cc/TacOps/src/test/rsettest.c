#include <kiwi/string.h>
#include <rset.h>
#include <stdio.h>
#include <stdlib.h>


int	main(void)
{
  char buffer[1024];
  rset_t* rset;
  char* name,* fields;
  int num_records, num_fields, row, col;

  printf("enter rset name: ");
  fflush(stdout);
  if (NULL == fgets(buffer, 1024, stdin))
    return 0;
  strchomp(buffer);
  name = strdup(buffer);

  printf("enter number of fields: ");
  fflush(stdout);
  if (NULL == fgets(buffer, 1024, stdin))
    return 0;
  num_fields = atoi(buffer);

  printf("enter field names, tab-separated:\n");
  fflush(stdout);
  if (NULL == fgets(buffer, 1024, stdin))
    return 0;
  strchomp(buffer);
  fields = strdup(buffer);

  printf("enter number of records: ");
  fflush(stdout);
  if (NULL == fgets(buffer, 1024, stdin))
    return 0;
  num_records = atoi(buffer);

  rset = rset_new(name, num_fields, num_records);
  rset_setfields(rset, fields, '\t');

  for (row = 0; row < num_records; row++)
  {
    printf("enter row #%d, tab-separated:\n", row + 1);
    fflush(stdout);
    if (NULL == fgets(buffer, 1024, stdin))
      return 0;
    strchomp(buffer);
    rset_setrec(rset, row, buffer, '\t');
  }

  printf("\nrset %s:\n%d records, %d fields\n", rset->name,
	 rset->num_records, rset->num_fields);
  for (col = 0; col < rset->num_fields; col++)
    printf("%s\t", rset->fields[col]);
  printf("\n");
  for (row = 0; row < rset->num_records; row++)
  {
    for (col = 0; col < rset->num_fields; col++)
      printf("%s\t", rset->records[row][col]);
    printf("\n");
  }
  fflush(stdout);
  return 0;
}
