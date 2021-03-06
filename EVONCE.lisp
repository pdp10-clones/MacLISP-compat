;;;   EVONCE 	-*-MODE:LISP;PACKAGE:SI-*- 		  -*-LISP-*-
;;;   **************************************************************
;;;   ***** MACLISP ******* Macro for Defining SETF Structures *****
;;;   **************************************************************
;;;   ** (C) COPYRIGHT 1980 MASSACHUSETTS INSTITUTE OF TECHNOLOGY **
;;;   ****** THIS IS A READ-ONLY FILE! (ALL WRITES RESERVED) *******
;;;   **************************************************************


(eval-when (eval compile)
	   (cond ((and (status feature MACLISP) (status nofeature FOR-NIL)) 
		  (sstatus feature FM)
		  (sstatus feature FOR-MACLISP)))
	   )

#-FM (globalize "EVAL-ORDERED" "EVAL-ORDERED*")


(herald EVONCE /14)

#-For-NIL (eval-when (eval compile)
  (macro lispdir (x)
	(setq x (cadr x))
	#+Pdp10   `(QUOTE ((LISP) ,x))
	#+Lispm   (string-append "lisp;" (get-pname x) "qfasl")
	#+Multics (catenate ">exl>lisp_dir>object" (get_pname x))
	#+For-NIL (string-append "lisp:" (get-pname x) "vasl")
	)
  (macro subload (x)
	(setq x (cadr x))
	`(OR (GET ',x 'VERSION) (LOAD #%(LISPDIR ,x))))
  (subload DEFSETF)
  )



(defmacro EVAL-ORDERED (bvl forms &rest body)
  (eval-ordered* bvl forms body))

; (not (null (SETF-gensyms expf))) is not really the right
; predicate.  Consider where one side-effectible and rest all constant.
; the right thing to do is to use SETF-SIDE-EFFECT-SCAN rather than SIMPLEP
; since we aren't worried about multiple evaluation, just ordering.
; Don't forget to write SETF-SIDE-EFFECT-SCAN first!

(defun eval-ordered* (bvl forms body)
   (let ((expf (SETF-struct () () () forms)))
     (SETF-simplep-scan expf ())
     (progv bvl (SETF-compute expf) 
	    (cond ((not (null (SETF-gensyms expf)))
		   `((lambda ,(SETF-gensyms expf)
			     ,@(eval body))
		     ,@(setf-genvals expf)))
		  ('T `(progn ,@(eval body)))))))




;; The following is not yet complete...make it invisible

#+EVAL-ONCE-TEST

(defmacro eval-once (bvl . body)
  (do ((ibvl bvl (cdr ibvl))
       (expfsym (gensym) (gensym))
       (expf-bvl) (nbvl))
      ((null ibvl)
       `(let ,expf-bvl
	   (let ,nbvl ,@body)))
   (desetq (bindform expf-form) (car ibvl))
   (push `(,expfsym (+internal-setf-x-1 ',expf-form)) expf-bvl)
   (cond ((not (and (get (cons () bindform) 'genvals)
		    (get (cons () bindform) 'gensyms)))
	  (error '|GENVALS and GENSYMS are required information -- EVAL-ONCE|
		 bindform)))
   (do ((form bindform (cddr form)))
       ((null form))
     (cond ((setq temp
		  (cdr (assq (car form)
			     '((COMPUTE      . SETF-compute)
			       (I-COMPUTE    . SETF-i-compute)
			       (SIDE-EFFECTS . SETF-side-effects)
			       (RET-OK	     . SETF-ret-ok)
			       (ACCESS-FUN   . SETF-access)
			       (ACCESS	     . SETF-access-expanded)
			       (INVERT-FUN   . SETF-invert)
			       (GENVALS	     . SETF-genvals)
			       (GENSYMS	     . SETF-gensyms)))))
	    (push `(,(cadr form) (,temp ,expfsym)) nbvl))
	   (T (error '|Unknown info name -- EVAL-ONCE| (car form)
		     'wrng-type-arg))))))

#+EVAL-ONCE-TEST
(defmacro SETF-access-expanded (expf)
  `(apply (setf-access ,expf) (setf-compute ,expf)))


