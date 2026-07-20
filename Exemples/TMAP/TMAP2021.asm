;===========================================================================
;	TMAP2021.ASM - carte memoire du PC-E500S
;	d'apres Tmap Version 1.05, (C)TORO 1994
;
;	Reecriture pour xasm2026-4. Le code machine emis est STRICTEMENT
;	IDENTIQUE a celui de TMAP2020.asm : rien n'a ete reordonne, aucune
;	instruction remplacee par une autre. Seules changent la lisibilite et
;	les verifications faites a l'assemblage.
;
;---------------------------------------------------------------------------
;	CE QUE FAIT CE PROGRAMME
;
;	Il dresse l'etat de la memoire de la machine et l'affiche, ou l'ecrit
;	dans un fichier si un nom lui est passe en argument. Trois inventaires
;	se succedent :
;
;	  1. version de la ROM ;
;	  2. contenu des slots fichiers S1:, S2: et S3:, avec pour chaque
;	     entree son adresse, son nom, ses attributs, sa taille ;
;	  3. peripheriques declares et vecteurs d'interruption installes.
;
;	Le resultat sort par FCS, ce qui permet indifferemment l'ecran ou un
;	fichier : le bit 0 de FLAG distingue les deux.
;
;---------------------------------------------------------------------------
;	POINTS A CONNAITRE AVANT DE MODIFIER
;
;	STRBUF est une etiquette NUE, placee en fin de programme : le tampon
;	d'expansion des chaines s'etend donc au-dela du dernier octet emis. La
;	memoire qui suit le programme est utilisee et ne doit pas etre supposee
;	libre.
;
;	Les lignes ";	PRE 30H" en commentaire sont des vestiges : le prebyte
;	etait autrefois ecrit a la main. PRE_ON etant actif, l'assembleur
;	l'emet desormais tout seul. Elles sont conservees car elles signalent
;	les endroits ou un prebyte est bel et bien produit.
;
;	VECTBL et BASTBL sont des listes TERMINEES PAR ZERO, parcourues en
;	boucle jusqu'a ce marqueur. Retirer le zero final ferait deborder le
;	parcours ; des verifications en fin de fichier en fixent la taille.
;===========================================================================
;
	ORG     0BE000H
;
	pre_on
;
	OR      [FLAG],1
	MV      X,[U]
	MV      A,[X++]
	CMP     A,' '
	JRZ     OPT2
	CMP     A,22H
	JRZ     OPT2
	JR      OPT12
OPT1:
	CMP     A,22H
	JRNZ    OPT11
	INC     X
OPT11:  MV      [U],X
OPT12:  MV      X,_SCRN
	JR      OPT5
OPT2:
	CALL    SKIPSPC
	JRC     OPT1
	CALL    SETFIL
	JPC     ERROR
	AND     [FLAG],0FEH
OPT3:
	MV      A,[X++]
	CMP     A,22H
	JRZ     OPT4
	CMP     A,' '
	JRNC    OPT3
	DEC     X
OPT4:
	MV      [U],X
	MV      X,STRBUF
OPT5:   MV      IL,0
	MV      A,0
	CALLF   FCS
	JPC     ERROR
;	PRE 30H 
	MV      [HANDLE],(CX)
;
	MV      Y,_TITLE
	CALL    PRINT
;ROM Version affichage ------------
	MV      Y,_ROMV
	CALL    CHPUTS
	MV      A,[0FFFF0H]
	CALL    BYTPUT
	MV      A,'.'
	MV      [X++],A
	MV      A,[0FFFF1H]
	CALL    BYTPUT
	CALL    SCRENL
;Afficher le statut du fichier ------
	MV      Y,_FILE
	CALL    PRINT
;
	MV      X,[UWORK]
	MV      Y,[0BFC09H+6+6] ;[S1:]
	MV      A,[0BFC09H+6+6+5]
;	PRE 30H	
	MVP	(SI),_S1
	CALL    PFILE0
;
;Affichage de travaux variables
	MV	X,UWORK
	MV	IL,20
VW:
	MV	Y,[X++]
;	PRE 30H	
	MVP	(SI),[X]
;	PRE 30H	
	CMPP	(SI),Y
	JRZ	VW1			;Inutilise
	PUSHU	IL
	PUSHU	X
	PUSHU	Y
	MV	X,STRBUF
	CALL	ADRPUT			;Adresse de depart
	MV      A,'-'
	MV      [X++],A
