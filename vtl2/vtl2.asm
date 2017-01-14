; ***************************************************************************************************************
; ***************************************************************************************************************
;
;		File:		vtl2.asm
;		Purpose:	Main Program.
;		Author:		Paul Robson (paul@robsons.org.uk)
;		Date:		14th January 2017.
;
; ***************************************************************************************************************
; ***************************************************************************************************************

	cpu 	1802 														; obviously !
	
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
	lrx 	r3,Initialise 												; jump to start.
	sep 	r3

	include expression.asm 												; expression evaluator, all arithmetic, atoi/itoa

	align 	256 
	include handler.asm 												; special routine handler.
	include readline.asm 												; line input routine.

	align 	256

; ***************************************************************************************************************
;
;												Initialisation
;
; ***************************************************************************************************************

Initialise:
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

	ldi 	('&' & 03Fh) * 2  											; set program pointer ; optional ?
	plo 	rVarPtr
	ldi 	(ProgramCode & 255)
	str 	rVarPtr
	inc 	rVarPtr
	ldi 	(ProgramCode / 256)
	str 	rVarPtr

; ***************************************************************************************************************
;
;										OK Prompt (Come here after CMD exec, or #=0)
;
; ***************************************************************************************************************

Prompt:
	lrx 	rUtilPC,__PrintString 										; print Prompt
	lrx 	rParam2,__Prompt
	sep 	rUtilPC

	ldi 	('#' & 03Fh) * 2 											; # = 0
	plo 	rVarPtr
	ldi 	0
	str 	rVarPtr
	inc 	rVarPtr
	str 	rVarPtr
	lrx 	rSpecialHandler,SpecialHandler 								; initialise 'special handler' vector.

; ***************************************************************************************************************
;
;							Read line loop (come back here if modifying program)
;
; ***************************************************************************************************************

EnterCommand:
	lrx 	rUtilPC,READLine 											; input a new line.
	mark
	sep 	rUtilPC
	dec 	r2
	lrx 	rUtilPC,ASCIIToInteger 										; see if there is a number up front
	mark
	sep 	rUtilPC
	dec 	r2 															; if there is it will be in rParam2 and D # 0, rParam1 points to first non-space
	bz 		Execute 													; if D = 0, it is text, so execute the command in rParam1.

	glo 	rParam2 													; if rParam2 is non zero, then go to edit
	bnz 	Edit 														; if zero (e.g. typed line number zero) this is actually list.
	ghi 	rParam2
	bnz 	Edit

; ***************************************************************************************************************
;
;												Program Listing
;
; ***************************************************************************************************************

ListProgram:
	ldi 	('&' & 03Fh) * 2  											; point to & (program area)
	plo 	rVarPtr
	lda 	rVarPtr 													; read & into rSrc ready for listing.
	plo 	rSrc
	ldn 	rVarPtr
	phi 	rSrc
__ListLoop:
	lda 	rSrc 														; read the offset link, which we don't use as a step
	bz 		Prompt 														; if the link is zero, we have reached the end of the program.

	lda 	rSrc 														; read line number into rParam1
	plo 	rParam1 													
	lda 	rSrc
	phi 	rParam1 													

	ghi 	rVarPtr 													; use keyboard buffer for conversion
	phi 	rParam2
	ldi 	0FFh
	plo 	rParam2
	lrx 	rUtilPC,IntegerToASCII 										; and convert it to ASCII
	mark 	
	sep 	rUtilPC

	lrx 	rUtilPC,__PrintString 										; print it.
	sep 	rUtilPC

	ldi 	' '															; print a space - note this takes advantage of __PrintString
	mark 																; loading rSubPC with the XIOWriteCharacter() routine.
	sep 	rSubPC
	dec 	r2

	glo 	rSrc 														; put rSrc -> rParam2 and print that.
	plo 	rParam2
	ghi 	rSrc
	phi 	rParam2
	sep 	rUtilPC

	ldi 	13 															; same trick to print CR as above
	mark
	sep 	rSubPC
	dec 	r2

__ListNext: 															; advance pointer forward and do next.
	lda 	rSrc
	bnz 	__ListNext
	br 		__ListLoop

; ***************************************************************************************************************
;
;			Print String at rParam2 (ASCIIZ) , on exit leaves rSubPC set up to print a character
;
; ***************************************************************************************************************

	sep 	r3
__PrintString:
	lrx 	rSubPC,XIOWriteCharacter 									; print character routine
	lda 	rParam2
	bz 		__PrintString-1
	mark
	sep 	rSubPC
	br 		__PrintString

__Prompt: 																; VTL-2 Prompt.
	db 		"OK",13,0

; ***************************************************************************************************************
;
;									Edit Line rParam2, new text in rParam1
;
; ***************************************************************************************************************

Edit: 																	; edit line - number in rParam2, new text in rParam1.
	br 	Edit


Execute:
	; do it. look for side effects, #=n goes into a different routine which runs code.
	br 	Execute



RunMode:
	br 		RunMode


	align 	256
	include	virtualio.asm 												; I/O routines that are hardware specific.


; ***************************************************************************************************************
;
;												VTL-2 Code, test 
;
; ***************************************************************************************************************


vtl macro line,code 													; creating VTL-2 code in line.
startLine:
	db 		endLine-startLine 											; +0 offset to next
	db 		line & 255,line / 256 										; +1,+2 line number
	db 		code,0 														; ASCIIZ line.
endLine:	
	endm

ProgramCode:
	vtl 	10,"A=42) this is a comment"
	vtl 	20,"#=?"		
	vtl 	30,"?=A"
	db 		0