org 0x7c00

start:
    xor ax, ax
    mov es, ax
    mov sp, 0x7c00
    mov ah, 0x02
    mov al, 40
    mov ch, 0
    mov cl, 2
    mov dl, 0x80
    mov dh, 0  
    mov bx, 0x7e00
    int 0x13
    jmp 0x7e00
    
times 510-($-$$) db 0 
dw 0xaa55