CPU 8086

section .data
ten         dw 10.0
dot_char    db '.'
E_char      db 'E'
plus_char   db '+'
minus_char  db '-'
zero_char   db '0'

section .bss
temp_int        resd 1        ; for significand digits
temp_exponent   resw 1
buffer          resb 32       ; output buffer

section .text
global float_to_string

; --------------------------
; Converts float on ST(0) to string in scientific notation
; Inputs:
;   ST(0) = float
;   DS:SI = pointer to output buffer
; Outputs:
;   string at DS:SI like "1.2345E+02"
; --------------------------
float_to_string:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    ; FXTRACT: ST(0) = significand, ST(1) = exponent
    fxtract

    ; Convert exponent (ST(1)) to integer
    fistp word [temp_exponent]
    mov cx, [temp_exponent]

    ; ST(0) = significand now

    ; Convert 5 digits of significand
    mov bx, 5              ; number of digits

.convert_digits:
    fld st0                ; duplicate ST(0)
    fimul word [ten]       ; multiply by 10
    fistp dword [temp_int] ; store integer part
    fidiv word [ten]       ; divide back to remove integer part
    mov ax, word [temp_int]
    add al, '0'
    stosb
    dec bx
    jnz .convert_digits

    ; Add decimal point
    mov al, '.'
    stosb

    ; Add E
    mov al, 'E'
    stosb

    ; Add sign of exponent
    cmp cx, 0
    jge .positive_exp
    mov al, '-'
    neg cx
    jmp .store_sign

.positive_exp:
    mov al, '+'
.store_sign:
    stosb

    ; Convert exponent (CX) to ASCII digits
    call print_decimal

    ; Null-terminate
    mov al, 0
    stosb

    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; ---------------------------
; print_decimal: converts CX to ASCII and stores at DS:DI
; Modifies: AX, CX, DX, DI
; ---------------------------
print_decimal:
    push ax
    push bx
    push dx

    mov bx, 10
    xor ax, ax
    mov dx, 0
    mov bp, sp             ; save current stack pointer
    mov ax, cx             ; move number into AX

.store_digits:
    xor dx, dx
    div bx                 ; AX / 10 → AX = quotient, DX = remainder
    push dx                ; store remainder (digit)
    cmp ax, 0
    jne .store_digits

.output_digits:
    pop dx
    add dl, '0'
    mov al, dl
    stosb
    cmp sp, bp
    jne .output_digits

    pop dx
    pop bx
    pop ax
    ret
