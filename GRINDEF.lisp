;;;   GFN 						  -*-LISP-*-
;;;   **************************************************************
;;;   ***** Maclisp ****** S-expression formatter (grindef) ********
;;;   **************************************************************
;;;   ** (c) Copyright 1981 Massachusetts Institute of Technology **
;;;   ****** this is a read-only file! (all writes reserved) *******
;;;   **************************************************************
;;;
;;; 04/06/81 kmp  - renamed PREDICT to GPREDICT to avoid name conflicts with
;;;		    other systems. for compatibility, i do a 
;;;		    (DEFPROP PREDICT GPREDICT EXPR) iff PREDICT is not
;;;		    fboundp at load time. this defprop should go away sometime
;;;		    after people have made the changeover.
;;; 01/29/81 jonl - flushed (STATUS FEATURE MACAID) and NIL --> () 
;;; 		    added special declaration for GRIND-MACROEXPANDED
;;; 04/15/80 kmp  - made GRLINEL use the value of GRLINEL variable if it is
;;;		    bound rather than guessing about a LINEL by looking at
;;;		    outfiles. It is defaultly UNBOUND.
;;; 04/13/80 rwk  - made SETF grind like SETQ.  Added OWN-SYMBOL's for system
;;;		    funs.  Converted THROW's to *THROWs, CATCH's to *CATCHs.
;;;		    Tag in both cases of ()
;;; 04/02/80 rees - introduced GATOMP in an attempt to make handling of
;;;		   hunks more consistent.  Complete crockery.
;;;		   Also added variable GRIND*RSET so I can debug the
;;;		   damn thing.
;;; 02/28/80 kmp - removed buggy COND for re-examination, too. sigh.
;;; 02/27/80 kmp - removed LET and CASEQ buggy grindfn properties until
;;;		   they can be looked into in more detail. They don't
;;;		   currently do the right thing as GLS points out.
;;; 02/24/80 kmp - added grind properties for DO and CASEQ. Fixed DEF-FORM
;;;		   to handle DEFMACRO and DEFUN& optimally. 
;;; 02/18/80 kmp - nreversed this history to put new entries at the top
;;;		   fixed. Made EVAL-WHEN grind right.
;;; 02/14/80 kmp - flushed some old, unreachable code from several points,
;;;		   clearly marked. Made LET/LAMBDA grind right.
;;; 02/11/80 kmp - hunk pretty-printing supported. depends on the variable
;;;		   hunkp being non-nil and the variable hunksprin1 being
;;;		   set to a pretty-printer. default printers provided.
;;;		   if either variable is NIL, hunks are sprinter'd like lists.
;;;		   fixed a probably non-existent bug in the sprintering of
;;;		   non-atomic atoms in the cdr of a cons.
;;; 02/04/80 jonl - lambda-bind *RSET for "interior" calls, to achieve speed.
;;; 		    Installed use of HERALD and DEFSIMPLEMAC (in MULTICS
;;; 		    case) "require"ing loading MACAID
;;; 11/28/79 alan - fixed GFLATSIZE1 (see kmp 6/18/79) to only look at
;;;		   property lists of symbols (e.g. not lists!)
;;; 11/15/79 kmp - fixed SPRIN1 to take a file object as second arg, augmenting
;;;		   addition to former ability to take a list of files...
;;; 11/8/79 rees -  minor bug fixes, e. g. ",." flatsizing, 2nd SPRIN1
;;;		    arg, VERSION property and (LISP) device modernization
;;; 09/27/79 rees - Changed name of "FORM" to "GRINDFORM"
;;;		    Added function SPRIN1 for prettyprinting PRIN1
;;; 09/25/79 jonl - Changed name of "FILL" to "GRINDFILL"
;;;		    Installed some usage of #
;;; 06/19/79 kmp - Fixed bug that non-null end of list in 'block'-type
;;;			special forms were blindly CAR'ing and CDR'ing 
;;;			the atom.
;;; 06/18/79 kmp - Added in GFLATSIZE1 and ability to check for a 
;;;			GRINDFLATSIZE property on CAR's of forms.
;;; 05/24/79 jonl -  Add some special grindmacro functions for backquote
;;; 			and defmacro stuff.
;;; 05/03/79 kmp - lambda-bind ERRSET when loading init file so people
;;;		    with ERRSET handlers don't get breakpoints at what
;;;		    is really a non-error. (version 421)
;;; 03/30/79 jonl - flush CNVR stuff, put in a modern loading-message-print,
;;; 			and a modern-style init file finder.
;;; 01/09/79 jonl - flush "niop/|", since only newio is available.  Fix up
;;;			autoload property for GRILAP
;;; 11/01/78 jonl - print loading message on MSGFILES instead of OUTFILES
;;;			don't GRINDEF is atomic arg is not a SYMBOL
;;; 09/15/78 {hic?} - let "*" be returned instead of (ascii 0)
;;; 07/12/78 jonl - Fix up usages of LINEL by creating function GRLINEL,
;;;			and install macros for POPL and REMSEMI-TAC
;;; 05/25/78 jonl - Had GRINDEF and SPRINTER lambda-bind variable LINEL, and 
;;;			removed all references to CONNIVER and PLANNER stuff.
;;;			Flush "SGPLOSES" and NOARGS calls; flush GBREAK.
;;;			Change "NIL" into "()".
;;; 09/13/76 jonl - changed loading message for qio, removed "M" from 
;;;			toplevel setqs
;;; 11/01/75 jonl - Fixed up the autoload properrty makers for slashify etc.
;;; 10/10/75 jonl - Added mem-form property for fillarray
;;; 09/18/75 jonl - Fixed up a few newio goodies, and removed more grind 
;;;			stuff to gfile
;;; 08/07/75 jonl - Flushed newio macroified stuff, and made dynamic
;;; 06/14/75 jonl - Flushed remgrind. repaired ghash to work on dec-10
;;; 05/7/75 ? - Vertical-bars and exclamations slashed
;;; 09/21/74 maxpan made into 3 arg fn.  third arg = m. /Eliminate 
;;;	excessive specbinding. grindpredict obtained via apply.

(herald GRINDEF /462)



