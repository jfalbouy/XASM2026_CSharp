;---------------------------------------------
;	tydos.asm   for PC-E500s  Ver 1.0
;	Jean-François Albouy	12/06/2019
;---------------------------------------------
;
;=== Variables et constantes =============================================
;-Constantes -----------
CR:		equ $0d
LF:		equ $0a
EOF:	equ $1a
;-----------------------
;
;-Mémoire interne ------
bl:		equ	0d4h
bh:		equ	0d5h
cl:		equ	0d6h
ch:		equ	0d7h
dl:		equ	0d8h
dh:		equ	0d9h
cx: 	equ 0d6h
si:		equ	0dah
scr:	equ 0fdh
;-----------------------
;
;- Mémoire externe -----
fcs_call:	equ	0fffe4h
iocs_call:	equ	0fffe8h
lcd_heigh:	equ 0bfc9eh
defdrv: 	equ 0bfc7dh
usrwrk:		equ 0bfd1ah
;-----------------------
;
;========================================================================
;
	org	0bf800h
;
	pre_on
;
;=== Main ===============================================================
;- Initialisation de la zone mémoire ---
begin:	mv a,4				
		mv [lcd_heigh],a 					;nombre de lignes à afficher
		and [flag],0						;flag initialisation
		mv y,ptr_str
		mv x,ptr_str
		mv [y++],x
		mv x,kbd							;buffer clavier
		mv [y++],x
		mv x,flag
		mv [y++],x
		mv x,iocs_call
		mv a,3								;jpf
		mv [y++],a 
		mv [y++],x							;jpf 0fffe8h (IOCS)
		mv x,fcs_call
		mv [y++],a 
		mv [y++],x							;jpf 0fffe4h (FCS)
		mv x,run_il
		mv [y++],a
		mv [y++],x							;jpf 0bf907h (traitement IL)
		mv a,($ec)							;lecture de BP
		pushu a								;sauvegarde de BP sur la pile
		mv [stacks],s						;sauvegarde pile système
		mv [stacku],u						;sauvegarde pile utilisateur
		mv il,$10							;Initialize a file control system
		mv a,1								;release all FCB, File handle and File buffer
		call run_fcs						;callf FCS
		mv a,2								;file handle PRN
		call close_fcb						;close FCB printer
;
start:	test [flag],2						;test du flag
		jrnz st2
		test [flag],1						;test du flag
		jrnz st1
;
		;affichage du titre ---
		mv x,tydos_title					;titre à afficher
		mv y,btmtydostitle - tydos_title	;longueur du texte
		mv il,4								;Writing a block of the file
		mv (cl),0							;cl = file handle, ici LCD
		call run_fcs						;callf FCS
;
st1:	mv x,tycom_title					;titre de tycom.sys
		mv y,file_buf
		mv il,2								;lecture buffer fichier
		callf ptr_runil						;appel de la routine de traitement
		mv x,file_buf
		mv il,1								;opening a file
		mv a,1								;file is opening for reading-out
		call run_fcs						;callf FCS
		jrc st2								;saut si erreur
		mv a,(cl)							;lire la valeur du File handle
		pushu a								;sauver la valeur sur la pile
		mv il,1								;Lecture du fichier TYCOM.SYS
		callf ptr_runil						;appel de la routine de traitement
		jrc st2								;saut si erreur en bf907h
		cmp a,0
		jrz st2
		popu a 								;récupérer le file handle
		mv il,3								;execution de tycom.sys
		callf ptr_runil						;appel de la routine de traitement
st2:	mv s,[stacks]						;récupérer la pile système
		mv u,[stacku]						;récupérer la pile utilisateur
		mv il,$10							;initializing a file control system
		mv a,1								;release all FCB, file handle and file buffer
		call run_fcs						;callf FCS
		popu a 								;récupérer BP
		mv ($ec),a 							;restaurer la valeur d'origine
		rc									
		retf								;retour au BASIC
