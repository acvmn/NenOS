build:
    call skip_space
    mov cl, 0
    call argc_file
    test cl, cl
    je return
    mov [src], cl

    call to_space

    call skip_space
    cmp byte [si], 0
    je calc_error
    mov cl, 0
    call argc_file
    test cl, cl
    je return
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

    mov word [l_count], 0
    mov word [j_count], 0
    mov di, ins_table
    mov byte [bytes], 0x90
    mov dx, 1
    jmp ins_compare

build_error:
    mov bx, 0x9e00
    xor cx, cx
    jmp error_count

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

is_comment:
    cmp ah, 0xff
    je skip_label
    cmp al, ";"
    jne call_done
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
    jmp check_label

valid:
    inc cx
    jmp is_label

is_label:
    lodsb
    cmp al, 0
    je not_label
    cmp al, 13
    je not_label
    cmp al, " "
    je not_label

    cmp al, ":"
    je a_label

    cmp al, "_"
    je valid
    cmp al, "0"
    jb a_error
    cmp al, "9"
    jbe valid
    cmp al, "a"
    jb a_error
    cmp al, "z"
    jbe valid
    jmp a_error

check_label:
    cmp byte [si], "0"
    jb is_label
    cmp byte [si], "9"
    ja is_label
    pop si
    stc
    ret

call_done:
    stc
    ret

a_label:
    mov di, labels
    add di, [l_count]

    call check_dup
    jc a_error

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
    jmp done

a_error:
    pop si
    stc
    ret

not_label:
    pop si
    clc
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

have_arg:
    cmp cx, ins_compare
    jne have
    ret

have:
    cmp byte [si], " "
    jne call_done
    ret

ins_compare:
    mov di, ins_table
    call skip_space
    cmp byte [si], ";"
    je skip_comment

    mov cx, 0
    push di
    call ready_label
    pop di
    jc build_error
    mov bx, 0
    jmp is_next

ins_loop:
    call skip_space

    cmp byte [si], "j"
    je com_flag

    cmp byte [si], 0
    je bin

    cmp byte [si], 13
    je skip_line

    cmp byte [si], ";"
    je skip_comment

    cmp di, ins_end
    jae build_error

    mov bx, [di]
    mov cx, [di + 4]

    push si
    push di

    mov di, bx
    repe cmpsb

    pop di
    pop si

    je ins_true

    add di, 8
    jmp ins_loop

ins_true:
    mov cx, [di + 6]

    mov bx, dx
    mov byte [bytes + bx], cl
    inc dx

    mov cx, [di + 4]
    add si, cx

    mov cx, [di + 2]
    call have_arg
    jc build_error

    call skip_space
    mov di, reg_table
    jmp cx

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
    jae call_done

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

is_jmp:
    sub ax, dx
    cmp bx, 0xe9
    je jmp_long
    cmp bx, 0xe8
    je jmp_long
    sub ax, 1
    mov bx, dx
    mov [bytes + bx], al
    jmp match_next

match:
    pop cx
    pop di
    pop si
    mov ax, [di + 2]
    mov bx, dx
    dec bx
    mov bl, [bytes + bx]
    cmp bl, 0xb8
    jb is_jmp
    cmp bl, 0xbf
    ja is_jmp
    add ax, 0x9e00
    mov bx, dx
    mov [bytes + bx], al
    mov [bytes + bx + 1], ah
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
    stc
    jmp done

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

    mov bx, dx
    mov byte [bytes + bx], 0x00
    inc dx

    xor bp, bp
    call resolve_jmps
    jc build_error

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
    mov si, error_line
    call print
    pop ax
    mov dx, 0
    call number
    mov si, enter
    call print
    jmp return

sec_reg:
    push cx
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
    add si, 2
    mov bx, [di + 2]
    mov ax, [di + 6]
    mov bh, al
    mov al, 1
    mov ah, 0
    cmp ch, bh
    jne call_done
    ret

sec_false:
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

    jmp ins_compare