(declare (own-symbol READMACROINVERSE SPRINTER SPRIN1 GRINDEF
		     |MACROEXPANDED-grindmacro/|| |+INTERNAL-`-grindmacros/||))

(declare (array* (notype (gtab/| 128.)))
	 (special /; /;/; /;/;? arg chrct comnt comspace gap global-lincnt
		  grind-standard-quote grindef grindfill grindfn grindform
		  grindlinct grindmacro grindmerge grindnomerge grindpredict
		  grindproperties grindreadtable h l linel m macro n outfiles
		  pagewidth gpredict prog? programspace readtable remsemi 
		  sprin1
		  topwidth unbnd-vrbl user-paging hunksprin1 grind*rset
		  grlinel grind-macroexpanded)
	 (*expr grindform topwidth programspace pagewidth comspace
		grindnomerge remsemi)
	 (*fexpr trace slashify unslashify grindfn grindmacro
		 unreadmacro readmacro grindef)
	 (*lexpr grindmerge gpredict user-paging grindfill testl)
	 (*expr prin50com rem/;/; rem/;) ;; Imported from GFILE
	 (mapex 't)
	 (genprefix /|gr)
	 (fixnum nn mm 
		 (prog-predict notype fixnum fixnum)
		 (block-predict notype fixnum fixnum)
		 (setq-predict notype fixnum fixnum)
		 (panmax notype fixnum fixnum)
		 (maxpan notype fixnum fixnum)
		 (gflatsize) (grchrct) (grlinel)))
 
(cond ((not (boundp 'hunksprin1))
       (setq hunksprin1 'standard-hunksprin1)))
(cond ((not (boundp 'grind*rset))
       (setq grind*rset ())))

;;;REMSEMI - test and call

(declare (setq defmacro-for-compiling () defmacro-displace-call () ))

  (defmacro remsemi-tac () '(and remsemi (remsemi)))
  (defmacro popl () '(progn (pop l) (remsemi-tac) l))
   ;;; replaced by compiler by tab (8 its, 10. multics)
  (defmacro stat-tab () `(quote ,(status tabsize)))
  #+multics 
    (defsimplemac ghash (x)
	`(cond ((atom ,x) (abs (sxhash ,x)))
	       ((maknum ,x))))
  #-multics
    (defmacro ghash (x) `(maknum ,x))
 

(prog (*RSET)
      (*rset grind*rset)
      ;;;some initializations
      (and (not (boundp 'grind-use-original-readtable))
	   (setq grind-use-original-readtable 't))
      ;;; standard readmacroinverter for quote.  "quote"
      ;;; If you have your own macro for quote take effect, set
      ;;; grind-standard-quote to ().
      (and (not (boundp 'grind-standard-quote))
	   (setq grind-standard-quote 't))
      (setq remsemi ()
	    grindlinct 8. 
	    grindef () 
	    global-lincnt 59. 
	    grindproperties '(expr fexpr value macro))
      (array gtab/| t 128.)) 



;;; (GRINDEF <atom> <atom> ...) 
;;;  Grinds the properties of the atoms listed on GRINDPROPERTIES.
;;;
;;; (GRINDEF (<property> <property> ...) <atom> <atom> ...)
;;;   grinds the additional properties as well.

(defun grindef fexpr (atoms)
  (let ((linel (grlinel)) (*rset grind*rset) (nouuo grind*rset))
       (prog (traced fn props)
	     (cond (atoms (setq grindef atoms))
		   ((setq atoms grindef)))
	     (setq props grindproperties)
	a    (cond ((null atoms) (return '*)))
	     (setq fn (car atoms) atoms (cdr atoms))
	     (cond ((atom fn) (and (not (symbolp fn)) (go a)))
		   ((setq props (append fn props)) (go a)))
	     ;;; flag for fn being traced
	     (cond ((setq traced  (and (status feature trace) 
					(memq fn (trace))))
		    (terpri)
		    (terpri)
		    (princ '/;traced)))
	     (do
	      ((plist (plist fn) (cddr plist))
	       (ind 'value (car plist))
	       (prop (and (boundp fn) (cons () (eval fn)))
		     (cadr plist))
	       ;;; needed in case there are value properties
	       (valueless () 't))
	      (())
	      (cond ((and traced
			  ;;; ignore all but last if traced
			  (memq ind '(expr fexpr macro)))
		     (setq traced (get (cdr plist) ind))
		     (go b))
		    ;;; grindef only desired properties.
		    ((not (memq ind props)) (go b))
		    ((eq ind 'value)
		     (cond ((and prop (not valueless))
			    (terpri)
			    (terpri)
			    (sprint `(setq ,fn (quote ,(cdr prop)))
				    linel
				    0.)))
		     (go b)))
	      (terpri)
	      ;;; terpri's placed here to avoid
	      (terpri)
	      ;;; lambda -> defun
	      (cond ((and (memq ind '(expr fexpr macro))
			  (eq (car prop) 'lambda))
		     (sprint (cons 'defun
				   (cons fn
					 (cond ((eq ind 'expr)
						(cdr prop))
					       ((cons ind
						      (cdr prop))))))
			     linel
			     0.))
		    ((sprint `(defprop ,fn ,prop ,ind)
			     linel
			     0.)))
	      b
	      ;;; exit from do when no more properties
	      ;;; look for more atoms to do.
	      (or plist (return ())))
	     (go a))))

;;; (unformat fn1 fn2 ...) or (unformat (fn1 fn2 ...))
;;; Removes grinding information from the each of a list of functions.

(defun unformat fexpr (x)
       (or (atom (car x)) (setq x (car x)))
       (mapc '(lambda (x) (remprop x 'grindfn)
			  (remprop x 'grindmacro)
			  (remprop x 'grindpredict)
			  (remprop x 'gflatsize))
	     x)) 

;;; eg (grindmacro quote /')

(defun grindmacro fexpr (y)
       (putgrind (car y) (cdr y) 'grindmacro)) 

;;; eg (grindfn (defun defmacro) def-form)

(defun grindfn fexpr (y)
       (putgrind (car y) (cdr y) 'grindfn)) 

;;; (PUTGRIND <function-spec> <prop> <ind>)
;;;
;;; <function-spec> may be a function-name or a list of function-names
;;;     (in which case, the operation will be distributed recursively
;;;      across the list)
;;;
;;; <prop> must be a list.  ... more documentation needed ...

(defun putgrind (fn prop ind)
  (cond ((atom fn)
	 (setq prop
	       (cond ((atom (car prop))
		      (cond ((get (car prop) 'grindpredict)
			     (putprop fn
				      (get (car prop) 'grindpredict)
				      'grindpredict)))
		      (car prop))
		     ('t (cond ((eq (caar prop) 'readmacroinverse)
				(putprop fn
					 (get 'readmacroinverse 'grindpredict)
					 'grindpredict)))
		      (cons 'lambda (cons () prop)))))
	 (putprop fn prop ind))
	('t (mapc '(lambda (x) (putgrind x prop ind)) fn))))


;;; eg (readmacro quote /' <optional-arg>)
;;; where optional means grind CDR instead of CADR.

(defun readmacro fexpr (y)
       (putgrind (car y)
		 (list (cons 'readmacroinverse
			     (cons (cadr y) (cddr y))))
		 'grindmacro)) 

;;; remove readmacro info from a character

(defun unreadmacro fexpr (y) (remprop y 'grindmacro)) 

;;; *** If you know what this does, please document it --kmp ***

(defun grindmacrocheck (x l) 
       (cond ((or (atom x) (cdr x)) ())
	     ((null (car x)) (= (length l) 2.))  ;x = (())
	     ((equal (car x) '(t)) (cdr l))))    ;x = ((t)) 

;;; (readmacroinverse <macro-char>) --> <macro-char><pretty-print l>. 
;;; Macro-char may be an atom or list of ascii values.
;;; Note that it expects the special variable L to have info about the
;;; form which is being printed.

(defun readmacroinverse fexpr (x)			
       (prog (sprarg) 
	     (cond ((cond ((null (cdr x)) (= (length l) 2.))
			  ((and (null (cddr x)) (eq (cadr x) 't)) (cdr l)))
		    (cond ((atom (car x)) (princ (car x)))
			  ((mapc 'tyo (car x))))
		    ;;; macro must have arg to execute inverse
		    (setq sprarg (cond ((null (cdr x)) (cadr l)) 
				       ((eq (cadr x) 't) (cdr l))
				       ((= (length (cdr l)) 1.)
					(cond ((null (cadr l))
					       (tyo #\space)
					       (return 't))
					      ('t (cadr l))))
				       ('t (cdr l))))
		    (cond ((sprint1 sprarg (grchrct) m)
			   (prin1 sprarg)))
		    (return 't))
		   ('t (return ()))))) 

;;; GATOMP - ATOM check for proper (?) handling of hunks.  REES 4/2/80
;;; Returns true for objects which should NOT be iteratively
;;; CDRed during analysis.

(defun gatomp (x)
       (or (atom x)
	   (and (hunkp x) hunkp hunksprin1)))

;;; Format for LAMBDA and LET
;;;
;;; (name bvl body) if it all fits on one line.
;;; else (name bvl
;;;         body) with 3 spaces indentation.
;;;

(defun lambda-form () 
       (let ((obj (car l)))
	    (grindform 'line)  
	    (setq grindform (cond ((and gpredict
					(< (grchrct) (gflatsize (testl))))
				   'form2)
				  ('t (+ arg (gflatsize obj)))))
	    (grindform 'block)))



(eval-when (eval compile) (tyipeek 12.) ) ; skip debugging stuff

 ;; debugging only

(defun beep-trace (X)
    (let (((v . h) (cursorpos tyo)))
	 (tyo 7.)
	 (cursorpos 23. 50. tyo)
	 (princ'*) (princ x)
	 (cursorpos v h tyo)
	 (rubout(tyi))
	 (cursorpos 23. 70. tyo)
	 (cursorpos'l tyo)
	 (cursorpos v h tyo)))



(defun do-form ()
       (let ((c-ct (grchrct)) (c-ct2) (gflag 't))
;	    (beep-trace 'do)
	    (grindform'line)
	    (setq c-ct2 (grchrct))
	    (grindform'code)
	    (cond ((not (and gpredict (< (grchrct) (gflatsize (testl)))))
		   (setq gflag 't)
		   (indent-to c-ct2)))
	    (grindform'code)
	    (and gflag (indent-to c-ct))
	    (setq grindform (cond ((and gpredict
					(< (grchrct) (gflatsize (testl))))
				   'form2)
				  ('t (+ arg 3.))))
	    (setq prog? 't)
	    (grindform 'block)))

; Experimental: -kmp
;(defun cond-form ()
;       (beep-trace 'cond)
;       (let ((cct (- (grchrct) 5.)))
;	    (grindform'line)
;	    (cond ((not (and gpredict
;			     (< (grchrct) (gflatsize (testl)))))
;		   (do ((flag nil t)) ((done? cct))
;		       (and flag (indent-to cct))
;		       (grindform'code)))
;		  (t
;		   (grindform'block)))))
;
;(grindfn (cond) cond-form)

;;; Format for PROG's
;;; prohibits form3 if args do not fit on line

(defun prog-form () 
;       (beep-trace'prog)
       (grindform 'line)
       (setq prog? 't)
       (setq grindform (cond ((and gpredict
				   (< (grchrct) (gflatsize (testl))))
			      'form2)
			     (arg)))
       (grindform 'block)) 


;;; prohibits form3 if args do not fit on line

(defun def-form () 
       (prog (c)
	     (setq c (car l))
	     (grindform 'line)
	     (grindform 'line)
	go   (cond ((memq (testl) '(expr fexpr macro))
		    (grindform 'line)
		    (go go)))
	     (setq grindform (cond ((and gpredict
					 (< (grchrct) (gflatsize (testl))))
				    'form2)
				   ('t (+ arg (gflatsize c)))))
	     (return (grindform 'block)))) 

;;; quoted second arg ground as block

(defun mem-form () 
       (prog (p gm) 
	     (grindform 'line)
	     (remsemi-tac)
	     (*catch ()
		     (and (setq p (panmax (car l) (grchrct) 0.))
			  (cond ((< (panmax (car l) n 0.) p))
				((setq n (grchrct))))))
	     (cond ((sprint1 (car l) n 0.) (prin1 (car l))))
	a    (cond ((null (cdr l))
		    (setq l (error 'mem-form l 'fail-act))
		    (go a)))
	     (popl)
	go   (indent-to n)
	     (setq m (1+ m))
	     (cond ((eq (caar l) 'quote)
		    (tyo #/')
		    (cond ((pprin (cadar l) 'block))
			  ((prin1 (cadar l)))))
		   ((setq gm (sprint1 (car l) n m))
		    (prin1 (car l))))
	     (popl)
	     (cond (l (go go)) ((return ()))))) 

;;; standard form
;;; committed to at least standard form
;;; prediction in special form computed to
;;; compare to p.
;;; setq form

(defun setq-form () 
   (cond ((*catch ()
	   (prog (mm) 
		 (setq mm (maxpan (cdr l) arg m))
		 (setq n arg)
		 (defprop setq setq-predict grindpredict)
		 (and (< mm (panmax l (prog2 () (1+ n)
						(setq n arg))
				    m))
		      (return 't))
		 (grindform 'line)
	     d	 (or l (return ()))
	         (indent-to n)
		 (grindform 'line)
		 (grindform 'code)
		 (remsemi-tac)
		 (go d)))
	      ;;; SETQ-PREDICT causes throw when variable name is very long.
	      ;;;  therefore, it is not used all the time but only inside
	      ;;;  setq-form.
	  (defprop setq () grindpredict)
	  (grindform 'line)
	  (setq grindform n))))





;;; grinds l with args outputed as list.

(defun comment-form () (gblock (- (grchrct) 1. (gflatsize (car l)))))

(defun block-form () (gblock (grchrct))) 



(declare (unspecial l n m)) 

;;; returns number of lines to print args
;;; as name-value pairs.
;;; n = space for name<space>value.  2 =
;;; space for ( and <space preceding variable>.
;;; nn = space for value. 2 = space for )
;;; and <space preceding value>.

(defun setq-predict (l n ()) ; m omitted -- not used
       (prog (mm nn)
	     (setq n (- n 2. (gflatsize (car l))))
	     (setq mm 0.)
	a    (and (null (setq l (cdr l))) (return mm))
	     (and (semi? (car l)) (go a))
	     (setq nn (- n 2. (gflatsize (car l))))
	b    (cond ((null (cdr l))
		    (setq l (error 'setq-predict l 'wrng-no-args))
		    (go b)))
	     (setq l (cdr l))
	     (and (semi? (car l)) (go b))
	     (setq mm (+ mm (panmax (car l) nn 0.)))
	     (go a))) 

(declare (special l n m)) 

;;;format control

;;; (gpredict) <=> (gpredict t) => super-careful
;;; sprint considering all formats.  (gpredict ())
;;; => less careful but quicker.

(defun gpredict args (setq gpredict (cond ((= args 0.)) ((arg 1.)))))

  ;;don't clobber user def. this is for compatibility only
(cond ((not (fboundp 'predict)) 
       (defprop predict gpredict expr)))


(defun programspace (x) 
       (setq programspace (setq linel x))
       (setq comspace (- pagewidth gap programspace))) 

(defun pagewidth (w x y z) 
       (setq pagewidth w)
       (setq gap y)
       (setq programspace (setq linel x))
       (setq comspace z)) 

(defun comspace (x) 
       (setq comspace x)
       (setq programspace (setq linel (- pagewidth gap comspace)))) 

;;; (grindfill) <=> (grindfill t) => spaces gobbled in ;

(defun grindpage () (tyo #\formfeed) (setq grindlinct global-lincnt)) 

;;; comments.  (grindfill ()) => spaces not gobbled. 
;;; triple semi comments are never filled but are
;;; retyped exactly inuser's original form.

(defun grindfill args (setq grindfill (cond ((= args 0.)) ((arg 1.)))))

;;; (grindmerge) <=> (grindmerge t) => adjoining ; and ;;
;;; comments are merged. (grindmerge ()) => adjoining
;;; comments not merged.   ;;;... are never merged.

(defun grindmerge args (setq grindmerge (cond ((= args 0.)) ((arg 1.)))))

;;; (user-paging) <=> (user-paging t) 
;;; grind does not insert any formfeeds, but
;;; preserves paging of user's file. (user-paging
;;; () ) => grind inserts formfeed every 59 lines. 
;;; attempts to avoid s-expr pretty-printed over
;;; page boundary.  ignores users paging. paging of
;;; user's file.

(defun user-paging args
       (setq user-paging (cond ((= args 0.)) ((arg 1.)))))

(defun topwidth (x) (setq topwidth x))

;;; REMSEMI must be non-()

(defun remsemi ()
    (do ((fl)) 
	((cond ((rem/;) (rem/;/;) (setq fl 't) ()) 
	       ((rem/;/;) (setq fl 't) ())
	       ('t))
	 fl))) 

;;; check for any ;;'s
;;; at any depth

(defun semisemi? (k) 
       (cond ((null remsemi) ())
	     ((eq k /;/;))
	     ((gatomp k) ())
	     ((or (semisemi? (car k)) (semisemi? (cdr k))))))

(defun semi? (k) (and remsemi (or (eq (car k) /;) (eq (car k) /;/;)))) 


;;; indents additonal nn spaces.

(defun indent (nn)
   (cond ((minusp (setq nn (- (grchrct) nn)))
	  (error 'indent/ beyond/ linel? nn 'fail-act)
	  (terpri))
	 ((indent-to nn)))) 


;;; chrct set to nn
;;; chrct may become negative from
;;; prin50com.
;;; some indentation is necessary
;;; position as a result of first tab.
;;; tabs do not move 8, but
;;; to nearest multiple of 8

(defun indent-to (nn)
   ((lambda (nct tab) 
	    (declare (fixnum nct tab))
	    (cond ((or (< nct 0.) (> nn nct))
		   (turpri)
		   (setq nct linel)))
	    (cond ((< nn nct)
		   (setq tab (+ nct
				(- (stat-tab))
				(\ (- linel nct) (stat-tab))))
		   (cond ((< tab nn) (grindslew (- nct nn) #\space))
			 ((tyo #\tab)
			  (setq nct tab)
			  (cond ((< nn nct)
				 (setq nct (- nct nn))
				 (grindslew (// nct (stat-tab))
					    #\tab)
				 (grindslew (\ nct (stat-tab))
					    #\space))))))))
	(grchrct)
	0.)) 

(defun grindslew (nn x) (do mm nn (1- mm) (zerop mm) (tyo x))) 

;;; this global variable records whether the last
;;; form printed was a double-semi comment.  if so,
;;; it is non-() and rem/;/; merges the current
;;; comment.  this meging should not happen across
;;; a pprin.  furthermore, it is a bug if pprin is
;;; printing code that is an atom.  then /;/;? is
;;; not set to () and it falsely indicates tha the
;;; last form printed was a /;/; comment. l is
;;; = 'block or as a function followed by a list
;;; ground as line if tp = 'line, as a block if tp
;;; of arguments if l = 'list, or normally
;;; if tp = 'code.

(defun pprin (l tp) 
       (setq /;/;? ())
       (cond ((atom l) (prin1 l) 't)
	     ((eq tp 'line) (cond ((gprin1 l n) (prin1 l))) 't)
	     ((eq tp 'block)
	      (or (and (symbolp (car l))
		       ((lambda (x) (and x (apply x ())))
			(get (car l) 'grindmacro)))
		  (progn (princ '/()
			 (gblock (grchrct))
			 (princ '/)))))
	     ((eq tp 'list)
	      (or (and (symbolp (car l))
		       ((lambda (x) (and x (apply x ())))
			(get (car l) 'grindmacro)))
		  (progn (princ '/()
			 (gblock (- (grchrct) 1. (gflatsize (car l))))
			 (princ '/)))))
	     ((eq tp 'code) (sprint1 l (grchrct) m) 't))) 



;;; cr with line of outstanding single semi
;;; comment printed, if any.  grindlinct =
;;; lines remaining on page.

(defun turpri () 
       (and remsemi comnt (prin50com))
       (terpri)
       (setq grindlinct (cond ((= grindlinct 0.) global-lincnt)
			      ((1- grindlinct))))) 

;;; (grchrct)
;;; Returns the amount of room between the current horizontal position
;;; and the end of the line. For many applications, this is the right
;;; second arg to give to sprint1 on recursive pretty-print dives.

(defun grchrct () 
    (- linel (charpos (car (or (and ^R outfiles) '(t))))))

;;; (grlinel)
;;; This is the linel of the output file that we are presumably grinding to

(defun grlinel ()
        (cond ((boundp 'grlinel) grlinel)
	      ('t (linel (car (or (and ^R outfiles) '(t)) )))))

;;; KMP: Note -- this function is hairier than it needs to be. In current
;;;	 GFN and GFILE, it is ALWAYS called with no args. Somebody who is
;;;	 awake at the time should try to simplify it into something readable
;;;	 and/or scrap this package entirely and write something winning.

(defun testl args 
       (prog (k nargs) 
	     (setq k l nargs (cond ((= 0. args) 0.) ((arg 1.))))
	a    (cond ((null k) (return ()))
		   ((semi? (car k)) (setq k (cdr k)) (go a))
		   ((= 0. nargs)
		    (return (cond ((= 2. args) k) ('t (car k)))))
		   ((setq nargs (1- nargs))
		    (setq k (cdr k))
		    (go a))))) 

;;; pprin the car of l, then pops l.
;;; no-op if l is already (). process
;;; initial semi-colon comment, if any,
;;; then try again. pretty-print c(car l)
;;; in desired format. if l is not yet (), output
;;; a space. return popped l. 

(defun grindform (x)
       (cond ((remsemi-tac) (grindform x))
	     (l (cond ((pprin (car l) x)
		       (cond ((and (cdr l)
				   (not (and hunkp
					     hunksprin1
					     (hunkp (cdr l)))))
			      (tyo #\space)))
		       (setq l (cdr l)))
		      ('t (prin1 (car l))
		       (cond ((and (cdr l)
				   (not (and hunkp
					     hunksprin1
					     (hunkp (cdr l)))))
			      (tyo #\space)))
		       (setq l (cdr l)))))))

;;; pretty print over whole width

(defun sprinter (l)
    (let ((linel (grlinel)) (*rset grind*rset) (nouuo grind*rset))
	 (turpri)
	 (turpri)
	 (sprint l linel 0.)
	 (turpri)
	 '*))

;;; For efficiency, the symbol SPRIN1 is a substitution alist for the
;;; function SPRIN1 to use. This actually does the wrong thing if TYO is
;;; rebound to something else, but fooey on people that do that.

(setq sprin1 `((T . ,tyo)))

;;; (SPRIN1 object [ optional-file-info ])
;;; pretty-prin1's object to files specified or default output file if
;;; none given explicitly. No initial carriage return is typed by SPRIN1
;;; so the form is displayed properly indented for the current horizontal
;;; position.

(defun sprin1 (ll &OPTIONAL (files outfiles))
   (let ((*rset grind*rset) 
	 (nouuo grind*rset)
	 (linel (grlinel))
	 (^r 't)
	 (^w ^w)
	 (outfiles (progn (cond ((not files) ())
				((atom files) (setq files (ncons files))))
			  (sublis sprin1 files))))
	(and files (setq ^w 't))
	(sprint ll (grchrct) 0)
	't))

;;; This is the correct toplevel function to call when sprin1'ing a function.
;;; Clears the hash table and then calls sprint1. sprint1 is the correct
;;; function to recursively call. see doc on sprin1 for info on what the
;;; args l, m, and n do.

(defun sprint (l n m) 
       (fillarray 'gtab/| '(()))
       (sprint1 l n m)) 

;;;sprint formats
;;;form1 = (s1    form2 = (s1 s2    form3 = (s1 s2 (sprint1 last))
;;;         s2                s3)
;;;         s3)

;;; expression l to be sprinted in space n
;;; with m unbalanced "/)" hanging. p is
;;; number lines to sprint1 as form2
;;; this is an explicit check for quote.
;;; the alternative is to use the standard
;;; grindmacro to use your own personal readmacro
;;; for quote, setq grind-standard-quote to ().
;;; if a ;; comnt, force multi-line
;;;
;;; p = # of lines to sprint l in standard

(defun sprint1 (l n m)
       (prog (grindform arg fn args p prog? grindfn form3? gm)
	     (and (remsemi-tac) (null l) (return ()))
	     (setq /;/;? ())
	     (indent-to n)
	     (cond ((gatomp l)
		    (cond ((atom l) (prin1 l))
			  ('t (funcall hunksprin1 l n m)))
		    (return ())))
	     (cond ((and grind-standard-quote
			 (not (and hunkp
				   hunksprin1
				   (hunkp l))) 
			 (eq (car l) 'quote)
			 (cdr l)
			 (null (cddr l)))
		    (princ '/')
		    (setq gm (sprint1 (cadr l) (grchrct) m))
		    (return ())))
	     (and (symbolp (car l))
		  (setq fn (car l))
		  (let ((x (get fn 'grindmacro)))
		       (and x (apply x ())))
		  (return ()))
	     (cond ((semisemi? l))
		   ((< (+ m -1. (gflatsize l)) (grchrct))
		    (return (gprin1 l n))))
	     (princ '/()
	     (setq n (grchrct))
	     (setq arg (- n (gflatsize (car l)) 1.))
	     (and
	      (atom (setq args
			  (cond ((setq grindfn (get fn
						    'grindfn))
				 (apply grindfn ())
				 (and (numberp grindform)
				      (setq n grindform)
				      (go b))
				 (and (null l)
				      (princ '/))
				      (return ()))
				 l)
				((cdr l)))))
	      (go b))
             ;; catch exited if space insufficient.
	     (*catch ()
	      (and
	       (setq p (maxpan args arg m))
	       ;;; Format. Exit if miser more efficient than standard
	       ;;;  in no-predict mode, use miser format on all non-fn-lists.
	       (cond (gpredict (not (< (maxpan args n m) p)))
		     (fn))
	       (setq n arg)
	       ;;; committed to standard format.
	       (cond
		(grindfn (or (eq grindform 'form2)
			  (> (maxpan args (grchrct) m) p)
			  (setq n (grchrct))))
		((prog () 
		       ;;; skip form3 is gpredict=().
		       (or gpredict (go a))
		       (*catch ()
			;;; l cannot be fit in chrct is it more
			;;;   efficient to grind l form3 or form2
			(setq 
			 form3?
			 (and (not (eq (car (last l)) /;))
			      (< (maxpan (last l)
					 (- (grchrct)
					    (- (gflatsize l)
					       (gflatsize (last l))))
					 m)
				 p))))
		  a    (setq gm (gprin1 (car l) n)) 
;;;
;;; KMP: The previous setq used to be the COND commented out here. I stripped
;;;      the COND off the outside because GPRIN1 always returns () nowadays.
;;;      This may not be the right thing -- GPRIN1 may not want to always
;;;      return (), but this code will never get reached in the current state
;;;      of things, so it might as well not get compiled in.
;;;
;;;                    (cond ((setq gm (gprin1 (car l) n))
;;;			      (cond ((grindmacrocheck gm l)
;;;				     (princ '/./ )
;;;				     (gprin1 l (- n 2.))
;;;				     (setq l ())
;;;				     (go b1))
;;;				    (t (prin1 (car l))))))
;;;
		       (cond ((and (cdr l)
				   (not (and hunkp
					     hunksprin1
					     (hunkp (cdr l)))))
			      (tyo #\space)))
		       (and (cdr (setq l (cdr l))) form3? (go a))
		  b1   (setq n (grchrct)))))))
	b    (grindargs l n m)))

;;; hunk L to be sprinted in space N with M unbalanced /)'s hanging...

(defun standard-hunksprin1 (l n m)
       (cond ((< (gflatsize l) (- n m))
	      (standard-hunkprin1 l n m))
	     ('t 
	      (princ '|(|) 
	      (do ((i 1. (1+ i))
		   (m+3 (+ 3 m))
		   (width (grchrct))
		   (size (hunksize l)))
		  ((= i size)
		   (indent-to n)
		   (sprint1 (cxr 0. l) width m+3)
		   (princ '| .)|))
		  (cond ((> i 1) (indent-to n)))
		  (sprint1 (cxr i l) width m+3)
		  (princ '| . |)))))

(defun (standard-hunksprin1 hunkgflatsize) (x)
       (declare (fixnum i s w))
       (do ((i 0. (1+ i))
	    (s (hunksize x))
	    (w 1. (+ w 3. (gflatsize (cxr i x)))))
	   ((= i s) w)))

(defun standard-hunkprin1 (l n m)
       (princ '|(|)
       (do ((i 1. (1+ i))
	    (m+3 (+ 3 m))
	    (size (hunksize l)))
	   ((= i size)
	    (sprint1 (cxr 0. l) (grchrct) m+3)
	    (princ '| .)|))
	   (sprint1 (cxr i l) (grchrct) m+3)
	   (princ '| . |)))

;;; elements of l are ground one under the
;;; next
;;; prints closing paren if done.
;;; exception of tags which are unindented
;;; 5

(defun grindargs (l nn mm)
       (prog (gm sprarg1 sprarg2)
	a    (and (done? nn) (return ()))
	     (setq sprarg1
		   (cond ((and prog?
			       (car l)
			       (atom (car l)))
			  (+ nn 5.))
			 (nn)))
	     (setq sprarg2 (cond ((null (cdr l)) (1+ mm))
				 ((atom (cdr l))
				  (+ 4. mm (gflatsize (cdr l))))
				 (0.)))
	     (setq gm (sprint1 (car l) sprarg1 sprarg2))

;;;
;;; KMP: The previous setq used to be the COND commented out here. I stripped
;;;      the COND off the outside because GPRIN1 and SPRINT1 always return ()
;;;	 nowadays. This may not be the right thing -- they may not want 
;;;	 to always return (), but this code will never get reached in the
;;;	 current state of things, so it might as well not get compiled in.
;;;
;;;	     (cond ((setq gm (sprint1 (car l) sprarg1 sprarg2))
;;;		    (cond ((grindmacrocheck gm l)
;;;			   (princ '/./ )
;;;			   (sprint1 l (- sprarg1 2.) sprarg2)
;;;			   (setq l ())
;;;			   (go a))
;;;			  (t (prin1 (car l))))))
;;;

	     (setq l (cdr l))
	     (go a))) 

;;; if previous line a ;; comment, then do
;;; not print closing paren on same line as
;;; comment.
;;; prints closing "/)" if done

(defun done? (nn) 
       (cond ((gatomp l)
	      (and /;/;?  (indent-to nn))
	      (cond (l (princ '/ /./ )
		       (cond ((> (gflatsize l) (grchrct)) ; for hunks
			      (indent-to nn)))
		       (sprint1 l (grchrct) m)))
	      (princ '/))
	      't)))


;;; l printed as text with indent n.

(defun gblock (n)
       (prog (gm) 
	     (and (remsemi-tac) (or l (return ())))
	a    (cond ((gatomp l)
		    ;;; Hunks used to not get middle shown by grind. For
		    ;;; people that might have used this feature, we won't
		    ;;; treat hunks specially if HUNKSPRIN1 is not set to
		    ;;; the name of a printer.
		    (princ '|. |)
		    (prin1 l)
		    (return ()))
		   ((setq gm (gprin1 (car l) n))
		    ;;; Result Omitted -- See below
		    ))

;;;
;;; KMP: The previous COND used to have a consequent to its last clause, but
;;;      since GPRIN1 always returns () nowadays, I have factored out that
;;;	 part. This may not be the right thing -- GPRIN1 may not want to always
;;;      return (), but this code will never get reached in the current state
;;;      of things, so it might as well not get compiled in.
;;;
;;;		   ((setq gm (gprin1 (car l) n))
;;;		    (cond ((grindmacrocheck gm l)
;;;			   (princ '/./ )
;;;			   (gprin1 l (- n 2.))
;;;			   (return (setq l ())))
;;;			  (t (prin1 (car l))))) 
;;;

	     (or (popl) (return ()))
	     (cond ((< (gflatsize (car l)) (- (grchrct) 2. m))
		    (tyo #\space)
		    (go a))
		   ;;; non-atomic elements occuring in block
		   ;;;  too large for the line are sprinted. 
		   ;;;  this occurs in the variable list of a prog.
		   ((and (not (atom (car l)))  ;GATOMP?
			 (< (- n m) (gflatsize (car l))))
		    (cond ((setq gm (sprint1 (car l) n m))
		           ;;; KMP: I think this code can never be reached.
			   ;;;      It looks like SPRINT1 always returns ()
			   ;;;      since it looks like GPRIN1 does too...
			   ;;;      Can someone check me on this? Tnx.
			   (cond ((grindmacrocheck gm l)
				  (princ '/./ )
				  (sprint1 l (- n 2.) m)
				  (return (setq l ())))
				 ('t (prin1 (car l))))))
		    (or (popl) (return ()))))
	     ;;; new line
	     (indent-to n)
	     (go a))) 

;;; prin1 with grindmacro feature.

(defun gprin1 (l nn)
       (cond ((gatomp l)
	      (cond ((hunkp l) (funcall hunksprin1 l nn m))
		    ('t (prin1 l)))
	      ())
	     ((prog (gm) 
		    (remsemi-tac)
		    (and (atom (car l))
 			 (let ((x (get (car l) 'grindmacro)))
			      (and x (apply x ())))
			 (return ()))
		    (princ '/()
		    (setq nn (1- nn))
	       a    (setq gm (gprin1 (car l) nn))

;;;
;;; KMP: The previous setq used to be the COND commented out here. I stripped
;;;      the COND off the outside because GPRIN1 always returns () nowadays.
;;;      This may not be the right thing -- GPRIN1 may not want to always
;;;      return (), but this code will never get reached in the current state
;;;      of things, so it might as well not get compiled in.
;;;
;;;                 (cond ((setq gm (gprin1 (car l) nn))
;;;			   (cond ((grindmacrocheck gm l)
;;;				  (princ '/./ )
;;;				  (gprin1 l (- nn 2.))
;;;				  (setq l ())
;;;				  (go a1))
;;;				 (t (prin1 (car l))))))
;;;

		    (popl)
	       a1   (and (done? nn) (return ()))
		    (tyo #\space)
		    (go a))))) 



(comment Special grind functions for system-related facilities)


;;; For use with "macroexpanded" forms

(defun |MACROEXPANDED-grindmacro/|| ()
   (declare (special l m))
   (sprint1 (cond (grind-macroexpanded (nth 4 l)) ((nth 3 l)))
	    (grchrct) 
	    m)
   't)

;;; For help with "backquote" forms
;;;
;;; KMP: This function is put on the GRINDMACRO property of |`-expander/||
;;;      et al when the BACKQ package gets loaded. If you ask me, it should
;;;      get set up at the time this package loads.

(defun |+INTERNAL-`-grindmacros/|| ()
   (declare (special l m))
   (eval (cons 'readmacroinverse
	       (cdr (assq (car l)  
			  '((|`-expander/||  |`|  t)
			    (|`,/||  |,|  t)
			    (|`,@/|| |,@| t)
			    (|`,./|| |,.| t))))))
   't)



;;prediction functions

(declare (unspecial l n m))

;;;for increased speed, l n m are made unspecial in maxpan and panmax
;;; list of s expression one under the next
;;; estimates number of lines to sprint1
;;; in space n

(defun maxpan (l n m) 
       (declare (fixnum g))
       (prog (g)
	     (setq g 0.)
	a    (setq g
		   (+ g
		      (panmax (car l)
			      n
			      (cond ((null (setq l (cdr l))) (1+ m))
				    ((gatomp l) (+ m 4. (gflatsize l)))
				    (0.)))))
	     (and (gatomp l) (return g))
	     (go a))) 

;;; estimates number of lines to sprint1 an
;;; s expression in space n.  less costly
;;; than sprint as prediction always chooses form2.
;;;  if insufficient space, throws.

(defun panmax (l n m) 
       (cond ((< (+ m -1. (gflatsize l)) n) 1.)
	     ((or (< n 3.) (atom l))
	      (*throw () 40.))		      ;should these "atom"s be 
	     ((or (not (atom (car l))) (gatomp (cdr l))) ;"gatomp"'s?
	      (maxpan l (sub1 n) m))
	     (((lambda (x) (and x (funcall x l n m)))
	       (get (car l) 'grindpredict)))
	     ((maxpan (cdr l) (- n 2. (gflatsize (car l))) m)))) 

(defun prog-predict (l n m) 
       ((lambda (nn) (+ (block-predict (cadr l) nn 1.)
			(maxpan (cddr l) nn m)))
	(- n 2. (gflatsize (car l))))) 

(defprop lambda-form prog-predict grindpredict) 

(defprop prog-form prog-predict grindpredict) 

;;; indent=spaces indented to margin of
;;; block. throw if insuff remaining space.
;;; number of lines approx by dividing size of l by
;;; block width.

(defun block-predict (l n indent)
       (cond ((> 1. (setq n (- n indent))) (*throw () 50.))
	     ((1+ (// (- (gflatsize l) indent) n)))))

;;; m not used.

(defun block-predictor (l n () ) (block-predict l n 1.)) ; m = unused 3rd arg

(defprop block-form block-predictor grindpredict) 

;;; m not used by block-predict.  third arg
;;; represents indentation of block.

(defun comment-predict (l n () ) ; m = unused 3rd arg
       (block-predict l n (+ (gflatsize (car l)) 2.)))

(defprop comment-form comment-predict grindpredict) 

(defun readmacroinverse-predict (l n m)
       (panmax (cadr l)
	       (- n (cond ((atom (car l)) (flatc (car l)))
			  ('t (length (car l)))))
	       m)) 

(defprop readmacroinverse readmacroinverse-predict grindpredict) 



(declare (special l n m)) 

;;; user read macros.
;;; (eg (slashify $)).  preserve slashes preceding

(defun slashify fexpr (chars) (mapc 'slashify1 chars))

(defun unslashify fexpr (chars) (mapc 'unslashify1 chars)) 

;;; make char '-like readmacro.
;;; will be null only if char is single

(defun slashify1 (char)
       ((lambda (readtable) 
		(or (null (getchar char 2.))
		    (setq char (error 'slashify
				      char
				      'wrng-type-arg)))
		(setsyntax char
			   'macro
			   (subst char
				  'char
				  '(lambda () (list 'char
						     (read)))))
		(apply 'readmacro (list char char)))
	grindreadtable)) 

(defun unslashify1 (char) 
       ((lambda (readtable) (or (null (getchar char 2.))
				(setq char
				      (error 'unslashify
					     char
					     'wrng-type-arg)))
			    (setsyntax char 'macro ())
			    (apply 'unreadmacro (list char)))
	grindreadtable)) 



;;;(defun gflatsize (data) 
;;;       ((lambda (nn bucket) 
;;;	 (setq bucket (gtab/| nn))
;;;	 (cdr (cond ((and bucket (assq data bucket)))
;;;		    (t (car (store (gtab/| nn)
;;;				   (cons (setq data
;;;					       (cons data
;;;						     (flatsize data)))
;;;					 bucket)))))))
;;;	(\ (ghash data) 127.)
;;;	())) 

(defun gflatsize (data) 
       ((lambda (nn bucket) 
	 (setq bucket (gtab/| nn))
	 (cdr (cond ((and bucket (assq data bucket)))
		    ('t (car (store (gtab/| nn)
				   (cons (setq data
					       (cons data
						     (gflatsize1 data 't)))
					 bucket)))))))
	(\ (ghash data) 127.)
	()))

(defun +internal-dwim-predictfun (l n ())
       (cond ((> (gflatsize1 l 't) n) (*throw () 40.))
	     ('t 1.)))

;;; (GFLATSIZE1 L FLAG)
;;; This is a hook into the gflatsize process that says that we want L's
;;; 

(defun gflatsize1 (l flag)
       (cond ((gatomp l)
	      (let ((fsize-fun (and (hunkp l)
				    (get hunksprin1 'hunkgflatsize))))
		   (cond (fsize-fun (funcall fsize-fun l))
			 ('t (flatsize l)))))
	     ((and flag
		   (symbolp (car l))
		   (let ((fsize-fun (get (car l) 'grindflatsize)))
			(cond (fsize-fun
			       (funcall fsize-fun l))))))
	     ('t 
	      (do ((len 2. (+ len
			      (gflatsize1 (car ll) 't)
			      (cond ((eq l ll) 0.) ('t 1.))))
		   (ll  l  (cdr ll)))
		  ((gatomp ll)
		   (cond ((null ll) len)
			 ('t (+ len 3.
			       (let ((fsize-fun (and (hunkp ll)
						     (get hunksprin1
							  'hunkgflatsize))))
				    (cond (fsize-fun
					   (funcall fsize-fun ll))
					  ('t (flatsize ll))))))))))))

(defun gflatsize=1+cdr (l)
       (1+ (gflatsize1 (cdr l) 't)))

(defun gflatsize=2+cdr (l)
       (+  (gflatsize1 (cdr l) 't) 2.))

(defprop |`-expander/|| gflatsize=1+cdr grindflatsize)
(defprop |`,/||         gflatsize=1+cdr grindflatsize)
(defprop |`,@/||	gflatsize=2+cdr grindflatsize)
(defprop |`,./||	gflatsize=2+cdr grindflatsize)

(defun (/' grindflatsize) (l)
       (cond ((and grind-standard-quote (= (length l) 2.))
	      (+ 1. (gflatsize1 (cadr l) 't)))
	     ((+ 8. (gflatsize1 (cdr l) ()))))) 

(mapc (function
       (lambda (x)
	       (putprop x '+internal-dwim-predictfun 'grindpredict)))
      '(quote |`-expander/|| |`,/|| |`,@/|| |`,./||))



;;; default formats						
;;; still need to define the standard macro

(readmacro quote /')

(grindfn (grindfn grindmacro) (grindform 'line)
			      (grindform 'block)) 

   ;; let needs its own thing...
(grindfn (lambda eval-when) lambda-form)

(grindfn (do) do-form)

   ;; caseq needs to do something much like def-form
(grindfn (defun defun/& defmacro) def-form)

(grindfn prog prog-form) 

(grindfn (comment remob **array *fexpr *expr *lexpr special unspecial fixnum flonum) comment-form) 

(grindfn (member memq map maplist mapcar mapcon mapcan mapc assq
	  assoc sassq sassoc getl fillarray) mem-form) 

(grindfn setq setq-form) 
(grindfn setf setq-form)

(gpredict ()) 

;;;the following default formats are relevant only to grinding files.
;;;however, they appear here since the format fns are not defined
;;;in gfile and gfn is not loaded until after gfile.
;;default formats

(pagewidth 112. 70. 1. 41.) 

(topwidth 110.) 

(grindmerge 't) 

(grindfill 't) 

(user-paging ()) 



;;; The GRINDREADTABLE is tailored for grind.

((lambda (m)
      (and (or (not (boundp 'grindreadtable))
	       (null grindreadtable))
	   ((lambda (readtable) 
		    ;;; ^L made noticeable.
		    (setsyntax 12. 'single ())
		    ;;; No auto cr. are inserted by lisp when
		    (sstatus terpri 't)
		    (setsyntax '/;
			       'splicing
			       'semi-comment))
	    (setq grindreadtable
		  (*array ()
			  'readtable
			  grind-use-original-readtable))))

      (cond ((or m (status feature maclisp))
	     (let ((grindform (status userid)) 
		   (comnt (cond ((status status homed) (status homed))
				((status udir))))
		   (defaultf defaultf)
		   l h)
		  (setq h (cons (list 'dsk comnt)
				(cond ((status feature its) 
				       (cons grindform '(grind)))
				      ('(grind ini)))))
		  (cond ((cond ((setq l (probef h)))
			       ((status feature its)
				(rplaca (cdr h) '*)
				(and
				 ((lambda (errset)
					  (setq l
						(car
						 (errset
						  (funcall 
						   (cond ((status feature sail)
							  'eopen)
							 ('open))
						   h 
						   '(nodefault))
						  () ))))
				  ())
				 (setq l (truename l)))
				l))
			 (or (status feature noldmsg)
			     (prog2 (princ '|Loading GRIND init file| msgfiles)
				    (terpri msgfiles)))
			 (and
			  (atom (errset (funcall (cond ((status feature sail)
							'eload)
						       ('load))
						 l)
					't))
			  (princ '| *** ERRORS DURING LOADING *** BEWARE!| 
				 msgfiles))))))
	    ;;; loader for start_up.grind file
	    ('t (errset (load (list (status udir)
				    'start_up
				    'grind))
			())))) 
 (status feature its))

(sstatus feature grindef)

;;;;;;;;;;;;;;;;;;;;;; Bug Notes // Feature requests ;;;;;;;;;;;;;;;;;;;;;
;;;
;;; [ALAN (07/29/80)] Re: GRINDEF
;;;  GRINDEF, SPRIN1 and friends don't seem to understand about
;;;  (SSTATUS USRHU ...) etc.
;;;
;;; [KMP (09/23/80)] Re: GRINDEF
;;;  The variable GRINDEF should be SETQ-IF-UNBOUND'd or something like that
;;;  rather than just SETQ'd when the GRIND package loads.
;;;
;;; [ALAN (09/26/80)] Re: Old Style DO
;;;  ... why don't you make it understand old-style DO?
;;;
;;; [SOLEY (09/26/80)] Re: GRINDEF
;;;  In NILE;DOC >, the function DOCUMENTOR grinds terribly.
;;;
;;; [ALAN (09/29/80)] Re: Old-Style DO
;;;    Date: 29 September 1980 1115-EDT (Monday)
;;;    From: Guy.Steele at CMU-10A
;;;    Recall that one can always convert old-style DO to new-style
;;;    simply by inserting six parentheses:
;;;    	(DO X INIT STEP TEST BODY) => (DO ((X INIT STEP)) (TEST) BODY)
;;;    SO a quick way out is just to grind every old-style DO as a new-style
;;;    one, by this conversion (this amounts to an implicit declaration of war
;;;    against old-style DO as being obsolete).
;;;    I'm not sure I really advocate this -- just pointing out the 
;;;    possibility. 
;;;  -----
;;;  barf
;;;
;;; [Source: BEN@ML (09/24/80)] Re: GRIND mangles end-of-line comments
;;;  In TOPS-10 MACLISP at Tufts (though I suspect elsewhere, too), GRINDing
;;;  a file that includes end-of-line comments frequently puts the comments on
;;;  the following line, unprotected by semi-colons.  When this is loaded into
;;;  LISP, we get lots of undefined value errors. (At installations that could
;;;  run EMACS, no one would have to run GRIND, but . . .) Ben
;;;
;;; [Source: KMP,SRF,DANIEL (09/19/80)] Re: GRINDEF/TRACE interaction
;;;  (DEFUN F (X) X)		; Define a function
;;;  (GRINDEF F)		; Grinds just fine
;;;  (TRACE F)			; Traces just fine
;;;  (GRINDEF F)		; Grinds just fine with note that it's traced
;;;  (DEFUN F (Y) Y)		; Redefine without untracing
;;;  (GRINDEF)			; Claims traced. Doesn't grind
;;;  (UNTRACE F)		; Untrace doesn't break the F(y) definition
;;;  (GRINDEF F)		; Grinds just fine as F(y)
;;;  -----
;;;  If there is a more recent definition than the traced definition, GRINDEF 
;;;  should allow that definition to supersede the trace information.
;;;
;;; [Reply-To: HMR, RWK, REES] Vectors
;;;  Context: XNIL of 03/17/80
;;;  (defun foo (x) #(A B))
;;;  FOO
;;;  (grindef foo)
;;;   DEFUN FOO (X) #
;;;         (A))
;;;  *
;;;  ; Missing paren, broken over line
;;;
;;; [CWH] Re: TYO
;;;  Make (TYO 100) => (TYO #/@), (TYO 11) as (TYO #\TAB), etc.
;;;
;;; [PRATT (3/18/80)] Re: ##MORE##
;;;  Is grindef supposed to work correctly in conjunction with the standard 
;;;  more-processing?  It seems like it gets confused about whether an 
;;;  s-expression will fit on the current line when that line follows ##MORE##.
;;;
;;; The following functions need special grind handlers --
;;;  DEFMACRO, CASEQ (Maybe like LAMBDA? -JAR), DEFUN& (-RLB), SETF (-RWK)
;;;
;;; #PRINT / GPRINT 
;;;  Waters' printer lives in LIBLSP;GPRINT. See LIBDOC;GPRINT for details.
;;;  DICK;LSPMP QFASL is a version of GPRINT which will run on the LispMachine.
;;;
;;; [Reply-To: BKERNS (05/22/80)] Re: Prin{level/length}
;;;  How hard would it be to make the grinder know about prinlength and
;;;  prinlevel?  I'm in desperate need of such a feature.
;;;
;;; [Reply-To: ALAN (06/28/80)] Re: GRINDEF
;;;  ... since we will continue to support old-style DO can we please have it
;;;  grind properly?  Please?? ...
;;;  
;;; [Reply-To: RLB (06/29/80)] Re: GRINDEF (In-Reply-To: ALAN's note)
;;;  Seconded by me.  Language redesign shouldn't happen defacto by causing
;;;  constructs which you find distasteful to become otherwise distasteful to 
;;;  others.  Is this paranoia or unusual perceptiveness?
;;;
;;; [Reply-To: ALAN (09/18/80)] Re: GRINDEF
;;;  Is anybody EVER going to fix grindef to understand old-style do?
;;;
;;; *** Don't forget crlf after this line! ***

