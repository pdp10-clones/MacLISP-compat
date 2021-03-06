; -*- MIDAS -*-
TITLE SENDI -- Standard Send Interpreter
.INSRT SYS:.FASL DEFS
.FASL

SVERPRT SENDI,83

.INSRT LSPSRC;EXTMDF >

;; (SI:MAP-OVER-CLASSES FUNCTION CLASS)
.entry SI:MAP-OVER-CLASSES SUBR 003
	movei r,[%mapcls tt,(c)]
	movei f,(CALL 2,)	   ;2 args
	jrst imapit

; (SI:MAP-OVER-METHODS FUNCTION CLASS)
.entry SI:MAP-OVER-METHODS SUBR 003
	movei r,[%mapmth tt,(c)]
	movei f,(CALL 3,)	   ;3 args
imapit:	push fxp,flp		   ;Save the state of the stacks for
	push fxp,p		   ;quick return
	hrli a,(f)		   ;prepare to XCT-call the function
	push fxp,a		   ;put on FXP so can be snapped.
	push p,a
	push p,b
	move a,b		   ;let's check the second arg
mclp:	pushj p,classp		   ;is this a class?
	jumpe a,[ move a,(p)	   ;recover the non-class
		  WTA [NOT A CLASS!]
		  movem a,(p)
		  jrst mclp]
	pop p,c			   ;Recover the class, now in C
	pop p,a			   ;Get our function to balance the stack
	setz a,			   ;SI:MAP-OVER-CLASSES expects () in A
	xct (r)			   ;Get the map-method/class method
	pushj p,(tt)		   ;call it
	pop fxp,a		   ;restore the state
	pop fxp,p		   ;of our various PDL's
	pop fxp,flp
false:	setz a,			   ;Return ()
cpopj:	popj p,

.entry SI:STANDARD-MAP-OVER-METHODS MAP-METHODS 003
	%methd ar1,(c)		   ;Get methods
	jumpe ar1,irecur	   ;If null, don't.  Look at superiors instead
	push p,c
mmsear:	move a,(p)		   ;First arg is the class method is in
	%mname b,(ar1)		   ;Get the method symbol
	%mfsym c,(ar1)		   ;Get the method function
	push p,ar1		   ;save our state
	xct (fxp)		   ;Invoke the user's function
	jumpn a,mmret		   ;if non-nil return, go return result
	pop p,ar1		   ;recover state
	%mnext ar1,(ar1)	   ;Get the next one
	jumpn ar1,mmsear	   ;loop until end
	pop p,c			   ;recover class being hacked.
	movei r,[%mapmth tt,(c)]   ;Pass in how to get recursion
	jrst irecur

.entry SI:STANDARD-MAP-OVER-CLASSES MAP-CLASSES 000
	move b,a		   ;Second arg:  Previous class, or ()
        movei a,(c)		   ;First arg:  Class
	push p,c		   ;Don't forget what class we are
	xct (fxp)		   ;Invoke the user's function
	jumpn a,mmret		   ;If non-null, time to return.
	pop p,c			   ;Recover class
	movei a,(c)		   ;In super-classes, tell this is inferior of
				   ;Interest.
	movei r,[%mapcls tt,(c)]   ;How to get next level's routine.

irecur:	%super ar1,(c)		   ;Get list of superiors
	jumpe ar1,cpopj		   ;no such luck
ircur0:	hlrz c,(ar1)		   ;look at first
	xct (r)			   ;Get in TT the frob to call
	push p,ar1		   ;Save our state
	push flp,r		   ;Can't use FXP, has P on it.
	pushj p,(tt)		   ;Call it
	pop flp,r
	pop p,ar1
	hrrz ar1,(ar1)		   ;He failed, look at next
	jumpn ar1,ircur0	   ;loop until end
	popj p,			   ;Return our failure

mmret:	pop fxp,t		   ;flush the instruction
	pop fxp,p		   ;restore the stack
	pop fxp,flp		   ;Restore FLP
	popj p,			   ;and return

