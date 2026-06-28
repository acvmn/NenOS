org 0x7c00

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    mov [boot_drive], dl
    mov bx, 0x7e00
    mov dh, 10
    mov dl, [boot_drive]

    mov si, message
    call print
    call disk_load
    jmp 0x7e00

print:
    lodsb
    cmp al, 0
    je done
    mov ah, 0x0e
    int 0x10
    jmp print

done:

disk_load:
    mov si, dap
    mov [dap_buffer], bx
    mov ah, 0x42
    mov dl, [boot_drive]
    int 0x13
    ret

dap:
    db 0x10
    db 0
    dw 10

dap_buffer:
    dw 0
    dw 0
    dd 1
    dd 0

message: db "Loading kernel...", 10, 13, 0
boot_drive: db 0

times 510-($-$$) db 0
dw 0xaa55