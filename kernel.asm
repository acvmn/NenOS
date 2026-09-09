org 0x7e00

start:
    mov si, welcome
    call print
    mov si, console
    call print
    mov bx, ds
    mov es, bx
    mov di, command
    mov dl, 0
    jmp input

print:
    lodsb
    cmp al, 0
    je done
    mov ah, 0x0e
    int 0x10
    jmp print

done:
    ret

input:
    mov ah, 0x00
    int 0x16
    cmp al, 8
    je back
    cmp al, 13
    je check
    cmp al, "a"
    jl skip
    cmp al, "z"
    jg skip
    stosb
    mov ah, 0x0e
    int 0x10
    inc dl
    jmp input

skip:
    jmp input

back:
    cmp dl, 0
    je input
    mov si, backspace
    dec di
    mov byte [di], 0
    call print
    dec dl
    jmp input

check:
    mov al, 0
    stosb

    mov si, enter
    call print
    mov bl, 0

    mov si, command
    mov di, command_cls
    mov cx, 4
    repe cmpsb
    je cls

    mov si, command
    mov di, command_help
    mov cx, 5
    repe cmpsb
    je print_help

    mov si, command
    mov di, command_read
    mov cx, 5
    repe cmpsb
    je read

    mov si, command
    mov di, command_reboot
    mov cx, 7
    repe cmpsb
    je reboot

    mov si, command
    mov di, command_time
    mov cx, 5
    repe cmpsb
    je time

    mov si, command
    mov di, command_write
    mov cx, 6
    repe cmpsb
    je ready

    cmp dl, 0
    je return

    mov si, error
    call print
    mov si, console
    call print
    mov si, 0
    mov bx, ds
    mov es, bx
    mov di, command
    mov dl, 0
    jmp input

cls:
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    jmp return

print_help:
    mov si, help
    call print

    jmp return

reboot:
    jmp 0xffff:0x0000

exit:
    mov ah, 0x00
    int 0x16
    mov dx, 0x3d4
    mov al, 0x0a
    out dx, al
    inc dx
    in al, dx
    and al, 0xdf
    out dx, al
    mov si, enter
    call print
    jmp return

time:
    mov dx, 0x3d4
    mov al, 0x0a
    out dx, al
    inc dx
    in al, dx
    or al, 0x20
    out dx, al
    dec dx

    mov al, 13
    mov ah, 0x0e
    int 0x10
    
    mov ah, 0x02
    int 0x1a

    mov dl, ch
    call convert
    mov al, ":"
    mov ah, 0x0e
    int 0x10

    mov dl, cl
    call convert
    mov al, ":"
    mov ah, 0x0e
    int 0x10

    mov dl, dh
    call convert

    mov ah, 0x01
    int 0x16
    jz time
    jmp exit

convert:
    mov al, dl
    mov ah, al
    shr ah, 4
    add ah, "0"
    mov bh, ah
    
    mov al, dl
    shl al, 4
    shr al, 4
    add al, "0"
    mov bl, al

    mov al, bh
    mov ah, 0x0e
    int 0x10

    mov al, bl
    mov ah, 0x0e
    int 0x10

    mov al, 0
    ret

return:
    mov si, console
    call print

    mov si, 0
    mov bx, ds
    mov es, bx
    mov dx, 0
    mov [command], dx
    mov di, command
    mov dl, 0
    jmp input

read:
    mov si, readed
    call print

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 18
    mov dl, 0x80
    mov dh, 0
    mov bx, 0x9e00
    int 0x13
    jc disk_error

    mov si, 0x9e00
    call print

    mov si, enter
    call print

    jmp return

ready:
    mov si, esc
    call print

    mov si, 0
    mov bx, ds
    mov es, bx
    mov dx, 0
    mov [document], dx
    mov di, document
    mov dl, 0
    jmp write

back_write:
    cmp dl, 0
    je write
    mov si, backspace
    dec di
    mov byte [di], 0
    call print
    dec dl
    jmp write

next:
    mov si, enter
    call print

    mov al, 10
    stosb
    mov al, 13
    stosb

    mov dl, 0

    jmp write

write:
    mov ah, 0x00
    int 0x16
    cmp al, 8
    je back_write
    cmp al, 13
    je next
    cmp al, 27
    je save
    stosb
    mov ah, 0x0e
    int 0x10
    inc dl
    jmp write

save:
    mov al, 0
    stosb

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov si, document
    mov cx, 512
    mov bx, document
    mov ah, 0x03
    mov al, 1
    mov ch, 0
    mov cl, 18
    mov dl, 0x80
    mov dh, 0
    int 0x13
    jc disk_error

    mov si, enter
    call print

    mov si, saved
    call print

    jmp return

disk_error:
    mov si, disk
    call print
    jmp return

welcome: db "Welcome to NenOS!", 10, 13, "Type <help> to show available commands.", 10, 13, 0
console: db "NenOS> ", 0
esc: db "Press <ESC> to save.", 10, 13, 0
saved: db "The document was saved.", 10, 13, 0
readed: db "Document:", 10, 13, 0
disk: db "Disk error.", 10, 13, 0
error: db "Unknown command.", 10, 13, 0
help: db "Available Commands:", 10, 13, "  1. CLS - clear the screen.", 10, 13, "  2. HELP - displaying available commands.", 10, 13, "  3. READ - read the document.", 10, 13, "  4. REBOOT - reboot the computer.", 10, 13, "  5. TIME - launches the watch app.", 10, 13, "  6. WRITE - write the document.", 10, 13, 0
backspace: db 8, " ", 8, 0
enter: db 10, 13, 0
command_cls: db "cls", 0
command_help: db "help", 0
command_read: db "read", 0
command_reboot: db "reboot", 0
command_time: db "time", 0
command_write: db "write", 0
command: db 0
document: db 0

times 8192-($-$$) db 0