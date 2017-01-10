
	cpu 	1802
	
return macro
	dis
	endm

r0 = 0 															; not used (may be used in interrupt display)
r1 = 1 															; interrupt register
r2 = 2 															; stack pointer

rVarPtr = 9 													; always points to variables.
rExprPC = 10 													; used as P register in expression (mandated)
rSrc = 11 														; source code.
rUtilPC = 12 													; used as P register calling routines (not mandated)
rSubPC = 13														; used as P register to call routines within routines
rParam1 = 14 													; subroutine parameters/return values.
rParam2 = 15

rParenthesisLevel = 9 											; bracket level (low byte)

ldr macro 	r,n
	ldi 	(n)/256
	phi 	r
	ldi 	(n)&255
	plo 	r
	endm


	dis
	db 		0
	ldr 	r2,3FFFh
	sex 	r2
	ldr 	rVarPtr,2800h
	ldr 	rSrc,eString
	ldr 	rExprPC,EXPRevaluate
	mark
	sep 	rExprPC
	dec 	r2
wait:
	br 	wait

buffer:
	org 		100h
	include 	expression.asm

	org 		200h
UtilityPage:	
	include 	utility/itoa.asm
	include 	utility/multiply.asm
	include 	utility/divide.asm
	include 	utility/atoi.asm


__OpAdd:
	sex		r2 														; rParam1 := rParam1 + rParam2
	glo 	rParam2
	str 	r2
	glo 	rParam1
	add	
	plo 	rParam1
	ghi 	rParam2
	str 	r2
	ghi 	rParam1
	adc
	phi 	rParam1
	inc 	r2
	return

__OpSub:															; rParam1 := rParam1 - rParam2
	sex		r2
	glo 	rParam2
	str 	r2
	glo 	rParam1
	sm
	plo 	rParam1
	ghi 	rParam2
	str 	r2
	ghi 	rParam1
	smb
	phi 	rParam1
	inc 	r2
	return

__OpLookUp: 														; rParam1 := Memory[* + rParam2 * 2]
	sex 	r2
	glo 	rParam2 												; double rParam2
	shl
	plo 	rParam2
	ghi 	rParam2
	rshl
	phi 	rParam2
	ldi 	'*' * 2 												; point VarPtr to '*' variable
	plo 	rVarPtr
	sex 	rVarPtr

	glo 	rParam2 												; add * to rParam2 
	add
	plo 	rParam2		
	inc 	rVarPtr
	ghi 	rParam2
	adc
	phi 	rParam2 

	lda 	rParam2 												; read rParam2 into rParam1
	plo 	rParam1
	ldn 	rParam2
	phi 	rParam1
	sex 	r2
	inc 	r2
	return

oper macro chdb,addr
	db 		chdb,addr & 255
	endm 

__OperatorTable:
	oper 		'+',__OpAdd 
	oper		'*',Multiply
	oper 		'/',Divide
	oper 		'@',__OpLookUp 
	oper 		0,__OpSub

eString:
	db 		"1+(2*3)",0
