build:
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

    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, [src]
    mov dl, 0x80
    mov dh, 0
    mov bx, 0x9e00
    int 0x13
    mov si, 0x9e00

    call normal
    mov di, labels
    call clear_buff
    mov di, jmps
    call clear_buff

    mov word [l_count], 0
    mov word [j_count], 0
    mov di, ins_table
    mov byte [bytes], 0x90
    mov dx, 1
    jmp ins_compare

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

skip_line:
    inc si
    jmp ins_compare

skip_done:
    inc si
    jmp ins_compare

normal:
    push si
    jmp normal_loop

normal_check:
    cmp ah, 0x00
    je normal_start
    jmp normal_end

normal_start:
    mov ah, 0xff
    jmp normal_next

normal_end:
    mov ah, 0x00
    jmp normal_next

normal_loop:
    mov al, [si]

    cmp al, "'"
    je normal_check
    cmp al, '"'
    je normal_check
    cmp al, "A"
    jb normal_next
    cmp al, "Z"
    ja normal_next
    cmp ah, 0xff
    je normal_next

    add byte [si], 0x20
    jmp normal_next

normal_next:
    inc si
    cmp byte [si], 0
    jne normal_loop
    pop si
    ret

clear_buff:
    cmp word [di], 0
    je done
    mov word [di], 0
    inc di
    jmp clear_buff

is_comment:
    cmp ah, 0xff
    je skip_label
    cmp al, ";"
    jne build_error
    mov ah, 0xff
    jmp skip_label

skip_label:
    lodsb
    cmp al, 13
    je done
    cmp al, 0
    je done
    cmp al, " "
    jne is_comment
    jmp skip_label

ready_label:
    push si
    jmp is_label

is_label:
    lodsb

    cmp al, 13
    je label_done
    cmp al, 0
    je label_done
    cmp al, ":"
    je a_label
    cmp al, " "
    je not_label

    inc cx
    jmp is_label

check_label:
    cmp byte [si], "0"
    jb a_label
    cmp byte [si], "9"
    ja a_label
    jmp build_error

a_label:
    mov di, labels
    add di, [l_count]

    call check_dup

    sub si, cx
    dec si
    mov ax, si
    stosw
    mov ax, dx
    stosw
    mov ax, cx
    stosw

    add word [l_count], 6
    pop si
    add si, cx
    inc si
    jmp skip_label

not_label:
    pop si
    pop ax
    jmp ins_loop

label_done:
    pop si
    ret

is_next:
    cmp byte [si + bx], ":"
    je ins_compare
    cmp byte [si + bx], 13
    je ins_loop
    cmp byte [si + bx], 0
    je ins_loop

    inc bx
    jmp is_next

ins_compare:
    mov cx, 0
    push di
    call ready_label
    pop di
    mov bx, 0
    jmp is_next

ins_loop:
    call skip_space

    cmp byte [si], 0
    je bin

    cmp byte [si], 13
    je skip_line

    cmp byte [si], ";"
    je skip_comment

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
    jmp ins_loop

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
    jmp build_error

resolve_jmps:
    xor bp, bp
    jmp next_jmp

next_jmp:
    cmp bp, [j_count]
    jae done

    mov di, jmps
    add di, bp
    mov si, [di]
    mov dx, [di + 2]
    mov cx, [di + 4]

    mov di, labels
    xor bx, bx
    jmp next_label

next_label:
    cmp bx, [l_count]
    jae build_error

    mov ax, [di + 4]
    cmp ax, cx
    jne skip

    push si
    push di
    push cx
    mov di, [di]
    jmp label_cmp

skip:
    add di, 6
    add bx, 6
    jmp next_label

label_cmp:
    test cx, cx
    jz match
    mov al, [si]
    cmp al, [di]
    jne diff
    inc si
    inc di
    dec cx
    jmp label_cmp

diff:
    pop cx
    pop di
    pop si
    add di, 6
    add bx, 6
    jmp next_label

