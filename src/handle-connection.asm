HandleConnection:

ech(HandleGeneralSysError)

syscall(_sys_mmap,NULL,32768,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS|MAP_NORESERVE,NULL,NULL)
mov rbp,rax	; Save the address of our memory block
		; XXX: tmalloc() uses rbp, so don't touch it

tmalloc(PollStruct,8)

mov dword [PollStruct],ebx	; Build the struct used by the poll() syscall
mov dword [PollStruct+4],POLLIN	; We're looking for input

xor r15,r15	; Count number of poll/read loops
xor r14,r14	; Count number of bytes read

.ReceiveRequest:
syscall(_sys_poll,[PollStruct],1,GLOBAL_REQUEST_TIMEOUT)
jz .NoData

tmalloc(HttpRequest,GLOBAL_MAX_HTTP_REQLEN)

syscall(_sys_read,+rbx,[HttpRequest],lenHttpRequest)
jz DieClientDisconnected

inc r15
add r14,rax
cmp r14d,16
jle .ReceiveRequest

lea rdi,[HttpRequest+r14-3]
lea rcx,[rax+3]	; NRAA
mov al,0x0d

.FindReqEnd:
repne scasb
jne .ReceiveRequest

mov esi, dword [rdi-1]
cmp esi, 0x0a0d0a0d	; Little endian
je .GotReq
jmp short .FindReqEnd

.NoData:
or r15,r15
jz DieError408	; Never got anything - 408 Request Timed Out
jnz DieError400	; Got bullshit - 400 Bad Request

.GotRequest
mov r15,[rdi+3]		
sub r15,r14		; Length of request
lea r14,[rdi+3]		; Address of data (if any)
mov r13,r14		; Total length of received data
