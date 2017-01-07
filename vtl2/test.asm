
	cpu 	1802
	
r0 = 0
r1 = 1
r2 = 2
r3 = 3
r4 = 4
r5 = 5



rCounter = 13
rResult = 14 							
rRemainder = 14
rRValue = 15

	dis
	db 		0
	ldi 	040h 												; set up stack.
	phi 	r2
	ldi 	000h
	plo 	r2


v1 = 62770
v2 = 11537

	sex 	r2													; set up stack with left value.
	dec 	r2 													; (R2) = LSB (R2-1) = MSB
	ldi 	v1&255
	stxd
	ldi 	v1/256
	str 	r2
	inc 	r2

	ldi 	v2/256 												; set up rRValue with right value.
	phi 	rRValue
	ldi 	v2&255
	plo 	rRValue

;	include 	multiply.asm
	include 	divide.asm




st:	br		st
