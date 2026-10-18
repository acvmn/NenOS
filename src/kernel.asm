org 0x7e00

start:
    pop ax
    mov ax, 0x1110
    mov bh, 16
    mov bl, 0
    mov cx, 256
    mov dx, 0
    push ds
    pop es
    mov bp, font
    int 0x10
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
    mov si, welcome
    call print
    mov si, console
    call print
    mov bx, 0
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

print_enter:
    mov al, 10
    mov ah, 0x0e
    int 0x10
    jmp print

print:
    lodsb
    cmp al, 0
    je done
    mov ah, 0x0e
    int 0x10
    cmp al, 13
    je print_enter
    jmp print

done:
    ret

input:
    mov ah, 0x00
    int 0x16

    cmp ah, 0x0f
    je input_change

    cmp al, 8
    je back

    cmp al, 13
    je check

    cmp dl, 255
    je input

    cmp dl, 255
    je input

    call cp866

    mov ah, 0x0e
    int 0x10
    inc dl
    stosb
    jmp input

input_change:
    xor byte [lang], 1
    jmp input

cmd_lower:
    mov al, [si]
    cmp al, " "
    je done
    call to_lower
    mov [si], al
    inc si
    jmp cmd_lower

to_lower:
    cmp al, "A"
    jb done
    cmp al, "Z"
    ja done
    or al, 0x20
    ret

back:
    cmp dl, 0
    je input
    push dx
    call check_line
    mov al, " "
    mov ah, 0x0a
    mov bh, 0
    mov cx, 1
    int 0x10
    dec di
    mov byte [di], 0
    pop dx
    dec dl
    jmp input

check:
    mov al, " "
    stosb

    mov al, 0
    stosb

    mov si, enter
    call print
    mov bl, 0

    mov si, command
    mov di, cmd_table

    call skip_space

    push si
    call cmd_lower
    pop si

    jmp check_compare

check_compare:
    cmp di, cmd_end
    jae check_false

    mov bx, [di]
    mov cx, [di + 4]

    push si
    push di

    mov di, bx
    repe cmpsb

    pop di
    pop si

    je check_true

    add di, 6
    jmp check_compare

check_true:
    mov cx, [di + 4]
    add si, cx
    cmp byte [si], " "
    jne check_false

    mov ax, [di + 2]
    jmp ax

check_false:
    cmp dl, 0
    je return

    mov si, error
    call print

    jmp return

cp866:
    mov dh, 0
    cmp [lang], dh
    je done

    push bx
    push si
    push dx

    mov dl, al

    mov bx, lower
    cmp al, "A"
    jb  cp866_lower
    cmp al, "Z"
    ja  cp866_lower
    mov bx, upper

    jmp cp866_lower

cp866_lower:
    mov si, bx
    mov bl, ah
    mov bh, 0
    add si, bx
    mov al, [si]
    test al, al
    jnz cp866_done
    mov al, dl
    jmp cp866_done

cp866_done:
    pop dx
    pop si
    pop bx
    ret

calc_error:
    pop ax
    mov si, argcs
    call print
    jmp return

first_space:
    lodsb
    cmp al, "+"
    je action_add
    cmp al, "-"
    je action_sub
    cmp al, "*"
    je action_mul
    cmp al, "/"
    je action_div
    cmp al, " "
    je first_space
    jmp calc_error

action_add:
    cmp cl, 0
    je calc_error
    mov dl, 0
    mov ah, 0
    mov cl, al
    call skip_space
    jmp calc_second

action_sub: 
    cmp cl, 0
    je calc_error
    mov dl, 0
    mov ah, 0
    mov cl, al
    call skip_space
    jmp calc_second

action_mul:
    cmp cl, 0
    je calc_error
    mov dl, 0
    mov ah, 0
    mov cl, al
    call skip_space
    jmp calc_second

action_div:
    cmp cl, 0
    je calc_error
    mov dl, 0
    mov ah, 0
    mov cl, al
    call skip_space
    jmp calc_second

calc_second:
    lodsb

    cmp al, 0
    je done
    cmp al, " "
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
    cmp al, " "
    je first_space

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
    xor dx, dx
    sub ax, bx
    mov dx, 0
    sbb dx, 0
    cmp dx, 0
    jne negative
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

