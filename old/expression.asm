; ***************************************************************************************************************
; ***************************************************************************************************************
;
;		File:		expression.asm
;		Purpose:	16 bit expression evaluator
;		Author:		Paul Robson (paul@robsons.org.uk)
;		Date:		8th January 2017.
;
; ***************************************************************************************************************
; ***************************************************************************************************************
;
;	There's room for about 100 bytes preceding this in the page. I'd put it in page 0 with
;	startup and utility functions, but it isn't mandatory.
;
;	Note: Errors are ignored in VTL-2.
;
; ***************************************************************************************************************

doubleRValue macro 												; double 16 bit value in rValue.
	glo 	rRValue
	shl
	plo 	rRValue
	ghi 	rRValue
	rshl
	phi 	rRValue
	endm


EXPRPageAddress:

; ***************************************************************************************************************
;
;		Exit. We restore the stack because we don't know if/where we have crashed out - there is no
;		error reporting at all. Then we get whatever the value on the stack was. If it worked right
;		this is the expression value. If not, it will probably be 0.
;
; ***************************************************************************************************************

EXPRExit:
	glo 	rStackSave 											; restore the stack
	plo 	r2
	ghi 	rStackSave
	phi 	r2
	dec 	r2 													; look at value on TOS.
	dec 	r2
	lda 	r2 													; LSB
	plo 	rResult
	lda 	r2 													; MSB and pointing at MARK data
	phi 	rResult
	ret 														; and return.

; ***************************************************************************************************************
;
;								Evaluate expression code starts here
;
; ***************************************************************************************************************

EXPRession:
	glo 	r2 													; copy the stack start value to end value.
	plo 	rStackSave
	ghi 	r2
	phi 	rStackSave

	ldi 	0  													; clear the parenthesis depth.
	plo 	rParenDepth 	

__EXPRNewExpression:
	dec 	r2 													; push two 00 on the stack.
	stxd
	stxd
	ldi 	'+' 												; push '+' on the stack.
	str 	r2

; ***************************************************************************************************************
;
;	Main loop. We have something on the stack (initially 0+) and are looking for a term to push on, which
;	could be a variable, could be an integer constant or a side-effect variable (? or $)
;
; ***************************************************************************************************************

