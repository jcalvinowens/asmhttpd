; asmhttpd: A minimalist HTTP webserver for Linux, written in x86_64 assembly.
;
; Copyright (C) 2012 Calvin Owens <jcalvinowens@gmail.com>
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

[bits 64]
global _start

%include "constants.inc"		; Flags for system calls, etc.
%include "syscall.inc"			; syscall() definition

%assign thread_memory_offset 0 ; This is rewritten each time tmalloc() is called
%macro reserve_thread_memory 2
	%define %1 rbp+%[thread_memory_offset]
	%define len%1 %2
	%assign thread_memory_offset thread_memory_offset+%[%2]
%endmacro
%define tmalloc(a,b) reserve_thread_memory a,b

%define GLOBAL_REQUEST_TIMEOUT 5
%define GLOBAL_MAX_HTTP_REQLEN 1024
%define THREAD_MEM_SIZE 4096
%define CLIENT_TIMEOUT_MS 60000
%define NAME_MAX 254

segment .text

SEGMENT_BEGIN:

Setsock_ARGUMENT:
	dd 0x00000001			; Turn option ON

Sighand_SIGPIPE:
	dq 0x0000000000000001		; SIG_IGN is 1
	dq 0x0000000000000000

SocketAddress:
	dw 0x0002			; AF_INET is 2 (AF_INET6 is 0xa)
	dw 0x5000			; TCP Port we want to bind to (:80) (Net byte ordering)
	dd 0x00000000                   ; Address to bind to (0.0.0.0 or ::)
	dd 0x00000000
	dd 0x00000000
	dd 0x00000000
	dd 0x00000000

SocketAddressNotRoot:
	dw 0x0002			; AF_INET is 2 (AF_INET6 is 0xa)
	dw 0x901F			; TCP Port we want to bind to (:8080) (Net byte ordering)
	dd 0x00000000                   ; Address to bind to (0.0.0.0 or ::)
	dd 0x00000000
	dd 0x00000000
	dd 0x00000000
	dd 0x00000000

DecAsciiConvTable:
	db 0x30,0x31,0x21,0x32,0x33,0x21,0x34,0x21,0x35,0x36,0x21,0x37,0x38,0x21,0x39,0x21

Response200:
	db "HTTP/1.1 200 OK",0x0d,0x0a
%define lenResponse200 17
Header12:
	db "Content-Length: "
%define lenHeader12 16

Error400:
	db "HTTP/1.1 400 Bad Request",0x0d,0x0a,0x0d,0x0a
%define lenError400 28
Error403:
	db "HTTP/1.1 403 Forbidden",0x0d,0x0a,0x0d,0x0a
%define lenError403 26
Error404:
	db "HTTP/1.1 404 Not Found",0x0d,0x0a,0x0d,0x0a
%define lenError404 26
Error408:
	db "HTTP/1.1 408 Request Timeout",0x0d,0x0a,0x0d,0x0a
%define lenError408 32
Error411:
	db "HTTP/1.1 411 Length Required",0x0d,0x0a,0x0d,0x0a
%define lenError411 32
Error413:
	db "HTTP/1.1 413 Request Entity Too Large",0x0d,0x0a,0x0d,0x0a
%define lenError413 41
Error414:
	db "HTTP/1.1 414 Request URI Too Long",0x0d,0x0a,0x0d,0x0a
%define lenError414 37
Error500:
	db "HTTP/1.1 500 Internal Server Error",0x0d,0x0a,0x0d,0x0a
%define lenError500 38
Error501:
	db "HTTP/1.1 501 Not Implemented",0x0d,0x0a,0x0d,0x0a
%define lenError501 32
HelpMessage:
	db "Usage: ./asmhttpd <webroot>",0x0a
%define lenHelpMessage 42

ech(____die)	; Who shall catch the catchers?

DieClientDisconnected:
syscall(sys_close,+rbx)
syscall(sys_munmap,+rbp,THREAD_MEM_SIZE)
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

PrintHelpMessageAndDie:
syscall(sys_write,2,[HelpMessage],lenHelpMessage)
jmp ____die

__die:
syscall(sys_write,+rbx,+rcx,+rdx)
syscall(sys_close,+rbx)
syscall(sys_munmap,+rbp,THREAD_MEM_SIZE)
____die:
syscall(sys_exit,-1);

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

_start:

ech(HandleInitSysError)

; Parse command line arguments. At the start of the program, [rsp] contains a
; qword that tells us how many arguments we got, and [rsp+8] is the beginning of
; a list of pointers to the NUL-terminated argument strings.

