#include "var.h"
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>


int		var_validname(const char* key)
{
  int ch;

  if (NULL == key || '\0' == *key)
    return 0;
  while ('\0' != (ch = *key++))
    if (!isalnum(ch) && NULL == strchr("./_", ch))
      return 0;
  return 1;
}
varset_t*	var_new(void)
{
  varset_t* vars = malloc(sizeof(varset_t));
  if (NULL == vars)
    return NULL;
  bzero(vars, sizeof(varset_t));
  return vars;
}
void		var_free(varset_t* vars)
{
  if (NULL == vars)
    return;
  free(vars->keys);
  free(vars->values);
  bzero(vars, sizeof(varset_t));
  free(vars);
}
uint16_t	_var_findcmp(varset_t* vars, const char* key, int* cmp)
{
  uint16_t index;
  int mycmp, first, last;

  if (NULL == cmp)
    cmp = &mycmp;
  *cmp = mycmp = -1;
  index = 0;
  if (NULL == vars || NULL == key)
    return index;
  first = 0;
  last = vars->count - 1;

  /* binary search */
  while (last >= first)
  {
    index = (first + last) >> 1;
    mycmp = strcmp(key, vars->keys[index]);
    if (!mycmp)
    {
      *cmp = mycmp;
      return index;
    }
    if (mycmp < 0)
      last = index - 1;
    else
      first = index + 1;
  }
  if (mycmp > 0)
    index++;
  *cmp = mycmp;
  return index;
}
uint16_t	var_find(varset_t* vars, const char* key)
{
  int cmp;
  uint16_t index;

  if (NULL == vars || NULL == key)
    return VAR_INDEX_INVALID;
  if (NULL == vars->keys || NULL == vars->values)
    vars->count = 0;
  if (vars->count < 1)
    return VAR_INDEX_INVALID;
  index = _var_findcmp(vars, key, &cmp);
  if (!cmp)
    return index;
  return VAR_INDEX_INVALID;
}
const char*	var_get(varset_t* vars, const char* key)
{
  uint16_t index;

  if (NULL == vars || NULL == key || NULL == vars->values)
    return NULL;
  index = var_find(vars, key);
  if (index >= vars->count)
    return NULL;
  return vars->values[index];
}
void		var_set(varset_t* vars, const char* key, const char* value)
{
  uint16_t index;
  int cmp = -1;
  char** keys,** values;

  if (NULL == vars || NULL == key)
    return;
  if (NULL == value)
  {
    var_unset(vars, key);
    return;
  }
  if (NULL == vars->keys || NULL == vars->values)
    vars->count = 0;
  index = _var_findcmp(vars, key, &cmp);
  if (!cmp)
  {
    free(vars->values[index]);
    vars->values[index] = strdup(value);
    return;
  }

  keys = malloc(sizeof(char*) * (vars->count + 1));
  values = malloc(sizeof(char*) * (vars->count + 1));
  if (NULL == keys || NULL == values)
  {
    free(keys);
    return;
  }
  memcpy(keys, vars->keys, sizeof(char*) * index);
  memcpy(values, vars->values, sizeof(char*) * index);
  keys[index] = strdup(key);
  values[index] = strdup(value);
  if (NULL == keys[index])
  {
    free(keys);
    free(values);
    return;
  }
  memcpy(keys + index + 1, vars->keys + index,
	 sizeof(char*) * (vars->count - index));
  memcpy(values + index + 1, vars->values + index,
	 sizeof(char*) * (vars->count - index));
  free(vars->keys);
  free(vars->values);
  vars->keys = keys;
  vars->values = values;
  vars->count++;
}
void		var_unset(varset_t* vars, const char* key)
{
  uint16_t index, count;

  if (NULL == vars || NULL == key)
    return;
  index = var_find(vars, key);
  if (index >= vars->count || NULL == vars->keys || NULL == vars->values)
    return;
  count = vars->count - index - 1;
  memcpy(vars->keys + index, vars->keys + index + 1, count);
  memcpy(vars->values + index, vars->values + index + 1, count);
  vars->count--;
}
