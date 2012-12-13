ech(HandleInitSysError)

; Change and chroot to the webroot
syscall(_sys_chdir,[ChrootDirectory])
syscall(_sys_chroot,[ChrootDirectory])

; Ignore SIGPIPE
syscall(_sys_rt_sigaction,13,[Sighand_SIGPIPE],NULL,8)

; Create, bind to, and listen on socket
syscall(_sys_socket,2,1,NULL)
mov rdi,rax
syscall(_sys_bind,,[SocketAddress], 24)
syscall(_sys_listen,,1024)

mov r8,rdi

; Drop privlages
syscall(_sys_setgid,1000)
syscall(_sys_setuid,)

; Fork away from calling TTY
syscall(_sys_fork)
jz ServeHTTP

syscall(_sys_exit,NULL)

;; Fall through to ServeHTTP
