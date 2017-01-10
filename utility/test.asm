
	cpu 	1802
	
r0 = 0
r1 = 1
r2 = 2
r3 = 3
r4 = 4
r5 = 5


return macro
	dis
	endm

rSubPC = 13
rParam1 = 14
rParam2 = 15


ldr macro 	r,n
	ldi 	(n)/256
	phi 	r
	ldi 	(n)&255
	plo 	r
	endm


	dis
	db 		0

	ldr 	r2,3FFFh
	sex 	r2
	ldr 	rParam1,47258
	ldr 	rParam2,buffer-1
	ldr 	r3,IntegerToASCII

	mark	
	sep 	r3
	dec 	r2

wait:
	br 	wait

	db 	1,1,1,1,1,1
buffer:

	org 		100h
	include 	itoa.asm
	include 	multiply.asm
	include 	divide.asm
	include 	atoi.asm

