; ***************************************************************************************************************
; ***************************************************************************************************************
;
;		File:		editing.asm
;		Purpose:	Line editing/finding functionality.
;		Author:		Paul Robson (paul@robsons.org.uk)
;		Date:		14th January 2017.
;
; ***************************************************************************************************************
; ***************************************************************************************************************

; ***************************************************************************************************************
;
;	Find line number, return pointer to it in rParam2, return DF = 1 if exact match. DF = 0 if just next one.
;	So if lines are 10,20,30 25 will be ^30 and DF = 0, 20 will be ^20 and DF = 1
;
; ***************************************************************************************************************

LocateLine:
	sex 	r2 															; save the target on the stack.
	dec 	r2
	ghi 	rParam2
	stxd
	glo 	rParam2
	str 	r2

	lrx 	rParam2,ProgramStart  										; read base of program into rParam2
	
__LLSearch:
	ldn 	rParam2 													; look at the link.	
	adi 	255 														; DF will be zero if the link was zero, any +ve sets it.
	bnf 	__LLExit

	inc 	rParam2 													; point to line number.0
	lda 	rParam2 													; calculate current - required
	sm 
	plo 	rVarPtr 													; save interim value in rVarPtr.0
	inc 	r2 													
	ldn 	rParam2 											
	smb 
	dec 	r2
	bdf 	__LLFound 													; if DF set is >= so this is the find point.

	dec 	rParam2 													; point rParam2 back to the offset address
	dec 	rParam2
	ldn 	rParam2 													; read offset
	dec 	r2 															; save on stack.
	str 	r2 												
	glo 	rParam2 													; add to position.
	add
	plo 	rParam2
	ghi 	rParam2
	adci 	0
	phi 	rParam2
	inc 	r2 															; drop stacked value.
	br 		__LLSearch 													; and go to the next one.

__LLFound: 																; found answer, DF set. 
	dec 	rParam2 													; point back to the link.
	dec 	rParam2
	adi 	0 															; clear DF.
	bnz 	__LLExit 													; if results non-zero return DF = 0
	glo 	rVarPtr 													
	bnz 	__LLExit 
	sdi 	0 															; set DF

__LLExit:
	inc 	r2 															; throw stacked values.
	inc 	r2
	inc 	r2 															; return from subroutine.
	return 

; ***************************************************************************************************************
;
;				Delete program line at rParam2 (address), breaks rSubPC, rParenthesisLevel
;
; ***************************************************************************************************************

DeleteLine:
	sex 	rParam2 													; (X) is the offset

	glo 	rParam2 
	plo 	rParenthesisLevel
	add
	plo 	rSubPC 														; copy from rSubPC to rParenthesisLevel
	ghi 	rParam2
	phi 	rParenthesisLevel
	adci 	0
	phi 	rSubPC

	ldi 	('&' & 03Fh) * 2 											; point rVarPtr to the end of memory.
	plo 	rVarPtr
	sex 	rVarPtr

	dec 	rSubPC
	dec 	rParenthesisLevel
__DeleteLoop:
	inc 	rParenthesisLevel 											; copy one byte over.
	inc 	rSubPC
	ldn 	rSubPC
	str 	rParenthesisLevel
	ldi 	0 															; clear newly cleared memory (not really required)
	str 	rSubPC
	glo 	rSubPC 														; loop back if not at end
	xor
	bnz 	__DeleteLoop
	inc 	rVarPtr
	ghi 	rSubPC 														; source reached program top ?
	xor
	dec 	rVarPtr
	bnz 	__DeleteLoop 												

	glo 	rParenthesisLevel 											; update top of program.
	str 	rVarPtr
	inc 	rVarPtr
	ghi 	rParenthesisLevel
	str 	rVarPtr

	sex 	r2
	inc 	r2
	return	
