org 0x7c00

start:
    cli
    cld
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov sp, 0x7c00
    in al, 0x92
    or al, 2
    out 0x92, al

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