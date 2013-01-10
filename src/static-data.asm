Sighand_SIGPIPE:
	dq 0x0000000000000001		; SIG_IGN is 1
	dq 0x0000000000000000           ; FIXME: This works, but probably isn't right...

ChrootDirectory:
	db "/public/public",0x00 ; The directory we chroot() to before beginning to serve

SocketAddress:
	dw 0x0002			; AF_INET is 2 (AF_INET6 is 0xa)
	dw 0x5000			; TCP Port we want to bind to (:80) (Net byte ordering)
	dd 0x00000000                   ; Address to bind to (0.0.0.0 or ::)
	dd 0x00000000
	dd 0x00000000
	dd 0x00000000
	dd 0x00000000			; Not sure what this last null dword is for...

DecAsciiConvTable:
	db 0x30,0x31,0x21,0x32,0x33,0x21,0x34,0x21,0x35,0x36,0x21,0x37,0x38,0x21,0x39,0x21
