asmhttpd:
	nasm -f elf64 -O0 -o ./nanohttpd.o src/master.asm
	ld nanohttpd.o -o nanohttpd

clean:
	rm nanohttpd.o nanohttpd
