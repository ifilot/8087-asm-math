CPU 8086

org 100h

; always start with a jump to the start of the programs
jmp start

; include float routines (code)
%include "floatroutines/float2scientific_code.asm"
%include "floatroutines/float2hex_code.asm"
%include "floatroutines/exp.asm"
%include "floatroutines/printstacktop.asm"

start:
    mov ax, cs
    mov ds, ax

    mov ax,7                    ; clear screen
    int 0x10                    ; call routine

    ; set-up 8087 and load values
    finit                       ; initialize 8087
    mov cx, 10
.loop:
    mov ax, 10
    sub ax, cx
    mov [temp_int], ax
    add ax, '0'
    mov ah, 0x0E
    int 0x10                    ; print parameter
    mov ah, 0x0E
    mov al, ' '                 ; print space
    int 0x10
    fild word [temp_int]        ; load parameter onto stack
    fwait
    call exp                    ; call exponential function
    call printfloat             ; print result on the screen
    loop .loop

    mov ah,0x09                 ; set routine
    mov dx, msg                 ; set pointer to string
    int 0x21                    ; print string

    ; wait for keypress
    mov ah,0x08
    int 0x21

    ; exit to DOS
    mov ax, 0x4c00
    int 21h

%include "io/io.asm"

section .data
    msg: DB "Press any key to exit...$"
    %include "floatroutines/float2scientific_data.asm"

section .bss
    ascii:          resb 20
    %include "floatroutines/float2hex_bss.asm"
    %include "floatroutines/float2scientific_bss.asm"