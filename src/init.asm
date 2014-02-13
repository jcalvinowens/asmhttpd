ech(HandleInitSysError)

; Parse command line arguments. At the start of the program, [rsp] contains a
; qword that tells us how many arguments we got, and [rsp+8] contains a pointer
; to the array of NULL-terminated strings representing the arguments.

; Make sure we have 2 arguments:
;	0:	Executable name (we ignore this)
;	1:	Webroot
mov r11,[rsp]
cmp r11,2
jl HandleInitSysError

; Okay, find the arg
mov r11,[rsp+8]
xor rcx,rcx

.FindNULL:
movzx r12, byte [r11+rcx]
test r12,r12
jz .GotNULL
inc rcx
jmp .FindNULL

.GotNULL:
; Okay, we got the webroot argument. Even if somebody is screwing with us, we
; know it will be NULL-terminated, so just pass it to chdir() and chroot()

; Change and chroot to the webroot
syscall(_sys_chdir,[r11+rcx+1])
syscall(_sys_chroot,)

; Ignore SIGPIPE
syscall(_sys_rt_sigaction,13,[Sighand_SIGPIPE],NULL,8)

; Create, bind to, and listen on socket
syscall(_sys_socket,2,1,NULL)
mov rdi,rax
syscall(_sys_bind,,[SocketAddress], 24)
syscall(_sys_listen,,1024)

mov r8,rdi

; Drop privs (Nobody)
syscall(_sys_setgid,65535)
syscall(_sys_setuid,)

; Fork away from calling TTY
syscall(_sys_fork)
jz ServeHTTP

syscall(_sys_exit,NULL)

;; Fall through to ServeHTTP
