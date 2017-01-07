; ***************************************************************************************************************
; ***************************************************************************************************************
;
;		File:		divide.asm
;		Purpose:	16 bit x 16 bit unsigned divide with 16 bit result/remainder
;		Author:		Paul Robson (paul@robsons.org.uk)
;		Date:		7th January 2017.
;
; ***************************************************************************************************************
; ***************************************************************************************************************

; ***************************************************************************************************************
;
;		16 bit divisor.
;
;		On entry, first value is (R2-1)(R2) (e.g. on the stack, TOS = LSB), second is in rRValue
;		On entry, X is 2.
;		On exit, result is in R2-1/R2 (MSB/LSB). Remainder of division is in rRemainder.
;	
;		R2 (stack pointer) is unchanged. rRValue is changed. rCounter is changed.
;
; ***************************************************************************************************************

DIVStart:

	ldi 	0 													; zero remainder
	phi 	rRemainder
	plo 	rRemainder
	shrc 														; clear carry (DF)

	ldi 	17 													; set counter to 17.
	plo 	rCounter

__DIVLoop:
	ldn 	r2 													; read LSB of Dividend.
	rshl 														; shift carry into it left
	stxd  														; write back, point to MSB of Dividend.
	ldn 	r2													; read MSB
	rshl 														; shift into that
	str 	r2 													; write it back.
	inc 	r2 													; fix stack to point to LSB of Dividend.

	dec 	rCounter 											; decrement counter
	glo 	rCounter 											; exit if zero.
	bz 		__DIVExit

	glo 	rRemainder 											; shift DF into the remainder
	rshl
	plo 	rRemainder
	ghi 	rRemainder
	rshl
	phi 	rRemainder

	dec 	r2 													; make space on TOS for remainder-divisor temp 	
	dec 	r2
	glo 	rRValue 											; D = LSB divisor
	str 	r2
	glo 	rRemainder 											; D = LSB remainder - LSB divisor.
	sm
	phi 	rCounter 											; temp result in rCounter.1

	ghi 	rRValue 											; now repeat it with MSB.
	str 	r2
	ghi 	rRemainder
	smb  														; D = MSB of result.
	inc 	r2 													; fix up stack.
	inc 	r2

	bnf 	__DIVLoop 											; if DF = 0 loop back with DF = 0.

	phi 	rRemainder 											; update remainder with result of the sum.
	ghi 	rCounter 											; and the interim value
	plo 	rRemainder
	br 		__DIVLoop 											; loop round with DF = 1

__DIVExit:														; result is already in dividend.

DIVEnd:
