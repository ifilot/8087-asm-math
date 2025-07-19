;------------------------------------------------------------------------------
; EXP ROUTINE
;
; Calculates natural exponent, i.e. exp(x)
;
; Input: ST(0) - Floating point number x
;
; Leaves exp(x) at ST(0)
;------------------------------------------------------------------------------
exp:
    ; set up comparison routines
    fnstcw [old_cw]             ; save current control word
    fwait
    mov ax, [old_cw]            ; load control word in ax
    or ah, 0x0C                 ; set rounding bits to 11 (truncate)
    mov [new_cw], ax            ; store updated control word
    fldcw [new_cw]              ; load modified control word into FPU

    fldl2e                      ; ST(0) = log2(e), ST(1) = x
    fmulp                       ; ST(0) = x * log2(e)
    fld st0                     ; duplicate x * log2(e)
    frndint                     ; ST(0) = int(x), ST(1) = x
    fsub st1, st0               ; ST(1) = frac(x)
    fxch                        ; ST(0) = frac(x), ST(1) = int(x)
    f2xm1                       ; ST(0) = 2^frac(x) - 1
    fld1
    faddp                       ; ST(0) = 2^frac(x)
    fscale                      ; ST(0) = 2^frac(x) * 2^int(x) = 2^x
    fstp st1                    ; clean up
    fldcw [old_cw]              ; restore original mode
    ret