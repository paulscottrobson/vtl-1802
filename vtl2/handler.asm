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
;		put in rParam2. Otherwise D should be unchanged.
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
	xri 	'?'
	br 		__SHExit

; ***************************************************************************************************************
;
;							$ operator. Returns a single key press in rParam2
;
; ***************************************************************************************************************

__SHGetKey:
	lrx 	rUtilPC,XIOGetKey 											; this is the external function which reads the keyboard
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
	lrx 	rSubPC,XIOWriteCharacter 									; prompt.
	ldi 	'?'
	mark
	sep 	rSubPC
	dec 	r2

	lrx 	rUtilPC,READLine 											; read line into input buffer.
	mark 																; returns it in rParam1
	sep 	rUtilPC 
	dec 	r2

	lrx 	rUtilPC,ASCIIToInteger										; convert to number
	mark 																; and do so.
	sep 	rUtilPC
	dec 	r2
	bz 		__SHInput

	ldi 	0  															; and exit with D = 0 indicating done.
	br 		__SHExit 

