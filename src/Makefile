# compile instructions
ex01.com: ex01.asm
	nasm -w+error -o ex01.com ex01.asm

# run in dosbox-x (more accurate representation of 8086 processor)
rundosbox-x: ex01.com
	dosbox-x -exit -conf dosbox-x.conf ex01.com

# run in dosbox
rundosbox: ex01.com
	dosbox -exit ex01.com
