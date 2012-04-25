/* 
   Author: Andy Goetz
   Copyright 2011 All Rights Reserved
*/


#include <sys/stat.h>
#include <sys/times.h>
#include <errno.h>



/*these are the absolute minimum stubs necessary for libc to understand what is going on with your system. */

/* Exit a program without cleaning up files*/
void _exit(int code);

/* Close a file */
int close(int file);

char *__env[1] = {0};
/* A pointer to a list of environment variables and their values */
char **environ = __env;

/* Transfer control to a new process */
int _execve(char *name, char **argv, char **env);

/* Create a new process */
int _fork();

/* Status of an open file */
int _fstat(int file, struct stat *st);

/* Process-ID; this is sometimes used to generate strings unlikely to conflict with other processes. */
int _getpid(void);

/* Query whether output stream is a terminal */
int _isatty(int file);

/*  Send a signal*/
int _kill(int pid, int sig);

/* Establish a new name for an existing file */
int _link (char *old, char *new);

/* Set a position in a file */
int _lseek(int file, int ptr, int dir);

/* Open a file */
int _open(const char *name, int flags, int mode);

/* Read a file */
int _read(int file, char *ptr, int len);

/* Increase program data space */
caddr_t _sbrk(int incr);

/* status of a file (by name) */
/* int stat(char *file, struct stat *st); */

/* Timing information for current process */
/* int times(struct tms *buf); */

/* remove a file's directory entry */
int _unlink(char *name);

/* wait for a child process */
int _wait(int *status);

/* write to a file */
int _write(int file, char *ptr, int len);
