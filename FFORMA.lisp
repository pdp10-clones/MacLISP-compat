;;;   FFORMA 						-*-LISP-*-
;;;   **************************************************************
;;;   ***** MACLISP ****** Fortran-style FORMAT package ************
;;;   **************************************************************
;;;   ** (C) COPYRIGHT 1981 MASSACHUSETTS INSTITUTE OF TECHNOLOGY **
;;;   ****** THIS IS A READ-ONLY FILE! (ALL WRITES RESERVED) *******
;;;   **************************************************************
;;;   *** Three functions for numeric print formating:
;;;		PRINT-FIXED-FIELD-FLOATING
;;;		PRINT-FIXED-PRECISION-FLOATING
;;;		PRINT-FIXED-FIELD-FIXED
;;;   **************************************************************
;;;   **************************************************************
(IN-PACKAGE :MACLISP)

(keep
(herald FFORMA /13)
)
;;; Two functions for formatted printing of floating-point numbers
;;; and a simple one for fixed-point numbers.  A null is returned if
;;; the number cant be printed in the requested format; and otherwise
;;; "T" (or a list of characters) is returned.

;;;	PRINT-FIXED-FIELD-FLOATING   -  abbreviated "PFFF"
;;; A function for printing a floating point number with a specified
;;;	number of integral places, and of fractional places.
;;;   Total field width is specified by second arg, and should
;;;	allow enough for the algebraic sign, and the decimal point.
;;;   Number of places to the right of the decimal-point is
;;;	specified by third arg.  Similar to FORTRAN F8.3 style.
;;; Two optional args are permitted (both default to null).
;;;   A list of options is fourth arg.  see below under "variables".
;;;   A file, or list of files, for output is fifth.

;;;	PRINT-FIXED-PRECISION-FLOATING   -   abbreviated "PFPF"
;;; A function for printing a specified number of leading non-zero
;;;	digits, using "E" format where necessary.
;;;   Total field width is specified by second arg, and should
;;;	be large enough to allow for sign, point, etc.
;;;   Number of significant digits wanted is specified by third arg.
;;; Three optional args are permitted:
;;;   A list of options is fourth arg, default to null.
;;; 	See below under "variables" for further description.
;;;   A file, or list of files, for output is fifth, default to null.
;;;   A list of "balance" numbers is sixth arg - one of these numbers
;;; 	(the first) specifies the number of digits printed to the left
;;; 	of the point when "E" format is selected;  the second and third
;;; 	determine the exponent range wherein "E" format is not forced.
;;; 	For backwards-compatibility, if this argument is not a list,
;;; 	but is a fixnum, say <n>, that is equivalent to the list
;;; 		(<n>  -3  8)
;;; 	thus for 1.0E-3 < x < 1.0E8, x will not be forced "E" format.


;;;		PRINT-FIXED-FIELD-FIXED    -    abbreviated "PFFX"
;;;  A function to print a fixnum or bignum in a field of specified size.
;;;  First arg is number to be printed, second is field width,
;;;  Three optional arguments:
;;;   A fixnum, the radix for conversion, is third;  defaults to BASE.
;;;   A list of options is fourth arg, default to null.
;;; 	See below under "variables" for further description.
;;;   A file, or list of files, for output is fifth.

;;;   Applicable input domains:
;;;	For "PFFF", 1.0E-9 < |CANDIDATE| < 1.0E+9  is required.
;;;	For "PFPF",  "E" format is used if |CANDIDATE| < 1.0E-3, or
;;;	    |CANDIDATE| >= 1.0E+9.   Otherwise, an appropriatly
;;;	    selected version of PFPF is used.
;;;	For "PFFX", |CANDIDATE| < 8.5E+37  is required.



;;;		    EXPLANATION OF ARGUMENT VARIABLES