;========================================================================
;
;----------- Routines ---------------------------------------------------
;--- Lecture du clavier -------------------------------------------------
			mv il,5							;reading a byte of the file
			mv (cl),1						;cl = file handle, ici clavier
			jr run_fcs						;callf FCS
;
;--- Ecriture à l'écran -------------------------------------------------
			mv il,6							;writing a byte of the file
			mv (cl),0						;cl = file handle, ici l'écran
			jr run_fcs						;callf FCS
;
;--- Fermeture de fichier -----------------------------------------------
close_fcb:	mv (cl),a 						;cl = file handle
			mv il,2							;closing a file
;
;--- Appel FCS ----------------------------------------------------------
run_fcs: 	and ($ea),$f7
			callf ptr_fcs					;callf FCS
			or ($ea),$08
			ret
;------------------------------------------------------------------------
;
;----------- Messages ---------------------------------------------------
tydos_title:	db $0c,'TY-DOS V1 system by T.Yamaguchi', CR, LF
btmtydostitle:
tycom_title:	db 'TYCOM.SYS', CR
btmtycomtitle:	
;------------------------------------------------------------------------
;
;************* routines des fonctions selon IL ******************
; les branchements aux sous-routines se font en décrémentant    *
; la valeur de IL												*
;           													* 
; IL = 1, run_il		Lecture du fichier TYCOM.SYS            *
; IL = 2, run_il2		Lecture buffer fichier		            *
; IL = 3, run_il3		Exécution de TYCOM.SYS                  *
; IL = 4, run_il4		Calcule buffer IOCS                     *
; IL = 5, run_il5		Calcul adresse de TYCOM.SYS             *
; IL = 6, run_il6 		Modification buffer IOCS Work           *
; IL = 7, run_il7 		Se positionner au début de la routine   *
; IL = 8, run_il8		Traitement erreur                       *
;****************************************************************
;
; IL = 1 : lecture TYCOM.SYS ************************************
run_il:		dec il
			jrnz run_il2					;saut si IL > 1
			pushu a							;sauver le file handle
			popu a 
			pushu a 
; lecture du header du fichier ---
			mv (cl),a 						;cl = file handle
			mv il,7							;verifying a file
			mv x,header						;lead address of the file to be verified
			mv y,btmheader - header			;5 bits to be verified "FF 00 06 01 10"
			mv a,1							;physical end of file
			call run_fcs					;callf fcs
			jrnc run_il10					;saut si pas d'erreur
			cmp a,$0b 						;error in data verification
			jrz run_il11					;saut si cette errreur
			jr run_il12						;sinon retour avec code d'erreur
;	
; lecture complet du fichier ---
run_il10:	popu a							;récupérer le file handle
			pushu a							;sauver de nouveau la valeur
			mv (cl),a 						;cl = file handle
			mv il,3							;reading a block of the file
			mv x,file_buf					;lead address to which data is transfered
			mv y,11							;read the 11 bits of the header file
			mv a,1							;physical end of file
			call run_fcs					;callf fcs
			jrc run_il12					;saut si erreur
			mv y,[file_buf]					;taille du fichier dans le header
			mv x,[file_buf+3]				;adresse d'immplantation dans le header
			popu a 							;récupérer le file handle
			mv a,1							;valeur de retour
			rc
			retf
;
; Error in data verification ---
run_il11:	mv il,9							;moving a file pointer
			popu a 							;récupérer le file handle
			mv (cl),a 						;cl = file handle
			mvp (si),0						;(si) : nombre de bits à déplacer
			mv a,0							;déplacement depuis le début de fichier
			call run_fcs					;callf fcs
			jrc run_il12					;saut si erreur
			mv a,0							;valeur de retour à zéro
			rc								;reset carry nul
			retf
run_il12:	sc								;carry = 1
			retf							;A = code de l'erreur
;
; Reading a byte of the file ---
run_il13:	mv il,5
			popu a 							;récupérer le file handle
			pushu a 						;sauvegarder le file handle
			mv (cl),a 						;cl = file handle
			jp run_fcs						;jpf fcs
