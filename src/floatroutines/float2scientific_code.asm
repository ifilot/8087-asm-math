;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------

CPU 8086

;------------------------------------------------------------------------------
; FLOAT_TO_SCIENTIFIC ROUTINE
;
; Converts a floating point number in ST(0) to a ASCII-string using scientific
; notation (e.g. 1.234567890e+12).
;
; Input: ST(0) - Floating point number
;        DI    - Pointer to char buffer
;
; Removes value from STACK
;------------------------------------------------------------------------------
float_to_scientific:
    push ax                     ; store register on stack
    push bx
    push cx
    push dx
    ; set up comparison routines
    fstcw [old_cw]              ; save current control word
    fwait
    mov ax, [old_cw]            ; load control word in ax
    or ah, 0x0C                 ; set rounding bits to 11 (truncate)
    mov [new_cw], ax            ; store updated control word
    fldcw [new_cw]              ; load modified control word into FPU
    ; determine sign
    fld st0                     ; create copy of ST(0)
    fabs                        ; ST(0) = |val|
    fcom st1                    ; ST(0) ? ST(1)
    fstsw word [sw]             ; load status word in memory
    fwait                       ; wait until CPU has written the status
    mov ax, [sw]                ; move status word in ax
    sahf                        ; store AH into flags
    jb .negative                ; is negative?
    mov byte [di], ' '          ; if positive, prepend by space
    jmp .cont                   ; if not, jump to integer part
.negative:
    mov byte [di], '-'
.cont:
    inc di
    ; construct 10-based exponent by calculating:
    ; exp10 = floor(log10(2) * log2(x))
    fstp st1                    ; continue only with absolute value
    fld st0                     ; ST(0) = x, ST(1) = x
    fldlg2                      ; ST(0) = log10(2), ST(1) = x, ST(2) = x
    fxch                        ; ST(0) = x, ST(1) = log10(2), ...
    fyl2x                       ; ST(0) = log10(x), ST(1) = x
    frndint                     ; ST(0) = floor(log10(x)), ST(1) = x
    fist word [exp10]           ; store base-10 exponent (ok)
    ; compute 10^exp10 via 2^(int + frac)
    ; first compute exp10 * log2(10)
    fldl2t                      ; ST(0) = log2(10), ST(1) = exp10, ST(2) = x
    fmulp                       ; ST(0) = exp10 * log2(10) = power, ST(1) = x
    ; split into int + frac
    fld st0                     ; ST(0) = power, ST(1) = power
    frndint                     ; ST(0) = int part, ST(1) = power
    fsub st1, st0               ; ST(1) = x - int = frac
    fxch                        ; ST(0) = frac, ST(1) = int, ST(2) = x
    f2xm1                       ; ST(0) = 2^frac - 1, ST(1) = int, ST(2) = x
    fld1                        ; ST(0) = 1, ST(1) = 2^frac - 1, ...
    faddp                       ; ST(0) = 2^frac, ST(1) = int, ST(2) = x
    fscale                      ; ST(0) = 2^frac * 2^int = 10^exp10, ST(1) = int    
    fstp st1                    ; ST(0) = 10^exp10, ST(1) = x
    ; divide original x by 10^exp10 to get mantissa
    fdiv                        ; ST(0) = x / 10^exp10 = mantissa
    fstp st1                    ; remove ST(1)
    ; here, we only have the mantissa on the stack, this mantissa lies between
    ; [1, 10), so we can safely extract the leading digit and store that
    ; in the string
    fld st0                     ; create copy of mantissa for first digit
    frndint                     ; truncate to get first digit
    fist word [temp_int]        ; store digit
    fwait                       ; wait needed because memory write
    call .temp_to_digit         ; place the extracted digit in the string
    fsubp st1, st0              ; subtract integer from mantissa and pop
    mov byte [di], '.'          ; insert decimal point
    inc di                      ; increment pointer
    ; here we proceed by extracting 11 decimals
    mov cx, 11                  ; number of decimals
.frac_loop:
    fld tword [real10]          ; ST(0) = 10.0, ST(1) = mantissa
    fmulp                       ; ST(0) = mantissa * 10
    fst st1                     ; update mantissa
    frndint                     ; truncate remainder
    fist word [temp_int]        ; store digit
    fwait
    call .temp_to_digit
    fsubp st1, st0              ; subtract integer from mantissa and pop
    loop .frac_loop             ; continue extracting digits
    ; all decimals have been written, now write exponent part
    mov byte [di], 'e'          ; write exponent symbol
    inc di                      ; increment pointer
    mov ax, [exp10]             ; load signed int (exp10) into AX
    call int16_to_expstring     ; call function to convert
    mov byte [di], '$'          ; write terminating symbol
    fldcw [old_cw]              ; restore original mode
    fstp st0                    ; clear stack
    pop dx
    pop cx
    pop bx
    pop ax
    ret
.temp_to_digit:
    mov ax, [temp_int]
    add al, '0'
    mov [di], al
    inc di
    ret

;------------------------------------------------------------------------------
; INT16_TO_EXPSTRING ROUTINE
;
; Converts a 16 bit signed value in AX to a formatted string used as the
; trailing (exponent) part in scientific notation. The formatted string is
; built up as follows: (sign)(digits) where at least two digits are being
; printed, potentially prepended by zeros.
;
; Input:    AX - 16 bit signed integer
;           DS - string pointer
; Garbles:  DS (auto-incremented)
;
; First, all digits are being collected by continuously dividing by 10 and
; putting the result on the stack. After digits have been collected, the
; stack is popped and the digits are put in the ASCII string.
;------------------------------------------------------------------------------
int16_to_expstring:
    push ax                 ; store register on stack
    push bx
    push cx
    push dx
    push si
    mov cx, 0               ; digit count
    mov bx, 10              ; divisor for base 10
    cmp ax, 0               ; check sign
    jge .positive           ; if positive, print '+'
    mov byte [di], '-'      ; if not, print '-'
    neg ax
    jmp .cont
.positive:
    mov byte [di], '+'      ; print '+'
.cont:
    inc di                  ; increment pointer
    xor dx, dx              ; clear high word for division
    mov si, di              ; remember where to start writing digits in reverse
.convert_loop:
    xor dx, dx              ; DX must be 0 before DIV
    div bx                  ; AX / 10 -> quotient in AX, remainder in DL
    push dx                 ; save remainder (digit)
    inc cx                  ; count digits
    test ax, ax
    jnz .convert_loop       ; repeat if quotient not zero
.output_digits:
    cmp cx, 1
    jne .print_digits       ; if more than 1 digit, skip padding
    mov dl, '0'             ; add leading zero before popping the only digit
    mov [es:di], dl
    inc di
.print_digits:
    pop dx
    add dl, '0'
    mov [di], dl
    inc di
    loop .print_digits
    pop si                  ; restore all registers (except DI)
    pop dx
    pop cx
    pop bx
    pop ax
    ret