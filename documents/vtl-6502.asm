;234567890123456789012345678901234567890123456789012345
	.lf  vtl02a1.lst	
	.cr  6502	
	.tf  vtl02a1.obj,ap1
;------------------------------------------------------
; VTL-2 for the 6502 (VTL02)
; Original Altair 680b version by
;   Frank McCoy and Gary Shannon 1977
; Adapted to the 6502 by Michael T. Barry 2012
; Thanks to sbprojects.com for a very nice assembler!
; Notes concerning this version:
;   {&} and {*} are initialized on entry.
;   Division by zero returns a quotient of 65535 (the
;     original 6800 version froze).
;   The 6502 has NO 16-bit registers (other than PC)
;     and less overall register space than the 6800, so
;     it was necessary to reserve some obscure VTL02
;     variables {@ _ $ ( ) 0 1 2 3 4 5 6 7 8 9 :} for
;     the interpreter's internal use (the 6800 version
;     also uses several of these, but with different
;     designations).  The deep nesting of parentheses
;     also puts {; < =} in danger of corruption.  For
;     example, A=((((((((1)))))))) sets both {A}
;     and {;} to the value 1.
;   Users wishing to use a machine language subroutine
;     via the system variable {>} must first set the
;     system variable {"} to the proper address vector
;     (for example, "=768).
;   The x register is used to point to a simple VTL02
;     variable (it can't point explicitly to an array
;     element like the 6800 version because it's only
;     8-bits).  In the comments, var[x] refers to the
;     16-bit contents of the zero-page variable pointed
;     to by register x (residing at addresses x, x+1).
;   The y register is used as a pointer offset inside a
;     VTL02 statement (it can easily handle the maximum
;     statement length of about 128 bytes).  In the
;     comments, @[y] refers to the 16-bit address
;     formed by adding register y to the value in {@}.
;   The structure and flow of this interpreter is
;     similar to the 6800 version, but it has been re-
;     organized in a more 6502-friendly format (the
;     6502 has no 'bsr' instruction, so the 'stuffing'
;     of subroutines within 128 bytes of the caller is
;     only advantageous for conditional branches).
;   I designed this version to duplicate the OFFICIALLY
;     DOCUMENTED behavior of Frank's 6800 version:
;	http://www.altair680kit.com/manuals/Altair_
;	680-VTL-2%20Manual-05-Beta_1-Searchable.pdf
;     Both versions ignore all syntax errors and plow
;     through VTL-2 programs with the assumption that
;     they are "correct", but in their own unique ways,
;     so any claims of compatibility are null and void
;     for VTL-2 code brave (or stupid) enough to stray
;     from the beaten path.
;   This version is wound rather tightly, in a failed
;     attempt to fit it into 768 bytes like the 6800
;     version; some structured programming principles
;     were sacrificed in that attempt.  The 6502 simply
;     requires more instructions than the 6800 does to
;     manipulate 16-bit values, but the execution speed
;     should be comparable due to the 6502's slightly
;     lower average clocks/instruction ratio.  As it is
;     now, it fits into 1k with room to spare.  When
;     coding VTL02, I chose compactness over execution
;     speed at every opportunity; a higher-performance,
;     more highly-structured, and/or more featureful
;     version (with error detection perhaps?) should
;     still fit into 1k.  Are there any volunteers?
;   VTL02 is my free gift (?) to the world.  It may be
;     freely copied, shared, and/or modified by anyone
;     interested in doing so, with only the stipulation
;     that any liabilities arising from its use are
;     limited to the price of VTL02 (nothing).
;------------------------------------------------------
; VTL02 variables occupy RAM addresses $0080 to $00ff.
; They are little-endian, in the 6502 tradition.
; The use of lower-case and control characters for
;   variable names is allowed, but not recommended; any
;   attempts to do so would likely result in chaos.
; Variables tagged with an asterisk are used internally
;   by the interpreter and can change without warning.
;   {@ _} cannot be entered via the command line, and
;   {$ ( ) 0..9 : > ?} are (usually) intercepted by the
;   interpreter, so their internal use by VTL02 is
;   "safe".  The same cannot be said for {; < =}, so
;   be careful!		
at	 =   $80	{@}* interpreter text pointer
; VTL02 standard user variable space
;	     $82	{A B C .. X Y Z [ \ ] ^}
; VTL02 system variable space
under	 =   $be	{_}* interpreter temp storage
;	 =   $c0	{ }  space is a valid variable
bang	 =   $c2	{!}  return line number
quote	 =   $c4	{"}  user ml subroutine vector
pound	 =   $c6	{#}  current line number
dolr	 =   $c8	{$}* interpreter temp storage
remn	 =   $ca	{%}  remainder of last division
ampr	 =   $cc	{&}  pointer to start of array
tick	 =   $ce	{'}  pseudo-random number
lparen	 =   $d0	{(}* old line number
rparen	 =   $d2	{)}* interpreter temp storage
star	 =   $d4	{*}  pointer to end of free mem
;	     $d6	{+ , - . /}  valid variables
; Interpreter argument stack space
arg	 =   $e0	{0 1 2 3 4 5 6 7 8 9 :}*
; Rarely used variables and argument stack overflow
;	     $f6	{; < =}*
gthan	 =   $fc	{>}*
ques	 =   $fe	{?}*
;			
nulstk	 =   $01ff	system stack resides in page 1
linbuf	 =   $0200	input line buffer
prgm	 =   2048	VTL program grows from here ...
himem	 =   4096	up to the top of contiguous RAM
;------------------------------------------------------
; Equates specific to the Apple 1
; Machine language programmers can use address ranges
;   $0000 .. $007f and $0280 .. $03ff as their own,
;   safe from "well-behaved" VTL02 programs.
vtl02	 =   $0400	interpreter cold entry point
;			  (warm entry point is startok)
keyin	 =   $d010	last key pressed (ascii - 128)
keyrdy	 =   $d011	< 0 if key has been pressed
echo	 =   $ffef	woz monitor charout routine
;======================================================
	.or  vtl02	
;------------------------------------------------------
; Initialize program area pointers and start VTL02
;			
	lda  #prgm	
	sta  ampr	{&} -> empty program
	lda  /prgm	
	sta  ampr+1	
	lda  #himem	
	sta  star	{*} -> top of RAM
	lda  /himem	
	sta  star+1	
startok	sec  		request "OK" message
; - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Start/restart VTL02 command line with program intact
;			
start	ldx  #nulstk	
	txs  		reset the system stack pointer
	bcc  user	skip "OK" if carry clear
	jsr  outcr	
	lda  #'O'	print "OK" to user terminal
	jsr  outch	  and fall through to 'user'
	lda  #'K'	
	jsr  outch	
user	jsr  newln	input a line from the user
	ldx  #pound	direct 'cvbin' to {#}
	jsr  cvbin	does line start with a number?
	bcc  stmnt	  yes: handle program entry
	jsr  exec	  no: execute direct statement
	lda  pound	    if {#} = 0 then restart
	ora  pound+1	    else begin execution at {#}
	beq  startok	      by falling through to the
	clc  		      main execution loop
; - - - - - - - - - - - - - - - - - - - - - - - - - - -
; The main program execution loop
;			
branch	ldx  lparen	
	ldy  lparen+1	execute a VTL02 branch
	inx  		  (cs: forward, cc: backward)
	bne  branch2	{!} = {(} + 1
	iny  		  (VTL02 return pointer)
branch2	stx  bang	
	sty  bang+1	execute statement at new {#}
loop	jsr  findln	find program line >= {#}
	iny  		point to left-side of statement
	jsr  exec	execute one program statement
	sec  		default to forward execution
	lda  pound	if {#} = 0 then execute next
	ora  pound+1	  line (false branch condition)
	beq  loop	
	lda  pound+1	
	cmp  lparen+1	
	bne  branch	else has {#} changed?
	lda  pound	
	cmp  lparen	
	bne  branch	  yes: execute a branch
	beq  loop	  no: execute next line (cs)
;------------------------------------------------------
; Delete/insert program line or list program
;			
stmnt	lda  pound	
	ora  pound+1	if {#} = 0 then list program
	bne  skp2	else delete/insert line
; - - - - - - - - - - - - - - - - - - - - - - - - - - -
; List program to terminal and restart "OK" prompt
; Carry must be clear on entry
; uses:	 findln, outcr, prnum, prmsg, {@ ( )}
;			
list	jsr  findln	find program line >= {#}
	ldx  #lparen	line number for prnum
	jsr  prnum	print the line number
	lda  #' '	print a space instead of the
	jsr  outch	  line length byte
	lda  #0		zero for delimiter
	jsr  prstr	print the rest of the line
	sec  		continue at the next line
	bcs  list	(always taken)
;------------------------------------------------------
; Delete/insert program line and restart command prompt
; Carry must be clear on entry
; uses:	 find, start, linbuf, {@ _ # & * (}
;			
skp2	tya  		save linbuf offset pointer
	pha  		
	jsr  find	locate first line >= {#}
	bcs  insrt	
	lda  lparen	
	eor  pound	if line doesn't already exist
	bne  insrt	  then skip deletion process
	lda  lparen+1	
	eor  pound+1	
	bne  insrt	
	tax  		x = a (= 0)
	lda  (at),y	
	tay  		y = length of line to delete
	eor  #-1	
	sec  		
	adc  ampr	{&} = {&} - y
	sta  ampr	
	bcs  delt	
	dec  ampr+1	
delt	lda  at		
	sta  under	{_} = {@}
	lda  at+1	
	sta  under+1	
delt2	lda  under	
	cmp  ampr	delete the line
	lda  under+1	
	sbc  ampr+1	
	bcs  insrt	
	lda  (under),y	
	sta  (under,x)	
	inc  under	
	bne  delt2	
	inc  under+1	
	bcc  delt2	(always taken)
insrt	pla  		
	tax  		x = linbuf offset pointer
	lda  pound	
	pha  		push the new line number on
	lda  pound+1	  the system stack
	pha  		
	ldy  #2		
cntln	inx  		
	iny  		determine new line length and
	lda  linbuf-1,x	  push statement string on
	pha  		  the system stack
	bne  cntln	
	cpy  #4		if empty line then skip the
	bcc  jstart	  insertion process
	tax  		x = a (= 0)
	tya  		
	clc  		
	adc  ampr	calculate new program end
	sta  under	  {_} = {&} + y
	txa  		
	adc  ampr+1	
	sta  under+1	
	lda  under	
	cmp  star	
	lda  under+1	if {_} >= {*} then the program
	sbc  star+1	  won't fit in available RAM,
	bcs  jstart	  so abort to the "OK" prompt
slide	lda  ampr	
	bne  slide2	
	dec  ampr+1	
slide2  dec  ampr	
	lda  ampr	
	cmp  at		
	lda  ampr+1	
	sbc  at+1	
	bcc  move	slide open a gap inside the
	lda  (ampr,x)	  program just big enough to
	sta  (ampr),y	  hold the new line
	bcs  slide	(always taken)
move	tya  		
	tax  		x = new line length
move2	pla  		pull the statement string and
	dey  		  the new line number and store
	sta  (at),y	  them in the program gap
	bne  move2	
	ldy  #2		
	txa  		
	sta  (at),y	store length after line number
	lda  under	
	sta  ampr	{&} = {_}
	lda  under+1	
	sta  ampr+1	
jstart	jmp  start	dump stack, restart cmd prompt
;------------------------------------------------------
; Point @[y] to the first/next program line >= {#}
; entry: (cc): start search at beginning of program
;	 (cs): start search at next line
;		({@} -> beginning of current line)
; uses:  find, jstart, prgm, {@ # & (}
; exit:	 if line not found then abort to "OK" prompt
;	 else {@} -> found line, y = 2, {#} = {(} = 
;		actual line number
;			
findln	jsr  find	find first/next line >= {#}
	bcs  jstart	if end then restart "OK" prompt
	lda  lparen	
	sta  pound	{#} = {(}
	lda  lparen+1	
	sta  pound+1	
	rts  		
;------------------------------------------------------
; {?="...} handler; called from 'exec'
; list line handler; called from 'list'
;			
prstr	iny  		skip over the " or length byte
	tax  		x = delimiter, fall through
; - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Print a string at @[y]
; x holds the delimiter char, which is skipped over,
;   not printed (a null byte is always a delimiter)
; pauses before returning if a key was pressed and
;   waits for another	
; restarts the command prompt with user program intact
;   if either key was ctrl-c
; escapes out eventually if delimiter or null not found
; entry: @[y] -> string, x = delimiter char
; uses:	 keyrdy, keyin, start, outch, outrts
; exit:  (normal) @[y] -> null or byte after delimiter
; 	 (ctrl-c) dump the stack & restart "OK" prompt
;			
prmsg	txa  		
	cmp  (at),y	found x delimiter?
	beq  prmsg2	  yes: finish up
	lda  (at),y	found null delimiter?
	beq  prmsg2	  yes: finish up
	jsr  outch	  no: print character to the
	iny  		    terminal and loop
	bpl  prmsg	    (with safety escape)
prmsg2	tax  		save closing delimiter
	bit  keyrdy	has the user pressed a key?
	bpl  prout  	  no: resume without pausing
	jsr  inch2	  yes: process first key press
	jsr  inch	    and pause for another
prout	txa  		retrieve closing delimiter
	beq  outcr	always cr after null delimiter
	iny  		skip over the delimiter
	lda  (at),y	if trailing char is ';' then
	cmp  #';'	  suppress the carriage return
	beq  outrts	
outcr	lda  #$0d	cr to terminal
	bne  outch	(always taken)
;------------------------------------------------------
; Read user key press into a and echo
;			
inch	bit  keyrdy	
	bpl  inch	wait for a key press
inch2	lda  keyin	grab it
	and  #$7f	ensure that it's positive ascii
	cmp  #$03	ctrl-c?
	beq  jstart	  yes: abort to "OK" prompt
; - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Print ascii character in a to user terminal
;			
outch	pha  		save original char
	ora  #$80	(apples prefer negative ascii)
	jsr  echo	emit char via monitor routine
	pla  		restore original char
outrts	rts  		
;------------------------------------------------------
; Execute a hopefully valid VTL02 statement at @[y]
; entry: @[y] -> left-side of statement
; uses:  nearly everything
; exit:	 note to {>} users: no registers or variables
;	   are required to be preserved except the
;	   system stack pointer, the text base pointer
;	   {@}, and the original line number {(}
;	 if the right-side of the assignment begins
;	   with a {"}, it will be treated as a
;	   {?="...} statement for any left-side
;	   variable other than {)}
;			
exec	lda  (at),y	fetch left-side variable name
	beq  execrts	do nothing if null statement
	iny  		
	ldx  #arg	initialize argument pointer
	jsr  convp	arg[{0}] = address of left-side
	bne  exec1	  variable 
	lda  arg	
	cmp  #rparen	full line comment?
	beq  execrts	  yes: do nothing with the rest
exec1	iny  		skip over assignment operator
	lda  (at),y	is right-side a literal string?
	cmp  #'"'	  yes: print the string with
	beq  prstr	    trailing ';' check & return
	ldx  #arg+2	point eval to arg[{1}]
	jsr  eval	evaluate right-side in arg[{1}]
	lda  arg+2	
	ldx  arg+1	was left-side an array element?
	bne  exec8	  yes: skip to default actions
	ldx  arg	
	cpx  #dolr	if {$=...} statement then print
	beq  outch	  arg[{1}] as ascii character
	cpx  #gthan	
	bne  exec4	if {>=...} statement then call
	tax  		  user machine language routine
	lda  arg+3	  with arg[{1}] in a, x regs
	jmp  (quote)	  (MSB, LSB)
exec4	cpx  #ques	if {?=...} statement then print
	beq  prnum0	  arg[{1}] as unsigned decimal
exec8	ldy  #0		
	sta  (arg),y	
	adc  tick+1	store arg[{1}] in the left-
	rol  		  side variable
	tax  		
	iny  		
	lda  arg+3	
	sta  (arg),y	
	adc  tick	pseudo-randomize {'}
	rol  		
	sta  tick+1	
	stx  tick	
execrts	rts  		return to 'loop' or 'user'
;------------------------------------------------------
; {?=...} handler; called by 'exec'
;			
prnum0	ldx  #arg+2	x -> arg[{1}], fall through
; - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Print an unsigned decimal number (0..65535) in var[x]
; entry: var[x] = number to print
; uses:  div, outch, var[x+2], preserves original {%}
; exit:  var[x] = 0, var[x+2] = 10
;			
prnum	lda  remn	entry: print value of var[x]
	pha  		save {%}
	lda  remn+1	
	pha  		
	lda  #10	divisor = 10
	sta  2,x	
	lda  #0		
	pha  		null delimiter for print
	sta  3,x	repeat {
prnum2	jsr  div	  divide var[x] by 10
	lda  remn	
	ora  #'0'	  convert remainder to ascii
	pha  		  stack digits in ascending
	lda  0,x	    order ('0' for zero)
	ora  1,x	
	bne  prnum2	} until var[x] is 0
	pla  		
prnum3	jsr  outch	print digits in descending
	pla  		  order until delimiter is
	bne  prnum3	  encountered
	pla  		
	sta  remn+1	restore {%}
	pla  		
	sta  remn	
	rts  		
;------------------------------------------------------
; Evaluate a hopefully valid VTL02 expression at @[y]
;   and place its numeric result in arg[x]
; A VTL02 expression is defined as a string of one or
;   more terms, separated by operators and terminated
;   with a null or an unmatched right parenthesis
; A term is defined as a variable name, a decimal
;   constant, or a parenthesized sub-expression; terms
;   are evaluated strictly from left to right
; A variable name is defined as a simple variable or an
;   array element expression enclosed in {: )}
; entry: @[y] -> expression text, x -> argument
; uses:  getval, oper, argument stack area
; exit:	 arg[x] = result, @[y] -> next text
;			
eval	lda  #0		
	sta  0,x	start evaluation by simulating
	sta  1,x	  {0+expression}
	lda  #'+'	
notdn	pha  		stack alleged operator
	inx  		advance the argument stack
	inx  		  pointer
	jsr  getval	arg[x+2] = value of next term
	dex  		
	dex  		
	pla  		retrieve and apply the operator
	jsr  oper	  to arg[x], arg[x+2]
	lda  (at),y	end of expression?
	beq  evalrts	  (null or right parenthesis)
	iny  		
	cmp  #')'	  no: skip over the operator
	bne  notdn	    and continue the evaluation
evalrts	rts  		  yes: return with final result
;------------------------------------------------------
; Put the numeric value of the term at @[y] into var[x]
; Some examples of valid terms:  123, $, H, (15-:J)/?)
;			
getval	jsr  cvbin	decimal number at @[y]?
	bcc  getrts	  yes: return with it in var[x]
	lda  (at),y	
	iny  		
	cmp  #'?'	user line input?
	bne  getval2	
	tya  		  yes:
	pha  		
	lda  at		    save @[y]
	pha  		      (current expression ptr)
	lda  at+1	
	pha  		
	jsr  inln	    input expression from user
	jsr  eval	    evaluate, var[x] = result
	pla  		
	sta  at+1	
	pla  		
	sta  at		    restore @[y]
	pla  		
	tay  		
	rts  		    skip over "?" and return
getval2	cmp  #'$'	user char input?
	bne  getval3	
	jsr  inch	  yes: input one char
	sta  0,x	    var[x] = char
	rts  		    skip over "$" and return
getval3	cmp  #'('	sub-expression?
	beq  eval	  yes: evaluate it recursively
	jsr  convp	
	lda  (0,x)	
	pha  		  no: first set var[x] to the
	inc  0,x	    address of the named
	bne  getval4	    variable, then store that
	inc  1,x	    variable's value in var[x]
getval4	lda  (0,x)	    before returning
	sta  1,x	
	pla  		
	sta  0,x	
getrts	rts  		
;------------------------------------------------------
; Apply the binary operator in a to var[x] and var[x+2]
; Valid VTL02 operators are +, -, *, /, <, and =
; Any other operator in a defaults to >=
;			
oper	cmp  #'+'	addition operator?
	bne  oper2	  no: next case
; - - - - - - - - - - - - - - - - - - - - - - - - - - -
add	clc  		
	lda  0,x	var[x] += var[x+2]
	adc  2,x	
	sta  0,x	
	lda  1,x	
	adc  3,x	
	sta  1,x	
	rts  		
oper2	cmp  #'-'	subtraction operator?
	bne  oper3	  no: next case
; - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub	sec  		
	lda  0,x	var[x] -= var[x+2]
	sbc  2,x	
	sta  0,x	
	lda  1,x	
	sbc  3,x	
	sta  1,x	
	rts  		
oper3	cmp  #'*'	multiplication operator?
	bne  oper4	  no: next case
; - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 16-bit unsigned multiply routine
;   overflow is ignored/discarded
;   var[x] *= var[x+2], var[x+2] = 0, {_} is modified
;			
mul	lda  0,x	
	sta  under	
	lda  1,x	{_} = var[x]
	sta  under+1	
	lda  #0		
	sta  0,x	var[x] = 0
	sta  1,x	
mul2	lsr  under+1	
	ror  under	{_} /= 2
	bcc  mul3	
	jsr  add	form the product in var[x]
mul3	asl  2,x	
	rol  3,x	left-shift var[x+2]
	lda  2,x	
	ora  3,x	loop until var[x+2] = 0
	bne  mul2	
	rts  		
oper4	cmp  #'/'	division operator?
	bne  oper5	  no: next case
; - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 16-bit unsigned division routine
;   var[x] /= var[x+2], {%} = remainder, {_} modified
;   var[x] /= 0 produces {%} = var[x], var[x] = 65535
;			
div	lda  #0		
	sta  remn	{%} = 0
	sta  remn+1	
	lda  #16	
	sta  under	{_} = loop counter
div1	asl  0,x	var[x] is gradually replaced
	rol  1,x	  with the quotient
	rol  remn	{%} is gradually replaced
	rol  remn+1	  with the remainder
	lda  remn	
	cmp  2,x	
	lda  remn+1	partial remainder >= var[x+2]?
	sbc  3,x	
	bcc  div2	
	sta  remn+1	  yes: update the partial
	lda  remn	    remainder and set the
	sbc  2,x	    low bit in the partial
	sta  remn	    quotient
	inc  0,x	
div2	dec  under	
	bne  div1	loop 16 times
	rts  		
;------------------------------------------------------
; Apply comparison operator in a to var[x] and var[x+2]
;    and place result in var[x] (1 if true, 0 if false)
;			
oper5	sec  		{_} = operator: -2 = less than,
	sbc  #'>'	  -1 = equal, other = greater
	sta  under	  than or equal
	jsr  sub	var[x] -= var[x+2]
	inc  under	equality test?
	bne  oper5b	
	ora  0,x	  yes: 'or' high and low bytes
	beq  oper5c	    cs if 0
oper5a	clc  		    cc if not 0
oper5b	lda  #0		
	inc  under	less than test?
	bne  oper5c	  no: default to >=
	bcs  oper5a	  yes: complement carry
	sec  		
oper5c	sta  1,x	
	rol  		
	sta  0,x	var[x] = 1 (true), 0 (false)
	rts  		
;------------------------------------------------------
; Set var[x] to address of variable named in a reg
; entry:  a reg holds variable name in ascii
;	  @[y] -> array element expression (if a = ':')
; uses:	  eval, argument stack, {&}	
; exit:   @[y] -> following text, (eq) if simple var
;			
convp	cmp  #':'	array element?
	beq  varray	
	asl  		  no:
	ora  #$80	
	sta  0,x	    var[x] -> simple variable
	lda  #0		
	beq  pack	
varray	jsr  eval	  yes: evaluate array index at
	asl  0,x	    @[y] and advance y
	rol  1,x	
	clc  		
	lda  ampr	    var[x] -> array element
	adc  0,x	
	sta  0,x	
	lda  ampr+1	
	adc  1,x	
pack	sta  1,x	
	rts  		
;------------------------------------------------------
; If text at @[y] is a decimal constant, translate into
;	var[x] (discarding any overflow) and update y
; entry:  @[y] -> text containing possible constant
; uses:	  mul, add, var[x], var[x+2], {@ _}
; exit:   (cc): var[x] = constant, @[y] -> next text
;	  (cs): var[x] = 0, @[y] unchanged
;			
cvbin	lda  #0		
	sta  0,x	var[x] = 0
	sta  1,x	
	sta  3,x	
	jsr  tstn	is first char decimal?
	bcs  tstrts	  no: return with carry set
cvbin2	pha  		save decimal digit
	lda  #10	
	sta  2,x	
	jsr  mul	var[x] *= 10
	pla  		retrieve decimal digit
	sta  2,x	
	jsr  add	var[x] += digit
	iny  		
	jsr  tstn	is next char decimal?
	bcc  cvbin2	  yes: loop for more digits
cvbrts	clc  		
	rts  		
tstn	lda  (at),y	
	cmp  #'9'+1	
	bcs  tstrts	
	sbc  #'0'-1	
	bcs  cvbrts	
	sec  		
tstrts	rts  		
;------------------------------------------------------
; Accept input line from user and place in linbuf, zero
;   terminated (allows very primitive edit/cancel)
; entry:  (jsr to inln or newln, not inln6)
; uses:   linbuf, inch, outcr, {@}
; exit:   @[y] -> linbuf
;			
inln6	cmp  #'@'	@ (cancel)?
	beq  newln	  yes: discard entire line
	iny  		line limit exceeded?
	bpl  inln2	  no: keep going
newln	jsr  outcr	  yes: discard entire line
inln	ldy  #linbuf	entry point: start a fresh line
	sty  at		{@} -> input line buffer
	ldy  /linbuf	
	sty  at+1	
	ldy  #1		
inln5	dey  		
	bmi  newln	
inln2	jsr  inch	get (and echo) one key press
	cmp  #'_'	_ (backspace)?
	beq  inln5	  yes: delete previous char
	cmp  #$0d	cr?
	bne  inln3	
	lda  #0		  yes: replace with null
inln3	sta  (at),y	put key in linbuf
	bne  inln6	continue if not null
	tay  		y = 0
	rts  		
;------------------------------------------------------
; Find the first/next program line >= {#}
; entry:  (cc): start search at program beginning
;	  (cs): start search at next line
;		({@} -> beginning of current line)
; uses:   prgm, {@ # & (}
; exit:	  (cs): line not found, {@} = {&} (usually),
;		{(} = garbage, y = 2
;	  (cc): {@} -> found line, {(} = actual line
;		number, y = 2
;			
find	bcs  findnxt	cs: search begins at next line
	lda  #prgm	cc: search begins at first line
	sta  at		
	lda  /prgm	  {@} -> first program line
	sta  at+1	
	bcc  getlpar	  (always taken)
findnxt	jsr  checkat	if {@} >= {&} then the search
	bcs  findrts	  failed; return with (cs)
	lda  at		
	adc  (at),y	(length of current line)
	sta  at	  	{@} -> next program line
	bcc  getlpar	
	inc  at+1	
getlpar	ldy  #0		
	lda  (at),y	
	sta  lparen	{(} = current line number
	cmp  pound	  (invalid if {@} >= {&}, but
	iny  		  we'll catch that later...)
	lda  (at),y	
	sta  lparen+1	if {(} < {#} then try the next
	sbc  pound+1	  program line
	bcc  findnxt	else the search is complete
checkat	ldy  #2		
	lda  at		{@} >= {&} (end of program)?
	cmp  ampr	
	lda  at+1	  yes: search failed (cs)
	sbc  ampr+1	  no: clear carry
findrts	rts  		
;------------------------------------------------------
	.en  		