;		
; Header de tycom.sys ----------------------		
header:		db	$ff,$00,$06,$01,$10
btmheader:
;-------------------------------------------
;
; IL = 2 Lecture buffer fichier *********************************
run_il2:	dec il
			jpnz run_il3					;saut si IL > 2
	;- initialisation du buffer -
			mv a,1							;on positionne le flag
			mv [file_buf],a 		
			pushu y							;file_buf
			mv ba,$2020						;double espaces
			mv il,9							;18 espaces à copier
run_il21:	mv [y++],ba						;recopie des valeurs
			dec il							;décrémenter le compteur
			jrnz run_il21					;boucler tant que non nul
			popu y							;récuper file_buf
			pushu y							;sauver file_buf	
;
run_il22:	mv a,[x++]						;tycom_title
			call fch1						;lecture fin de chaine
			jpc err1						;saut si erreur
;
			cmp a,'-'						;flag token
			jrz run_il2994
			cmp a,'<'						;redirection
			jrz run_il23
			cmp a,'>'
			jrnz run_il24
run_il23:	sub a,'8'						;a=4 ou 6
			ror a							;a / 2 = 2 ou 3
			mv [file_buf],a					;sauver la valeur
run_il24:	call fch2						;lecture des caractères spéciaux
			jrc run_il22					;boucler sur la lecture de la chaine
run_il25:	call fch1						;lecture code fin de chaine
			jrc err1						;saut si fin de chaine
			call fch2						;lecture des caractères spéciaux
			jrc run_il25					;boucler sur la lecture de la chaine
			cmp a,'.'						;extension de fichier
			jrz run_il296
			dec x							;se positionner sur le dernier caractère
			popu y							;file_buf
			pushu x							;sauver l'adresse du dernier caractère lu
;
	;- lecture driver name par défaut -
run_il26:	mv a,[x++]
			cmp a,':'
			jrz run_il28					
			call fch2						;lecture des caractères spéciaux
			jrnc run_il26					;boucler sur la lecture de la chaine
			mv x,defdrv						;DEFDRV : nom du lecteur actuel, 0 terminal
			pushu y							;sauver file_buf
run_il27:	mv a,[x++]						;lecture du caractère
			mv [y++],a						;recopie de DEFDRV
			cmp a,':'
			jrnz run_il27					;boucler sur la lecture de la chaine
			popu y							;file_buf
			popu x							;dernière adresse lue dans file_buf
			pushu y
			jr run_il291
;
	;- lecture driver name contenu dans le nom de fichier -
run_il28:	popu x
			pushu y
			mv il,6							;nombre de caractères
run_il29:	mv a,[x++]						;lire la valeur
			mv [y++],a 						;la recopier
			cmp a,':'
			jrz run_il291					;saut si trouvé
			dec il							;décrémenter le compteur
			jrnz run_il29					;boucler si non nul
			jr err1
;
	;- lecture du file name -
run_il291:	mv il,8							;nombre de caractères de file name
			popu y							;file_buf
			pushu y
			mv a,6							;se positionner sur ':'
			add y,a 						;calcul de la nouvelle adresse
			mv a,[x]						;lire la valeur à cette nouvelle adresse
			call fch2						;lecture des caractères spéciaux
			jrnc run_il292
;
	;- lecture de l'extension-
			call fch5						;recopie "?" * IL
			mv a,'.'
			mv [y++],a						;recopier la valeur
			mv il,3							;nombre de caractères à copier
			call fch5						;recopie "?" * IL
			jr run_il2993
;
run_il292:	mv a,[x++]						;lire la valeur
			cmp a,'*'
			jrnz run_il293
			call fch5						;recopie "?" * IL
			jr run_il295
;
run_il293:	call fch2						;lecture des caractères spéciaux
			jrc run_il294					
			mv [y++],a						;recopier la valeur
			dec il							;décrémenter le compteur
			jrnz run_il292					;boucler tant que non nul
			jr run_il295
