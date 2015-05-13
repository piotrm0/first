/*
 *	errno.h - error handling functions and defines
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
 * $Id: errno.h,v 1.1 2004/02/06 04:25:14 rick Exp $
 */

#ifndef __KIWI_ERRNO_H__
#define __KIWI_ERRNO_H__

#include <kiwi/types.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef WIN32
#include <winsock2.h>
#endif /* WIN32 */

/***  missing error numbers  ***/
#ifdef KIWI_ERRNO
const kiwi_errorlist_t kiwi_errorlist[] = {
#else /* no KIWI_ERRNO */
#define KIWI_ERRNO(num,name,str)	name = num
enum {
#endif /* no KIWI_ERRNO */
#ifdef WIN32
#define KIWI_ERRNO_WSA(name,str)	\
		KIWI_ERRNO(CONCAT(WSA,name),name,str)
#endif /* WIN32 */
  KIWI_ERRNO(  0, ENONE,	"No error"),
#ifdef WIN32
  KIWI_ERRNO( 15, ENOTBLK,	"Block device required"),
  KIWI_ERRNO( 26, ETXTBSY,	"Text file busy"),
  KIWI_ERRNO( 36, EINPROGRESS,	"Operation now in progress"),
  KIWI_ERRNO_WSA( EWOULDBLOCK,	"Resource temporarily unavailable"),
  KIWI_ERRNO_WSA( EALREADY,	"Operation already in progress"),
  KIWI_ERRNO_WSA( ENOTSOCK,	"Socket operation on non-socket"),
  KIWI_ERRNO_WSA( EDESTADDRREQ,	"Destination address required"),
  KIWI_ERRNO_WSA( EMSGSIZE,	"Message too long"),
  KIWI_ERRNO_WSA( EPROTOTYPE,	"Protocol wrong type for socket"),
  KIWI_ERRNO_WSA( ENOPROTOOPT,	"Protocol not available"),
  KIWI_ERRNO_WSA( EPROTONOSUPPORT, "Protocol not supported"),
  KIWI_ERRNO_WSA( EOPNOTSUPP,	"Operation not supported"),
  KIWI_ERRNO_WSA( ETOOMANYREFS,	"Too many references"),
  KIWI_ERRNO_WSA( EREMOTE,	"Remote error"),
  KIWI_ERRNO( 79, EFTYPE,	"Inappropriate file type or format"),
  KIWI_ERRNO( 80, EAUTH,	"Authentication error"),
  KIWI_ERRNO( 84, EOVERFLOW,	"Value too large to be stored in data type"),
  KIWI_ERRNO( 85, ECANCELED,	"Operation canceled"),
  KIWI_ERRNO( 87, ENOATTR,	"Attribute not found"),
  KIWI_ERRNO( 88, EDOOFUS,	"Programming error"),
  KIWI_ERRNO_WSA( SYSNOTREADY,	"System not ready"),
  KIWI_ERRNO_WSA( VERNOTSUPPORTED, "Winsock version not supported"),
  KIWI_ERRNO_WSA( NOTINITIALISED, "Winsock not initialized"),
  KIWI_ERRNO_WSA( EDISCON,	"Disconnected"),
#endif /* not WIN32 */
#ifdef __APPLE__
  KIWI_ERRNO(200, EDOOFUS,	"Programming error"),
#endif /* not __APPLE__ */
  /***  this must be the last defined error  ***/
  KIWI_ERRNO( -1, EERROR,	"An error occurred")
};


BEGIN_DECLS

void	perr(const char* format, ...);
void	pexit(const char* format, ...);
const char*	strerr(int error);

END_DECLS

#endif /* __KIWI_ERRNO_H__ */
