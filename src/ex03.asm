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
    fwait
    fldpi
    mov ax, 8
    mov [temp_int], ax
    fwait
    fild word [temp_int]
    fwait
    fdivp st1, st0              ; ST(0) = pi / 8 (ST(1) <- ST(1) / ST(0), then pop)
    fwait
    fld st0
    fwait
    call printfloathex
    fld st0
    fwait
    call printfloat
    fwait
    fptan                       ; apply y/x = tan(theta); x in ST(0); y in ST(1)
    fwait
    fdivp st1, st0              ; ST(0) = tan(theta) (ST(1) <- ST(1) / ST(0), then pop)
    fwait
    fld st0
    fwait
    call printfloathex
    fld st0
    fwait
    call printfloat             ; print result on the screen
    fst st0
    fwait
    fldpi
    mov ax, 128
    mov [temp_int], ax
    fwait
    fild word [temp_int]
    fwait
    fdivp st1, st0              ; ST(0) = pi / 8 (ST(1) <- ST(1) / ST(0), then pop)
    fwait
    fptan                       ; apply y/x = tan(theta); x in ST(0); y in ST(1)
    fwait
    fdivp st1, st0              ; ST(0) = tan(theta) (ST(1) <- ST(1) / ST(0), then pop)
    fwait
    fld st0
    fwait
    call printfloathex
    fld st0
    fwait
    call printfloat             ; print result on the screen
    fst st0


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