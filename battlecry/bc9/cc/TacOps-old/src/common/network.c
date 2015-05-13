/*
 *	network.c - common functions for asynchronous networking
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
 * $Id: network.c,v 1.3 2004/02/22 19:32:22 rick Exp $
 */

#include <kiwi/network.h>
#include <kiwi/string.h>


/***  cross-platform asynchronous network sockets  ***/
int	network_init(void)
{
  static int startup_flag = 0;		/* boolean */
#ifdef WIN32
  WORD wVersionRequested = MAKEWORD(1,1);
  WSADATA wsaData;
#endif /* WIN32 */

  if (startup_flag)
    return 0;
#ifdef WIN32
  if (WSAStartup(wVersionRequested, &wsaData))
  {
    NETWORK_REPORT_ERROR();
    perr("Unable to start WinSockAgent");
    return errno;
  }
#endif /* WIN32 */
  startup_flag = 1;
  return 0;
}
socket_t network_socket(int domain, int type, int protocol)
{
  int error;
  socket_t sock;
#ifdef WIN32
  unsigned long flag = 1;
#endif /* WIN32 */
  unsigned int enable = 1;

  if (0 != (errno = network_init()))
    return SOCKET_INVALID;
  if (SOCKET_INVALID == (sock = socket(domain, type, protocol)))
  {
    NETWORK_REPORT_ERROR();
    return SOCKET_INVALID;
  }
  /***  make the socket non-blocking  ***/
#ifdef WIN32
  if (ioctlsocket(sock, FIONBIO, &flag))
  {
#else /* not WIN32 */
  if (fcntl(sock, F_SETFL, O_NONBLOCK))
  {
#endif /* not WIN32 */
    NETWORK_REPORT_ERROR();
    error = errno;
    network_close(sock);
    errno = error;
    return SOCKET_INVALID;
  }
  if (setsockopt(sock, SOL_SOCKET, SO_REUSEPORT,
		 (void*)&enable, sizeof(enable)))
  {
    NETWORK_REPORT_ERROR();
    error = errno;
    network_close(sock);
    errno = error;
    return SOCKET_INVALID;
  }
  return sock;
}
int	network_broadcast(socket_t sock, boolean_t enable_flag)
{
  int enable = enable_flag != 0;

  if (SOCKET_INVALID == sock)
    return errno = EBADF;
  if (setsockopt(sock, SOL_SOCKET, SO_BROADCAST,
		 (void*)&enable, sizeof(enable)))
  {
    NETWORK_REPORT_ERROR();
    return errno;
  }
  return 0;
}
int	network_bind(socket_t sock, const sockaddr_t* local)
{
  if (SOCKET_INVALID == sock)
    return errno = EBADF;
  if (NULL == local)
    return errno = EFAULT;
  if (bind(sock, &local->addr, local->len))
  {
    NETWORK_REPORT_ERROR();
    return errno;
  }
  return 0;
}
int	network_connect(socket_t sock, const sockaddr_t* remote)
{
  if (SOCKET_INVALID == sock)
    return errno = EBADF;
  if (NULL == remote)
    return errno = EFAULT;
  if (connect(sock, &remote->addr, remote->len))
  {
    NETWORK_REPORT_ERROR();
    return errno;
  }
  return 0;
}
int	network_listen(socket_t sock, unsigned int backlog)
{
  if (SOCKET_INVALID == sock)
    return errno = EBADF;
  if (listen(sock, backlog))
  {
    NETWORK_REPORT_ERROR();
    return errno;
  }
  return 0;
}
socket_t network_accept(socket_t sock, sockaddr_t** remote)
{
  socklen_t len = 1024;
  byte buffer[len];
  socket_t ret;

  if (SOCKET_INVALID == sock)
  {
    errno = EBADF;
    return SOCKET_INVALID;
  }
  if (NULL != remote)
    *remote = NULL;
  ret = accept(sock, (struct sockaddr*)buffer, &len);
  NETWORK_REPORT_ERROR();
  if (SOCKET_INVALID == ret)
    return SOCKET_INVALID;
  if (NULL == remote)
    return ret;
  if (NULL == (*remote = (sockaddr_t*)malloc(len + SOCKADDR_EXTRALEN)))
  {
    close(ret);
    return SOCKET_INVALID;
  }
  (*remote)->len = len;
  memcpy(&(*remote)->addr, buffer, len);
#ifndef WIN32
  if ((*remote)->addr.sa_len > len)
    (*remote)->addr.sa_len = len;
#endif /* not WIN32 */
  return ret;
}
ssize_t	network_recv(socket_t sock, void* buffer, size_t len)
{
  ssize_t bytes;

  if (SOCKET_INVALID == sock)
  {
    errno = EBADF;
    return -1;
  }
  if (NULL == buffer)
  {
    errno = EFAULT;
    return -1;
  }
  bytes = recv(sock, buffer, len, 0);
  NETWORK_REPORT_ERROR();
  return bytes;
}
ssize_t	network_recvfrom(socket_t sock, void* buffer, size_t len,
			 sockaddr_t** remote)
{
  ssize_t bytes;
  socklen_t socklen = 1024;
  byte sockaddr[len];

  if (SOCKET_INVALID == sock)
  {
    errno = EBADF;
    return -1;
  }
  if (NULL == buffer || NULL == remote)
  {
    errno = EFAULT;
    return -1;
  }
  *remote = NULL;
  bytes = recvfrom(sock, buffer, len, 0,
		   (struct sockaddr*)sockaddr, &socklen);
  NETWORK_REPORT_ERROR();
  if (bytes < 0 ||
      NULL == (*remote = (sockaddr_t*)malloc(socklen + SOCKADDR_EXTRALEN)))
    return -1;
  (*remote)->len = socklen;
  memcpy(&(*remote)->addr, buffer, socklen);
#ifndef WIN32
  if ((*remote)->addr.sa_len > len)
    (*remote)->addr.sa_len = len;
#endif /* not WIN32 */
  return bytes;
}
ssize_t	network_send(socket_t sock, const void* buffer, size_t len)
{
  ssize_t bytes;

  if (SOCKET_INVALID == sock)
  {
    errno = EBADF;
    return -1;
  }
  if (NULL == buffer)
  {
    errno = EFAULT;
    return -1;
  }
  bytes = send(sock, buffer, len, 0);
  NETWORK_REPORT_ERROR();
  return bytes;
}
ssize_t	network_sendto(socket_t sock, const void* buffer, size_t len,
		       const sockaddr_t* remote)
{
  ssize_t bytes;

  if (SOCKET_INVALID == sock)
  {
    errno = EBADF;
    return -1;
  }
  if (NULL == buffer || NULL == remote)
  {
    errno = EFAULT;
    return -1;
  }
  bytes = sendto(sock, buffer, len, 0, &remote->addr, remote->len);
  NETWORK_REPORT_ERROR();
  return bytes;
}
int	network_close(socket_t sock)
{
  if (SOCKET_INVALID == sock)
    return errno = EBADF;
#ifdef WIN32
  if (closesocket(sock))
  {
    NETWORK_REPORT_ERROR();
    return errno;
  }
#else /* not WIN32 */
  if (close(sock))
    return errno;
#endif /* not WIN32 */
  return 0;
}
