ServeHTTP:
ech(HandleServeSysError)

mov r9d,CLONE_SIGHAND|CLONE_FS|CLONE_VM|CLONE_THREAD|CLONE_SIGHAND|CLONE_FILES
mov r10d,_sys_accept
mov r13d,_sys_clone
xor rsi,rsi
xor rdx,rdx

.AcceptNextRequest:
syscall(+r10,+r12)
mov rbx,rax
syscall(+r13,+r9,)
jnz .AcceptNextRequest

; Fall through to handle-connection.asm
