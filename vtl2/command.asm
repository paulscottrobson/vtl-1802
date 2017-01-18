; ***************************************************************************************************************
; ***************************************************************************************************************
;
;		File:		command.asm
;		Purpose:	Execute a single command
;		Author:		Paul Robson (paul@robsons.org.uk)
;		Date:		18th January 2017.
;
; ***************************************************************************************************************
; ***************************************************************************************************************

; ***************************************************************************************************************
;
;											Execute command in rParam1. 
;
;	Side effects : # (goto, change rCurrentPC and '!') $ (char out) ? (number/literal out) :<expr>) array
; 	handler.
;
; ***************************************************************************************************************

__ECExitDrop2:
	inc 	r2
	inc 	r2
__ECExit:
	sep 	r3
ExecuteCommand:
	glo  	rParam1 													; copy rParam to rSrc
	plo 	rSrc
	ghi 	rParam1
	phi 	rSrc

	lrx 	rExprPC,EXPREvaluate 										; this is re-entrant throughout
	ldi 	(39 & 03Fh) * 2 + 1 										; point rVarPtr to the random number MSB (39 is single quote)
	plo 	rVarPtr
	ldn 	rVarPtr 													; read MSB
	shr 																; shift right and save.
	str 	rVarPtr
	dec 	rVarPtr
	ldn 	rVarPtr 													; rotate into LSB
	rshr 
	str 	rVarPtr
	bnf 	__ECNoXor
	inc 	rVarPtr 													; xor the MSB with $B4 is LSB was one.
	ldn 	rVarPtr
	xri 	0B4h
	str 	rVarPtr
__ECNoXor:

	ldn 	rSrc 														; look at command first character
	xri 	')'															; exit if comment
	bz 		__ECExit
	xri 	')'!':'														; check for array.
	bz 		__ECArray
	xri 	':'!'$'
	bz 		__ECOutput
	xri 	'$'!'?' 													; if $ or ? go to the output routine.
	bz 		__ECOutput

	lda 	rSrc 														; read variable ptr and skip over it.
	plo 	rParam1 													; save it temporarily.
	adi 	256-'a' 													; a+ will generate DF
	bnf 	__ECNotLower
	smi 	32
__ECNotLower:	
	smi 	256-'a'
	ani 	3Fh 														; six bit ASCII
	shl 																; 2 bytes per variable
	stxd 																; save on stack.
	ghi 	rVarPtr 													; push high byte of variable address on stack
	stxd 

__ECSkipEquals: 														; advance past equals.
	lda 	rSrc
	bz 		__ECExitDrop2
	xri 	'='
	bnz 	__ECSkipEquals

	glo 	rParam1 													; was it '#' that has a special handler
	xri 	'#'
	bz 		__ECGoto 

	mark  																; evaluate expression.
	sep 	rExprPC 


	lda 	r2 															; read save address MSB (we can miss dec r2/inc r2 after mark.)
	phi 	rParam2
	ldn 	r2
	plo 	rParam2

	glo 	rParam1 													; write result out.
	str 	rParam2
	ghi 	rParam1
	inc 	rParam2
	str 	rParam2
	br 		__ECExit

; ***************************************************************************************************************
;
;												Handle #=xxxx (goto)
;
; ***************************************************************************************************************

__ECGoto:
	inc 	r2 															; throw save address, we know where it is
	inc 	r2

	mark  																; evaluate expression.
	sep 	rExprPC 
	dec 	r2

	glo 	rParam1 													; if result is zero do nothing
	bnz 	__ECGotoNonZero
	ghi 	rParam1
	bz 		__ECExit
__ECGotoNonZero:

	ldi 	('#' & 03Fh) * 2 											; point rVarPtr to current line.
	plo 	rVarPtr

	ldn 	rVarPtr 													; read old to rParam2, save new 
	plo 	rParam2
	glo 	rParam1
	str 	rVarPtr

	inc 	rVarPtr 													; read old to rParam2, save new
	ldn 	rVarPtr
	phi 	rParam2
	ghi 	rParam1
	str 	rVarPtr

	inc 	rParam2 													; add 1 to old line number
	ldi 	('!' & 03Fh) * 2 											; write to '!'
	plo 	rVarPtr
	glo 	rParam2
	str 	rVarPtr
	inc 	rVarPtr
	ghi 	rParam2
	str 	rVarPtr

	glo 	rParam1 													; put line number in rParam2
	plo 	rParam2
	ghi 	rParam1
	phi 	rParam2
	lrx 	rUtilPC,LocateLine 											; find out where the line is.
	mark
	sep 	rUtilPC
	dec 	r2
	glo 	rParam2 													; copy result to rCurrentLine
	plo 	rCurrentLine
	ghi 	rParam2
	phi 	rCurrentLine
	br 		__ECExit 

; ***************************************************************************************************************
;
;										Handle :<array>) = nnnn
;
; ***************************************************************************************************************

__ECArray:
	inc 	rSrc 														; skip over the :
	mark  																; evaluate expression into rParam1 which is the array index
	sep 	rExprPC 
	dec 	r2 															; fix up afterwards

	glo 	rParam1 													; double the array index.
	shl
	plo 	rParam1
	ghi 	rParam1
	rshl
	phi 	rParam1

	ldi 	('&' & 03Fh) * 2 											; point rVarPtr to &
	plo 	rVarPtr
	sex 	rVarPtr 													; use as index.

	glo 	rParam1 													; add to '*' and push on stack
	add
	str 	r2
	dec 	r2
	ghi 	rParam1
	inc 	rVarPtr
	adc
	sex 	r2
	stxd
	br 		__ECSkipEquals 												; and continue as if variable assignment.

; ***************************************************************************************************************
;
;												Handle ?= and $=
;
; ***************************************************************************************************************

__ECOutput:
	br 		__ECOutput

