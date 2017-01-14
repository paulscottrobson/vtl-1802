asl -L vtl2.asm
p2bin -r 0-4095 -l 0 vtl2.p
rm vtl2.p
../emulator/dist/Debug/GNU-Linux/emulator vtl2.bin
