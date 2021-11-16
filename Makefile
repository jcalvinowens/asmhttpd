
asmhttpd: asmhttpd.o
	ld $^ -o $@

%.o: %.asm
	nasm -f elf64 -O0 -o $@ $<

clean:
	rm -f *.o asmhttpd
