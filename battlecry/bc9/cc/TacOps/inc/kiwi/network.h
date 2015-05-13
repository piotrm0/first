/*
 *	network.h - common functions for asynchronous networking
 *	Project:	KIWI, useful items for platform-independence
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
 * $Id: network.h,v 1.2 2004/02/20 01:45:34 rick Exp $
 */

#ifndef __NETWORK_H__
#define __NETWORK_H__

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <kiwi/types.h>


#ifdef WIN32
#include <stdint.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <wininet.h>

#define NETWORK_REPORT_ERROR()	errno = WSAGetLastError()
#define SOCKET_INVALID	INVALID_SOCKET

/***  fix typedefs  ***/
typedef u_long in_addr_t;
typedef u_short in_port_t;
typedef int ssize_t;		/* NOTE: size_t is unsigned */
typedef SOCKET socket_t;

#else /* not WIN32 */

#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/un.h>

#define NETWORK_REPORT_ERROR()

typedef int	socket_t;
#define SOCKET_INVALID	-1

#endif /* not WIN32 */

typedef struct {
  uint16_t	len;		/* cuz winsock is stupid */
  struct sockaddr addr;
} sockaddr_t;
#define SOCKADDR_EXTRALEN	\
		(sizeof(sockaddr_t) - sizeof(struct sockaddr))


#define NETWORKADDR_NONE	NETWORKADDR_BROADCAST;
extern const char*	NETWORKADDR_BROADCAST;
extern const char*	NETWORKADDR_ANY;
extern const char*	NETWORKADDR_LOOPBACK;


/***  cross-platform asynchronous network sockets  ***/
int	network_init(void);
char*	network_addrcpy_noport(const char* addr);
int	network_addr2ascii(const sockaddr_t* addr, char** ascii);
int	network_ascii2addr(const char* ascii, sockaddr_t** addr);
int	network_sockaddr(socket_t sock, char** ascii);
socket_t network_socket(int domain, int type, int protocol);
int	network_broadcast(socket_t sock, boolean_t enable_flag);
int	network_bind(socket_t sock, const sockaddr_t* local);
int	network_connect(socket_t sock, const sockaddr_t* remote);
int	network_listen(socket_t sock, unsigned int backlog);
socket_t network_accept(socket_t sock, sockaddr_t** remote);
ssize_t	network_recv(socket_t sock, void* buffer, size_t len);
ssize_t	network_recvfrom(socket_t sock, void* buffer, size_t len,
			 sockaddr_t** remote);
ssize_t	network_send(socket_t sock, const void* buffer, size_t len);
ssize_t	network_sendto(socket_t sock, const void* buffer, size_t len,
		       const sockaddr_t* remote);
int	network_close(socket_t sock);

#endif /* __NETWORK_H__ */
