;;; -*-LISP-*-

;;; Standard way to create a private obarray, starting with a copy
;;;   of the current (standard) obarray, and adding some new symbols
;;;   to be shared between the standard and the new one, and getting 
;;;   private copies of some (possibly already existing) symbols for 
;;;   the private obarray.  Normally, the standard obarray would be
;;;   current when this file is executed, so that LOCALS, GLOBALS
;;;   STANDARD-OBARRAY, and PRIVATE-OBARRAY would appear as global 
;;;   symbols (i.e., on both obarrays).
;;; The lines of comment having "*****" in them, just below, show how
;;;   this file could be modified for incorporation as a leading part
;;;   of some other file.  One could then replace the names used for
;;;   GLOBALS, LOCALS, STANDARD-OBARRAY, and PRIVATE-OBARRAY.


;These lines must be done first, before any other actions, so that the 
; initial creation of PRIVATE-OBARRAY will have on it only the symbols 
; found on the standard obarray.
(PROGN (SETQ STANDARD-OBARRAY OBARRAY 	
	     PRIVATE-OBARRAY (COND ((BOUNDP 'PRIVATE-OBARRAY) PRIVATE-OBARRAY) 
				   ((*ARRAY () 'OBARRAY))))
       (AND (OR (NOT (BOUNDP 'GLOBALS)) (ATOM GLOBALS)) (SETQ GLOBALS () ))
       (AND (OR (NOT (BOUNDP 'LOCALS)) (ATOM LOCALS)) (SETQ LOCALS () )))


;;; ***** (SETQ GLOBALS '(globalsym1 globalsym2 | . . . | globalsymn))
;;; ***** (SETQ LOCALS  '(privatesym1 privatesym2 | . . . | privatesymn))



; Check for conflicting requests.
(AND (MAPCAN '(LAMBDA (GLOBALS) 
	       (MAPCAN '(LAMBDA (LOCALS) 
			 (AND (SAMEPNAMEP GLOBALS LOCALS) (LIST GLOBALS))) 
		       LOCALS))
	     GLOBALS)
     (ERROR '|GLOBALS request conflict with LOCALS for private obarray|))


;So here we try to fix up the two obarrays, as per request
     ; Get private copies of the "local" symbol requests, just to factor 
     ;   out the obarray under which these requests were read in.  
     ; Get the copies of the "global" requests from off the standard obarray,
     ;   and remove any locals from off the standard obarray
(SETQ LOCALS (LET ((OBARRAY PRIVATE-OBARRAY)) 
		  (MAPCAR '(LAMBDA (X) 
				   (REMOB X)
				   (INTERN (COPYSYMBOL X () )))
			  LOCALS)))
(SETQ GLOBALS (LET ((OBARRAY STANDARD-OBARRAY)) 
		   (MAPCAR 'INTERN GLOBALS)))


