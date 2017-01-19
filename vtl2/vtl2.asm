; ***************************************************************************************************************
; ***************************************************************************************************************
;
;		File:		vtl2.asm
;		Purpose:	Main Program.
;		Author:		Paul Robson (paul@robsons.org.uk)
;					Based on Frank McCoy's documentation for the 6800 version.
;		Date:		14th January 2017.
;
; ***************************************************************************************************************
; ***************************************************************************************************************

	cpu 	1802 														; obviously !
	
r0 = 0 																	; not used (may be used in interrupt display)
r1 = 1 																	; not used (interrupt register)
r2 = 2 																	; stack pointer
r3 = 3 																	; general run P
rExecutePC = 4 															; execute commands using R4. (param1 = code to execute)
rCurrentLine = 5 														; current line pointer.
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

	ldi 	('&' & 03Fh) * 2  											; set program end pointer (&)
	plo 	rVarPtr
	ldi 	(ProgramEnd & 255)
	str 	rVarPtr
	inc 	rVarPtr
	ldi 	(ProgramEnd / 256)
	str 	rVarPtr

	ldi 	(39 & 03Fh) * 2 											; initialise RNG
	plo 	rVarPtr
	str 	rVarPtr

; ***************************************************************************************************************
;
;						OK Prompt (Come here after CMD exec, or program halted) also clears #
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

	lrx 	rSrc,ProgramStart 											; point rSrc to the start of the program
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
	dec 	r2

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
;									Edit Line rParam2, new text in rParam1
;
; ***************************************************************************************************************

Edit: 																	; edit line - number in rParam2, new text in rParam1.
	glo 	rParam2 													; save line number in rSrc
	plo 	rSrc
	ghi 	rParam2
	phi 	rSrc
	lrx 	rUtilPC,LocateLine 											; find the line.
	mark 
	sep 	rUtilPC
	dec 	r2
	bnf 	__DontDelete 												; if DF = 0 not found line to delete.

	lrx 	rUtilPC,DeleteLine 											; Delete line (address in rParam2)
	mark 
	sep 	rUtilPC
	dec 	r2

__DontDelete:
	ldn 	rParam1  													; look at first not space character
	bz 		EnterCommand 												; if zero, it's delete only.

	lrx 	rUtilPC,InsertLine 											; Insert the new line
	mark 
	sep 	rUtilPC
	dec 	r2
	br 		EnterCommand

; ***************************************************************************************************************
;	
;										Execute line in rParam1
;
; ***************************************************************************************************************

Execute:
	ldn 	rParam1 													; read first character
	bz 		EnterCommand 												; blank line, do nothing
	lrx 	rExecutePC,ExecuteCommand 									; execute command in P1.
	sep 	rExecutePC 

	ldi 	('#' & 03Fh) * 2 											; look at '#'
	plo 	rVarPtr
	lda 	rVarPtr 													; if non zero go to run code.
	bnz 	RunProgram
	ldn 	rVarPtr 	
	bz 		Prompt  													; if zero, loop back, displaying "OK"

; ***************************************************************************************************************
;
;													In Run Mode.
;
; ***************************************************************************************************************

RunProgram:
	ldn		rCurrentLine 												; if current offset = 0 (end of program) then exit to prompt
	str 	r2 															; save at TOS.
	bz 		Prompt
	glo 	rCurrentLine 												; copy current line into rParam1
	plo 	rParam1
	ghi 	rCurrentLine
	phi 	rParam1

	glo 	rCurrentLine 												; set currentPC to point to next line.
	add  																; done here so the Execute Routine can update it if it wants.
	plo 	rCurrentLine
	ghi 	rCurrentLine
	adci 	0
	phi 	rCurrentLine

	ldi 	('#' & 03Fh) * 2 											; set rVarPtr to point to current line number
	plo 	rVarPtr
	inc 	rParam1 													; skip over offset
	lda 	rParam1 													; read line# low
	str 	rVarPtr 													; copy to # low
	lda 	rParam1 													; read line# high
	inc 	rVarPtr 													; copy to # high
	str 	rVarPtr 	 												; now points to first byte of command.

	sep 	rExecutePC 													; and execute it.
	br 		RunProgram


	align 	256
	include expression.asm 												; expression evaluator, all arithmetic, atoi/itoa
	align 	256 
	include handler.asm 												; special routine handler.
	include editing.asm 												; line editing code	
__Prompt: 																; VTL-2 Prompt.
	db 		"OK",13,0
	align 	256
	include command.asm 												; command execution code (slightly more than one page)
	include readline.asm 												; line input routine.

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

ProgramStart:
	vtl 10,"A=0"
	vtl 20,"B=1"
	vtl 30,"?=A"
	vtl 40,"?=\" factorial is \";"
	vtl 50,"?=B"
	vtl 60,"?=\"\""
	vtl 70,"A=A+1"
	vtl 80,"B=B*A"
	vtl 90,"#=A<9*30"	
ProgramEnd:	
	db 		0

;
;	Things that don't work:
;
;	(1) You can't assign to & (set correctly by default)
; 	(2) You can't enter expressions in input, only numbers (using A=?)
;	(3) The backspace is the backspace key and displays as ^H in the emulator and is chr(8)
;	(4) Erroneous expressions may return different values compared to other versions.
;
;	Code checked as far as "Hurkle" in the VTL-2 manual.
;
