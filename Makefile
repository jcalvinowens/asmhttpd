asmhttpd:
	nasm -f elf64 -O0 -o ./asmhttpd.o src/master.asm
	ld asmhttpd.o -o asmhttpd

clean:
	rm -rf asmhttpd.o asmhttpd
