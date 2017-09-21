@echo off
echo Compiling
del game1.bin
c:\xampp\php\php a2gfx-dbl-hires.php
asm6.exe game1.asm game1.bin
echo Copying into diskette
copy master.dsk game1.dsk > nul
java -jar AppleCommander-1.3.5.jar -p game1.dsk DEMO B 0x200 < game1.bin
echo Running
start game1.dsk