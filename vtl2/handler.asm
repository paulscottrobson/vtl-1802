; ***************************************************************************************************************
; ***************************************************************************************************************
;
;		File:		handler.asm
;		Purpose:	Handle side-effect variables on read.
;		Author:		Paul Robson (paul@robsons.org.uk)
;		Date:		11th January 2017.
;
; ***************************************************************************************************************
; ***************************************************************************************************************

; ***************************************************************************************************************
;
;		This routine provides the variable in D. On exit, if D = 0 the "variable" has been accessed and
;		put in rParam2.
;
;		The right hand variables with side effects in VTL-2 are :-
;
;		?	input an integer (technically an expression .....)
; 		$ 	input a single character
;
;		This is run with P = rSpecialHandler X = 2
;
;		Must preserve: rSrc, rVarPtr*, rExprPC, rParenthesisLevel, rSaveStack and of course R2.
;
;		* can be assumed constant.
;
;		Use: rUtilPC, rSubPC, rParam1, rParam2.
;
; ***************************************************************************************************************

__SHExit:
	sep 	rExprPC
SpecialHandler:
	xri 	'$'															; check if '$' (get character)
	bz 		__SHGetKey
	xri 	'$'!'?'														; check if '?' (get string expression)
	bz 		__SHInput
	br 		__SHExit

; ***************************************************************************************************************
;
;							$ operator. Returns a single key press in rParam2
;
; ***************************************************************************************************************

__SHGetKey:
	ldr 	rUtilPC,XIOGetKey 											; this is the external function which reads the keyboard
	mark 																; and it is called using the MARK method. 
	sep 	rUtilPC
	dec 	r2
	plo 	rParam2 													; put result in rParam2.0
	ldi 	0 															; clear rParam2.1 and D, indicating successful processing.
	phi 	rParam2
	br 		__SHExit 													; and exit.

; ***************************************************************************************************************
;
;							? operator. Inputs a string, evaluates it and returns.
;
; ***************************************************************************************************************

__SHInput:
	ldr 	rSubPC,XIOWriteCharacter 									; prompt.
	ldi 	'?'
	mark
	sep 	rSubPC
	dec 	r2

	ldr 	rUtilPC,READLine 											; read line into input buffer.
	mark 																; returns it in rParam1
	sep 	rUtilPC 
	dec 	r2

	ldr 	rUtilPC,ASCIIToInteger										; convert to number
	mark 																; and do so.
	sep 	rUtilPC
	dec 	r2
	bz 		__SHInput

	ldi 	0  															; and exit with D = 0 indicating done.
	br 		__SHExit 

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
	ldr 	rSubPC,XIOGetKey 											; call get key routine.
	mark 	
	sep 	rSubPC
	dec 	r2
	str 	rParam1	 													; save in text buffer.

	ldr 	rSubPC,XIOWriteCharacter
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
	dec 	rParam1
	glo 	rParam1
	shl
	bdf 	__RLLLoop
	br 		__RLLNextCharacter
