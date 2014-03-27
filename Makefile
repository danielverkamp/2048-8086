default: all

all: 2048.com

2048.com: 2048.asm color.inc boxchar.inc scancode.inc Makefile
	nasm -fbin $< -o $@

clean:
	rm -f 2048.com
