
	cpu 	1802
	
r0 = 0
r1 = 1
r2 = 2
r3 = 3
r4 = 4
r5 = 5


rVarPtr = 9 													; variable pointer.
rExpression = 10 												; pointer to string expression.
rStackSave = 11 												; original stack value.
rParenDepth = 12 												; (lower byte) parenthesis depth.

rCounter = 13 													; used in multiply and divide.
rResult = 14 							
rRemainder = 14
rTemp = 14
rRValue = 15

	dis
	db 		0
	ldi 	040h 												; set up stack.
	phi 	r2
	ldi 	000h
	plo 	r2
	sex 	r2
	ldi 	sExpression/256 									; set up string pointer.
	phi 	rExpression
	ldi 	sExpression&255
	plo 	rExpression

	ldi 	03Eh 												; variables in this page.
	phi 	rVarPtr

	lbr 	EXPRession

sExpression:
	db 		" \"4\" 5) comment"

	include expression.asm
