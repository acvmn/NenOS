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
    mov ax, 0
    mov bx, 0
    mov cx, 0
    mov dx, 0
    mov [first], ax
    mov [second], ax
    jmp calc_error

bin:
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

com_line:
    inc si
    jmp ins_compare

com_mov:
    mov bx, dx
    mov byte [bytes + bx], 0xb0
    mov di, reg_table
    cmp byte [si + 3], " "
    jne calc_error
    add si, 4

    call reg_compare
    mov bx, dx
    add byte [bytes + bx], cl
    inc dx
    cmp byte [si + 2], ","
    jne calc_error
    cmp byte [si + 3], " "
    jne calc_error

    call com_arg
    mov bx, dx
    mov byte [bytes + bx], cl
    inc dx
    mov di, ins_table
    jmp ins_compare

com_int:
    mov bx, dx
    mov byte [bytes + bx], 0xcd

    inc dx
    cmp byte [si + 3], " "
    jne calc_error

    call com_arg
    mov bx, dx
    mov byte [bytes + bx], cl
    inc dx
    mov di, ins_table
    jmp ins_compare

com_rst:
    mov ax, dx
    neg ax
    sub ax, 3

    mov bx, dx
    mov byte [bytes + bx], 0xe9
    inc dx

    mov bx, dx
    mov byte [bytes + bx], al
    inc dx

    mov bx, dx
    mov byte [bytes + bx], ah
    inc dx

    add si, 3
    mov di, ins_table
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
    mov cx, [di + 2]
    ret

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
    cmp byte [si], 13
    je calc_error
    cmp byte [si], 0
    je calc_error
    cmp byte [si], "0"
    jne com_dec
    cmp byte [si + 1], 13
    je com_dec
    cmp byte [si + 1], 0
    je com_dec
    cmp byte [si + 1], "x"
    jne calc_error
    mov cl, 0
    add si, 2
    jmp com_hex

null_arg:
    mov al, [si + 3]
    cmp al, 0
    je com_rst
    cmp al, 13
    je com_rst
    jmp calc_error

check_hex:
    cmp bl, "0"
    jb calc_error
    cmp bl, "9"
    jbe done
    cmp bl, "a"
    jb calc_error
    cmp bl, "f"
    ja calc_error
    ret

com_hex:
    push ax
    lodsb
    mov bl, al
    pop ax
    mov cl, al
    cmp bl, 0
    je done
    cmp bl, 13
    je done
    call check_hex
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
    je done
    cmp al, 13
    je done

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

ins_mov: db "mov "
ins_int: db "int "
ins_rst: db "rst"

ins_table:
    dw ins_mov, com_mov, 4
    dw ins_int, com_int, 4
    dw ins_rst, null_arg, 3

ins_end:

reg_al: db "al"
reg_cl: db "cl"
reg_dl: db "dl"
reg_bl: db "bl"
reg_ah: db "ah"
reg_ch: db "ch"
reg_dh: db "dh"
reg_bh: db "bh"

reg_table:
    dw reg_al, 0, 2
    dw reg_cl, 1, 2
    dw reg_dl, 2, 2
    dw reg_bl, 3, 2
    dw reg_ah, 4, 2
    dw reg_ch, 5, 2
    dw reg_dh, 6, 2
    dw reg_bh, 7, 2

reg_end:

bytes: times 512 db 0