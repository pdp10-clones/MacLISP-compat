;;; ERRCK    				-*-Mode:Lisp;Package:SI;Lowercase:T-*-
;;; **************************************************************************
;;; *** NIL ******** ERRor ChecKing and correcting ***************************
;;; **************************************************************************
;;; ** (c) Copyright 1981 Massachusetts Institute of Technology **************
;;; **************************************************************************

(herald ERRCK /30)

#-NIL (include ((lisp) subload lsp))

#-NIL 
(eval-when (eval compile)
  (subload SHARPCONDITIONALS)
  )

#+(or LISPM (and NIL (not MacLISP)))
(globalize "ERROR-RESTART"
	   "CHECK-ARG"
	   "CHECK-ARG-CONTROL-STRING"
	   "CHECK-TYPE"
	   "CHECK-SUBSEQUENCE" 
	   )

#-For-NIL 
(eval-when (eval compile)
  (subload UMLMAC)
  )



#M (declare (own-symbol ERROR-RESTART CHECK-ARG 
			CHECK-TYPE CHECK-SUBSEQUENCE 
			SI:CHECK-TYPER SI:CHECK-SUBSEQUENCER)
	    (*lexpr SEND))

#+(and MacLISP (not NIL))
(eval-when (eval load compile)
   (cond ((status feature COMPLR)
	  (*lexpr SI:CHECK-SUBSEQUENCER SI:LOST-MESSAGE-HANDLER)
	  (*expr SI:CHECK-TYPER)))
)



;;;; CHECK-ARG and ERROR-RESTART are LISPM compatible
;;;; CHECK-TYPE and CHECK-SUBSEQUENCE


