_start:
ech(HandleInitSysError)

; We need to ignore SIGPIPE, since the default action is to terminate
syscall(_sys_rt_sigaction,13,[Sighand_SIGPIPE],NULL,8)

; Chroot ourselves into the http root
syscall(_sys_chdir,[ChrootDirectory])
syscall(_sys_chroot,)

; Open the server socket
syscall(_sys_socket,2,1,NULL)
mov r12,rax	; Save the socket file descriptor
syscall(_sys_bind,+r12,[SocketAddress],24)
syscall(_sys_listen,,1000)

; Drop privs
syscall(_sys_setgid,1000)
syscall(_sys_setuid,)

; Daemonize
syscall(_sys_fork)
jnz DieInitUnforked

; Fall through to serve-http.asm