negative:
    mov al, "-"
    mov ah, 0x0e
    int 0x10
    mov ax, [first]
    mov bx, [second]
    xor dx, dx
    sub bx, ax
    mov ax, bx
    mov dx, 0
    sbb dx, 0
    call number
    mov si, enter
    call print
    jmp return

calc:
    call skip_space
    mov cl, 0
    call calc_first

    call skip_space

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

to_space:
    lodsb
    cmp al, " "
    je done
    cmp al, 0
    je done
    jmp to_space

cls:
    call skip_space

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

copy:
    call skip_space
    mov cl, 0
    call argc_file
    mov [src], cl

    call to_space

    call skip_space
    cmp byte [si], 0
    je calc_error
    mov cl, 0
    call argc_file
    mov [dst], cl

    mov dx, 0
    mov [0x9e00], dx

    mov ah, 0x02
    mov al, 1
    mov dl, 0x80
    mov dh, 0
    mov ch, 0
    mov cl, [src]
    mov bx, 0x9e00
    int 0x13

    mov si, 0x9e00
    mov di, document
    mov cx, 512
    rep movsb

    mov si, document
    mov cx, 512
    mov bx, document
    mov ah, 0x03
    mov al, 1
    mov ch, 0
    mov cl, [dst]
    mov dl, 0x80
    mov dh, 0
    int 0x13

    jmp return

create:
    call skip_space
    push si

    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 42
    mov dl, 0x80
    mov dh, 0
    mov bx, 0x9e00
    int 0x13

    mov cx, 32
    mov bx, 0x9e00
    jmp create_dup

create_dup:
    cmp byte [bx], 0
    je next_dup
    push bx
    push si
    mov dx, 15
    jmp cmp_dup

cmp_dup:
    mov al, [bx]
    mov ah, [si]

    cmp ah, 0
    je dup_end

    cmp al, ah
    jne not_dup

    cmp al, 0
    je create_exists

    inc bx
    inc si
    dec dx
    jnz cmp_dup
    jmp create_exists

dup_end:
    cmp al, 0
    je create_exists
    jmp not_dup

not_dup:
    pop si
    pop bx
    jmp next_dup

next_dup:
    add bx, 16
    dec cx
    jnz create_dup
    mov bx, 0x9e00
    mov cx, 32
    jmp file_empty

file_empty:
    cmp byte [bx], 0
    je empty_found
    add bx, 16
    dec cx
    jnz file_empty
    mov si, full
    call print
    jmp return

create_exists:
    pop si
    pop bx
    pop si
    mov si, exists
    call print
    jmp return

empty_found:
    mov ax, bx
    sub ax, 0x9e00
    shr ax, 4
    inc ax
    mov dx, ax
    mov di, bx
    pop si
    mov cx, 15
    jmp create_copy

create_copy:
    lodsb
    cmp al, 0
    je create_zero
    stosb
    loop create_copy
    jmp write_sector

create_zero:
    xor al, al
    stosb
    loop create_zero
    jmp write_sector

write_sector:
    add dx, 42
    mov ax, dx
    mov [di], al

    mov ah, 0x03
    mov al, 1
    mov ch, 0
    mov cl, 42
    mov dl, 0x80
    mov dh, 0
    mov bx, 0x9e00
    int 0x13

    jmp return

pad_zero:
    xor al, al
    stosb
    loop pad_zero
    jmp write_sector

delete:
    call skip_space
    push si

    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 42
    mov dl, 0x80
    mov dh, 0
    mov bx, 0x9e00
    int 0x13

    mov cx, 32
    mov bx, 0x9e00
    jmp delete_loop

delete_loop:
    cmp byte [bx], 0
    je delete_next
    push bx
    push si
    mov dx, 15
    jmp delete_cmp

delete_cmp:
    mov al, [bx]
    cmp al, [si]
    jne delete_differ
    cmp al, 0
    je delete_found
    inc bx
    inc si
    dec dx
    jnz delete_cmp
    jmp delete_found

delete_differ:
    pop si
    pop bx
    jmp delete_next

