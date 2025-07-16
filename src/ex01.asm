CPU 8086

org 100h

start:
    mov ax, cs
    mov ds, ax

    mov ax,7
    int 0x10

    finit                   ; initialize 8087
 
    fldpi                   ; load pi in ST(0)
    fstp tword [var01]
    fldpi                   ; load pi in ST(0)
    fsqrt
    fstp tword [var02]      ; pop result from the stack

    ; try to print pi to console
    lea si, [var02]         ; set pointer to 80 bit value
    lea di, [ascii]         ; set pointer to char buffer
    call float_to_string    ; call routine
    mov ah,0x09
    mov dx, ascii
    int 0x21
    call printcrnl

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
    call printcrnl
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

;------------------------------------------------------------------------------
; Convert 80-bit float to ASCII
; Input:  [SI] = tword float
; Output: [DI] = ASCII string, null-terminated with '$'
; Clobbers: AX, BX, CX, DX, FPU stack
;------------------------------------------------------------------------------
float_to_string:
    fnstcw [old_cw]             ; save current control word
    mov ax, [old_cw]            ; load control word in ax
    or ah, 0x0C                 ; set rounding bits to 11 (truncate)
    mov [new_cw], ax            ; store updated control word
    fldcw [new_cw]              ; load modified control word into FPU

    fld tword [si]              ; ST(0) = floating point value in [si]
    fld st0                     ; ST(1) = copy of ST(0)

    ; Determine sign
    fabs                        ; ST(0) = |val|
    fcom st1                    ; ST(0) ? ST(1)
    fstsw word [status_word]    ; load status word in memory
    mov ax, [status_word]       ; move status word in ax
    sahf                        ; store AH into flags
    jb .negative                ; is negative?
    jmp .integer_part           ; if not, jump to integer part

.negative:
    mov byte [di], '-'
    inc di

.integer_part:
    fst st1                     ; ST(0) = |val|, ST(1) = |val|
    frndint                     ; round ST(0) to integer
    fsub st1, st0               ; ST(1) = original - int = fraction
    fistp word [temp_int]       ; ST(0) = fraction

    ; print integer
    mov ax, [temp_int]
    xor cx, cx
    test ax, ax
    jnz .store_digits
    mov byte [di], '0'
    inc di
    jmp .after_integer

.store_digits:
    push ax
.next_digit:
    xor dx, dx
    mov bx, 10
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .next_digit

.print_digits:
    pop dx
    add dl, '0'
    mov [di], dl
    inc di
    loop .print_digits
    pop ax

.after_integer:
    mov byte [di], '.'
    inc di

    mov cx, 6                   ; number of decimals
.frac_loop:
    fld tword [real10]          ; ST(0) = 10.0, ST(1) = fraction
    fmul                        ; ST(0) = fraction * 10
    fst st1                     ; update fraction
    frndint                     ; truncate remainder
    fld st0                     ; create copy
    fistp word [temp_int]       ; store digit, pop int

    mov ax, [temp_int]
    add al, '0'
    mov [di], al
    inc di

    fsub st1, st0
    fstp st0                    ; pop, now ST(0) = new fraction

    loop .frac_loop

    mov byte [di], '$'
    fldcw [old_cw]              ; restore original mode
.exit:
    ret


section .data
    real10: dt 10.0
    msg: DB "Press any key to exit...$"

section .bss
    ascii:          resb 20
    var01:          resb 10
    var02:          resb 10
    temp_int:       resb 2
    status_word:    resb 2
    old_cw:         resb 2
    new_cw:         resb 2