; Make sure we have 2 arguments:
;	0:	Executable name (we ignore this)
;	1:	Webroot
mov r11,[rsp]
cmp r11,2
jne PrintHelpMessageAndDie

syscall(sys_open,+[rsp+8*1+8],O_DIRECTORY,NULL)
mov r15,rax	; Save webroot file descriptor

; Ignore SIGPIPE
syscall(sys_rt_sigact,13,[Sighand_SIGPIPE],NULL,8)

; Create and set SO_REUSEADDR on the socket
syscall(sys_socket,2,1,NULL)
mov rbx,rax

syscall(sys_setsockopt,+rbx,SOL_SOCKET,SO_REUSEADDR,[Setsock_ARGUMENT],4)
syscall(sys_getuid)
test rax,rax
jnz .NotRoot

; Bind, and drop privs (nobody)
syscall(sys_bind,+rbx,[SocketAddress],24)
syscall(sys_setgid,65535)
syscall(sys_setuid)
jmp .OverNotRoot

.NotRoot:
syscall(sys_bind,+rbx,[SocketAddressNotRoot],24)

.OverNotRoot:
syscall(sys_listen,+rbx,1024)

; Now, we can unmap everything but our two pages (including the stack!)
; If you use L5 pagetables, change the shift by 47 to 56

; Unmap everything after .text
lea rdi,[SEGMENT_BEGIN]
shr rdi,12
inc rdi
shl rdi,12

mov rsi,1
shl rsi,47
sub rsi,rdi
sub rsi,4096	; Highest page is off-limits
syscall(sys_munmap)

; Unmap everything before .text
mov rsi,rdi
shr rsi,12
dec rsi
shl rsi,12
dec rsi
xor rdi,rdi
syscall(sys_munmap)

; Fork away from calling TTY
;syscall(sys_fork)
;jz ServeHTTP
;syscall(sys_exit,NULL)

ServeHTTP:

ech(HandleServeSysError)

mov r8,rbx ; file descriptor for listening socket
mov r9,CLONE_FS|CLONE_THREAD|CLONE_SIGHAND|CLONE_VM|CLONE_FILES
mov r10d,sys_accept
mov r12d,sys_clone
xor rsi,rsi
xor rdx,rdx

.AcceptNextRequest:

syscall(+r10,+r8)
mov rbx,rax
syscall(+r12,+r9)
jnz .AcceptNextRequest

;; (rbx contains client connection file descriptor)

HandleConnection:
ech(HandleGeneralSysError)

syscall(sys_mmap,NULL,THREAD_MEM_SIZE,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS|MAP_POPULATE,NULL,NULL)
mov rbp,rax	; Store offset for tmalloc() macro

tmalloc(PollStruct,8)

; Build a struct pollfd in memory
mov [PollStruct],rbx
mov dword [PollStruct+4],POLLIN

tmalloc(ClientRequest,1024)

; Load offset and counter for receieve loop
lea r9,[ClientRequest]
mov r10d,1024

ReceiveRequest:

syscall(sys_poll,[+PollStruct],1,CLIENT_TIMEOUT_MS)
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

lea r8,[rbp+thread_memory_offset]	; Load scratch address, to store offsets of escaped %xx literals
xor r10,r10	; Zero index registers
xor r9,r9
mov eax,0x25	; '%' in ASCII
mov rcx,r12	; Counter for 'repne scasb'...
sub rcx,r13	; ...subtract from end to get length
cmp rcx,3	; If there are less than 3 characters...
jl ExpandDone	; ...there can't be anything to unescape
mov rdi,r13	; Beginning of URI

ExpandChar:
repne scasb	; Search for a '%' character
jne ExpandOut	; ...if we didn't find one, we're done
cmp rcx,1	; If there are less than 2 characters left...
jle ExpandOut	; ...don't try to unescape
movzx rdx,word [rdi]	; Pull the ASCII-encoded hex byte into dx
ror dl,4	; You are not expected to understand this
ror dx,4
ror dl,4
and dh,0x44
shr dh,2
add dl,dh
shl dh,3
or dl,dh
mov [rdi-1],dl	; Overwrite the '%' character with the newly-unescaped byte
mov word [rdi],r10w	; Write NULL's over the just-unescaped ASCII-encoded hex
mov [r8+r9*8],rdi	; Add the address to our list of unescaped literals
inc r9	; Increment the counter
jmp short ExpandChar	; ...and do it again

ExpandOut:
or r9,r9	; If r9 is zero...
jz ExpandDone	; ...then there was nothing to un-escape - jump over copying
mov [r8+r9*8],rdi	; Store the offset of the last byte of the URI

