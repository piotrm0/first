#ifndef __RSET_H__
#define __RSET_H__

#include <kiwi/types.h>
#include <stdio.h>


typedef struct rset_s
{
  unsigned int	num_fields, num_records;	/* columns, rows */
  char*		name;
  char**	fields;
  char***	records;
  struct rset_s* next;		/* for rset pools only */
} rset_t;


int	rset_validname(const char* key);
rset_t*	rset_new(const char* name, unsigned int fields, unsigned int recs);
void	rset_free(rset_t* rset);
void	rset_resize(rset_t* rset, unsigned int fields, unsigned int recs);
void	rset_empty(rset_t* rset);
void	rset_setfields(rset_t* rset, const char* str, char sep);
void	rset_setfield(rset_t* rset, unsigned int field, const char* fmt, ...);
void	rset_setrec(rset_t* rset, unsigned int rnum, const char* s, char sep);
void	rset_setval(rset_t* rset, unsigned int rec, unsigned int field,
		    const char* fmt, ...);

/* the following only apply to rset pools, not individual rsets */
void	rsetpool_add(rset_t** pool, rset_t* rset);
rset_t*	rsetpool_del(rset_t** pool, const char* rset_name);
rset_t*	rsetpool_find(rset_t** pool, const char* rset_name);

#endif /* __RSET_H__ */
