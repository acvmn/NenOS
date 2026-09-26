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
    mov bx, ax
    or bx, dx
    je zero
    mov bx, 0
    push bx
    jmp check_number

check_number:
    cmp dx, 0
    jne push_number
    cmp ax, 0
    jne push_number
    jmp pop_number

push_number:
    mov bx, 10
    mov cx, ax
    mov ax, dx
    xor dx, dx
    div bx
    mov si, ax
    mov ax, cx
    div bx
    add dx, "0"
    push dx
    mov dx, si
    jmp check_number

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
    mov di, table

    jmp compare

compare:
    cmp di, end
    jae false

    mov bx, [di]
    mov cx, [di + 4]

    push si
    push di

    mov di, bx
    repe cmpsb

    pop di
    pop si

    je true

    add di, 6
    jmp compare

true:
    mov ax, [di + 2]
    jmp ax

false:
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

    mov dx, 0
    mov ax, [second]
    mov bx, 10
    mul bx
    cmp dx, 0
    jne calc_error
    mov [second], ax

    lodsb

    mov dl, al

    cmp al, "0"
    jl calc_error
    cmp al, "9"
    jg calc_error
    sub al, "0"
    mov ah, 0
    add [second], ax
    jc calc_error

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

    mov dx, 0
    mov ax, [first]
    mov bx, 10
    mul bx
    cmp dx, 0
    jne calc_error
    mov [first], ax

    lodsb

    mov cl, al

    cmp al, "0"
    jl calc_error
    cmp al, "9"
    jg calc_error
    sub al, "0"
    mov ah, 0
    add [first], ax
    jc calc_error

    jmp calc_first

calc_add:
    mov ax, [first]
    mov bx, [second]
    xor dx, dx
    add ax, bx
    adc dx, 0
    call number
    mov si, enter
    call print
    jmp return

calc_sub:
    mov ax, [first]
    mov bx, [second]
    cmp bx, ax
    ja calc_error
    xor dx, dx
    sub ax, bx
    mov dx, 0
    sbb dx, 0
    call number
    mov si, enter
    call print
    jmp return

calc_mul:
    mov dx, 0
    mov ax, [first]
    mov bx, [second]
    mul bx
    call number
    mov si, enter
    call print
    jmp return

calc_div:
    mov dx, 0
    mov ax, [first]
    mov bx, [second]
    cmp bx, dx
    je calc_error
    div bx
    mov dx, 0
    call number
    mov si, enter
    call print
    jmp return

calc:
    mov di, command
    mov al, " "
    mov ch, 0
    mov cl, dl
    repne scasb
    jne calc_error

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

help:
    mov si, available_commands
    call print
    
    jmp return

reboot:
    jmp 0xffff:0x0000

run:
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

stop:
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

exit:
    mov ah, 0x00
    int 0x16
    mov si, enter
    call print
    mov al, 0x00
    mov [running], al
    jmp return

break:
    push ax
    mov dx, 0x3d4
    mov al, 0x0a
    out dx, al
    inc dx
    in al, dx
    and al, 0xdf
    out dx, al
    pop ax
    cmp al, 27
    je exit
    mov ah, 0x00
    int 0x16
    mov si, enter
    call print
    mov al, 0x00
    mov [running], al
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
    jmp break

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

write:
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
    jmp input_write

input_write:
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
    jmp input_write

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

    mov ax, 0
    mov bx, 0
    mov cx, 0
    mov dx, 0
    mov [first], ax
    mov [second], ax

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
available_commands: db "Available Commands:", 10, 13, "  1. CALC <?> - calculate.", 10, 13, "  2. CLS - clear the screen.", 10, 13, "  3. ECHO <?> - print text to screen.", 10, 13, "  4. HELP - displaying available commands.", 10, 13, "  5. READ - read the document.", 10, 13, "  6. REBOOT - reboot the computer.", 10, 13, "  7. RUN - run the program.", 10, 13, "  8. TIME - launches the watch app.", 10, 13, "  9. WRITE - write the document.", 10, 13, 0
press_esc: db "Press <ESC> to save.", 10, 13, 0
saved: db "The document was saved.", 10, 13, 0
readed: db "Document:", 10, 13, 0
error: db "Unknown command.", 10, 13, 0
syntax: db "Syntax error.", 10, 13, 0
backspace: db 8, " ", 8, 0
enter: db 10, 13, 0
first: dw 0
second: dw 0
running: db 0x00

command_calc: db "calc", 0
command_cls: db "cls", 0
command_echo: db "echo", 0
command_help: db "help", 0
command_read: db "read", 0
command_reboot: db "reboot", 0
command_run: db "run", 0
command_time: db "time", 0
command_write: db "write", 0

table:
    dw command_calc, calc, 4
    dw command_cls, cls, 4
    dw command_echo, echo, 4
    dw command_help, help, 5
    dw command_read, read, 5
    dw command_reboot, reboot, 7
    dw command_run, run, 4
    dw command_time, time, 5
    dw command_write, write, 6

end:
    
command: times 256 db 0
document: times 512 db 0

times 8192-($-$$) db 0 