match:
    pop cx
    pop di
    pop si
    mov ax, [di + 2]
    sub ax, dx
    mov bx, dx
    dec bx
    mov bl, [bytes + bx]
    cmp bl, 0xe9
    je jmp_long
    sub ax, 1
    mov bx, dx
    mov [bytes + bx], al
    jmp match_next

match_next:
    add bp, 6
    jmp next_jmp

jmp_long:
    sub ax, 2
    mov bx, dx
    mov [bytes + bx], al
    mov [bytes + bx + 1], ah
    jmp match_next

check_dup:
    mov di, labels
    xor bx, bx
    jmp dup_loop

dup_loop:
    cmp bx, [l_count]
    jae done

    mov ax, [di + 4]
    cmp ax, cx
    jne dup_skip

    push si
    push di
    push cx
    mov di, [di]
    jmp dup_cmp

dup_cmp:
    test cx, cx
    jz dup_found
    mov al, [si]
    cmp al, [di]
    jne dup_diff
    inc si
    inc di
    dec cx
    jmp dup_cmp

dup_found:
    pop cx
    pop di
    pop si
    jmp build_error

dup_diff:
    pop cx
    pop di
    pop si
    jmp dup_skip

dup_skip:
    add di, 6
    add bx, 6
    jmp dup_loop

bin:
    mov bx, dx
    mov byte [bytes + bx], 0xc3
    inc dx

    xor bp, bp
    call resolve_jmps

    mov si, bytes
    mov cx, 512
    mov bx, bytes
    mov ah, 0x03
    mov al, 1
    mov ch, 0
    mov cl, [dst]
    mov dl, 0x80
    mov dh, 0
    int 0x13

    jmp return

build_error:
    mov bx, 0x9e00
    xor cx, cx
    jmp error_count

error_count:
    cmp bx, si
    jae error_done
    cmp byte [bx], 13
    jne error_next
    inc cx
    jmp error_next

error_next:
    inc bx
    jmp error_count

error_done:
    inc cx
    push cx
    mov si, syntax
    call print
    pop ax
    mov dx, 0
    call number
    mov si, enter
    call print
    jmp return

sec_reg:
    push cx
    add si, 4
    mov di, reg_table
    jmp sec_compare

sec_compare:
    cmp di, reg_end
    jae sec_false

    mov bx, [di]
    mov cx, [di + 4]

    push si
    push di

    mov di, bx
    repe cmpsb

    pop di
    pop si

    je sec_true

    add di, 8
    jmp sec_compare

sec_true:
    pop cx
    mov ax, [di + 6]
    cmp al, ch
    jne build_error

    add si, 2
    mov bx, [di + 2]
    mov ax, [di + 6]
    mov bh, al
    mov al, 1
    mov ah, 0
    ret

sec_false:
    sub si, 4
    pop cx
    mov al, 0
    ret

reg_16:
    cmp ch, 2
    je true_16
    ret

true_16:
    mov bx, dx
    mov byte [bytes + bx], 0x89
    ret

mov_reg:
    push bx
    dec dx
    mov bx, dx
    mov byte [bytes + bx], 0x88
    call reg_16
    inc dx
    pop bx

    mov al, 0xc0
    shl bl, 3
    or al, bl
    or al, cl
    mov bx, dx
    mov byte [bytes + bx], al
    inc dx

    mov di, ins_table
    call skip_space
    inc si
    cmp byte [si - 1], ";"
    je skip_comment
    jmp ins_compare

