bits 16

; ======== AES Mathetmatical Primitives ========

; Polynomial multiplication over GF(2^8) modulo x^8 + x^4 + x^3 + x + 1
; si: first operand
; di: second operand
GaloisMultiply:
    xor ax, ax
    .loop:
        test si, si
        jle .exit
        test si, 0x1
        je .b_not_zero
        xor ax, di
        .b_not_zero: add di, di
        sar si, 0x1
        bt di, 0x8
        jae .loop
        .sxor: xor di, 0x11b
        jmp .loop
    .exit:
        ret

; Gets the GF(2^8) muliplicative inverse modulu x^8 + x^4 + x^3 + x + 1 of number in di
IGaloisMultiply:
    xor dx, dx
    mov cx, di
    test di, di     ; inverse of 0 = 0, it is the identity
    jz .exit
    ; test every possible number against parameter
    .loop:
        mov si, dx
        mov di, cx
        call GaloisMultiply
        dec ax
        jz .exit
        inc dx
        cmp dx, 0x100
        jne .loop
    .exit:
        mov ax, dx
        ret

; ======== Actual AES Functions ========

; Calculates s-box substitution of the byte given in al.
GetSBoxByte:
    push cx
    push si
    movzx di, al
    call IGaloisMultiply
    mov word [GaloisMultiply.sxor + 2], 0x0101
    movzx di, al
    mov si, 0x1f
    call GaloisMultiply
    xor al, 0x63
    mov word [GaloisMultiply.sxor + 2], 0x011b
    pop si
    pop cx
    ret

; si: round key
; di: state
AddRoundKey:
    mov cx, 0x10
    .xor_key:
        lodsb
        xor al, [di]
        stosb
        loop .xor_key
    ret

; di: state
ShiftRows:
    xor cx, cx
    .loop:
        movzx eax, byte [di]
        movzx edx, byte [di + 0x4]
        inc di
        shl edx, 0x10
        shl eax, 0x18
        or eax, edx
        movzx edx, byte [di + 0xb]
        or eax, edx
        movzx edx, byte [di + 0x7]
        shl edx, 0x8
        or eax, edx
        rol eax, cl
        add cx, 0x8
        mov edx, eax
        mov byte [di + 0x7], ah
        shr edx, 0x18
        mov byte [di + 0xb], al
        mov byte [di - 0x1], dl
        mov edx, eax
        shr edx, 0x10
        mov byte [di + 0x3], dl
        cmp cx, 0x20
        jne .loop
    ret

; di: state
MixColumns:
    xor cx, cx
    .loop:
        mov bx, cx
        shl bx, 2
        
        mov dl, byte [di + bx] ; first
        
        ; Calculate GF(2^8) sum of entire column
        movzx bp, byte [di + bx]
        movzx ax, byte [di + bx + 1]
        xor bp, ax
        movzx ax, byte [di + bx + 2]
        xor bp, ax
        movzx ax, byte [di + bx + 3]
        xor bp, ax

        ; First byte
        mov al, dl
        xor al, byte [di + bx + 1]

        push di
        movzx di, al
        mov si, 0x2
        call GaloisMultiply
        pop di
        xor ax, bp
        xor [di + bx], al
        
        ; Second byte
        mov al, byte [di + bx + 1]
        xor al, byte [di + bx + 2]

        push di
        movzx di, al
        mov si, 0x2
        call GaloisMultiply
        pop di
        xor ax, bp
        xor [di + bx + 1], al
        
        ; Third byte
        mov al, byte [di + bx + 2]
        xor al, byte [di + bx + 3]

        push di
        movzx di, al
        mov si, 0x2
        call GaloisMultiply
        pop di
        xor ax, bp
        xor [di + bx + 2], al

        ; Last byte
        mov al, byte [di + bx + 3]
        xor al, dl

        push di
        movzx di, al
        mov si, 0x2
        call GaloisMultiply
        pop di
        xor ax, bp
        xor [di + bx + 3], al

        inc cx
        cmp cx, 0x4
        jne .loop
    ret

; si: state
SubBytes:
    mov cx, 16
    .loop:
        lodsb
        call GetSBoxByte
        mov di, si
        dec di      ; needed since si is incremented after lodsb
        stosb
        loop .loop
    ret
