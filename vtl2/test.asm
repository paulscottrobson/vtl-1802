
	cpu 	1802
	
return macro
	dis
	endm

r0 = 0 															; not used (may be used in interrupt display)
r1 = 1 															; interrupt register
r2 = 2 															; stack pointer

rVarPtr = 6 													; always points to variables.
rExprPC = 7 													; used as P register in expression (mandated)
rSrc = 8 														; source code.
rSpecialHandler = 9 											; special variables handler.
rParenthesisLevel = 10 											; bracket level (low byte)
rSaveStack = 11 												; original value of stack pointer

rUtilPC = 12 													; used as P register calling routines (not mandated)
rSubPC = 13														; used as P register to call routines within routines
rParam1 = 14 													; subroutine parameters/return values.
rParam2 = 15


ldr macro 	r,n
	ldi 	(n)/256
	phi 	r
	ldi 	(n)&255
	plo 	r
	endm


	dis
	db 		0
	ldr 	r2,3FFFh 											; stack
	sex 	r2
	ldr 	rVarPtr,2800h 										; varptr high byte only reqd
	ldr 	rSrc,eString 										; evaluate the string
	ldr 	rExprPC,EXPRevaluate 								; the code
	ldr 	rSpecialHandler,SpecialHandler 						; dummy special handler.
	mark
	sep 	rExprPC
	dec 	r2
wait:
	br 	wait

SpecialHandler:
	sep 	rExprPC


	org 		100h
	include 	expression.asm

	org 		200h
UtilityPage:	
	include 	utility/itoa.asm
	include 	utility/multiply.asm
	include 	utility/divide.asm
	include 	utility/atoi.asm

eString:
;	db 		" \"A\"+1",0
;	db 		":2)-1",0
;	db 		"42 ) this is a comment",0
;	db 		"4+255+",0
	db 		"(4*5)-(2*3)*2",0
