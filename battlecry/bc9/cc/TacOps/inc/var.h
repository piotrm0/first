#ifndef __VAR_H__
#define __VAR_H__

#include <kiwi/types.h>
#include <stdarg.h>


#define	VAR_INDEX_INVALID	((uint16_t)-1)
typedef struct
{
  uint16_t	count;	/* number of variables */
  char**	keys;	/* sorted list of keys */
  char**	values;
} varset_t;


int		var_validname(const char* key);
varset_t*	var_new(void);
void		var_free(varset_t* vars);
uint16_t	var_find(varset_t* vars, const char* key);
const char*	var_get(varset_t* vars, const char* key);
void		var_set(varset_t* vars, const char* key, const char* value);
void		var_unset(varset_t* vars, const char* key);

#endif /* __VAR_H__ */