com_mov:
    mov bx, dx
    mov byte [bytes + bx], 0xb0
    mov di, reg_table
    cmp byte [si + 3], " "
    jne build_error
    add si, 4

    call skip_space

    call reg_compare
    mov [com_bit], ch
    call fst_bit
    mov bx, dx
    add byte [bytes + bx], cl
    inc dx
    add si, 2
    call skip_space
    sub si, 2
    cmp byte [si + 2], ","
    jne build_error

    add si, 4
    call skip_space
    sub si, 4

    call sec_reg
    cmp al, 1
    je mov_reg

    push dx
    call com_arg
    pop dx
    cmp bh, "x"
    je build_error
    mov bx, dx
    mov byte [bytes + bx], cl
    inc dx
    mov al, ch
    call num_bit

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
    jne build_error

    add si, 4
    call skip_space
    sub si, 4

    push dx
    call com_arg
    pop dx
    cmp bh, "x"
    je build_error
    cmp ch, 0
    jne build_error
    mov bx, dx
    mov byte [bytes + bx], cl
    inc dx

    mov di, ins_table
    call skip_space
    cmp byte [si - 1], ";"
    je skip_comment
    jmp ins_compare

a_jmp:
    mov di, jmps
    add di, [j_count]

    sub si, cx
    dec si
    mov ax, si
    stosw
    mov ax, dx
    stosw
    mov ax, cx
    stosw

    add word [j_count], 6
    pop si
    jmp skip_jmp

skip_jmp:
    lodsb
    cmp al, 13
    je jmp_skipped
    cmp al, 0
    je jmp_skipped
    jmp skip_jmp

jmp_skipped:
    mov cx, 0
    sub cx, 3
    mov bx, dx
    mov byte [bytes + bx], cl
    inc dx
    mov bx, dx
    mov byte [bytes + bx], ch
    inc dx

    mov di, ins_table
    call skip_space
    cmp byte [si - 1], ";"
    je skip_comment
    jmp ins_compare

jmp_ready:
    add si, 3
    call skip_space
    push si
    jmp jmp_label

jmp_label:
    lodsb
    cmp al, ";"
    je a_jmp
    cmp al, " "
    je a_jmp
    cmp al, 13
    je a_jmp
    cmp al, 0
    je a_jmp
    inc cx
    jmp jmp_label

com_jmp:
    mov bx, dx
    mov byte [bytes + bx], 0xe9
    inc dx
    cmp byte [si + 3], " "
    jne build_error

    add si, 4
    call skip_space
    sub si, 4

    mov cx, 0
    cmp byte [si + 4], "0"
    jl jmp_ready
    cmp byte [si + 4], "9"
    jg jmp_ready

    push dx
    call com_arg
    pop dx
    cmp bh, "x"
    je build_error
    sub cx, 0x9e00
    sub cx, dx
    sub cx, 2
    mov bx, dx
    mov byte [bytes + bx], cl
    inc dx
    mov bx, dx
    mov byte [bytes + bx], ch
    inc dx

    mov di, ins_table
    call skip_space
    cmp byte [si - 1], ";"
    je skip_comment
    jmp ins_compare

cmp_reg:
    mov al, 0x38
    cmp ch, 2
    jne op
    mov al, 0x39
    jmp op

op:
    push bx
    mov bx, dx
    mov byte [bytes + bx], al
    call reg_16
    inc dx
    pop bx

    mov al, 0xc0
    shl bl, 3
    or al, bl
    or al, cl
    mov bx, dx
    mov byte [bytes + bx], al
    inc dx

    mov di, ins_table
    call skip_space
    inc si
    cmp byte [si - 1], ";"
    je skip_comment
    jmp ins_compare

com_cmp:
    mov di, reg_table
    cmp byte [si + 3], " "
    jne build_error
    add si, 4

    call skip_space

    call reg_compare
    mov [com_bit], ch
    call fst_bit

    add si, 2
    call skip_space
    sub si, 2
    cmp byte [si + 2], ","
    jne build_error

    add si, 4
    call skip_space
    sub si, 4

    call sec_reg
    cmp al, 1
    je cmp_reg

    push cx
    push dx
    call com_arg
    pop dx
    pop bx
    cmp bl, 0
    jne not_al
    cmp bh, 2
    je op_ax
    
    mov bx, dx
    mov byte [bytes + bx], 0x3c
    inc dx
    jmp write_imm

