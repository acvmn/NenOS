# NenOS

This repository contains files for operating system "NenOS" on assembly language. NenOS is an operating system written in NASM assembly language. It runs in real mode (x16) using BIOS interrupts. It has a simple file system and you can create simple scripts on it.

## Commands
- CALC &lt;?&gt; - calculate.
- CLEAR &lt;?&gt; - clear the document.
- CLS - clear the screen.
- COPY &lt;?&gt; &lt;?&gt; - copy the document.
- ECHO &lt;?&gt; - print text to screen.
- HELP - displaying available commands.
- NOTE &lt;?&gt; - leave a comment in the script.
- READ &lt;?&gt; - read the document.
- REBOOT - reboot the computer.
- RUN &lt;?&gt; - run the program.
- TIME - launches the watch app.
- WRITE &lt;?&gt; - write the document.

You can also write your own programs, save them, and run them. WARNING: for the file system to work, make your disk where you want to write files the first one (0x80). In this case, you need to convert the image into a virtual hard disk or make the image accessible for recording. To run the program, enter RUN &lt;?&gt;. After that, the OS will read the file and execute the commands from it sequentially. Example of a program:
```
cls
echo Current Time:
time
run 1
```
This program starts the watch app.

You can use any commands from <help> to write a program, which allows you to create loops, for example:
```
echo LOOP
run 1
```
To exit the loop, press any key. If the current command is TIME, press &lt;ESC&gt;.

You can also jump from one file to another, for example:
```
echo Hello from first file!
run 2
```
```
echo Hello from second file!
run 1
```

![alt Preview](preview.png)
