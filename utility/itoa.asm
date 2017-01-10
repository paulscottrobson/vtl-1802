; ***************************************************************************************************************
; ***************************************************************************************************************
;
;		File:		itoa.asm
;		Purpose:	Convert 16 bit integer to ASCIIZ string
;		Author:		Paul Robson (paul@robsons.org.uk)
;		Date:		10th January 2017.
;		Size: 		47 bytes.
;
; ***************************************************************************************************************
; ***************************************************************************************************************

; *******************************************************************************************************************
;
;	rParam1 is the number to convert. rParam2 is the end of the buffer, which is written backwards. On exit.
;	rParam2 points to the string terminated in a NULL character.
;
; *******************************************************************************************************************

__ITOAExit:
	inc 	r2
	return

IntegerToASCII:
	sex 	r2 															; index back at 2
	ldi 	0 															; write the NULL terminator.
	str 	rParam2
__ITOALoop:
	stxd 																; push dummy value, digit return stored here.
	ghi 	rParam2 													; push rParam2 on the stack.
	stxd
	glo	 	rParam2
	stxd
	ldr 	rParam2,10 													; set to divide by 10.
	ldr 	rSubPC,Divide 												; set for call.
	mark  
	sep 	rSubPC 														; do the call.
	inc 	r2
	inc 	r2 															; save digit result in dummy space
	glo 	rParam2
	stxd 
	dec 	r2 															; now points to memory pointer for result
	lda 	r2 															; restore buffer pointer
	plo 	rParam2
	lda 	r2
	phi 	rParam2
	ldn 	r2 															; restore digit
	ori		'0'															; make ASCII 
	dec 	rParam2 													; back one character.
	str 	rParam2 													; write into buffer

	glo 	rParam1 													; go around again if non-zero
	bnz 	__ITOALoop
	ghi 	rParam1
	bnz 	__ITOALoop
	br 		__ITOAExit 													; and prepare to exit.