a_je:
    mov di, jmps
    add di, [j_count]

    sub si, cx
    dec si
    mov ax, si
    stosw
    mov ax, dx
    stosw
    mov ax, cx
    stosw

    add word [j_count], 6
    pop si
    jmp skip_je

skip_je:
    lodsb
    cmp al, 13
    je je_skipped
    cmp al, 0
    je je_skipped
    jmp skip_je

je_skipped:
    mov cx, 0
    sub cx, 2
    mov bx, dx
    mov byte [bytes + bx], 0
    inc dx
    mov di, ins_table
    call skip_space
    cmp byte [si - 1], ";"
    je skip_comment
    jmp ins_compare

je_ready:
    add si, 2
    call skip_space
    push si
    jmp je_label

je_label:
    lodsb
    cmp al, ";"
    je a_je
    cmp al, " "
    je a_je
    cmp al, 13
    je a_je
    cmp al, 0
    je a_je
    inc cx
    jmp je_label

com_je:
    mov bx, dx
    mov byte [bytes + bx], 0x74
    inc dx
    cmp byte [si + 2], " "
    jne build_error

    add si, 4
    call skip_space
    sub si, 4

    mov cx, 0
    cmp byte [si + 4], "0"
    jl je_ready
    cmp byte [si + 4], "9"
    jg je_ready

    push dx
    call com_arg
    pop dx
    cmp bh, "x"
    je build_error
    sub cx, 0x9e00
    sub cx, dx
    sub cx, 2
    mov bx, dx
    mov byte [bytes + bx], cl
    inc dx
    mov bx, dx
    mov byte [bytes + bx], ch
    inc dx

    mov di, ins_table
    call skip_space
    cmp byte [si - 1], ";"
    je skip_comment
    jmp ins_compare

op_ax:
    mov bx, dx
    mov byte [bytes + bx], 0x3d
    inc cx
    jmp write_imm

not_al:
    cmp bh, 2
    je op_other
    mov bx, dx
    mov byte [bytes + bx], 0x80
    inc dx
    mov al, 0xf8
    or al, bl
    mov bx, dx
    mov [bytes + bx], al
    inc dx
    jmp write_imm

op_other:
    mov bx, dx
    mov byte [bytes + bx], 0x81
    inc dx
    mov al, 0xf8
    or al, bl
    mov [bytes + bx], al
    inc dx
    jmp write_imm

write_imm:
    mov bx, dx
    mov [bytes + bx], cl
    inc dx
    cmp byte [com_bit], 1
    je cmp_done
    mov bx, dx
    mov [bytes + bx], ch
    inc dx
    jmp cmp_done

cmp_done:
    mov di, ins_table
    call skip_space
    cmp byte [si - 1], ";"
    je skip_comment
    jmp ins_compare

fst_bit:
    cmp ch, 2
    je fst_16
    ret

fst_16:
    mov bx, dx
    mov byte [bytes + bx], 0xb8
    ret

scd_bit:
    cmp ch, 2
    je scd_16
    ret

scd_16:
    dec dx
    mov bx, dx
    mov byte [bytes + bx], 0x89
    inc dx
    ret

num_bit:
    cmp byte [com_bit], 2
    je num_16
    cmp ch, 0
    jne build_error
    ret

num_16:
    mov bx, dx
    mov byte [bytes + bx], al
    inc dx
    ret

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

    add di, 8
    jmp reg_compare

reg_true:
    mov cx, [di + 2]
    mov ax, [di + 6]
    mov ch, al
    ret

reg_false:
    cmp dl, 0
    je build_error

    mov ax, 0
    mov bx, 0
    mov cx, 0
    mov dx, 0
    mov [first], ax
    mov [second], ax

    jmp build_error

