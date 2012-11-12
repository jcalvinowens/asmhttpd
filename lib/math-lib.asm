;; Invocation: qword_length,trash1,trash2,trash3,ascii_dest
;; 	qword_length: MUST be qword, EITHER register or memory dereference
;;	trashX: MUST be qword registers
;;	ascii_dest: MUST be 16-byte memory address
;; Clobbers: rax,rcx,rdx,rsi, and trashX
%macro do_10e17_truncated_qword_ascii_conversion_to_mem 5
	mov rax,%1                             ; The file's length to convert (as an unsigned quadword)
	mov ecx,16                             ; Counter for the conversion loop
	lea rsi,[DecAsciiConvTable]	       ; Address of table for ASCII conversion
	mov %1,0x199999999999999a              ; Multiplicative inverse of 10d (0xa)
	xor %2,%2                              ; Zero out registers for the ASCII string
	xor %3,%2                            
	
	%%division_loop:
		shld %2,%3,8                           ; Shift the most significant byte of r10 into r9
		shl %3,8                               ; (shld only shifts in, not out, so we have to discard the byte)
		mul %1                                 ; Execute the division
		shr rax,60                             ; Shift the most significant byte of the remainder to the least
		movzx rax,byte [rsi+rax]               ; Load the value from our conversion table
		or %3,rax                              ; Store the new value in r10
		mov rax,rdx                            ; Restore the working quotient for the next iteration
		loop %%division_loop                   ; ...and do it again
	
	mov [%4],%3                            ; Store the ASCII decimal value in memory
	mov [%4+8],%2
%endmacro
