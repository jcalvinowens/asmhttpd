;; This global constant is rewritten each time the macro is called
%assign thread_memory_offset 0

%macro reserve_thread_memory 2
	%define %1 rbp+%[thread_memory_offset]
	%define len%1 %2
	%assign thread_memory_offset thread_memory_offset+%[%2]
%endmacro
%define tmalloc(a,b) reserve_thread_memory a,b
