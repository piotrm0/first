#include "buffer.h"
#include <errno.h>
#include <kiwi/string.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>


buffer_t*	buf_new(uint32_t expected_size)
{
  buffer_t* ret = malloc(sizeof(buffer_t));
  if (NULL == ret)
    return NULL;
  bzero(ret, sizeof(buffer_t));
  buf_resize(ret, expected_size);
  if (ret->size < expected_size)
  {
    buf_free(ret);
    return NULL;
  }
  errno = 0;
  return ret;
}
void		buf_free(buffer_t* buffer)
{
  if (NULL == buffer)
    return;
  if (NULL != buffer->ptr)
    free(buffer->ptr);
  free(buffer);
  errno = 0;
}
void		buf_resize(buffer_t* buffer, uint32_t expected_size)
{
  uint8_t* ptr;

  if (NULL == buffer)
    return;
  if (!expected_size)
    expected_size = 1024;
  if (NULL == buffer->ptr)
    buffer->size = 0;
  errno = 0;
  if (expected_size < buffer->size)
    return;
  ptr = realloc(buffer->ptr, expected_size);
  if (NULL == ptr)
    return;
  buffer->size = expected_size;
  buffer->ptr = ptr;
}
void		buf_consume(buffer_t* buffer, uint32_t bytes, uint32_t off)
{
  if (NULL == buffer || off >= buffer->len)
    return;
  if (!bytes || off + bytes > buffer->len)
    bytes = buffer->len - off;
  if (bytes + off < buffer->len)
    memmove(buffer->ptr + off, buffer->ptr + off + bytes,
	    buffer->len - bytes - off);
  buffer->len -= bytes;
}
void		buf_appendf(buffer_t* buffer, const char* fmt, ...)
{
  va_list ap;
  char* str = NULL;

  if (NULL == buffer || NULL == fmt)
    return;
  va_start(ap, fmt);
  vasprintf(&str, fmt, ap);
  va_end(ap);
  if (NULL == str)
    return;
  buf_append(buffer, str);
  free(str);
}
void		buf_append(buffer_t* buffer, const char* str)
{
  uint32_t len;
  char* p;

  if (NULL == buffer || NULL == str)
    return;
  while (NULL != (p = strchr(str, '\n')))
  {
    /* translate \n into proper EOL convention */
    buf_appendx(buffer, str, p - str);
    buf_append_eol(buffer);
    str = p + 1;
  }
  len = strlen(str) + 1;	/* make sure to copy over the '\0' */
  buf_appendx(buffer, str, len);
  buffer->len--;	/* don't include the '\0' in the length */
  errno = 0;
}
void		buf_appendx(buffer_t* buffer, const void* p, uint32_t bytes)
{
  if (NULL == buffer || NULL == p || 0 == bytes)
    return;
  if (NULL == buffer->ptr || buffer->len + bytes >= buffer->size)
  {
    buf_resize(buffer, buffer->size << 1);
    if (buffer->len + bytes >= buffer->size)
      return;	/* ?? disallow huge increases in buffer size */
  }
  memcpy(buffer->ptr + buffer->len, p, bytes);
  buffer->len += bytes;
  errno = 0;
}
void	buf_append_eol(buffer_t* buffer)
{
  char eol_chars[4] = "\n";
  unsigned int len = 1;

  if (NULL == buffer)
    return;
  if (NULL != buffer->term &&
      (buffer->term->CR || buffer->term->LF || buffer->term->NUL))
  {
    len = 0;
    if (buffer->term->CR)
      eol_chars[len++] = '\r';
    if (buffer->term->LF)
      eol_chars[len++] = '\n';
    if (buffer->term->NUL)
      eol_chars[len++] = '\0';
  }
  buf_appendx(buffer, eol_chars, len);
}
int	buf_appendf_wrap(buffer_t* buffer, win_fmt_params_t* win_fmt,
			 const char* fmt, ...)
{
  va_list ap;
  win_fmt_params_t empty_win_fmt = {};
  char* text = NULL;
  char* str1,* str2;
  int len, line_start, indent;
  int width = 0;

  if (NULL == buffer || NULL == fmt)
    return errno = EFAULT;
  if (NULL == win_fmt)
    win_fmt = &empty_win_fmt;
  va_start(ap, fmt);
  vasprintf(&text, fmt, ap);
  va_end(ap);
  if (NULL == text)
    return errno;
  if (NULL != buffer->term)
    width = buffer->term->width;
  if (!width)
    width = 80;
  if (width < win_fmt->lmargin + win_fmt->rmargin + win_fmt->min_width)
    width = win_fmt->lmargin + win_fmt->rmargin + win_fmt->min_width;
  if (width < win_fmt->indent + win_fmt->rmargin + win_fmt->min_width)
    width = win_fmt->indent + win_fmt->rmargin + win_fmt->min_width;
  line_start = win_fmt->lmargin;
  width -= win_fmt->rmargin;
  indent = win_fmt->indent + win_fmt->lmargin;
  while ((len = strlen(text)) > width - line_start)
  {

    if (NULL != (str1 = strchr(text, '\n')))
    {
      if (str1 - text < width - line_start)
      {
	buf_appendf(buffer, "%*.*s\n", str1 - text, str1 - text, text);
	text = str1 + 1;	/* advance pointer past LF */
	goto pretty_next_line;
      }
    }
    str1 = strnrchr(text, ' ', width - line_start);
    str2 = strnrchr(text, '\t', width - line_start);
    if (NULL == str1 && NULL == str2)
    {
      // someday: add hyphenation here
      buf_appendf(buffer, "%*.*s\n", width - line_start - 1,
		  width - line_start - 1, text);
      text += width - line_start - 1;	/* advance */
      goto pretty_next_line;
    }
    if (str2 - text > str1 - text)
      str1 = str2;	/* pick the one with the most chars this line */
    buf_appendf(buffer, "%*.*s\n", str1 - text, str1 - text, text);
    text = str1 + 1;	/* advance */
pretty_next_line:
    line_start = indent;	/* start next line @ indent */
    buf_appendf(buffer, "%*.*s", indent, indent, "");
  } /* all that's left is to finish off the string */
  while (NULL != (str1 = strchr(text, '\n')))
  {
    buf_appendf(buffer, "%*.*s\n", str1 - text, str1 - text, text);
    text = str1 + 1;	/* advance past LF */
  }
  buf_appendf(buffer, "%s", text);
  return errno = 0;
}
void		buf_prependf(buffer_t* buffer, const char* fmt, ...)
{
  va_list ap;
  char* str = NULL;

  if (NULL == buffer || NULL == fmt)
    return;
  va_start(ap, fmt);
  vasprintf(&str, fmt, ap);
  va_end(ap);
  if (NULL == str)
    return;
  buf_prependx(buffer, str, strlen(str));
  free(str);
}
void		buf_prependx(buffer_t* buffer, const void* p, uint32_t bytes)
{
  if (NULL == buffer || NULL == p || 0 == bytes)
    return;
  if (NULL == buffer->ptr || buffer->len + bytes >= buffer->size)
  {
    buf_resize(buffer, buffer->size << 1);
    if (buffer->len + bytes >= buffer->size);
      return;	/* ?? disallow huge increases in buffer size */
  }
  if (buffer->len)
    memmove(buffer->ptr + bytes, buffer->ptr, buffer->len);
  else
    buffer->ptr[bytes] = '\0';
  memcpy(buffer->ptr, p, bytes);
  buffer->len += bytes;
  errno = 0;
}
