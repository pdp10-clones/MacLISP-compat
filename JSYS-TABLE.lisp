;;; -*-Lisp-*-

;;; JSYS-TBL - Twenex JSYS calls.


(eval-when (eval compile) 

  (do ((i 0 (1+ i))
       (l '(JSYS LOGIN CRJOB LGOUT CACCT EFACT SMON TMON GETAB ERSTR GETER 
	    GJINF TIME RUNTM SYSGT GNJFN GTJFN OPENF CLOSF RLJFN GTSTS STSTS 
	    DELF SFPTR JFNS FFFFP RDDIR CPRTF CLZFF RNAMF SIZEF GACTF STDIR 
	    DIRST BKJFN RFPTR CNDIR RFBSZ SFBSZ SWJFN BIN BOUT SIN SOUT RIN 
	    ROUT PMAP RPACS SPACS RMAP SACTF GTFDB CHFDB DUMPI DUMPO DELDF 
	    ASND RELD CSYNO PBIN PBOUT PSIN PSOUT MTOPR CFIBF CFOBF SIBE SOBE 
	    DOBE GTABS STABS RFMOD SFMOD RFPOS RFCOC SFCOC STI DTACH ATACH 
	    DVCHR STDEV DEVST MOUNT DSMNT INIDR SIR EIR SKPIR DIR AIC IIC DIC 
	    RCM RWM DEBRK ATI DTI CIS SIRCM RIRCM RIR GDSTS SDSTS RESET RPCAP 
	    EPCAP CFORK KFORK FFORK RFORK RFSTS SFORK SFACS RFACS HFORK WFORK 
	    GFRKH RFRKH GFRKS DISMS HALTF GTRPW GTRPI RTIW STIW SOBF RWSET 
	    GETNM GET SFRKV SAVE SSAVE SEVEC GEVEC GPJFN SPJFN SETNM FFUFP 
	    DIBE FDFRE GDSKC LITES TLINK STPAR ODTIM IDTIM ODCNV IDCNV NOUT 
	    NIN STAD GTAD ODTNC IDTNC FLIN FLOUT DFIN DFOUT FOO FOO CRDIR 
	    GTDIR DSKOP SPRIW DSKAS SJPRI STO )
	  (cdr l)))
      ((null l))
    (set (car l) i))
	  
  (do ((i #o260 (1+ i))
       (l '(ASNDP RELDP ASNDC RELDC STRDP STPDP STSDP RDSDP WATDP FOO FOO FOO 
	    ATNVT CVSKT CVHST FLHST GCVEC SCVEC STTYP GTTYP BPT GTDAL WAIT
	    HSYS USRIO PEEK MSFRK ESOUT SPLFK ADVIS JOBTM DELNF SWTCH TFORK 
	    RTFRK UTFRK SCTTY FOO OPRFN )
	  (cdr l)))
      ((null l))
    (set (car l) i))

  (setq seter #o336)

;New (not in BBN Tenex) JSYS's added starting at 500

  (do ((i #o500 (1+ i))
       (l '(RSCAN HPTIM CRLNM INLNM LNMST RDTXT SETSN GETJI MSEND MRECV MUTIL 
	    ENQ DEQ ENQC SNOOP SPOOL ALLOC CHKAC TIMER RDTTY TEXTI UFPGS SFPOS 
	    SYERR DIAG SINR SOUTR RFTAD SFTAD TBDEL TBADD TBLUK STCMP SETJB 
	    GDVEC SDVEC COMND PRARG GACCT LPINI GFUST SFUST ACCES RCDIR RCUSR 
	    MSTR STPPN PPNST PMCTL LOCK BOOT UTEST USAGE FOO VACCT NODE ADBRK )
	  (cdr l)))
      ((null l))
    (set (car l) i))

  (setq gtblt #o634)	 ;6 GETAB BLT JSYS
	  
   ;Temporary JSYS definitions
	  
  (do ((i #o750 (1+ i))
       (l '(SNDIM RCVIM ASNSQ RELSQ)
	  (cdr l)))
      ((null l))
    (set (car l) i))

  (do ((i #o770 (1+ i))
       (l '(THIBR TWAKE MRPAC SETPV MTALN TTMSG)
	  (cdr l)))
      ((null l))
    (set (car l) i))

)