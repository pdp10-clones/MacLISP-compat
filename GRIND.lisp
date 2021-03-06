

;;;   -*-LISP-*-
;;;   ***********************************************************************
;;;   ***** Maclisp ****** S-expression formatter for files (grind) *********
;;;   ***********************************************************************
;;;   ** (c) Copyright 1980 Massachusetts Institute of Technology ***********
;;;   ****** this is a read-only file! (all writes reserved) ****************
;;;   ***********************************************************************
;;; This version of Grind works in both ITS Maclisp and Multics Maclisp
;;; GFILE - fns for pretty-printing and grinding files.

(eval-when (eval compile)
	   (or (status nofeature MACLISP)
	       (status macro /#)
	       (load '((LISP) SHARPM)))
)

(herald GRIND /422)

(declare (array* (notype (gtab/| 128.)))
	 (special merge readtable grindreadtable remsemi ~r
		  grindpredict grindproperties grindef predict
		  grindfn grindmacro programspace topwidth 
		  grindlinct global-lincnt /; /;/; user-paging form
		  prog? n m l h arg chrct linel pagewidth gap comspace
		  grindfill nomerge comnt /;/;? ^d macro unbnd-vrbl
		  cnvrgrindflag outfiles infile stringp)
	 (*expr form topwidth programspace pagewidth comspace
		nomerge remsemi stringp)
	 (*fexpr trace slashify unslashify grindfn grindmacro
		 unreadmacro readmacro grindef)
	 (*lexpr merge predict user-paging grindfill testl)
	 (mapex t)
	 (genprefix gr+)
	 (fixnum nn
		 mm
		 (grchrct)
		 (newlinel-set fixnum)
		 (prog-predict notype fixnum fixnum)
		 (block-predict notype fixnum fixnum)
		 (setq-predict notype fixnum fixnum)
		 (panmax notype fixnum fixnum)
		 (maxpan notype fixnum fixnum)
		 (gflatsize))) 




(prog () 							       ;some initializations
      (and (not (boundp 'grind-use-original-readtable))
	   (setq grind-use-original-readtable t))
      (and (or (not (boundp 'grindreadtable))			       ;readtable (default).
	       (null grindreadtable))
	   ((lambda (readtable) (setsyntax 12. 'single ())	       ;^l made noticeable.
				(setsyntax '/;
					   'splicing 
					   'semi-comment)) 
	        (setq grindreadtable
		      (*array ()
			      'readtable
			      grind-use-original-readtable))))
      (setq macro '/; 
	    /; (copysymbol '/; ()) 
	    /;/; (copysymbol '/;/; ()))
      (setq grindlinct 8. global-lincnt 59. comnt () /;/;? ())
      (setq stringp (status feature string))
)


;;; Grinds and files file.
(defun grind fexpr (file)
      ((lambda (x) 
	  (cond ((and stringp (stringp (car file))))	;already filed.
		(t (cond ((not (status feature its))
			  (cond ((status feature DEC20)
				 (setq x (append (namelist x) () ))
				 (rplacd (cddr x) () ))
				((probef x) (deletef x)))))
		   (apply 'ufile x)))
	   file)
	 (apply 'grind0 file)))

 (defun grind0 fexpr (file) 					       ;grinds file and returns file
	      (or (status feature grindef)
		  (funcall autoload (cons 'grindef (get 'grindef 'autoload))))
	(prog (remsemi linel *nopoint readtable base l ^q ^r ^w ^d 
	       outfiles eof n /;/;? comnt terpri) 
	      (setq base 10. linel programspace 
		    readtable grindreadtable remsemi t)
	      (cond
	       ((and stringp (stringp (car file)))
		(inpush (openi (car file)))
		(setq 
		 outfiles
		 (list
		  (openo
		   (mergef
		    (cond ((null (cdr file))
			   (princ '|/Filing as !GRIND OUTPUT |)
			   '(* /!GRIND OUTPUT))
			  ((cadr file)))
		    (cons (car (namelist ())) '*) )))))
	       ('t (apply (cond ((status feature sail) 'eread) ('uread))
			  (cond ((and (null (cdr file)) (symbolp (car file)))
				 (car file))
				((and (status feature sail) 
				      (cadr file)
				      (eq (cadr file) 'dsk))
				 (cons (car file) (cons  '| | (cdr file))))
				('t file)))
		   (uwrite)))
	      (setq eof (list ()) n topwidth)
	      (setq ^q t ^r t ^w t grindlinct global-lincnt)
	 read (and (= (tyipeek 47791616. -1) 
		      59.)			  ;catch top-level splicing macro
		   (readch)
		   (cond ((eq (car (setq l (car (semi-comment)))) /;)
			  (rem/;)
			  (go read))
			 (t (go read1))))
	      (and (null ^q) (setq l eof) (go read1))		       ;catch eof in tyipeek
	      (and (eq (car (setq l (read eof))) /;)		       ;store /; strings of /; comments.
		   (rem/;)
		   (go read))
	 read1(prinallcmnt)					       ;print stored /; comments
	      (or (eq eof l) (go process))
	 exit (terpri)
	      (setq ~r ())
	      (and stringp 
		   (stringp (car file))
		   (close (car outfiles)))			       ;won't get ufile'd
	      (return file)
	 process
	      (cond ((eq l (ascii 12.))				       ;formfeed read in ppage mode
		     (or user-paging (go read))			       ;ignore ^l except in user-paging mode.
		     (and (< (tyipeek 50167296. -1) 0)
			  (go exit))					;any non-trivial characters before eof?
		     (terpri)
		     (grindpage)
		     (setq /;/;? t)
		     (go read))
		    ((eq (car l) /;/;)				       ;toplevel ;;... comment
		     (newlinel-set topwidth)
		     (or /;/;? (= linel (grchrct)) (turpri) (turpri))  ;produces  blank line preceding new
		     (rem/;/;)					       ;block of /;/; comments. (turpri is
		     (newlinel-set programspace)		       ;already in rem/;/;).  a total of 3
		     (go read)))				       ;turpri's are necessary if initially
	      (fillarray 'gtab/| '(()))				       ;chrct is not linel, ie we have just
	      (cond (user-paging (turpri) (turpri))		       ;finished a line and have not yet cr.
		    ((< (turpri)
			(catch (\ (panmax l (grchrct) 0.) 60.)))       ;clear hash array
		     (grindpage))
		    ((turpri)))
	      (cond ((eq (car l) 'lap) (lap-grind))
		    ((sprint1 l linel 0.) (prin1 l)))
	      (tyo 32.)							 ;prevents toplevel atoms from being
	      (go read))) 					       ;accidentally merged by being separated only by
								       ;cr.


(defun newlinel-set (x) 
    (setq chrct (+ chrct (- x linel))
	  linel x))

(putprop /; '(lambda (l n m) 0.) 'grindpredict) 

(putprop /;/; '(lambda (l n m) 1.) 'grindpredict) 

;;semi-colon comments

(defun rem/; () 
       (prog (c retval) 
	a    (cond ((atom l) (return retval))
		   ((eq (car l) /;)
		    (setq c (cdr l))
		    (setq retval 'car)
		    (setq l ()))
		   ((and (null (atom (car l))) (eq (caar l) /;))
		    (setq c (cdar l))
		    (setq retval 'caar)
		    (setq l (cdr l)))
		   (t (cond ((and (eq retval 'caar)		       ;look ahead to separate comments.
				  (cdr l)
				  (null (atom (cdr l)))
				  (null (atom (cadr l)))
				  (eq (caadr l) /;))
			     (prinallcmnt)
			     (indent-to n)))
		      (return retval)))
	b    (cond ((null comnt) (setq comnt c))
		   ((< comspace (length comnt)) (turpri) (go b))
		   ((nconc comnt (cons '/  c))))
	     (go a))) 


(defun rem/;/; () 
       (prog (c retval) 
	a    (cond ((atom l)
		    (and (eq retval 'caar) (indent-to n))
		    (return retval))
		   ((eq (car l) /;/;)
		    (setq c (cdr l))
		    (setq retval 'car)
		    (setq l ()))
		   ((and (null (atom (car l))) (eq (caar l) /;/;))
		    (setq c (cdar l))
		    (setq retval 'caar)
		    (setq l (cdr l)))
		   (t (and (eq retval 'caar) (indent-to n))	       ;restore indentation for upcoming code
		      (return retval)))
	     (prinallcmnt)
	     (and (null /;/;?) (turpri))
	     (prog (comnt pagewidth comspace macro) 
		   (setq comnt c)
		   (and (or (memq (car c) '(/; *))
			    (null merge))			       ;nomerge.  update pagewidth, comspace
			(setq /;/;? '/;/;/;)			       ;appropriate for a total line of
			(setq pagewidth topwidth 		       ;topwidth
			      comspace (+ n (- topwidth linel)))
			(go prinall))
		   (setq pagewidth linel)
		   (cond ((eq /;/;? /;/;)			       ;preceding comnt.  merge.
			  (setq comnt (cons '/  comnt))
			  (setq macro (ascii 0.))
			  (setq comspace (grchrct))
			  (prin50com))
			 ((setq /;/;? /;/;)))
		   (setq comspace n)
	      prinall
		   (setq macro /;/;)
		   (prinallcmnt))
	     (tj6 c)
	     (go a))) 

(defun tj6 (x) 							       ;tj6 commands: ;;*--- or ;;*(...) (...)
       (and
	(eq (car x) '*)
	(setq x (cdr x))
	(turpri)
	(cond
	 ((errset
	   (cond ((atom (car (setq x
				   (readlist (cons '/(
						   (nconc x
							  '(/))))))))
		  (eval x))
		 ((mapc 'eval x)))))
	 ((error '/;/;*/ error x 11.))))) 


(defun prin50com () 						       ;prints one line of ; comment
       (prog (next)
	   (newlinel-set pagewidth)				       ;update linel, chrct for space of pagewidth.
	   (prog (comnt) (indent-to comspace))
	   (princ macro)
	   pl
	   (cond ((null comnt) (return ()))
		 ((eq (car comnt) '/ )
		  (setq comnt (cdr comnt))
		  (setq next
			(do ((x comnt (cdr x)) (num 2. (1+ num)))      ;number of characters till next space.
			    ((or (null x) (eq (car x) '/ ))
			     num)))
		  (cond ((and (or (eq macro /;) (eq /;/;? /;/;))
			      grindfill 
			      (= next 2.)
			      (go pl)))
			((and (not (eq macro (ascii 0.)))
			      (> next comspace)))
			((< (grchrct) next) (return ())))
		  (tyo 32.)
		  (go pl))
		 ((> (grchrct) 0.)
		  (princ (car comnt))
		  (and (or (eq macro /;) (eq /;/;? /;/;))
		       grindfill
		       (eq (car comnt) '/.)
		       (eq (cadr comnt) '/ )
		       (tyo 32.)))
		 (t (return ())))
	   (setq comnt (cdr comnt))
	   (go pl))
		(newlinel-set programspace)) 		       ;may restore chrct to be negative.

(defun prinallcmnt () (cond (comnt (prin50com) (prinallcmnt))))       ;prints \ of ; comment

(defun semi-comment () 					       ;converts ; and ;; comments to exploded
       (prog (com last char) 					       ;lists
	     (setq com (cons /; ()) last com)
	     (setq char (readch))				       ;decide type of semi comment
	     (cond ((eq char '/
) (return (list com)))
		   ((eq char '/;) (rplaca last /;/;))
		   ((rplacd last (cons char ()))
		    (setq last (cdr last))))
	a    (setq char (readch))
	     (cond ((eq char '/
) (return (list com)))
		   ((rplacd last (cons char ()))
		    (setq last (cdr last))
		    (go a))))) 


(defun grindcolmac () (list ': (read))) 

(defun grindcommac () (list '/, (read))) 

(defun grindatmac () (cons '@ (read))) 

(defun grindexmac () 
       (prog (c f) 
	     (setq c (grindnxtchr))
	ta   (cond ((setq f (assq c '((" /!") (@ /!@) ($ /!$))))
		    (tyi)
		    (return (cons (cadr f) (read))))
		   ((setq f (assq c
				  '((? /!?) (/' /!/') (> /!>) (/, /!/,)
				    (< /!<) (/; /!/;))))
		    (tyi)
		    (setq f (cadr f)))
		   (t (setq c (error 'bad/ /!/ macro
				     c
				     'wrng-type-arg))
		      (go ta)))
	     (return (cond ((grindseparator (grindnxtchr))
			    (list f ()))
			   ((atom (setq c (read))) (list f c))
			   (t (cons f c)))))) 

(defun grindnxtchr () (ascii (tyipeek))) 

(defun grindseparator (char) (memq char '(| | |	| |)|)))	;space, tab, rparens	

(sstatus feature grind)