;	PRE 30H	
	MV	Y,(SI)
	DEC	Y
	CALL	ADRPUT			;Adresse de fin
	MV	A,5bh
	MV	B,A
	MV	A,' '
	MV	[X++],BA
	MV	Y,[U+3]
	MV	A,3
	SUB	Y,A
	CALL	ADRPUT
	MV	A,' '
	MV	B,A
	MV	A,']'
	MV	[X++],BA
	MV	A,' '
	MV	B,A
	MV	[X++],BA
	POPU	Y
	PUSHU	X			;La taille
;	PRE 30H	
	MV	X,(SI)
	SUB	X,Y
	MV	Y,X
	POPU	X
	CALL	ZDECPUT
	CALL	SCRENL
	POPU	X
	POPU	IL
VW1:	DEC	IL
	JRNZ	VW
;
	MV      Y,[USRWRK]              ;Affichage de la zone utilisateur
	MV      X,0BFC00H
	SUB     X,Y
	JRZ     NOUSR
	PUSHU   X
	MV      X,STRBUF
	CALL    ADRPUT
	MV      Y,_UFREE
	CALL    CHPUTS
	POPU    Y
	CALL	ZDECPUT
	MV      A,' '
	MV      [X++],A
;	PRE 30H 	
	SUB     (0ECH),6
	MVP     (0),[USRWRK]    ;BOTTOM
	MVP     (3),0BFBFFH     ;TOP
	CALL    DVINFO
	CALL    SCRENL
NOUSR:
	MV      Y,[0BFC09H+6]   ;[S2:]
	MV      A,[0BFC09H+6+5]
;	PRE 30H		
	MVP	(SI),_S2
	CALL    PFILE
;
	MV      Y,[0BFC09H]     ;[S3:]
	MV      A,[0BFC09H+5]
;	PRE 30H		
	MVP	(SI),_S3
	CALL    PFILE
	                                ;Afficher l'etat du lien de l'appareil
	MV      Y,_DEV
	CALL    PRINT
	MV      Y,[IOCSH]
DLINK1:
	PUSHU   Y
	MV      Y,[Y+5]
	CALL    ADRPUT  ;ENTRY
	MV      Y,[U]
	MV      A,' '
	MV      [X++],A
	MV      A,[Y+3]
	CALL    BYTPUT  ;ID
	MV      A,' '
	MV      [X++],A 
	MV      A,[Y+4]
	CALL    BYTPUT  ;atr
	MV      A,' '
	MV      [X++],A ;NAME
	CALL    IOCSINFO
	CALL    SCREND
	POPU    Y
	MV      Y,[Y]
	INC     Y
	JRZ     DLINK2
	DEC     Y
	JR      DLINK1
DLINK2:
	CALL    SCRENL
;	PRE 30H 	
	MV      (CX),[HANDLE]
	MV      IL,2
	CALLF   FCS
	RC
	RETF
;
ERROR:
	MV      X,_FERR
	MV      Y,_FERRE-_FERR
	MV      IL,0BH
;	PRE 30H 	
	MV      (CX),0
	CALLF   IOCS
	RETF
;
;
;FILE INFOMATION                        ;Affiche le statut du fichier ==
;
PFILE:
	MV      I,[Y+2]
_197:	MV      X,I             ;etait encode a la main : DB 0FDH,43H
_197E:
	MV      IL,11
FP00:
	ADD     X,X
	DEC     IL
	JRNZ    FP00
	ADD     X,Y
PFILE0:
	DEC     X
	MV      [TOPSLT],X
	MV      X,STRBUF
	CMP     A,0
	JPZ     PFILEE                  ;Ca n'existe pas
;Fente d'affichage -------------
	PUSHU	Y
	CALL	ADRPUT			;Adresse de depart
;	PRE 30H		
	MV	Y,(SI)			;Nom de l'emplacement
	CALL    CHPUTS
	MV	Y,[U]
	MV      I,[Y+2]			;Taille de la fente
_218:	MV      Y,I             ;etait encode a la main : DB 0FDH,53H
_218E:
	MV      IL,11
