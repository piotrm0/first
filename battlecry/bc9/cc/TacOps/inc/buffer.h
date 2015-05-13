#ifndef __BUFFER_H__
#define __BUFFER_H__

#include <kiwi/types.h>
#include <stdarg.h>


/* terminal properties */
typedef struct
{
  unsigned int	interactive : 1;	/* should prompt? */
  unsigned int	CR : 1;
  unsigned int	LF : 1;
  unsigned int	NUL : 1;
  uint16_t	width, height;	/* size of terminal window */
} termprop_t ;

typedef struct
{
  uint32_t	size;	/* allocated */
  uint32_t	len;	/* length, filled */
  uint8_t*	ptr;
  termprop_t*	term;	/* optional */
} buffer_t;

typedef struct
{
  unsigned int	min_width;	/* after removing margins */
  unsigned int	lmargin;	/* start of first line */
  unsigned int	rmargin;	/* relative to width */
  int		indent;		/* added to lmargin on successive lines */
} win_fmt_params_t;


/* NOTE: appendx() is raw output, rest all convert \n to CR/LF/NUL */
buffer_t*	buf_new(uint32_t expected_size);
void		buf_free(buffer_t* buffer);
void		buf_resize(buffer_t* buffer, uint32_t expected_size);
void		buf_consume(buffer_t* buffer, uint32_t bytes, uint32_t off);
void		buf_appendf(buffer_t* buffer, const char* fmt, ...);
void		buf_append(buffer_t* buffer, const char* str);
void		buf_appendx(buffer_t* buffer, const void* p, uint32_t bytes);
void		buf_append_eol(buffer_t* buffer);
int	buf_appendf_wrap(buffer_t* buffer, win_fmt_params_t* win_fmt,
			 const char* fmt, ...);
void		buf_prependf(buffer_t* buffer, const char* fmt, ...);
void		buf_prependx(buffer_t* buffer, const void* p, uint32_t bytes);

#endif /* __BUFFER_H__ */
