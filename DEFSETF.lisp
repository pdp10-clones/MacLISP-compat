;;;  DEFSETF   				-*-Mode:Lisp;Package:SI;Lowercase:T-*-
;;;  *************************************************************************
;;;  ***** MacLISP ******* DEFine SETF structures -- a macro *****************
;;;  *************************************************************************
;;;  ** (c) Copyright 1981 Massachusetts Institute of Technology *************
;;;  *************************************************************************


(herald DEFSETF /96)

#-NIL (include ((lisp) subload lsp))

#-NIL 
(eval-when (eval compile)
  (subload SHARPCONDITIONALS)
)


#+(local MacLISP)
(eval-when (eval compile)
  (subload EXTEND)
  (subload EXTMAC)
  (subload VECTOR)
  )

#+(or LISPM (and NIL (not MacLISP)))
(globalize "DEFSETF" "SETF")



(eval-when (eval compile)
  #+(local MacLISP) (*lexpr symbolconc)
  (setq DEFMACRO-DISPLACE-CALL MACROEXPANDED) 
  #-NIL (subload DEFVST)
  )

#-NIL
(eval-when (eval load compile)  
	    ;; EXTHUK needed for SI:XREF
   (subload EXTHUK)
  )

(def-or-autoloadable GENTEMP MACAID)


;;;; define SETF structures

; SSETF-<mumble>  is a slight variant on the update format for structures
;   e.g. (SSETF-<mumble> foo val)  ==>  (SETVST (SETF-<mumble> foo) val)


#-LISPM 
(defmacro (DEFINE-SETFS-STRUCTURE defmacro-for-compiling () defmacro-displace-call () )
	  (&REST keys)
    `(PROGN 'COMPILE 
	    (DEFVST SETF ,. keys)
	    ,.(mapcar 
	        '(lambda (x)
		   `(defmacro ,(intern (symbolconc '|SSETF-| x)) (struct val)
		       `(SETVST (,',(intern (symbolconc '|SETF-| x)) ,struct) ,val)))
		keys)))

#+LISPM 
(defmacro DEFINE-SETFS-STRUCTURE (&rest form)
     (do ((x form (cdr x))  (funs)  (accessors))
	 ((null x)
	   `(progn 'compile 
		   (defstruct (setf-struct :constructor cons-a-setf)
			      ,@accessors)
		   ,@funs))
       (push (string-append "SETF-" x) accessors)
       (push `(defmacro ,(string-append "SSETF-" x) (frob val)
		   `(setf (,',(car accessors) ,frob) ,val))
	     funs)))


(DEFINE-SETFS-STRUCTURE compute i-compute side-effects ret-ok
			access invert genvals gensyms user-slot
			function)


;;;;  DEFSETF

(defmacro DEFSETF (name (( fun . vars) val) ret-ok invert)
  (let ((access (gentemp "access-spec"))
	(funsym (gentemp "Function"))
	(struct (gentemp "SETF-struct"))
	(access-name (intern (symbolconc name '| SETF-X-ACCESS|)))
	(invert-name (intern (symbolconc name '| SETF-X-INVERT|)))
	(other-funs)
	(computes (delete () vars)))
    (if (not (atom name))
	(desetq (name . other-funs) name))
    `(PROGN 'COMPILE
	(|forget-macromemos/|| () ) 			;Invalidate memoizings
	(DEFUN ,access-name (,struct ,@computes)
	  (LET ((,funsym (setf-function ,struct)))
	    `(,,funsym ,,@vars)))
	(DEFUN ,invert-name (,struct ,val ,@computes)
	  (let ((,fun (setf-function ,struct)))
	    ,invert))
	(DEFUN (,name SETF-X) (,access)
	   (let (( (,funsym ,@vars) ,access))
	      (SETF-STRUCT ',access-name		;Access continuation
			   ',invert-name		;Invert continuation
			   ',ret-ok			;Return value right?
			   `(,,@computes)
			   ,funsym)))
	,.(mapcar #'(lambda (other-fun)
		      `(PUTPROP ',other-fun (GET ',name 'SETF-X) 'SETF-X))
		  other-funs)
	',name)))

