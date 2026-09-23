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

zero:
    mov al, "0"
    mov ah, 0x0e
    int 0x10
    ret

number:
    cmp ax, 0
    je zero
    mov bx, 0
    push bx
    jmp push_number

push_number:
    cmp ax, 0
    je pop_number
    mov dx, 0
    mov bx, 10
    div bx
    add dx, "0"
    push dx
    jmp push_number

pop_number:
    pop ax
    cmp ax, 0
    je done
    mov ah, 0x0e
    int 0x10
    jmp pop_number

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

    cmp al, " "
    je space

    cmp al, 8
    je back

    cmp al, 13
    je check

    call find

    cmp al, "a"
    jl skip
    cmp al, "z"
    jg skip

    cmp dl, 255
    je input

    stosb
    mov ah, 0x0e
    int 0x10
    inc dl
    jmp input

space:
    push di
    mov si, command
    mov di, command_calc
    mov cx, 4
    repe cmpsb
    pop di
    je argc

    push di
    mov si, command
    mov di, command_echo
    mov cx, 4
    repe cmpsb
    pop di
    je argc

    push di
    mov si, command
    mov di, command_sleep
    mov cx, 5
    repe cmpsb
    pop di
    je argc

    jmp input

argc:
    stosb
    mov ah, 0x0e
    int 0x10
    inc dl
    jmp input

find:
    push di
    mov dh, al
    mov di, command
    mov al, " "
    mov ch, 0
    mov cl, dl
    repne scasb
    pop di
    mov al, dh
    je argc
    ret

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
    mov di, command_calc
    mov cx, 4
    repe cmpsb
    je calc

    mov si, command
    mov di, command_cls
    mov cx, 4
    repe cmpsb
    je cls

    mov si, command
    mov di, command_echo
    mov cx, 4
    repe cmpsb
    je echo
    
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
    mov di, command_run
    mov cx, 4
    repe cmpsb
    je run

    mov si, command
    mov di, command_sleep
    mov cx, 5
    repe cmpsb
    je sleep
    
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

    mov al, 0xff
    cmp [running], al
    je programer
    
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

programer:
    mov al, 0x00
    mov [running], al

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

calc:
    cmp dl, 4
    je calc_error

    mov bl, 0
    mov bh, 0
    mov si, command
    add si, 5
    mov cl, 0
    call calc_first

    cmp dl, 0
    je calc_error

    cmp cl, "+"
    je calc_add
    cmp cl, "-"
    je calc_sub
    cmp cl, "*"
    je calc_mul
    cmp cl, "/"
    je calc_div

    jmp calc_error

calc_error:
    mov si, syntax
    call print
    jmp return

action_add:
    cmp cl, 0
    je calc_error
    mov dl, 0
    mov ah, 0
    mov cl, al
    jmp calc_second

action_sub: 
    cmp cl, 0
    je calc_error
    mov dl, 0
    mov ah, 0
    mov cl, al
    jmp calc_second

action_mul:
    cmp cl, 0
    je calc_error
    mov dl, 0
    mov ah, 0
    mov cl, al
    jmp calc_second

action_div:
    cmp cl, 0
    je calc_error
    mov dl, 0
    mov ah, 0
    mov cl, al
    jmp calc_second

calc_second:
    lodsb

    cmp al, 0
    je done

    dec si

    mov al, bh
    mov ah, 10
    mul ah
    mov bh, al

    lodsb

    mov dl, al

    cmp al, "0"
    jl calc_error
    cmp al, "9"
    jg calc_error
    sub al, "0"
    add bh, al

    jmp calc_second

calc_first:
    lodsb

    cmp al, "+"
    je action_add
    cmp al, "-"
    je action_sub
    cmp al, "*"
    je action_mul
    cmp al, "/"
    je action_div

    dec si

    mov al, bl
    mov ah, 10
    mul ah
    mov bl, al

    lodsb

    mov cl, al

    cmp al, "0"
    jl calc_error
    cmp al, "9"
    jg calc_error
    sub al, "0"
    add bl, al

    jmp calc_first

calc_add:
    mov al, bl
    mov ah, bh
    add al, ah
    mov ah, 0
    call number
    mov si, enter
    call print
    jmp return

calc_sub:
    mov al, bl
    mov ah, bh
    sub al, ah
    mov ah, 0
    call number
    mov si, enter
    call print
    jmp return

calc_mul:
    mov al, bl
    mov ah, bh
    mul ah
    call number
    mov si, enter
    call print
    jmp return

calc_div:
    mov al, bl
    mov ah, 0
    div bh
    mov ah, 0
    call number
    mov si, enter
    call print
    jmp return

cls:
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
    
    jmp return

found:
    mov si, di
    call print

    mov si, enter
    call print

    jmp return

echo:
    mov di, command
    mov al, " "
    mov ch, 0
    mov cl, dl
    repne scasb
    je found
    mov si, enter
    call print
    jmp return

print_help:
    mov si, help
    call print
    
    jmp return

reboot:
    jmp 0xffff:0x0000