(defmacro CHECK-ARG (var pred string &optional type complainant)
   (if (and (null type) (symbolp pred))
       (setq type pred))
   (if complainant (setq complainant `',complainant))
   (let ((termin (cond ((symbolp pred) `(,pred ,var)) 
		       ('T pred))))
     `(DO () 
	  (,termin ,var)
	(SETQ ,var (CERROR 'T () ':WRONG-TYPE-ARGUMENT
			   CHECK-ARG-CONTROL-STRING
			   ',type ,var ',var ,string ,complainant)))))

(defvar CHECK-ARG-CONTROL-STRING 
	'|The ~2G~S argument ~4G~:[~;to ~4G~S ~]was ~1G~S, which is not ~3G~A|)


(defmacro ERROR-RESTART (&rest forms)
   `(DO () (()) (*CATCH 'ERROR-RESTART (RETURN (PROGN ,.forms)))))



(defmacro CHECK-TYPE (var type-test-predicate using-function)
   (cond ((and var (symbolp var)) () ) 
	 ((fboundp 'si:check-typer)
	   (setq var (si:check-typer var #'SYMBOLP '|CHECK-TYPE MACRO|)))
	 ('T (error '|Not a SYMBOL| var)))
   `(SETQ ,var (SI:CHECK-TYPER ,var ,type-test-predicate ,using-function)))


(defmacro CHECK-SUBSEQUENCE ((seq start cnt) requisite-type using-function 
					     &optional (startp 'T) (cntp 'T)
					     &rest     rest)
  (or (and seq (symbolp seq)) 
      (setq seq (si:check-typer seq #'SYMBOLP '|CHECK-SUBSEQUENCE MACRO|)))
  (or (and start (symbolp start)) 
      (setq start (si:check-typer start #'SYMBOLP '|CHECK-SUBSEQUENCE MACRO|)))
  (cond 
    ((null cnt) (setq cntp () ))
    ((not (symbolp cnt)) 
      (setq cnt (si:check-typer cnt #'SYMBOLP '|CHECK-SUBSEQUENCE MACRO|))))
  `(MULTIPLE-VALUE (,seq ,start ,cnt) 
		   (SI:CHECK-SUBSEQUENCER ,seq ,start ,cnt 
					  ,requisite-type ,using-function 
					  ,startp ,cntp ,. rest)))



;;;; SI:CHECK-TYPER and SI:CHECK-SUBSEQUENCER

;; Someday, pleas put in a 4th arg here, which is paralle to the
;;  'complainant' arg of CHECK-ARG.    11/26/80 JonL and RLB


(defun SI:CHECK-TYPER (argument type-test-predicate using-function)
   (do () 
        ;; Basically, a funcall follows, but "beat-out-the-funcall" if possible
       ((cond ((eq type-test-predicate #'SI:NON-NEG-FIXNUMP)
	        (and (fixnump argument) (>= argument 0)))
	      ((eq type-test-predicate #'SI:MAX-EXTEND-SIZEP)
	       (and (fixnump argument) 
		    (>= argument 0) 
		    (< argument #M 510. #-MacLISP 1_18.)))
	      ((eq type-test-predicate #'PAIRP)
	        (pairp argument))
	      ((eq type-test-predicate #'SYMBOLP)
	        (symbolp argument))
	      ((eq type-test-predicate #'FIXNUMP)
	        (fixnump argument))
	      (T (funcall type-test-predicate argument))))
     (setq argument 
	   (cerror 'T () ':WRONG-TYPE-ARGUMENT 
		   "~1G~S does not pass the ~0G~S test, for function ~2G~S" 
		   type-test-predicate argument using-function)))
   argument)


(defun SI:CHECK-SUBSEQUENCER (seq start cnt requisite-type using-function 
			      &optional (startp 'T) 
					(cntp 'T) 
					(forwardp 'T) 
					lispmp )
    ;;The 'lispm' argument only matters when 'forwardp' is null -- then
    ;; we need to know whether the 'start' index signifies the last index,
    ;; or (as on the LISPM) the last index plus one.
  (let ((floating-type (null requisite-type))
	 len)
     (do () 
	 ((prog2 (cond (requisite-type)
		        ;; Let the requisite-type "float" if it isn't supplied
		       ((null seq) (setq requisite-type 'LIST))
		       ('T (setq requisite-type (ptr-typep seq))
			   (if (eq requisite-type 'PAIR) 
			       (setq requisite-type 'LIST))))
		 (memq requisite-type '(STRING VECTOR BITS LIST EXTEND))))
       (if floating-type 
	   (setq seq (cerror 'T () ':WRONG-TYPE-ARGUMENT 
			     "~1G~S (of ptr-TYPEP ~S) is not a sequence -- ~S"
			     'T seq requisite-type 'CHECK-SUBSEQUENCE)
		 requisite-type () )
	   (setq requisite-type 
		 (cerror 'T () ':WRONG-TYPE-ARGUMENT 
			 "~1G~S is not a sequence type-name -- ~S"
			 'T  requisite-type 'CHECK-SUBSEQUENCE))))
      ;; Loop while checking type of sequence argument
     (do () 
	 ((caseq requisite-type 
		 (STRING (when (stringp seq)
			       (setq len (string-length seq))
			       'T))
		 (VECTOR (when (vectorp seq)
			       (setq len (vector-length seq))
			       'T))
		 (BITS   (when (bitsp seq)
			       (setq len (bits-length seq))
			       'T))
		 (LIST   (when (listp seq)
			       (setq len (length seq))
			       'T))
		 (EXTEND (when (extendp seq) 
			       (setq len (extend-length seq))
			       'T)) 
		 (T (error 'CHECK-SUBSEQUENCE))))
       (setq seq (cerror 'T () ':WRONG-TYPE-ARGUMENT 
			 "~1G~S must be a ~0G~S for function ~2G~S" 
			 requisite-type seq using-function)))
      ;; Do defaulting on the start-index argument, if necessary, or
      ;;  loop while checking it for being withing range
     (if (or (not startp) (null start))  
	 (setq start (if forwardp 0 (if lispmp len (1- len))))
	 (do () 
	    ((and (fixnump start)
		  (or (and (>= start 0)	      ;Normal accessible element index
			   (< start len))
		      (and (>= start -1)
			   (<= start len)
			    ;;For backwards searching, permit index to be one 
			    ;; greater than  maximum legal for access.
			   (or (not forwardp)
			        ;;Or a 0 cnt permits this kind of index too.
			       (or (and (fixnump cnt)
					(= cnt 0))
				   (and (not cntp)
					(= len 0))
				   ))))))
	  (setq start (cerror 'T () ':INCONSISTENT-ARGUMENTS 
			      "The 'start' index ~1G~S is not within ~2G~S, for function ~3G~S"
			      (list start seq) start seq using-function))))
      ;; Do defaulting on the number-of-items argument, if necessary, or
      ;;  loop while checking start number-of-items argument
     (if (or (not cntp) (null cnt))
	 (setq cnt (if forwardp (- len start)  (if lispmp start (1+ start))))
	 (do () 
	    ((cond ((or (not (fixnump cnt)) (< cnt 0)) () )
		   (forwardp (<= (+ start cnt) len))
		   ('T  (if lispmp (> start cnt) (>= start cnt)))))
	  (setq cnt (cerror 'T () ':INCONSISTENT-ARGUMENTS 
			    "The 'count' value ~1G~S is out of range for ~2G~S,~%    ~4G~:[bounded above by~;starting at~] index ~3G~S, and going in the ~4G~:[backward~;forward~] direction,~%    from function ~5G~S"
			    (list seq start cnt (if forwardp '+ '-)) 
			    cnt seq start forwardp using-function))))
     (values seq start cnt)))