to_16:
    cmp byte [si + 1], "x"
    je is_to
    ret

is_to:
    mov bx, dx
    mov byte [bytes + bx], 0x89
    ret

to_mem:
    inc si
    call skip_space
    mov di, mem_table
    jmp to_loop

to_loop:
    cmp di, mem_end
    jae build_error

    mov bx, [di]
    mov cx, [di + 4]

    push si
    push di

    mov di, bx
    repe cmpsb

    pop di
    pop si

    je to_true

    add di, 6
    jmp to_loop

to_true:
    mov cx, [di + 2]
    jmp write_to

write_to:
    add si, 2
    call skip_space
    cmp byte [si], "]"
    jne build_error
    inc si

    call skip_space
    cmp byte [si], ","
    jne build_error
    inc si
    call skip_space

    mov bx, dx
    mov byte [bytes + bx], 0x88
    call to_16
    inc dx

    call sec_reg

    mov al, 0x00
    shl bl, 3
    or al, bl
    or al, cl
    mov bx, dx
    mov byte [bytes + bx], al
    inc dx

    jmp ins_compare

from_16:
    cmp ch, 2
    je is_from
    ret

is_from:
    mov bx, dx
    mov byte [bytes + bx], 0x8b
    ret

from_mem:
    inc si
    call skip_space
    mov di, mem_table
    push cx
    jmp from_loop

from_loop:
    cmp di, mem_end
    jae build_error

    mov bx, [di]
    mov cx, [di + 4]

    push si
    push di

    mov di, bx
    repe cmpsb

    pop di
    pop si

    je from_true

    add di, 6
    jmp from_loop

from_true:
    mov bx, [di + 2]
    pop cx
    jmp write_from

write_from:
    add si, 2
    call skip_space
    cmp byte [si], "]"
    jne build_error
    inc si

    push bx
    dec dx
    mov bx, dx
    mov byte [bytes + bx], 0x8a
    call from_16
    inc dx
    pop bx

    mov al, 0x00
    shl cl, 3
    or al, cl
    or al, bl
    mov bx, dx
    mov byte [bytes + bx], al
    inc dx

    jmp ins_compare

com_mov:
    dec dx
    cmp byte [si], "["
    je to_mem

    call reg_compare
    jc build_error
    mov [com_bit], ch
    call fst_bit
    mov bx, dx
    add byte [bytes + bx], cl
    inc dx
    add si, 2
    call skip_space
    cmp byte [si], ","
    jne build_error
    inc si

    call skip_space
    cmp byte [si], "["
    je from_mem

    call sec_reg
    jc build_error
    cmp al, 1
    je mov_reg

    push dx
    call com_arg
    dec si
    pop dx
    jc build_error
    mov bx, dx
    mov byte [bytes + bx], cl
    inc dx
    mov al, ch
    call num_bit
    jc build_error

    jmp ins_compare

com_int:
    push dx
    call com_arg
    dec si
    pop dx
    cmp ch, 0
    jne build_error
    jc build_error
    cmp ch, 0
    jne build_error
    mov bx, dx
    mov byte [bytes + bx], cl
    inc dx

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

    jmp ins_compare

jmp_ready:
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

    add si, 3
    call skip_space

    mov cx, 0
    cmp byte [si + 4], "0"
    jl jmp_ready
    cmp byte [si + 4], "9"
    jg jmp_ready

    push dx
    call com_arg
    dec si
    pop dx
    jc build_error
    sub cx, 0x9e00
    sub cx, dx
    sub cx, 2
    mov bx, dx
    mov byte [bytes + bx], cl
    inc dx
    mov bx, dx
    mov byte [bytes + bx], ch
    inc dx

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
    jc build_error
    inc dx
    pop bx

    mov al, 0xc0
    shl bl, 3
    or al, bl
    or al, cl
    mov bx, dx
    mov byte [bytes + bx], al
    inc dx

    jmp ins_compare

