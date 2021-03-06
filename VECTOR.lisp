;;;  VECTOR    				-*-Mode:Lisp;Package:SI;Lowercase:T-*-
;;;  **************************************************************************
;;;  *** MacLISP ******** VECTOR support **************************************
;;;  **************************************************************************
;;;  ******** (c) Copyright 1981 Massachusetts Institute of Technology ********
;;;  **************************************************************************

(herald VECTOR /71)

;; This file can be run interpretively only in a COMPLR
;;  due to the use of DEFCOMPLRMAC


(include ((lisp) subload lsp))

(eval-when (eval compile)
  (setq USE-STRT7 'T MACROS () )
  (subload MACAID)
  (subload UMLMAC)
   ;; Remember, EXTMAC down-loads CERROR
  (subload EXTMAC)
  (subload DEFSETF)
  (subload SUBSEQ)
  (subload LOOP)
  (setq defmacro-for-compiling 'T defmacro-displace-call MACROEXPANDED)

 )


(eval-when (eval load compile)
    (subload EXTEND)
    (if (fboundp 'SPECIAL) (special VECTOR-CLASS))
)

(def-or-autoloadable FLUSH-MACROMEMOS DEFMAX)


(define-loop-path (vector-elements vector-element)
		  si:loop-sequence-elements-path
		  (of from to below above downto in by)
		  vref vector-length vector notype)


;;;; VECTORP,VREF,VSET,MAKE-VECTOR,VECTOR,VECTOR-LENGTH,SET-VECTOR-LENGTH

(defun VECTORP (x) (eq (ptr-typep x) 'VECTOR))

(defcomplrmac VREF (v n) `(SI:XREF ,v ,n))
(defun VREF (seq index)
  (when *RSET
	(let ((cnt 1))
	  (check-subsequence (seq index cnt) 'VECTOR 'VREF)))
  #%(vref seq index))

(defsetf VREF ((() seq index) val) ()
   `(VSET ,seq ,index ,val))


(defcomplrmac VSET (v n val) `(SI:XSET ,v ,n ,val))
(defun VSET (seq index val)
  (when *RSET
	(let ((cnt 1))
	  (check-subsequence (seq index cnt) 'VECTOR 'VREF)))
  #%(vset seq index val)
  seq)


(defcomplrmac MAKE-VECTOR (n) `(SI:MAKE-EXTEND ,n VECTOR-CLASS))
(defun MAKE-VECTOR (n) 
   (when *RSET (check-type n #'SI:MAX-EXTEND-SIZEP 'MAKE-VECTOR))
   #%(make-vector n))

(defcomplrmac VECTOR (&rest x) `(SI:EXTEND VECTOR-CLASS ,.x))
(defun VECTOR n
   (when *RSET (check-type n #'SI:MAX-EXTEND-SIZEP 'VECTOR))
   (let ((v (make-vector n)))
     (dotimes (i n) (vset v i (arg (1+ i))))
     v))


(defcomplrmac VECTOR-LENGTH (v) `(SI:EXTEND-LENGTH ,v))
(defun VECTOR-LENGTH (seq)
  (when *RSET (check-type seq #'VECTORP 'VECTOR-LENGTH))
  #%(vector-length seq))



(defun SET-VECTOR-LENGTH (seq newsize)
  (when *RSET
	(let ((i 0))
	  (check-subsequence (seq i newsize) 'VECTOR 'SET-VECTOR-LENGTH)))
   ;; What a crock!
  (do ((max (1- (hunksize seq)))
       (i (+ 2 newsize))
       (crock (munkam #o777777)))
      ((> i max))
    (rplacx i seq crock))
  seq)


(defun |&restv-ify/|| (n &aux allp)
    ;; Cooperates with output of DEFUN& to snarf args off pdl and into a VECTOR
   (declare (fixnum n arg-offset))
   (cond ((< n 0) (setq n (- n)))	;Take ABS of 'n'
	 ('T (setq allp 'T)))		;Are we getting all the args?
   (let ((v (make-vector n))
	 (arg-offset (if allp 
			 1 
			 (- (arg () ) n -1))))
     (dotimes (i n) (vset v i (arg (+ i arg-offset))))
     v))



(defun |#-MACRO-/(| (x) 		;#(...) is VECTOR notation
   (let ((form (read)) v)
     (if (or x 
	     (and form (atom form))
	     (and (setq x (cdr (last form))) (atom x)))
	 (error "Not a proper list for #/(" (list x form)))
     (setq v (make-vector (length form)))
     (dolist (item form i) (vset v i item))
     v))


(defvar /#-MACRO-DATALIST () )

;; An open-coding of SETSYNTAX-SHARP-MACRO
(push '(#/(T MACRO . |#-MACRO-/(| ) /#-MACRO-DATALIST)


;;;; DOVECTOR, VECTOR-POSASSQ, SI:COMPONENT-EQUAL, and SI:SUBST-INTO-EXTEND

(defmacro DOVECTOR ((var form index) &rest body &aux (cntr index) vec vecl)
   (or cntr (si:gen-local-var cntr))
   (si:gen-local-var vec)
   (si:gen-local-var vecl)
   `(LET ((,vec ,form))
      (DO ((,cntr 0 (1+ ,cntr))
	   (,var)
	   (,vecl (VECTOR-LENGTH ,vec)))
	  ((= ,cntr ,vecl))
	(DECLARE (FIXNUM ,cntr ,vecl))
	,.(and var (symbolp var) `((SETQ ,var (VREF ,vec ,cntr))))
	,.body)))

(def-or-autoloadable GENTEMP MACAID)

(defun VECTOR-POSASSQ (x v)
   (dovector (e v i) (and (pairp e) (eq x (car e)) (return i))))


;; called by EQUAL->VECTOR-CLASS and EQUAL->STRUCT-CLASS
(defun SI:COMPONENT-EQUAL (ob other)
   (let ((l1 (si:extend-length ob)) 
	 (l2 (si:extend-length other)))
     (declare (fixnum l1 l2 i))
     (and (= l1 l2)
	  (do ((i 0 (1+ i)))
	      ((= i l1) 'T)
	    (if (not (equal (si:xref ob i) (si:xref other i)))
		(return () ))))))

;; called by SUBST->VECTOR-CLASS and SUBST->STRUCT-CLASS
(defun SI:SUBST-INTO-EXTEND (ob a b)
   (let ((l1 (si:extend-length ob)))
     (declare (fixnum l1 i))
     (do ((i 0 (1+ i))
	  (newob (si:make-extend l1 (class-of ob))))
	 ((= i l1) newob)
       (si:xset newob i (subst a b (si:xref ob i))))))


;;;; Some methods

(defmethod* (EQUAL VECTOR-CLASS) (obj other-obj)
   (cond ((not (vectorp obj)) 
	   (+internal-lossage 'VECTORP 'EQUAL->VECTOR-CLASS obj))
	 ((not (vectorp other-obj)) () )
	 ((si:component-equal obj other-obj))))

(defmethod* (subst vector-class) (ob a b)
   (si:subst-into-extend ob a b))

(DEFVAR VECTOR-PRINLENGTH () )
(DEFVAR SI:PRINLEVEL-EXCESS '|#|)
(DEFVAR SI:PRINLENGTH-EXCESS '|...|)

(DEFMETHOD* (:PRINT-SELF VECTOR-CLASS) (OBJ STREAM DEPTH SLASHIFYP)
  (DECLARE (FIXNUM LEN I DEPTH))	
    ;Be careful where you put the declaration for LEN!
  (LET ((LEN (VECTOR-LENGTH OBJ)))
    (SETQ DEPTH (1+ DEPTH))
    (SETQ STREAM (SI:NORMALIZE-STREAM STREAM))
    (COND 
      ((= LEN 0) (PRINC "#()" STREAM))
      ((AND PRINLEVEL (NOT (< DEPTH PRINLEVEL))) 
        (PRINC SI:PRINLEVEL-EXCESS STREAM))
      ('T (PRINC "#(" STREAM)
	  (DO ((I 0 (1+ I)) FL)
	      ((= I LEN) )
	    (IF FL (TYO #\SPACE  STREAM) (SETQ FL 'T))
	    (COND ((OR (AND VECTOR-PRINLENGTH (NOT (> VECTOR-PRINLENGTH I)))
		       (AND PRINLENGTH (NOT (> PRINLENGTH I))))
		   (PRINC SI:PRINLENGTH-EXCESS STREAM)
		   (RETURN () )))
	    (PRINT-OBJECT (VREF OBJ I) DEPTH SLASHIFYP STREAM))
	  (TYO #/) STREAM)))))

(DEFMETHOD* (FLATSIZE VECTOR-CLASS) (OBJ PRINTP DEPTH SLASHIFYP
				       &AUX (LEN (VECTOR-LENGTH OBJ)))
  (AND DEPTH (SETQ DEPTH (1+ DEPTH)))
  (COND ((ZEROP LEN) 3)
	((AND DEPTH PRINLEVEL (NOT (< DEPTH PRINLEVEL))) 1)  ;?
	(PRINTP (+ 2 (FLATSIZE-OBJECT (VREF OBJ 0)
				      PRINTP
				      DEPTH
				      SLASHIFYP)))
	('T (DO ((I (1- LEN) (1- I))
		 (CNT 2 (+ CNT
			   (FLATSIZE-OBJECT (VREF OBJ I)
					    PRINTP
					    DEPTH
					    SLASHIFYP)
			   1)))
		((< I 0) CNT)
		(DECLARE (FIXNUM I CNT))))))



(DEFMETHOD* (SPRINT VECTOR-CLASS) (SELF N M)
    (IF (= (VECTOR-LENGTH SELF) 0)
	(PRINC "#()")
	(PROGN (SETQ SELF (TO-LIST SELF))
	       (PRINC '/#)
	       (SPRINT1 SELF (GRCHRCT) M))))

(DEFMETHOD* (GFLATSIZE VECTOR-CLASS) (OBJ)
  (DO ((LEN (VECTOR-LENGTH OBJ))
       (I 0 (1+ I))
       (SIZE 2 (+ SIZE (GFLATSIZE (VREF OBJ I)))))
      ((= I LEN)
       (COND ((= LEN 0) 3)
	     (T (+ SIZE LEN))))
      (DECLARE (FIXNUM MAX I SIZE))))


(DEFMETHOD* (SXHASH VECTOR-CLASS) (OB)
   (SI:HASH-Q-EXTEND OB #,(sxhash 'VECTOR)))

;;Someday we'd like this hook, but for now there is just the
;; complr feature that lets them go out as hunks.  Also, DEFVST
;; puts out a hunk with a computed value in the CDR which sill
;; be the value of VECTOR-CLASS if it exists.
;(DEFMETHOD* (USERATOMS-HOOK VECTOR-CLASS) (self)
;   (list `(TO-VECTOR ',(to-list self))))


(and (status status VECTOR) 
     (sstatus VECTOR (list (get 'VECTORP 'SUBR) 
			   (get 'VECTOR-LENGTH 'SUBR)
			   (get 'VREF 'SUBR))))

		       