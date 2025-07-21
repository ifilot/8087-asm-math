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
; ROUTINE PRINTFLOATHEX
;------------------------------------------------------------------------------
printfloathex:
    lea di, [ascii]
    call float_to_hex           ; print result on the screen
    mov ah,0x09                 ; set routine
    mov dx, ascii               ; set pointer to string
    int 0x21                    ; print string
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