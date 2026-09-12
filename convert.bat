cd NenOS
del NenOS.iso
del NenOS.bin
"C:\Program Files\NASM\nasm.exe" -f bin ..\boot.asm -o boot.bin
"C:\Program Files\NASM\nasm.exe" -f bin ..\kernel.asm -o kernel.bin
copy /b boot.bin + kernel.bin NenOS.bin
del boot.bin
del kernel.bin
..\xorriso.exe -as mkisofs \ -volid "NenOS" \ -isohybrid-mbr NenOS.bin \ -c boot.cat \ -b NenOS.bin \ -no-emul-boot \ -boot-load-size 4 -boot-info-table \ -eltorito-alt-boot \ -isohybrid-gpt-basdat \ -o NenOS.iso
del NenOS.bin
cd C:\Program Files\Oracle\VirtualBox
"C:\Program Files\Oracle\VirtualBox\vboxmanage.exe" controlvm {e1260df9-966e-444e-a9a8-6a5bfae27932} reset