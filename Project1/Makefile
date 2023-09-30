P=$(shell pwd)

.PHONY: build clean rebuild

build:
	# gcc -g -o ./executable main.c
	nasm -felf64 -g -o ./main.o $(P)/main.asm
	ld -o ./executable ./main.o

clean:
	rm -f ./main.o
	rm -f ./executable

rebuild: clean build