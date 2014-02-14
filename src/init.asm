ech(HandleInitSysError)

; Parse command line arguments. At the start of the program, [rsp] contains a
; qword that tells us how many arguments we got, and [rsp+8] contains a pointer
; to the array of NULL-terminated strings representing the arguments.

; Make sure we have 2 arguments:
;	0:	Executable name (we ignore this)
;	1:	Webroot
mov r11,[rsp]
cmp r11,2
jne HandleInitSysError

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
syscall(sys_chdir,[r11+rcx+1])
syscall(sys_chroot,)

; Ignore SIGPIPE
syscall(sys_rt_sigaction,13,[Sighand_SIGPIPE],NULL,8)

; Create, bind to, and listen on socket
syscall(sys_socket,2,1,NULL)
mov rdi,rax
syscall(sys_bind,,[SocketAddress], 24)
syscall(sys_listen,,1024)

mov r8,rdi

; Drop privs (Nobody)
syscall(sys_setgid,65535)
syscall(sys_setuid,)

; .rodata is higher than .text in virtual memory. Calculate the address of the
; first unused page after .data
lea rdi,[DATASEGMENT_END]
shr rdi,12
inc rdi
shl rdi,12

; Now, calculate the page-size-aligned length from the end of .data to the top
; of the userspace addresses (See: http://en.wikipedia.org/wiki/X86-64)
mov rsi,0x00007fffffffffff
sub rsi,rdi
shr rsi,12
dec rsi
shl rsi,12

; Do the munmap() call. This unmaps the stack, which we no longer need.
syscall(sys_munmap,,)

; Fork away from calling TTY
syscall(sys_fork)
jz ServeHTTP

syscall(sys_exit,NULL)

;; Fall through to ServeHTTP
