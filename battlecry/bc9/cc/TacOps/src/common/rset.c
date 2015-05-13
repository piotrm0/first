#include "rset.h"
#include <ctype.h>
#include <kiwi/string.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>


int	rset_validname(const char* key)
{
  int ch;

  if (NULL == key || '\0' == *key)
    return 0;
  while ('\0' != (ch = *key++))
    if (!isalnum(ch) && NULL == strchr("_", ch))
      return 0;
  return 1;
}
rset_t*	rset_new(const char* name, unsigned int fields, unsigned int recs)
{
  rset_t* rset = malloc(sizeof(rset_t));
  if (NULL == rset)
    return NULL;
  bzero(rset, sizeof(rset_t));
  if (NULL != name)
  {
    rset->name = strdup(name);
    if (NULL == rset->name)
    {
      rset_free(rset);
      return NULL;
    }
  }
  rset_resize(rset, fields, recs);
  if (rset->num_fields < fields || rset->num_records < recs)
  {
    rset_free(rset);
    return NULL;
  }
  return rset;
}
void	rset_free(rset_t* rset)
{
  if (NULL == rset)
    return;
  rset_empty(rset);
  free(rset->name);
  bzero(rset, sizeof(rset_t));
  free(rset);
}
void	rset_resize(rset_t* rset, unsigned int fields, unsigned int recs)
{
  int j;

  if (NULL == rset)
    return;
  rset_empty(rset);
  rset->num_fields = fields;
  rset->num_records = recs;
  rset_setfields(rset, NULL, 0);
  if (rset->num_fields < fields)
    return;
  rset->records = malloc(sizeof(char**) * recs);
  if (NULL == rset->records)
  {
    rset->num_fields = 0;
    rset->num_records = 0;
    return;
  }
  bzero(rset->records, sizeof(char**) * recs);
  for (j = 0; j < recs; j++)
  {
    rset->records[j] = malloc(sizeof(char*) * fields);
    if (NULL == rset->records[j])
    {
      rset->num_records = j;
      return;
    }
    bzero(rset->records[j], sizeof(char*) * fields);
  }
}
void	rset_empty(rset_t* rset)
{
  int i, j;

  if (NULL == rset)
    return;
  if (NULL != rset->fields)
  {
    for (i = 0; i < rset->num_fields; i++)
      free(rset->fields[i]);
    free(rset->fields);
    rset->fields = NULL;
  }
  if (NULL != rset->records)
  {
    for (j = 0; j < rset->num_records; j++)
      if (NULL != rset->records[j])
      {
	for (i = 0; i < rset->num_fields; i++)
	  free(rset->records[j][i]);
	free(rset->records[j]);
      }
    free(rset->records);
    rset->records = NULL;
  }
  rset->num_fields = rset->num_records = 0;
}
void	rset_setfields(rset_t* rset, const char* str, char sep)
{
  int i = 0;
  char* next;

  if (NULL == rset)
    return;
  if (NULL != rset->fields)
  {
    for (i = 0; i < rset->num_fields; i++)
      free(rset->fields[i]);
    free(rset->fields);
  }
  rset->fields = malloc(sizeof(char*) * rset->num_fields);
  if (NULL == rset->fields)
    return;
  bzero(rset->fields, sizeof(char*) * rset->num_fields);
  if (NULL == str)
    return;
  i = 0;
  do
  {
    next = strchr(str, sep);
    if (NULL == next)
    {
      rset->fields[i] = strdup(str);
      break;
    } else
      rset->fields[i] = strndup(str, next - str);
    str = next + 1;
    i++;
  } while (i < rset->num_fields && NULL != str);
}
void	rset_setfield(rset_t* rset, unsigned int field, const char* fmt, ...)
{
  char* str = NULL;
  va_list ap;

  if (NULL == rset || NULL == fmt || NULL == rset->fields)
  {
    errno = EFAULT;
    return;
  }
  if (field >= rset->num_fields)
  {
    errno = EINVAL;
    return;
  }
  va_start(ap, fmt);
  vasprintf(&str, fmt, ap);
  va_end(ap);
  if (NULL == str)
    return;
  free(rset->fields[field]);
  rset->fields[field] = str;
  errno = 0;
}
void	rset_setrec(rset_t* rset, unsigned int rnum, const char* s, char sep)
{
  int i = 0;
  char* next;

  if (NULL == rset || NULL == rset->records || rnum >= rset->num_records)
    return;
  if (NULL != rset->records[rnum])
  {
    for (i = 0; i < rset->num_fields; i++)
      free(rset->records[rnum][i]);
    free(rset->records[rnum]);
  }
  rset->records[rnum] = malloc(sizeof(char*) * rset->num_fields);
  if (NULL == rset->records[rnum])
  {
    rset->num_records = 0;
    return;
  }
  bzero(rset->records[rnum], sizeof(char*) * rset->num_fields);
  if (NULL == s)
    return;
  i = 0;
  do
  {
    next = strchr(s, sep);
    if (NULL == next)
    {
      rset->records[rnum][i] = strdup(s);
      break;
    } else
      rset->records[rnum][i] = strndup(s, next - s);
    s = next + 1;
    i++;
  } while (i < rset->num_fields && NULL != s);
}
void	rset_setval(rset_t* rset, unsigned int rec, unsigned int field,
		    const char* fmt, ...)
{
  char* str = NULL;
  va_list ap;

  if (NULL == rset || NULL == fmt || NULL == rset->records)
  {
    errno = EFAULT;
    return;
  }
  if (rec >= rset->num_records || field >= rset->num_fields)
  {
    errno = EINVAL;
    return;
  }
  if (NULL == rset->records[rec])
  {
    errno = EFAULT;
    return;
  }
  va_start(ap, fmt);
  vasprintf(&str, fmt, ap);
  va_end(ap);
  if (NULL == str)
    return;
  free(rset->records[rec][field]);
  rset->records[rec][field] = str;
  errno = 0;
}


