## NenOS
NenOS is an operating system written in NASM assembly language. It runs in real mode (x16) using BIOS interrupts. It has a simple file system and a built‑in assembler.

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
The built‑in NenOS assembler currently supports only the MOV to AX, BX, CX, DX registers, all interrupts and the entire syntax of a standard assembler. This allows you to write simple programs using the WRITE command, compile them using the BUILD command, and run them using the RUN command. Code examples:
```
mov al, "!"
mov ah, 0x0e
int 0x10
```
```
mov ah, 0x00
int 0x16
mov ah, 0x0e
int 0x10
```

## Screenshots
![alt Preview](preview.png)
