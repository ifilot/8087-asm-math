CPU 8086

org 100h

; always start with a jump to the start of the programs
jmp start

; include float routines (code)
%include "floatroutines/float2scientific_code.asm"
%include "floatroutines/float2hex_code.asm"
%include "floatroutines/exp.asm"

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

;------------------------------------------------------------------------------
; ROUTINE PRINTFLOAT
; Print floating point value in ST(0) to screen. Pops ST(0) from stack.
;------------------------------------------------------------------------------
printfloat:
    lea di, [ascii]             ; set pointer to char buffer
    call float_to_scientific    ; call routine
    mov ah,0x09
    mov dx, ascii
    int 0x21
    call printcrnl
    ret

;------------------------------------------------------------------------------
; ROUTINE PRINTWORDHEX
; Print value stored in DX as 4 digit hex
;
; Garbles: DL, AX
;------------------------------------------------------------------------------
printwordhex:
    push ax
    push dx
    mov dl, dh
    call printhex
    pop dx
    call printhex
    pop ax
    ret

;------------------------------------------------------------------------------
; ROUTINE PRINTHEX
; Print value stored in DL as two-digit hex
;
; Garbles: DL, AX
;------------------------------------------------------------------------------
printhex:
    mov dh, dl
    shr dl,1
    shr dl,1
    shr dl,1
    shr dl,1
    call printnibble
    mov dl, dh
    and dl, 0x0f
    call printnibble
    ret

;------------------------------------------------------------------------------
; ROUTINE PRINTNIBBLE
; Print nibble stored in DL
;
; Garbles: DL, AX
;------------------------------------------------------------------------------
printnibble:
    cmp dl, 10
    jl .digit
    add dl, 'A' - 10
    jmp .done
.digit:
    add dl, '0'
.done:
    mov ah, 2
    int 0x21
    ret

;------------------------------------------------------------------------------
; ROUTINE PRINTCRNL
;
; Print Carriage Return (0x0D) and New Line (0x0A)
;
; Garbles: AL, DL
;------------------------------------------------------------------------------
printcrnl:
    mov dl,0x0D
    mov ah, 2
    int 0x21
    mov dl,0x0A
    int 0x21
    ret

section .data
    msg: DB "Press any key to exit...$"
    %include "floatroutines/float2scientific_data.asm"

section .bss
    ascii:          resb 20
    %include "floatroutines/float2hex_bss.asm"
    %include "floatroutines/float2scientific_bss.asm"