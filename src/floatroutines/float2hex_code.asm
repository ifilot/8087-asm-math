;------------------------------------------------------------------------------
; ROUTINE FLOAT_TO_HEX
;
; Output the 80 bit representation of a floating point number.
; Input: ST(0) - Floating point number
;        DI    - Pointer to char buffer
;
; Removes value from STACK
;------------------------------------------------------------------------------
float_to_hex:
    mov cx,10                       ; number of bytes
    fstp tword [temp_var]           ; store value in memory
    fwait
    lea si, [temp_var]              ; set source index
.nextbyte:
    lodsb                           ; load byte from SI, increment SI
    call .storehex
    test cl,1                       ; store a space every two bytes
    je .cont
    mov byte [di], ' '
    inc di
.cont:
    loop .nextbyte
    mov byte [di], '$'
    ret
; convert byte in AL to 2-digit HEX and store in DI
.storehex:
    mov ah, al
    shr al,1
    shr al,1
    shr al,1
    shr al,1
    call .storenibble
    mov al, ah
    and al, 0x0f
    call .storenibble
    ret
; convert nibble in AL to HEX and store in DI
.storenibble:
    cmp al, 10
    jl .digit
    add al, 'A' - 10
    jmp .done
.digit:
    add al, '0'
.done:
    stosb                           ; store AL in DI, increment DI
    ret