FP01:
	ADD     Y,Y
	DEC     IL
	JRNZ    FP01
	CALL    ZDECPUT
	CALL    SCRENL
	POPU	Y
	MV      X,[Y+12H]
	ADD     Y,X
PFILE1:
	MV      X,STRBUF                ;Afficher l'adresse de depart --------
	CALL    ADRPUT
	MV      A,[Y]
	CMP     A,0FFH
	JRZ     PFILE3                  ;Bloc de fin
	MV      A,' '
	MV      [X++],A
	PUSHU   Y
	INC     Y
;
	MV      IL,4                    ;Transfert de nom de fichier ------------
PFILE2: MV      BA,[Y++]
	MV      [X++],BA
	DEC     IL
	JRNZ    PFILE2
	MV      A,'.'
	MV      [X++],A
	MV      BA,[Y++]
	MV      [X++],BA
	MV      A,[Y++]
	MV      [X++],A
	MV      A,' '
	MV      [X++],A
;
	MV      A,[Y++]                 ;Affichage d'attribut ------------------
	CALL    BYTPUT
	MV      A,' '
	MV      [X++],A
;
	MV      Y,[U]                   ;Indication de taille ----------------
	MV      Y,[Y+16H]
	MV      A,22H
	SUB     Y,A
	CALL    ZDECPUT
	MV      A,' '
	MV      [X++],A
	                                ;Traitement des notes ------------------
	MV      Y,[U]                   ;Dispositif / TSR
	MV      A,[Y+12]
	MV      Y,_ADEV
	TEST    A,4
	JRNZ    PSMOV
	MV      Y,_ATSR
	TEST    A,8
	JRNZ    PSMOV
PFS:
	MV      Y,[U]                   ;Confirmer le fichier systeme
	MV      BA,[Y+22H]
	MV      I,00FFH
	SUB     BA,I
	JRNZ    PFS3
	MV      A,[Y+24H]
	CMP     A,9
	JRNC    PFS3
	MV      Y,_ASYS
	ADD     Y,A
	ROL     A
	ROL     A
	ADD     Y,A
	MV      IL,5
PFS1:
	MV      A,[Y++]
	MV      [X++],A
	DEC     IL
	JRNZ    PFS1
;
	MV      Y,[U]                   ;BTEXT / BDATA Ç©ÅH
;	PRE 30H 	
	CMPP    (DATBAS),Y
	JRZ     PFS2
;	PRE 30H 	
	CMPP    (TXTBAS),Y
	JRNZ    PFS3
PFS2:   OR      [STRBUF+5],'*'
PFS3:	                                ;Lien de peripherique
;	PRE 30H 	
	SUB     (0ECH),6
	MV      Y,[U]
	MV      (0),Y ;BOTTOM
	PUSHU   X
	MV      X,[Y+16H]
	ADD     Y,X
	POPU    X
	MV      (3),Y ;TOP
	CALL    DVINFO
;
	MV      Y,[U]                   ;Quand il y a une zone libre ----
	MV      X,[Y+16H]
	MV      Y,[Y+11H]
	SUB     Y,X
	JRZ     PFI1
	PUSHU   Y
	MV      Y,[U+3]
	MV      X,[Y+16H]
	ADD     Y,X
	MV      X,STRBUF
	CALL    ADRPUT
	MV      Y,_IFREE
	CALL    CHPUTS
	POPU    Y
	CALL    ZDECPUT
	CALL    SCRENL
PFI1:
	POPU    Y
	MV      X,[Y+11H]
	ADD     Y,X
	JR      PFILE1
PFILE3:
	MV      A,'-'
	MV      [X++],A
	PUSHU   Y
	MV      Y,[TOPSLT]
	CALL    ADRPUT
	MV      Y,_FFREE
	CALL    CHPUTS
	MV      Y,[TOPSLT]
	PUSHU   X
	MV      X,[U+3]
	SUB     Y,X
	POPU    X
	CALL    ZDECPUT
	POPU    Y
	CALL    SCRENL
PFILEE:
	JP      SCRENL
PSMOV:
	MV      IL,5
PFMOV1:
	MV      A,[Y++]
	MV      [X++],A
	DEC     IL
	JRNZ    PFMOV1
	JR      PFS
