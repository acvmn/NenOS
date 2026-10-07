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

    call normal

    mov di, ins_table
    mov dx, 0
    jmp ins_compare

normal:
    push si

normal_loop:
    mov al, [si]
    cmp al, "A"
    jb normal_next
    cmp al, "Z"
    ja normal_next
    add byte [si], 0x20

normal_next:
    inc si
    cmp byte [si], 0
    jne normal_loop
    pop si
    ret

skip_space:
    cmp byte [si], " "
    jne done
    inc si
    jmp skip_space

skip_comment:
    cmp byte [si], 0
    je skip_done
    cmp byte [si], 13
    je skip_done
    inc si
    jmp skip_comment

skip_done:
    inc si
    jmp ins_compare

ins_compare:
    call skip_space

    cmp byte [si], ";"
    je skip_comment

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

    call skip_space

    call reg_compare
    mov bx, dx
    add byte [bytes + bx], cl
    inc dx
    add si, 2
    call skip_space
    sub si, 2
    cmp byte [si + 2], ","
    jne calc_error

    add si, 4
    call skip_space
    sub si, 4

    call com_arg
    mov bx, dx
    mov byte [bytes + bx], cl
    inc dx
    mov di, ins_table
    call skip_space
    cmp byte [si - 1], ";"
    je skip_comment
    jmp ins_compare

com_int:
    mov bx, dx
    mov byte [bytes + bx], 0xcd

    inc dx
    cmp byte [si + 3], " "
    jne calc_error

    add si, 4
    call skip_space
    sub si, 4

    call com_arg
    mov bx, dx
    mov byte [bytes + bx], cl
    inc dx
    mov di, ins_table
    call skip_space
    cmp byte [si - 1], ";"
    je skip_comment
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

    mov ax, 0
    mov bx, 0
    mov cx, 0
    mov dx, 0
    mov [first], ax
    mov [second], ax

    jmp calc_error

com_arg:
    mov al, 0
    mov cl, 0
    add si, 3
    call skip_space
    cmp byte [si], 13
    je calc_error
    cmp byte [si], 0
    je calc_error
    cmp byte [si], "'"
    je com_one
    cmp byte [si], '"'
    je com_two
    cmp byte [si], "0"
    jne com_dec
    cmp byte [si + 1], 13
    je com_dec
    cmp byte [si + 1], 0
    je com_dec
    cmp byte [si + 1], "x"
    jne calc_error
    add si, 2
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
    cmp al, " "
    je done
    cmp al, ";"
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
    cmp bl, " "
    je done
    cmp bl, ";"
    je done
    call check_hex
    cmp bl, "9"
    jbe is_dec
    sub bl, "a" - 10
    mov ah, 16
    mul ah
    cmp ah, 0
    jne calc_error
    add al, bl
    jc calc_error
    mov ah, 0
    jmp com_hex

com_one:
    inc si
    mov cl, [si]
    inc si
    cmp byte [si], "'"
    jne calc_error
    inc si
    ret
    
com_two:
    inc si
    mov cl, [si]
    inc si
    cmp byte [si], '"'
    jne calc_error
    inc si
    ret

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

ins_mov: db "mov"
ins_int: db "int"

ins_table:
    dw ins_mov, com_mov, 3
    dw ins_int, com_int, 3

ins_end:

bytes: times 512 db 0