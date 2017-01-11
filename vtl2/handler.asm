; ***************************************************************************************************************
; ***************************************************************************************************************
;
;		File:		handler.asm
;		Purpose:	Handle side-effect variables on read.
;		Author:		Paul Robson (paul@robsons.org.uk)
;		Date:		11th January 2017.
;
; ***************************************************************************************************************
; ***************************************************************************************************************

; ***************************************************************************************************************
;
;		This routine provides the variable in D. On exit, if D = 0 the "variable" has been accessed and
;		put in rParam2.
;
;		The right hand variables with side effects in VTL-2 are :-
;
;		?	input an expression (we will probably do integer here.)
; 		$ 	input a single character
;
; ***************************************************************************************************************

SpecialHandler:
	xri 	'?'
	bz 		__SHGetKey
	sep 	rExprPC

__SHGetKey:
	inp 	1
	bz 		__SHGetKey
	plo 	rParam2
	ldi 	0
	phi 	rParam2
	sep 	rExprPC	

