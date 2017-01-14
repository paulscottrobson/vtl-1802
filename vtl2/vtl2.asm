
	cpu 	1802
	
r0 = 0 																	; not used (may be used in interrupt display)
r1 = 1 																	; interrupt register
r2 = 2 																	; stack pointer
r3 = 3 																	; general run P

rVarPtr = 6 															; always points to variables (64 variables 2 bytes each 6 bit ASCII)
rExprPC = 7 															; used as P register in expression (mandated)
rSrc = 8 																; source code.
rSpecialHandler = 9 													; special variables handler.
rParenthesisLevel = 10 													; bracket level (low byte)
rSaveStack = 11 														; original value of stack pointer

rUtilPC = 12 															; used as P register calling routines (not mandated)
rSubPC = 13																; used as P register to call routines within routines
rParam1 = 14 															; subroutine parameters/return values.
rParam2 = 15

return macro 															; allows subroutine returns to disable/enable interrupts as you want.
	dis 																; this program uses MARK-subroutines
	endm

lrx macro 	r,n 														; load 16 bit value into register macro
	ldi 	(n)/256
	phi 	r
	ldi 	(n)&255
	plo 	r
	endm

; ***************************************************************************************************************
;
;													Start up 1802
;
; ***************************************************************************************************************

	return 																; enable/disable interrupts, switch to R3.
	db 		000h
	ghi 	r0
	phi 	r3
	ldi 	start & 255
	plo 	r3
	sep 	r3

; ***************************************************************************************************************
;
;												Initialisation
;
; ***************************************************************************************************************

start:
	lrx 	r2,0FFFFh 													; find top of memory for stack & vartop.
	sex 	r2 															; this won't work with mirrored memory.
findRAMTop:
	ldi 	05Ah 														; write this and re-read it.
	str 	r2 													
	ldn 	r2	
	xri 	05Ah 														; check the write actually worked.
	bz		foundRAMTop
	ghi 	r2
	smi 	1
	phi 	r2
	br 		findRAMTop 
foundRAMTop:
	ldi 	('*' & 03Fh) * 2 + 1 										; set up rVarPtr.0 so it will point to MSB of RAMTop.
	plo 	rVarPtr
	ghi 	r2 															; use the top page of RAM for the variables + keyboard buffer
	phi 	rVarPtr
	smi 	1 															; and the page below that is the stack.
	phi 	r2
	str 	rVarPtr 													; save in RAMTop MSB
	dec 	rVarPtr
	ldi 	0 															; zero RAMTop LSB
	str 	rVarPtr

	lrx 	rSrc,eString 												; evaluate the string
	lrx 	rExprPC,EXPRevaluate 										; the code
	lrx 	rSpecialHandler,SpecialHandler 								; dummy special handler.
	mark
	sep 	rExprPC
	dec 	r2
wait:
	br 	wait

eString:
	db 		":1)",0
;	db 		"(4*5)-(2*3)*2",0

	align 	256 
	include expression.asm 												; expression evaluator, all arithmetic, atoi/itoa

	align 	256 
	include handler.asm 												; special routine handler.
	include readline.asm 												; line input routine.

	align 	256
	include	virtualio.asm 												; I/O routines that are hardware specific.
