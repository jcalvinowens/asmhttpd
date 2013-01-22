lea r8,[rbp+thread_memory_offset]	; Load scratch address, to store offsets of escaped %xx literals
xor r10,r10	; Zero index registers
xor r9,r9
mov eax,0x25	; '%' in ASCII
mov rcx,r12	; Counter for 'repne scasb'...
sub rcx,r13	; ...subtract from end to get length
mov rdi,r13	; Beginning of URI

ExpandChar:
repne scasb	; Search for a '%' character
jne ExpandOut	; ...if we didn't find one, we're done
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
;mov word [rdi],r10w	; Write NULL's over the just-unescaped ASCII-encoded hex
mov [r8+r9*8],rdi	; Add the address to our list of unescaped literals
inc r9	; Increment the counter
jmp short ExpandChar	; ...and do it again

ExpandOut:
mov [r8+r9*8],rdi	; Store the offset of the last byte of the URI
or r9,r9	; If r9 is zero...
jz ExpandDone	; ...then there was nothing to un-escape - jump over copying

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

WriteNULLs:
mov [rdi+rcx*2-2],dx	; Write NULLs over the extra junk copied backwards at the end
loop WriteNULLs		; (We really only need one NULL - this is to aid in debugging)

ExpandDone:

tmalloc(StatStruct,144)

syscall(_sys_stat,+r13,[StatStruct])
syscall(_sys_open,+r13,NULL,NULL)

mov r13,rax	; Save file descriptor

mov r12,[StatStruct+48]	; Get the file size out of the struct from stat()
lea rsp,[rbp+thread_memory_offset]	; Get scratch space, store it in rsp for awhile

; Convert the filesize to ASCII
do_10e17_truncated_qword_ascii_conversion_to_mem r12,r8,r9,r10,rsp

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
syscall(_sys_sendto,+rbx,[+rsp],,0x8000,NULL,NULL)

keep_sending:
syscall(_sys_sendfile,+rbx,+r13,NULL,+r12)
sub r12,rax
jnz keep_sending

syscall(_sys_close,+r13)
syscall(_sys_close,+rbx)
syscall(_sys_exit,NULL)
