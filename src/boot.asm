org 0x7c00

start:
    mov ah, 0x06
    mov al, 0x00
    mov ch, 0
    mov cl, 0
    mov dh, 0x24
    mov dl, 0x80
    mov bh, 0x07
    int 0x10

    mov ah, 0x02
    mov bh, 0
    mov dl, 0
    mov dh, 0
    int 0x10

    mov ah, 0x02
    mov al, 24
    mov ch, 0
    mov cl, 2
    mov dl, 0x80
    mov dh, 0
    xor bx, bx    
    mov es, bx
    mov bx, 0x7e00
    int 0x13
    jmp 0x7e00
    
times 510-($-$$) db 0 
dw 0xaa55