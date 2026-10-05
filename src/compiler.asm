build:
	mov al, 0
    mov [file], al

    mov di, command
    mov al, " "
    mov ch, 0
    mov cl, dl
    repne scasb
    jne calc_error

    mov si, di
    mov cl, 0
    call two_argc_file

    cmp al, 0
    je calc_error

    cmp cl, 0
    je calc_error

    mov al, 0
    cmp [file], al
    je calc_error

    mov bh, [file]

    mov al, 0
    mov [file], al

    mov cl, 0
    call argc_file

    cmp al, 0
    jne calc_error

    cmp cl, 0
    je calc_error

    mov al, 0
    cmp [file], al
    je calc_error

    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, bh
    add cl, 25
    mov dl, 0x80
    mov dh, 0
    mov bx, 0x9e00
    int 0x13
    mov si, 0x9e00

    mov di, ins_table
    mov dx, 0
    jmp ins_compare

bin:
    mov bx, dx
    mov byte [bytes + bx], 0

    mov si, bytes
    mov cx, 512
    mov bx, bytes
    mov ah, 0x03
    mov al, 1
    mov ch, 0
    mov cl, [file]
    add cl, 25
    mov dl, 0x80
    mov dh, 0
    int 0x13

    jmp return

ins_compare:
    cmp byte [si], 0
    je bin

    cmp byte [si], 13
    je com_line

    cmp di, ins_end
    jae ins_false

    mov bx, [di]
    mov cx, [di + 4]

    push si
    push di

    mov di, bx
    repe cmpsb

    pop di
    pop si

    je ins_true

    add di, 6
    jmp ins_compare

ins_true:
    mov ax, [di + 2]
    jmp ax

ins_false:
    cmp dl, 0
    je calc_error

    mov si, error
    call print

    mov ax, 0
    mov bx, 0
    mov cx, 0
    mov dx, 0
    mov [first], ax
    mov [second], ax

    jmp calc_error

com_line:
    inc si
    jmp ins_compare

reg_compare:
    cmp di, reg_end
    jae reg_false

    mov bx, [di]
    mov cx, [di + 4]

    push si
    push di

    mov di, bx
    repe cmpsb

    pop di
    pop si

    je reg_true

    add di, 6
    jmp reg_compare

reg_true:
    mov ax, [di + 2]
    jmp add_two

reg_false:
    cmp dl, 0
    je calc_error

    mov si, error
    call print

    mov ax, 0
    mov bx, 0
    mov cx, 0
    mov dx, 0
    mov [first], ax
    mov [second], ax

    jmp calc_error

com_arg:
    mov al, 0
    add si, 4
    cmp byte [si], "0"
    jne com_dec
    mov cl, 0
    add si, 2
    jmp com_hex

com_hex:
    push ax
    lodsb
    mov bl, al
    pop ax
    cmp bl, 0
    je add_hex
    cmp bl, 13
    je add_hex
    cmp bl, "9"
    jbe is_dec
    sub bl, "a" - 10
    mov ah, 16
    mul ah
    add al, bl
    mov ah, 0
    jmp com_hex

is_dec:
    sub bl, "0"
    mov ah, 16
    mul ah
    add al, bl
    mov ah, 0
    jmp com_hex

com_dec:
    lodsb

    cmp al, 0
    je add_dec
    cmp al, 13
    je add_dec

    dec si

    mov al, cl
    mov ah, 0
    mov bl, 10
    mul bl
    cmp ah, 0
    jne calc_error
    mov cl, al

    lodsb

    cmp al, "0"
    jl calc_error
    cmp al, "9"
    jg calc_error
    sub al, "0"
    add cl, al
    jc calc_error

    jmp com_dec

add_hex:
    mov bx, dx
    mov byte [bytes + bx], al
    inc dx
    mov di, ins_table
    jmp ins_compare

add_dec:
    mov bx, dx
    mov byte [bytes + bx], cl
    inc dx
    mov di, ins_table
    jmp ins_compare

add_two:
    mov bx, dx
    add byte [bytes + bx], al
    inc dx
    cmp byte [si + 2], ","
    jne calc_error
    cmp byte [si + 3], " "
    jne calc_error
    jmp com_arg

com_mov:
    mov bx, dx
    mov byte [bytes + bx], 0xb0
    mov di, reg_table
    cmp byte [si + 3], " "
    jne calc_error
    add si, 4
    jmp reg_compare

com_int:
    mov bx, dx
    mov byte [bytes + bx], 0xcd
    inc dx
    cmp byte [si + 3], " "
    jne calc_error
    jmp com_arg

ins_mov: db "mov "
ins_int: db "int "

ins_table:
    dw ins_mov, com_mov, 4
    dw ins_int, com_int, 4

ins_end:

reg_al: db "al"
reg_ah: db "ah"

reg_table:
    dw reg_al, 0, 2
    dw reg_ah, 4, 2

reg_end:

bytes: db ""