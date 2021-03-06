;;;  SUBLOAD 				-*-mode:lisp;package:si;lowercase:T-*-
;;;  **************************************************************************
;;;  ***** NIL ****** NIL/MacLISP/LISPM Preamble for Autoloadings *************
;;;  **************************************************************************
;;;  ******** (c) Copyright 1981 Massachusetts Institute of Technology ********
;;;  **************************************************************************

#+Compile-Subload 
  (herald SUBLOAD /3)	 ;DONT USE HERALD!! this file usually gets included

#+(or Compile-Subload
      #.(if (fboundp 'SUBLOAD) 		;How to say "Flush this stuff if merely
	    'THIS-AINT-NO-FEATURE 	; INCLUDEing it into a lisp/compiler
	    'PAGING 			; which already have these  loaded"
	    ))

(eval-when (eval compile #+Compile-Subload load)

(defun (AUTOLOAD-FILENAME macro) (x)
  (let (((() module-name) x)
	(more (and (if (get 'SHARPCONDITIONALS 'VERSION) 
		       (featurep '(and MacLISP (not For-NIL)))
		       (status nofeature For-NIL))
		   '(FASL))))
    `'((LISP) ,module-name ,.more)))

(defun (SUBLOAD macro) (x)
  (let ((module-name (cadr x)))
    `(OR (GET ',module-name 'VERSION) 
	 (LOAD ,(macroexpand `(AUTOLOAD-FILENAME ,module-name))))))

(defun (SUBLOAD-FUNCTION macro) (x)
  (let ((fun-name (cadr x)))
    `(OR (FBOUNDP ',fun-name) 
	 (+INTERNAL-TRY-AUTOLOADP ',fun-name))))

(defun (DEF-OR-AUTOLOADABLE macro) (x)
  (let (((() function-name module-name) x))
    `(OR (FBOUNDP ',function-name)
	 (GET ',function-name 'AUTOLOAD) 
	 ,`(DEFPROP ,function-name  
		    ,(eval `(AUTOLOAD-FILENAME ,module-name))
	 	    AUTOLOAD))))

)
