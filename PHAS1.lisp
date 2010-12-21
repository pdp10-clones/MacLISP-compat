;;;   PHAS1  						  -*-LISP-*-
;;;   **************************************************************
;;;   ***** MACLISP ***** LISP COMPILER (PHASE 1) ******************
;;;   **************************************************************
;;;   ** (C) Copyright 1981 Massachusetts Institute of Technology **
;;;   ****** This is a Read-Only file! (All writes reserved) *******
;;;   **************************************************************


(SETQ PHAS1VERNO '#.(let* ((file (caddr (truename infile)))
			   (x (readlist (exploden file))))
			  (setq |verno| (cond ((fixp x) file)  ('/81)))))

(EVAL-WHEN (COMPILE) 
     (AND (OR (NOT (GET 'COMPDECLARE 'MACRO))
	      (NOT (GET 'OUTFS 'MACRO)))
	  (LOAD `(,(cond ((status feature ITS) '(DSK COMLAP))
			 ('(LISP)))
		  CDMACS
		  FASL)))
)


(EVAL-WHEN (COMPILE)
	   (ALLOC '(LIST (55296. 65536. 0.2) FIXNUM (4096. 6144. 0.2)))
	   (COMPDECLARE)
	   (GENPREFIX |/|p1-|))



(COMMENT P1 - BASIC PHASE 1 FUNCTION)


(DEFUN P1 (X)
 (PROG (FTYP 2NDP Z Y TEM MODE)
   P1-START
     (COND ((NULL X) (GO P1NIL))
	   ((EQ X 'T) (RETURN (COND (ARITHP '('T)) (''T))))
	   ((MEMQ (SETQ Z (TYPEP X)) '(BIGNUM FIXNUM FLONUM))
	    (SETQ X (LIST 'QUOTE X) MODE (COND ((EQ Z 'BIGNUM) () ) (Z)))
	    (GO P1XIT))
	   ((EQ Z 'SYMBOL)
	    (COND ((SETQ Z (ASSQ X RNL))
		   (SETQ X (CDR Z))
		   (GO P1-START))
		  ((GET X '+INTERNAL-STRING-MARKER)
		   (SETQ X `(QUOTE ,X) MODE () )
		   (GO P1-START)))
	    (SETQ CNT (ADD1 CNT))
	    (P1SPECIAL X)
	    (AND ARITHP (SETQ MODE (VARMODE X)))
	    (GO P1XIT))
	   ((NOT (EQ Z 'LIST)) 
	    (COND ((AND (HUNKP X) (NOT (EQ (SETQ Z (P1MACROGET X)) NULFU)))
		   (SETQ X Z) 
		   (GO P1-START)))
	    (PDERR X |Random piece of data - () will be substituted|) 
	    (GO P1NIL))
	   ((EQ (SETQ Z (TYPEP (CAR X))) 'LIST)
	    (COND ((EQ (CAAR X) 'LAMBDA) (RETURN (P1LAM (CAR X) (CDR X))))
		  ((EQ (CAAR X) 'LABEL) 
		   (PDERR X |LABEL is no longer supported|)
		   (GO P1NIL))
		  ((EQ (CAAR X) CARCDR) 
		   (SETQ X (LIST (CAR X) (P1VN (CADR X))))
		   (GO P1XIT))
		  ((MEMQ (CAAR X) '(QUOTE FUNCTION))
		   (SETQ X (CONS (CADAR X) (CDR X)))
		   (GO P1-START))
		  ((EQ (CAAR X) COMP)
		   (P1SQV PROGN)
		   (SETQ X ((LAMBDA (EFFS ARITHP KTYPE PNOB)
				    (RPLACD (CDAR X) (P1 (CDDAR X)))
				    (COND ((> (LENGTH (CDR X)) #%(NACS)) 
					   (P1FAKE X))
					  ('T (CONS (CAR X) (MAPCAR 'P1 (CDR X))))))
				() () () 'T))
		    (SETQ MODE (AND (MEMQ (CADAR X) '(FIXNUM FLONUM)) (CADAR X)))
		   (GO P1XIT))
		  ((EQ (CAAR X) MAKUNBOUND) (GO P1XIT))
		  ((NOT (EQ (SETQ Z (P1MACROGET (CAR X))) NULFU)) 
		   (SETQ X (CONS Z (CDR X)))
		   (GO P1-START))
		  ('T (P1SQV PROGN)
		      (SETQ X ((LAMBDA (EFFS ARITHP KTYPE PNOB)
				       (SETQ Z (P1 (CAR X)) ARITHP () )
				       (COND ((CDR Z) 
					      (PDERR X |Computed function cant be numeric|)
					      (GO P1NIL))
					     ('T (WARN X |Computed functions are not generally supported,/
	This code is being rewritten using FUNCALL|)))
				       (AND (ATOM (CAR Z)) 
					    (SYSP (CAR Z))
					    (SETQ X (CONS (CAR Z) (CDR X)))
					    (GO P1-START))
				       (SETQ X (CONS (CONS COMP (CONS 'FUNCALL (CAR Z)))
						     (MAPCAR 'P1 (CDR X)))))
			       () 'T () 'T))
		      (GO P1XIT))))
	   ((NOT (EQ Z 'SYMBOL)) 
	    (PDERR X |Unlikely crufft used in functional position|)
	    (GO P1NIL))
	   ((OR (NULL (CAR X)) (EQ (CAR X) 'T)) 
	    (WARN X |T and NIL are verry poor choices for function names - 
you will most likely lose badly!|))
	   ((EQ (CAR X) 'QUOTE)	 	      ;Certain QUOTEs are trivial
	    (COND ((OR (NULL (CDR X)) (CDDR X)) (GO WNA))
		  ((OR (EQ (CADR X) 'T) (NULL (CADR X)))
		   (SETQ X (CADR X))
		   (GO P1-START))
		  ((MEMQ (SETQ TEM (TYPEP (CADR X))) '(FIXNUM FLONUM))
		   (SETQ MODE TEM)))
	    (GO P1XIT))
	   ((EQ (CAR X) NULFU) (GO P1-CALL))  ;Placeholder for pseudo-SUBR
	   ((and (setq z (get (car x) 'SOURCE-TRANS))
		 (do ((l z (cdr l)))
		     ((null l) () )
		   (multiple-value (y z) (funcall (car l) x))
		   (if z (return 'T))))
	    (setq x y)
	    (go p1-start))
	   ((NOT (EQ (SETQ Z (P1MACROGET X)) NULFU))
	     (SETQ X Z) 
	      (GO P1-START)))		    ;Try again after MACRO expansion

	;Here, we analyze a symbol used in functional position, 
	;  obtaining the relevant information from property list flags

   B-?  (SETQ FTYP (FUNTYP-DECODE (CAR X)))
	(COND ((NULL FTYP) 
	       ;Each wing of this COND will GO someplace
	       (COND ((GET (CAR X) '*ARRAY) (GO P1-CALL))
		     ((EQ (CAR X) GOFOO) (GO P1XIT))
;;;		     ((SETQ Y (ASSQ (CAR X) RNL))
;;;		      (SETQ X (CONS (CDR Y) (CDR X)))
;;;		      (GO P1-START))
		     ('T (P1SQV PROGN)
			 (AND (MEMQ (CAR X) BVARS)
			      #%(WARN X |Bound variable used as Function name|))
;;;			 (COND ((AND (NULL NFUNVARS) 
;;;				     (OR (SETQ TEM (SPECIALP (CAR X)))
;;;					 (MEMQ (CAR X) BVARS)))
;;;				(COND ((NOT (SETQ Y (ASSQ (CAR X) FFVL))) 
;;;				       (COND (TEM #%(WARN (CAR X) |Used as free functional variable|))
;;;					     ('T (CKCFV (CAR X))
;;;						 #%(WARN (CAR X) |Used as bound functional variable|)))
;;;				       (PUSH (LIST (CAR X) TOPFN) FFVL))
;;;				      ((NOT (MEMQ TOPFN (CDR Y))) 
;;;				       (RPLACD Y (CONS TOPFN (CDR Y)))))
;;;				(SETQ X (CONS (CONS COMP (CONS 'FUNCALL (CAR X))) (CDR X)))
;;;				(GO P1-START)))
			 (PUSH (CAR X) UNDFUNS)
			 (PUTPROP (CAR X)
				  'T 
				  (COND ((> (SETQ Z (LENGTH (CDR X))) #%(NACS))
					 (SETQ Z (CONS Z Z))
					 '*LEXPR)
					('T (SETQ Z (CONS () Z))
					    '*EXPR)))
			 (P1ACK (CAR X) () Z (CDR Z))
			 (COND ((CAR Z) (RETURN (P1FAKE X)))
			       ('T (GO P1-CALL))) )) )
	      ((EQ FTYP 'JSP) 
	       (AND (P1ACK (CAR X) 'SUBR () (CDR X)) (GO WNA))
	       (GO P1-CALL))
	      ((EQ FTYP 'CARCDR) (RETURN (P1CARCDR X)))
	      ((MEMQ FTYP '(*EXPR *FEXPR *LEXPR))
	       (P1SQV PROGN)
	       (COND ((EQ FTYP '*EXPR)
		      ((LAMBDA (ZZ) 
			       (COND ((OR (> ZZ #%(NACS)) (GET (CAR X) '*LEXPR))
				      (LREMPROP (CAR X) '(*EXPR *LEXPR))
				      (PUTPROP (CAR X) 'T '*LEXPR)
				      (AND (P1ACK (CAR X) 'LSUBR (CONS ZZ ZZ) ZZ)
					   (GO WNA))
				      (RETURN (P1FAKE X)))
				     ((P1ACK (CAR X) 'SUBR (CONS () ZZ) ZZ) 
				      (GO WNA))
				     ('T (GO P1-CALL))))
		           (LENGTH (CDR X))))
		     ((EQ FTYP '*LEXPR) 
		      (AND (P1ACK (CAR X) 'LSUBR () (CDR X)) (GO WNA))
		      (RETURN (P1FAKE X)))
		     ((EQ FTYP '*FEXPR) (RETURN (P1MODESET X)))) )
	      ((EQ FTYP 'SUBR)
	       (COND ((EQ (CAR X) 'PAIRP)
		      (SETQ X `(EQ (TYPEP ,(cadr x)) 'LIST)))
		     ((MEMQ (CAR X) '(SORT SORTCAR))
		      (AND (SETQ Y (P1FUNGET (CADDR X)))
			   (SETQ X (LIST (CAR X) (CADR X) Y)))))
	       (GO DISPATCH))
	      ((MEMQ FTYP '(FSUBR LSUBR)) (GO DISPATCH))
	      ('T (BARF () |Bad function type - P1|) ))

  B-SUBR   (SETQ 2NDP (SETQ FTYP 'SUBR))	(GO DISPATCH)

  B-LSUBR  (SETQ 2NDP (SETQ FTYP 'LSUBR)) 	(GO DISPATCH)

  B-FSUBR  (SETQ 2NDP (SETQ FTYP 'FSUBR)) 	(GO DISPATCH)

  DISPATCH	;It is assumed that FTYP will be among SUBR, FSUBR, and LSUBR
	    (SETQ TEM () Z () )
	    (COND ((AND (NOT 2NDP)						;"2NDP" non-null means
			(OR (SETQ TEM (GET (CAR X) 'ARITHP))			; already half dispatched
			    (SETQ Z (GET (CAR X) 'NUMBERP))))			;Throw numeric stuff to P1ARITH
		   (AND (P1ACK (CAR X) FTYP () (CDR X)) (GO WNA))
		   (COND ((AND Z (MEMQ (CAR X) '(EQ EQUAL)))	
			  (AND (COND ((OR (NULL (CADR X)) (QNILP (CADR X)))	;But trap-out "(EQ MUMBLE () )"
				      (SETQ TEM (CADDR X))
				      'T)
				     ((OR (NULL (CADDR X)) (QNILP (CADDR X)))
				      (SETQ TEM (CADR X))
				      'T))
			       (PROG2 (SETQ X (LIST 'NULL TEM)) (GO B-SUBR)))))
		   (RETURN (P1ARITH X TEM Z)))
		  ((EQ FTYP 'FSUBR)
		   (COND ((EQ (CAR X) 'SETQ)  (RETURN (P1SETQ X)))
			 ((EQ (CAR X) 'PROG) (RETURN (P1PROG (CDR X))))
			 ((EQ (CAR X) 'COND) (RETURN (P1COND (CAR X) (CDR X))))
			 ((MEMQ (CAR X) '(AND OR))
			  (COND ((NULL (CDDR X)) 
				 (WARN X |There are not two or more clauses here - do you really want this?|)
				 (SETQ X (COND ((CDR X) (CADR X)) 
					       ((EQ (CAR X) 'AND))))
				 (GO P1-START))
				(EFFS (RETURN (P1COND (CAR X) (CDR X))))
				((EQ (CAR X) 'OR) (SETQ TEM (MAPCAR 'NCONS (CDR X))))
				('T (SETQ TEM (L2F (CDR X)))
				    (SETQ TEM (LIST (LIST (COND  ((NULL (CDDR TEM)) (CADR TEM))
								 ((CONS 'AND (CDR TEM))))
							  (CAR TEM))))))
			  (RETURN (P1COND 'COND TEM)))
			 ((EQ (CAR X) 'GO) (SETQ X (P1GO X)) (GO P1XIT))
			 ((EQ (CAR X) 'DO)			;DO expands into a LAMBDA application
			  (SETQ X (P1DO (SETQ TEM X)))		; and hence this must be dispatched
			  (AND (NULL X) (DBARF TEM |Bad DO format|))
			  (GO P1-START))			; from the start again.
			 ((EQ (CAR X) 'CASEQ) 
			  (SETQ X (P1CASEQ (SETQ TEM X)))	;Might expand into a COND, or
			  (AND (NULL X) (DBARF TEM |Bad CASEQ format|))
			  (GO P1-START))			;  a LAMBDA application
			 ((EQ (CAR X) 'PUSH)
			  (SETQ X (+INTERNAL-PUSH-X (CDR X) EFFS))  ;Expand
			  (GO P1-START))		       ;and try again
			 ((EQ (CAR X) 'POP)
			  (SETQ X (+INTERNAL-POP-X (CDR X) EFFS))  ;Expand
			  (GO P1-START))		       ;and try again
			 ((EQ (CAR X) 'SETF)
			  (SETQ X (+INTERNAL-SETF-X (CDR X) EFFS))  ;Expand
			  (GO P1-START))		       ;and try again
			 ((EQ (CAR X) 'STORE)
			  ((LAMBDA (EFFS ARITHP KTYPE PNOB)
				   (SETQ Z (P1 (CADDR X)))
				   (SETQ MODE (CDR Z) Z (CAR Z) ARITHP () )
				   (AND KTYPE MODE (NOT (EQ MODE KTYPE)) (P1ARG-WRNTYP X))
				   (SETQ X (LIST 'STORE (P1 (CADR X)) Z)))
			      ()  'T  (CDR (NUMTYP (CADR X) () ))  () )
			  (GO P1XIT))
			 ((COND ((EQ (CAR X) 'ARRAYCALL)
				   (AND (NOT ARRAYOPEN)
					(SETQ X (CONS (CONS COMP (CONS 'FUNCALL (CADDR X))) (CDDDR X)))
					(GO P1-START))
				   (AND (NULL (CDDDR X)) (GO WNA))
				   'T)
				((MEMQ (CAR X) '(SUBRCALL LSUBRCALL)) 
				 (P1SQV PROGN)
				 'T))
			  (COND ((OR (NULL (CDR X)) (NULL (CDDR X))) (GO WNA))
				((EQ (SETQ TEM (TYPEP (CADR X))) 'SYMBOL))
				('T (PDERR X |Wrong functional designator|)))
			  (COND ((SETQ MODE (ASSQ (CADR X) COMAL)) 
				 (SETQ MODE (AND (NOT (EQ (CAR MODE) 'T)) (CAR MODE))))
				('T (WARN X |Non-standard type info| 3 5) (SETQ MODE () )))
			  (AND KTYPE MODE (NOT (EQ MODE KTYPE)) (P1ARG-WRNTYP X))
			  (AND (COND ((EQ (SETQ TEM (TYPEP (CADDR X))) 'SYMBOL) 
					(MEMQ (CADDR X) '(T NIL)))
				     ((EQ TEM 'LIST) 
					(MEMQ (CAADDR X) '(QUOTE FUNCTION *FUNCTION)))
				     (T))
			       (PDERR X |The function pointer can't be right|))
			  #%(LET (EFFS ARITHP KTYPE (PNOB 'T))
				(COND ((EQ (CAR X) 'LSUBRCALL)
				       (SETQ X (P1FAKE (CONS (CAR X) (CDDR X))))
				       (RPLACD (SETQ TEM (CADDDR (CDDAR X))) 
					       (CONS MODE (CDR TEM))))
				      ('T (AND (> (LENGTH (CDDDR X)) 5) 
					       (PDERR X |Too many args for SUBRCALL or ARRAYCALL|))
					  (SETQ ARITHP 'T)
					  (SETQ Z (P1 (CADDR X)))
					  (COND ((NULL (CDR Z)))
						('T (PDERR X |Numeric function-ptr?|)))
					  (AND (EQ (CAR X) 'ARRAYCALL) (SETQ  KTYPE 'FIXNUM))
					  (SETQ ARITHP () )
					  (SETQ Z (CONS (CAR Z) (MAPCAR 'P1 (CDDDR X))))
					  (SETQ X (COND ((EQ (CAR X) 'ARRAYCALL) 
							 `(,(car x) ,mode ,. z))
							('T (RPLACA 
							     Z 
							     `(,comp ,mode ,. (car z)))
							    Z))))))
			  (GO P1XIT)) 
			 ((EQ (CAR X) 'ARRAY)
		  	  (SETQ X (CONS '*ARRAY 
					(CONS (LIST 'QUOTE (CADR X))
					      (CONS (LIST 'QUOTE (CADDR X)) (CDDDR X)))))
			  (GO B-LSUBR))
			 ((MEMQ (CAR X) '(STATUS SSTATUS))
			  (SETQ X (CONS (CONS MAKUNBOUND (CONS 'FSUBR (CAR X)))
					(P1STATUS X)))
			  (GO P1XIT))
			 ((MEMQ (CAR X) '(ERRSET *CATCH CATCH-BARRIER CATCHALL 
					  UNWIND-PROTECT CATCH PASS-THRU))
			  #%(LET ((P1VARS LOCVARS) (P1CNT CNT))
				(SETQ Z
				  (P1FAKE 
				    (CASEQ (CAR X) 
					   (ERRSET (LIST 'ERRSET 
							 (LIST 'NCONS (CADR X))
							 (COND ((NULL (CDDR X))) 
							       ((CADDR X)))))
					   ((*CATCH CATCH-BARRIER) X)
					   (CATCHALL (CONS '%CATCHALL 
							   (CONS (CONS 'FUNCALL 
								       (CONS (CADR X) 
									     CAAGL))
								 (CDDR X))))
					   (UNWIND-PROTECT (CONS '%PASS-THRU 
								 (CONS (CONS 'PROGN 
									     (CDDR X))
								       (LIST (CADR X)))))
					   (PASS-THRU (CONS '%PASS-THRU 
							    (CONS (LIST 'FUNCALL (CADR X))
								  (CDDR X))))
					   (CATCH (AND (EQ X 'CATCH) 
						       (WARN X | Obsolete form - please use *CATCH|))
						  (LIST '*CATCH 
							(LIST 'QUOTE (CADDR X)) 
							(CADR X))) )))
				(P1SYNCHRONIZE-CNTS P1CNT P1VARS))
			  (RETURN Z))
			 ((EQ (CAR X) 'THROW)
			  (WARN X | Obsolete form - please use *THROW|)
			  (SETQ X (LIST '*THROW 
					(LIST 'QUOTE (CADDR X))
					(P1VN (CADR X))))
			  (GO P1XIT))
			 ((SETQ TEM (ASSQ (CAR X) '((FUNCTION . QUOTE) (*FUNCTION . *FUNCTION))))
			  (COND ((OR (NULL (CDR X)) (CDDR X)) (GO WNA)))
			  (SETQ X (LIST (CDR TEM) (P1GFY (CADR X) 'EXPR)))
			  (GO P1XIT))
			 ((EQ (CAR X) 'SIGNP) (SETQ X (P1SIGNP X)) (GO P1XIT))
			((EQ (CAR X) 'BREAK)
			 (AND (OR (NULL (CDR X)) (CDDDR X)) (GO WNA))
			 (SETQ X (LIST '*BREAK 
					(COND ((CDDR X) (CADDR X))
					      ('(QUOTE T)))
					(LIST 'QUOTE (CADR X))))
			 (P1SQV PROGN)
			 (GO B-SUBR))
		         ((EQ (CAR X) 'PROGV)
			  (AND (NULL (CDDDR X)) (GO WNA))
			  (RETURN (P1PROGN (CDR X) 'PROGV)))
			 ((EQ (CAR X) 'ERR)
			  (SETQ X (COND ((NULL (CDR X)) '(ERR '() ) )
					((OR (NULL (CDDR X))
					     (AND (CADDR X) (NOT (QNILP (CADDR X)))))
					 (LIST 'ERR (P1VN (CADR X))))
					(X)))
			  (GO P1XIT))
			 ((MEMQ (CAR X) '(DECLARE EVAL-WHEN)) 
			  (PDERR X |Local declaration at wrong place|)
			  (RETURN X))
			('T (AND (NOT (GET X 'ACS)) (P1SQV PROGN))
			    (RETURN (P1MODESET X)))))
		  ((EQ FTYP 'LSUBR)
		   (COND ((MEMQ (CAR X) '(LIST LIST*)) 
			  (COND ((NULL (CDR X)) (GO P1NIL)) 
				((AND (NULL (CDDR X)) (EQ (CAR X) 'LIST*))
				 (SETQ X (CADR X))
				 (GO P1-START)))
			  (SETQ X (P1ITERLIST (CDR X) (EQ (CAR X) 'LIST*)))
			  (COND (ARITHP (RETURN (NCONS (P1VN X)))) 
				((ATOM X) (GO P1-START))
				('T (GO B-SUBR)))))
		   (AND (P1ACK (CAR X) 'LSUBR () (CDR X)) (GO WNA))
		   (AND (EQ (GET (CAR X) 'NOTNUMP) 'EFFS) (P1SQV NULFU))
		   (AND (EQ (CAR X) 'PRINC)
			(CDR X) 
			(SYMBOLP (CADR X))
			(GET (CADR X) '+INTERNAL-STRING-MARKER)
			(SETQ X `(PRINC ',(cadr x) ,.(cddr x))))
		   (COND ((EQ (CAR X) 'PROG2) (RETURN (P1PROG2 (CDR X))))
			 ((EQ (CAR X) 'PROG1) 
			  (RETURN (P1PROG2 (CONS () (CDR X)))))
			 ((EQ (CAR X) 'PROGN) 
			  (RETURN (P1PROGN (COND ((CDR X)) ( '( () ) ))  PROGN)))
			 ((COND ((AND (NULL (CDR X)) 
				      (SETQ Z  (ASSQ (CAR X) '((READ . *READ) 
							       (READCH . *READCH) 
							       (TYI . *TYI)
							       (TERPRI . *TERPRI))))))
				((AND (CDR X) (NULL (CDDR X))
				      (SETQ Z (ASSQ (CAR X) '((PRINT . *PRINT) 
							      (PRIN1 . *PRIN1) 
							      (PRINC . *PRINC) 
							      (TYO . *TYO)))))
				 'T)
				((AND (CDR X) (CDDR X) (NULL (CDDDR X))
				      (OR (SETQ Z (ASSQ (CAR X) '((APPEND . *APPEND)
								  (NCONC . *NCONC)
								  (DELETE . *DELETE)
								  (DELQ . *DELQ))))
					  (AND  (NOT CLOSED)
						(SETQ Z (ASSQ (CAR X) '((GREATERP . *GREAT)
									(LESSP . *LESS)
									(PLUS . *PLUS)
									(DIFFERENCE . *DIF)
									(TIMES . *TIMES)
									(QUOTIENT . *QUO)))))))))
			  ;Fall thru for normal CALL processing after this
			  (SETQ X (CONS (CDR Z) (CDR X))))
			 ((SETQ Z (ASSQ (CAR X) '((MAPCAN (*MAP 0) MAPCON CAR)
						  (MAPCON (*MAP 1) MAPCON LIST)
						  (MAPC (*MAP 2) MAP CAR)
						  (MAP (*MAP 3) MAP LIST)
						  (MAPCAR (*MAP 4) MAPLIST CAR)
						  (MAPLIST (*MAP 5) MAPLIST LIST)
						  (MAPATOMS))))
			  (RETURN (P1MAP (CDR X) Z)))
			 ((EQ (CAR X) 'FUNCALL)
			  (COND ((NULL (CDR X)) (GO WNA)))
			  (SETQ X (COND
				   ((AND 
				     (NOT (ATOM (SETQ Z (CADR X)))) 
				     (SETQ Z (P1FUNGET (CADR X)))
				     (SETQ Z (COND 
					       ((AND (ATOM (CADR Z))
						     (OR (GET (CADR Z) '*FEXPR)
							 (EQ (SYSP (CADR Z)) 'FSUBR)))
						`(APPLY ,.(cdr x)))
					       ((OR (ATOM (CADR Z))
						    (EQ (CAADR Z) 'LAMBDA))
						`(,(cadr z) ,.(cddr x))))))
				    Z)
				   (`((,COMP . (FUNCALL . ,(cadr x))) 
				      ,.(cddr x)))))
			  (GO P1-START))
			 ((AND  (EQ (CAR X) 'BOOLE) 
				(SETQ Z (COND ((ATOM (CADR X)) (CADR X))
					      ((EQ (CAADR X) 'QUOTE) (CADADR X))
					      ((NOT (EQ (SETQ Z (P1MACROGET (CADR X)))
							NULFU))
					       (SETQ X (CONS 'BOOLE (CONS Z (CDDR X))))
					       (GO P1-START))))
				(FIXP Z)
				(NOT (< Z 0))
				(< Z 1_4)))
			  ;Dont need to P1FAKE explicit BOOLE since will be open coded anyway

			 ((EQ (CAR X) '*ARRAY)
			  (COND ((AND (NOT (ATOM (CADR X))) (EQ (CAADR X) 'QUOTE))
				   (AND (COND ((NOT (SYMBOLP (SETQ Z (CADADR X)))))
					      ((AND (GET Z '*ARRAY)
						    (SETQ Z (GET Z 'NUMFUN)))
						(SETQ Y (COND ((MEMQ (CADDR X) '(T NIL)) (CADDR X))
							      ((AND (P1EQQTE (CADDR X))
								    (MEMQ (CADR (CADDR X)) 
									  '(T NIL FIXNUM FLONUM OBARRAY)))
								(CADR (CADDR X)))))
						(COND ((MEMQ Y '(FIXNUM FLONUM)) (NOT (EQ Y (CADR Z))))
						      ((MEMQ (CADR Z) '(FIXNUM FLONUM))))))
					(PDERR X |Contradicts declared type of array|))))
			  (P1SQV PROGN)
			  (RETURN (P1FAKE X)))
			 ((AND (EQ (CAR X) 'HUNK) (< (SETQ TEM (LENGTH (CDR X))) 5))
			  (AND (= TEM 0) (GO P1NIL))
			  (SETQ X (CONS (CASEQ TEM
					       (1 (COND (HUNK2-TO-CONS 'NCONS) 
							('%HUNK1)))
					       (2 (COND (HUNK2-TO-CONS 'CONS) 
							('%HUNK2)))
					       (3 '%HUNK3)
					       (4 '%HUNK4))
					(CDR X)))
			  (GO B-SUBR))
			 ((AND  (EQ (CAR X) 'APPLY)
				(NULL (CDDDR X)) 
				(RETURN (PWTNTPTFN (CDR X)))))
			 ((AND (EQ (CAR X) 'EVAL) (NULL (CDDR X)))
			    (P1SQV PROGN)
			    (SETQ Z (LIST (P1VN (CADR X))))
			    (COND ((AND (NOT (ATOM (CAR Z))) 		;hac for 
					(EQ (CAAR Z) 'CONS)		;(EVAL  (CONS 'FSUBR L))
					(SETQ X (P1F (CADAR Z) (CADDAR Z)))))
				  ('T (SETQ X (CONS '*EVAL Z))))
			    (GO P1XIT))
			 ('T (COND ((GET (CAR X) 'ACS)				;Pass on out the
				    (AND (EQ (GET (CAR X) 'NOTNUMP) 'EFFS)	; severity info, if there
					 (P1SQV NULFU)))				; really are side effects
				   ('T (P1SQV PROGN)))	
			     (RETURN (P1FAKE X)))))
	          ((EQ FTYP 'SUBR)
		   (AND (P1ACK (CAR X) 'SUBR () (CDR X)) (GO WNA))
		   (AND (EQ (CAR X) 'NOT) (SETQ X `(NULL ,.(cdr x))))
		   (SETQ Y 'T)
		   (COND ((EQ (CAR X) 'NULL) 
			  (p1nonumck (cadr x))
			  (SETQ X (let ((EFFS EFFS) ARITHP KTYPE)
				    (COND ((AND (P1BOOL1ABLE (CADR X))
						(OR EFFS (NOT (EQ (CAADR X) 'MEMQ))))
					   (COND (EFFS (LIST 'NULL (P1 (CADR X))))
						 ((P1COND 'COND 
							  `((,x ',*:truth))))))
					  ('T (SETQ EFFS () ) (LIST 'NULL (P1 (CADR X)))))))
			  (GO P1XIT))
			((EQ (CAR X) 'RETURN)  (RETURN (P1RETURN X)))
			((NOT (GET (CAR X) 'ACS))
			 (COND ((EQ (CAR X) 'BOUNDP)
				(SETQ X (LIST 'NOT 
					      (CONS 'EQ (CONS (LIST 'SYMEVAL (CADR X)) 
							      QSM))))
				(GO B-?))
			       ((MEMQ (CAR X) '(ROT LSH ASH FSC))
				(SETQ MODE (COND ((EQ (CAR X) 'FSC) 'FLONUM)
						 ('FIXNUM)))
				#%(LET ((KTYPE (COND ((CDR (NUMTYP (CADR X) 'T)))
						     (MODE)))
					ARITHP EFFS)
				    (SETQ X (LIST (CAR X) 
						  (P1 (CADR X))
						  (PROG2 (SETQ KTYPE 'FIXNUM) 
							 (P1 (CADDR X))))))
				(AND (NOT (ATOM (SETQ TEM (CADDR X))))
				     (EQ (CAR TEM) 'QUOTE)
				     (NOT (NUMBERP (CADR TEM)))
				     (PDERR X |Invalid 2nd arg - must be numeric|))
				(GO P1XIT))
			       ((GET (CAR X) 'P1BOOL1ABLE)
				(AND (MEMQ (CAR X) '(NUMBERP FIXP FLOATP))
				     (SETQ TEM (NUMTYPEP (CADR X) () )) 
				     (COND ((EQ (CAR X) 'FIXP) (EQ (CDR TEM) 'FIXNUM))
					   ((EQ (CAR X) 'FLOATP) (EQ (CDR TEM) 'FLONUM))
					   ((EQ (CAR X) 'NUMBERP) (CDR TEM)))
				     (PROG2 (WARN X |Numeric predicate applied 
 to numeric type datum is a constant| 4 5)
					    (SETQ X `(PROG2 ,(cadr x) ',*:truth))
					    (GO B-LSUBR))))
			       ((EQ (CAR X) 'SET)
				(AND (NOT (ATOM (CADR X))) 
				     (EQ (CAADR X) 'QUOTE)
				     (ATOM (CADADR X))
				     (RETURN (P1 (APPEND (LIST 'SETQ (CADADR X)) (CDDR X))))))
			       ((MEMQ (CAR X) '(CXR RPLACX))
				 (AND (COND ((ATOM (SETQ TEM (CADR X))))
					    ((QNP TEM) (SETQ TEM (CADR TEM)) 'T))
				      (FIXP TEM)
				      (COND ((= TEM 0) (SETQ TEM '(CDR . RPLACD)) 'T)
					    ((= TEM 1) (SETQ TEM '(CAR . RPLACA)) 'T))
				      (SETQ X (CONS (COND ((EQ (CAR X) 'CXR) (CAR TEM)) 
							  ((CDR TEM)))
						    (CDDR X)))
				      (GO B-?)))
			       ((EQ (CAR X) 'SYMEVAL) 
				(RETURN (P1CARCDR (CONS 'CDDAR (CDR X)))))
			       ('T (P1SQV PROGN))))
			((MEMQ (CAR X) '(MEMBER ASSOC SASSOC EQUAL MEMQ))
			  (RETURN (P1LST X)))
			((MEMQ (CAR X) '(NTH NTHCDR))
			 (SETQ Y (CDR X))
			 ((LAMBDA (EFFS ARITHP KTYPE PNOB)
				  (SETQ TEM    (P1 (CAR Y))
					ARITHP (SETQ KTYPE (SETQ PNOB () ))
					Y      (LIST (CAR TEM) (P1 (CADR Y)))))
			     () 'T 'FIXNUM 'T)
			 (SETQ X (COND ((AND (CDR TEM)
					     (QNP (CAR Y)) 
					     (FIXP (SETQ Z (CADAR Y)))
					     (< Z 6)) 
					(AND (< Z 0) 
					     (SETQ Z 0)
					     #%(PDERR X |Negative count to NTH|))
					(SETQ Z #%(NCDR '(D D D D D) (- 5 Z)))
					(AND (EQ (CAR X) 'NTH) (PUSH 'A Z))
					
					(COND ((NULL Z) (CADR Y)) 
					      ('T (LIST (CONS CARCDR (REVERSE Z))
							(CADR Y)))))
				       ((CONS (CAR X) Y))))
			 (GO P1XIT)) 
			((EQ (CAR X) 'MAKNUM) 
			 (AND (CDR (SETQ TEM (P1VAP (CADR X) 'T)))
			      (WARN X |MAKNUM on numeric quantity?| 4 5))
			      (SETQ X (LIST (CONS MAKUNBOUND '(MAKNUM)) 
					    (CAR TEM))
				    MODE 'FIXNUM)
			 (GO P1XIT))
;;;; ######## At one time, some losing code for *FUNCTION was here.
			((EQ (GET (CAR X) 'NOTNUMP) 'EFFS) (P1SQV NULFU))))
		('T (BARF X |Lost function - P1|)) )

  P1-CALL
	;This is for the general function-application (CALL)
     ((LAMBDA (PNOB EFFS ARITHP KTYPE MAPP)
	      (COND ((AND (NOT (EQ FTYP 'JSP)) 
			  (SETQ TEM (GET (CAR X) 'NUMFUN)) 
			  (CDDR TEM))
		     (SETQ MODE (CADR TEM) 	TEM (CDDR TEM)
			   Z ()  		ARITHP 'T)
		     (SETQ Z (MAPCAR 
			      '(LAMBDA (ITEM) 
				  (SETQ MAPP (COND ((ATOM ITEM) () )
						   ((MEMQ (CAR ITEM) 
							  '(MAP MAPC MAPLIST MAPCAR 
							    MAPCAN MAPCON MAPATOMS)))))
				  (SETQ KTYPE (CAR TEM) TEM (CDR TEM))
				  (SETQ ITEM (P1 ITEM))			;TEM IS LIST OF DECLARED ARG TYPES
				  (COND (Z ITEM)			;Z IS FLAG TO INDICATE MIS-MATCH 
					((COND  ((NULL KTYPE) () )
						((CDR ITEM) (NOT (EQ KTYPE (CDR ITEM))))
						(MAPP)
						((NOTNUMP (CAR ITEM))))
					 (P1ARG-WRNTYP X)
					 (SETQ Z 'T ARITHP () )
					 (CAR ITEM))
					((CAR ITEM))))
			      (CDR X)))
		     (SETQ X (CONS (CAR X) Z))
		     (GO P1XIT))
		    ('T (AND (EQ FTYP 'SUBR) (NULL Y) (SETQ PNOB () ))
			(SETQ Z (MAPCAR 'P1 (CDR X))))))
	'T () () () () )
     (RETURN (P1MODESET (CONS (CAR X) Z)))


 WNA    #%(PDERR X |Wrong number of args|)
 P1NIL  (RETURN (COND (ARITHP '('() . () ) ) ( ''() )))
 P1XIT  (RETURN (COND (ARITHP (CONS X MODE)) (X)))  ))




(DEFUN PWTNTPTFN (X)							;Page Width Too Narrow To Print This Function's Name
   (LET ((NARGS 0) (FUN (P1FUNGET (CAR X))) VAR FL FORM)
	(COND ((COND ((OR (NULL FUN) (NULL (SETQ FUN (CADR FUN))))	;Find form like 
		      () )						;(APPLY (FUNCTION 
		     ((NOT (ATOM FUN))					;        (LAMBDA (A B) FOO))
		      (COND ((NOT (EQ (CAR FUN) 'LAMBDA)) () )		;       BAR)
			    ((OR (NOT (ATOM (SETQ FORM (CADR FUN))))	;LAMBDA list
				 (NULL FORM))
			     (SETQ NARGS (LENGTH FORM))
			     'T)))
		     ((AND (EQ (SYSP FUN) 'SUBR) (SETQ FORM (ARGS FUN)))
			(SETQ NARGS (CDR FORM))				;# of args to function
			'T))
	       (SETQ VAR (CADR X))
	       (AND (> NARGS 1)						;2 or more LAMBDA vars in
		    (NOT (ATOM VAR))					;some complexly-computed list
		    (NOT (EQ (CAR VAR) 'QUOTE))
		    (NOT (P1CARCDR-CHASE VAR))
		    (SETQ VAR (GENSYM) FL 'T))
	       (SETQ FORM (CONS FUN 
				(DO ((A VAR (LIST 'CDDDDR A)) (Z))
				    ((NOT (> NARGS 0))  (NREVERSE Z))
				  (DO ((N (COND ((> NARGS 4) 4) (NARGS)) (1- N)) 
				       (FUN '(CAR CADR CADDR CADDDR) (CDR FUN)))
				      ((NOT (> N 0)))
				      (SETQ NARGS (1- NARGS))
				      (PUSH (LIST (CAR FUN) A) Z)))))
	       (AND FL (SETQ FORM (LIST (LIST 'LAMBDA (LIST VAR) FORM)
					(CADR X))))
	       (P1 FORM))
	      ('T (P1SQV PROGN)
		  (SETQ FORM (MAPCAR 'P1VN X))
		  (SETQ FORM (COND ((P1F (CAR FORM) (CADR FORM)))
				   ((CONS '*APPLY FORM))))
		  (COND (ARITHP (NCONS FORM)) (FORM))))))



(DEFUN P1ACK (NAME TYPE FL L)							;P1 args check
   #%(LET ((AARGS (OR (ARGS NAME) (GET NAME 'ARGS))) TEM) 
	 (COND ((NULL AARGS) 
		(AND FL (PUTPROP NAME FL 'ARGS)) 
		() )
	       ('T (AND (OR (NULL L) (NOT (ATOM L))) (SETQ L (LENGTH L)))
		   (SETQ TEM (COND ((NULL (CAR AARGS)) 
				    (OR (AND TYPE (NOT (EQ TYPE 'SUBR))) 
					(NOT (= (CDR AARGS) L))))
				   ((OR (AND TYPE (NOT (EQ TYPE 'LSUBR))) 
					(< L (CAR AARGS)) 
					(> L (CDR AARGS)))
				    'T)))
		   (AND (AND FL TEM) 
			#%(WARN NAME |Has been previously used with wrong number of arguments|))
		   TEM ))))



(DEFUN P1ARG-WRNTYP (X) 
   #%(PDERR (LIST X 'NOT-OF-TYPE KTYPE) 
	   |First item in list is an argument somewhere, but is of the wrong type|))


(COMMENT P1ANDOR and P1ARITH)

(DEFUN P1ANDOR (X ORP)
    (PROG (Z)
	(COND ((NULL (CDR X)) (RETURN (P1 (NOT ORP))))
	      ((NULL (CDDR X)) (RETURN (P1 (CADR X))))
	      (EFFS (RETURN (P1COND (CAR X) (CDR X)))))
	(SETQ Z (COND (ORP (MAPCAR 'NCONS (CDR X)))
		      ('T (SETQ Z (L2F (CDR X)))				;Convert (AND A B C)
			  (LIST (LIST (CONS 'AND (CDR Z)) (CAR Z))))))		; into (COND ((AND  B) C))
	(RETURN (P1COND 'COND Z))))


(DEFUN P1ARITH (XPR ARITHFUNP NUMBERP)
 (P1SQE (PROG (TYP TEMP TEM FUN SAVXPR KNOW-ALL-TYPES P1LSQ LMBP CONDP P1LL PNOB)
	      (SETQ FUN (CAR XPR) LMBP T SAVXPR XPR)
	      (AND NUMBERP (MEMQ FUN '(EQ EQUAL)) (GO EXAMINE-ARGS))
	      (AND NUMBERP 
		   (SETQ TEM (ASSQ FUN '((*PLUS . PLUS) 
					 (*TIMES . TIMES)
					 (*DIF . DIFFERENCE)
					 (*QUO . QUOTIENT)
					 (*LESS . LESSP)
					 (*GREAT . GREATERP))))
		   (SETQ FUN (CDR TEM)))
	      (AND (NULL (CDDR XPR))
		   (NULL (ARGS FUN))
		   (SETQ TEM (COND ((OR (AND NUMBERP (MEMQ FUN '(PLUS DIFFERENCE)))
					(AND ARITHFUNP (MEMQ FUN '(+ +$ - -$))))
				    '('0 . '0.0))
				   ((OR (AND NUMBERP (MEMQ FUN '(TIMES QUOTIENT)))
					(AND ARITHFUNP (MEMQ FUN '(* *$ // //$))))
				    '('1 . '1.0))))
		    ;Case of 0 or 1 arguments to rational function
		    ;Note that "(car tem)" and "(cdr tem)" can be used as P1 output
		   (COND ((AND ARITHFUNP (CDR XPR))
			  (COND ((MEMQ FUN '(- -$ // //$))
				 (SETQ XPR `(,fun ,(cond ((memq fun '(-$ //$)) 
							  (cdr tem))
							 ((car tem)))
						   ,(cadr xpr))))
				('T 
				 (SETQ TYP (CADR ARITHFUNP)
				       XPR (P1VN `(,(cond ((eq typ 'FIXNUM)
							   'FIXNUM-IDENTITY)
							  ('FLONUM-IDENTITY))
						   ,(cadr xpr))))
				 (GO XITF) )))
			 ('T 
			  (SETQ XPR (COND ((CDR XPR) (P1VN (CADR XPR)))
					  ((MEMQ FUN '(+$ -$ *$ //$)) 
					   (CDR TEM))	;Constants appear to be
					  ((CAR TEM)))) ; Already P1'd!
			  (GO XITF))))
	      (COND ((SETQ TEMP (COND ((AND ARITHFUNP (NULL (CADR ARITHFUNP)))
				       (GO EXAMINE-ARGS))
				      (ARITHFUNP)				;type is pre-determined
				      ((AND NUMBERP CLOSED) () )		;so processing is easy
				      (FIXSW `(,fun FIXNUM))
				      (FLOSW `(,fun FLONUM)) ))
		     (SETQ TYP (CADR TEMP))
		     (SETQ XPR `(,(car temp) ,typ 
					    ,. #%(let (arithp effs (ktype typ)) 
						     (mapcar 'p1 (cdr xpr)))))
		     (AND (EQ NUMBERP 'NOTYPE) (SETQ TYP () ))
		     (COND ((EQ (CAR XPR) IDENTITY))
			   ((SETQ TEM (P1AEVAL FUN (CDDR XPR) SAVXPR TYP))
			    (COND ((EQ (CAR TEM) 'QUOTE)
				   (SETQ XPR (CDR TEM)) 
				   (GO XITF))
				  ('T (SETQ XPR `(,(car xpr) ,(cadr xpr) ,.(cdr tem)))))))
		     (SETQ KNOW-ALL-TYPES 'T)
		     (AND (EQ FUN 'DIFFERENCE)			; (DIFFERENCE <type> 0 X) ==>
			  (Q0P+0P (CAR (SETQ TEMP (CDDR XPR))))	; (MINUS <type> X)
			  (NULL (CDDR TEMP))
			  (SETQ XPR `(MINUS ,typ ,.(cdr temp))))
		     (GO XITF)))
	      (AND (GET FUN 'LSUBR) (SETQ PNOB 'T))

	   EXAMINE-ARGS 
	      #%(LET ((ARITHP 'T) EFFS KTYPE)
		    (COND ((AND ARITHFUNP (NULL (CADR ARITHFUNP)))		;Seek special action
			   (SETQ KTYPE (CDR (NUMTYP (CADR XPR) 'T)) 		; on =, >, and  <
				 TYP (CDR (NUMTYP (CADDR XPR) 'T)))
			   (COND ((AND (NULL KTYPE) (NULL TYP))			;Sigh! No info
				  #%(LET ((P1CNT CNT) (LL LOCVARS)		; from numtypep!
					 (LLL (MAPCAR 'CDR LOCVARS))
					 ARG1 ARG2 T1 T2)
					(SETQ ARG1 (P1 (CADR XPR))
					      T1 (CDR ARG1))
					(COND (T1 (SETQ KTYPE T1 
							ARG2 (P1 (CADDR XPR))))
					      ('T (SETQ ARG2 (P1 (CADDR XPR)) 
							T2 (CDR ARG2)
							KTYPE 
							  (COND (T2) 
								(FLOSW 'FLONUM)
								(FIXSW 'FIXNUM)
								('FIXNUM)))
						  (SETQ CNT P1CNT LOCVARS LL)
						  (MAPC 'RPLACD LOCVARS LLL)
						  (SETQ ARG1 (P1 (CADR XPR)) 
							ARG2 (P1 (CADDR XPR)))))
					(AND (NOT (MEMQ KTYPE '(FIXNUM FLONUM))) 
					     #%(PDERR SAVXPR |Mixed modes|))
					(SETQ XPR (LIST (CAR ARITHFUNP) 
							KTYPE 
							(CAR ARG1) 
							(CAR ARG2))) )
				  (SETQ TYP () )			 	;Resultant is of NOTYPE
				  (GO XITF))
				 ('T (SETQ KTYPE (COND ((NULL KTYPE) TYP)	;KTYPE is set to ()
						       ((NULL TYP) KTYPE)	; only if a conflict is found
						       ((EQ KTYPE TYP)
							(SETQ TEM 
							      (CDR (P1AEVAL 
								    FUN 
								    (CDR XPR) 
								    SAVXPR 
								    () )))
							(AND TEM
							     (SETQ XPR TEM)
							     (GO XITF))
							KTYPE))))))
			  ((AND (EQ NUMBERP 'NOTYPE) 
				(MEMQ FUN '(PLUSP MINUSP ZEROP)))
			   (SETQ KTYPE (OR (CDR (NUMTYP (CADR XPR) 'T)) 
					   'FIXNUM))))
		    (SETQ TYP () )
		    (SETQ XPR (MAPCAR '(LAMBDA (X)
					   (SETQ X (P1 X))
					   (PUSH (OR (CDR X) KTYPE) TYP)
					   (CAR X))
				      (CDR XPR))
			  TYP (SAMETYPES TYP))
		    (OR (MEMQ TYP '(() FIXNUM FLONUM))
			(SETQ TYP (NREVERSE TYP))) )
	      (SETQ XPR (CONS FUN (CONS TYP XPR)))
	      (COND (ARITHFUNP							;Catches  =, <, >
		     (AND (CADR ARITHFUNP) 
			  (BARF SAVXPR |ARITHP function came too far - P1ARITH|))
		     (AND (NOT (MEMQ TYP '(FIXNUM FLONUM))) 
			  #%(PDERR SAVXPR |Mixed modes|))
		     (RPLACA XPR (CAR ARITHFUNP))
		     (RPLACA (CDR XPR) TYP)
		     (SETQ TYP () )
		     (GO XITF)))
	      (SETQ KNOW-ALL-TYPES #%(KNOW-ALL-TYPES TYP))
	   A-EQ
	      (CASEQ FUN 
		     (EQUAL
		      (COND ((COND (KNOW-ALL-TYPES (NOT (ATOM TYP)))
				   ((NULL TYP) () )
				   ((NOTNUMP (COND ((CADDR TYP) (CADDDR XPR))
						   ('T (CADDR XPR))))
				    (RPLACA (CDR XPR) () )
				    'T))
			     (WARN SAVXPR |This EQUAL test will never come up true| 4 5))
			    ((AND (NOT KNOW-ALL-TYPES) TYP) 
			     (RPLACA (CDR XPR) () ))
			    ((OR (P1EQQTE (CADDR XPR)) (P1EQQTE (CADDDR XPR)))
			     (RPLACA XPR 'EQ)
			     (RPLACA (CDR XPR) (SETQ TYP () ))))
		      (GO XIT))
		     (EQ 
		      (COND (TYP (WARN SAVXPR |EQ of a number - EQUAL assumed| 4 5)
				 (RPLACA XPR (SETQ FUN 'EQUAL))
				 (GO A-EQ)))
		      (GO XIT))
		     (FLOAT
		      (COND ((EQ TYP 'FLONUM) (SETQ XPR (CADDR XPR)))
			    ((EQ TYP 'FIXNUM)
			     (SETQ TEM (P1AEVAL FUN (CDDR XPR) SAVXPR () ))
			     (AND TEM (SETQ XPR (CDR TEM)))))
		      (SETQ TYP 'FLONUM)
		      (GO XITF))
		     ((FIX IFIX)
		      (AND (EQ KTYPE 'FLONUM) 
			   (PROG2 (P1ARG-WRNTYP SAVXPR) (SETQ TYP () )))
		      (COND ((EQ TYP 'FIXNUM) (SETQ XPR (CADDR XPR)) (GO XITF))
			    ((EQ TYP 'FLONUM)
			     (SETQ TEM (P1AEVAL FUN (CDDR XPR) SAVXPR () ))
			     (AND TEM 
				  (EQ (TYPEP (CADR (SETQ TEM (CDR TEM)))) 
				      'FIXNUM)
				  (SETQ XPR TEM TYP 'FIXNUM)
				  (GO XITF))))
		      (SETQ TYP (COND ((OR (EQ KTYPE 'FIXNUM) FIXSW)
				       (RPLACA XPR (SETQ FUN 'IFIX))
				       'FIXNUM)
				      ((EQ FUN 'IFIX) 'FIXNUM)))
		      (GO XITF)))
	      (AND (COND ((EQ FUN 'REMAINDER)
			  (COND ((EQ TYP 'FIXNUM) () )
				('T (SETQ KNOW-ALL-TYPES () TYP () )
				    (RPLACA (CDR XPR) () )
				    'T)))
			 ((AND (NOT KNOW-ALL-TYPES) (NOT CLOSED))))
		   (NOT MUZZLED)
		   #%(WARN SAVXPR |Closed compilation forced| 4 5))
	      (COND ((AND (NOT KNOW-ALL-TYPES)					;Convert (PLUS A B)
			  (CDDDR XPR) 						;into (*PLUS A B)
			  (NULL (CDDDDR XPR))					;If not open-coded
			  (SETQ TEMP (MEMASSQR (CAR XPR) '((*PLUS . PLUS) 
							 (*TIMES . TIMES)
							 (*DIF . DIFFERENCE)
							 (*QUO . QUOTIENT)
							 (*LESS . LESSP)
							 (*GREAT . GREATERP)))))
		     (SETQ XPR (CONS (CAAR TEMP) (CDR XPR))))
		    ((AND (NOT KNOW-ALL-TYPES) 		;This should exclude 
			  (GET (CAR XPR) 'LSUBR))	; PLUS TIMES etc.
		     (SETQ XPR (P1GLM1 () 
				       XPR 
				       0 
				       (COND ((MEMQ 'FLONUM TYP) 'FLONUM)	;CONTAGIOUS FLOATING
					     (KTYPE))
				       () ))
		     (SETQ CNT (1+ CNT))
		     (SETQ TYP (AND ARITHP (PROG2 () (CDR XPR) (SETQ XPR (CAR XPR)))))
		     (SETQ XPR (LIST XPR))
		     (GO XITF))
		    ((AND KNOW-ALL-TYPES 
			  (SETQ TEM (P1AEVAL FUN (CDDR XPR) SAVXPR () )))
		     (SETQ XPR (CDR TEM))
		     (GO XITF)))
	      (COND ((AND (CDR (SETQ TEM (CDDR XPR)))				;Precisely 2 args
			  (NULL (CDDR TEM))
			  (MEMQ FUN '(*DIF DIFFERENCE *PLUS PLUS 		; to rational op
				      *TIMES TIMES *QUO QUOTIENT))
			  (OR (Q0P+0P (CAR TEM)) 
			      (Q0P+0P (CADR TEM))
			      (Q1P+1P-1P (CAR TEM))
			      (Q1P+1P-1P (CADR TEM))))
		     (COND ((AND (NOT KNOW-ALL-TYPES)				;rational op, merely
				 (MEMQ 'FLONUM TYP)) 				;to cause FLOATing,
			    (AND (COND ((COND ((NOT (EQ (CAR TYP) 'FLONUM))
					       () ) 
					      ((MEMQ FUN '(*PLUS PLUS)) 
					       (Q0P+0P (CAR TEM)))
					      ((MEMQ FUN '(*TIMES TIMES))
					       (AND (Q1P+1P-1P (CAR TEM))
						    (= (CADR (CAR TEM)) 1.0))))
					(SETQ XPR (CADR TEM) TYP (CADR TYP))
					'T)
				       ((COND ((NOT (EQ (CADR TYP) 'FLONUM))
					       () ) 
					      ((MEMQ FUN '(*PLUS PLUS *DIF DIFFERENCE)) 
					       (Q0P+0P (CADR TEM)))
					      ((MEMQ FUN '(*TIMES TIMES *QUO QUOTIENT))
					       (AND (Q1P+1P-1P (CADR TEM))
						    (= (CADR (CADR TEM)) 1.0))))
					(SETQ XPR (CAR TEM) TYP (CAR TYP))
					'T))
				 (SETQ XPR `(FLOAT ,typ ,xpr) FUN 'FLOAT)
				 (GO A-EQ)) )
			   ((AND KNOW-ALL-TYPES (MEMQ TYP '(FIXNUM FLONUM)))
			    (AND (COND ((COND ((NOT (MEMQ FUN '(*DIF DIFFERENCE))) () )
					      ((Q0P+0P (CAR TEM))
					       (SETQ FUN 'MINUS TEM (CADR TEM))
					       'T)
					      ((SETQ TEMP (Q1P+1P-1P (CADR TEM)))
					       (SETQ FUN (COND ((PLUSP TEMP) 'SUB1) ('ADD1))
						     TEM (CAR TEM))
					       'T)))
				       ((COND ((NOT (MEMQ FUN '(*PLUS PLUS))) () ) 
					      ((SETQ TEMP (Q1P+1P-1P (CADR TEM))) 
					       (SETQ TEM (CAR TEM))
					       'T)
					      ((SETQ TEMP (Q1P+1P-1P (CAR TEM))) 
					       (SETQ TEM (CADR TEM))
					       'T))
					(SETQ FUN (COND ((PLUSP TEMP) 'ADD1) ('SUB1)))
					'T))
				 (SETQ XPR `(,fun ,typ ,tem)) 
				 (GO XITF))))))

	XIT   (SETQ TYP (COND ((EQ FUN 'HAULONG) 'FIXNUM)
			      ((EQ NUMBERP 'NOTYPE) 
				(AND (NULL EFFS) KTYPE (P1ARG-WRNTYP SAVXPR))
				())
			      (CLOSED (RPLACA (CDR XPR) () ) () )		;All ARITHP types taken earlier
			      ((ATOM TYP) (OR TYP KTYPE))			;Only NUMBERP types come here
			      ((MEMQ 'FLONUM TYP) 'FLONUM)
			      ((AND (MEMQ 'FIXNUM TYP)
				    (OR (EQ FUN 'REMAINDER)
				        (AND (EQ FUN 'GCD) (CAR TYP) (CADR TYP))))
			        'FIXNUM)
			      (KTYPE)))
	XITF  (AND ARITHP (SETQ XPR (CONS XPR TYP)))
	      (RETURN P1LSQ)))
 XPR)


(DEFUN P1AEVAL (FUN ARGL SAVXPR TYP)						;Called only 
   (PROG (TEM VAL OTHERS ALL-CNSTNTS-P LOSERP COMMUP NO-CNSTNTS)		; by "P1ARITH"
	 (DECLARE (FIXNUM NO-CNSTNTS))
	 (SETQ NO-CNSTNTS 0
	       ALL-CNSTNTS-P 'T 
	       COMMUP (MEMQ FUN '(TIMES PLUS)))
	 (MAPC '(LAMBDA (X)
		  (COND ((OR (ATOM X) (NOT (EQ (CAR X) 'QUOTE)))	;Already P1'd
			 (SETQ ALL-CNSTNTS-P () ))
			((NOT (NUMBERP (CADR X)))
			 (AND (NOT (EQ (CAADR X) SQUID))
			      (SETQ LOSERP 'T))
			 (SETQ ALL-CNSTNTS-P () ))
			('T (SETQ NO-CNSTNTS (1+ NO-CNSTNTS)))))
	       ARGL)
	 (COND ((AND (NOT LOSERP)
		     ALL-CNSTNTS-P 
		     (ERRSET (SETQ LOSERP 'T
				   TEM (EVAL (CONS FUN ARGL))) 
			     () )
		     (OR (NULL TYP) (EQ (TYPEP TEM) TYP)))
		(RETURN `(QUOTE . ',tem)))
	       ((AND (NOT LOSERP)		;Partial computations of
		     (NOT ALL-CNSTNTS-P)	; constants - like (+ 3 x 4)
		     TYP 			; but dont try on predicates
		     (> NO-CNSTNTS 1)		; or mixed modes.
		     (NOT (MEMQ FUN '(// //$ QUOTIENT *QUO)))
		     (ERRSET 
		      (PROGN 
		       (cond ((setq tem (cdr (assq fun '((- . +) 
							 (-$ . +$) 
							 (DIFFERENCE . PLUS)
							 (*DIF . PLUS)))))
			      (setq tem (P1AEVAL tem (cdr argl) savxpr typ))
			      (cond ((and (eq (car tem) 'QUOTE)
					  (eq (typep (caddr tem)) typ))
				     (setq tem (list (cdr tem))))
				    ((eq (car tem) 'ARGS)
				     (setq tem (cdr tem))))
			      (and tem
				   (setq argl `(,(car argl) ,.tem))))
			     ('T (SETQ LOSERP 'T OTHERS () TEM  ()) 
				 (MAPC 
				   '(LAMBDA (X) 
				      (COND ((OR (ATOM X) 
						 (NOT (EQ (CAR X) 'QUOTE))
						 (NOT (NUMBERP (CADR X))))
					     (PUSH X OTHERS))
					    ((NULL TEM) (SETQ TEM (CADR X)))
					    ('T (SETQ TEM (FUNCALL FUN TEM (CADR X))))))
				   ARGL)
				 (cond ((EQ (TYPEP TEM) TYP) 
					(setq argl `(',tem ,.(nreverse others)))
					(setq tem 'T))
				       ('T (setq tem () )))))
		       'T)
		      () )
		     tem)
		(RETURN `(ARGS ,.argl)))
	       (LOSERP 
		(PDERR SAVXPR |Illegal arithmetic construction|)
		(RETURN (OR (CDR (ASSQ TYP '((FIXNUM . (QUOTE . '0)) 
					     (FLONUM . (QUOTE . '0.0)))))
			    '(QUOTE . '() )))))))




(COMMENT P1BINDARG and P1BOOL1ABLE)

(DEFUN P1BINDARG (SPFL VAR OARG KTYPE)
  ((LAMBDA (TYP ARG ARITHP PNOB EFFS)
        (COND ((GET VAR '+INTERNAL-STRING-MARKER)
	       (PDERR (LIST VAR OARG)
		      |Pseudo-strings aren't good lambda variables|)))
	(SETQ TYP KTYPE)
	(COND ((AND SPFL (NULL TYP)) (SETQ ARITHP () ) (P1 OARG))	;SPECIAL, non-numeric var
	      (TYP 
		(SETQ ARG (P1 OARG))
		(COND ((COND ((CDR ARG) (NOT (EQ (CDR ARG) TYP)))
			     ((QNILP (CAR ARG))
			      #%(WARN (LIST VAR OARG) 
				     |Binding number variable to NIL may be a bug|)
			      () )
			     ((NOTNUMP (CAR ARG))))
			(PDERR (LIST VAR OARG) 
				|Binding number variable to quantity of wrong type|)
			(COND ((EQ TYP 'FIXNUM) ''1) (''1.0)))
		      ((CAR ARG))))
	      ((COND ((NULL (SETQ ARG (NUMTYP OARG () ))) () )			;Local-list-type-var being
		     ((EQ (SETQ TYP (TYPEP (CAR ARG))) 'SYMBOL) 		; bound to something that 
		      (NOT (SPECIALP (CAR ARG))))				; just might be a PDLNUM
		     ((EQ TYP 'LIST) (NOT (EQ (CAAR ARG) 'COND)))
		     ((NOT (MEMQ TYP '(FIXNUM FLONUM)))))
		(SETQ ARG (P1 OARG))
		(NLNVEX VAR 
			(COND ((CDR ARG) 
				 (SETQ CNT (+ CNT 2))
				 (CADR (SETQ ARG (LIST 'SETQ (NLNVCR VAR (CDR ARG)) (CAR ARG)))))
			      ('T (P2UNSAFEP (SETQ ARG (CAR ARG))))))
		ARG)
	      ('T (SETQ PNOB VAR ARG (P1 OARG) OARG (P2UNSAFEP (CAR ARG)))
		  (AND OARG 
		       (OR (NOT (ATOM OARG)) (NUMERVARP OARG))			;See note below
		       (NLNVEX VAR OARG))
		  (CAR ARG))))
    () () 'T () () ))

;;; Note: We dont want a var X to get unsafe just because it occurs somewhere (SETQ X Y)
;;;  and Y is unsafe [where both X and Y are LLTVS

(DEFUN P1BOOL1ABLE (X) 
    (COND ((OR (ATOM X) (NOT (ATOM (CAR X)))) () )
	  ((EQ (CAR X) 'PROG2) (AND (NULL (CDDDR X)) (P1BOOL1ABLE (CADDR X))))
	  (((LAMBDA (PROP) 
		    (COND ((NULL PROP) () )
			  ((EQ PROP 'NUMBERP)
			   (COND ((AND P2P (MEMQ (CADR X) '(FIXNUM FLONUM))) X)
				 (CLOSED () )
				 ((NULL P2P) X)))
			  ('T X)))				;PROP must be either T or A fixnum here
	     (GET (CAR X) 'P1BOOL1ABLE)))))
;;; On P1, when it is the "numberp" case such as "PLUSP, or "GREATERP",
;;;   this may answer yes falsely, since we dont know whether or not 
;;;   all the arithmetics are of the same type
		
(DEFUN P1BASICBOOL1ABLE (X) (AND (SETQ X (P1BOOL1ABLE X)) (NOT (MEMQ (CAR X) '(AND OR MEMQ COND)))))




(COMMENT P1CARCDR)

(DEFUN P1CARCDR (X)
    (PROG (Y TEM)
	(COND ((OR (NULL (CDR X)) (CDDR X)) 
		#%(PDERR X |Wrong number of arguments|)
		(SETQ Y ''() ) (GO XIT)))
	(SETQ Y (P1VAP (CADR X) () ))
	(AND (CDR Y)
	     (PDERR X |Attempt to take CAR or CDR of a numeric quantity|))
	(SETQ Y (CAR Y))
	(COND ((AND (SETQ TEM (NOT (ATOM Y)))		;(CAR (CDR X))
		    (NOT (ATOM (CAR Y)))		;GOES FIRST INTO
		    (EQ (CAAR Y) CARCDR))		;(CAR ((CARCDR D) X)) THEN TO
	       (NCONC (CAR Y) (P1CCEXPLODE (CAR X))))	;((CARCDR D A) X)
	      ((AND TEM (EQ (CAR X) 'CDR) (EQ (CAR Y) 'RPLACD))
	       (SETQ Y (CONS (CONS MAKUNBOUND '(RPLACD)) (CDR Y))))
	      ('T (SETQ Y (LIST (CONS CARCDR (P1CCEXPLODE (CAR X))) Y))))
   XIT	(RETURN (COND (ARITHP (NCONS Y)) (Y)))))

(DEFUN P1CARCDR-CHASE (X) 
    (COND ((ATOM X) X)
	  ((NULL (CDR X)) () )
	  ((CDDR X) () )
	  ((AND (SYMBOLP (CAR X)) (|carcdrp/|| (CAR X))) 
	    (P1CARCDR-CHASE (CADR X)))))

(DEFUN P1CCEXPLODE (FUN)
    (DO ((FUN (|carcdrp/|| FUN) (|carcdrp/|| FUN)) (L))
	((NULL FUN) L)
      (PUSH (CAR FUN) L)
      (SETQ FUN (CADR FUN))))


(DEFUN P1ITERLIST (L FL)
    (COND ((NULL (CDR L)) (COND (FL (CAR L)) ((LIST 'NCONS (CAR L)))))
	  ('T (LIST 'CONS (CAR L) (P1ITERLIST (CDR L) FL)))))


(COMMENT P1COND)

;;; The CONDTYPE var has a rigid format - see P1TYPE-ADD

(DEFUN P1COND (FUN X)
    (PROG (P1VARS P1CNT BODY CONDTYPE CONDUNSF CONDPNOB 
		CONDP P1CSQ LMBP P1LSQ P1CCX ARITHP)
	  (SETQ P1VARS LOCVARS P1CNT CNT CONDP 'T P1CCX 0)
	  (SETQ BODY (XCONS (MAPLIST '(LAMBDA (X) 
					(IF (EQ FUN 'COND) 
					    (P1CDC (CAR X) X)
					    (P1AOC X))) 
				     X)
			    (COND ((NOT (EQ FUN 'COND)) () )
				  ((NULL (CDR CONDTYPE)) KTYPE)
				  ((NULL KTYPE) 
				   (COND ((CDDR CONDTYPE) () )
					 ((AND (CAR CONDTYPE) 
					       (EQ (CAR CONDTYPE) (CADR CONDTYPE)))
					  (CAR CONDTYPE))
					 (CONDTYPE)))
				  ((OR (CDDR CONDTYPE)
				       (NOT (EQ KTYPE (CADR CONDTYPE)))
				       (AND (CAR CONDTYPE) 
					    (NOT (EQ KTYPE (CAR CONDTYPE)))))
				   (PDERR (CONS FUN X) |COND has clause of wrong numeric type|)
				   () )
				  (KTYPE))))
	  (SETQ X (CONS FUN (CONS P1CCX (CONS P1CSQ (CONS CONDUNSF BODY)))))
	  (P1SYNCHRONIZE-CNTS P1CNT P1VARS))
   (P1SQE (CADDR X))
   (COND (ARITHP (OR (ATOM (SETQ FUN (CADDDR (CDR X)))) (SETQ FUN () )) (CONS X FUN))
	 (X)))

(DEFUN P1AOC (J)
;;;   Compile a piece in an AND-OR clause, or the first part of a COND clause
    (COND ((P1BOOL1ABLE (CAR J)) (P1E (CAR J)))	
	   ;If MEMQ is not BOOL1ABLE, then it would need a special check in
	   ; order for (MEMQ X '(A B)) to go into (OR (EQ X A) (EQ X B)).
	  ('T (and (cdr j) (p1nonumck (car j)))
	      (P1VN (car J)))))

(defun p1nonumck (j)
   (if (numtypep j () )
       (WARN j |Using this numeric quantity in a predicate position| 3 5))
   () )

(DEFUN P1CDC (J clauses)  ;P1s COND clause analyzer
    (COND ((NOT (EQ (TYPEP J) 'LIST)) 
	   (PDERR J |Random COND clause|)
	   '( '() ) )
	  ((COND ((NULL (CDR J)))
		 ((CDDR J) () )						;Singleton COND clause, or
		 ((AND  (OR (EQ (CADR J) 'T)				; like ((EQ X Y) T) or
			    (AND (NOT (ATOM (CADR J)))			; ((NULL BARF) (QUOTE T))
				 (EQ (CAADR J) 'QUOTE)
				 (EQ (CADADR J) 'T)))			;All converted to singleton
			(P1BASICBOOL1ABLE (CAR J)))			; like (foobar)
		  (SETQ J (LIST (CAR J)))
		  'T))
	      (COND ((ATOM (CAR J)) 
		      (if (cdr clauses) (p1nonumck (car j)))
		      (P1CJ J))
		    ((MEMQ (CAAR J) '(GO RETURN)) (P1CDC (CONS 'T J) clauses))
		    (EFFS (if (cdr clauses) (p1nonumck (car j)))
			   ;; Note that P1AOC wont check here, since (null (cdr j)) 
			  (LIST (P1AOC J)))
		    ((OR (P1BASICBOOL1ABLE (CAR J))
			 (AND (EQ (CAAR J) 'OR)
			      (CDAR J)
			      (CDDAR J)
			      (P1BASICBOOL1ABLE (CADDAR J))
			      (P1BASICBOOL1ABLE (CADR J))))
		     (CONS (P1E (CAR J)) (P1CJ '(T))))
		    ('T (P1CJ J))))
	  ((AND (NOT EFFS)
		(NULL (CDDR J))						;((NULL FOO) () )
		(OR (EQ (CAAR J) 'NULL) (EQ (CAAR J) 'NOT))
		(OR (NULL (CADR J)) (QNILP (CAAR J)))
		(OR (NOT (P1BOOL1ABLE (CADAR J))) (EQ (CAADAR J) 'MEMQ)))
	   (p1nonumck (cadar j))
	   (NREVERSE (CONS NULFU (P1CJ (CDAR J)))))
	  ('T 
	   (IF (AND (NULL (CDR CLAUSES)) (NUMBERP (CAR J)))
	       (SETQ J `(',(car j) ,. (cdr j))))
	   (CONS (P1AOC J) 
		 (COND ((NULL (CDDR J)) (P1CJ (CDR J)))
		       ('T (SETQ J (L2F (CDR J)))
			   (NRECONC (DO ((LL (CDR J) (CDR LL))
					 (Z) (ARITHP) (EFFS 'T) (KTYPE))
					((NULL LL) Z )
					(PUSH (P1 (CAR LL)) Z))
				    (P1CJ J))))))))


(DEFUN P1CJ (J)
     ((LAMBDA (ARITHP MODE FL)
	      (SETQ J (P1 (CAR J)))
	      (COND (ARITHP 
		     (SETQ MODE (CDR J) J (CAR J))
		     (SETQ P1CCX (PLUS P1CCX (P1TRESS J)))
		     (COND ((NOT (SETQ FL (P2UNSAFEP J)))) 
			   ((NOT (ATOM FL)) (SETQ CONDUNSF (LADD FL CONDUNSF) FL 'T)) 
			   ((NULL (VARMODE FL)) (PUSH FL CONDUNSF) (SETQ FL () ))
			   ('T (SETQ FL GOFOO)		;Local numeric type vars are always unsafe
			       (PUSH 'T CONDUNSF)))	; so dont need to put explicitly on UNSFLST
		     (SETQ CONDTYPE (P1TYPE-ADD CONDTYPE MODE))))
	      (COND ((AND PNOB 						;If a PDL number is in order 
			  MODE						; and val is numeric, 
			  (NOT (EQ FL GOFOO))				; but not fixnumvar
			  (OR FL (P1CJ-NUMVALP J)))			; then might need NLNVTHTBP 
		     (AND (NULL CONDPNOB) (SETQ CONDPNOB (CONS () () )))
		     (SETQ CNT (+ CNT 2) FL () )
		     (SETQ MODE (COND ((EQ MODE 'FIXNUM) 
					(AND (NULL (CAR CONDPNOB)) 
					     (RPLACA CONDPNOB (SETQ FL (NLNVFINDCR MODE 'COND))))
					(CAR CONDPNOB))
				      ((EQ MODE 'FLONUM)
					(AND (NULL (CDR CONDPNOB)) 
				  	     (RPLACD CONDPNOB (SETQ FL (NLNVFINDCR MODE 'COND))))
					(CDR CONDPNOB))))
		     ;MODE now has name of NLNVTHTBP, either FIXNUM or FLONUM, for the wings of the COND
		     ;FL is non-null if name is newly created
		     (AND FL (NOT (EQ CONDUNSF 'T)) (PUSH MODE CONDUNSF))
		     (SETQ J (CONS 'SETQ (LIST MODE J)))))
	      (NCONS J))
    (NOT EFFS) () () ))


;;; Basically, a PHASE2 type analyzer, except that quoted numbers 
;;;   and variables are ignored.  Called only by P1CJ.

(DEFUN P1CJ-NUMVALP (FORM)
  (COND ((ATOM FORM) () )
	((NOT (ATOM (CAR FORM)))
	 (COND ((EQ (CAAR FORM) 'LAMBDA) (P1CJ-NUMVALP (CADDDR (CDDAR FORM))))
	       ((EQ (CAAR FORM) COMP) 
		(AND (MEMQ (CADAR FORM) '(FIXNUM FLONUM)) (CADAR FORM)))))
	((MEMQ (CAR FORM) '(SETQ QUOTE)) () )
	((EQ (CAR FORM) 'PROG2) (P1CJ-NUMVALP (CADDR FORM)))
	((OR (EQ (CAR FORM) 'PROGN) (EQ (CAR FORM) PROGN) (EQ (CAR FORM) 'PROGV))
	 (P1CJ-NUMVALP (CAR (LAST (CDR FORM)))))
	((AND (SETQ FORM (NUMFUNP FORM () )) (NOT (EQ FORM 'T))) FORM)))

(COMMENT P1CASEQ)

(defvar *:TRUTH 'T "NACOMPLR will override this")

(DEFUN P1CASEQ (X)
    (PROG (KEYFORM LFORM EXP TYPE-PRED TEM LL CLAUSES)
	  (DECLARE (SPECIAL KEYFORM TYPE-PRED))
	  (SETQ EXP (CDR X))
	  (POP EXP KEYFORM)
	  (AND (OR (NULL KEYFORM) (NUMBERP KEYFORM) (ATOM EXP) (ATOM (CAR EXP)))
	       (RETURN () ))
	  (COND ((NOT (PAIRP KEYFORM)))
		((OR (NOT (P1CARCDR-CHASE KEYFORM))				;Wrap a LAMBDA around it
		     (> (FLATC (CAR KEYFORM)) 4)				; if not "simple".
		     (NOT (ATOM (CADR KEYFORM))))
		 (SETQ TEM (GENSYM))
		 (SETQ LFORM (LIST (LIST 'LAMBDA (LIST TEM) NULFU) KEYFORM))
 		 (SETQ KEYFORM TEM)))
	  (SETQ TYPE-PRED (ASSQ (TYPEP (COND ((PAIRP (CAAR EXP)) (CAAAR EXP))
					      ('T (CAAR EXP))))
				 '((SYMBOL . EQ) (FIXNUM . =) (FLONUM . =))))
	  (AND (NULL TYPE-PRED) (RETURN () ))
	  (SETQ LL EXP CLAUSES () )
	A (COND (LL (PUSH (CONS (COND ((ATOM (CAR LL)) (RETURN () ))
				      ((EQ (CAAR LL) *:TRUTH) ''T)
				      ((NOT (PAIRP (CAAR LL))) 
				       (COND ((EQ (CAAR LL) 'T)
					      ''T)
					     ((P1CASEQ-CLAUSE (CAAR LL)))
					     ('T (RETURN () ))))
				      ('T (SETQ TEM (MAPCAR 'P1CASEQ-CLAUSE
							    (CAAR LL)))
					  (AND (MEMQ () TEM) (RETURN () ))
					  (COND ((NULL (CDR TEM)) (CAR TEM))
						((CONS 'OR TEM))) ))
				(CDAR LL)) 
			  CLAUSES)
		    (POP LL)
		    (GO A)))
	  (SETQ EXP (CONS 'COND (NREVERSE CLAUSES)))
	  (RETURN (COND (LFORM (RPLACA (CDDAR LFORM) EXP) LFORM)
			(EXP))) ))


(DEFUN P1CASEQ-CLAUSE (X)
    (DECLARE (SPECIAL TYPE-PRED KEYFORM))
    (COND ((NOT (EQ (TYPEP X) (CAR TYPE-PRED))) () )
	  ('T (LIST (CDR TYPE-PRED) KEYFORM (LIST 'QUOTE X)))))
 


(COMMENT P1DO)

(DEFUN P1DO (XX)
    (PROG (INDXL ENDTST ENDVAL TG1 TAG3 PVARS LVARS STEPDVARS LVALS BODY DECL X)
	  (SETQ X (CDR XX))
	  (COND ((AND (CAR X) (ATOM (CAR X)))
		 (SETQ  INDXL (LIST (LIST (POP X) (POP X) (POP X)))
			ENDTST (POP X) 
			ENDVAL ()
			TG1 (LIST (GENSYM))))
		('T (SETQ INDXL (REVERSE (POP X))) 
		    (COND ((SETQ ENDTST (POP X))
			   (SETQ ENDVAL (COND ((OR (NULL (CDR ENDTST))
						   (NULL (CADR ENDTST))
						   (AND (NOT (ATOM (CADR ENDTST)))
							(QNILP (CADR ENDTST))))
					       () )
					      ('T (REVERSE (CDR ENDTST))))
				 ENDTST (CAR ENDTST)
				 TG1 (LIST (GENSYM))))
			  ('T (SETQ ENDTST CLPROGN)))))
	  (MAPC '(LAMBDA (X) (COND ((COND ((ATOM X))
					  ((NULL (CDR X)) (SETQ X (CAR X)) 'T)) 
				    (PUSH X PVARS))
				   ('T (PUSH (CAR X) LVARS)  
				       (PUSH (CADR X) LVALS)
				       (AND (CDDR X) (PUSH X STEPDVARS))
				       (AND (CDDDR X) (SETQ XX () ))
				       (SETQ X (CAR X))))
			     (AND (NOT (SYMBOLP X)) (SETQ XX () )))
		INDXL)
	  (AND (NULL XX) (RETURN () ))
	  (AND (NOT (ATOM (CAR X))) 
	       (EQ (CAAR X) 'DECLARE)
	       (POP X DECL))
	  (SETQ BODY (LIST 
			(NCONC  (LIST 'PROG PVARS)
				TG1 
				(AND (AND TG1 ENDTST)
				     (OR (ATOM ENDTST) (NOT (QNILP ENDTST)))
				     (LIST 
				      (LIST 
					'COND
					(CONS ENDTST 
					      (COND ((NULL ENDVAL) '((RETURN () )))
						    (TAG3 (LIST (LIST 'GO TAG3)))
						    ('T (P1DO-RETURN ENDVAL)))))))
				(APPEND X () )
				(AND STEPDVARS (LIST (P1DO-STEPPER STEPDVARS)))
				(LIST (COND (TG1 (LIST 'GO (CAR TG1)))
					    ((EQ ENDTST CLPROGN) '(RETURN () ))
					    ((DBARF XX |Bad DO format|)) ))
				(AND TAG3 (CONS TAG3 (P1DO-RETURN ENDVAL))))))
	  (AND DECL (SETQ BODY (CONS DECL BODY)))
	  (RETURN (CONS (CONS 'LAMBDA (CONS LVARS BODY)) LVALS))))


(DEFUN P1DO-RETURN (ENDVAL) 
    (NREVERSE (CONS (LIST 'RETURN (CAR ENDVAL)) (CDR ENDVAL))))

(DEFUN P1DO-STEPPER (L) 
    (LIST 'SETQ 
	  (CAAR L)
	  (COND  ((NULL (CDR L)) (CADDAR L))
		 ((LIST 'PROG2 () (CADDAR L) (P1DO-STEPPER (CDR L)))))))

(COMMENT Random P1 helper funs in the E and F range)

(DEFUN P1EQQTE (Z)
	(AND (NOT (ATOM Z))
	     (EQ (CAR Z) 'QUOTE)
	     (SYMBOLP (CADR Z))))

(DEFUN P1E (X) ((LAMBDA (EFFS) (P1 X)) 'T))

(DEFUN P1E1 (X)
;    Called only from P1PROG  
;	Tries to factor out a SETQ from a COND - for example,  
;	(COND ((AND (SETQ X (FOO)) ALPHA) (RETURN () ))) 
;	goes into 
;	(PROG2 (SETQ X (FOO)) (COND ((AND X ALPHA) (RETURN () ))))
    (COND ((OR PRSSL (NOT (MEMQ (CAR X) '(COND AND OR)))) (P1 X))
	  (((LAMBDA (DATA TEM F) 
		    (AND (SETQ DATA (P1HUNOZ (SETQ TEM (COND (F (CADR X)) 
								((CDR X)))))) 
			 (OR (MEMQ (CADR DATA) BVARS)
			     (ASSQ (CADR DATA) RNL))
			 (P1 (PROG2 (SETQ TEM (P1HUNOZ TEM))
				     (LIST 'PROG2 
					   DATA 
					   (CONS (CAR X)
					         (COND (F (CONS TEM (CDDR X)))
						       (TEM))))))))
		 () () (EQ (CAR X) 'COND)))
	  ((P1 X))))

(DEFUN P1HUNOZ (Y)  (COND ((OR (ATOM (CAR Y)) 
				(NULL (CDAR Y))
				(NOT (ATOM (CAAR Y)))
				(ASSQ (CAAR Y) MACROLIST)) 
			    (AND DATA Y))
			  ((EQ (CAAR Y) 'SETQ) (COND (DATA (CONS (P1FV (CDAR Y)) (CDR Y))) 
						     ('T (CAR Y))))
			  ((GETL (CAAR Y) '(FEXPR FSUBR *FEXPR MACRO)) (AND DATA Y))
			  (DATA (CONS (CONS (CAAR Y) (P1HUNOZ (CDAR Y))) (CDR Y)))
			  ((P1HUNOZ (CDAR Y)))))

(DEFUN P1F (F L) 
;	PATCH UP FOR FORMS OF (EVAL (CONS 'FSUBR LIST))
    (AND (P1KNOWN F '(FSUBR *FEXPR)) (CONS (CONS MAKUNBOUND (CONS 'FSUBR (CADR F))) L)))

(DEFUN P1FAKE (X)
;   Convert FOO into ((LAMBDA () FOO)) so that 
;	     the setq count and clearing action of LAMBDA
;	     form will be done for FOO
    ((LAMBDA (F ZZ) 
	     (SETQ ZZ (CDDAR F))
	     (RPLACA ZZ (ADD PROGN (CAR ZZ)))				;Make it appear as though
	     (RPLACA (CADDDR ZZ) (CAR X))				; the unknown function is
	     (P1MODESET F)) 		 				; of high "severity" 
	(P1VN (LIST (LIST 'LAMBDA () (CONS NULFU (CDR X)))))
	() ))

(DEFUN P1FV (X)
	(COND ((AND (CDR X) (CDDR X)) (P1FV (CDDR X)))
	      ((CAR X))))


(DEFUN P1FUNGET (FUN)			;Idea is to convert '(LAMBDA . . .)
  (PROG () 				; to (FUNCTION (LAMBDA . . .))
     A	(COND ((ATOM FUN))
	      ((EQ (CAR FUN) 'FUNCTION) (RETURN FUN))
	      ((EQ (CAR FUN) 'QUOTE) (RETURN (CONS 'FUNCTION (CDR FUN))))
	      ((NOT (EQ (SETQ FUN (P1MACROGET FUN)) NULFU)) (GO A)))))

(DEFUN P1GFY (X FL)
	(COND ((ATOM X) 
	       (OR (FUNTYP-DECODE X) (PUSH X UNDFUNS))
	       X)
	      ('T (SETQ X (COMPILE (P1PFX) FL X () 'T)) 
		  (AND (NOT FASLPUSH) (ICOUTPUT GOFOO))
		  X)))


(DEFUN P1PFX () (MAKNAM (APPEND GENPREFIX (EXPLODEC (SETQ GFYC (ADD1 GFYC))))))


(COMMENT P1LAM and P1GLM)

(DEFUN P1LAM (F AARGS)
   #%(LET ((LMBP 'T) (P1LLCEK P1LLCEK)
	   P1LL  P1LSQ  NEW-NLNVS  BIND-ANALYZE-IN-OLD-ENV)
	 (SETQ BIND-ANALYZE-IN-OLD-ENV 
	       (*FUNCTION (LAMBDA (VSS LL AARGS VMS) 
				  (MAPCAR 'P1BINDARG VSS LL AARGS VMS))))
	 #%(LET ((BVARS BVARS) (SPECVARS SPECVARS) (IGNOREVARS IGNOREVARS) 
		(MODELIST MODELIST) (RNL RNL) (NLNVS () )
		CONDP NLNVTHTBP TEM VSS VMS)
		;Binding BVARS MODELIST, SPECVARS, RNL, NLNVS, and NLNVTHTBP 
		; after making the funarg protects against spurious propogation
		; of local declarations, and spurious NLNVASG warnings
		;WARNING! WARNING!  Any variable augmented by local declaration
		; part of P1LMBIFY must be so bound here.
	       (SETQ F (P1LMBIFY (CADR F) () (CDDR F)))
	       (SETQ P1LL (CAR F) F (CDR F))
	        ;This has caused P1LL to be set up properly (after RNL'd)
	       (AND P1LL (PUSH P1LL P1LLCEK))
	       (COND ((NOT (ZEROP (SETQ TEM (- (LENGTH AARGS) (LENGTH P1LL))))) 
		      (PDERR (CONS (CONS 'LAMBDA (CONS P1LL F)) AARGS) 
			     |Wrong number of args to LAMBDA|) 
		      (DO ((Z) (I TEM (1- I)))
			  ((SIGNP LE I) 
			   (COND (Z 
				   ;Following code taken from P1LMBIFY
				  (MAPC '(LAMBDA (Y)
					  (PUTPROP Y () 'OHOME)
					  (PUSH (CONS Y 0) LOCVARS)
					  (PUSH Y BVARS))
					Z)
				  (SETQ P1LL (NCONC Z P1LL)))))
			  (PUSH (GENSYM) Z))))
	       (SETQ VSS (MAPCAR '(LAMBDA (X) (PUSH (VARMODE X) VMS)
					  (SPECIALP X))
				 P1LL)
		     VMS (NREVERSE VMS))
	       (SETQ AARGS (FUNCALL BIND-ANALYZE-IN-OLD-ENV VSS P1LL AARGS VMS))
	       (SETQ TEM (P1GLM P1LL F))
	       (P1SPECIALIZEDVS)						;Check for screw case
	       (SETQ CNT (1+ CNT))
	       (SETQ AARGS (COND (ARITHP (RPLACA TEM (CONS (CAR TEM) AARGS)))
				 ((CONS TEM AARGS))))
	       (AND (SETQ F (UUVP 'P1LL)) (WARN F |Unused LAMBDA variables|))
	       (SETQ NEW-NLNVS NLNVS  F P1LSQ))
	 (COND ((NULL NLNVS) (SETQ NLNVS NEW-NLNVS))
	       (NEW-NLNVS (SETQ NLNVS (NCONC NEW-NLNVS NLNVS))))
	 (NLNVASG P1LL))
   (P1SQE F)
   AARGS)

(DEFUN P1GLM (LL BODY)
     ((LAMBDA (T1 MODE FL)
	      (COND ((NULL (CDR BODY)) 
		     (SETQ T1 (P1 (CAR BODY)))
		     (SETQ BODY (COND (ARITHP (CAR T1)) (T1))))
		    ('T (SETQ BODY (P1L BODY EFFS ARITHP KTYPE))
			(SETQ T1 (CAR (SETQ FL (LAST BODY))))
			(AND ARITHP (RPLACA FL (CAR T1)))
			(SETQ BODY (CONS PROGN BODY))))
	      (AND ARITHP (SETQ MODE (CDR T1) T1 (CAR T1)))
	      (P1GLM1   LL 
			BODY
			(COND ((OR EFFS (ZEROP (P1TRESS T1))) 0) (1))
			(OR MODE KTYPE)
			(COND ((NULL (SETQ FL (P2UNSAFEP T1))) () )
			      ((ATOM FL) (LIST FL))
			      (FL))))
	  () () () ))

(DEFUN P1GLM1 (LL BODY N MODE UNSAFEP)
    ((LAMBDA (T1)
	(COND ((NOT ARITHP) T1)
	      ((CONS T1 MODE))))
      (LIST 'LAMBDA N P1LSQ (LIST SPECVARS MODELIST IGNOREVARS) 
	    LL BODY CNT UNSAFEP NLNVTHTBP)))



		      

(DEFUN P1KNOWN (F L)
    (AND (NOT (ATOM F))
	 (MEMQ (CAR F) '(QUOTE FUNCTION))
	 (ATOM (SETQ F (CADR F)))
	 (SETQ L (GETL F L))
	 (OR (NOT (MEMQ (CAR L) '(SUBR FSUBR LSUBR)))
	     (SYSP (CADR L)))))


(DEFUN P1L (X OEFFS OARITHP OKTYPE)
   ((LAMBDA (EFFS ARITHP KTYPE)
	    (MAPLIST '(LAMBDA (X)
			      (AND (NULL (CDR X)) 
				   (SETQ EFFS OEFFS ARITHP OARITHP KTYPE OKTYPE))
			      (P1 (CAR X)))
		 X))
	'T () () ))


(DEFUN P1LST (X)
  (PROG (Z LL V)
	(SETQ Z (CDR X))
	(COND ((MEMQ (CAR X) '(MEMBER ASSOC SASSOC))		;CONVERT TO MEMQ, ASSQ, SASSQ IF POSSIBLE
		(AND (OR (NULL (CADR Z)) (QNILP (CADR Z)))
		     (RETURN (P1 (LIST 'PROG2 (CAR Z) () ))))
		(AND (COND ((P1EQQTE (CAR Z)))
			   ((NULL (SETQ LL (P1LST-LSTGET (CADR Z)))) () )
			   ((NOT (DO Y LL (CDR Y) (NULL Y)
				      (AND (NOT (SYMBOLP (COND ((EQ (CAR X) 'MEMBER) (CAR Y))
								('T (CAAR Y)))))
					   (RETURN 'T))))))
		     (SETQ X (CONS (CDR (ASSQ (CAR X) '((MEMBER . MEMQ) 
							(ASSOC . ASSQ) 
							(SASSOC . SASSQ))))
				   (CDR X))))))
	(COND ((NOT (AND EFFS 
			 (EQ (CAR X) 'MEMQ) 
			 (OR LL (SETQ LL (P1LST-LSTGET (CADR Z))))
			(LESSP (LENGTH LL) 5))))
	      ((P1CARCDR-CHASE (SETQ V (CAR Z)))
	       (RETURN (P1 (CONS 'OR (MAPCAR '(LAMBDA (X) (LIST 'EQ V (LIST 'QUOTE X)))  LL)))))
	      ((COND ((EQ (CAR V) 'SETQ) (SETQ LL V V (NX2LAST V)) 'T)
		     ((AND (EQ (CAR V) 'PROG2) 
			   (AND (CDDR V) (NULL (CDDDR V)))
			   (P1CARCDR-CHASE (CADDR V)))
			(SETQ LL (CADR V) V (CADDR V))
			'T))
		(RETURN (P1 (LIST 'PROG2 LL (CONS 'MEMQ (CONS V (CDR Z))))))))
	(SETQ X (CONS (CAR X) (MAPCAR 'P1VN (CDR X))))
	(RETURN (COND (ARITHP (NCONS X)) (X)))))

(DEFUN P1LST-LSTGET (Z)
    (COND ((OR (ATOM Z) (NOT (EQ (CAR Z) 'QUOTE))) () ) 
	  ((NULL (CADR Z)) () )
	  ((NOT (EQ (TYPEP (CADR Z)) 'LIST)) (PDERR Z |Cant use this as 2nd arg to MEMQ|))
	  ((CADR Z))))


(COMMENT P1LMBIFY)
;Process an optional declaration in the body of a LAMBDA or PROG 
;  and process the lambda list, returning cons of new lambda-list onto
;  a possibly truncated body.

;WARNING WARNING!!  P1LAM must bind any global lists which are augmented here.

(DEFUN P1LMBIFY (LL TYPEL EXP)
    (COND ((AND (NOT (ATOM (CAR EXP))) (EQ (CAAR EXP) 'DECLARE)) 
	    ;Do the local declarations - augment SPECVARS, MODELIST
	   (MAPC '(LAMBDA (DATA)
		    (DO ((X (CDR DATA) (CDR X)) (TEMP) (ATOMP))	;fix up for renamings of variables
			((NULL X))
		      (COND ((SETQ TEMP (ASSQ (COND ((SETQ ATOMP (ATOM (CAR X))) 
						     (CAR X))
						    ((CAAR X)))
					      RNL))
			     (RPLACA (COND (ATOMP X) ((CAR X))) (CDR TEMP)))))
		    (AND (COND ((MEMQ (CAR DATA) '(SPECIAL IGNORE FIXNUM FLONUM NOTYPE)))
			       ('T (PDERR DATA |Illegal local declaration|) () ))
			 (MAPC '(LAMBDA (X)
				 (COND ((ATOM X) 
					(COND ((AND (MEMQ X BVARS)
						    (NOT (MEMQ X LL))) 
						(PDERR DATA |Local declaration occurs too late in function|) 
						() )
					      ((EQ (CAR DATA) 'SPECIAL)
						(REMPROP X 'OHOME)
						(AND (NOT (GET X 'SPECIAL)) 
						     (PUSH (CONS X (LIST 'SPECIAL X))
							   SPECVARS)))
					      ((EQ (CAR DATA) 'IGNORE)
					       (PUSH X IGNOREVARS))
					      ((AND (GET X 'NUMVAR) 
						    (EQ (GET X 'NUMVAR) (CAR DATA))))
					      ((PUSH (CONS X (COND ((EQ (CAR DATA) 'NOTYPE) () )
								    ((CAR DATA))))
						      MODELIST))))
				      ((VARMODE (CAR X))
				       (PDERR DATA |Cant locally redeclare function|))
				      ((AND (NULL (CDR X)) (EQ (CAR DATA) 'NOTYPE)))
				      ((PUSH `((,(car x)) ,. (nmpsubst (cdr x) (car data)))
					     MODELIST))))
			       (CDR DATA))))
		 (CDAR EXP))
	   (SETQ EXP (CDR EXP))))
    (DO ((LLL LL (CDR LLL)) 		;Process the LAMBDA-list
	 (TYP TYPEL (CDR TYP))		;TYPEL comes from NUMFUN property
	 (ANS () (CONS VAR ANS))
	 VAR )
	((NULL LLL) (CONS (NREVERSE ANS) EXP) )	;Return ((LAMBDA-list) . body) 
       (COND ((NULL (SETQ VAR (CAR LLL))))
	     ((OR (MEMQ VAR '(T QUOTE)) (NOT (SYMBOLP VAR)))
	      (PDERR (LIST VAR 'FROM LL) |Not permissible in bound variable list|))
	     ((MEMQ VAR (CDR LLL)) 
	      (WARN (LIST VAR 'FROM LL)
		    |- Repeated in bound variable list| 
		    3 6)))
       (COND ((NULL VAR))
	     ((SPECIALP VAR))
	     ((AND SPECIALS (NOT (GET VAR ':LOCAL-VAR)))
	      (PUTPROP VAR (LIST 'SPECIAL VAR) 'SPECIAL))
	     ('T (COND ((ASSQ VAR LOCVARS)
			(PUSH (CONS VAR (GENSYM)) RNL)
			(AND (SETQ VAR (VARMODE VAR))
			     (PUSH (CONS (CDAR RNL) VAR) MODELIST))
			(SETQ VAR (CDAR RNL))))
		 (PUTPROP VAR () 'OHOME)			;Just to be sure that OHOME prop exists
		 (PUSH (CONS VAR 0) LOCVARS)))
       (COND (VAR (PUSH VAR BVARS)
		  (AND TYP (CAR TYP) 
		       (NOT (EQ (CAR TYP) (VARMODE VAR)))
		       (PUSH (CONS VAR (CAR TYP)) MODELIST)) )) ))



(COMMENT P1MODESET and P1MACROGET)

(DEFUN P1MODESET (XPR)
  (COND ((NOT ARITHP) XPR)
	('T ((LAMBDA (TEMP FORM)
		     (CONS XPR
			   (COND ((ATOM FORM) (VARMODE FORM))
				 ((AND (NOT (SETQ TEMP (ATOM (CAR FORM))))
				       (NOT (EQ (CAAR FORM) 'LAMBDA)))
				  () )
				 ((COND ((NOT TEMP)			;Implies a LAMBDA
					 (SETQ FORM (CADDR (CDDDAR FORM)))
					 (AND (NOT (ATOM FORM)) 
					      (EQ (CAR FORM) PROGN)
					      (SETQ FORM (CAR (LAST FORM))))
					 (COND ((ATOM FORM) (SETQ TEMP (VARMODE FORM)) 'T)
					       ((NOT (ATOM (CAR FORM))) (SETQ TEMP () ) 'T))))
				  TEMP)
				 ((SETQ TEMP (OR (GET (CAR FORM) 'NUMFUN) (FUNMODE (CAR FORM))))
				  (CADR TEMP)))))
	     () XPR))))


(DEFUN P1MACROGET (X)
   ;(NOT (ATOM X))  This has been ascertained in all the places of call
   (COND ((NOT (SYMBOLP (CAR X))) NULFU)
	 (((LAMBDA (Z)
		   (COND ((COND ((OR Z (SETQ Z (GET (CAR X) 'MACRO)))  () )
				((AND (GET (CAR X) 'AUTOLOAD) 
				      (EQ (CAR (GET (CAR X) 'FUNTYP-INFO)) 'MACRO)
				      (NOT (GETL (CAR X) '(SUBR FSUBR LSUBR EXPR FEXPR))))
				 (FUNCALL AUTOLOAD (CONS (CAR X) (GET (CAR X) 'AUTOLOAD)))
				 (NULL (SETQ Z (GET (CAR X) 'MACRO))))
				('T))
			  NULFU)
			 ((NOT (ATOM (SETQ Z (ERRSET (FUNCALL Z X) 'T))))
			  (CAR Z))
			 ('T (PDERR X |LISP error during MACRO expansion|) ''() )))
	 (CDR (ASSQ (CAR X) MACROLIST))) )))



(COMMENT P1MAP)

(DEFUN P1MAP (X Z)
    (PROG (Y TEM CCSLD FUN)
    A	(SETQ Y () CCSLD 'T)
	(COND ((SETQ TEM (ATOM (SETQ FUN (CAR X)))))  ;Random variable function
	      ((MEMQ (CAR FUN) '(QUOTE FUNCTION))
		(SETQ Y (COND ((SETQ TEM (ATOM (CADR FUN)))
			       (SETQ CCSLD (NOT (P1KNOWN (CADR FUN)
							 '(SUBR FSUBR LSUBR))))
			       'T)
			      ((EQ (CAADR FUN) 'LAMBDA)))))
	      ((NOT (EQ (SETQ FUN (P1MACROGET FUN)) NULFU))
	       (SETQ X (CONS FUN (CDR X)))
	       (GO A)))
	(AND Y          			;CONVERT '(LAMBDA FOO)
	     (NULL TEM)
	     (EQ (CAAR X) 'QUOTE)		;INTO (FUNCTION (LAMBDA FOO))
	     (SETQ X (CONS (LIST 'FUNCTION (CADAR X)) (CDR X))))
	(AND Y
	     (OR (AND MAPEX (NOT (AND Y TEM
				      (GETL (CADAR X) '(FSUBR *FEXPR))))) 
		 (AND (NOT TEM)
		      (EQ (*CATCH 'CFVFL
				  (SETQ X `((QUOTE 
					     ,((LAMBDA (CFVFL)
						  (P1GFY (CADAR X) 'LEXPR))
					       (CONS (CONS BVARS RNL) CFVFL))) 
					    ,@(CDR X)))) 
			  'CFVFL)))
	     (GO MAPEXPAND))
	(AND CCSLD (P1SQV PROGN))
	(RETURN 
	 (P1FAKE 
	  (CONS (CONS 
		 MAKUNBOUND 
		 (CONS '*MAP (CONS CCSLD 
				   (COND ((OR (CDDR X) (NULL (CDR Z))) Z) 
					 ('T (CADR Z))))))
		X)))

MAPEXPAND
      (COND ((EQ (CAR Z) 'MAPATOMS)
	     (AND (NULL (CDR X)) (SETQ X (CONS (CAR X) '(OBARRAY))))
	     (SETQ TEM (SUBLIS (LIST (CONS 'PVR (CAR X)) 
				     (CONS 'STSL (CADR X)) 
				     (CONS 'VL (GENSYM)))
			       '(DO VL (- (CADR (ARRAYDIMS STSL)) 129.)
				    (1- VL) (MINUSP VL) 
				    (DECLARE (FIXNUM VL))
				    (MAPC PVR (ARRAYCALL T STSL VL)))))
	    (RETURN ((LAMBDA (MAPEX) (P1 TEM)) 'T))))
      (SETQ TEM () )		;To look for MAPC's for value!!
      #%(let ((form)
	      (indicl (MAPCAR #'(LAMBDA (Z) 
				  (let ((local (local-var)))
				       `(,LOCAL ,Z (CDR ,local))))
			      (CDR X))))
	   (COND (EFFS (setq form	;not for value, simple DO
			     '(DO VL EXIT EXITN)))
		 ((EQ (CADDR Z) 'MAP) 
		  (SETQ TEM		;This will be value for PVR below
			(CONS (LOCAL-VAR) (CADR X)))
		  (SETQ X (CONS (CAR X) (CONS (CAR TEM) (CDDR X))))
		   ;;STSL will become the first of the list being mapped
		   ;;  Must not evaluate the list-arg twice!
		  (rplaca (cdar indicl) (car tem))
		  (setq form '((LAMBDA (PVR) (DO VL EXIT EXITN) PVR) STSL)))
		 ((EQ (CADDR Z) 'MAPCON) 
		  (setq form
			'((LAMBDA (PVR STSL) (GOFOO PVR STSL)
			    (DO VL EXIT
				(SETQ STSL (LAST (RPLACD STSL EXITN))))
			    PVR)
			  () () )))
		 ((setq form
			'((LAMBDA (PVR STSL) (GOFOO PVR STSL)
			    (DO VL EXIT
				(SETQ STSL
				      (CDR (RPLACD STSL (LIST EXITN)))))
			    PVR)
			  () () ))))

	   (RPLACD (CAR MAPSB) INDICL)  ;Install indices list in subst list
	   (RPLACD (CADR MAPSB)		;Install the exit test
		   (LIST (COND ((NULL (CDR INDICL))
				(LIST 'NULL (CAAR INDICL)))
			       ((CONS 'OR
				      (MAPCAR #'(LAMBDA (X)
						  (LIST 'NULL (CAR X)))
					      INDICL))))))
	   (RPLACD (CAR (SETQ Y (CDDR MAPSB))) 
		   (CONS (CADAR X)
			 (MAPCAR #'(LAMBDA (X)
				     (COND ((EQ (CADDDR Z) 'LIST) (CAR X))
					   ((LIST 'CAR (CAR X)))))
				 INDICL)))
	   (COND ((NOT EFFS)
		  (SETQ Y (CDR Y))	;POSITION Y OVER ((PVR) (STSL) . . .)
		  (COND (TEM (RPLACD (CAR Y) (CAR TEM))
			     (RPLACD (CADR Y) (CDR TEM)))
			('T (RPLACD (CAR Y) (LOCAL-VAR))
			    (RPLACD (CADR Y) (LOCAL-VAR))))))
	   ;Format of MAPSB is ((VL . NIL) (EXIT . NIL) (EXITN . NIL) 
	   ;		     (PVR . NIL) (STSL . NIL) (GOFOO . GOFOO))
	   (SETQ X (SUBLIS MAPSB FORM))	;Substitute into the expander
					;form 

	   (RETURN (P1 X)))))


(DEFUN LOCAL-VAR () 
  #%(LET ((X (GENSYM)))
	(AND SPECIALS (PUTPROP X 'T ':LOCAL-VAR))
	X))


(COMMENT P1PROG)

(DEFUN P1PROG (X)
  (PROG2 (AND (OR (NULL (CDR X)) (AND (CAR X) (ATOM (CAR X))))
	      (DBARF X |Is this a PROG?|))
	 ((LAMBDA (OPVRL SPECVARS MODELIST RNL BVARS IGNOREVARS PROGP EFFS P1PCX OARITHP PKTYP)
		  (PROG (CONDP P1CSQ LMBP P1LSQ PVRL P1VARS GL P1CNT KTYPE 
			       ARITHP GONE2 P1PSQ BODY PRSSL PROGTYPE PROGUNSF NLNVTHTBP)
			(AND P1LL (NOT (MEMQ P1LL OPVRL)) (PUSH P1LL OPVRL))
			(SETQ X (P1LMBIFY (SETQ P1VARS (CAR X))  ()  (CDR X) ))
			(SETQ PVRL (DELQ () (CAR X)) X (CDR X))
			(SETQ P1VARS LOCVARS)
			(SETQ P1CNT (SETQ CNT (ADD1 CNT)))
			(SETQ BODY 
			      (MAPCAR 
				 '(LAMBDA (Y)
				      (PROG ()  
					   (SETQ CNT (ADD1 CNT))
					 A (COND ((SETQ BODY (ATOM Y)))
						 ((EQ (SETQ BODY (P1MACROGET Y)) NULFU)
						  (SETQ BODY () ))
						 ((QNILP BODY) (SETQ BODY () ))
						 ('T (SETQ Y BODY) (GO A)))
					   (COND (BODY 
						  (SETQ PRSSL 'T)
						  (SETQ Y (P1TAG Y))
						  (SETQ GL (PUSH (CONS Y (GENSYM)) GL))
						  (AND  (ASSQ Y (CDR GL))
							(NOT (EQ Y GOFOO))
							(WARN Y |Repeated GO tag|))
						  (RETURN Y))
						('T (RETURN (P1E1 Y))))))
				  X))
			(P1SPECIALIZEDVS)		;CHECK FOR SCREW CASE
			(P1SYNCHRONIZE-CNTS P1CNT P1VARS)
			(AND (SETQ X (UUVP 'PVRL)) (WARN X |Unused PROG variables|))
			(COND ((MEMQ GOFOO GONE2))     ;GOFOO ON GONE2 SAYS THERE IS A COMPUTED GO
			      ('T (MAPC '(LAMBDA (TAG) (AND (NOT (MEMQ (CAR TAG) GONE2))
							   (SETQ GL (DELETE TAG GL))))
				       GL)))
			(SETQ GL (NREVERSE GL))
			(MAPC  '(LAMBDA (TAG) (COND ((NOT (ATOM TAG)) 
						     (MAPC 'P1TAGDEFP (CAR TAG)))
						    ('T (P1TAGDEFP TAG))))
			       GONE2)
			(SETQ X P1PSQ)
			(NLNVASG PVRL)
;		HERE IS RETURN VALUE, PUT IN GONE2
			(SETQ GONE2 (LIST 'PROG P1PCX X GL 
					  (LIST SPECVARS MODELIST IGNOREVARS)
					   PVRL BODY PROGUNSF NLNVTHTBP))
			(RETURN (COND ((NULL OARITHP) GONE2)
				      ((CONS GONE2 (COND ((NULL (CAR PROGTYPE)) PKTYP)
							 ((EQ (CAR PROGTYPE) (CADR PROGTYPE)) 
							  (CAR PROGTYPE))
							 (PKTYP))))))))
		(COND (PVRL (CONS PVRL OPVRL)) (OPVRL))
	        SPECVARS MODELIST RNL BVARS IGNOREVARS 'T 'T 0 ARITHP KTYPE)
 	 (P1SQE X)
	 (COND (PROGP (SETQ P1PSQ (LADD (LSUB X PVRL) P1PSQ))))))


(DEFUN P1GO (X)
    (P1SQG X)
    (COND ((ATOM (CADR X)) 
	   (AND (NOT (SYMBOLP (CADR X)))
		(SETQ X (CONS 'GO (CONS (P1TAG (CADR X)) (CDDR X)))))
	   (PUSH (CADR X) GONE2)
	   X) 
	 ('T (COND ((ATOM (CADDR X)) (PUSH GOFOO GONE2))
		   ('T (SETQ GONE2 (APPEND (CADDR X) GONE2))))
	     (CONS 'GO (CONS (P1VN (CADR X)) (CDDR X))) )))

(DEFUN P1RETURN (X)
	(P1SQG X) 
	(COND ((OR (NULL (CDR X)) (NULL (CADR X)) (QNILP (CADR X)))
	       (SETQ PROGTYPE (P1TYPE-ADD PROGTYPE () ))
	       (COND (ARITHP '( (RETURN '() ) . () )) 
		     ('T '(RETURN '() ))))
	      (((LAMBDA (T1 MODE UNSAFEP)
			(SETQ T1 ((LAMBDA (ARITHP PNOB EFFS KTYPE) 
					  (P1 (CADR X)))
				     'T () () PKTYP))
			(SETQ MODE (CDR T1) T1 (CAR T1))
			(AND (NOT (ZEROP (P1TRESS T1)))
			     (SETQ P1PCX (ADD1 P1PCX)))
			(SETQ PROGTYPE (P1TYPE-ADD PROGTYPE MODE))
			(COND ((NULL (SETQ UNSAFEP (P2UNSAFEP T1)))
				(SETQ UNSAFEP (AND (NOT (QNP T1)) (NOT (SYMBOLP T1)) 'T)))
			      ((SETQ PROGUNSF (COND ((ATOM T1)
						     (OR (MEMQ T1 PVRL)		;If returning a PROG number var
							 (SETQ UNSAFEP () ))	; then allow NLNFINDCR below
						      (ADD T1 PROGUNSF))
						    ('T (AND (LAND T1 PROGUNSF)
							     (SETQ PROGUNSF (ADD PROGN PROGUNSF)))
							(LADD T1 PROGUNSF))))))
			(SETQ T1 (LIST 'RETURN T1))
			(COND (ARITHP (CONS T1 () )) (T1)))
		  () () () ))))

(DEFUN P1TAG (X)
  ((LAMBDA (TYPE)
	(COND ((EQ TYPE 'SYMBOL) X)
	      ((MEMQ TYPE '(FIXNUM FLONUM)) 
		((LAMBDA (*NOPOINT BASE) (IMPLODE (EXPLODEC X))) 'T 10.))
	      ('T (PDERR X |Not acceptable as GO tag|) GOFOO)))
    (TYPEP X)))

(DEFUN P1TAGDEFP (TAG)
       (AND (NOT (ASSQ TAG GL))
	    (NOT (EQ TAG GOFOO))
	    (PDERR (LIST 'GO TAG) |GO to non-existent tag|)))

(COMMENT P1PROG2 and P1PROGN)

(DEFUN P1PROG2 (XPR)
   (DO ((TYPE) (T1) (T2) (OEFFS EFFS) (EFFS 'T) (OARITHP ARITHP) (ARITHP))
       () 
    (SETQ T1 (P1 (CAR XPR)))
    (COND ((NULL OEFFS) 
	   (SETQ ARITHP OARITHP EFFS () )
	   (SETQ T2 (P1 (CADR XPR)))
	   (AND ARITHP (SETQ TYPE (CDR T2) T2 (CAR T2) ARITHP () ))
	   (SETQ EFFS 'T))
	  ('T (SETQ T2 (P1 (CADR XPR)))))
    (SETQ T2 (CONS 'PROG2 (CONS T1 (CONS T2 (MAPCAR 'P1 (CDDR XPR))))))
    (RETURN (COND ((NOT OARITHP) T2) ((CONS T2 TYPE))))))

(DEFUN P1PROGN (X FUN)
    (SETQ X (CONS FUN (P1L X EFFS ARITHP KTYPE)))
    (AND ARITHP 
	 ((LAMBDA (LL MODE)
		  (SETQ MODE (CDAR LL))
		  (RPLACA LL (CAAR LL))
		  (SETQ X (CONS X MODE)))
    	    (LAST X) () ))
    X)


(DEFUN P1SETQ (X)
    (PROG (VAR VAL LCP SPFL)
	  (SETQ LCP () )
	  (DO ((ZZ (CDR X) (CDDR ZZ)) (ARITHP)) ((NULL ZZ))
	      (COND ((NULL (CDR ZZ)) (RETURN (SETQ LCP () )))
		    ((COND ((NOT (SYMBOLP (CAR ZZ)))
			     (PDERR X |Non-SYMBOL for assignment in SETQ|)
			     (SETQ VAR (GENSYM))
			     'T)
			   ((GET (CAR ZZ) '+INTERNAL-STRING-MARKER)
			    (PDERR X |Don't SETQ a pseudo-STRING|)
			    (SETQ VAR (COPYSYMBOL (CAR ZZ) () ))
			    'T)
			   ((MEMQ (CAR ZZ) '(T NIL)) 
			     (PDERR X |Dont SETQ T or NIL|)
			     (SETQ VAR (COPYSYMBOL (CAR ZZ) () ))
			     'T))
			(SETQ ZZ (CONS VAR (CDR ZZ)))))
	      (COND ((AND (NULL (CDDR ZZ)) 
			  (OR (EQ (CAR ZZ) (CADR ZZ))
			      (AND (NOT (ATOM (CADR ZZ))) 
				   (EQ (CAADR ZZ) 'PROG2)
				   (EQ (CAR ZZ) (CADDR (CADR ZZ))))))
		     (SETQ X '(PROG2))
		     (SETQ LCP (LIST (COND ((NULL LCP) ''() ) 
					   ((CONS 'SETQ (NREVERSE LCP))))
				     (P1 (CADR ZZ))))		  ;(SETQ Y Y) => (PROG2 () Y)
		     (RETURN () )))				  ;(SETQ A B Y Y) => (PROG2 (SETQ A B) Y)
	      (SETQ VAR (COND ((CDR (ASSQ (CAR ZZ) RNL)))	  ;(SETQ Y (PROG2 C Y D)) ==> 
			      ((CAR ZZ))))			  ;    (PROG2 () (PROG2 C Y D))
								  ;(SETQ A B Y (PROG2 C Y D)) =>
	      (P1SQV VAR)					  ;    (PROG2 (SETQ A B) (PROG2 C Y D))
	      (SETQ VAL (P1BINDARG (SETQ SPFL (P1SPECIAL VAR)) VAR (CADR ZZ) (VARMODE VAR)))
	      (SETQ CNT (PLUS 2 CNT))
	      (AND (NOT SPFL) (RPLACD (ASSQ VAR LOCVARS) CNT))
	      (SETQ LCP (CONS VAL (CONS VAR LCP))))
	  (AND (NULL LCP) (PDERR X |Wrong number of args to SETQ|))
	  (SETQ VAR (CADR LCP))			;REGARDLESS OF CONDITION BELOW, THIS GETS THE NAME OF 
	  (AND  (NOT (EQ (CAR X) 'PROG2))	;THE VARIABLE WHOSE VALUE IS BEING RETURNED
		(SETQ LCP (NREVERSE LCP)))
	  (SETQ LCP (CONS (CAR X) LCP))
	  (RETURN (COND ((NOT ARITHP) LCP)
			((CONS LCP (VARMODE VAR)))))))



(COMMENT P1SPECIAL and funs to hack SETQ flow)

(DEFUN P1SPECIAL (X)
   (COND 
      ((EQ X 'QUOTE)
        (DBARF X |Can't be used as a variable - you lose.|))
      ((SPECIALP X))
      ((COND ((NOT (MEMQ X BVARS))
	       (CKCFV X)
	       (COND ((GET X ':LOCAL-VAR)
		      (BARF X |Trying to specialize internal temporary|))
		     ((NULL SPECIALS) 
		      #%(WARN X |Undeclared - taken as SPECIAL|)
		      (PUSH X P1SPECIALIZEDVS)
		      (AND (REMPROP X 'OHOME)
			   (LET ((Y (ASSQ X LOCVARS)))
			     (AND Y (SETQ LOCVARS (DELQ Y LOCVARS)))))))
	       'T)
	     (SPECIALS (NOT (GET X ':LOCAL-VAR))))
       ((LAMBDA (Z) (PUTPROP X Z 'SPECIAL) Z)
	(LIST 'SPECIAL X)))
      ('T (RPLACD (COND ((ASSQ X LOCVARS)) ((BARF X |Lost LOCVAR - P1SPECIAL|)))
		      CNT)
	      () )))

(DEFUN P1SPECIALIZEDVS () 
      (DO ((LL P1SPECIALIZEDVS (CDR LL)) (TEM) (Z))
	  ((NULL LL) 
	    (AND Z (DBARF Z |These variables must be declared special by user 
- the code for this function will probably not be correct|))
	    (SETQ P1SPECIALIZEDVS () )
	    Z)
	(COND ((SETQ TEM (ASSQ (CAR LL) LOCVARS))
		(SETQ LOCVARS (DELQ TEM LOCVARS))
		(COND ((SETQ TEM (ASSQ (CAR LL) RNL))
		       (SETQ RNL (DELQ TEM RNL))
		       (PUSH (CONS (CDR TEM) (LIST 'SPECIAL (CDR TEM)))
			     SPECVARS)
		       (AND (SETQ TEM (ASSQ (CDR TEM) LOCVARS))
			    (SETQ LOCVARS (DELQ TEM LOCVARS)))))
		(PUSH (CAR LL) Z)))))


(DEFUN P1SQE (L)
;   Extend SETQ vars from inner PROG, COND, or LAMBDA to
;	the outer CONDs and any outer LAMBDAs
    (COND (L (COND (CONDP (SETQ P1CSQ (LADD L P1CSQ))))
	     (COND (LMBP (SETQ P1LSQ  (LADD (LSUB L P1LL) P1LSQ))))))
    () )

(DEFUN P1SQG (Z) 
    (COND ((NOT PROGP) (PDERR Z |GO or RETURN not in PROG|)))
    (SETQ PRSSL 'T)
    (P1SQV GOFOO))

(DEFUN P1SQV (Y) 
	  (COND (CONDP (SETQ P1CSQ (ADD Y P1CSQ))))
	  (COND ((AND LMBP (NOT (MEMQ Y P1LL))) (SETQ P1LSQ (ADD Y P1LSQ))))
	  (COND ((AND PROGP (NOT (EQ Y GOFOO)) (NOT (MEMQ Y PVRL)))
		 (SETQ P1PSQ (ADD Y P1PSQ)))))

(DEFUN P1SYNCHRONIZE-CNTS (P1CNT P1VARS)
	(SETQ CNT (ADD1 CNT))
	(DO X P1VARS (CDR X) (NULL X)
	    (COND ((> (CDAR X) P1CNT) (RPLACD (CAR X) CNT))))
	(SETQ CNT (ADD1 CNT)))


(COMMENT P1SIGNP and P1STATUS)

(DEFUN P1SIGNP (X)
   #%(LET ((TEST (ASSQ ((LAMBDA (OBARRAY) (INTERN (CADR X))) SOBARRAY)
		      '((N . ZEROP) (E . ZEROP) (G . PLUSP) (LE . PLUSP)
			(L . MINUSP) (GE . MINUSP) (- . NIL)  (A . T))))
	  (ARG (CADDR X)))
	 (COND ((NULL TEST) (PDERR X |Bad args to SIGNP|) ''() )
	       ((NOT (MEMQ (CDR TEST) '(T NIL)))
		(SETQ ARG (P1VAP ARG 'T))
		(COND ((NULL (CDR ARG))
		       (LIST 'SIGNP (CAR TEST) (CAR ARG)))
		      ('T (SETQ ARG (LIST (CDR TEST) (CDR ARG) (CAR ARG)))
			  (AND (MEMQ (CAR TEST) '(N GE LE)) 
			       (SETQ ARG (LIST 'NULL ARG)))
			  ARG)))
	       ('T (P1 (LIST 'PROG2 ARG (CDR TEST)))))))


(DEFUN P1STATUS (X)
    (PROG (Z Y TEM)
	  (COND ((ZEROP (GETCHARN (CADR X) 6)) (SETQ TEM () ))
		((SETQ TEM (EXPLODEN (CADR X)))
		 (AND (CDDDDR TEM) (RPLACD (CDDDDR TEM) () ))))
	  (AND (NOT (MEMQ #%(LET ((OBARRAY SOBARRAY))
				(SETQ Y (COND (TEM (IMPLODE TEM))
					      ((INTERN (CADR X))))))
			  (COND ((EQ (CAR X) 'STATUS) (CAR STSL))
				((CADR STSL)))))
	      (WARN X |Possibly illegal STATUS call| 3 5))
	  (COND ((AND (SETQ TEM (CDDR X))
		      (SETQ Z (GET Y 'STATUS))
		      (SETQ Z (COND ((EQ (CAR X) 'STATUS) (CAR Z))
				    ((CDR Z))))
		      (COND ((AND (EQ Z 'A) (MAPCAN 'P1STVAL TEM (CAR COMAL)))
			     (SETQ TEM (MAPCAR 'P1STQLIFY TEM))
			     'T) 
			  ;LIKE ([S]STATUS FOO VALUE1)
			  ;OR ([S]STATUS FOO VALUE1 VALUE2)
			    ((AND (EQ Z 'B) 
				  (OR (P1STVAL (CAR TEM) 'T) 
				      (MAPCAN 'P1STVAL (CDR TEM) (CAR COMAL))))
			     (SETQ TEM (CONS (COND ((SYMBOLP (CAR TEM)) 
						    (LIST 'QUOTE (CAR TEM)))
						   ('T (P1VN (CAR TEM))))
					     (AND (CDR TEM) 
						  (CONS (P1STQLIFY (CADR TEM)) 
							(AND (CDDR TEM) 
							     (LIST (LIST 'QUOTE 
									 (CADDR TEM))))))))
			     T)))
		 ;LIKE (SSTATUS MACRO D VALUE1)
		 (SETQ Z (CONS 'CONS (CONS (LIST 'QUOTE (CADR X))
					   (LIST (P1ITERLIST TEM () ))))))
		('T (SETQ Z (LIST 'QUOTE (CDR X)))))
	  (RETURN Z)))

(DEFUN P1STVAL (X IPN)
  #%(LET ((Y (TYPEP X)))
	(COND ((EQ Y 'SYMBOL)
	       (COND ((OR IPN (MEMQ X '(T NIL)) (SPECIALP X)) () )
		     ('T (AND (SETQ Y (ASSQ X RNL)) (SETQ X (CDR Y)))
			 (COND ((MEMQ X BVARS) (LIST 'T))
			       ('T (P1SPECIAL X) () )))))
	      ((EQ Y 'LIST) 
	       (AND (NOT (MEMQ (CAR X) '(QUOTE FUNCTION)))
		    (LIST 'T))))))

(DEFUN P1STQLIFY (X)
    (P1VN (SUBST X 'X (COND ((NOT (P1STVAL X () )) '(QUOTE X))
			    ('(LIST 'QUOTE X))))))

(COMMENT P1TYPE-ADD and P1TRESS)
(comment for TYPE and complexity maintenance of COND and PROG)

;;; CONDTYPE AND PROGTYPE HAVE A VERY RIGID FORMAT:
;;;  	()
;;;	( () )
;;;	(FIXNUM FIXNUM)
;;;	(FLONUM FLONUM)
;;;	(FIXNUM FLONUM)
;;;	(() FIXNUM)
;;;	(() FLONUM)
;;;	(() FIXNUM FLONUM)

(DEFUN P1TYPE-ADD (TYPEL TYP)
     (COND ((NULL TYPEL)
	    (SETQ TYPEL (COND ((EQ TYP 'FIXNUM) '(FIXNUM FIXNUM)) 
			      ((EQ TYP 'FLONUM) '(FLONUM FLONUM))
			      ( '( () ) ))))
	   ((CDDR TYPEL))
	   ((NULL (CAR TYPEL))
	    (COND ((NULL TYP))
		  ((CDR TYPEL) (AND (NOT (EQ TYP (CADR TYPEL))) 
				    (SETQ TYPEL '(() FIXNUM FLONUM))))
		  ('T (SETQ TYPEL (COND ((EQ TYP 'FIXNUM) '(() FIXNUM))
					('(() FLONUM)))))))
	   ((NOT (EQ (CAR TYPEL) (CADR TYPEL)))
	    (AND (NULL TYP) (SETQ TYPEL '(() FIXNUM FLONUM))))
	   (TYP (AND (NOT (EQ (CAR TYPEL) TYP)) (SETQ TYPEL '(FIXNUM FLONUM))))
	   ('T (SETQ TYPEL (COND ((EQ (CADR TYPEL) 'FIXNUM) '(() FIXNUM))
				 ('(() FLONUM))))))
     TYPEL)



(DEFUN P1TRESS (F)	;F HAS ALREADY BEEN P1'D
    (COND ((OR  (ATOM F)
		(MEMQ (CAR F) '(QUOTE FUNCTION *FUNCTION EQ GO RETURN))
		(COND ((NOT (ATOM (CAR F)))
		       (AND (EQ (CAAR F) CARCDR) 
			    (< (LENGTH (CDAR F)) 3)))
		      ((SYMBOLP (CAR F)) 
		       (AND (|carcdrp/|| (CAR F))
			    (< (FLATC (CAR F)) 5)))))
	   0)
	  ((MEMQ (CAR F) '(RPLACD RPLACA))
	   (COND ((AND  (NOT (ZEROP (P1TRESS (CADR F)))) 
			(ZEROP (P1TRESS (CADDR F))))
		  1)
		 (0)))
	  ((MEMQ (CAR F) '(MEMQ SETQ))
	   (COND ((NOT (ZEROP (P1TRESS (CADDR F)))) 1) (0)))
	  ((MEMQ (CAR F) '(COND PROG)) (CADR F))
	  ((EQ (CAAR F) 'LAMBDA) (CADAR F))
	  ((AND (EQ (CAR F) 'NULL) (P1BOOL1ABLE (CADR F))) 0)
	  ((MEMQ (CAR F) '(AND OR)) (BARF F |AND or OR loss - P1TRESS|))
	  (1)))


(DEFUN P1VAP (XPR OPNOB) 	;P1 for value, arithmetics, and PNOB supplied
    ((LAMBDA (ARITHP PNOB EFFS KTYPE) (P1 XPR)) 'T OPNOB () () ))

(DEFUN P1VN (XPR)	;P1 for value, no arithmetics
    ((LAMBDA (ARITHP EFFS KTYPE) (P1 XPR)) () () () ))




(COMMENT NLNVTHTBP VARIABLE HACKERY)

(DEFUN NLNVASG (VARS) 
      (DO ((X NLNVS (CDR X)) (FL))
	  ((NULL X)  (AND FL (SETQ NLNVS (DELQ () NLNVS))))
	(COND ((MEMQ (CAAR X) VARS)
	       (PUSH (CDAR X) NLNVTHTBP)
	       (PUTPROP (CDAR X) () 'OHOME)
	       (PUSH (CONS (CDAR X) CNT) LOCVARS)
		(SETQ FL 'T)
		(RPLACA X () ))
	      ((AND (NOT (MEMQ (CAAR X) BVARS)) 
		    (NOT (MEMQ (CAAR X) ROSENCEK))
		    (DO ((Y P1LLCEK (CDR Y)))
			((NULL Y) 'T)
		      (AND (MEMQ (CAAR X) (CAR Y)) (RETURN () ))) )
		 (WARN (CAR X) |Show JONL - NLNVASG|)))))

(DEFUN NLNVFINDCR (MODE TYPE)
	(NLNVCR (COND ((AND (NOT (EQ PNOB 'T)) PNOB)) 
		      ((COND ((NULL PNOB) () )
			     ((AND (NOT (EQ TYPE 'PROG)) (CAR (OR P1LL PVRL))))
			     ((CAAR OPVRL))))
		      ((CAR (PUSH (LOCAL-VAR) ROSENCEK))))
		MODE))

(DEFUN NLNVCR (VAR MODE)
	((LAMBDA (NAME)
		 (PUTPROP NAME MODE 'NUMVAR)
		 (PUSH (CONS VAR NAME) NLNVS)
		 NAME)
	    (LOCAL-VAR)))


(DEFUN NLNVEX (VAR ITEM)			;CALLED ONLY BY P1BINDARG
    (COND ((AND ITEM (NOT (EQ ITEM 'T)))	;ONLY CALLED WHERE ITEM IS RESULT OF P2UNSAFEP
	   (SETQ UNSFLST (ADD VAR UNSFLST))
	   (COND ((ATOM ITEM) (NLNV1 VAR ITEM NLNVS))
		 ('T (MAPC '(LAMBDA (OLDVAR) (NLNV1 VAR OLDVAR NLNVS)) ITEM))))))

(DEFUN NLNV1 (NEWVAR OLDVAR SHEE-IT)
	(AND (MEMQ NEWVAR (MEMQ OLDVAR BVARS))
	     (DO ((Y SHEE-IT (CDR Y)) (ITEM))
		 ((NULL Y))
		(COND ((EQ (CAAR Y) OLDVAR)
			(PUTPROP OLDVAR NEWVAR 'NLNVS)
			(RPLACA (CAR Y) NEWVAR))
		      ((EQ (CAAR Y) (SETQ ITEM (GET OLDVAR 'NLNVS)))
			(NLNV1 NEWVAR ITEM Y))))))




(COMMENT SOME TYPE ANALYZERS USED BY PHASE 1)

;Basically, P1 type analyzers, where XPR has not yet been P1'd

(DEFUN NUMTYP (XPR NUMBERP) 
    (SETQ XPR (NUMTYPEP XPR NUMBERP)) 
    (AND (MEMQ (CDR XPR) '(FIXNUM FLONUM)) XPR))

(DEFUN NUMTYPEP (XPR NUMBERP)		;Returns form actually found to be of numeric type [except for
					; a numeric constant, in which case 1 or 1.0 is used] CONS'd to type
   #%(LET ((TYPE (TYPEP XPR)))
       (COND  ((EQ TYPE 'FIXNUM) '(1 . FIXNUM))
	      ((EQ TYPE 'FLONUM) '(1.0 . FLONUM))
	      ((EQ TYPE 'SYMBOL) (AND (SETQ TYPE (VARMODE XPR)) (CONS XPR TYPE)))
	      ((NOT (EQ TYPE 'LIST)) () )
	      ((EQ (SETQ TYPE (TYPEP (CAR XPR))) 'LIST)
	       (COND ((EQ (CAAR XPR) 'LAMBDA)		;### this fails when ret val depends on
		      (NUMTYPEP (CAR (LAST (CDDAR XPR))) NUMBERP))	; local vars and declarations
		     ((EQ (CAAR XPR) COMP)
		      (WARN XPR |Let JONL see this code - NUMTYPEP|)
		      (AND (MEMQ (CADAR XPR) '(FIXNUM FLONUM))
			   (CONS XPR (CADAR XPR))))))
	      ((NOT (EQ TYPE 'SYMBOL)) () )
	      ((EQ (CAR XPR) 'SETQ) 
	       (SETQ XPR (NX2LAST (CDR XPR)))
	       (AND (SETQ TYPE (NUMERVARP XPR)) (CONS XPR TYPE)))
	      ((EQ (CAR XPR) 'QUOTE) 
	       (COND ((EQ (SETQ XPR (TYPEP (CADR XPR))) 'FIXNUM) '(1 . FIXNUM))
		     ((EQ XPR 'FLONUM) '(1.0 .FLONUM))))
	      ((EQ (CAR XPR) 'PROG2) (NUMTYPEP (CADDR XPR) NUMBERP))
	      ((MEMQ (CAR XPR) '(PROGN PROGV)) 
	       (NUMTYPEP (CAR (LAST (CDR XPR))) NUMBERP))
	      ((EQ (CAR XPR) 'DO)				;### SEE THE CAVEAT ON LAMBDAS ABOVE
	       (AND (NOT (ATOM (CADR XPR)))			;### ALSO FAILS ON PROGS TOO
		    (SETQ TYPE (CAR (LAST (CADDR XPR))))
		    (OR (ATOM TYPE) (NOT (QNILP TYPE)))
		    (NUMTYPEP TYPE NUMBERP)))
	      ((EQ (CAR XPR) 'COND)
	       (COND (NUMBERP (DO ((Y (CDR XPR) (CDR Y))) 
				  ((NULL Y) (SETQ TYPE () ))
				(AND (SETQ TYPE (CDR (NUMTYP (CAR (LAST (CAR Y))) 'T)))
				     (RETURN () ))))
		     ('T (SETQ TYPE () )
			 (DO ((Y (CDR XPR) (CDR Y)) (FL)) 
			     ((NULL Y))
			   (SETQ FL 
				 (CDR (NUMTYPEP (CAR (LAST (CAR Y)))
						() )))
			   (COND ((NULL FL) (RETURN (SETQ TYPE () )))
				 ((NULL TYPE) (SETQ TYPE FL))
				 ((NOT (MEMQ TYPE '(FIXNUM FLONUM))))
				 ((EQ TYPE FL))
				 ('T (SETQ TYPE 'T))))))
	       (AND TYPE (CONS XPR TYPE)))
	      ((SETQ TYPE (NUMFUNP XPR 'T)) (CONS XPR TYPE))
	      ((NOT (EQ (SETQ TYPE (P1MACROGET XPR)) NULFU))
	       (NUMTYPEP TYPE NUMBERP)))))




;;;A subroutine for P1CJ-NUMVALP and NUMTYPEP - argument must be a list with 
;;;   a SYMBOL as first element.
;;; Wants to ascertain if the "function" is guaranteed to producee a manageable
;;;   numerical result.  Thus PLUS isn't generally so, since it can produce  a
;;;   BIGNUM, or perhaps the type is not fixable at compile time.

(DEFUN NUMFUNP (FORM P1P)
   (COND ((MEMQ (CAR FORM) '(ARRAYCALL LSUBRCALL SUBRCALL)) 
	  (AND (MEMQ (CADR FORM) '(FIXNUM FLONUM)) (CADR FORM)))
	 (((LAMBDA (PROP)
		   (COND ((NULL PROP)
			  (SETQ PROP (ASSQ (CAR FORM) RNL))
			  (AND (SETQ PROP (FUNMODE (OR (CDR PROP) (CAR FORM))))
			       (CADR PROP)))
			 ((OR (EQ (CAR PROP) 'ARITHP) (EQ (CAR PROP) 'NUMFUN))
			  (CADADR PROP))
			 ((EQ (CAR PROP) 'NUMBERP) 
			  (COND ((EQ (CADR PROP) 'NOTYPE) () )
				((NOT P1P) 
				 (COND ((OR (EQ (CAR FORM) 'FIX) (NULL (CADR FORM)))
					 () )	;For NUMVALP, we dont care to know the "T" types
				       ((MEMQ (CADR FORM) '(FIXNUM FLONUM))
					(CADR FORM))
				       ((OR FIXSW (EQ (CAR FORM) 'HAULONG)) 'FIXNUM)
				       ((OR FLOSW (EQ (CAR FORM) 'FLOAT)) 'FLONUM)
				       (CLOSED () )
				       ((GET (CAR FORM) 'CONTAGIOUS)
					(AND (MEMQ 'FLONUM (CADR FORM)) 'FLONUM))))
				((OR FIXSW (EQ (CAR FORM) 'HAULONG)) 'FIXNUM)
				((OR FLOSW (EQ (CAR FORM) 'FLOAT)) 'FLONUM)
				(CLOSED () )
				((GET (CAR FORM) 'CONTAGIOUS)
				 (DO ((Y (CDR FORM) (CDR Y)) 
				      (ANS 'FIXNUM))
				     ((NULL Y) ANS)
				   (SETQ PROP (CDR (NUMTYPEP (CAR Y) 'T)))
				   (COND ((EQ PROP 'FLONUM) (RETURN 'FLONUM))
					 ((NOT (EQ PROP 'FIXNUM)) (SETQ ANS 'T)))))
				('T (SETQ PROP (CDR (NUMTYPEP (CADR FORM) 'T)))
				    (COND ((AND (EQ (CAR FORM) 'FIX)
						(NOT (EQ PROP 'FIXNUM)))
					   'T)
					  (PROP))) ))))
	      (GETL (CAR FORM) '(ARITHP NUMFUN NUMBERP))))))

(DEFUN NUMERVARP (VAR) (AND (SYMBOLP VAR) (VARMODE VAR)))


;; PHASE2 analyzer for something proveably not a FIXNUM or FLONUM

(DEFUN NOTNUMP (X)
    (COND ((ATOM X) () )
	  ((NOT (ATOM (CAR X))) 
	    (COND ((EQ (CAAR X) '*MAP))
		  ((EQ (CAAR X) 'LAMBDA) (NOTNUMP (CADDDR (CDDAR X))))))
	  ((EQ (CAR X) 'QUOTE) 
	   #%(LET ((TYP (TYPEP (CADR X))))
		 (CASEQ TYP 
			((FIXNUM FLONUM) () )
			(LIST (NOT (EQ (CAADR X) SQUID)))
			(T T))))
	  ((EQ (CAR X) 'PROG2) (NOTNUMP (CADDR X)))
	  ((OR (EQ (CAR X) 'PROGN)
		(EQ (CAR X) PROGN)
		(EQ (CAR X) 'PROGV))
	   (NOTNUMP (CAR (LAST (CDR X)))))
	  ((LET ((FL (GETL (CAR X) '(NOTNUMP NUMBERP ARITHP FSUBR MACRO))))
	     (COND ((NULL FL) () )
		   ((EQ (CAR FL) 'NOTNUMP))
		   ((EQ (CAR FL) 'NUMBERP) (EQ (CADR FL) 'NOTYPE))
		   ((EQ (CAR FL) 'ARITHP) (NULL (CADADR FL)))
		   ((EQ (CAR FL) 'FSUBR) 
		    (COND ((MEMQ (CAR X) 
				 '(FASLOAD STORE STATUS SSTATUS SETQ GO THROW
				   ERR COND PROG POP ARRAYCALL SUBRCALL *THROW 
				   LSUBRCALL))
			   () )
			  ('T)))
		   ((NOT (EQ (CAR FL) 'MACRO)) () )
		   ((EQ (CAR X) SQUID) () )
		   ((NOT (EQ (SETQ FL (P1MACROGET X)) NULFU))
		    (NOTNUMP FL)))))))



(DEFUN SAMETYPES (TYPEL)						;Will take a types list, e.g.
	((LAMBDA (TYPE)							; (FIXNUM () FLONUM () FLONUM)
		(DO L (CDR TYPEL) (CDR L)				; and convert it to an atom [one of
		    (COND ((NULL L) (SETQ TYPEL TYPE) 'T)		; (), FIXNUM, FLONUM] if all types
			  ((NOT (EQ TYPE (CAR L)))))))			; are the same
	   (CAR TYPEL))
    TYPEL)


(DEFUN P2UNSAFEP (XPR)		;PHASE2 analyzer, for something that might be a PDL number
	(COND ((ATOM XPR) 
		(AND (COND ((MEMQ XPR UNSFLST))
			   ((NOT (NUMERVARP XPR)) () )
			   ((NOT (SPECIALP XPR))))
		     XPR))
	      ((NOT (ATOM (CAR XPR)))
		(AND (EQ (CAAR XPR) 'LAMBDA) (CADDDR (CDDDDR (CAR XPR)))))
	      ((EQ (CAR XPR) 'PROG) (CADDDR (CDDDDR XPR)))
	      ((MEMQ (CAR XPR) '(AND OR COND)) (CADDDR XPR))
	      ((EQ (CAR XPR) 'SETQ) (P2UNSAFEP (NX2LAST (CDR XPR))))
	      ((EQ (CAR XPR) 'PROG2) (P2UNSAFEP (CADDR XPR)))
	      ((OR (EQ (CAR XPR) 'PROGN) (EQ (CAR XPR) PROGN))
		(P2UNSAFEP (CAR (LAST (CDR XPR)))))
	      ((EQ (CAR XPR) 'ARG) ARGLOC)))


(COMMENT VARIOUS ARG AND VARIABLE CHECKERS)

(DEFUN UUVP (VAR)
   (let* ((ll (symeval var))
	  (tem)
	  (l (mapcan 
	       #'(lambda (x) 
		   (cond ((and x (setq x (assq x locvars)) (= (cdr x) 0))
			   (list (cond ((setq tem (memassqr (car x) RNL))
					 (setq RNL (delq (car tem) RNL))
					 (caar tem))
				       ('T (car x)))))))
	       ll)))
     (cond (l (set var (lsub ll (cons () l))))
	   ((memq () ll) (set var (lsub ll '(()) ))) )
     (do ((z l (cdr z)) (fl) (x))
	 ((null z)
	  (and fl (setq l (delq () l))))
       (setq x (car z))
       (cond ((or (eq x 'IGNORE)
		  (get x 'IGNORE)
		  (memq x IGNOREVARS)
		  (and (symbolp x)
		       (= (getcharn x 1) #/I)
		       (= (getcharn x 2) #/G)
		       (= (getcharn x 3) #/N)
		       (= (getcharn x 4) #/O)
		       (= (getcharn x 5) #/R)
		       (= (getcharn x 6) #/E)))
	      (rplaca z () )
	      (setq fl 'T))))
     l))


(DEFUN CKARGS (NAME M)
	((LAMBDA (AARGS)
	     (COND ((NULL AARGS) (PUTPROP NAME (CONS () M) 'ARGS))
		   ((AND (NULL (CAR AARGS)) (= (CDR AARGS) M)))
		   (#%(WARN NAME |Has been previously used with incorrect 
number of args -- Discovered while |))))
	   (OR (ARGS NAME) (GET NAME 'ARGS))))

(DEFUN CKCFV (X)
    (COND (SPECIALS)
	  (CFVFL (MAPC '(LAMBDA (Y) (AND (OR (MEMQ X (CAR Y)) (ASSQ X (CDR Y)))
					 (*THROW 'CFVFL 'CFVFL)))
		       CFVFL)
		 () )
	  ((AND P1GFY (OR (MEMQ X BVARS) (ASSQ X RNL)))
	   (DBARF X |Used free inside a LAMBDA form -  must be declared special|))))

(DEFUN WRNTYP (NAME)
    #%(WARN NAME |Has been incorrectly declared *EXPR or *FEXPR -- Discovered while |)
    (LREMPROP NAME '(*EXPR *FEXPR *LEXPR ARGS)))