;
;
;Devide & vector information ====  Affichage de la relation appareil / vecteur
DVINFO:
	MV      Y,[IOCSH] ;DEVICE
	INC     Y
DV1:    DEC     Y
	PUSHU   Y
	MV      Y,[Y+5]
	CMPP    (3),Y
	JRC     DV2
	CMPP    (0),Y
	JRNC    DV2
	CALL    IOCSINFO
DV2:    POPU    Y
	MV      Y,[Y]
	INC     Y
	JRNZ    DV1
;
	MV      Y,VECTBL ;VECTOR
DV3:    PUSHU   Y
	MV      Y,[Y]
	INC     Y
	DEC     Y
	JRZ     DV5
	MV      Y,[Y]
	CMPP    (3),Y
	JRC     DV4
	CMPP    (0),Y
	JRNC    DV4
	MV      Y,[U]
	MV      Y,[Y]
	CALL    ADRPUT
	MV      A,' '
	MV      [X++],A
DV4:    POPU    Y
	MV      A,3
	ADD     Y,A
	JR      DV3
DV5:    POPU    Y
;
	MV      Y,BASTBL ;BAS V
	JR      DV8
DV6:    	PUSHU   Y
;	PRE 30H 	
	MV      Y,(BASWRK)
	ADD     Y,A
	MV      Y,[Y]
	CMPP    (3),Y
	JRC     DV7
	CMPP    (0),Y
	JRNC    DV7
	MV      I,'+B'
	MV      [X++],I
	CALL    BYTPUT
	MV      A,' '
	MV      [X++],A
DV7:    POPU    Y
DV8:    MV      A,[Y++]
	CMP     A,0
	JRNZ    DV6
;	PRE 30H 	
	PMDF    (0ECH),6
	JP      SCREND
;
;Store IOCS information ===== IOCS Nom du peripherique de stockage ======
;
IOCSINFO:
	MV      Y,[U]
	MV      A,8
	ADD     Y,A
	JR      IINFO2
IINFO1:
	MV      A,[Y++]
	MV      [X++],A
	CMP     A,':'
	JRNZ    IINFO1
	MV      A,' '
	MV      [X++],A
IINFO2:
	MV      A,[Y]
	CMP     A,0
	JRNZ    IINFO1
	RET
;
;
;Skip space =============== Ignorer les espaces ==============
;IN     X:POINTER
;OUT    X:POINTER
;       C:Error
;REG    A
;
SKIPSPC:
	MV      A,[X++]
	CMP     A,22H
	JRZ     SKIPS1
	CMP     A,' '
	JRZ     SKIPSPC
	DEC     X
	RET
SKIPS1:
	DEC     X
	SC
	RET
;
;
;Set filename ========== Reglage du nom de fichier ==========
;IN     X:POINTER
;OUT    [STRBUF]:STRINGS
;       C:Error
;REG    BA I X Y
;
SETFIL:
	MV      Y,STRBUF ;iniwork Initialiser la zone de stockage
	MV      A,' '
	MV		B,A
	MV      IL,9
SF1:
	MV      [Y++],BA
	DEC     IL
	JRNZ    SF1
	MV      [Y],IL
	MV      A,'.'
	MV      [Y-04H],A
	MV      Y,STRBUF
	PUSHU   X                       ;Parametrage du nom de lecteur ------------
SF2:
	MV      A,[X++]
	CMP     A,' '+1
	JRC     SF11
	CMP     A,22H
	JRZ     SF11
	CMP     A,':'
	JRNZ    SF2
	POPU    X
	MV      IL,7
SF3:
	MV      A,[X++]                 ;Transfert de nom de lecteur
	DEC     IL
	JRZ     SF13    ;ERROR!
	MV      [Y++],A
	CMP     A,':'
	JRNZ    SF3
	DEC     IL
	ADD     Y,IL
SF4:
	MV      IL,8                    ;Reglage du nom de fichier ------------
SF5:
	MV      A,[X++]
	CMP     A,' '+1
	JRC     SF10
	CMP     A,22H
	JRZ     SF10
	CMP     A,'.'
	JRZ     SF7
	MV      [Y++],A
	DEC     IL
	JRNZ    SF5
SF6:
	MV      A,[X++]                 ;Traitement lorsque le nom du fichier est long
	CMP     A,' '+1
	JRC     SF10
	CMP     A,22H
	JRZ     SF10
	CMP     A,'.'
	JRNZ    SF6
