ech(____die)	; Who shall catch the catchers?

DieClientDisconnected:
syscall(sys_close,+rbx)
syscall(sys_munmap,+rbp,32768)
syscall(sys_exit,-1)

DieError403:
lea rcx,[Error403]
mov edx,lenError403
jmp __die

DieError404:
lea rcx,[Error404]
mov edx,lenError404
jmp __die

DieError414:
lea rcx,[Error414]
mov edx,lenError414
jmp __die

DieError500:
lea rcx,[Error500]
mov edx,lenError500
jmp __die

DieError408:
lea rcx,[Error408]
mov edx,lenError408
jmp __die

DieError400:
lea rcx,[Error400]
mov edx,lenError400
jmp __die

__die:
syscall(sys_write,+rbx,+rcx,+rdx)
syscall(sys_close,+rbx)
syscall(sys_munmap,+rbp,32768)
____die:
syscall(sys_exit,-1);