void	rsetpool_add(rset_t** pool, rset_t* rset)
{
  int cmp = -1;
  rset_t* prev;

  if (NULL == pool || NULL == rset)
    return;
  /* once it's in the pool, we have full control, so we can free it */
  if (NULL == rset->name)
  {
    rset_free(rset);
    return;
  }
  /* keep the rsets sorted, for easier searching */
  if (NULL == *pool || (cmp = strcmp(rset->name, (*pool)->name)) <= 0)
  {
    if (!cmp)
    {
      rset->next = (*pool)->next;
      rset_free(*pool);
    } else
      rset->next = *pool;
    *pool = rset;
    return;
  }
  for (prev = *pool; NULL != prev->next; prev = prev->next)
    if ((cmp = strcmp(rset->name, prev->next->name)) <= 0)
      break;
  /* replace rset if already in the pool */
  if (!cmp)
  {
    rset->next = prev->next->next;
    rset_free(prev->next);
  } else
    rset->next = prev->next;
  prev->next = rset;
}
rset_t*	rsetpool_del(rset_t** pool, const char* rset_name)
{
  int cmp = -1;
  rset_t* prev,* ret;

  if (NULL == pool || NULL == rset_name || NULL == *pool)
    return NULL;
  cmp = strcmp(rset_name, (*pool)->name);
  if (cmp < 0)
    return NULL;	/* not found */
  if (!cmp)
  {
    ret = *pool;
    *pool = ret->next;
    ret->next = NULL;
    return ret;
  }
  cmp = -1;
  for (prev = *pool; NULL != prev->next; prev = prev->next)
    if ((cmp = strcmp(rset_name, prev->next->name)) <= 0)
      break;
  if (cmp < 0)
    return NULL;	/* not found */
  ret = prev->next;
  prev->next = ret->next;
  ret->next = NULL;
  return ret;
}
rset_t*	rsetpool_find(rset_t** pool, const char* rset_name)
{
  int cmp = -1;
  rset_t* rset;

  if (NULL == pool || NULL == rset_name)
    return NULL;
  for (rset = *pool; NULL != rset; rset = rset->next)
  {
    cmp = strcmp(rset_name, rset->name);
    if (cmp < 0)
      break;
    if (!cmp)
      return rset;
  }
  return NULL;
}
