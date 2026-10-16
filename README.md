## NenOS
NenOS is an operating system written in NASM assembly language. It runs in real mode (x16) using BIOS interrupts. It has a simple file system and a built‑in assembler. The file system in it works by numbers. For example, READ 1 reads the very first file in the file system.

## Commands
- BUILD &lt;from&gt; &lt;to&gt; - compile the file.
- CALC &lt;sample&gt; - calculate.
- CLEAR &lt;number&gt; - clear the document.
- CLS - clear the screen.
- COPY &lt;from&gt; &lt;to&gt; - copy the document.
- HELP - displaying available commands.
- READ &lt;number&gt; - read the document.
- REBOOT - reboot the computer.
- RUN &lt;number&gt; - run the program.
- TIME - launches the watch app.
- WRITE &lt;number&gt; - write the document.

## Assembler
The built‑in NenOS assembler currently supports the MOV to all 16 bit registers, all interrupts, JMP, labels, CMP, JE and the entire syntax of a standard assembler. This allows you to write simple programs using the WRITE command, compile them using the BUILD command, and run them using the RUN command. Code example:
```
write:
    mov ah, 0x00
    int 0x16
    cmp al, 8
    je delete
    cmp al, 13
    je new
    cmp al, 27
    je exit
    mov ah, 0x0e
    int 0x10
    jmp write

delete:
    mov al, 8
    mov ah, 0x0e
    int 0x10
    mov al, " "
    mov ah, 0x0e
    int 0x10
    mov al, 8
    mov ah, 0x0e
    int 0x10
    jmp write

new:
    mov al, 10
    mov ah, 0x0e
    int 0x10
    mov al, 13
    mov ah, 0x0e
    int 0x10
    jmp write

exit:
```

## Screenshots
![alt Preview](preview.png)
