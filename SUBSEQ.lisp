;;;   SUBSEQ   				-*-Mode:Lisp;Package:SI;Lowercase:T-*-
;;;   ************************************************************************
;;;   *** NIL ******* SUBSEQuencing and coercion functions *******************
;;;   ************************************************************************
;;;   ** (c) Copyright 1981 Massachusetts Institute of Technology ************
;;;   ************************************************************************

;;; SUBSEQ and REPLACE are seen as a specific usage of the "coercion"
;;;   functions.
;;; General coercion routines TO-<mumble>, which take in any kind of
;;;    sequence, and give out a corresponding sequence of type <mumble>.
;;; Additionally, in this file is TO-CHARACTER, TO-CHARACTER-N, TO-BIT,
;;;    and TO-UPCASE .


(herald SUBSEQ /39)


#+(or LISPM (and NIL (not MacLISP)))
(progn 'compile  
	(globalize "SUBSEQ")
	(globalize "REPLACE")
	(globalize "TO-LIST")
	(globalize "TO-VECTOR")
	(globalize "TO-STRING")
	(globalize "TO-BITS")
	(globalize "TO-CHARACTER")
	(globalize "TO-CHARACTER-N")
	(globalize "TO-CHARACTER-N?")
	(globalize "TO-SYMBOL")
	(globalize "TO-BIT")
	(globalize "TO-UPCASE")
)

