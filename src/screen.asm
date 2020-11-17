bits 16

; di: count
; si: buffer
printhex:
    mov ah, 0xe
    .loop:
        lodsb
        mov dl, al
        mov cl, 2
        .inner:
            rol dl, 4
            mov bx, 0x000f
            and bl, dl
            mov al, [hex + bx]
            int 0x10
            dec cl
            jnz .inner
        mov al, 0x20
        int 0x10
        dec di
        test di, di
        jnz .loop
    ret

; si: null-terminated string
print:
    mov ah, 0xe
    .loop:
        lodsb
        int 0x10    ; int 0x10, ah = 0xe: Print char to screen
        test al, al
        jnz .loop
    ret

; di: buffer
read:
    .loop:
        xor ax, ax
        int 0x16    ; int 0x16, ah = 0x0: read single char
        stosb
        cmp al, 13  ; is carriage return?
        jz .exit

        mov ah, 0xe
        int 0x10
        jmp .loop
    .exit:
        mov byte [di - 1], 0    ; null-terminated instead of carriage return
        ret

newline: db 13,10,0
hex: db "0123456789abcdef"