;
;--- lecture de l'extension de fichier ---
run_il294:	dec x							;décrémenter l'adresse
run_il295:	mv a,[x++]						;lire la valeur
			cmp a,'.'
			jrz run_il296
			dec x							;se positionner sur le dernier caractère lu
run_il296:	popu y							;se positionner au début du buffer fichier
			pushu y							;sauver l'adresse
			mv a,14							;taille de 'drive name + file name'
			add y,a 						;calcul de l'adresse de l'extension
			mv a,'.'						
			mv [y++],a 						;recopier la valeur
			mv il,3							;compteur 3 caractères
;
	;- copie de l'extension de fichier -
run_il297:	mv a,[x++]						;lire la valeur
			cmp a,'*'
			jrnz run_il298
			call fch5						;recopie "?" * IL
			jr run_il299
;
run_il298:	call fch2						;lecture des caractères spéciaux
			jrc run_il299
			mv [y++],a						;recopie de la valeur
			dec il							;décrémenter le compteur
			jrnz run_il297					;boucler tant que non nul
;
run_il299:	dec x							;se positionner sur le dernier caractère lu
run_il2991:	mv a,[x++]						;lire le caractère
			call fch2						;lecture des caractères spéciaux
			jrnc run_il2991					;boucler tant que non fin de ligne
;
	;- clore le nom de fichier -
run_il2992:	dec x							;se positionner sur le dernier caractère lu
run_il2993:	popu y
			pushu y							;file_buf
			mv a,18							;se positionner après l'extension
			add y,a							;calcul de la nouvelle adresse
			mv a,0							;ajout du zéro terminal
			mv [y++],a						;recopie de la valeur
			jr run_il2999
;
	;- traitement des tokens -
run_il2994:	and [file_buf],0
			mv il,16						;nombre de caractères
run_il2995:	dec il							;décrémenter le compteur
			jrz run_il2997
			mv a,[x++]						;lire la valeur
			call fch2						;lecture des caractères spéciaux
			jrc run_il2998
;
	;- conversion en majuscule -
			cmp a,'a'
			jrc run_il2996
			cmp a,'z'+1
			jrnc run_il2996
			sub a,$20						;conversion en majuscule
run_il2996:	mv [y++],a						;recopier la valeur
			jr run_il2995					;boucler tant que non nul
;
run_il2997:	mv a,[x++]						;lire le caractère
			call fch2						;lecture des caractères spéciaux
			jrnc run_il2997
run_il2998:	dec x							;décrémenter l'adresse
run_il2999:	mv a,[file_buf]					;se positionner sur le premier caractère
			popu y							;file_buf
			rc
			retf
;
err1:		dec x							;décrémenter les adresses
			popu y
			mv a,$81						;flag d'erreur
			sc
			retf
;
;--- Lecture des caractères de fin de chaine ---
fch1:		cmp a,CR						;Retour chariot
			jrz fch4
			cmp a,$ff						;Fin de fichier
			jrz fch4
			cmp a,0							;Fin de chaine
			jrz fch4
			cmp a,EOF						;Fin de fichier
			jrz fch4
			jr fch3
;
;--- Lecture des caractères spéciaux ---
fch2:		cmp a,'?'
			jrz fch3
			cmp a,'*'
			jrz fch3
			cmp a,'0'
			jrc fch4						;erreur si a < '0'
			cmp a,':'
			jrc fch3
			cmp a,'@'
			jrc fch4
			cmp a,'Z'+1
			jrc fch3
			cmp a,'_'
			jrz fch3
			cmp a,'a'
			jrc fch4
			cmp a,'z'+1
			jrc fch3
			cmp a,$80
			jrc fch4
			cmp a,$ff						;Fin de fichier
			jrz fch4
fch3:		rc
			ret
fch4:		sc
			ret