run:
    mov dx, 0x3d4
    mov al, 0x0a
    out dx, al
    inc dx
    in al, dx
    or al, 0x20
    out dx, al
    dec dx

    mov ah, 0x03
    mov bh, 0
    int 0x10

    mov ah, 0x02
    mov bh, 0
    dec dh
    int 0x10

    mov si, 0
    mov bx, ds
    mov es, bx
    mov dx, 0
    mov [command], dx
    mov di, command
    mov dl, 0

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
    mov si, 0x9e00
    mov al, 0xff
    mov [running], al

    jmp loop

loop:
   lodsb
   push si
   cmp al, 10
   je check
   cmp al, 0
   je stop
   pop si
   stosb
   inc dl
   jmp loop

step:
    mov ah, 0x03
    mov bh, 0
    int 0x10

    mov ah, 0x02
    mov bh, 0
    dec dh
    int 0x10

    pop si
    mov bx, ds
    mov es, bx
    mov dx, 0
    mov [command], dx
    mov di, command
    mov dl, 0
    inc si

    mov ah, 0x01
    int 0x16
    jz loop
    jmp break

break:
    mov ah, 0x00
    int 0x16
    mov ah, 0x03
    mov bh, 0
    int 0x10
    mov ah, 0x02
    mov bh, 0
    inc dh
    int 0x10
    mov dx, 0x3d4
    mov al, 0x0a
    out dx, al
    inc dx
    in al, dx
    and al, 0xdf
    out dx, al
    mov al, 0x00
    mov [running], al
    jmp return

stop:
    mov dx, 0x3d4
    mov al, 0x0a
    out dx, al
    inc dx
    in al, dx
    and al, 0xdf
    out dx, al

    mov al, 0x00
    mov [running], al

    mov al, [command]
    cmp al, 0
    je null 

    jmp check

null:
    mov si, enter
    call print
    jmp return

sleep_argc:
    lodsb

    cmp al, 0
    je done

    dec si

    mov dx, 0
    mov ax, bx
    mov cx, 10
    mul cx
    mov bx, ax

    lodsb

    cmp al, "0"
    jl calc_error
    cmp al, "9"
    jg calc_error
    sub al, "0"
    mov ah, 0
    add bx, ax

    jmp sleep_argc

sleep:
    cmp dl, 5
    je calc_error

    mov bx, 0
    mov si, command
    add si, 6
    call sleep_argc

    mov ax, bx
    mov cx, 1000
    mul cx

    mov cx, dx
    mov dx, ax

    xor al, al
    mov ah, 0x86
    int 0x15

    jmp return

time:    
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
    
    mov si, enter
    call print
    jmp return

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

ready:
    mov si, press_esc
    call print

    mov si, 0
    mov bx, ds
    mov es, bx
    mov dx, 0
    mov [document], dx
    mov di, document
    mov dx, 0
    mov cx, 0
    jmp write

write:
    mov ah, 0x00
    int 0x16
    cmp al, 8
    je back_write
    cmp al, 27
    je save
    cmp cx, 511
    je write
    cmp al, 13
    je line
    stosb
    mov ah, 0x0e
    int 0x10
    inc dx
    inc cx
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
    
    mov si, enter
    call print
    
    mov si, saved
    call print
    
    jmp return

back_write:
    cmp dx, 0
    je write
    mov si, backspace
    dec di
    mov byte [di], 0
    call print
    dec dx
    dec cx
    jmp write

line:
    mov si, enter
    call print
    
    mov al, 10
    stosb
    mov al, 13
    stosb
    
    mov dx, 0
    inc cx
    
    jmp write

read:
    mov dx, 0
    mov [0x9e00], dx

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
    
    mov si, readed
    call print
    
    mov si, 0x9e00
    call print
    
    mov si, enter
    call print
    
    jmp return

return:
    mov al, 0xff
    cmp [running], al
    je step

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

welcome: db "Welcome to NenOS!", 10, 13, "Type <help> to show available commands.", 10, 13, 0
console: db "NenOS> ", 0
help: db "Available Commands:", 10, 13, "  1. CALC <?> - calculate.", 10, 13, "  2. CLS - clear the screen.", 10, 13, "  3. ECHO <?> - print text to screen.", 10, 13, "  4. HELP - displaying available commands.", 10, 13, "  5. READ - read the document.", 10, 13, "  6. REBOOT - reboot the computer.", 10, 13, "  7. RUN - run the program.", 10, 13, "  8. SLEEP <?> - time delay.", 10, 13, "  9. TIME - print time to screen.", 10, 13, " 10. WRITE - write the document.", 10, 13, 0
press_esc: db "Press <ESC> to save.", 10, 13, 0
saved: db "The document was saved.", 10, 13, 0
readed: db "Document:", 10, 13, 0
error: db "Unknown command.", 10, 13, 0
syntax: db "Syntax error.", 10, 13, 0
backspace: db 8, " ", 8, 0
enter: db 10, 13, 0
command_calc: db "calc"
command_cls: db "cls", 0
command_echo: db "echo"
command_help: db "help", 0
command_read: db "read", 0
command_reboot: db "reboot", 0
command_run: db "run", 0
command_sleep: db "sleep"
command_time: db "time", 0
command_write: db "write", 0
running: db 0x00
command: times 256 db 0
document: times 512 db 0

times 8192-($-$$) db 0 