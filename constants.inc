;; syscalls
%define sys_accept	43
%define sys_bind	49
%define sys_chdir	80
%define sys_chroot	161
%define sys_clone	56
%define sys_close	3
%define sys_exit	60
%define sys_fork	57
%define sys_fstat	5
%define sys_getuid	102
%define sys_listen	50
%define sys_mmap	9
%define sys_munmap	11
%define sys_open	2
%define sys_openat2	437
%define sys_poll	7
%define sys_read	0
%define sys_rt_sigact	13
%define sys_sendfile	40
%define sys_sendto	44
%define sys_setgid	106
%define sys_setsockopt	54
%define sys_setuid	105
%define sys_socket	41
%define sys_write	1

;; errno
%define	EPERM		1;	/* Operation not permitted */
%define	ENOENT		2;	/* No such file or directory */
%define	EACCES		13;	/* Permission denied */
%define	EPIPE		32;	/* Broken pipe */
%define	ENAMETOOLONG	36;	/* File name too long */

;; For clone()
%define CLONE_VM	0x00000100; /* Set if VM shared between processes.  */
%define CLONE_FS	0x00000200; /* Set if fs info shared between processes.  */
%define CLONE_FILES	0x00000400; /* Set if open files shared between processes.  */
%define CLONE_SIGHAND	0x00000800; /* Set if signal handlers shared.  */
%define CLONE_THREAD	0x00010000; /* Set to add to same thread group.  */

;; For mmap()
%define PROT_READ	0x1;		/* Page can be read.  */
%define PROT_WRITE	0x2;		/* Page can be written.  */
%define MAP_PRIVATE	0x02;		/* Changes are private.  */
%define MAP_ANONYMOUS	0x20;		/* Don't use a file.  */
%define MAP_POPULATE	0x08000;	/* Populate (prefault) pagetables.  */

;; For poll()
%define POLLIN		0x1;		/* There is data to read */

;; For sendto()
%define MSG_MORE	0x8000;		/* TCP_CORK behavior */

;; For setsockopt()
%define SOL_SOCKET	1;
%define SO_REUSEADDR	2;

;; For open()
%define O_DIRECTORY     0x10000;

;; For openat2()
%define RESOLVE_IN_ROOT	0x10;
