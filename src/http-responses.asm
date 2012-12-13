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
	db "HTTP/1.1 414 Requist URI Too Long",0x0d,0x0a,0x0d,0x0a
%define lenError414 37
Error500:
	db "HTTP/1.1 500 Internal Server Error",0x0d,0x0a,0x0d,0x0a
%define lenError500 38
Error501:
	db "HTTP/1.1 501 Not Implemented",0x0d,0x0a,0x0d,0x0a
%define lenError501 32
