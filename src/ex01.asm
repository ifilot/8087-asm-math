CPU 8086

org 100h

jmp start

start:
    mov ax, cs
    mov ds, ax

    mov ax,7
    int 0x10

    finit                   ; initialize 8087
    fldpi                   ; load pi in ST(0)
    fstp tword [var01]      ; pop to memory
    fldpi                   ; load pi in ST(0)
    fld tword [real10]
    fmulp
    fld st0
    fmulp

    ; try to print pi to console
    lea di, [ascii]         ; set pointer to char buffer
    call float_to_string    ; call routine
    mov ah,0x09
    mov dx, ascii
    int 0x21
    call printcrnl

    ;lea si, [var01]
    ;call printhexfp80

    ;lea si, [var02]
    ;call printhexfp80

    ;mov dx, [exp10]
    ;call printwordhex
    ;call printcrnl

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
;------------------------------------------------------------------------------
float_to_string:
    ; set up comparison routines
    fnstcw [old_cw]             ; save current control word
    mov ax, [old_cw]            ; load control word in ax
    or ah, 0x0C                 ; set rounding bits to 11 (truncate)
    mov [new_cw], ax            ; store updated control word
    fldcw [new_cw]              ; load modified control word into FPU

    ; Determine sign
    fld st0                     ; create copy of ST(0)
    fabs                        ; ST(0) = |val|
    fcom st1                    ; ST(0) ? ST(1)
    fstsw word [status_word]    ; load status word in memory
    fwait
    mov ax, [status_word]       ; move status word in ax
    sahf                        ; store AH into flags
    jb .negative                ; is negative?
    jmp .cont                   ; if not, jump to integer part

.negative:
    mov byte [di], '-'
    inc di

.cont:
    fstp st0                    ; ST(0) = abs(x); from here called x
    fld st0                     ; ST(0) = x, ST(1) = x
    fldlg2                      ; ST(0) = log10(2), ST(1) = x, ST(2) = x
    fxch                        ; ST(0) = x, ST(1) = log10(2), ...
    fyl2x                       ; ST(0) = log10(x), ST(1) = x
    frndint                     ; ST(0) = floor(log10(x)), ST(1) = x
    fist word [exp10]           ; store base-10 exponent (ok)

    ; Compute 10^exp10 via 2^(int + frac); first compute exp10 * log2(10)
    fldl2t                      ; ST(0) = log2(10), ST(1) = exp10, ST(2) = x
    fmulp                       ; ST(0) = exp10 × log2(10) = power, ST(1) = x

    ; Split into int + frac
    fld st0                     ; ST(0) = power, ST(1) = power
    frndint                     ; ST(0) = int part, ST(1) = power
    fsub st1, st0               ; ST(1) = x - int = frac
    fxch                        ; ST(0) = frac; ST(1) = int
    f2xm1                       ; ST(0) = 2^frac - 1
    fld1
    faddp                       ; ST(0) = 2^frac; ST(1) = int
    fscale                      ; ST(0) = 2^frac × 2^int = 10^exp10    
    fstp st1                    ; clean up integer part

    ; Divide original x by 10^exp10 to get mantissa
    fdiv                       ; ST(0) = x / 10^exp10 = mantissa

    fld st0
    frndint
    fist word [temp_int]        ; store digit, pop int
    mov ax, [temp_int]
    add al, '0'
    mov [di], al
    inc di

    fsub st1, st0
    fstp st0                    ; pop, now ST(0) = new fraction
    mov byte [di], '.'
    inc di

    mov cx, 10                  ; number of decimals
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

    mov byte [di], 'E'
    inc di
    mov ax, [exp10]
    call itoa16
    mov byte [di], '$'
    ret

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
itoa16:
    push ax
    push bx
    push cx
    push dx
    push si

    mov cx, 0              ; digit count
    mov bx, 10             ; divisor for base 10

    ; Handle sign
    cmp ax, 0
    jge .positive

    ; If negative, output '-' and negate AX
    mov byte [es:di], '-'
    inc di
    neg ax

.positive:
    xor dx, dx             ; clear high word for division
    mov si, di             ; remember where to start writing digits in reverse

.convert_loop:
    xor dx, dx             ; DX must be 0 before DIV
    div bx                 ; AX / 10 → quotient in AX, remainder in DL
    push dx                ; save remainder (digit)
    inc cx                 ; count digits
    test ax, ax
    jnz .convert_loop      ; repeat if quotient not zero

.output_digits:
    pop dx
    add dl, '0'            ; convert digit to ASCII
    mov [es:di], dl
    inc di
    loop .output_digits

    ; Null-terminate string
    mov byte [es:di], 0

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

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
    exp10       dw 0               ; will hold base-10 exponent (integer)
    real10      dt 10.0
    msg: DB "Press any key to exit...$"

section .bss
    temp_int        resd 1        ; for significand digits
    ascii:          resb 20
    var01:          resb 10
    var02:          resb 10
    status_word:    resb 2
    old_cw:         resb 2
    new_cw:         resb 2