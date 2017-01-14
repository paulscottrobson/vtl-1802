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

xpush macro n
	glo 	n
	stxd
	ghi 	n
	stxd
	endm

xpull macro n
	inc 	r2
	lda 	r2
	phi 	n
	ldn 	r2
	plo 	n
	endm

; ***************************************************************************************************************
;
;		This routine provides the variable in D. On exit, if D = 0 the "variable" has been accessed and
;		put in rParam2.
;
;		The right hand variables with side effects in VTL-2 are :-
;
;		?	input an expression (we will probably do integer here.)
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
	xri 	'?'															; check if '?' (get character)
	bz 		__SHGetKey
	xri 	'*'!'?'														; check if '*' (get string expression)
	bz 		__SHInput
	br 		__SHExit

; ***************************************************************************************************************
;
;							? operator. Returns a single key press in rParam2
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
;							* operator. Inputs a string, evaluates it and returns.
;
; ***************************************************************************************************************

__SHInput:
	xpush 	rSrc 														; we call expression recursively so save stuff on stack.
	xpush 	rExprPC
	xpush 	rParenthesisLevel
	xpush 	rSaveStack

	ldr 	rSrc,zString 								

	ldr 	rExprPC,EXPRevaluate 										; set up to recursively call evaluator
	mark 																; and do so.
	sep 	rExprPC
	dec 	r2

	glo 	rParam1 													; result comes back in rParam1, so copy it to rParam2.
	plo 	rParam2
	ghi 	rParam1
	phi 	rParam2

	xpull 	rSaveStack 													; restore registers.
	xpull 	rParenthesisLevel
	xpull 	rExprPC
	xpull 	rSrc

	ldi 	0  															; and exit with D = 0 indicating done.
	br 		__SHExit 

zString:
	db 		"42*2",0

XIOGetKey:
	sex 	r2
	inp 	1
	bz 		XIOGetKey
	inc 	r2
	return