SF7:
	ADD     Y,IL
	INC     Y
	MV      IL,3                    ;Reglage de l'extension ----------------
SF8:
	MV      A,[X++]
	CMP     A,' '+1
	JRZ     SF10
	CMP     A,22H
	JRZ     SF10
	MV      [Y++],A
	DEC     IL
	JRNZ    SF8
SF9:
	MV      A,[X++]
	CMP     A,' '+1
	JRC     SF10
	CMP     A,22H
	JRNZ    SF9
SF10:
	DEC     X
	RC
	RET
SF11:
	MV      X,DEFDRV                ;Nom du lecteur par defaut 
	MV      A,3
SF12:
	MV      I,[X++]
	MV      [Y++],I
	DEC     A
	JRNZ    SF12
	POPU    X
	JR      SF4
SF13:
	SC
	RET
;
;
;Store strings ==================       ;Stocker la chaine ASCII ========
;IN     X:String buffer
;       Y:Bottom of strings
;OUT    X:String buffer(inc)
;REG    A
;
CHPUTS:
	MV      A,[Y++]
	MV      [X++],A
	CMP     A,00H
	JRNZ    CHPUTS
	DEC     X
	RET
;
;
;Store & print strings(add CR+LF)       ;Affichage de la chaine de caracteres (avec saut de ligne) ====
;IN     Y:Bottom of strings
;OUT    X:Bottom of string buffer
;REG    A I (CX)
;
PRINT:
	MV      X,STRBUF
	CALL    CHPUTS
	JR      SCRENL
;
;
;Print stock strings(Del spc)====       ;Affichage de chaine avec espace vide supprime en fin de ligne =
;IN     X:End of strings
;OUT    X:Bottom of string buffer
;REG    A I (CX)
;
SCREND:
	MV      A,[--X]
	CMP     A,' '
	JRZ     SCREND
	INC     X
;
;
;Print stock strings(Add CR+LF)==       ;Affichage de chaines de caracteres enregistrees avec saut de ligne =====
;IN     X:End of strings
;OUT    X:Bottom of string buffer
;REG    A I (CX)
;
SCRENL:
	MV      I,0A0DH
	MV      [X++],I
;
;
;Print stock strings ============       ;afficher la chaine de caracteres stockee
;IN     X:End of strings
;OUT    X:Bottom of string buffer
;REG    A (CX)
;
SCREEN:
	PUSHU   Y
	PUSHU   I
	MV      Y,X
	MV      X,STRBUF
	SUB     Y,X
;	PRE 30H 	
	MV      (CX),[HANDLE]
	MV      IL,4
	CALLF   FCS
	TEST    [FLAG],1
	JRZ     SCREN1
	MV      A,[HEIGHT]             
	MV      IL,[SCRNY]
	SUB     A,IL
	JRNZ    SCREN1
	CALL    KEYIN
SCREN1:
	MV      X,STRBUF
	POPU    I
	POPU    Y
	RET
;
;
;Store number(00000 - FFFFF) ====       ;Y : Stockage hexadecimal ============
;IN     X:String buffer
;       Y:Data
;OUT    X:String buffer(inc)
;REG    BA
;
ADRPUT:
	PUSHU   Y
	MV      A,[U+2]
	CALL    HEXPUT
	MV      A,[U+1]
	CALL    BYTPUT
	MV      A,[U]
	POPU    Y
;
;
;Store number(00 - FF) ==========       ;A : Stockage hexadecimal ============
;IN     X:String buffer
;       A:Data
;OUT    X:String buffer(inc)
;REG    BA
;
BYTPUT:
	MV      B,A
	SWAP    A
	CALL    HEXPUT
	MV      A,B
;
;
;Store number(0 - F) ============       ;A : Memoire hexadecimale a un chiffre ========
;IN     X:String buffer
;       A:Data
;OUT    X:String buffer(inc)
;REG    A
;
HEXPUT:
	AND     A,0FH
	CMP     A,10
	JRC     HEXPU1
	ADD     A,7
HEXPU1:
	ADD     A,'0'
	MV      [X++],A
	RET
