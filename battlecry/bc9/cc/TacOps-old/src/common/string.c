/*
 *	string.c - general utility functions
 *	Project:	KIWI, useful items for platform-independence
 *	Author:		Rick C. Petty
 *
 * Copyright (C) 1993-2004 KIWI Computer.  All rights reserved.
 *
 * Please read the enclosed COPYRIGHT notice and LICENSE agreements, if
 * available.  All software and documentation in this file is protected
 * under applicable law as stated in the aforementioned files.  If not
 * included with this distribution, you can obtain these files, this
 * package, and source code for this and related projects from:
 *
 * http://www.kiwi-computer.com/
 *
 * $Id: string.c,v 1.2 2004/02/06 04:26:19 rick Exp $
 */

#include <kiwi/string.h>
#include <ctype.h>
#include <stdlib.h>


void*	memdup(const void* src, size_t len)
{
  void* dst;

  if (NULL == (dst = malloc(len)))
    return NULL;
  memcpy(dst, src, len);
  return dst;
}


char	hex2char(int h)
{
  return "0123456789abcdef"[h & 15];
}
int	char2hex(char c)
{
  return -'b' +
	"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	"aaaaaaaaaaaaaaaabcdefghijkaaaaaa"
	"almnopqaaaaaaaaaaaaaaaaaaaaaaaaa"
	"almnopqaaaaaaaaaaaaaaaaaaaaaaaaa"[c & 127];
}
int	c2hex(char c)
{
  return -'a' +
	"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	"aaaaaaaaaaaaaaaaabcdefghijaaaaaa"
	"aklmnopaaaaaaaaaaaaaaaaaaaaaaaaa"
	"aklmnopaaaaaaaaaaaaaaaaaaaaaaaaa"[c & 127];
}


/*
 *  string routines
 */
void	str2lowercase(char* str)
{
  if (NULL == str)
    return;
  while ('\0' != *str)
  {
    *str = tolower(*str);
    str++;
  }
}
void	str2uppercase(char* str)
{
  if (NULL == str)
    return;
  while ('\0' != *str)
  {
    *str = toupper(*str);
    str++;
  }
}
void	strchop(char* str)
{
  int len = strlength(str);

  if (!len)
    return;
  str[len - 1] = '\0';
}
void	strchomp(char* str)
{
  int i = strlength(str), j = 0;

  while (i-- > 0 && j++ < 2 && ('\r' == str[i] || '\n' == str[i]))
    str[i] = '\0';
}
char*	strndup(const char* str, unsigned int len)
{
  char* ret;

  ret = (char*)malloc(len + 1);
  if (NULL == ret)
    return NULL;
  strncpy(ret, str, len);
  ret[len] = '\0';
  return ret;
}
char*	strnrchr(const char* s, int c, size_t len)
{
  if (NULL == s)
    return NULL;
  for (--len; len>= 0; len--)
    if (c == s[len])
      return (char*)(s + len);
  return NULL;
}
unsigned int	strlength(const char* str)
{
  if (NULL == str)
    return 0;
  return strlen(str);
}
char**	strsplit(const char* str, char sep)
{
  char** ret = NULL,** new,* next;
  unsigned int size = 0;

  if (NULL == str)
    return NULL;
  do
  {
    size++;
    new = realloc(ret, sizeof(char*) * (size + 1));
    if (NULL == new)
    {
      free(ret);
      return NULL;
    }
    ret = new;
    next = strchr(str, sep);
    if (NULL == next)
      ret[size - 1] = strdup(str);
    else
      ret[size - 1] = strndup(str, next - str - 1);
    str = next;
  } while (NULL != str);
  ret[++size] = NULL;
  return ret;
}