com_arg:
    mov ax, 0
    mov cx, 0
    add si, 3
    call skip_space

    cmp byte [si], 13
    je build_error
    cmp byte [si], 0
    je build_error
    cmp byte [si], "'"
    je com_one
    cmp byte [si], '"'
    je com_two
    cmp byte [si + 1], "x"
    jne com_dec
    cmp byte [si + 1], 13
    je com_dec
    cmp byte [si + 1], 0
    je com_dec
    cmp byte [si + 1], "x"
    jne build_error

    add si, 2
    jmp com_hex

check_hex:
    cmp bl, "0"
    jb build_error
    cmp bl, "9"
    jbe done
    cmp bl, "a"
    jb build_error
    cmp bl, "f"
    ja build_error
    ret

com_hex:
    push ax
    dec si
    lodsb
    mov bh, al
    lodsb
    mov bl, al
    pop ax
    mov cx, ax

    cmp bl, 0
    je done
    cmp bl, 13
    je done
    cmp bl, " "
    je done
    cmp bl, ";"
    je done

    mov bh, 0
    call check_hex
    cmp bl, "9"
    jbe is_dec
    sub bl, "a" - 10
    mov dx, 0
    mov cx, 16
    mul cx
    cmp dx, 0
    jne build_error
    add ax, bx
    jc build_error
    jmp com_hex

is_dec:
    mov dx, 0
    sub bl, "0"
    mov cx, 16
    mul cx
    cmp dx, 0
    jne build_error
    add ax, bx
    jc build_error
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

    mov dx, 0
    mov ax, cx
    mov bx, 10
    mul bx
    cmp dx, 0
    jne build_error
    mov cx, ax

    lodsb

    cmp al, "0"
    jl build_error
    cmp al, "9"
    jg build_error
    sub al, "0"
    mov ah, 0
    add cx, ax
    jc build_error

    jmp com_dec

com_one:
    inc si
    mov cl, [si]
    inc si
    cmp byte [si], "'"
    jne build_error
    add si, 2
    ret
    
com_two:
    inc si
    mov cl, [si]
    inc si
    cmp byte [si], '"'
    jne build_error
    add si, 2
    ret

reg_al: db "al"
reg_cl: db "cl"
reg_dl: db "dl"
reg_bl: db "bl"
reg_ah: db "ah"
reg_ch: db "ch"
reg_dh: db "dh"
reg_bh: db "bh"
reg_ax: db "ax"
reg_cx: db "cx"
reg_dx: db "dx"
reg_bx: db "bx"
reg_sp: db "sp"
reg_bp: db "bp"
reg_si: db "si"
reg_di: db "di"

reg_table:
    dw reg_al, 0, 2, 1
    dw reg_cl, 1, 2, 1
    dw reg_dl, 2, 2, 1
    dw reg_bl, 3, 2, 1
    dw reg_ah, 4, 2, 1
    dw reg_ch, 5, 2, 1
    dw reg_dh, 6, 2, 1
    dw reg_bh, 7, 2, 1
    dw reg_ax, 0, 2, 2
    dw reg_cx, 1, 2, 2
    dw reg_dx, 2, 2, 2
    dw reg_bx, 3, 2, 2
    dw reg_sp, 4, 2, 2
    dw reg_bp, 5, 2, 2
    dw reg_si, 6, 2, 2
    dw reg_di, 7, 2, 2

reg_end:

ins_mov: db "mov"
ins_int: db "int"
ins_jmp: db "jmp"
ins_cmp: db "cmp"
ins_je: db "je"

ins_table:
    dw ins_mov, com_mov, 3
    dw ins_int, com_int, 3
    dw ins_jmp, com_jmp, 3
    dw ins_cmp, com_cmp, 3
    dw ins_je, com_je, 2

ins_end:

syntax: db "Syntax error: ", 0

com_bit: db 0
labels: times 3 * 512 dw 0
l_count: dw 0
jmps: times 3 * 512 dw 0
j_count: dw 0
bytes: times 512 db 0