.entry SEND-AS LSUBR 004777
	movei r,(p)
	addi r,(t)		   ;Get address of return address
	movei c,cpopj
	aos r			   ;Skip over this return address for now
	exch c,(r)		   ;1st arg becomes CPOPJ, pick up class
	hrrz a,1(r)		   ;Get object for sending
	hrrz b,2(r)		   ;Get method name
	aoja t,sndit		   ;one less argument


.entry SEND LSUBR 003777
send:	movei r,(p) 
	addi r,(t)		   ;Get address of return address
	hrrz a,1(r)		   ;Get object for sending
	hrrz b,2(r)		   ;Get method name
	jsp d,getcls		   ;get the class
sndit:	push fxp,p		   ;remember size of stack so can restore
	%sendi tt,(c)		   ;get the send interpreter
	pushj p,(tt)		   ;invoke it
				   ;Send interpreters return on failure
	jcall 16,.function SI:LOST-MESSAGE-HANDLER


.ENTRY TYPE-OF SUBR 002		   ;Better than TYPEP!
	jsp d,getcls
	%typep a,(c)		   ;Fetch the type from whatever class
	popj p,


.ENTRY GLOBAL:TYPEP SUBR 002	   ;A better TYPEP, for compatibility
	jumpe a,nilsym		   ;+ETERNAL-SPECIAL-CASE
	jsp d,getcls
	%typep a,(c)		   ;Fetch the type from whatever class
	caie a,.atom PAIR	   ;Special-case xformation for compatability
	  popj p,
	movei a,.atom LIST
	popj p,

nilsym:	movei a,.atom SYMBOL
	popj p,

.entry CLASSP SUBR 002
classp:	movei tt,(a)
	lsh tt,-seglog
	skipge tt,st(tt)	   ;Must be some kind of HUNK
	  tlnn tt,hnk
	    jrst false
	%marker tt,(a)		   ;With the marker in the CAR
	came tt,.special *:CLASS-MARKER
	  jrst false
	hrrz a,(a)		   ;Get the "class pointer"
	movei tt,(a)		   ;The class pointer must also
	lsh tt,-seglog		   ;pass the same two tests
	skipge tt,st(tt)
	  tlnn tt,hnk
	    jrst false
	%marker tt,(a)		   ;Get the marker
	came tt,.special *:CLASS-MARKER
	  jrst false
truth:	movei a,.atom T		   ;Passed all the tests, it's a class!
	popj p,

.entry CLASS-OF SUBR 002
	jsp d,getcls
	move a,c		   ;GETCLS returns in C for SI:SEND
	popj p,

getcls:	jumpe a,nilcls		   ;+ETERNAL-SPECIAL-CASE-CROCK
	movei tt,(a)		   ;copy
	lsh tt,-seglog		   ;get index into segment table
	hrrz tt,st(tt)		   ;get the type
	subi tt,.atom LIST	   ;get the type code number
	xct clstab(tt)
	jrst (d)
nilcls:	move c,.special NULL-CLASS
	jrst (d)

clstab:	  
	move c,.special PAIR-CLASS
  IRPS x,,[FIXNUM FLONUM BIGNUM SYMBOL]
	  move c,.special x!-CLASS
TERMIN
REPEAT hnklog,	jrst snhnk
	move c,.special RANDOM-CLASS
	jrst snary

snary:	move c,.special ARRAY-CLASS  ;An array; check for special cases
	move tt,ASAR(a)		   ;Get the ASAR bitss
	tlne tt,as.sfa		   ;Is it an SFA?
	  move c,.special SFA-CLASS
	tlne tt,as.fil		   ;Is it a file?
	  move c,.special FILE-CLASS
	tlne tt,as.job		   ;Heh heh, is it a JOB?
	  move c,.special JOB-CLASS
	jrst (d)