;
;
;Store number(     0 - 999999) ==       ;Y Memoriser dans la suppression zero en decimal
;IN     X:String buffer
;       Y:Data
;OUT    X:String buffer(inc)
;REG    A I
;
ZDECPUT:
	CALL    DECPUT
	PUSHU   X
	MV      IL,5
	SUB     X,IL
	DEC     X
ZDECP1:
	MV      A,[X++]
	CMP     A,'0'
	JRNZ    ZDECP2
	MV      A,' '
	MV      [X-1],A
	DEC     IL
	JRNZ    ZDECP1
ZDECP2: POPU    X
	RET
;
;
;Store number(000000 - 999999) ==       ;Y stocker en decimal ==========
;IN     X:String buffer
;       Y:Data
;OUT    X:String buffer(inc)
;REG    A
;
DECPUT:
	PUSHU   X
	MV      X,_DECPU+3
	JR      DECPU4
DECPU1:
	MV      A,'0'
	JR      DECPU3
DECPU2:
	INC     A
DECPU3:
	SUB     Y,X
	JRNC    DECPU2
	ADD     Y,X
	MV      X,[U+3]
	MV      [X++],A
	MV      [U+3],X
	POPU    X
	MV      A,3
	ADD     X,A
DECPU4:
	PUSHU   X
	MV      X,[--X]
	INC     X
	JRNZ    DECPU1
	POPU    X
	POPU    X
	RET
;
;
;Key input routine ==============================
;IN     none
;OUT    BA:Key code
;REG    none
;
KEYIN:
	MV      A,80H
	PUSHU   I
	PUSHU   X
	PUSHU   Y
;	PRE 30H 	
	MV      (CX),1
	MV      IL,43H
	CALLF   IOCS
	POPU    Y
	POPU    X
	POPU    I
	RET
