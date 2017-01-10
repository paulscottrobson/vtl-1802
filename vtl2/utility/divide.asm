; ***************************************************************************************************************
; ***************************************************************************************************************
;
;		File:		divide.asm
;		Purpose:	Divide two 16 bit integers.
;		Author:		Paul Robson (paul@robsons.org.uk)
;		Date:		9th January 2017.
;		Size: 		54 bytes.
;
; ***************************************************************************************************************
; ***************************************************************************************************************

; *******************************************************************************************************************
;
;				Calculate rParam1 / rParam2.  Result in rParam1. Remainder in rParam2.
;
; *******************************************************************************************************************

__DIVExit:
	inc 	r2 															; point to XP on the stack
	return

Divide:
	sex 	r2 															; back using R2 as the index register
																		; rParam1 is the dividend.
																		; rParam2 is the remainder.
																		; tos is [divisor:2][counter:1] 

	ldi 	16															; push counter on stack - 16 because post	
	stxd 																; decrements in main loop.

	ghi 	rParam2 													; push divisor on stack.
	stxd
	glo 	rParam2
	str 	r2 	
	
	ldi 	0 															; clear the remainder
	phi 	rParam2
	plo 	rParam2
	add 																; anything + 0 clears DF.

__DIVLoopIncR2IncR2:
	inc		r2 															; point R2 back to the counter.
__DIVLoopIncR2:
	inc 	r2

__DIVLoop:

	glo 	rParam1 													; shift DF into dividend, shift old bit 15 to DF
	rshl
	plo 	rParam1
	ghi 	rParam1
	rshl
	phi 	rParam1

	ldn 	r2 															; look at counter.
	bz 		__DIVExit 													; if zero then complete (decrement done later)

	glo	 	rParam2 													; shift DF into then remainder (rParam2)
	rshl
	plo 	rParam2
	ghi 	rParam2
	rshl
	phi 	rParam2

	ldn 	r2 															; decrement the counter (AFTER the test)
	smi 	1
	stxd 																; when saving back, point R2 to divisor LSB.
	dec 	r2

	glo 	rParam2 													; calculate remainder.0 - divisor.0
	sm
	dec 	r2 															; save the interim value below the LSB.
	str 	r2
	inc 	r2 															; to LSB
	inc		r2 															; to MSB
	ghi 	rParam2 													; calculate remainder.1 - divisor.1
	smb

	bnf 	__DIVLoopIncR2 												; if DF = 0 then inc r2 (to ctr) and loop back

	phi 	rParam2 													; copy result to remainder
	dec 	r2 															; to divisor.0
	dec 	r2 															; to temp result
	lda 	r2 															; get temp result, to divisor.0
	plo 	rParam2
	br 		__DIVLoopIncR2IncR2 										; go back, inc r2 twice to counter
