/*
 *	network_addr.c - asynchronous network addressing
 *	Project:	TacOps, v3.0
 *	Authors:	Rick C. Petty
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
 * $Id: network_addr.c,v 1.2 2004/02/20 01:47:00 rick Exp $
 */

#include <kiwi/errno.h>
#include <kiwi/network.h>
#include <kiwi/string.h>

const char*	NETWORKADDR_BROADCAST =	"255.255.255.255";
const char*	NETWORKADDR_ANY =	"0.0.0.0";
const char*	NETWORKADDR_LOOPBACK =	"127.0.0.1";


char*	network_addrcpy_noport(const char* addr)
{
  char* ret,* str;

  if (NULL == addr)
  {
    errno = EFAULT;
    return NULL;
  }
  if (NULL == (ret = strdup(addr)))
    return NULL;
  if (
#ifndef WIN32
      '/' != *ret &&
#endif /* not WIN32 */
      NULL != (str = strchr(ret, ':')))
    *str = '\0';
  return ret;
}

int	network_addr2ascii(const sockaddr_t* addr, char** ascii)
{
  struct sockaddr_in* sin;
  struct sockaddr_un* sun;
  unsigned int len;
  char dup[1024];

  if (NULL == addr || NULL == ascii)
    return EFAULT;
#if 0	// should be freed by the caller!
  if (NULL != *ascii)
    free(*ascii);
#endif
  *ascii = NULL;
  len = sizeof(addr->addr) - sizeof(addr->addr.sa_data);
  if (addr->len <= len)
    return EINVAL;
  switch (addr->addr.sa_family) {
#ifndef WIN32
  case AF_LOCAL:
    len = addr->len - len;
    sun = (struct sockaddr_un*)&addr->addr;
    if (NULL == (*ascii = strndup(sun->sun_path, len)))
      return errno;
    return 0;
#endif /* not WIN32 */
  case AF_INET:
    sin = (struct sockaddr_in*)&addr->addr;
//    sin->sin_port = ntohs(sin->sin_port);
    if (!sin->sin_port)
      sprintf(dup, "%s", INADDR_ANY == ntohl(sin->sin_addr.s_addr) ?
		NETWORKADDR_ANY : inet_ntoa(sin->sin_addr));
    else
      sprintf(dup, "%s:%u", INADDR_ANY == ntohl(sin->sin_addr.s_addr) ?
		NETWORKADDR_ANY : inet_ntoa(sin->sin_addr),
	      ntohs(sin->sin_port));
    NETWORK_REPORT_ERROR();
    if (NULL == (*ascii = strdup(dup)))
      return errno;
    return 0;
  default:
    return EPROTONOSUPPORT;
  }
}
int	network_ascii2addr(const char* ascii, sockaddr_t** addr)
{
  struct sockaddr_in* sin;
#ifndef WIN32
  struct sockaddr_un* sun;
#endif /* not WIN32 */
  sockaddr_t* aaddr;
  struct hostent* ent;
  char* dup,* p,* q;

  if (NULL == ascii || NULL == addr)
    return EFAULT;
#if 0	// should be freed by the caller!
  if (NULL != *addr)
    free(*addr);
#endif
  *addr = NULL;
  if ('/' == *ascii)
  {
#ifdef WIN32
    return EPROTONOSUPPORT;
#else /* not WIN32 */
    if (strlen(ascii) >= sizeof(sun->sun_path))
      return ENAMETOOLONG;
    if (NULL == (aaddr = (sockaddr_t*)malloc(sizeof(*sun) +
					     SOCKADDR_EXTRALEN)))
      return errno;
    sun = (struct sockaddr_un*)&aaddr->addr;
    memset(sun, 0, sizeof(*sun));
    sun->sun_family = AF_LOCAL;
    strcpy(sun->sun_path, ascii);
    sun->sun_len = sizeof(*sun) - sizeof(sun->sun_path) +
		   strlen(sun->sun_path) + 1;
    aaddr->len = sun->sun_len;
    *addr = aaddr;
    return 0;
#endif /* not WIN32 */
  }
  dup = strdup(ascii);
  if (NULL == dup)
    return errno;
  if (NULL == (aaddr = (sockaddr_t*)malloc(sizeof(*sin) +
					   SOCKADDR_EXTRALEN)))
  {
    free(dup);
    return errno;
  }
  sin = (struct sockaddr_in*)&aaddr->addr;
  memset(sin, 0, sizeof(*sin));
  aaddr->len = sizeof(*sin);
#ifndef WIN32
  sin->sin_len = aaddr->len;
#endif /* not WIN32 */
  sin->sin_family = AF_INET;
  sin->sin_port = 0;
  if (NULL != (p = strchr(dup, ':')))
  {
    *p++ = '\0';
    sin->sin_port = htons(strtol(p, &q, 0));
    if (p == q || NULL == q)
    {
      free(dup);
      free(sin);
      return EILSEQ;
    }
  }
  if (strlen(dup) < 1)
  {
    free(dup);
    sin->sin_addr.s_addr = INADDR_ANY;
    *addr = aaddr;
    return 0;
  }
#ifndef WIN32
  if (inet_aton(dup, &sin->sin_addr))
  {
    free(dup);
    *addr = aaddr;
    return 0;
  }
#endif /* not WIN32 */
  if (NULL == (ent = gethostbyname(dup)))
  {
    NETWORK_REPORT_ERROR();
#ifndef WIN32
    errno = h_errno;
#endif /* not WIN32 */
    free(dup);
    free(sin);
    return errno;
  }
  free(dup);
  if (AF_INET != ent->h_addrtype)
  {
    free(sin);
    return EPROTONOSUPPORT;
  }
  if (ent->h_length > sizeof(in_addr_t))
  {
    free(sin);
    return EOVERFLOW;
  }
  memset(&sin->sin_addr.s_addr, 0, sizeof(in_addr_t));
  memcpy(&sin->sin_addr.s_addr, ent->h_addr, ent->h_length);
  *addr = aaddr;
  return 0;
}
int	network_sockaddr(socket_t sock, char** ascii)
{
  sockaddr_t addr;
  socklen_t len;

  if (NULL == ascii)
    return errno = EFAULT;
  if (SOCKET_INVALID == sock)
    return errno = EINVAL;
  len = sizeof(addr) - SOCKADDR_EXTRALEN;
  addr.addr.sa_len = len;
  if (getsockname(sock, &addr.addr, &len))
    return errno;
  addr.len = len;
  return errno = network_addr2ascii(&addr, ascii);
}
