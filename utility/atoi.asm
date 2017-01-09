; ***************************************************************************************************************
; ***************************************************************************************************************
;
;		File:		atoi.asm
;		Purpose:	Extract 16 bit integer from ASCII string.
;		Author:		Paul Robson (paul@robsons.org.uk)
;		Date:		9th January 2017.
;		Size: 		67 bytes.
;
; ***************************************************************************************************************
; ***************************************************************************************************************

; *******************************************************************************************************************
;
;	Takes one value in rParam1, pointer to a string, returns number read in rParam2.
;	rParam1 points to the next character after the last one of the number.	
;	
;	On exit non-zero if a digit was read.
;
; *******************************************************************************************************************

__ATOIExit:
	dec 	rParam1 													; undo the last read, wasn't a digit.
	lda 	r2 															; read the flag for 'digits read'
	return

ASCIIToInteger:
	sex 	r2 															; index back at 2
	ldi 	0 															; clear number read
	plo 	rParam2
	phi 	rParam2
	str 	r2 															; [TOS] is count of digits read okay.

__ATOILoop:
	lda 	rParam1 													; read next character and bump
	xri 	' ' 														; skip over spaces.
	bz 		__ATOILoop 												
	xri 	' ' 														; fix it back.
	adi 	255-'9' 													; will cause DF if >= '9'
	bdf 	__ATOIExit
	adi 	10 															; adding 10 will cause NF if < '0'	
	bnf 	__ATOIExit

	stxd 																; push digit value, current value of number
	ghi 	rParam2  													; on stack.
	stxd
	glo 	rParam2
	str 	r2

__ATOIDoubleRParam2 macro 												; macro that doubles the value in rParam2
	glo 	rParam2 													
	shl
	plo 	rParam2
	ghi 	rParam2
	rshl
	phi 	rParam2
	endm

	__ATOIDoubleRParam2 												; rParam2 * 2
	__ATOIDoubleRParam2 												; rParam2 * 4
	glo 	rParam2 													; add stack values on there.
	add
	plo 	rParam2
	inc 	r2
	ghi 	rParam2
	adc
	phi 	rParam2  													; so now rParam * 5
	__ATOIDoubleRParam2 												; so now rParam * 10

	inc 	r2 															; point to digit value
	glo 	rParam2
	add
	plo 	rParam2
	ghi 	rParam2
	adci 	0
	phi 	rParam2

	ldi 	0FFh 														; set the 'read a digit' flag.
	str 	r2 
	br 		__ATOILoop
