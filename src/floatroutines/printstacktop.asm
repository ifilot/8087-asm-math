;------------------------------------------------------------------------------
; ROUTINE PRINTSTACKTOP
;
; Prints the current stack pointer value, leaves the stack untouched.
; Garbles: [sw] value in memory
;
; This function is useful to check whether the operations keep the stack
; in the right order.
;
; Note: this function requires "float2scientific_bss.asm" to be loaded.
;------------------------------------------------------------------------------
printstacktop:
    push ax
    push bx
    push cx
    push dx
    fwait
    fstsw [sw]          ; Store the FPU Status Word into AX
    fwait
    mov dx, [sw]
    mov dl, dh          ; Move DH into DL (we only care about high byte)
    shr dl, 1
    shr dl, 1
    shr dl, 1
    and dl, 7           ; Mask to isolate TOP (3 bits)
    call printnibble
    call printcrnl
    pop dx
    pop cx
    pop bx
    pop ax
    ret