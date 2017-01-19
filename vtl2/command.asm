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
__ECExitDrop1:
	inc 	r2
__ECExit:
	sep 	r3
ExecuteCommand:
	glo  	rParam1 													; copy rParam to rSrc
	plo 	rSrc
	ghi 	rParam1
	phi 	rSrc

	lrx 	rSubPC,__ECRandom 											; call RNG routine and load rExprPC
	mark
	sep 	rSubPC
	dec 	r2

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
	lda 	rSrc 														; fetch ? or $
	stxd 																; save on stack.

__ECSkipEquals2: 														; advance past equals.
	lda 	rSrc
	bz 		__ECExitDrop1
	xri 	'='
	bnz 	__ECSkipEquals2

	lrx 	rSubPC,XIOWriteCharacter 									; prepare for writing

	inc 	r2 															; reload target ($ or ?)
	ldn 	r2
	xri 	'?'															; if ? go to that code
	bz 		__ECWriteIntLiteral
;
;	handle $=nnnn
;
	mark  																; evaluate expression.
	sep 	rExprPC 
	dec 	r2

	glo 	rParam1 													; get the result.
__ECWriteDAndExit:	
	mark 	
	sep 	rSubPC
	dec 	r2															; dec r2 and exit.
	br 		__ECExit 		
;
;	Write  expression or string literal out.
;
__ECWriteIntLiteral:
	lda 	rSrc 														; read first character 
	bz 		__ECExit 													; end of line
	xri 	' ' 														; skip over spaces.
	bz 		__ECWriteIntLiteral 
	xri 	' '!'"'														; quoted string ?
	bnz 	__ECWriteExpression

__ECWriteString:
	lda 	rSrc 														; get next
	bz 		__ECExit 													; exit if NULL
	xri 	'"'															; if '"' check closing semicolon.
	bz 		__ECCheckSemicolon
	xri 	'"'															; get original value back.
	mark 																; output the character
	sep 	rSubPC
	dec 	r2
	br 		__ECWriteString

__ECWriteExpression:
	dec 	rSrc 														; unpick the read of first character
	mark 	 															; evaluate expression to rParam1
	sep 	rExprPC
	dec 	r2

	ghi 	rVarPtr 													; make rParam2 (buffer pointer) at end of input buffer
	phi 	rParam2
	ldi 	0FFh
	plo 	rParam2 
	lrx 	rUtilPC,IntegertoASCII 										; convert to ASCII, rParam2 points to it.
	mark
	sep 	rUtilPC
	dec 	r2
	lrx 	rSubPC,XIOWriteCharacter 									; prepare for writing

__ECWriteEx2:															; write the number out.
	lda 	rParam2
	bz 		__ECCheckSemicolon
	mark
	sep 	rSubPC
	dec 	r2
	br 		__ECWriteEx2


__ECCheckSemicolon:
	lda 	rSrc 														; look at next character
	bz 		__ECCRLF 													; if EOL do a CR
	xri 	' ' 														; skip spaces
	bz 		__ECCheckSemicolon 
	xri 	' '!';'														; if semicolon
	bz 		__ECExit 													; exit now.
__ECCRLF:	
	ldi 	13 															; else output CRLF
	br 		__ECWriteDAndExit
;
;	Update random number and load rExprPC
;

__ECRandom:
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
	lrx 	rExprPC,EXPREvaluate 										; this is re-entrant throughout
	sex 	r2
	inc 	r2
	return
