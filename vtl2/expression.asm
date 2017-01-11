; ***************************************************************************************************************
; ***************************************************************************************************************
;
;		File:		expression.asm
;		Purpose:	Evaluate an ASCII expression.
;		Author:		Paul Robson (paul@robsons.org.uk)
;		Date:		11th January 2017.
;
; ***************************************************************************************************************
; ***************************************************************************************************************

; ***************************************************************************************************************
;
;	Expression Evaluator : L -> R evaluation with parenthesis.
;
;	rSrc 			points to ASCIIZ expression, next character on exit. 
;	rExprPC 		runs in this R(P), this is mandatory.
;	rVarPtr.1 		points to variables
; 	rParam1 		returned value of expression.
;	rSpecialHandler	Routine (ends with sep rExprPC) which processes the provided character for special values
;					e.g. side effect variables like ?. Char in D, zeroes D if the character is found and processed,
;					in which case the result should be in rParam2
;
;	This does not report errors. VTL-2 does not. So if you have an error then the result returned may be somewhat
;	unexpected and should not be relied on, despite what the VTL-2 manual hints :)
;
;	Note this routine breaks most of the registers R6-R15. If this is called recursively it must still run in
;	rExprPC and the original rExprPC,rSrc,rParenthesisLevel and rSaveStack must be saved. rVarPtr does not change
;	but must be restored if changed by an external routine.
;
;	This is a long single function of 170 bytes or thereabouts. The add/sub/lookup routines and lookup table towards
;	the end can be moved to other pages if required ; it doesn't matter where these routines are in memory.
;
; ***************************************************************************************************************

__EXPRExitDec:
	dec 	rSrc 														; unpick bad source gets
__EXPRExit:
	glo 	rSaveStack 													; because we don't handle errors properly we 
	plo 	r2 															; may have incomplete operations on exit.
	ghi 	rSaveStack 													; (VTL-2 does not report expression syntax errors)
	phi 	r2
	dec 	r2 															; load top most expression which is the answer
	lda 	r2 															; if it actually worked.
	plo 	rParam1
	lda 	r2
	phi 	rParam1
	return

EXPREvaluate:
	sex 	r2 															; using X = 2 again
	ldi 	0 															; clear parenthesis level to 0.
	plo 	rParenthesisLevel 

	glo	 	r2 															; save original stack position
	plo 	rSaveStack
	ghi 	r2
	phi 	rSaveStack 

__EXPRNewLevel:	
	ldi 	0 															; push $0000  + on the stack.
	stxd 																; MSB first
	stxd 																; LSB
	ldi 	'+' 												 		; the put '+' on the stack as pending operation.
	stxd
	inc 	rParenthesisLevel 											; bump the parenthesis level up 1.
;
;		On reaching this point, we are looking for a new Term.
;
__EXPRNewTerm:
	glo 	rSrc 														; put rSrc into rParam1
	plo 	rParam1
	ghi 	rSrc
	phi 	rParam1

	ldi 	UtilityPage/256  											; set Utility Page.1
	phi 	rUtilPC 
	ldi 	ASCIIToInteger & 255 										; call the atoi() routine.
	plo 	rUtilPC
	mark
	sep 	rUtilPC
	dec 	r2 		

	adi 	0FFh 														; sets DF if non zero value returned
	glo 	rParam1 													; constant rParam1 back into rSrc
	plo 	rSrc
	ghi 	rParam1
	phi 	rSrc
	bdf 	__EXPRGotTerm 												; if constant then done.

	lda 	rSrc 														; look at character.
	bz 		__EXPRExitDec 												; none provided.
	xri 	'"'															; is it quote mark
	bz 		__EXPRGotCharacter 											; if so do that handler.
	xri	 	'('!'"' 													; is it open parenthesis.
	bz		__EXPRNewLevel 												; if so open new level.
	xri 	':'!'('														; is it new array ?
	bz 		__EXPRArray
	xri 	':' 														; so make it back to the correct character.
	sep 	rSpecialHandler 											; check for 'special ones'
	bz 		__EXPRGotTerm 												; if found one, we've got a term.
	shl 																; byte size to word size
	plo 	rVarPtr 													; now point to variable
	lda 	rVarPtr 													; read LSB into Param2
	plo 	rParam2
	ldn 	rVarPtr 													; and MSB
	phi 	rParam2
	br 		__EXPRGotTerm 
