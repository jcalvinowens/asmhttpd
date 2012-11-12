; nanohttpd: A minimalist HTTP webserver for Linux, written in x86_64 assembly.
; Copyright (C) 2013 Calvin Owens
;
; This program is free software: you can redistribute it and/or modify it
; under the terms of version 2 of the GNU General Public License as published
; by the Free Software Foundation.
;
; THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
; THE COPYRIGHT HOLDER(S) OR AUTHOR(S) BE LIABLE FOR ANY CLAIM, DAMAGES OR
; OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
; ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
; OTHER DEALINGS IN THIS SOFTWARE.

[bits 64]	
global _start

%include "inc/global-constants.inc"	; Global configurable constants
%include "inc/syscalls.inc"		; Contains _sys_whatever macros
%include "inc/errno.inc"		; ERRNO definitions
%include "inc/flags.inc"		; Flags for system calls

%include "lib/syscall-lib.asm"		; All the macro definitions
%include "lib/math-lib.asm"		; Canned math
%include "lib/mem-lib.asm"		; tmalloc() definition

segment .data
%include "src/static-data.asm"		; The data segment - it's all here.
%include "src/http-responses.asm"	; Contains canned HTTP headers and the like

segment .text
%include "src/http-actions.asm"		; Labels for HTTP actions (eg DieError404)
%include "src/handle-error.asm"		; Error handlers go here

%include "src/init.asm"			; Where execution starts (_start is here)
%include "src/serve-http.asm"		; The loop that calls accept() and clone()s off for connections
%include "src/handle-connection.asm"	; Beginning of each thread for each connection

%include "src/get.asm"			; Code for the GET method (and HEAD)
