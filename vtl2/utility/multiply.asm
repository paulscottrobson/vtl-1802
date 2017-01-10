; ***************************************************************************************************************
; ***************************************************************************************************************
;
;		File:		multiply.asm
;		Purpose:	Multiply two 16 bit integers.
;		Author:		Paul Robson (paul@robsons.org.uk)
;		Date:		9th January 2017.
;		Size: 		41 bytes.
;
; ***************************************************************************************************************
; ***************************************************************************************************************

; *******************************************************************************************************************
;
;	Multiply the values in rParam1 and rParam2 , returning result in rParam1.
;
; *******************************************************************************************************************

__MULExit:
	lda 	r2 															; pop LSB result off stack.
	plo 	rParam1
	lda 	r2  														; pop MSB result off stack, do inc r2
	phi 	rParam1
	return

Multiply:
	sex 	r2 															; back using R2 as the index register
	ldi 	0 															; reset the result, which is on the stack.
	stxd	
	str 	r2

__MULLoop:

	ghi 	rParam1 													; shift first multiplier right into DF
	shr
	phi 	rParam1
	glo 	rParam1
	rshr
	plo 	rParam1
	bnf 	__MULDontAdd 												; if DF is set add rParam2 to the result.

	glo 	rParam2 													; add rParam2 to result on TOS.
	add 
	str 	r2
	inc 	r2
	ghi 	rParam2
	adc
	stxd 

__MULDontAdd:
	glo 	rParam2 													; shift rParam2 left
	shl
	plo 	rParam2
	ghi 	rParam2
	rshl
	phi 	rParam2

	glo 	rParam1 													; is first multiplier non zero, if not go back.
	bnz 	__MULLoop
	ghi 	rParam1
	bnz 	__MULLoop
	br 		__MULExit 													; both are zero, so exit.	