op_ax:
    mov bx, dx
    mov byte [bytes + bx], 0x3d
    inc dx
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
    push bx
    mov bx, dx
    mov byte [bytes + bx], 0x81
    inc dx
    mov al, 0xf8
    pop bx
    or al, bl
    mov bx, dx
    mov [bytes + bx], al
    inc dx
    jmp write_imm

write_imm:
    cmp byte [com_bit], 1
    jne is_16
    mov bx, dx
    mov [bytes + bx], cl
    inc dx
    cmp ch, 0
    jne build_error
    jmp ins_compare

is_16:
    mov bx, dx
    mov [bytes + bx], cl
    inc dx
    mov bx, dx
    mov [bytes + bx], ch
    inc dx
    jmp ins_compare

com_cmp:
    call reg_compare
    jc build_error
    mov [com_bit], ch
    call fst_bit

    add si, 2
    call skip_space
    cmp byte [si], ","
    jne build_error
    inc si

    call skip_space

    call sec_reg
    jc build_error
    cmp al, 1
    je cmp_reg

    push cx
    push dx
    call com_arg
    dec si
    pop dx
    pop bx
    jc build_error
    cmp bl, 0
    jne not_al
    cmp bh, 2
    je op_ax

    jmp write_imm

a_flag:
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
    jmp skip_flag

skip_flag:
    lodsb
    cmp al, 13
    je flag_skipped
    cmp al, 0
    je flag_skipped
    jmp skip_flag

flag_skipped:
    mov cx, 0
    sub cx, 2
    mov bx, dx
    mov byte [bytes + bx], 0
    inc dx
    jmp ins_compare

flag_ready:
    call skip_space
    push si
    jmp flag_label

flag_label:
    lodsb
    cmp al, ";"
    je a_flag
    cmp al, " "
    je a_flag
    cmp al, 13
    je a_flag
    cmp al, 0
    je a_flag
    inc cx
    jmp flag_label

com_flag:
    mov di, flag_table
    jmp flag_compare

flag_compare:
    cmp di, flag_end
    jae build_error

    mov bx, [di]
    mov cx, [di + 4]

    push si
    push di

    mov di, bx
    repe cmpsb

    pop di
    pop si

    je flag_true

    add di, 6
    jmp flag_compare

flag_true:
    mov ax, [di + 2]
    mov cx, [di + 4]
    cmp ax, 0xe9
    je com_jmp
    add si, cx
    mov bx, dx
    mov byte [bytes + bx], al
    inc dx
    cmp byte [si], " "
    jne build_error

    call to_space
    call skip_space

    mov cx, 0
    cmp byte [si + 2], "0"
    jl flag_ready
    cmp byte [si + 2], "9"
    jg flag_ready

    push dx
    call com_arg
    dec si
    pop dx
    jc build_error
    sub cx, 0x9e00
    sub cx, dx
    sub cx, 2
    mov bx, dx
    mov byte [bytes + bx], cl
    inc dx
    mov bx, dx
    mov byte [bytes + bx], ch
    inc dx

    jmp ins_compare

com_inc:
    dec dx

    call reg_compare
    jc build_error
    add si, 2
    mov bx, dx
    add byte [bytes + bx], cl
    inc dx

    jmp ins_compare

com_dec:
    dec dx

    call reg_compare
    jc build_error
    add si, 2
    mov bx, dx
    add byte [bytes + bx], cl
    inc dx

    jmp ins_compare

com_db:
    dec dx
    jmp db_loop

db_loop:
    cmp byte [si], '"'
    je string_mode
    cmp byte [si], "'"
    je char_mode

    mov al, [si]
    mov ah, 0x0e

    push dx
    call com_arg
    dec si
    pop dx
    jc build_error

    mov bx, dx
    mov [bytes + bx], cl
    inc dx
    jmp check_comma

char_mode:
    inc si
    jmp char_loop

char_loop:
    lodsb
    cmp al, "'"
    je check_comma
    cmp al, 0
    je build_error

    mov bx, dx
    mov [bytes + bx], al
    inc dx
    jmp char_loop

