/*
 *	string.h - string-related functionality
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
 * $Id: string.h,v 1.2 2004/02/06 04:25:14 rick Exp $
 */

#ifndef __KIWI_STRING_H__
#define __KIWI_STRING_H__

#include <kiwi/types.h>
#include <stdlib.h>
#include <string.h>


BEGIN_DECLS
void*	memdup(const void* src, size_t len);


/***  character conversions routines  ***/
char	hex2char(int h);
int	char2hex(char c);	/* returns -1 if unknown */
int	c2hex(char c);		/* returns  0 if unknown */

/***  string routines  ***/
void	str2lowercase(char* str);
void	str2uppercase(char* str);
void	strchop(char* str);	/* remove last byte of string */
void	strchomp(char* str);
unsigned int
	strlength(const char* str);	/* accepts NULL strings */
char*	strndup(const char* str, unsigned int len);
char*	strnrchr(const char* s, int c, size_t len);
char**	strsplit(const char* str, char sep);

END_DECLS

#endif /* __KIWI_STRING_H__ */
