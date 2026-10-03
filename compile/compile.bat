cd ../build
del NenOS.iso
del NenOS.bin
"C:\Program Files\NASM\nasm.exe" -f bin ..\src\boot.asm -o boot.bin
"C:\Program Files\NASM\nasm.exe" -f bin ..\src\kernel.asm -o kernel.bin
copy /b boot.bin + kernel.bin NenOS.bin
del boot.bin
del kernel.bin
..\compile\xorriso.exe -as mkisofs \ -volid "NenOS" \ -isohybrid-mbr NenOS.bin \ -b NenOS.bin \ -no-emul-boot \ -boot-load-size 280 -boot-info-table \ -eltorito-alt-boot \ -isohybrid-gpt-basdat \ -o NenOS.iso
del NenOS.bin
cd C:\Program Files\Oracle\VirtualBox
"C:\Program Files\Oracle\VirtualBox\vboxmanage.exe" controlvm {2c90ea06-a285-4753-a6b1-ea59cbb54f28} reset