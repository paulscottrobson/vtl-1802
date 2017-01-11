
	cpu 	1802
	
return macro
	dis
	endm

r0 = 0 															; not used (may be used in interrupt display)
r1 = 1 															; interrupt register
r2 = 2 															; stack pointer
r3 = 3 															; general run P

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


	dis 														; preamble.
	db 		0
	ldi 	start/256
	phi 	r3
	ldi 	start&255
	plo 	r3
	sep 	r3

	include 	expression.asm
	include 	handler.asm
	
start:
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

eString:
	db 		"?",0
;	db 		"40003>40004",0
;	db 		" \"A\"+1",0
;	db 		":2)-1",0
;	db 		"42 ) this is a comment",0
;	db 		"4+255+",0
	db 		"(4*5)-(2*3)*2",0