__EXPRLoop: 													; main expression loop. looking for a term.

	lda 	rExpression 										; get the next character
	bz 		EXPRexit 											; if NULL then exit
	phi 	rTemp 												; save in rTemp.1
	xri 	' '													; skip spaces
	bz 		__EXPRLoop

	xri 	' '!'"'												; check for quote mark.
	bz 		__EXPRCharacter

	inc 	rParenDepth 										; inc parenthesis depth for ( and :
	xri 	'"'!'('												; is it an open parenthesis ?
	bz 		__EXPRNewExpression 								; if so, do a new expression with parenthesis bumped.
	ghi 	rTemp												; get character read.
	adi 	256-':'												; check for :
	bz 		__EXPRTermIsArray 									; if so, it is an array.
	dec 	rParenDepth 								

	bdf 	__EXPRTermIsVariable 								; if after : then it is a variable.
	adi 	10  												; checks 0-9 (colon follows 9)
	bnf 	__EXPRTermIsVariable 								; if before 0 then it is a variable.

; ***************************************************************************************************************
;
;											Reading in an unsigned integer.
;
; ***************************************************************************************************************

	plo 	rRValue 											; first digit of a integer rValue
	ldi 	0
	phi 	rRValue
__EXPRIntegerLoop:
	ldn 	rExpression  										; read next character
	bz 		EXPRExit	
	adi 	256-':'												; check it is an integer.
	bdf		__EXPRPendingArithmetic 
	adi 	10
	bnf 	__EXPRPendingArithmetic 	

	inc 	rExpression 										; skip over new character
	dec 	r2 													; put new digit value on the stack
	stxd
	ghi 	rRValue 											; put rValue on the stack (lo/hi)
	stxd
	glo 	rRValue
	str 	r2

	doubleRValue 												; double the rValue twice
	doubleRValue
	glo 	rRValue 											; add the saved value
	add 
	plo 	rRValue
	inc 	r2
	ghi 	rRValue
	adc
	phi 	rRValue
	inc 	r2 													; now points to the new digit.
	doubleRValue 												; double rValue again (now x 10)

	glo 	rRValue 											; add the new digit in with carry
	add
	plo 	rRValue
	ghi 	rRValue
	adci 	0
	phi 	rRValue
	inc 	r2 													; throw the new digit
	br 		__EXPRIntegerLoop 									; and try the next character

; ***************************************************************************************************************
;
;											Found a character
;
; ***************************************************************************************************************

__EXPRCharacter:
	lda 	rExpression 										; get next character (after ") and bump.
	bz 		EXPRExit 											; none provided
	plo 	rRValue 											; put into rRValue
	ldi 	0 													; clear high byte
	phi 	rRValue
	lda 	rExpression 										; get closing quote
	bz 		EXPRExit 											; none provided, we don't error check in VTL
	br 		__EXPRPendingArithmetic 

; ***************************************************************************************************************
;
;	Found an array (e.g. :<expr>) ). This is treated as an extra level of parenthesis, but the final
;	operator is 0@ not 0+ at the start, when evaluated this does the memory read.
;
; ***************************************************************************************************************

__EXPRTermIsArray:
	ldi 	'@' 												; push <dummy value> @ on the stack (array operator)
	dec 	r2
	stxd
	stxd
	str 	r2
	br 		__EXPRLoop

; ***************************************************************************************************************
;
;							Found a variable - this is actually anything except  0-9 ( and :
;
; ***************************************************************************************************************

__EXPRTermIsVariable:
	ghi 	rTemp 												; check for special cases ($ and ?) on RHS
	xri 	'$'													; which are input.
	bz 		__EXPRSpecialVariable
	xri 	'$'!'?'
	bz 		__EXPRSpecialVariable 

	ghi 	rTemp 												; ASCII value of variable x 2
	shl 
	plo 	rVarPtr 											; point to variable

	lda 	rVarPtr 											; copy variable into rValue
	plo 	rRValue
	ldn 	rVarPtr
	phi 	rRValue
	br 		__EXPRPendingArithmetic 							; and now have term.

; ***************************************************************************************************************
;
;	Call the 'special variables' routine. Should put the value required into 'rRValue'
;
; ***************************************************************************************************************

__EXPRSpecialVariable:
	ldi 	SpecialVariableHandler/256 							; prepare to call the SVHandler routine.
	phi 	rTemp
	ldi 	SpecialVariableHandler&255
	plo 	rTemp 												; prepare for return
	dec 	rExpression
	lda 	rExpression
	dec 	r2
	mark 		
	sep 	rTemp 												; call the SVHandler, then fall through to pending sum.

; ***************************************************************************************************************
;
;	We now have <lterm> <op>  on the stack and the rValue in rRValue, so this does that stacked operation.
;
;	operations are * / + - > < = and @ (the array index psuedo op, internal only)
;
;	This code is in page 2.
;
; ***************************************************************************************************************

	org 	(EXPRPageAddress/256)*256+100h-1

__EXPRPendingArithmetic:
	lda 	r2 													; get the pending operator off the stack.
	phi 	rTemp 												; save in rTemp.1
	xri 	'+'
	bnz 	__EXPRPANotAdd
;
;	Addition
;
	glo 	rRValue 											; Add.
	add
	str 	r2
	inc 	r2
	ghi 	rRValue
	adc
	stxd
	br 		__EXPRNextOperator

__EXPRPANotAdd:
	xri 	'+'!'*'
	bnz 	__EXPRPANotMultiply
;
;	Multiplication
;
	include multiply.asm 										; Multiply
	br 		__EXPRNextOperator
__EXPRPANotMultiply:

	xri 	'*'!'/'
	bnz 	__EXPRNotDivide
;
;	Division (with remainder)
;
	include divide.asm 											; Divide.

	ldi 	'%' * 2 											; Make rVarPtr point to remainder variable.
	plo 	rVarPtr	
	glo 	rRemainder 											; write division remainder out there.
	str 	rVarPtr
	inc 	rVarPtr
	ghi 	rRemainder
	str 	rVarPtr
	br 		__EXPRNextOperator

__EXPRNotDivide:
	xri 	'/'!'@'
	bnz 	__EXPRNotArray 										; Array access
;
;	Index Access a @ b (b * 2 + memtop read, e.g. array access)
;
	doubleRValue 												; x array index by two as word access
	ldi 	'*'*2 												; point rVarPtr to '*' (end of memory)
	plo 	rVarPtr

	sex 	rVarPtr 											; use that as index, briefly.
	glo 	rRValue 											; add to the doubled index, into rRValue.
	add
	plo 	rRValue
	inc 	rVarPtr
	ghi 	rRValue
	adc
	phi 	rRValue
	sex 	r2 													; X back to stack.

	lda 	rRValue 											; get LSB
	str 	r2
	inc 	r2
	ldn 	rRValue 											; get MSB
	str 	r2
	dec 	r2
	br 		__EXPRNextOperator

__EXPRNotArray:													; so we know it is not + * / @ it must be - = < >
;
;	do subtract whatever - works for - = < >
;
	glo 	rRValue 											; subtract rRValue from TOS.
	sd
	str 	r2
	inc 	r2
	ghi 	rRValue
	sdb
	stxd

	ghi 	rTemp 												; get operator.
	xri 	'-'													; if subtract, we are done.
	bz 		__EXPRNextOperator
	xri 	'='!'-'
	bnz 	__EXPRConditional
;
;	Equality test.
;
	lda 	r2 													; is now 0 if equal, nonzero if different
	or  														; (e.g. result of subtraction <> 0)
	dec 	r2 													; fix up SP
	bz 		__EXPREqual2 
	ldi 	1
__EXPREqual2: 													; now 0 if equal, 1 if different.	
	xri 	1 													; now 1 if equal, 0 if different
	br 		__EXPRSetBoolean 									; use that to set the boolean result.
;
;	Conditional tests < and > (note > is actually >=) and anything unrecognised is >=
;
;	At this point DF = 1 if >= 
;
__EXPRConditional:
	ghi 	rTemp 												; get the conditional.
	xri 	'<' 												; zero if < anything else non-zero.
	bz 		__EXPRConditional2
	ldi 	1
__EXPRConditional2:												; zero if < ; one if >= (default operator)
	adci 	0 													; add in DF. zero if < and true; two if >= and true
	ani 	1 													; now 0 if true, 1 if false
	xri 	1 													; now 1 if true, 0 if false
__EXPRSetBoolean:	
	str 	r2													; write 0/1 out.
	inc 	r2
	ldi 	0 													; write MSB
	stxd	

; ***************************************************************************************************************
;
;					Having done a pending operator, we now look at the next operator.
;
; ***************************************************************************************************************

__EXPRNextOperator:	
	ldi 	4
	br 		__EXPRJumpPage1

st:	br		st

__EXPRJumpPage1:								
;
;	Code to jump to offset D in page 1 of expression......
;
w1:	br 		w1


SpecialVariableHandler:
	ret


;
; get the next operator and handle 0
; push operator and loop back.
; handle ) and unstacking
;
