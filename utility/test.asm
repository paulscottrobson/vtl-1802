
	cpu 	1802
	
return macro
	dis
	endm

r0 = 0 															; not used (may be used in interrupt display)
r1 = 1 															; interrupt register
r2 = 2 															; stack pointer

rUtilPC = 12 													; used as P register calling routines (not mandated)
rSubPC = 13														; used as P register to call routines within routines
rParam1 = 14 													; subroutine parameters/return values.
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
	ldr 	rParam1,65432
	ldr 	rParam2,buffer-1
	ldr 	rUtilPC,IntegerToASCII

	mark	
	sep 	rUtilPC
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

