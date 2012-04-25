/* 
   Author: Andy Goetz
   Copyright 2011 All Rights Reserved
*/

#include <sys/stat.h>
#include <errno.h>
#include <stdlib.h>
#include <sys/times.h>
#include <stdio.h>
#include "syscalls.h"
#include <reent.h>

/*these are the absolute minimum stubs necessary for libc to understand what is going on with your system. */

/* Exit a program without cleaning up files*/
void _exit(int code)
{
  for(;;)
    ;
}

/* Close a file */
int _close(int file)
{
  return -1;
}


/* Transfer control to a new process */
int _execve(char *name, char **argv, char **env)
{
  errno = ENOMEM;
  return -1;
}

/* Create a new process */
int _fork()
{
  errno = EAGAIN;
  return -1;
}

/* Status of an open file */
int _fstat(int file, struct stat *st)
{
  st->st_mode = S_IFCHR;
  return 0;
}

/* Process-ID; this is sometimes used to generate strings unlikely to conflict with other processes. */
int _getpid(void)
{
  return 1;
}

/* re-entrant version */
int _getpid_r(struct _reent * reentdata)
{
  return 1;
}

/* Query whether output stream is a terminal */
int _isatty(int file)
{
  return 1;
}

/*  Send a signal*/
int _kill(int pid, int sig)
{
  errno = EINVAL;
  return -1;
}

/* re-entrant version */
int _kill_r(struct _reent * reentdata, int pid, int sig)
{
  errno = EINVAL;
  return -1;
}

/* Establish a new name for an existing file */
int _link (char *old, char *new)
{
  errno = EMLINK;
  return -1;
}

/* Set a position in a file */
int _lseek(int file, int ptr, int dir)
{
  return 0;
}

/* Open a file */
int _open(const char *name, int flags, int mode)
{
  return -1;
}

/* Read a file */
int _read(int file, char *ptr, int len)
{
  return 0;
}

/* Increase program data space */
caddr_t _sbrk(int incr)
{
  extern char _end;
  static char *heap_end;
  char *prev_heap_end;
  register char * stack_ptr __asm__ ("sp");
  if(heap_end == 0)
    {
      heap_end = &_end;
    }
  prev_heap_end = heap_end;
  if(heap_end + incr > stack_ptr)
    {
      _write(1, "Heap and stack collision\n", 25);
      abort();
    }
  heap_end += incr;
  return (caddr_t) prev_heap_end;
}

/* re-entrant version */

void *  _sbrk_r(struct _reent *r, ptrdiff_t incr)
{
  return _sbrk((int)incr);
}

/* status of a file (by name) */
/* int stat(char *file, struct stat *st) */
/* { */
/*   st->st_mode = S_IFCHR; */
/*   return 0; */
/* } */

/* Timing information for current process */
/* int times(struct tms *buf) */
/* { */
/*   return -1; */
/* } */

/* remove a file's directory entry */
int _unlink(char *name)
{
  errno = ENOENT;
  return -1;
}

/* wait for a child process */
int _wait(int *status)
{
  errno = ECHILD;
  return -1;
}

/* write to a file */
int _write(int file, char *ptr, int len)
{
  errno = ECHILD;
  return -1;
}
