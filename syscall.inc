; See the MACROS file for a description of how this monstrosity works

;; r64,r32,r16,r8,arg
%macro load_syscall_argument 0-*
	%if %0 == 4
		; Empty Argument
	%elif %0 == 5
		%defstr ___arg_str %[%5]
		%substr ___arg_c ___arg_str 1
			%if ___arg_c == '['
			%substr ___arg_c2 ___arg_str 2
			%if ___arg_c2 == "+"
				%substr ___arg_n ___arg_str 3,-2
				%deftok ___arg_n_t %[___arg_n]
				mov %1,___arg_n_t
				%undef ___arg_n_t
				%undef ___arg_n
			%else
				lea %1,%5
			%endif
			%undef ___arg_c2
		%elif ___arg_c == '+'
			%substr ___arg_n ___arg_str 2,-1
			%deftok ___arg_n_t %[___arg_n]
			mov %1,___arg_n_t
			%undef ___arg_n_t
			%undef ___arg_n
		%elif ___arg_c == '^'
			%define ___forced_imm_bit_len 32
			%substr ___arg_c2 ___arg_str 1,2
			%if ___arg_c2 == "^^"
				%define ___forced_imm_bit_len 16
				%substr ___arg_c3 ___arg_str 1,3
				%if ___arg_c3 == "^^^"
					%define ___forced_imm_bit_len 8
				%endif
				%undef ___arg_c3
			%endif
			%undef ___arg_c2
			%if ___forced_imm_bit_len == 32
				%substr ___arg_n ___arg_str 2,-1
				%deftok ___arg_n_t %[___arg_n]
				%substr ___arg_n_c ___arg_n 1,1
				%if ___arg_n_c != '['
					%warning "^thing is redundant in SYSCALL: thing is interpreted as 32bit by default" 
				%endif
				mov %2,___arg_n_t
				%undef ___arg_n_t
				%undef ___arg_n
			%elif ___forced_imm_bit_len == 16
				%substr ___arg_n ___arg_str 3,-1
				%deftok ___arg_n_t %[___arg_n]
				mov %3,___arg_n_t
				%undef ___arg_n_t
				%undef ___arg_n
			%elif ___forced_imm_bit_len == 8
				%substr ___arg_n ___arg_str 4,-1
				%deftok ___arg_n_t %[___arg_n]
				mov %4,___arg_n_t
				%undef ___arg_n_t
				%undef ___arg_n
			%endif
			%undef ___forced_imm_bit_len
		%elif ___arg_str == 'NULL'
			xor %1,%1
		%else
			mov %2,%5
		%endif
		%undef ___arg_c
		%undef ___arg_str
	%else
		%fatal "You fucked up the SYSCALL-load-arguments macro!"
	%endif
%endmacro

%macro macro_do_syscall 1-7
	load_syscall_argument rax,eax,ax,al,%1
	%if %0 >= 2
	load_syscall_argument rdi,edi,di,dil,%2
	%endif
	%if %0 >= 3
	load_syscall_argument rsi,esi,si,sil,%3
	%endif
	%if %0 >= 4
	load_syscall_argument rdx,edx,dx,dl,%4
	%endif
	%if %0 >= 5
	load_syscall_argument r10,r10d,r10w,r10b,%5
	%endif
	%if %0 >= 6
	load_syscall_argument r8,r8d,r8w,r8b,%6
	%endif
	%if %0 >= 7
	load_syscall_argument r9,r9d,r9w,r9b,%7
	%endif
	syscall	; Invoke loadall286+
	%ifdef __syserror_handler
		or rax,rax ; Set flags based on the return value
		js __syserror_handler
	%else
		%fatal "__syserror_handler is not defined!"
	%endif
%endmacro ;; Yo dawg, I heard you liked macros...
%define syscall(a,b,c,d,e,f,g) macro_do_syscall a,b,c,d,e,f,g
%define syscall(a,b,c,d,e,f) macro_do_syscall a,b,c,d,e,f
%define syscall(a,b,c,d,e) macro_do_syscall a,b,c,d,e
%define syscall(a,b,c,d) macro_do_syscall a,b,c,d
%define syscall(a,b,c) macro_do_syscall a,b,c
%define syscall(a,b) macro_do_syscall a,b
%define syscall(a) macro_do_syscall a

%macro change_syscall_error_handler 1
	%define __syserror_handler %1
%endmacro
%define ech(a) change_syscall_error_handler a