#-NIL 
(eval-when (eval compile)
  (or (get 'SUBLOAD 'VERSION)
      (load '((lisp) subload)))
  (subload SHARPCONDITIONALS)
  (subload EXTMAC)	;also gets MACAID, ERRCK,
  (subload EXTHUK)
  (setq-if-unbound *:bits-per-character #Q 8 #-LISPM 7)
)

#-NIL 
(eval-when (eval compile load)
    (subload EXTEND)
)
  


#+(local MacLISP)
(declare (own-symbol LENGTH  *:FIXNUM-TO-CHARACTER   GET-PNAME)
	 (own-symbol SUBSEQ REPLACE TO-LIST TO-VECTOR TO-STRING TO-BITS))
    
;;; Here's some particular macro definitions and declaractions,
;;;  knowing that the intended target is with the other maclisp 
;;;  NILCOM software.
#+(local MacLISP)
  (declare (*expr LENGTH  *:FIXNUM-TO-CHARACTER  TO-CHARACTER-N?  
		  GET-PNAME  MAKE-BITS  STRING-PNGET)
	   (*LEXPR MAKE-STRING STRING-REPLACE STRING-SUBSEQ STRING-MISMATCHQ 
		   STRING-POSQ STRING-POSQ-N STRING-BPOSQ STRING-BPOSQ-N )
	   (FIXNUM (+INTERNAL-CHAR-N () FIXNUM))
	   (NOTYPE (+INTERNAL-RPLACHAR-N () FIXNUM FIXNUM)))


#-NIL 
(eval-when (eval compile)
  (setq defmacro-for-compiling () defmacro-displace-call () )
  (defmacro STRING-LENGTH (x) `(SI:XREF ,x 1)) 
  (defmacro BITS-LENGTH (x) `(SI:XREF ,x 1))
  (defmacro VECTOR-LENGTH (&rest w) `(SI:EXTEND-LENGTH ,.w))
  (defmacro EXTEND-LENGTH (&rest w) `(SI:EXTEND-LENGTH ,.w))
  (defmacro SI:EXTEND-LENGTH (x) `(- (HUNKSIZE ,x) 2))
  (defmacro MAKE-VECTOR (n) `(SI:MAKE-EXTEND ,n VECTOR-CLASS))
  (defmacro VREF (&rest w) `(SI:XREF ,.w))
  (defmacro VSET (&rest w) `(SI:XSET ,.w))
  #M (progn 'compile 
       (defmacro *:CHARACTER-TO-FIXNUM (c) `(MAKNUM (SI:XREF ,c 0)))
       (defmacro SI:SYMBOL-CONS (x)
	  `(PNPUT (STRING-PNGET ,x 7) () ))
       (and (status feature COMPLR)
	    (SPECIAL |+internal-CHARACTER-table/||))
       )
  #Q (progn 'compile 
      (defmacro *:CHARACTER-TO-FIXNUM (VAL) `(AR-1 ,val 1))
     )
  #-(local PDP10) (progn 'compile 
	(defmacro +INTERNAL-CHAR-N (&rest w) `(CHAR-N ,.w)) 
	(defmacro +INTERNAL-RPLACHAR-N (&rest w) `(RPLACHAR-N ,.w)) )
  (setq defmacro-for-compiling 'T defmacro-displace-call 'T )
  )


#M (eval-when (eval load compile)
	(and (status feature complr)
	     (*lexpr SUBSEQ REPLACE TO-LIST TO-VECTOR TO-STRING TO-BITS)))



;;;; SUBSEQ,  REPLACE, and coercions  TO-<mumble>


(defun SUBSEQ (str &OPTIONAL (i 0) (cnt () cntp))
       (SI:replacer () str 0 i cnt cntp () ))

(defun REPLACE (v1 v2 &optional (i1 0) (i2 0) (cnt () cntp))
       (SI:replacer v1 v2 i1 i2 cnt cntp () ))


(defun TO-LIST (str &OPTIONAL (i 0) (cnt () cntp))
       (SI:replacer () str 0 i cnt cntp 'LIST))

(defun TO-VECTOR (str &OPTIONAL (i 0) (cnt () cntp))
       (SI:replacer () str 0 i cnt cntp 'VECTOR))

(defun TO-STRING (ob &OPTIONAL (i 0) (cnt () cntp))
   (cond 
     ((and (= i 0) 
	   (null cntp) 
	   (typecaseq ob 
		(STRING 'T)
		(SYMBOL (setq ob (get-pname ob)) 'T)
		(FIXNUM (setq ob (+internal-rplachar-n (make-string 1) 0 ob)) 
			'T)
		(CHARACTER (setq ob (+internal-rplachar-n 
				      (make-string 1) 
				      0 
				      (*:character-to-fixnum ob)))
			'T)))
       ob)
     ('T (SI:replacer () ob 0 i cnt cntp 'STRING))))

(defun TO-BITS (ob &OPTIONAL (i 0) (cnt () cntp))
   (cond ((and (= i 0) 
	       (null cntp) 
	       (typecaseq ob 
		  (BITS 
		   'T)
		  ((FIXNUM CHARACTER) 
		   (setq ob (rplacbit (make-bits 1) 1 (to-bit ob))) 
		   'T)))
	  ob)
	 ('T (if (symbolp ob) (setq ob (get-pname ob)))
	     (SI:replacer () ob 0 i cnt cntp 'BITS))))



;;;; TO-CHARACTER

(defvar SI:COERCION-ERROR-STRING  "~1G~S is not coercible to a ~0G~A")


(defbothmacro TO-CHARACTER (c) 
    `(*:FIXNUM-TO-CHARACTER (TO-CHARACTER-N? ,c () )))

(defbothmacro TO-CHARACTER-N (c) `(TO-CHARACTER-N? ,c () ))


(defun TO-CHARACTER-N? (char no-error?)
  #+(and (not NIL) (local PDP10)) 
   (subload STRING)
   (prog (nc) 
     A   (setq nc (typecaseq char
		     (CHARACTER (*:character-to-fixnum char))
		     (FIXNUM (if (and (>= char 0)
				      (< char #.(^ 2 *:bits-per-character)))
				 char))
		     (STRING (cond ((= (string-length char) 0) 0)
				   ((+internal-char-n char 0))))
		     (SYMBOL (cond ((= (flatc char) 0) 0)    ;More efficient
				   ((getcharn char 1))))     ; than get-pname
		     (T () )))
	 (if (or nc no-error?) (return nc))
	 (setq char (cerror 'T () ':WRONG-TYPE-ARGUMENT 
			    SI:COERCION-ERROR-STRING 'CHARACTER char))
	 (go A)))


;;;; SI:replacer


(defun SI:replacer (new str i1 i2 cnt cntp coercion? 
			#N &optional #N (rset 'T))
   (let ((cnt1 cnt)  (cnt2 cnt)
	 (l1 0) (l2 0)
	 (ty1p) (ty2p)
	 (*RSET #-NIL *RSET  
		#+NIL rset)  
	 )
     (declare (fixnum l1 l2))
     (cond 
       (*RSET 
	   (check-subsequence (str i2 cnt2) () 'SI:replacer 'T cntp)
	   (cond (new 
		  (if (and cntp (fixnump cnt1) (not (= cnt1 cnt2)))
		      (setq cnt1 cnt2))
		   (check-subsequence (new i1 cnt1) () 'SI:replacer 'T cntp)
		   (if (or (null cntp) (not (= cnt cnt1)) (not (= cnt cnt2)))
		       (setq cnt (if (< cnt1 cnt2) cnt1 cnt2))))
		 ('T (setq cnt cnt2)))
	   (setq cntp 'T)))
     (prog () ;; PROG-ification only for use by RETURN
	 ;; First, calculate type and lengths of primary "sequence" argument
	 ;; The types will be encoded as   0 - LIST   1 - VECTOR   2 - EXTEND 
	 ;;   3 - STRING   4 - BITS   5 - Other
       (typecaseq str 
		(PAIR (setq ty2p 0 l2 (length str)))
		(STRING (setq ty2p 3 l2 (string-length str)) )
		(VECTOR (setq ty2p 1 l2 (vector-length str)))
		(EXTEND (setq ty2p 2 l2 (extend-length str)))
		(BITS (setq ty2p 4 l2 (bits-length str)))
		(T (cond ((null str) (setq ty2p 0 l2 0))
			 ((or (null coercion?) (sequencep str))
			   (+internal-lossage '|Not yet coded| 'SI:REPLACER str))
			 ('T (setq str (list str) ty2p 0 l2 1)))))
       (if (and cntp (< l2 cnt)) (setq cnt l2))
	 ;; Calculate type and length of output sequence, if supplied by caller
       (cond (new 
	      (typecaseq new 
		   (PAIR (setq ty1p 0 l1 (length new)))
		   (STRING (setq ty1p 3 l1 (string-length new)) )
		   (VECTOR (setq ty1p 1 l1 (vector-length new)))
		   (EXTEND (setq ty1p 2 l1 (extend-length new)))
		   (BITS (setq ty1p 4 l1 (bits-length new)))
		   (T (+internal-lossage '|Not yet coded| 'SI:REPLACER new)))
	      (cond ((null cntp) 
		     (let ((n1 (- l1 i1))
			   (n2 (- l2 i2)))
		       (declare (fixnum n1 n2))
		       (if (< n1 n2) 
			   (setq cnt n1) 
			   (setq cnt n2))
		       (setq cntp 'T)))
		    ((< l1 cnt) (setq cnt l1))))
	     ('T  ;;Create output sequence, if not supplied;  default type 
		  ;; of output  to that of primary "sequence" argument.
		(if (null cntp) (setq cnt (- l2 i2)))
		(setq ty1p (cond ((null coercion?) ty2p)
				 ((cdr (assq coercion? '((LIST . 0) 
							 (STRING . 3)
							 (VECTOR . 1)
							 (EXTEND . 2)
							 (BITS . 4)))))
				 (5)))
		(if (and (= ty1p ty2p) (= i2 0) (= cnt l2) )
		    (return str))
		(setq new (caseq ty1p   
				 (0 (make-list cnt))		;LIST
				 (3 (make-string cnt))		;STRING
				 (1 (make-vector cnt))		;VECTOR
				 (4 (make-bits cnt))		;BITS
				 (2 (si:make-extend cnt (si:extend-class-of str)))
				 (T (+internal-lossage '|Not yet coded| 'SI:REPLACER () ))))))
	 ;; Use fast code on string-to-string movement; also for bits-to-bits
       (cond ((and (= ty1p ty2p) 
		   (or (= ty1p 4)		;BITS
		       #-Lispm (= ty1p 3) )	;STRING
		   )
	      (return 
	        (let (*RSET)
		   (caseq ty2p
			  (3 (string-replace new str i1 i2 cnt))
			  ;(1 (vector-replace new str i1 i2 cnt)) ??
			  (4 (bits-replace new str i1 i2 cnt)) )))))
	(and (= ty2p 0) (setq str (nthcdr i2 str)))	;LIST case
	 ;; Loop to move from one to the other, coercing each item as you go
	(let ((fwp 1) (ix1 i1) (ix2 i2) item 
	      (newl (and (= ty1p 0) (nthcdr i1 new))))
	  (declare (fixnum ix1 ix2 fwp))
	    ;;May have to move in the backwards direction, from the top,
	    ;; if the fields overlap.
	  (cond ((and (eq new str)
		      (< ix2 ix1)
		      (>= (+ ix2 cnt) ix1))
		  (if (= ty2p 0) 	;LIST case
		      (+internal-lossage "LIST-REPLACEing over self" 'SI:REPLACER () ))
		  (setq ix1 (+ ix1 cnt -1) ix2 (+ ix2 cnt -1))
		  (setq fwp -1)))
	  (do ((n 0 (1+ n)))
	      ((>= n cnt))
	    (declare (fixnum n))
	        (setq item (caseq ty2p 
				  (3 (+internal-char-n str ix2))
				  (1 (vref str ix2))
				  (2 (si:xref str ix2))
				  (0 (pop str))
				  (4 (bit str ix2))
				  (T (elt str ix2))))
		(caseq ty1p  
		       (3  (+internal-rplachar-n new 
						 ix1 
						 (to-character-n item)))
		       (1  (vset new ix1 item))
		       (0  (rplaca newl item) (pop newl))
		       (4  (rplacbit new ix1 (to-bit item)))
		       (2  (si:xset new ix1 item))
		       (T  (setelt str ix1)))
	     (setq ix1 (+ ix1 fwp) ix2 (+ ix2 fwp))))
	(return new))))


;;;; TO-SYMBOL, TO-BIT, TO-UPCASE 

(defun TO-SYMBOL (x)
   (cond ((symbolp x) x)
	 ((si:symbol-cons (to-string x)))))

(defun TO-BIT (x) 
   (prog (y)
      B	 (setq y x)
      A	 (typecaseq y 
	    (FIXNUM    (and (>= y 0) (return (boole 1 1 y))))
	    (STRING    (and (= 1 (string-length y)) 
			    (setq y (+internal-char-n y 0))
			    (go A)))
	    (CHARACTER (setq y (*:character-to-fixnum y))
		       (and (and (<= #/0 y) (<= y #/1)) 
			    (return (boole 1 1 y))))
	    (SYMBOL    (setq y (*:fixnum-to-character (getcharn y 1)))
		       (go A))
	    (T 	   () ))
	 (setq x (cerror 'T () ':WRONG-TYPE-ARGUMENT 
			 SI:COERCION-ERROR-STRING 'BIT y))
	 (go B)))



(defun TO-UPCASE (x)
   (typecaseq x
      (FIXNUM (char-upcase x))
      (CHARACTER
       (*:fixnum-to-character (char-upcase (*:character-to-fixnum x))))
      (STRING (string-upcase x))
      (SYMBOL (to-symbol (string-upcase (to-string x))))
      (PAIR (mapcar #'TO-UPCASE x))
      (VECTOR (let ((ln (vector-length x)))
		   (do ((i (1- ln) (1- i))
			(new (make-vector ln)))
		       ((< i 0) new)
		     (vset new i (to-upcase (vref x i))))))
      (T (to-upcase
	  (cerror 'T () ':WRONG-TYPE-ARGUMENT SI:COERCION-ERROR-STRING 
		  'UPPER-CASE-OBJECT x)))))


#M 
(progn 'compile 
  (and (not (fboundp 'MAKE-LIST))
       (putprop 'MAKE-LIST 
		'(lambda (n) (do ((i n (1- i)) (z () (cons () z)))
				 ((< i 1) z)))
		'EXPR))
  (mapc '(lambda (x) (or (fboundp (car x))
			 (get (car x) 'AUTOLOAD)
			 (putprop (car x) (cadr x) 'AUTOLOAD)))
	'((PTR-TYPEP #.(autoload-filename EXTEND))
	  (MAKE-VECTOR #.(autoload-filename VECTOR)) 
	  (MAKE-STRING #.(autoload-filename STRING))
	  (GET-PNAME #.(autoload-filename STRING))
	  (STRING-REPLACE #.(autoload-filename STRING)) 
	  (+INTERNAL-RPLACHAR-N #.(autoload-filename STRING))
	  (MAKE-BITS #.(autoload-filename BITS))
	  (RPLACBIT #.(autoload-filename BITS)) 
	  (BITS-REPLACE #.(autoload-filename BITS))))
  )
