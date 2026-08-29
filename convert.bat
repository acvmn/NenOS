cd C:\Images\NenOS
del NenOS.iso
del NenOS.bin
"C:\Program Files\NASM\nasm.exe" -f bin ..\boot.asm -o boot.bin
"C:\Program Files\NASM\nasm.exe" -f bin ..\kernel.asm -o kernel.bin
copy /b boot.bin + kernel.bin NenOS.bin
del boot.bin
del kernel.bin
C:\Images\xorriso -as mkisofs \ -volid "NenOS" \ -isohybrid-mbr NenOS.bin \ -c boot.cat \ -b NenOS.bin \ -no-emul-boot \ -boot-load-size 4 -boot-info-table \ -eltorito-alt-boot \ -isohybrid-gpt-basdat \ -o NenOS.iso
del NenOS.bin
cd C:\Program Files\Oracle\VirtualBox
vboxmanage startvm {620df864-9db7-429b-8af1-696a1056dcac}