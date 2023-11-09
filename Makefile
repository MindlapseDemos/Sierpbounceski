.PHONY: all
all: sierboun.com sierboun.img sierboun.rom

sierboun.com: sierboun.asm
	nasm -f bin -o $@ $<

sierboun.img: sierboun.asm
	nasm -f bin -DBOOTSECT -o $@ $<

sierboun.rom: sierboun.asm romfix
	nasm -f bin -DBOOTSECT -DROM -o $@ $<
	./romfix $@

romfix: romfix.c
	$(CC) -o $@ -g -Wall $<

.PHONY: clean
clean:
	rm -f sierboun.com sierboun.img sierboun.rom

.PHONY: boot
boot: sierboun.img
	qemu-system-i386 -fda $<

.PHONY: program
program: sierboun.rom
	minipro -p AT28C64B -w $<
