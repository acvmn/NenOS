# NenOS

This repository contains files for operating system "NenOS" on assembly language. NenOS is an operating system written in NASM assembly language. It runs in real mode (x16) using BIOS interrupts. It has a simple file system and a built‑in LEN language interpreter.

## Commands
- CLS - clear the screen.
- ECHO &lt;?&gt; - print text to screen.
- HELP - displaying available commands.
- READ - read the document.
- REBOOT - reboot the computer.
- RUN - run the program.
- TIME - launches the watch app.
- WRITE - write the document.

You can also write your own programs, save them, and run them. To run the program, enter RUN. After that, the OS will read the file and execute the commands from it sequentially. Example of a program:
```
cls
echo Current Time:
time
run
```
This program starts the watch app.

You can use any commands from <help> to write a program, which allows you to create loops, for example:
```
echo LOOP
run
```
To exit the loop, press any key. If the current command is TIME, press &lt;ESC&gt;.

![alt Preview](preview.png)