;
;	Found an array : - same as open parenthesis except we stack a '@'
;	
__EXPRArray:
	ldi 	'@' 														; push @@@ on the stack,  the first two don't matter.
	stxd
	stxd
	stxd
	inc 	rParenthesisLevel 											; it's like bracket with a different operator.
	br 		__EXPRNewTerm
;
;	Found a "<char>" 
;
__EXPRGotCharacter:
	phi 	rParam2 													; clear high byte of rParam2.
	lda 	rSrc 														; get character in quotes, skip over it
	bz 		__EXPRExitDec 												; none provided, exit backing up.
	plo 	rParam2 													; put in rParam2.0
	lda 	rSrc 														; look for what should be a quote but we dont check
	bz 		__EXPRExitDec
;
;	New term is in rParam2. Look at the TOS expression to do, look it up and do it.
;
__EXPRGotTerm:  														; new term is in rParam2.
	inc 	r2 															; point stack to operator.
	ldi 	(__OperatorTable-2)/256 									; rParam1 is the operator look up table.
	phi 	rParam1
	ldi 	(__OperatorTable-2)&255
	plo 	rParam1
__EXPRFindOperation:
	inc 	rParam1
	inc 	rParam1
	lda 	rParam1 													; look to see what it is.
	bz 		__EXPRFoundOperation 										; end of table.
	xor 																; same as stacked operator
	bnz 	__EXPRFindOperation 
__EXPRFoundOperation:	
	lda 	r2 															; load the stacked value into rParenthesisLevel.1
	phi 	rParenthesisLevel
	lda 	rParam1 													; put address of routine into rUtilPC
	plo 	rUtilPC
	ldn 	rParam1
	phi 	rUtilPC

	lda 	r2 															; read TOS for into param1
	plo 	rParam1
	ldn 	r2
	phi 	rParam1
	mark  																; and call the routine.
	sep 	rUtilPC
	dec 	r2

;
;	Having got the result, check to see if it was divide, if so write out the remainder to '%'
;
	ghi 	rParenthesisLevel 											; get the operator
	xri 	'/'															; was it divide ?
	bnz 	__EXPRNotDivide
	ldi 	'%' * 2 													; point rVarPtr to % variable
	plo 	rVarPtr
	glo 	rParam2 													; save remainder there
	str 	rVarPtr
	ghi 	rParam2
	inc 	rVarPtr
	str 	rVarPtr
__EXPRNotDivide:	

	ghi 	rParam1 													; push the result back on the stack.
	stxd
	glo 	rParam1
	stxd
;
;	Get the next operation, this is normally stacked, except if ) in which case the bracketed operation is closed
;
__EXPRSkipSpace:
	lda 	rSrc 														; get the next operator.
	bz 		__EXPRExitDec 												; done the next operator.
	xri 	' '
	bz 		__EXPRSkipSpace
	xri 	')'!' '														; was it )
	bz 		__EXPRDestackBracket
	xri 	')' 														; get it back
	stxd 																; push it on the stack.
	br 		__EXPRNewTerm 												; and get the next term.
;
; 	Close the bracketed operation
;
__EXPRDestackBracket:
	dec 	rParenthesisLevel 											; dec brackets
	glo 	rParenthesisLevel 											; if zero it is end of expression ) so exit.	
	bz 		__EXPRExit

	inc 	r2 															; pop rParam2 off the stack.
	lda 	r2
	plo 	rParam2
	ldn 	r2
	phi 	rParam2

	br 		__EXPRGotTerm 												; go back and do the stacked operation below

; ***************************************************************************************************************
;
;	Look up table for binary operators. 0 signifies the end of the table and default, so it covers - > < =
;
; ***************************************************************************************************************

oper macro chdb,addr
	db 		chdb,addr & 255,addr / 256
	endm 

__OperatorTable:
	oper 		'+',__OpAdd 
	oper		'*',Multiply
	oper 		'/',Divide
	oper 		'@',__OpLookUp 
	oper 		0,__OpSub

; ***************************************************************************************************************
;
;								Addition. rParam1 := rParam1 + rParam2
;
; ***************************************************************************************************************

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

; ***************************************************************************************************************
;
;				Array Lookup. rParam1 := Memory['*' + rParam * 2]. '*' is the top of memory variable.
;
; ***************************************************************************************************************

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

; ***************************************************************************************************************
;
;								Subtraction. rParam1 := rParam1 - rParam2
;									 (Also > < = which return 0 or 1)
;
; ***************************************************************************************************************

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
