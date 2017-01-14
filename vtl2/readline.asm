; ***************************************************************************************************************
; ***************************************************************************************************************
;
;		File:		readline.asm
;		Purpose:	Read an input line
;		Author:		Paul Robson (paul@robsons.org.uk)
;		Date:		14th January 2017.
;
; ***************************************************************************************************************
; ***************************************************************************************************************

; ***************************************************************************************************************
;
;						Read Line in from Keyboard, returns address in rParam1
;
; ***************************************************************************************************************

READLine:
	ldi 	7Fh 														; set up rParam1 to point to the string.
	plo 	rParam1
	ghi 	rVarPtr
	phi 	rParam1

__RLLNextCharacter:
	inc 	rParam1
__RLLLoop:
	sex 	r2 															; use R2 as index
	lrx 	rSubPC,XIOGetKey 											; call get key routine.
	mark 	
	sep 	rSubPC
	dec 	r2
	str 	rParam1	 													; save in text buffer.

	lrx 	rSubPC,XIOWriteCharacter
	ldn 	rParam1
	mark
	sep 	rSubPC
	dec 	r2

	ldn 	rParam1
	xri 	8 															; Ctl+H
	bz 		__RLLPrevCharacter 											; get previous character
	xri 	13!8 														; is it CR ?
	bnz 	__RLLNextCharacter 											; no go around again
__RLLExit:
	str 	rParam1 													; save the zero in rVarPtr making string ASCIIZ.
	ldi 	80h 														; point rParam1 to the start of the string.
	plo 	rParam1
	inc 	r2 															; and exit.
	return

__RLLPrevCharacter:
	dec 	rParam1 													; handle backspace (chr(8))
	glo 	rParam1
	shl
	bdf 	__RLLLoop
	br 		__RLLNextCharacter
