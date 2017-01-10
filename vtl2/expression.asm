
__EXPRExitDec:
	dec 	rSrc 
__EXPRExit:
	inc 	r2
	lda 	r2
	plo 	rParam1
	lda 	r2
	phi 	rParam1
	return

EXPREvaluate:
	sex 	r2 															; using X = 2 again
	ldi 	-1 															; clear parenthesis level to -1 (first increment)
	plo 	rParenthesisLevel 
	ldi 	UtilityPage/256  											; set Utility Page.1
	phi 	rUtilPC 
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
	sep 	rExprPC 													; check for 'special ones'
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
	ldr 	rParam1,__OperatorTable-1 									; rParam1 is the operator look up table.
__EXPRFindOperation:
	inc 	rParam1
	lda 	rParam1 													; look to see what it is.
	bz 		__EXPRFoundOperation 										; end of table.
	xor 																; same as stacked operator
	bnz 	__EXPRFindOperation 
__EXPRFoundOperation:	
	lda 	r2 															; load the stacked value into rParenthesisLevel.1
	phi 	rParenthesisLevel
	ldn 	rParam1 													; put address of routine into rUtilPC
	plo 	rUtilPC
	lda 	r2 			
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


__EXPRDestackBracket:
	; pop rParam2 off the stack.
	; adjust and test the parenthesis level counter. ) comment
	; go back to the got-term
	; maybe have 2 byte addresses for operator functions.
	br 		__EXPRDestackBracket	

