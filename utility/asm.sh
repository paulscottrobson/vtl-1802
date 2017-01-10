asl -L test.asm
p2bin -r 0-1023 -l 0 test.p
rm test.p
cp divide.asm multiply.asm atoi.asm itoa.asm ../vtl2/utility
../emulator/dist/Debug/GNU-Linux/emulator test.bin