;;; CANDIDATE	- THE INPUT NUMBER
;;; WIDTH	- THE WIDTH OF THE FORMAT FIELD, INCLUDING ALGEBRAIC
;;;		  SIGN, DECIMAL POINT, AND EXPONENT IF USED.
;;; FRAC	- [THIS IS THE THIRD ARGUMENT FOR "PFFF"]
;;;		  NUMBER OF COLUMNS RESERVED FOR THE FRACTIONAL PART
;;; PREC	- [THIS IS THE THIRD ARGUMENT FOR "PFPF"]
;;;		  TOTAL NUMBER OF SIGNIFICANT DIGITS REQUESTED.
;;;		  MUST BE IN THE RANGE  0 < PREC < 9.
;;; BASE	- [THIRD ARGUMENT TO "PFFX".  SAME AS IN LISP]
;;; OPTIONS	- LIST OF OPTION DESIGNATORS:
;;;		  +    - PRINT "+" FOR POSITIVE NUMBERS.
;;;			 SUBSTITUTING <SPACE> IS DEFAULT
;;;		  EXPLODE, EXPLODEC, OR EXPLODEN
;;;		      - IF ANY OF THESE APPEAR, THEN INSTEAD
;;;			OF PRINTING THE DIGITS, THEY ARE COLLECTED
;;;			IN AN OUTPUT LIST, AND RETURNED.
;;;		  ERROR - IF THE FORMATTING-PRINT FUNCTION CANNOT FIT
;;;			  THE CANDIDATE IN THE REQUESTED FORMAT, IT
;;;			  WILL NORMALLY RETURN A NULL.  BUT IF "ERROR"
;;;			  IS PRESENT, IT WILL RUN A FAIL-ACT ERROR.
;;;		  LEFT - FOR "PFFF" AND "PFFX", PLACE SIGN IN LEFTMOST
;;;			   COLUMN OF FIELD.   DEFAULT: PLACE SIGN
;;;			   ADJACENT TO LEFTMOST DIGIT.
;;;			 FOR "PFPF", LEFT-JUSTIFY CHARACTERS IN FIELD.
;;;			   RIGHT-JUSTIFICATION IS DEFAULT.
;;;		  0 - FOR "PFPF", PRINT TRAILING ZEROS IN THE FRACTION
;;;		        PART (AND LEADING ZEROS IN THE EXPONENT PART);
;;; 		      FOR "PFFF" AND "PFFX", PRINT LEADING ZEROS.
;;;		        SUPPRESSION IS DEFAULT.
;;;		[THE FOLLOWING IS APPLICABLE ONLY TO "PFPF"]
;;;		  E - FORCE "E" FORMAT IN ALL CASES.
;;;		[THE FOLLOWING IS APPLICABLE ONLY TO "PFFX"]
;;;		  . - *NOPOINT IS SET TO (NOT (MEMQ '\. OPTIONS))
;;;		      THIS HAS A DISCERNIBLE EFFECT ONLY IF BASE = 10.
;;; INT	 	- [THIS IS THE FIFTH ARGUMENT TO "PFPF"]
;;;		  NUMBER OF COLUMNS RESERVED FOR THE INTEGRAL PART
;;;		  IF "E" FORMAT IS SELECTED;   OTHERWISE IGNORED.
;;;		  AMOUNTS TO A SCALE FACTOR FOR THE EXPONENT, WITH 1
;;;		  YIELDING STANDARD SCIENTIFIC NOTATION.
;;;		  MUST BE IN THE RANGE  -1 < INT < 9.



;;;		    EXPLANATION OF SOME AUXILLIARY PROG VARIALBES

;;; ROUNDED	- THE INPUT NUMBER SUITABLY ROUNDED
;;; IPART	- THE ACTUAL INTEGRAL PART OF "ROUNDED"
;;; NID		- NUMBER OF DECIMAL DIGITS IN "IPART"
;;; FPART	- FRACTIONAL PART OF "ROUNDED", AS AN INTEGER
;;; FRAC 	- FOR "PFPF", THIS VALUE IS COMPUTED FROM THE INPUTS
;;; EFLAG	- NON-NULL IFF "E" FORMAT SELECTED
;;; EPART	- EXPONENT FOR "E" FORMAT
;;; \|10S	- AN ARRAY OF POWERS OF 10.0, FROM 1.0E-38 TO 1.0E+38
;;; \|\.10S	- SECOND WORD OF DOUBLE-PRECISION FOR POWERS OF 10.0





;;; Some example usages.  Note that spaces are printed either before
;;; or after the digit string as directed from the options list.

;;; (PRINT-FIXED-FIELD-FLOATING -385.236 8. 2 ()) -385.24
;;; (PRINT-FIXED-FIELD-FLOATING 385.236 8. 2 '(+ LEFT))+ 385.24


;;; (PRINT-FIXED-PRECISION-FLOATING 5.23759E2 10. 4 () () 1)     523.8
;;; (PRINT-FIXED-PRECISION-FLOATING .00135 10. 5 () () 0)   0.00135
;;; (PRINT-FIXED-PRECISION-FLOATING 58.2 10. 4 '(0) () 1)     58.20
;;; (PRINT-FIXED-PRECISION-FLOATING 58.2 10. 4 '(LEFT +) () 1)+58.2
;;; (PRINT-FIXED-PRECISION-FLOATING 58.2 10. 4 '(E) () 0)  0.582E+2
;;; (PRINT-FIXED-PRECISION-FLOATING .00045 12. 6 () () 2)     45.0E-5
;;; (PRINT-FIXED-PRECISION-FLOATING .00045 12. 6 () () '(2 -8 8))     0.00045
;;; (PRINT-FIXED-PRECISION-FLOATING .00045 12. 2 () () 2)     45.0E-5
;;; (PRINT-FIXED-PRECISION-FLOATING .00045 12. 6 '(0) () 2) 45.0000E-05
;;; (PRINT-FIXED-PRECISION-FLOATING 28. 12. 4 () () 1)        28.0



;;; (PRINT-FIXED-FIELD-FIXED -8400. 10. 10. '(\. LEFT))-    8400.
;;; (PRINT-FIXED-FIELD-FIXED 8400. 10. 8. '(\. \+))    +20320
;;; (PRINT-FIXED-FIELD-FIXED 1054. 6 10. '(/0 EXPLODE)) WILL RETURN
;;;					(/0 /0 /1 /0 /5 /4)




(DECLARE (SPECIAL \+OR- EXPLODE FILLER)
	 (*EXPR /1OUT\| NOUT\|)
	 (FIXNUM \+OR- FILLER (NDD\| FIXNUM) (LG10\| FLONUM))
	 (NOTYPE (1OUT\| FIXNUM) (REPEAT-OUT\| FIXNUM FIXNUM))
	 (ARRAY* (FLONUM (\|10S 79.)) (FLONUM (\|\.10S 79.))))



(DECLARE (SETQ DEFMACRO-FOR-COMPILING ()
	       DEFMACRO-DISPLACE-CALL ()
	       DEFMACRO-CHECK-ARGS () ))
(defmacro 10E  (I) `(\|10S (+ 39. ,i)))
(defmacro \.10E  (I) `(\|\.10S (+ 39. ,i)))
(defmacro <= (X Y) `(NOT (> ,x ,y)))
(defmacro >= (X Y) `(NOT (< ,x ,y)))




(DEFUN PRINT-FIXED-FIELD-FLOATING
	     (ICANDIDATE IWIDTH IFRAC &OPTIONAL OPTIONS FILE)
     (DECLARE (FIXNUM IPART FPART NID FRAC WIDTH NSPCS)
	      (FLONUM CANDIDATE ROUNDED))
     (LET ((BASE 10.) (\+OR- #\SPACE) (FILLER #\SPACE))
	  (PROG (*NOPOINT EXPLODE ROUNDED IPART FPART NID LJUST NSPCS
			  CANDIDATE WIDTH FRAC)
		(SETQ CANDIDATE (COND ((FLOATP ICANDIDATE) ICANDIDATE)
				      ((FLOAT ICANDIDATE)))
		      WIDTH (COND ((EQ (TYPEP IWIDTH) 'FIXNUM) IWIDTH)
				  ((GO BARF)))
		      FRAC (COND ((EQ (TYPEP IFRAC) 'FIXNUM) IFRAC)
				 ((GO BARF))))
		(SETQ ROUNDED (FSC CANDIDATE 0)
		      NSPCS (COND ((= ROUNDED CANDIDATE) 0) (1))
		      ROUNDED (ABS ROUNDED)
		      LJUST (OUT-SET\| OPTIONS))
		(SETQ  *NOPOINT 'T)
		(AND (MINUSP CANDIDATE) (SETQ \+OR- #\-))
		(AND (OR (MINUSP FRAC) (> FRAC 18.)) (GO BARF))
		(SETQ ROUNDED (+$ ROUNDED (*/$ 0.5 (10E (- FRAC)))))
		(AND (NOT (LESSP 1.0E-9 ROUNDED 1.0E9)) (GO BARF))
		(SETQ NID (NDD\| (SETQ IPART (FIX ROUNDED))))
		(AND (MINUSP (SETQ NSPCS (- WIDTH FRAC 2 NID NSPCS))) (GO BARF))
		 ;Algebraic sign and space-fillers
		(AND LJUST (1OUT\| \+OR- file))
		(REPEAT-OUT\| NSPCS FILLER file)
		(AND (NOT LJUST) (1OUT\| \+OR- file))
		(AND (NOT (= CANDIDATE (FSC CANDIDATE 0))) (1OUT\| #\# file))
		 ;Integer part, decimal point
		(NOUT\| IPART file)
		(1OUT\| #\. file)
		(COND ((NOT (ZEROP FRAC))
			(SETQ FPART (FIX (*$ (10E FRAC)
					     (-$ ROUNDED (FLOAT IPART)))))
			 ;Zeros at right of .
			(REPEAT-OUT\| (- FRAC (NDD\| FPART)) #\0 file)
			(NOUT\| FPART file)))
		(RETURN (COND ((NULL EXPLODE)) ((NREVERSE (CDR EXPLODE)))))
	   BARF (AND (NOT (MEMQ 'ERROR OPTIONS)) (RETURN () ))
		(ERROR  (LIST 'PRINT-FIXED-FIELD-FLOATING CANDIDATE WIDTH FRAC OPTIONS)
			'|OUT OF RANGE|
			'FAIL-ACT)))
  )



(DEFUN PRINT-FIXED-PRECISION-FLOATING
	     (ICANDIDATE IWIDTH IPREC &OPTIONAL OPTIONS FILE (BAL 1))
     (DECLARE (FIXNUM IPART NID FPART INT FRAC PREC EPART WIDTH NSPCS LO HI
		      ELOW EHIGH )
	      (FLONUM CANDIDATE ROUNDED))
     (LET ((BASE 10.) (\+OR- #\SPACE) (FILLER #\SPACE))
	  (PROG (*NOPOINT EXPLODE ROUNDED IPART NID INT ELOW EHIGH TEM EFLAG
		  FPART FRAC EPART NSPCS LJUST LO HI CANDIDATE WIDTH PREC)
		(SETQ CANDIDATE (COND ((FLOATP ICANDIDATE) ICANDIDATE)
				      ((FLOAT ICANDIDATE)))
		      WIDTH (COND ((EQ (TYPEP IWIDTH) 'FIXNUM) IWIDTH)
				  ((GO BARF)))
		      PREC (COND ((EQ (TYPEP IPREC) 'FIXNUM) IPREC)
				 ((GO BARF))))
		(SETQ  ROUNDED (FSC CANDIDATE 0))
		(SETQ FPART -1 IPART 0 FRAC PREC NID 0
		      INT 1 ELOW -3 EHIGH 8
		      LJUST (OUT-SET\| OPTIONS)
		      EFLAG (MEMQ 'E OPTIONS)
		      *NOPOINT 'T
		      NSPCS (COND ((= ROUNDED CANDIDATE) 0) (1))
		      ROUNDED (ABS ROUNDED))
		(COND ((NOT (ATOM BAL))
		       (AND (EQ (TYPEP (SETQ TEM (CAR BAL))) 'FIXNUM)
			    (SETQ INT TEM))
		       (AND (EQ (TYPEP (SETQ TEM (CADR BAL))) 'FIXNUM)
			    (AND (< (SETQ ELOW TEM) -11.)
				 (GO BARF)))
		       (AND (EQ (TYPEP (SETQ TEM (CADDR BAL))) 'FIXNUM)
			    (AND (> (SETQ EHIGH TEM) 11.)
				 (GO BARF))))
		      ((EQ (TYPEP BAL) 'FIXNUM) (SETQ INT BAL)))
		(AND (MINUSP CANDIDATE) (SETQ \+OR- #\-))
		(SETQ EPART (COND ((< ROUNDED #.(FSC 4_24. 0))
				   (COND ((NOT (ZEROP ROUNDED)) (GO BARF))
					 (T (SETQ NID 1 FPART 0) (GO B))))
				  ((AND (< ROUNDED 3.4359738E+10) (>= ROUNDED 1.0))
				   (1- (NDD\| (FIX ROUNDED))))
				  ((LG10\| ROUNDED))))
		(AND (NOT (LESSP 0 PREC 9.)) (GO BARF))
		(SETQ LO (- EPART PREC))
		(COND ((COND ((> LO 36.) (< ROUNDED 1.5E38))
			     ((> LO -39.)))
			 ;Round, if number not too small
			(SETQ ROUNDED (+$ ROUNDED (*$ 0.5 (10E (1+ LO)))))
			 ;Rounding may cause overflow to next power of 10.0
			(AND (>= ROUNDED (+$ (10E (SETQ HI (1+ EPART)))
					     (\.10E HI)))
			     (SETQ EPART HI LO (1+ LO)))))
		(COND (EFLAG)
		      ((OR (> EPART EHIGH) (< EPART ELOW)) (SETQ EFLAG 'T))
		      ((MINUSP EPART)
		        ;IPART stays 0
		       (SETQ FRAC (1- (ABS LO)) NID 1))
		      (T (SETQ NID (NDD\| (SETQ IPART (FIX ROUNDED)))
			       FRAC (- PREC NID))
			 (AND (NOT (PLUSP FRAC))
			      (OR (NOT (= FILLER #\0)) (> (+ NID 2) WIDTH))
			      (SETQ EFLAG 'T))))
		(COND (EFLAG
			(AND (OR (MINUSP INT) (> INT 8)) (GO BARF))
			(SETQ FRAC (- PREC INT) EPART (- EPART INT -1))
			(SETQ ROUNDED
			      (COND ((= EPART 39.) (*$ 10.0 (*$ ROUNDED 1.0E38)))
				    ('T  ;Normalize into proper interval
				         ;e.g., 1.0 <= ROUNDED < 10.0
				        (+$ (*$ ROUNDED (10E (- EPART)))
					    (*$ ROUNDED (\.10E (- EPART)))))))
			(SETQ NID (NDD\| (SETQ IPART (FIX ROUNDED))))
			(COND ((COND ((ZEROP INT) (< ROUNDED .1))
				     ((< NID INT))
				     ((ZEROP IPART) (NOT (ZEROP ROUNDED))))
			        ;Because of truncation in \|.10S, and roundings
			        ; in multiplication, possibly ROUNDED is a bit
			        ; too high or too low
			       (SETQ ROUNDED (*$ ROUNDED 10.0)
				     EPART (1- EPART) NID -1))
			      ((COND ((ZEROP INT) (>= ROUNDED 1.0))
				     ((> NID INT)))
				(SETQ ROUNDED (//$ ROUNDED 10.0)
				      EPART (1+ EPART) NID -1)))
			(AND (MINUSP NID)
			     (SETQ NID (NDD\| (SETQ IPART (FIX ROUNDED)))))))

	   B	(COND ((PLUSP FRAC)
		         ;Maybe hafta strip out fraction part from "ROUNDED"
		       (AND (MINUSP FPART)
			    (SETQ FPART (FIX (*$ (COND ((ZEROP IPART) ROUNDED)
						       ((-$ ROUNDED (FLOAT IPART))))
						 (10E FRAC)))))
			(COND ((= FILLER #\0))
			      ((ZEROP FPART) (SETQ FRAC 1))
			      ((PROG ()
				      ;Suppress trailing zeros
				  A  (AND (NOT (ZEROP (\ FPART 10.))) (RETURN () ))
				     (SETQ FPART (// FPART 10.) FRAC (1- FRAC))
				     (GO A)))))
		      (T (AND (MINUSP FRAC) (SETQ HI (FIX (10E (- FRAC)))
						  IPART (* (// IPART HI) HI)))
			 (SETQ FRAC 1 FPART 0)))
		(SETQ NSPCS (- WIDTH
			       NID
			       FRAC
			       NSPCS
			       (COND ((NOT EFLAG)
				      2)
				     ((OR (= FILLER #\0) 	;EXPONENT FIELD
					  (> EPART 9.)		; IS EITHER 5
					  (< EPART -9.))	; OR 6 PLACES
				      6)			; xx.yyE+5
				     (5))))			; xx.yyE+05
		(AND (MINUSP NSPCS) (GO BARF))
		 ;Space fillers (if necessary) and algebraic sign
		(AND (NULL LJUST) (REPEAT-OUT\| NSPCS #\SPACE  file))
		(1OUT\| \+OR- file)
		(AND (NOT (= CANDIDATE (FSC CANDIDATE 0))) (1OUT\| #\# file))
		 ;Integer part, decimal point, zeros at right of .
		(NOUT\| IPART file)
		(1OUT\| #\. file)
		(COND ((NOT (ZEROP FRAC))
			(REPEAT-OUT\| (- FRAC (NDD\| FPART)) #\0 file)
			(NOUT\| FPART file)))
		(COND (EFLAG
			(1OUT\| #\E file)
			(1OUT\| (COND ((MINUSP EPART)
				       (SETQ EPART (- EPART))
				       #\-)
				      (#\+))
				file)
			(AND (= FILLER #\0)
			     (< EPART +10.)
			     (1OUT\| #\0 file))
			(NOUT\| EPART file)))
		(AND LJUST (REPEAT-OUT\| NSPCS #\SPACE  file))
		(RETURN (COND ((NULL EXPLODE)) ((NREVERSE (CDR EXPLODE)))))
	   BARF (AND (NOT (MEMQ 'ERROR OPTIONS)) (RETURN () ))
		(ERROR  (LIST 'PRINT-FIXED-PRECISION-FLOATING CANDIDATE WIDTH PREC OPTIONS BAL)
			'|OUT OF RANGE|
			'FAIL-ACT))))



(DEFUN PRINT-FIXED-FIELD-FIXED
       (CANDIDATE WIDTH &OPTIONAL (FOOBASE BASE) OPTIONS FILE)
   (DECLARE (FIXNUM WIDTH BASE BITS NID NSPCS))
   (LET ((BASE BASE) (*NOPOINT 'T) (\+OR- #\SPACE) (FILLER #\SPACE))
	(PROG (EXPLODE NID BITS NSPCS LJUST TEM)
	      (AND (NOT (FIXP CANDIDATE))  (SETQ CANDIDATE (FIX CANDIDATE)))
	      (AND (OR (NOT (EQ (TYPEP FOOBASE) 'FIXNUM))
		       (< FOOBASE 2)
		       (> FOOBASE 36.))
		   (GO BARF))
	      (SETQ BASE FOOBASE LJUST (OUT-SET\| OPTIONS))
	      (AND (= FILLER #\0) (SETQ LJUST T))
	      (AND (MINUSP CANDIDATE)
		   (SETQ \+OR- #\-  CANDIDATE (ABS CANDIDATE)))
	      (SETQ  BITS (HAULONG CANDIDATE)
		     NID (COND ((= BASE 8.) (1+ (// (1- BITS) 3)))
			       ((AND (< BITS 127.) (= BASE 10.))
				(COND ((< BITS 36.) (NDD\| CANDIDATE))
				      ((1+ (LG10\| (FLOAT CANDIDATE))))))
			       ('T (SETQ TEM (//$ (LOG (FLOAT CANDIDATE))
						  (LOG BASE)))
				   (COND ((= TEM
					     (FLOAT (SETQ TEM (IFIX TEM))))
					  TEM)
					 ((1+ TEM))))))
	      (SETQ NSPCS (- WIDTH NID (COND ((OR *NOPOINT (NOT (= BASE 10.)))
					      1)
					     (2))))
	      (AND (MINUSP NSPCS) (GO BARF))
	      (AND LJUST (1OUT\| \+OR- file))
	      (REPEAT-OUT\| NSPCS FILLER file)
	      (AND (NOT LJUST) (1OUT\| \+OR- file))
	      (NOUT\| CANDIDATE file)
	      (RETURN (COND ((NULL EXPLODE)) ((NREVERSE (CDR EXPLODE)))))
	BARF  (AND (NOT (MEMQ 'ERROR OPTIONS)) (RETURN () ))
	      (ERROR (LIST 'PRINT-FIXED-FIELD-FIXED CANDIDATE WIDTH BASE OPTIONS)
		     '|OUT OF RANGE|
		     'FAIL-ACT))))



;COMPUTES INTEGRAL PART OF BASE-10.-LOG OF INPUT
(DEFUN LG10\| (ROUNDED)
  (DECLARE (FLONUM ROUNDED) (FIXNUM LO HI EPART))
  (PROG (LO MID HI)
	;Approximation to exponent of 10.
	(SETQ HI (FIX (+$ .5 (TIMES (- (LSH ROUNDED -27.) 128.) 0.30103)))
	      LO (- HI 4))
	(AND (< LO -38.) (SETQ LO -39.))
    A   (COND ((>= ROUNDED (10E (SETQ MID (// (+ HI LO) 2))))
		 (SETQ LO MID))
	      (T (SETQ HI MID)))
	(AND (> (- HI LO) 1) (GO A))
	(RETURN (COND ((>= ROUNDED (+$ (10E HI) (\.10E HI))) HI)
		      ((>= ROUNDED (+$ (10E LO) (\.10E LO))) LO)
		      (T (1- LO))))))


;NUMBER OF DECIMAL DIGITS IN A FIXNUM
(DEFUN NDD\| (N)
  (DECLARE (FIXNUM N))
  (COND ((< N 100000000.)
	 (COND ((< N 10000.)
		(COND ((< N 100.) (COND ((< N 10.) 1) (2)))
		      ((< N 1000.) 3)
		      (4)))
	       (T (COND ((< N 1000000.) (COND ((< N 100000.) 5) (6)))
			((< N 10000000.) 7)
			(8.)))))
	((< N 10000000000.) (COND ((< N 1000000000.) 9.) (10.)))
	(11.)))



(DEFUN OUT-SET\| (OPTIONS)
      ;Set up some global variables right at the outset
  (DO ((Y OPTIONS (CDR Y)) (FL))
      ((NULL Y) FL)
    (COND ((EQ (CAR Y) 'LEFT) (SETQ FL T))
	  ((EQ (CAR Y) '\.) (SETQ *NOPOINT () ))
	  ((MEMQ (CAR Y) '(EXPLODE EXPLODEC EXPLODEN))
	   (SETQ EXPLODE (LIST (EQ (CAR Y) 'EXPLODEN))))
	  ((EQ (CAR Y) '\+) (SETQ \+OR- #\+))
	  ((OR (EQ (CAR Y) '\0) (SIGNP E (CAR Y))) (SETQ FILLER #\0)))))


(DEFUN 1OUT\| (CHAR FILE)
    (COND ((NULL EXPLODE) (TYO CHAR FILE))
	  ((RPLACD EXPLODE (CONS (COND ((CAR EXPLODE) CHAR)
				       ((ASCII CHAR)))
				 (CDR EXPLODE)))))
    () )

(DEFUN NOUT\| (X FILE)
    (COND ((NULL EXPLODE) (PRIN1 X FILE))
	  ((RPLACD EXPLODE (NRECONC (COND ((CAR EXPLODE) (EXPLODEN X))
					  ((EXPLODE X)))
				    (CDR EXPLODE)))))
    () )


(DEFUN REPEAT-OUT\| (N CHAR FILE)
    (DECLARE (FIXNUM N I))
    (AND (PLUSP N)  (DO I N (1- I) (ZEROP I) (1OUT\| CHAR FILE))))




;CODE TO INITIALIZE THESE TWO FOOLISH ARRAYS
(AND (OR (NULL (GET '\|10S 'ARRAY)) (NULL (ARRAYDIMS '\|10S)))
 (PROGN (ARRAY \|10S FLONUM 79.)
	(ARRAY \|\.10S FLONUM 79.)
	 ;Smallest magnitude normalized, floating-point number
	(STORE (\|10S 0) #.(FSC 4_24. 0))
	 ;Largest magnitude normalized, floating-point number
	(STORE (\|10S 78.) #.(FSC 377777777777 0))
	 ;Second word of double-precision
	(STORE (\|\.10S 78.) #.(FSC 344377777777 1_18.))
	 ;A well-known constan
	(STORE (\|10S 39.) 1.0)
	(COND ((STATUS FEATURE BIGNUM)
		(DO ((I 40. (1+ I)) (VAL 10. (TIMES VAL 10.)) (T1) (T2) (L) (INV))
		    ((= I 78.))
		  (COND ((> (SETQ L (HAULONG VAL)) 53.)
			 (SETQ T1 (HAIPART VAL 27.) T2 (HAIPART (HAIPART VAL 54.) -27.)))
			((> L 26.) (SETQ T1 (HAIPART VAL 27.) T2 (LSH (HAIPART VAL (- 27. L)) (- 54. L))))
			(T (SETQ T1 (LSH VAL (- 27. L)) T2 0)))
		  (STORE (\|10S I) (FSC T1 (+ 128. L)))
		  (AND (PLUSP T2)
		       (STORE (\|\.10S I)
			      (FSC (BOOLE 7 (LSH (+ 101. L) 27.) T2) 1_18.)))
		  (STORE (\|10S (- 78. I))
			 (FSC (HAIPART (SETQ INV (*QUO #.(EXPT 2 181.) VAL)) 27.)
			      (- 129. L)))
		  (AND (< I 70.)
		       (STORE (\|\.10S (- 78. I))
			      (FSC (BOOLE 7
					  (LSH (- 102. L) 27.)
					  (HAIPART (HAIPART INV 54.) -27.))
				   1_18.)))))
	      ((DO ((I 40. (1+ I)) (VAL 10.0 (*$ VAL 10.0)))
		   ((= I 78.))
		(STORE (\|10S I) VAL)
		(STORE (\|10S (- 78. I)) (QUOTIENT 1.0 VAL)))))))
