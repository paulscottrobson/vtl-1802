asl -L test.asm
p2bin -r 0-4095 -l 0 test.p
rm test.p
../emulator/dist/Debug/GNU-Linux/emulator test.bin
