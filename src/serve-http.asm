ServeHTTP:

ech(HandleServeSysError)

;; (r8 contains file descriptor for listening socket)

mov r9,CLONE_FS|CLONE_THREAD|CLONE_SIGHAND|CLONE_VM|CLONE_FILES
mov r10d,_sys_accept
mov r12d,_sys_clone
xor rsi,rsi
xor rdx,rdx

.AcceptNextRequest:

syscall(+r10,+r8)
mov rbx,rax
syscall(+r12,+r9,)
jnz .AcceptNextRequest

;;; Fall through to handle-connection.asm
