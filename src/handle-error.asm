HandleInitSysError:
HandleServeSysError:
mov rbx,rax
syscall(sys_exit,+rbx)

HandleGeneralSysErrorAfterOpen:
syscall(sys_close,+r13)
HandleGeneralSysError:
cmp eax,-EPERM
je DieError403	; Permission Denied
cmp eax,-ENOENT
je DieError404	; File not found
cmp eax,-EACCES
je DieError403	; Permission denied
cmp eax,-ENAMETOOLONG
je DieError414	; URI too long (although, is it?)
cmp eax,-EPIPE
je DieClientDisconnected

jmp DieError500
