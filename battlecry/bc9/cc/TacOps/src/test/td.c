#include <arpa/inet.h>
#include <arpa/telnet.h>
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>


int sock = -1;


void	pexit(const char* fmt, ...)
{
  char* str = NULL;
  va_list ap;

  va_start(ap, fmt);
  vasprintf(&str, fmt, ap);
  va_end(ap);
  perror(NULL == str ? "<NULL>" : str);
  exit(EXIT_FAILURE);
}
void	dump(const char* prefix, const char* bytes, unsigned int count)
{
  int i;

  while (count > 0)
  {
    printf("%s: ", prefix);
    for (i = 0; i < 16; i++)
      if (i < count)
	printf("%02X ", bytes[i] & 0xFF);
      else
	printf("   ");
    printf(" [");
    for (i = 0; i < 16; i++)
      if (i < count)
      {
	char c = bytes[i];
	printf("%c", c <= ' ' ? '.' : c);
      } else
	printf(" ");
    printf("]\n");
    if (i < count)
    {
      count += i;
      bytes += i;
    } else
      count = 0;
  }
  fflush(stdout);
}

int	main(void)
{
  unsigned int enable = 1;
  struct sockaddr_in sin;
  socklen_t len;
  char buffer[1024];
  ssize_t bytes;

  sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (sock < 0)
    pexit("socket()");
  if (setsockopt(sock, SOL_SOCKET, SO_REUSEPORT,
		 (void*)&enable, sizeof(enable)))
    pexit("setsockopt(REUSEPORT)");
  bzero(&sin, sizeof(sin));
  sin.sin_len = sizeof(sin);
  sin.sin_family = AF_INET;
  sin.sin_addr.s_addr = INADDR_ANY;
  sin.sin_port = htons(7777);
  if (bind(sock, (struct sockaddr*)&sin, sizeof(sin)))
    pexit("bind(ANY:7777)");
  if (listen(sock, 0))
    pexit("listen");
  fprintf(stderr, "waiting for incoming connection...\n");
  len = sizeof(sin);
  enable = accept(sock, (struct sockaddr*)&sin, &len);
  if (enable < 0)
    pexit("accept()");
  close(sock);
  sock = enable;
  if (fcntl(sock, F_SETFL, O_NONBLOCK))
    pexit("fcntl(NONBLOCK)");
  usleep(100000);
  while ((bytes = recv(sock, buffer, 1024, 0)) >= 0)
    dump("recv", buffer, bytes);
  if (EAGAIN != errno)
    pexit("recv()");
  buffer[0] = IAC;
  buffer[1] = AYT;
  bytes = 2;
  dump("send", buffer, bytes);
  bytes = send(sock, buffer, bytes, 0);
  if (bytes < 2)
    pexit("send()");
  usleep(100000);
  while ((bytes = recv(sock, buffer, 1024, 0)) >= 0)
    dump("recv", buffer, bytes);
  if (EAGAIN != errno)
    pexit("recv()");
  buffer[0] = IAC;
  buffer[1] = DO;
  buffer[2] = TELOPT_NAWS;
  bytes = 3;
  dump("send", buffer, bytes);
  bytes = send(sock, buffer, bytes, 0);
  if (bytes < 3)
    pexit("send()");
  if (fcntl(sock, F_SETFL, 0))
    pexit("fcntl(BLOCK)");
  while ((bytes = recv(sock, buffer, 1024, 0)) >= 0 || EAGAIN == errno)
    dump("recv", buffer, bytes);
  pexit("recv()");

  return 0;
}
