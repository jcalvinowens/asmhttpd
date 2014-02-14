;; (rbx contains client connection file descriptor)

HandleConnection:
ech(HandleGeneralSysError)

syscall(sys_mmap,NULL,32768,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS|MAP_NORESERVE,NULL,NULL)
mov rbp,rax	; Store offset for tmalloc() macro

tmalloc(PollStruct,8)

; Build a struct pollfd in memory
mov [PollStruct],rbx
mov dword [PollStruct+4],1

tmalloc(ClientRequest,1024)

; Load offset and counter for receieve loop
lea r9,[ClientRequest]
mov r10d,1024

ReceiveRequest:

syscall(sys_poll,[+PollStruct],1,60000)
jz DieError408

syscall(sys_read,+rbx,+r9,+r10)
jz DieClientDisconnected

cmp rax,18		; If we got too few bytes to be valid...
jl ReceiveRequest	; ...go wait for more.

mov esi,0x0a0d0a0d
lea rdi,[r9+rax-4]
lea r8,[ClientRequest]

.FindTerminator:
cmp esi,dword [rdi]
je short .FoundTerminator

dec rdi		; If we haven't reached the beginning...
cmp rdi,r8	; ...then keep looking
jne short .FindTerminator

add r9,rax	; Adjust offset and counter
sub r10,rax
jz DieError414	; If zero, send 412 REQUEST URI TOO LARGE

jmp ReceiveRequest	; Go back up and wait for more data

.FoundTerminator:
lea r15,[rdi+3]		; Store the last byte of the request
lea r14,[r9+rax]	; Store last byte received from client

; Skip past the METHOD specification, find the start of the URI:
mov eax,0x20
lea rdi,[ClientRequest]
mov ecx,20
repne scasb
jne DieError400		; Go thou and fuck with me no more

mov r13,rdi

; NULL-terminate the filename
mov ecx,1024
repne scasb
jne DieError400		; This should never happen

mov byte [rdi-1],0x00
lea r12,[rdi-1]		; Store addr of last byte of URI

;; Fall through