string_mode:
    inc si
    jmp str_loop

str_loop:
    lodsb
    cmp al, '"'
    je check_comma
    cmp al, 0
    je build_error

    mov bx, dx
    mov [bytes + bx], al
    inc dx
    jmp str_loop

check_comma:
    call skip_space
    cmp byte [si], ","
    jne ins_compare
    inc si
    call skip_space
    jmp db_loop

com_dw:
    dec dx
    jmp dw_loop

dw_loop:
    push dx
    call com_arg
    dec si
    pop dx
    jc build_error

    mov bx, dx
    mov [bytes + bx], cl
    inc dx
    mov bx, dx
    mov [bytes + bx], ch
    inc dx

    call skip_space
    cmp byte [si], ","
    jne ins_compare
    inc si
    call skip_space
    jmp dw_loop

com_call:
    mov cx, 0
    cmp byte [si + 4], "0"
    jl jmp_ready
    cmp byte [si + 4], "9"
    jg jmp_ready

    push dx
    call com_arg
    dec si
    pop dx
    jc build_error
    sub cx, 0x9e00
    sub cx, dx
    sub cx, 2
    mov bx, dx
    mov byte [bytes + bx], cl
    inc dx
    mov bx, dx
    mov byte [bytes + bx], ch
    inc dx

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
    jne call_done
    clc
    ret

num_16:
    mov bx, dx
    mov byte [bytes + bx], al
    inc dx
    clc
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
    je call_done
    jmp call_done

arg_label:
    mov bx, si
    xor cx, cx
    jmp arg_len

arg_len:
    cmp byte [bx], 0
    je len_done
    cmp byte [bx], 13
    je len_done
    cmp byte [bx], " "
    je len_done
    cmp byte [bx], ";"
    je len_done
    inc bx
    inc cx
    jmp arg_len

len_done:
    mov di, jmps
    add di, [j_count]

    mov ax, si
    stosw
    mov ax, dx
    stosw
    mov ax, cx
    stosw

    add word [j_count], 6
    add si, cx
    inc si
    mov cx, 0x9e00
    clc
    ret

com_arg:
    mov ax, 0
    mov cx, 0
    call skip_space

    cmp byte [si], 13
    je call_done
    cmp byte [si], 0
    je call_done
    cmp byte [si], "'"
    je com_one
    cmp byte [si], '"'
    je com_two
    cmp byte [si], "0"
    jl arg_label
    cmp byte [si], "9"
    jg arg_label
    cmp byte [si + 1], "x"
    jne num_dec
    cmp byte [si + 1], 13
    je num_dec
    cmp byte [si + 1], 0
    je num_dec
    cmp byte [si + 1], "x"
    jne call_done

    add si, 2
    jmp com_hex

check_hex:
    cmp bl, "0"
    jb call_done
    cmp bl, "9"
    jbe is_hex
    cmp bl, "a"
    jb call_done
    cmp bl, "f"
    ja call_done
    clc
    ret

is_hex:
    clc
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
    je end_hex
    cmp bl, 13
    je end_hex
    cmp bl, " "
    je end_hex
    cmp bl, ";"
    je end_hex

    mov bh, 0
    call check_hex
    jc call_done
    cmp bl, "9"
    jbe is_dec
    sub bl, "a" - 10
    mov dx, 0
    mov cx, 16
    mul cx
    cmp dx, 0
    jne call_done
    add ax, bx
    jc call_done
    jmp com_hex

is_dec:
    mov dx, 0
    sub bl, "0"
    mov cx, 16
    mul cx
    cmp dx, 0
    jne call_done
    add ax, bx
    jc call_done
    jmp com_hex

end_hex:
    cmp byte [si - 2], "x"
    je call_done
    clc
    ret

num_dec:
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
    jne call_done
    mov cx, ax

    lodsb

    cmp al, "0"
    jl call_done
    cmp al, "9"
    jg call_done
    sub al, "0"
    mov ah, 0
    add cx, ax
    jc call_done

    jmp num_dec