delete_next:
    add bx, 16
    dec cx
    jnz delete_loop

    pop si
    mov si, not_found
    call print
    jmp return

delete_found:
    pop si
    pop bx
    mov al, [bx + 15]
    mov [del_sector], al
    mov cx, 16
    jne delete_delete

delete_delete:
    mov byte [bx], 0
    inc bx
    loop delete_delete

    mov ah, 0x03
    mov al, 1
    mov ch, 0
    mov cl, 42
    mov dl, 0x80
    mov dh, 0
    mov bx, 0x9e00
    int 0x13

    mov cl, [del_sector]
    test cl, cl
    jz return

    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov dl, 0x80
    mov dh, 0
    mov bx, 0x9e00
    int 0x13

    mov di, 0x9e00
    mov cx, 512
    xor al, al
    rep stosb

    mov ah, 0x03
    mov al, 1
    mov ch, 0
    mov cl, [del_sector]
    mov dl, 0x80
    mov dh, 0
    mov bx, 0x9e00
    int 0x13

    jmp return

dir:
    call skip_space
    push si

    mov si, dir_list
    call print

    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 42
    mov dl, 0x80
    mov dh, 0
    mov bx, 0x9e00
    int 0x13

    mov cx, 32
    xor bl, bl
    mov si, 0x9e00
    jmp dir_loop

dir_loop:
    cmp byte [si], 0
    je dir_next

    mov bl, 1
    push si
    mov dx, 15

    push si
    mov si, dir_tab
    call print
    pop si

    jmp dir_print

dir_print:
    mov al, [si]
    cmp al, 0
    je dir_line
    mov ah, 0x0e
    int 0x10
    inc si
    dec dx
    jnz dir_print
    jmp dir_line

dir_line:
    pop si
    mov al, " "
    mov ah, 0x0e
    int 0x10
    mov al, 13
    mov ah, 0x0e
    int 0x10
    mov al, 10
    int 0x10
    jmp dir_next

dir_next:
    add si, 16
    dec cx
    jnz dir_loop
    jmp return

help:
    call skip_space

    mov si, available_commands
    call print
    
    jmp return

reboot:
    call skip_space

    jmp 0xffff:0x0000

run_error:
    mov si, not_bin
    call print

    jmp return

run:
    call skip_space
    mov cl, 0
    call argc_file

    call skip_space

    mov dx, 0
    mov [0x9e00], dx

    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov dl, 0x80
    mov dh, 0
    mov bx, 0x9e00
    int 0x13

    cmp byte [0x9e00], 0x90
    jne run_error
    
    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx
    xor si, si
    xor di, di
    xor bp, bp
    xor sp, sp
    call 0x9e00

    mov si, enter
    call print
    
    jmp return

break:
    mov dx, 0x3d4
    mov al, 0x0a
    out dx, al
    inc dx
    in al, dx
    and al, 0xdf
    out dx, al
    mov ah, 0x00
    int 0x16
    mov si, enter
    call print
    jmp return

time:
    call skip_space
    jmp bcd

bcd:
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
    jz bcd
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
    mov al, 0
    mov [command], al

    call skip_space
    mov cl, 0
    call argc_file
    mov ch, 0
    push cx

    mov si, press_esc
    call print

    mov dx, 0
    mov [0x9e00], dx

    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov dl, 0x80
    mov dh, 0
    mov bx, 0x9e00
    int 0x13
    
    mov si, 0x9e00
    call print

    mov si, 0
    mov bx, ds
    mov es, bx
    mov dx, 0
    mov [document], dx
    mov di, document
    mov cx, 0

    mov si, 0x9e00
    mov di, document
    mov cx, 512
    rep movsb

    mov di, document
    mov al, 0
    mov cx, 512
    repne scasb
    sub di, document
    dec di
    mov si, di

    mov di, document
    add di, si
    mov cx, si

    jmp input_write

input_write:
    mov ah, 0x00
    int 0x16
    cmp ah, 0x0f
    je write_change
    cmp al, 8
    je back_write
    cmp al, 27
    je save
    cmp cx, 512
    je input_write
    cmp al, 13
    je line
    call cp866
    stosb
    mov ah, 0x0e
    int 0x10
    inc cx
    jmp input_write