snhnk:	hrrz tt,(a)		   ;get the class of this object
	lsh tt,-seglog		   ;check it out
	move tt,st(tt)
	tlnn tt,HNK		   ;Is this a hunk?
	  jrst symul		   ;  No, hack as random system datum
	%class c,(a)
	%marker tt,(c)		   ;Get the marker of this class
	came tt,.special *:CLASS-MARKER
symul:	  move c,.special HUNK-CLASS
	jrst (d)

;; SEND interpreters expect:
;; In A, the object
;; In B, the method name
;; In C, the class from which the SEND interpreter was extracted
;; In R, the address of the return address on the stack.
;; On FXP, the saved P to restore before calling method, to flush the
;; saved state from the SEND interpreters
;; An arbitrary amount of cruft on the stack beyond point saved on FXP
;; For the sake of trampolines, they should leave the method bucket in
;; 

.entry SI:DEFAULT-SENDI SENDI 000   ;not to be called, just need property
	%methd ar2a,(c)		   ;get the dispatch list
	jumpe ar2a,sndup	   ;if NIL, try superiors
mthlp:	%mname ar1,(ar2a)	   ;get the method name
	cain ar1,(b)		   ;is it this one? (symbol in right half)
	  jrst sndgo		   ;  yes, do it up!
	%mnext ar2a(ar2a)	   ;next method
	jumpn ar2a,mthlp	   ;(unless end)

sndup:	%super ar1,(c)		   ;get superiors
	jumpe ar1,sndfail	   ;failed if none
suplp:	hlrz c,(ar1)		   ;get the class to hack
	push p,ar1		   ;save our state
	%sendi tt,(c)		   ;get the send interpreter
	pushj p,(tt)		   ;invoke it
	pop p,ar1		   ;it failed, recover our state
	hrrz ar1,(ar1)		   ;throw that class away
	jumpn ar1,suplp		   ;try next
sndfail:
	popj p,			   ;foo, we failed too.

sndgo:	pop fxp,p		   ;restore our stack to initial state
	%msubr tt,(ar2a)	   ;get the LSUBR part of the method
	jumpn tt,(tt)		   ;and invoke it if found
				   ;Not compiled (or undefined...)
	%mfsym tt,(ar2a)	   ;Get the symbol or lambda or whatever
	jcall 16,(tt)		   ;(closure!?)

;; CALLI frobs are called with the stack in IAPPLY format

.entry SI:DEFAULT-CALLI CALLI 000   ;not to be called, just need property
	movei tt,(p)
	addi tt,1(t)		   ;get address of first arg
	hrli tt,-1(t)		   ;Make it into an AOBJN ptr to args
	push p,NIL		   ;Make room for additional arg
	movei b,.atom CALL	   ;First arg comes out of the blue
	hrrzs (tt)		   ;Flush left-half
dcloop:	exch b,(tt)		   ;swap! previous goes in this slot, save this
	aobjn tt,dcloop		   ;for next time around
	subi t,2		   ;count 2 additional arguments, self and CALL
	jrst send		   ;go send the message

.entry SI:CALLI-TRANSFER CALLI 000
	move tt,t		   ;copy number of args
	addi tt,(p)		   ;get loc of function
	hrrz a,(tt)		   ;get "function"
	hrrz a,(a)		   ;get class
	%calli tt,(a)		   ;get CALLI interpreter from the class
	jrst (tt)		   ;Invoke it

.entry *:EXTENDP SUBR 002
	movei tt,(a)		;copy
	lsh tt,-seglog
	move tt,st(tt)
	tlnn tt,HNK
	  jrst false
	hrrz a,(a)		;CDR
	movei tt,(a)
	lsh tt,-seglog
	move tt,st(tt)
	tlnn tt,hnk
	  jrst false
	%marker b,(a)		;Get the marker
	movei a,.atom T
	came b,.special *:CLASS-MARKER
	  setz a,
	popj p,
FASEND