;
_DECPU: DP      99999,9999,999,99,9,0,0FFFFFH
;
_SCRN: DB      'SCRN: ', 0
;
VECTBL:	DP      MENUV,FASTV,SLOWV,KEYV,ONV,SIOSV,SIORV,EXV,IRV,0BFC41H,0BFCC3H,0
VECTBLE:                                ;fin de table, terminateur compris
;
BASTBL:	DB      2,5,8,0BH,0
BASTBLE:                                ;fin de table, terminateur compris
;
_ROMV:	DB      'ROM version:', 0
;
_FILE:	DB      13,10, 'adds  file name    atr size  memo', 13,10, '----- ------------ -- ------ ----------', 0
;
_S1:		DB      ' === S1: ==== == ', 0
;
_S2:		DB      ' === S2: ==== == ', 0
;
_S3:		DB      ' === S3: ==== == ', 0
;
_FFREE:	DB      '    <free> ', 0
;
_IFREE:	DB      ' (free)          ', 0
;
_UFREE:	DB      '-BFBFF <usr free>', 0
;
_ADEV:  DB      '<dev>'
_ATSR:  DB      '<tsr>'
_ASYS:  DB      '<bas><dat><fnc><???><AER><???><bin><dsk><txt>'
;
_DEV:	DB      13,10, 'entry ID atr device name', 13,10, '----- -- -- ---------------------------', 0
;
_FERR:	DB      'File error.', 10
_FERRE:
;
_TITLE:	DB      'Tmap Version 1.05          (C)TORO 1994', 13,10,0
;
FLAG:   DB      0                       ;b0:affiche a l'ecran
HANDLE: DB      0                       ;File handle
TOPSLT: DP      0                       ;Adresse maximale de la fente
STRBUF:                                 ;Tampon de developpement de chaine
;
;LABELS -------------------------
;
;Inner RAM label & port                 
TXTBAS:  EQU 0CBH                        ;TEXT.BAS 
DATBAS:  EQU 0CEH                        ;DATA.BAS
BASWRK:  EQU 0D1H                        ;BASIC zone de travail
BX:      EQU 0D4H                        ;Registre logique
CX:      EQU 0D6H                        ;Registre logique
DX:      EQU 0D8H                        ;Registre logique
SI:      EQU 0DAH                        ;Registre logique
DI:      EQU 0DDH                        ;Registre logique
IOCSW:   EQU 0E6H                        ;IOCS
;BP:      EQU 0ECH                       ;
PX:      EQU 0EDH                        ;Registre de designation relatif auxiliaire RAM interne
PY:      EQU 0EEH                        ;Registre de designation relatif auxiliaire RAM interne
KO:      EQU 0F0H                        ;Specification de la ligne de clavier
KI:      EQU 0F2H                        ;Sortie clavier
EO:      EQU 0F3H                        ;Sortie de port
EI:      EQU 0F5H                        ;Entree de port
IMR:     EQU 0FBH                        ;Interruption activee
SCR:     EQU 0FDH                        ;Systeme de controle OUT
SSR:     EQU 0FFH                        ;Controle du systeme IN
;
;Zone de travail du systeme
SCRNX:   EQU 0BFC27H                     ;position colonne du curseur
SCRNY:   EQU 0BFC28H                     ;position linge du curseur
MENUV:   EQU 0BFC57H                     ;MAIN MENU vecteur
DEFDRV:  EQU 0BFC7DH                     ;Nom actuel du lecteur
DOTSOP:  EQU 0BFC96H                     ;Mode dessin
CSRX:    EQU 0BFC9BH                     ;Curseur x
CSRY:    EQU 0BFC9CH                     ;Curseur y
WIDTH:   EQU 0BFC9DH                     ;Largeur de l'ecran
HEIGHT:  EQU 0BFC9EH                     ;Nombre de lignes d'ecran
LCDMOD:  EQU 0BFCA1H                     ;Flip flag
IOCSH:   EQU 0BFCA2H                     ;IOCS
FASTV:   EQU 0BFCC6H                     ;16ms Vecteur de minuterie
SLOWV:   EQU 0BFCC9H                     ;0.5s Vecteur de minuterie
KEYV:    EQU 0BFCCCH                     ;Vecteur d'entree cle
ONV:     EQU 0BFCCFH                     ;ON Vecteur d'entree cle
SIOSV:   EQU 0BFCD2H                     ;SIO Vecteur de transmission
SIORV:   EQU 0BFCD5H                     ;SIO Recevoir un vecteur
EXV:     EQU 0BFCDBH                     ;Vecteur etendu {BATT]
IRV:     EQU 0BFCC9H                     ;Vecteur d'interruption douce
UWORK:   EQU 0BFCDEH                     ;pile utilisateur
SWORK:   EQU 0BFCE1H                     ;pile systeme
HISBUF:  EQU 0BFCF6H ;History buff       ;Historique tampon
SCCBUF:  EQU 0BFCF9H ;SCC buffer         ;SCC PLAY tampon
USRWRK:  EQU 0BFD1AH                     ;zone de travail de l'utilisateur
;
;SYSTEM ENTRY
FCS:     EQU 0FFFE4H                     ;FCS
IOCS:    EQU 0FFFE8H                     ;IOCS
;
;Source sonore liee
SCCB:    EQU 19000H ;BANK SELECT MEGA ROM Changement de banque
SCCW:    EQU 19800H ;WAVE TABLE (32*4)
SCCT:    EQU 19880H ;TONE TABLE (2*5)
SCCV:    EQU 1988AH ;VOLUME TABLE (1*5)
SCCM:    EQU 1988FH ;MIX FLAG(5bits)
;
_COMPO: EQU 0FFFFFH ;For COMPO
;
;---------------------------------------------------------------------------
;	VERIFICATIONS A L'ASSEMBLAGE
;
;	Elles n'emettent aucun octet : elles interrompent l'assemblage si une
;	hypothese du programme cesse d'etre vraie.
;---------------------------------------------------------------------------
;
; Les deux instructions autrefois ecrites en octets bruts doivent continuer a
; tenir sur deux octets, faute de quoi tout ce qui suit serait decale.
	ASSERT	_197E-_197 = 2,'MV X,I doit tenir sur 2 octets'
	ASSERT	_218E-_218 = 2,'MV Y,I doit tenir sur 2 octets'
;
; VECTBL est parcourue jusqu'a son entree nulle : 11 vecteurs plus le
; terminateur, sur 3 octets chacun.
	ASSERT	VECTBLE-VECTBL = 12*3,'VECTBL : nombre d entrees inattendu'
;
; BASTBL est parcourue de meme : 4 valeurs plus le terminateur, un octet chacune.
	ASSERT	BASTBLE-BASTBL = 5,'BASTBL : nombre d entrees inattendu'

	pre_off
	end