write_change:
    xor byte [lang], 1
    jmp input_write

save:
    mov al, 0
    stosb

    mov si, document
    mov cx, 512
    mov bx, document
    mov ah, 0x03
    mov al, 1
    pop cx
    mov dl, 0x80
    mov dh, 0
    int 0x13
    
    mov si, enter
    call print
    
    mov si, saved
    call print
    
    jmp return

pointer:
    add dl, 7
    jmp loop_line

back_line:
    cmp dh, 0
    je read_line

    mov ah, 0x03
    mov bh, 0
    int 0x10
    dec dh

    mov ah, 0x08
    mov bh, 0
    int 0x10
    cmp al, " "
    jne done_last

    mov dl, 0
    mov si, di
    dec si

    mov al, [command]
    cmp al, 0
    jne pointer
    jmp loop_line

line:
    mov si, enter
    call print
    
    mov al, 13
    stosb
    
    inc cx
    
    jmp input_write

done_line:
    mov ah, 0x03
    mov bh, 0
    int 0x10

    mov ah, 0x02
    mov bh, 0
    inc dl
    int 0x10

    ret

done_last:
    mov al, " "
    mov ah, 0x0a
    mov bh, 0
    mov bl, 0
    mov cx, 1
    int 0x10
    ret

done_after:
    mov ah, 0x03
    mov bh, 0
    int 0x10

    mov ah, 0x02
    mov bh, 0
    mov dl, 79
    dec dh
    int 0x10

    ret

back_write:
    cmp cx, 0
    je input_write
    push cx
    call check_line
    mov al, " "
    mov ah, 0x0a
    mov bh, 0
    mov bl, 0
    mov cx, 1
    int 0x10
    dec di
    mov byte [di], 0
    pop cx
    dec cx
    jmp input_write

read_width:
    cmp dl, 80
    jb read_print
    sub dl, 80
    jmp read_width

read_print:
    mov si, di
    mov dh, 0
    sub si, dx
    dec si
    call print
    mov ah, 0x02
    mov bh, 0
    int 0x10
    ret

read_loop:
    dec si
    mov al, [si]
    cmp al, 0
    je read_width
    cmp al, 13
    je read_width
    inc dl
    jmp read_loop

read_line:
    mov ah, 0x02
    mov bh, 0
    mov dx, 0
    int 0x10
    mov dl, 0
    mov si, di
    dec si
    jmp read_loop

check_line:
    mov ah, 0x03
    mov bh, 0
    int 0x10

    cmp dl, 0
    je back_line

    mov al, 8
    mov ah, 0x0e
    int 0x10
    ret

loop_line:
    dec si
    mov al, [si]
    cmp al, 0
    je line_done
    cmp al, 13
    je line_done
    inc dl
    jmp loop_line

line_done:
    mov ah, 0x02
    mov bh, 0
    int 0x10
    ret

read:
    call skip_space
    mov cl, 0
    call argc_file

    mov dx, 0
    mov [0x9e00], dx

    mov ah, 0x02
    mov al, 1
    mov ch, 0
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

argc_file:
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 42
    mov dh, 0
    mov dl, 0x80
    mov bx, 0x9e00
    int 0x13

    mov bx, 0x9e00
    mov cx, 32

    jmp search_file

search_file:
    cmp byte [bx], 0
    je search_next

    push bx
    push si
    
    mov dx, 15
    jmp search_loop

search_end:
    cmp ah, 0
    je search_match

not_search:
    pop si
    pop bx
    jmp search_next

search_next:
    add bx, 16
    dec cx
    jnz search_file
    jmp search_fail

search_match:
    pop si
    pop bx
    mov al, [bx + 15]
    mov ah, 1
    xchg al, ah
    mov cl, ah
    ret

search_fail:
    pop ax
    xor ax, ax
    mov si, not_found
    call print
    jmp return

search_loop:
    mov al, [si]
    mov ah, [bx]

    cmp al, 0
    je search_end
    cmp al, " "
    je search_match

    cmp al, ah
    jne not_search

    inc si
    inc bx
    dec dx
    jnz search_loop
    jmp search_match

