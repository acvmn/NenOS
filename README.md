## NenOS
NenOS is an operating system written in NASM assembly language. It runs in real mode (x16) using BIOS interrupts. It has a simple file system and a built‑in assembler.

## Commands
- BUILD &lt;from&gt; &lt;to&gt; - compile the file.
- CALC &lt;sample&gt; - calculate.
- CLEAR &lt;number&gt; - clear the document.
- CLS - clear the screen.
- COPY &lt;from&gt; &lt;to&gt; - copy the document.
- ECHO &lt;text&gt; - print text to screen.
- HELP - displaying available commands.
- NOTE &lt;text&gt; - leave a comment in the script.
- READ &lt;number&gt; - read the document.
- REBOOT - reboot the computer.
- RUN &lt;number&gt; - run the program.
- TIME - launches the watch app.
- WRITE &lt;number&gt; - write the document.

## Assembler
The built‑in NenOS assembler currently supports only the AX register and interrupts. This allows you to write simple programs using the WRITE command, compile them using the BUILD command, and run them using the RUN command. Code examples:
```
mov al, 33
mov ah, 0x0e
int 0x10
```
```
mov al, 0x00
int 0x16
mov ah, 0x0e
int 0x10
```

## Screenshots
![alt Preview](preview.png)
