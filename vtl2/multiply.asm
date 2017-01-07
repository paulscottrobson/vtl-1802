; ***************************************************************************************************************
; ***************************************************************************************************************
;
;		File:		multiply.asm
;		Purpose:	16 bit x 16 bit unsigned multiply with 16 bit product.
;		Author:		Paul Robson (paul@robsons.org.uk)
;		Date:		7th January 2017.
;
; ***************************************************************************************************************
; ***************************************************************************************************************

; ***************************************************************************************************************
;
;		16 bit multiplier. 
;
;		On entry, first value is (R2-1)(R2) (e.g. on the stack, TOS = LSB), second is in rRValue
;		On entry, X is 2.
;		On exit, result is in R2-1/R2 (MSB/LSB).
;	
;		R2 (stack pointer) is unchanged. rRValue is changed. rResult is changed
;
; ***************************************************************************************************************

MULStart:
	ldi 	0  													; clear the result.
	phi 	rResult
	plo 	rResult

__MULLoop:	
	ghi 	rRValue 											; shift the R Value right into the carry
	shr
	phi 	rRValue
	glo 	rRValue
	rshr
	plo 	rRValue

	bnf 	__MULDontAdd 										; if no carry do not add multiplicand.

	glo 	rResult 											; add value on stack (multiplicand) to rResult
	add
	plo 	rResult
	dec 	r2
	ghi 	rResult
	adc
	phi 	rResult
	inc 	r2

__MULDontAdd:	
	
	ldn 	r2 													; shift multiplicand left
	add
	stxd
	ldn 	r2
	adc
	str 	r2
	inc 	r2

	glo 	rRValue 											; loop back if multiplier is non-zero.
	bnz 	__MULLoop
	ghi 	rRValue
	bnz 	__MULLoop

	glo 	rResult 											; copy result out to stack.
	stxd
	ghi 	rResult
	str 	r2
	inc 	r2