xor rax,rax	; Zero out rax (index register for the loop)
mov rdi,[r8]	; Get the offset of the first un-escaped literal
mov rsi,rdi	; rsi holds the destination

DoCopying:
add rsi,2	; Jump over unescaped xx
mov rcx,[r8+rax*8+8]	; Load the offset of the next escapee
sub rcx,rsi	; Subtract where we are now to get how far to copy
rep movsb	; Boom
inc rax	; Increment the idex register
cmp rax,r9	; If we're not done...
jne DoCopying	; ...do it again

mov rcx,r9	; Use the number of %xx's we unescaped as a counter
xor dx,dx	; Zero dx so we can write NULL words
mov [rdi],dx	; NUL terminate the (now shorter) string

ExpandDone:

tmalloc(OpenAtStruct,24)
mov qword [OpenAtStruct],0
mov qword [OpenAtStruct+8],0
mov qword [OpenAtStruct+16],RESOLVE_IN_ROOT
syscall(sys_openat2,+r15,+r13,[OpenAtStruct],lenOpenAtStruct)
mov r13,rax	; Save file descriptor

ech(HandleGeneralSysErrorAfterOpen)	; Now if we crash we have to close the file to
					; avoid leaking file descriptors

tmalloc(StatStruct,144)

syscall(sys_fstat,+r13,[StatStruct])

; Make sure we have a regular file or a symlink
mov r12w,[StatStruct+24]	; Get the file mode
shr r12w,14
cmp r12w,2
jne DieError403

mov r12,[StatStruct+48]	; Get the file size out of the struct from stat()

lea rsp,[rbp+thread_memory_offset]	; Get scratch space, store it in rsp for awhile

; Convert the filesize to ASCII
mov rax,r12			; The file's length to convert (as an unsigned quadword)
mov ecx,16			; Counter for the conversion loop
lea rsi,[DecAsciiConvTable]	; Address of table for ASCII conversion
mov r8,0x199999999999999a	; Multiplicative inverse of 10d (0xa)
xor r9,r9			; Zero out registers for the ASCII string
xor r10,r10

DivisionLoop:
	shld r9,r10,8		; Shift the most significant byte of r10 into r9
	shl r10,8		; (shld only shifts in, not out, so we have to discard the byte)
	mul r8			; Execute the division
	shr rax,60		; Shift the most significant byte of the remainder to the least
	movzx rax,byte [rsi+rax]; Load the value from our conversion table
	or r10,rax		; Store the new value in r10
	mov rax,rdx		; Restore the working quotient for the next iteration
	loop DivisionLoop	; ...and do it again

mov [rsp],r10			; Store the ASCII decimal value in memory
mov [rsp+8],r9

mov eax,0x30	; Skip over the leading zeros (they break stupid browsers...)
mov ecx,16
mov rdi,rsp
repe scasb

mov r11,[rdi-1]	; Move the significant values back to the beginning of [rsp]
mov [rsp],r11
mov r11,[rdi-1+8]
mov [rsp+8],r11

lea rsp,[rsp+rcx+1]	; Skip past the ASCII number

mov rdi,rsp	; Copy to the scratch area...
mov rsi,Response200	; ...from the canned HTTP 200 response
mov ecx,lenResponse200	; Size
rep movsb	; Boom

mov rsi,Header12	; Copy the "Content-Length: " header
mov ecx,lenHeader12	; Size
rep movsb	; Boom

lea rsi,[rbp+thread_memory_offset]	; Load rsi with the address of the ASCII-expressed file size
mov rcx,rsp	; Get the address of the start of the send buffer
sub rcx,rsi	; Subtract the offset of the size from the offset of the buffer (strlen(num))
rep movsb	; ...and copy the difference in bytes to the header field

mov dword [rdi], 0x0a0d0a0d	; Terminate the HTTP response

lea rdx,[rdi+4]	; Address from which to send response plus 4...
sub rdx,rsp	; ...and subtract the end to get the length
syscall(sys_sendto,+rbx,[+rsp],+rdx,MSG_MORE,NULL,NULL)

keep_sending:
syscall(sys_sendfile,+rbx,+r13,NULL,+r12)
sub r12,rax
jnz keep_sending

; Close file descriptor and socket
syscall(sys_close,+r13)
syscall(sys_close,+rbx)

; Deallocate thread-local memory and exit
syscall(sys_munmap,+rbp,THREAD_MEM_SIZE)
syscall(sys_exit,NULL)

ud2	; SIGILL
