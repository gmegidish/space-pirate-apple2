@echo off
echo Compiling
del game1.bin
c:\xampp\php\php ../tools/grfx/a2gfx-generate-tiles.php tilemap.png > tiles.s
c:\xampp\php\php ../tools/grfx/a2gfx-generate-sprites.php > sprites.s
..\bin\asm6.exe game1.asm game1.bin
echo Copying into diskette
copy ..\bin\master.dsk game1.dsk > nul
java -jar ../bin/AppleCommander-1.3.5.jar -p game1.dsk DEMO B 0x8000 < game1.bin
