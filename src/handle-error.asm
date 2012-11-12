HandleInitSysError:
HandleServeSysError:
mov rbx,rax
syscall(_sys_exit,+rbx)

HandleGeneralSysError:
cmp eax,-EPERM
je DieError403	; Permission Denied
cmp eax,-ENOENT
je DieError404	; File not found
cmp eax,-EISDIR
je DieError403	; FIXME: Is this how we want to handle this? Or 405?
cmp eax,-EACCES
je DieError403	; Permission denied
cmp eax,-ENAMETOOLONG
je DieError414	; URI too long (although, is it?)

jmp DieError500
