
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

	ldr 	r2,03FFFh
	sex 	r2
	ldr 	rParam1,51132 	; result 4DFr5
	ldr 	rParam2,41
	ldr 	r3,Divide

	mark	
	sep 	r3
	dec 	r2

wait:
	br 	wait


	include 	divide.asm
	include 	atoi.asm

