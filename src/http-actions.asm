ech(0)	; Who shall catch the catchers?

DieClientDisconnected:
syscall(_sys_close,+rbx)
syscall(_sys_exit,-1)

DieError400:
lea rcx,[Error400]
mov edx,lenError400
jmp __die

__die:
syscall(_sys_write,rbx,rcx,rdx)
syscall(_sys_exit,-1);