;
;- Recopie de "?" à l'adresse pointée par Y ---
fch5:		mv a,'?'						;IL = nombre de caractère à copier
fch6:		mv [y++],a						;recopie de la valeur
			dec il							;décrémenter le compteur
			jrnz fch6						;boucler tant que non nul
			ret
;-------------------------------------------
;
; IL = 3 Exécution de TYCOM.SYS *********************************
run_il3:	dec il
			jrnz run_il4					;saut si IL > 4
			pushu x							;sauver l'adresse d'implantation
			pushu a							;sauver le file handle
			mv (cl),a						;cl = file handle	
			mv a,1							;physical end of file
			mv il,3							;reading a block and writing in memory, y = data sise
			call run_fcs					;callf FCS
			jrc run_il32					;saut si erreur
			popu a 							;récupérer le file handle
			call close_fcb					;close a file
			jrc run_il32					;saut si erreur
			mv x,run_il31					;adresse de retour après le saut à tycom.sys
			mv [--s],x						;sauver l'adresse de retour
			popu x							;dépiler l'adresse d'immplantation
			mv y,[kbd_nxt]					;adresse suivante dans buffer de saisie
			pushu y							;sauver cette adresse
			jp x							;exécution de tycom.sys
;
run_il31:	popu y							;récupérer l'adresse suivante dans buffer clavier
			mv s,[stacks]					;rétablir la pile système
			mv u,[stacku]					;rétablir la pile utilisateur
run_il32:	jp start						;boucler au début du programme
;--------------------------------------------
;
; IL = 4 modification buffer IOCS *********************************
run_il4:	dec il
			jrnz run_il5					;saut si IL > 5
			mv il,6
			callf ptr_runil					;jpf bf907h
			mv y,x							;Y = nouvelle adresse de IOCS work
			mv x,[usrwrk]					;USRWRK
			sub y,x							;calcul de la nouvelle taille
			jrc run_il41
			jrz run_il41
			add y,x							;rétablir l'adresse
			mv x,y
run_il41:	rc
			retf
;-------------------------------------------
;
; IL = 5 Calcul adresse de fin de TYCOM.SYS *********************
run_il5:	dec il
			jrnz run_il6					;saut si IL > 6
			mv x,begin-1					;x = adresse de TYDOS.SYS - 1
			rc
			retf
;-------------------------------------------
;
; IL = 6 Modification buffer IOCS Work **************************
run_il6:	dec il
			jrnz run_il7					;saut si IL > 7
			mv x,($e6)						;(E6) = (BFD17) = IOCSWRK
			mv i,$26c						;nouvelle taille du buffer
			add x,i							;calcul de la nouvelle adresse
			rc
			retf
;-------------------------------------------
;
; IL = 7 Se positionner au début de la routine ******************
run_il7:	dec il
			jrnz run_il8					;saut si IL > 8
			mv x,run_il						;adresse début traitement
			rc
			retf
;-------------------------------------------
;
; IL = 8 Traitement erreur **************************************
run_il8:	mv a,$80
			sc
			retf
;-------------------------------------------
;
;			
;-Variables TYDOS ------------------------------------------------------------------
file_buf:	ds 20							;bfb5b
flag:		db 0							;bfb6f
kbd_nxt:	ds 3							;bfb70
stacks:		ds 3							;bfb73
stacku:		ds 3							;bfb76
data:		ds 22							;bfb79
kbd:		ds 92							;bfb8f
ptr_str:	ds 3							;bfbeb, [bfbeb] = bfbeb
ptr_kbd:	ds 3							;bfbee, [bfbee] = bfb8f
ptr_flag:	ds 3							;bfbf1, [bfbf1] = bfb6f
ptr_iocs:	ds 4							;bfbf4, [bfbf4] = callf 0fffe8h
ptr_fcs:	ds 4							;bfbf8, [bfbf8] = callf 0fffe4h
ptr_runil:	ds 4							;bfbfc; [bfbfc] = callf 0bf907h

	pre_off
	end