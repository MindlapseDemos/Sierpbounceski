.PHONY: all
all: sierboun.com sierboun.img

sierboun.com: sierboun.asm
	nasm -f bin -o $@ $<

sierboun.img: sierboun.asm
	nasm -f bin -DBOOTSECT -o $@ $<

.PHONY: clean
clean:
	rm -f sierboun.com sierboun.img

.PHONY: boot
boot: sierboun.img
	qemu-system-i386 -fda $<
