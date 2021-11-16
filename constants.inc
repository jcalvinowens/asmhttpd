;; syscalls
%define sys_accept	0x0000002B
%define sys_bind	0x00000031
%define sys_chdir	0x00000050
%define sys_chroot	0x000000A1
%define sys_clone	0x00000038
%define sys_close	0x00000003
%define sys_exit	0x0000003C
%define sys_fork	0x00000039
%define sys_fstat	0x00000005
%define sys_listen	0x00000032
%define sys_mmap	0x00000009
%define sys_munmap	0x0000000B
%define sys_open	0x00000002
%define sys_poll	0x00000007
%define sys_read	0x00000000
%define sys_rt_sigact	0x0000000D
%define sys_sendfile	0x00000028
%define sys_sendto	0x0000002C
%define sys_setgid	0x0000006A
%define sys_setuid	0x00000069
%define sys_socket	0x00000029
%define sys_write	0x00000001

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
%define MAP_NORESERVE	0x04000;	/* Don't check for reservations.  */
%define MAP_POPULATE	0x08000;	/* Populate (prefault) pagetables.  */

;; For poll()
%define POLLIN		0x1;		/* There is data to read */

;; For sendto()
%define MSG_MORE	0x8000;		/* TCP_CORK behavior */
