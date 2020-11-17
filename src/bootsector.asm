bits 16
org 0x7c00

jmp start


start:
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov es, ax

    mov ah, 0x2 ; read sectors from disk
    mov al, 1   ; sector count
    mov ch, 0   ; cylinder 0
    mov cl, 2   ; sector 2 (counting starts at 1)
    mov dh, 0   ; head 0
    mov dl, 0   ; drive 0
    mov bx, 0x7e00
    
    int 0x13    ; load round keys from disk

    mov bp, 0x7b00
    mov di, bp
    call read

    xor cx, cx
    .AESMain:
        mov bx, cx
        shl bx, 4
        lea si, [0x7e00 + bx]
        mov di, bp
        push cx
        call AddRoundKey
        pop cx

        cmp cx, 10
        je .exit
        inc cx
        push cx

        mov si, bp
        call SubBytes

        mov di, bp
        call ShiftRows

        pop cx
        cmp cx, 10
        je .AESMain

        push cx
        push bp
        mov di, bp
        call MixColumns
        pop bp
        pop cx
        jmp .AESMain
    
    .exit:
        mov si, newline
        call print
        mov si, bp
        mov di, 16
        call printhex
        cli
        hlt

%include "src/screen.asm"
%include "src/aes.asm"

times 510 - ($ - $$) db 0

dw 0xaa55