return:
    mov ax, 0
    mov bx, 0
    mov cx, 0
    mov dx, 0
    mov [first], ax
    mov [second], ax

    mov si, console
    call print

    mov cx, 256
    mov di, command
    mov al, 0
    rep stosb  
    
    mov si, 0
    mov bx, 0
    mov dx, 0
    mov di, command
    mov dl, 0
    jmp input

%include "../src/compiler.asm"

welcome: db "Welcome to NenOS!", 13, "Type <help> to show available commands.", 13, "Press <TAB> to change language.", 13, 0
console: db "NenOS> ", 0
argcs: db "Arguments error.", 13, 0
full: db "Directory full.", 13, 0
exists: db "Already exists.", 13, 0
not_found: db "Not found.", 13, 0
dir_list: db "Directory:", 13, 0
dir_tab: db "   ", 0
available_commands: db "Available Commands:", 13, "   1. BUILD <from> <to> - compile the file.", 13, "   2. CALC <sample> - calculate.", 13, "   3. CLS - clear the screen.", 13, "   4. COPY <from> <to> - copy the document.", 13, "   5. CREATE <name> - create the document.", 13, "   6. DELETE <name> - delete the document.", 13, "   7. DIR - show directory.", 13, "   8. HELP - displaying available commands.", 13, "   9. READ <name> - read the document.", 13, "  10. REBOOT - reboot the computer.", 13, "  11. RUN <name> - run the script.", 13, "  12. TIME - launches the watch app.", 13, "  13. WRITE <name> - write the document.", 13, 0
readed: db "Document:", 13, 0
not_bin: db "Not binary file.", 13, 0
press_esc: db "Press <ESC> to save.", 13, 0
saved: db "The document was saved.", 13, 0
error: db "Unknown command.", 13, 0
enter: db 13, 0
lang: db 0
first: dw 0
second: dw 0
src: db 0
dst: db 0
del_sector: db 0

command_build: db "build", 0
command_calc: db "calc", 0
command_cls: db "cls", 0
command_copy: db "copy", 0
command_create: db "create", 0
command_delete: db "delete", 0
command_dir: db "dir", 0
command_help: db "help", 0
command_read: db "read", 0
command_reboot: db "reboot", 0
command_run: db "run", 0
command_time: db "time", 0
command_write: db "write", 0

cmd_table:
    dw command_build, build, 5
    dw command_calc, calc, 4
    dw command_cls, cls, 3
    dw command_copy, copy, 4
    dw command_create, create, 6
    dw command_delete, delete, 6
    dw command_dir, dir, 3
    dw command_help, help, 4
    dw command_read, read, 4
    dw command_reboot, reboot, 6
    dw command_run, run, 3
    dw command_time, time, 4
    dw command_write, write, 5

cmd_end:

lower:
    times 0x10 db 0
    db 0xa9, 0xe6, 0xe3, 0xaa, 0xa5, 0xad, 0xa3, 0xe8, 0xe9, 0xa7, 0xe5, 0xeA, 0, 0, 0xe4, 0xeb
    db 0xa2, 0xa0, 0xaf, 0xe0, 0xae, 0xab, 0xa4, 0xa6, 0xed, 0xf1, 0, 0, 0xef, 0xe7, 0xe1, 0xac
    db 0xa8, 0xe2, 0xec, 0xa1, 0xee, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    times 0xc0 db 0

upper:
    times 0x10 db 0
    db 0x89, 0x96, 0x93, 0x8a, 0x85, 0x8d, 0x83, 0x98, 0x99, 0x87, 0x95, 0x9a, 0, 0, 0x94, 0x9b
    db 0x82, 0x80, 0x8f, 0x90, 0x8e, 0x8b, 0x84, 0x86, 0x9d, 0xf0, 0, 0, 0x9f, 0x97, 0x91, 0x8c
    db 0x88, 0x92, 0x9c, 0x81, 0x9e, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    times 0xc0 db 0
    
command: times 256 db 0
document: times 512 db 0

times 16384-($-$$) db 0

font: incbin "../src/cp866-8x16.fnt"