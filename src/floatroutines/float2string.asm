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