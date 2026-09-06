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
    mov di, command_reboot
    mov cx, 7
    repe cmpsb
    je reboot

    mov si, command
    mov di, command_time
    mov cx, 5
    repe cmpsb
    je time

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
    jmp 0xFFFF:0x0000

time:
    mov ah, 0x01
    mov cx, 0x2000
    int 0x10

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

exit:
    mov ah, 0x00
    int 0x16
    mov ah, 0x01
    mov cx, 0x0607
    int 0x10
    mov si, enter
    call print
    jmp return

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

welcome: db "Welcome to NenOS!", 10, 13, "Type <help> to show available commands.", 13, 10, 0
console: db "NenOS> ", 0
help: db "Available Commands:", 10, 13, "  1. CLS - clear the screen.", 10, 13, "  2. HELP - displaying available commands.", 10, 13, "  3. REBOOT - reboot the computer.", 10, 13, "  4. TIME - launches the watch app.", 10, 13, 0
error: db "Unknown command.", 10, 13, 0
backspace: db 8, " ", 8, 0
enter: db 10, 13, 0
command_cls: db "cls", 0
command_help: db "help", 0
command_reboot: db "reboot", 0
command_time: db "time", 0
command: db ""

times 8192-($-$$) db 0