com_one:
    inc si
    mov cl, [si]
    inc si
    cmp byte [si], "'"
    jne call_done
    add si, 2
    ret
    
com_two:
    inc si
    mov cl, [si]
    inc si
    cmp byte [si], '"'
    jne call_done
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

mem_table:
    dw reg_si, 4, 2
    dw reg_di, 5, 2
    dw reg_bp, 6, 2
    dw reg_bx, 7, 2

mem_end:

ins_mov: db "mov"
ins_int: db "int"
ins_jmp: db "jmp"
ins_cmp: db "cmp"
ins_inc: db "inc"
ins_dec: db "dec"
ins_db: db "db"
ins_dw: db "dw"
ins_call: db "call"
ins_ret: db "ret"

flag_jb: db "jb"
flag_jc: db "jc"
flag_jnae: db "jnae"
flag_jae: db "jae"
flag_jnb: db "jnb"
flag_jnc: db "jnc"
flag_jbe: db "jbe"
flag_jna: db "jna"
flag_ja: db "ja"
flag_jnbe: db "jnbe"
flag_jl: db "jl"
flag_jnge: db "jnge"
flag_jge: db "jge"
flag_jnl: db "jnl"
flag_jle: db "jle"
flag_jng: db "jng"
flag_jg: db "jg"
flag_jnle: db "jnle"
flag_je: db "je"
flag_jz: db "jz"
flag_jne: db "jne"
flag_jnz: db "jnz"
flag_js: db "js"
flag_jns: db "jns"
flag_jo: db "jo"
flag_jno: db "jno"
flag_jp: db "jp"
flag_jpe: db "jpe"
flag_jnp: db "jnp"
flag_jpo: db "jpo"
flag_jcxz: db "jcxz"

ins_table:
    dw ins_mov, com_mov, 3, 0xb0
    dw ins_int, com_int, 3, 0xcd
    dw ins_cmp, com_cmp, 3, 0x3c
    dw ins_inc, com_inc, 3, 0x40
    dw ins_dec, com_dec, 3, 0x48
    dw ins_db, com_db, 2, 0x00
    dw ins_dw, com_dw, 2, 0x00
    dw ins_call, com_call, 4, 0xe8
    dw ins_ret, ins_compare, 3, 0xc3

ins_end:

flag_table:
    dw ins_jmp, 0xe9, 3
    dw flag_jb, 0x72, 2
    dw flag_jc, 0x72, 2
    dw flag_jnae, 0x72, 4
    dw flag_jae, 0x73, 3
    dw flag_jnb, 0x73, 3
    dw flag_jnc, 0x73, 3
    dw flag_jbe, 0x76, 3
    dw flag_jna, 0x76, 3
    dw flag_ja, 0x77, 2
    dw flag_jnbe, 0x77, 4
    dw flag_jl, 0x7c, 2
    dw flag_jnge, 0x7c, 4
    dw flag_jge, 0x7d, 3
    dw flag_jnl, 0x7d, 3
    dw flag_jle, 0x7e, 3
    dw flag_jng, 0x7e, 3
    dw flag_jg, 0x7f, 2
    dw flag_jnle, 0x7f, 4
    dw flag_je, 0x74, 2
    dw flag_jz, 0x74, 2
    dw flag_jne, 0x75, 3
    dw flag_jnz, 0x75, 3
    dw flag_js, 0x78, 2
    dw flag_jns, 0x79, 3
    dw flag_jo, 0x70, 2
    dw flag_jno, 0x71, 3
    dw flag_jp, 0x7a, 2
    dw flag_jpe, 0x7a, 3
    dw flag_jnp, 0x7b, 3
    dw flag_jpo, 0x7b, 3
    dw flag_jcxz, 0xe3, 4

flag_end:

com_bit: db 0
labels: times 3 * 32 dw 0
l_count: dw 0
jmps: times 3 * 32 dw 0
j_count: dw 0
error_line: db "Error line: ", 0
bytes: times 512 db 0