all: ex01.com ex02.com ex03.com ex04.com ex05.com

# compile instructions
ex01.com: ex01.asm floatroutines/*.asm
	nasm -w+error -o ex01.com ex01.asm

ex02.com: ex02.asm floatroutines/*.asm
	nasm -w+error -o ex02.com ex02.asm

ex03.com: ex03.asm floatroutines/*.asm
	nasm -w+error -o ex03.com ex03.asm

ex04.com: ex04.asm floatroutines/*.asm
	nasm -w+error -o ex04.com ex04.asm

ex05.com: ex05.asm floatroutines/*.asm
	nasm -w+error -o ex05.com ex05.asm

# run in dosbox-x (more accurate representation of 8086 processor)
run: $(FILE).com
	dosbox-x -conf dosbox-x.conf -exit $(FILE).com