CPU 8086

org 100h

start:
    mov ax, cs
    mov ds, ax

    mov ax,7
    int 0x10

    finit
 
    fldz                    ; Load 0.0
    fstp tword [var01]
    fldpi                   ; Load pi again
    fstp tword [var02]

    lea si, [var01]
    call printhexfp80

    lea si, [var02]
    call printhexfp80

    fld1
    fadd st0,st0
    fsqrt
    fstp tword [var01]

    lea si, [var01]
    call printhexfp80

    mov ah,0x09
    mov dx, msg
    int 0x21

    ; wait for keypress
    mov ah,0x08
    int 0x21

    ; exit to DOS
    mov ax, 0x4c00
    int 21h

;------------------------------------------------------------------------------
; ROUTINE PRINTHEXFP80
;
; Output the 80 bit representation of a floating point number
;------------------------------------------------------------------------------
printhexfp80:
    mov cx,10
.nextbyte:
    lodsb
    mov dl,al
    call printhex
    test cl,1
    je .cont
    mov ah, 2
    mov dl, ' '
    int 0x21
.cont:
    loop .nextbyte
    mov dl,0x0D
    mov ah, 2
    int 0x21
    mov dl,0x0A
    int 0x21
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

var01: dt 0.0
var02: dt 0.0
msg: DB "Press any key to exit...$"