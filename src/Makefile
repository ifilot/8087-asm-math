all: ex01.com ex02.com ex03.com

# compile instructions
ex01.com: ex01.asm
	nasm -w+error -o ex01.com ex01.asm

ex02.com: ex02.asm
	nasm -w+error -o ex02.com ex02.asm

ex03.com: ex03.asm
	nasm -w+error -o ex03.com ex03.asm

ex04.com: ex04.asm
	nasm -w+error -o ex04.com ex04.asm

ex05.com: ex05.asm
	nasm -w+error -o ex05.com ex05.asm

# run in dosbox-x (more accurate representation of 8086 processor)
run: $(FILE).com
	dosbox -exit $(FILE).com