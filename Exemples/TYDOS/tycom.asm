;---------------------------------------------
;	tycom.asm   for PC-E500s  Ver 1.0
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
src_work:	equ	$00
p_kbd:		equ $01			;adresse
p_kbdend:	equ $04			;adresse
;			equ $07			;valeur 8 bits ou adresse
p_filehdle:	equ $08			;file handle
;			equ $0d			;valeur 8 ou 16 bits
;			equ $0f			;adresse, $0601, $be7b6
;			equ $13			;directory number : 0,1,2,4,8,16; 4 = fin de programme
;			equ $14			;0,1,2
p_flag:		equ $15
stack_u:	equ $18
stack_s:	equ $1b
;			equ $1e
;			equ $1f			;DEL=$0100,TYPE ou MAKE=$0101,REN ou COPY=$0201
token:		equ $21			;'P'=1, 'W'=2, 'N'=4, ' '=0
;
bl:			equ	$d4
bh:			equ	$d5
bx:			equ	$d4
cl:			equ	$d6
ch:			equ	$d7
cx:			equ	$d6
dl:			equ	$d8
dh:			equ	$d9
dx:			equ	$d8
si:			equ	$da
di:			equ	$dd
;
scr:		equ $fd
;-----------------------
;
;- Touches -------------
key_ctrlc:	equ $03
key_basic:	equ $05
key_BS:		equ	$08
key_cce:	equ $0c
key_right:	equ $1c
key_left:	equ	$1d
key_up:		equ $1e
;
;- Mémoire programme ---
bufferkbd1:		equ begin - $473	;0be38dh - 1024 octets
bufferkbd2:		equ begin - $72		;0be78eh - 19 bits
string1:		equ begin - $5e		;0be7a2h - 19 bits 
filename1:		equ begin - $4a		;0be7b6h - 19 bits
adresse1:		equ begin - $36		;0be7cah - 14 bits
filename2:		equ begin - $28		;0be7d8h - 6 bits
filename3:		equ begin - $22		;0be7deh - 14 bits
filename4:		equ begin - $14		;0be7ech - 6 bits
string2:		equ begin - $0e		;0be7f2h - 12 bits	
adresse2:		equ begin - 2		;0be7feh - 2 bits
;
ptr_str:	equ 0bfbebh
ptr_kbd:	equ 0bfbeeh
ptr_flag:	equ 0bfbf1h
ptr_iocs:	equ 0bfbf4h
ptr_fcs:	equ 0bfbf8h
ptr_runil:	equ 0bfbfch
;-----------------------
;
;- Mémoire externe -----
defdrv: 	equ 0bfc7dh
csrx:		equ 0bfc9bh
csry:		equ 0bfc9ch
lcd_width:	equ 0bfc9dh
lcd_heigh:	equ 0bfc9eh
softint:	equ 0bfcbeh
usrwrk:		equ 0bfd1ah
fcs_call:	equ	0fffe4h
iocs_call:	equ	0fffe8h
;-----------------------
;
;==== Fin variables et constantes========================================
;
	org	0be800h
;
	pre_on
;
;=== Main ===============================================================
;- Initialisation de la zone mémoire ------------------------------------
begin:	mv a,($ec)							;lecture de BP
		pushu a								;sauvegarde de BP sur la pile
		mv ($ec),$60						;nouvelle valeur pour BP
		mv (bp+stack_u),u					;sauvegarde de la pile utilisateur
		mv (bp+stack_s),s					;sauvegarde de la pile système
		mv (bp+$13),0						;initialisation
		mvp (bp+p_flag),[ptr_flag]			;$bfb6f
		call endkbd							;calcule la fin de buffer clavier
		mv a, [(bp+p_flag)]					;flag
		test a,1							;
		jrnz _be83f							;saut si ex-tycom.sys déjà exécuté => a=1
		mv y,(bp+p_kbd)						;début adresse buffer clavier
;
;--- Copie de CR + LF dans le buffer clavier ---
_be820:	mv a,CR								;remplissage du buffer avec CR
		mv [y++],a
		cmpp (bp+p_kbdend),y
		jrnc _be820							;boucler jusqu'à la fin du buffer
;
		mv x,tycom_tle						;adresse du titre "tycom.sys"
		call wrtScrn						;affichage de la chaine
_be830:	call close_allfiles					;close all file handle
		mv a,$0b							;flag execution tycom.sys
		mv [(bp+p_flag)+10],a 				;sauvegarde de la valeur
		mv a,1				
_be83b:	mv [(bp+p_flag)+11],a 				;file handle = KEYBD
_be83f:	and (bp+$13),$ef
		mv a,EOF
		call wrtByteScrn					;écriture d'un bit à l'écran
		call OpenSCRN_KYBD					;open SCRN et KYBD
		mv a, [(BP+p_flag)]					;lecture du flag
		test a,1
		jrz _be859							;saut si première exécution
		call fullmark						;affichage curseur
		call cmdline						;affichage invite de commande
		jr check_scrut						;traitement fin de programme
;
_be859:	or a,1								;set le flag tycom = 1
		mv [(BP+p_flag)],a 
		or (BP+13h),10h
		call _bf068							;calcule adresse fin buffer claver
;
;--- recopie texte "AUTOEXEC" ---
		mv x,auto_tle						;adresse du texte de 'AUTOEXEC'		
_be868:	mv a,[x++]							;lire un caractère
		cmp a,0
		jrz _be8c2							;saut si fin de chaine
		mv [y++],a 							;sinon copier la valeur
		jr _be868							;boucler la lecture de la chaine
;
check_scrut:								;_be872
		test (bp+$13),4						
		jrz _be882
		mv a, [(BP+p_flag)]					;lecture flag
		or a,2								;modification du flag
		mv [(BP+p_flag)],a 					;sauvegarde de la nouvelle valeur
		jp exit_tycom						;exit tycom
;---Fin initialisation --------------------------------------------------------		
;
;--- Routines -----------------------------------------------------------------
_be882:	call read_byte						;lecture clavier
		cmp a,0
		jrnz _be895							;saut si valeur sur 2 bits
		call read_byte						;lecture clavier
		cmp a,key_basic						;touche BASIC
		jrnz check_scrut					;saut si différent de BASIC
		or (bp+$13),4
		jr check_scrut						;traitement fin de programme
;
_be895:	cmp a,10							;touche CTRL + P 
		jrz check_scrut						;traitement fin de programme
		cmp a,EOF							;touche CTRL + Z
		jrnz _be8be							;saut si différent de EOF
		mv a,[(bp+p_flag)+10]				;flag d'exécution de tycom
		cmp a,$0b							;touche CTRL + Q
		jrz _be8bc							;saut si égal
		mv x,(bp+p_flag)		
		add x,a
		mv il,[x++]							;lecture file handle
		dec a 								
		mv [(bp+p_flag)+10],a 				;sauvegarde nouveau flag de tycom
		mv (cl),il 							;file handle
		mv il,2								;closing a file
		call fcs_err						;appel FCS-traitement-erreur
		call _bf068							;calcule fin buffer clavier
_be8bc:	jr check_scrut						;traitement fin de programme
;
_be8be:	cmp a,CR
		jrnz _be8c8							;saut si différent de CR
;
_be8c2:										
		call curoff							;effacement curseur
		jp _be970							;traitement saisie clavier
;
_be8c8:	cmp a,key_ctrlc						;touche CTRL + C
		jrz check_scrut						;traitement fin de programme
		cmp a,key_cce						;touche C-CE
		jrnz _be8d8							;saut si différent
		call wrtByteScrn					;write a byte
		call cmdline						;affichage invite de commande
		jr check_scrut						;traitement fin de programme
_be8d8:	cmp a,key_BS						;touche BS
		jrz _be8e0							;saut si égal
		cmp a,key_left						;touche Flèche Gauche
		jrnz _be90e							;saut si différent
_be8e0:	cmpp (bp+p_kbd),y					;saut si fin buffer clavier atteint
		jrz _be912
		dec y
		mv a,[csrx]							;lecture position du curseur
		cmp a,0								;comparaison à l'origine
		jrz _be901							;saut si zéro
		mv il,[lcd_width]
		sub a,il
		mv a,8
		jrnc _be8fe							;saut si curseur > colonne max écran
		call wrtByteScrn					;write a byte
		jr check_scrut						;traitement fin de programme
_be8fe:	call wrtByteScrn					;write a byte
_be901:	call _be931							;idem flèche gauche
		mv a,' '
		call wrtByteScrn					;write a byte
		call _be931							;idem flèche haute
		jr check_scrut						;traitement fin de programme
;
_be90e:	cmp a,1
		jrnz _be921
_be912:	mv a,[y++]
		cmp a,CR
		jrz _be91d
		call wrtByteScrn					;write a byte
		jr _be912
_be91d:	dec y
		jr check_scrut						;traitement fin de programme
_be921:	cmp a,' '
		jrc check_scrut						;traitement fin de programme
		cmpp (bp+p_kbdend),y
		jrz check_scrut						;traitement fin de programme
		mv [y++],a 							;sauvegarde du caractère
		call wrtByteScrn					;write a byte
		jr check_scrut						;traitement fin de programme
;
_be931:	mv a,key_up							;touche 'fleche haute'
		call wrtByteScrn					;write a byte
		mv (bp+7),[lcd_width]
_be93b:	dec (bp+7)
		jrz _be946
		mv a,key_right						;touche 'fleche droite'
		call wrtByteScrn					;write a byte
		jr _be93b
_be946:	ret
;
;--- Lecture entrée ---
read_byte:
		mv a,[(bp+p_flag)+10]
		mv x,(bp+p_flag)
		add x,a
		mv a,[x++]							;a = file handle
_be951:	mv (cl),a							;sauver dans le registre
		mv il,5								;appel de la fonction
		mv a,1								;lecture jusqu'à la fin physique
		jp fcs_err							;appel FCS-traitement-erreur
;
;--- Reading a byte from the keyb ---
_be95b:	
		mv a,1								;file handle clavier
		jr _be951
;
;--- Write a byte on the screen ---
wrtByteScrn:	
		mv il,6								;_be95f
		mv (cl),0							;file handle SCRN
		jp fcs_spl
;
;--- Close a file ---
closeFile:	
		mv (cl),a							;file handle, _be968
		mv il,2								;close a file
		jp test_int
;
_be970:	mv a, [(BP+p_flag)]					;lecture du flag
		and a,$f3							;modification du flag
		mv [(bp+p_flag)],a 					;sauvegarde de la nouvelle valeur
		pushu y								;empiler l'adresse du ptr clavier en cours
;
;--- Copie de CR dans le buffer clavier ---
_be979:	mv a,CR
		mv [y++],a 
		cmpp (bp+p_kbdend),y
		jrnc _be979							;boucler tant que la fin n'est pas atteinte
;
		popu y								;dépiler ptr clavier
		call wrtCRLF						;copie CR + LF
		mv a,[--y]							;se postionner sur le dernier caractère
		cmp a,':'
		jrnz _be9e8							;saut si différent de ':'
		mv x,(bp+p_kbd)						;lire l'adresse du buffer clavier
_be98e:	mv a,[x++]							;lire la valeur
		cmp a,CR							;comparer à CR
		jrz _be99a							;saut si égal
		cmp a,' '+1
		jrc _be9e8							;lecture buffer clavier
		jr _be98e							;sinon boucler
;
_be99a:	mv x,(bp+p_kbd)						;adresse du kybd buffer
		mv y,filename4						;adresse du device par défaut
		mv il,6								;nombre de caractères du device par défaut
_be9a2:	dec il								;décrémenter 
		jrz _be9e8
		mv a,[x++]							;lire la valeur
		mv [y++],a 							;la copier
		cmp a,':'							;marqueur de fin
		jrnz _be9a2							;boucler tant que non lu
		mv a,0								;caractère terminal
		mv [y++],a 							;finir la chaine par un zéro terminal
;
;--- lecture buffer clavier dans tydos.sys ---
		mv x,filename4							
		mv y,filename2
		mv il,2
		callf ptr_runil
;
;--- recherche de fichiers ---
		mv x,filename2						;lead address of file name character string to be searched
		mv il,12							;searching for corresponding file name
		mv a,0								;search for the back of the direction number
		mvw (bx),0							;directory number to start searching
		mv y,filename4						;lead address to return the result
		call fcs_err						;appel FCS-traitement-erreur
		mv x,filename4						;lead address of file name character string	
		mv y,defdrv							;drive name par défaut
		mv il,6								;nombre de caractère du drive name
_be9de:	mv a,[x++]							;lire la valeur
		mv [y++],a							;la recopier
		dec il								;décrémenter le compteur
		jrnz _be9de							;boucler tant que non zéro
		jr _beab2							;jp $be83f
;
;--- lecture buffer clavier dans tydos.sys ---
_be9e8:	mv x,(bp+p_kbd)						;kybd
		mv y,filename4						;lead address of file name character string	
		mv il,2
		callf ptr_runil
		mv [(bp+p_flag)+1],x				;sauver kbd_next
		jrc _beab2							;jp $be83f
		cmp a,0
		jrz _beab2							;jp $be83f
;
;---Recopie chaine ---
		mv x,string2						;adresse de la chaine
		mv y,adresse1
_bea06:	mv a,[x++]							;copie des caractères
		mv [y++],a
		cmp a,0
		jrnz _bea06							;boucler tant que a est différent de zéro
;
		mv (bp+src_work),255				;positionner le flag
		call check_instr					;lecture des instructions
		jrc _bea25
;
;--- Opening a file ---
		mv il,1
		mv a,1
		mv x,filename4						;lead address of file name character string	
		call fcs_err						;appel FCS-traitement-erreur
		mv (bp+src_work),(cl)				;sauvegarde File handle
_bea25:	mvp (bp+7),[(bp+p_flag)+1]
;
;--- Lecture buffer clavier dans tydos.sys ---
_bea2a:	mv x,(bp+7)
		mv il,2
		mv y,filename4						;lead address of file name character string	
		callf ptr_runil
		mv (bp+7),x							;sauvegarde de kbd_next
		jrc _bea76
		cmp a,2
		jrc _bea2a
		cmp a,3
		jrz _bea5c
		mv a,1
		call closeFile
		mv il,1
		mv a,1
		mv x,filename4						;lead address of file name character string	
		call fcs_err						;appel FCS-traitement-erreur
		mv a, [(BP+p_flag)]
		or a,8
		mv [(bp+p_flag)],a
		jr _bea2a
;
;--- Creating a file ---
_bea5c:	mv a,0
		call closeFile						;close file SCRN
		mv il,0
		mv a,0
		mv x,filename4						;lead address of file name character string	
		call fcs_err						;appel FCS-traitement-erreur
		mv a, [(BP+p_flag)]					;lecture du flag
		or a,4								;modification du flag
		mv [(bp+p_flag)],a					;sauvegarde du flag
		jr _bea2a							;boucler lecture buffer clavier
;
_bea76:	call _beae2							;lecture des instructions
		jrc _beab2							;jp $be83f
		mv a,(bp+src_work)
		mv il,1								;lecture fichier tycom.sys
		callf ptr_runil
		cmp a,0
		jrz _beab8
;
		mv (bp+7),x
		mv (bp+15),y
		add y,x
		pushu y
		mv il,4								;calcule buffer IOCS
		callf ptr_runil
		cmpp (bp+7),x
		jrc _beab5
		popu y
		dec y
		mv il,5								;calcule adresse tycom.sys
		callf ptr_runil
		sub x,y
		jrc _beab5
		mv x,(bp+7)
		mv y,(bp+7)
		mv a,(bp+src_work)
		mv il,3								;exécution de tycom.sys
		callf ptr_runil
_beab2:	jp _be83f
_beab5: jp exit_cmd
;
_beab8:	mv (cl),(bp+src_work)
		mvp (si),0
		mv il,9								;moving a file ptr
		mv a,0
		call fcs_err						;appel FCS-traitement-erreur
		mv a,[(bp+p_flag)+10]
		cmp a,15
		jrz _beadf
		mv x,(bp+p_flag)
		inc a
		add x,a 
		mv [(bp+p_flag)+10],a
		mv a,(bp+src_work)
		mv [x],a 
_beadf:	jp _be83f
;
;--- Lecture des instructions ---
_beae2:	or (bp+$13),8						;nombre d'instructions à lire
		call check_instr					;lecture des instructions
		jrnc _beb36
		dec (bp+7)							;décrémenter le compteur
		jrnz _beaf3
		or (bp+$13),4						;instructions BASIC
		jr _beb34
_beaf3:	dec (bp+7)							;décrémenter le compteur
		jrnz _beafc				
		call DIR_instr						;instruction DIR
		jr _beb34
_beafc:	dec (bp+7)							;décrémenter le compteur
		jrnz _beb05
		call COPY_instr						;instruction COPY
		jr _beb34
_beb05:	dec (bp+7)							;décrémenter le compteur
		jrnz _beb0e
		call TYPE_instr						;instruction TYPE
		jr _beb34
_beb0e:	dec (bp+7)							;décrémenter le compteur
		jrnz _beb17
		call DEL_instr						;instruction DEL
		jr _beb34
_beb17:	dec (bp+7)							;décrémenter le compteur
		jrnz _beb20
		call REN_instr						;instruction REN
		jr _beb34
_beb20:	dec (bp+7)							;décrémenter le compteur
		jrnz _beb2b
		mv a,12								;instruction C-CE
		call wrtByteScrn					;write a byte
		jr _beb34
_beb2b:	dec (bp+7)							;décrémenter le compteur
		jrnz _beb34
		call MAKE_instr						;instruction MAKE
		jr _beb34
_beb34:	sc
_beb35:	ret
_beb36: ret
;
;--- comparaison de deux chaines ---
cmp_str:	
		mv (bp+7),0							;init le compteur
_beb3a:	mv x,(bp+15)
		inc (bp+7)							;incrémenter le compteur
_beb3e:	mv a,[y++]							;lire la valeur
		cmp a,'!'
		jrc _beb62							;saut si inférieur
		mv (bp+p_filehdle),a 				;sauver la valeur
		mv a,[x++]							;lire la valeur
		cmp a,'a'
		jrc _beb52							;saut si inférieur
		cmp a,'z'+1
		jrnc _beb52							;saut si supérieur
		sub a,$20							;convertir en majuscule
_beb52:	cmp (bp+p_filehdle),a 				;comparer la valeur
		jrz _beb3e							;boucler si identique
_beb56:	mv a,[y++]							;lire la valeur suivante
		cmp a,' '+1
		jrnc _beb56							;boucler si supérieur
_beb5c:	cmp a,' '
		jrz _beb3a							;boucler tant que SPACE
		sc
		ret
;
_beb62:	mv a,[x++]							;lire la valeur
		cmp a,' '
		jrz _beb6c							;fin si SPACE
		mv a,[y]							;lire la valeur
		jr _beb5c							;boucler sur la lecture
_beb6c:	rc
		ret
;
;--- Lecture des instructions ---
check_instr:								;_beb6e
		mv y,instruct_tle					;adresse des instructions
		mvp (bp+15),adresse1
		call cmp_str
		jrc _beb83
		mv a,(bp+src_work)									
		call closeFile						;close a file
		sc
		ret
_beb83:	rc
		ret
;
check_token:								;_beb85
		mv (bp+token),0
		mv (bp+7),0							;init compteur
_beb8b:	mv x,[(bp+p_flag)+1]				;kbd_next
		mv y,bufferkbd2
		mv il,2								;lecture buffer clavier tydos.sys
		callf ptr_runil
		mv [(bp+p_flag)+1],x
		mv x,bufferkbd2
		jrc _bebd8
		cmp a,0
		jrnz _bebc8
_beba7:	mv a,[x++]							;lire la valeur
		cmp a,' '
		jrz _beb8b							;saut si SPACE
		cmp a,'P'							;option PAUSE
		jrnz _bebb6							;saut si différent
		or (bp+token),1						;flag instruction
		jr _beba7							;saut vers l'exécution
_bebb6:	cmp a,'W'							;option WINDOW
		jrnz _bebbf							;saut si différent
		or (bp+token),2						;flag instruction
		jr _beba7							;saut vers l'exécution
_bebbf:	cmp a,'N'							;option NO
		jrnz _beba7							;saut si différent
		or (bp+token),4						;flag instruction
		jr _beba7							;saut vers l'exécution
;
_bebc8:	cmp a,1
		jrnz _beb8b
		cmp (bp+7),(bp+$20)
		jrz err83							;error $83
		call check_str									
		jrc err84							;error $84
		jr _beb8b							;boucler sur la routine
;
_bebd8:	cmp (bp+7),(bp+$1f)
		jrc err83							;error $83
		jrnz _bebfe
		mv a,(bp+$20)
		sub a,(bp+$1f)
_bebe3:	cmp a,1
		jrnz _bebfe
		mv x, wild2_tle
		mv y,bufferkbd2
		mv il,2								;lecture buffer clavier
		callf ptr_runil
		mv x,bufferkbd2
		call check_str
		jrc err84							;error $84
_bebfe:	rc
		ret
;
;--- Retourne erreur $83 ---
err83:	
		mv a,$83							;_bec00
		sc
		ret
;
;--- Retourne erreur $84 ---
err84:										;_bec04
		mv a,$84
		sc
		ret
;
check_str:									;_bec08
		inc (bp+7)							;incrémenter le compteur
		cmp (bp+7),1
		jrnz _bec15							;saut tant que différent de 1
		mv y,filename1						;traitement pour 1
		jr _bec1e
_bec15:	cmp (bp+7),2			
		jrnz _bec28							;saut si différent de 1 et 2
		mv y,string1						;traitement pour 2
_bec1e:	mv a,[x++]							;lire la valeur
		mv [y++],a							;la copier
		cmp a,0								;comparaison avec zéro terminal
		jrnz _bec1e							;boucler tant que non zéro terminal
		rc
		ret
_bec28:	sc
		ret
;
DIR_instr:									;_bec2a
		mvw (bp+$1f),$0100
		call check_token
		jrc _becc9
		mvw (bp+$0d),0
		mv x,direct_tle						;adresse chaine "directory"
		call wrtScrn						;affichage de la chaine
		mv x,filename1						;adresse de la chaine
		call wrtScrn						;affichage de la chaine
		call wrtCRLF						;copie CR + LF
		mv (bp+$14),2
_bec4b:	call search_file					;search file
		jrc _bec94
		mv x,string2						;adresse de la chaine
		call wrtScrn						;affichage de la chaine
		mv x,filename4						;adresse du nom de fichier lu
		mv a,1
		mv il,1								;opening a file
		call fcs_spl						;call FCS 
		jrnc _bec72							;saut si pas d'erreur
		cmp a,8								;erreur : fichier déjà ouvert
		jpnz exit_cmd
		mv x,wild1_tle						;adresse de la chaine
		call wrtScrn						;copie de la chaine '??????'
		jr _bec80
_bec72:	mv a,(cl)							;copie du file handle
		pushu a 							;sauvegarde de la valeur
		call file_info						;in return y = file size
		call deci_conv
		popu a 								;récupérer le file handle
		call closeFile						;fermer le fichier
_bec80:	test (bp+token),2					;token = 'W'
		jrz _bec89
		inc (bp+$14)
		jr _bec8f
_bec89:	call wrtCRLF						;copie CR + LF
		pmdf (bp+$14),2
_bec8f:	call _beccc
		jr _bec4b							;boucler sur la recherche de fin de fichier
_bec94:	cmp a,10
		jrz _becc9							;saut si le drive n'existe pas
		test (bp+$14),1
		jrz _beca5
		call wrtCRLF						;copie CR + LF
		inc (bp+$14)
		call _beccc
_beca5:	test (bp+token),4					;token = 'N'
		jrnz _becc8
		mv il,15							;reading a free capacity of drive
		mv a,0
		mv x,filename1						;drive name character string
		call fcs_err						;appel FCS-traitement-erreur
		mv y,(si)							;free capacity
		call deci_conv
		mv x,bytes_tle
		call wrtScrn						;affichage de la chaine
		pmdf (bp+$14),2
		call _beccc
_becc8:	ret
;
_becc9:	jp exit_cmd							;le drive n'existe pas
;
_beccc:	test (bp+token),1					;token = 'P' ?
		jrz _becec
		mv a, [(BP+p_flag)]					;lecture flag
		test a,12
		jrnz _becec
		mv a,[lcd_heigh]					;par défaut, valeur 4
		rol a								;a = 8
		cmp (bp+$14),a
		jrnz _becec
		call read_byte						;lecture clavier
		mv a,12								;C-CE
		call wrtByteScrn					;efface l'écran
		mv (bp+$14),0
_becec:	ret
;
;--- Searching for corresponding file name ---
search_file:								;_beced
		mvw (bx),(bp+13)					;directory number
		mv il,12
		mv a,0								;search for the back of the directory number
		mv x,filename1						;lead address of file name to be searched
		mv y,filename4						;lead address to return the result
		call fcs_spl						;call FCS
		jrc _bed11							;saut si erreur
		mv i,(bx)							;directory number of the file detected
		inc i								;incrémenter la valeur
		mv (bp+13),i						;et la sauver
		mv x,adresse2
		and (bp+$13),$f7
		ret
_bed11:	test (bp+$13),8
		jrz _bed18
		mv a,10
_bed18:	ret
;
_bed19:	mv x,filename4						;adresse de la chaine
		call wrtScrn						;affichage de la chaine
		jp wrtCRLF
;
_bed23:	mv x,string1
		mvp (bp+15),filename4				;save address name before renaming
		mv y,filename2
_bed30:	mv a,[x++]
		pushu x
		mv x,(bp+15)						;lire l'adresse
		mv (bp+p_filehdle),[x++]			;sauver la caractère
		mv (bp+15),x						;sauver la nouvelle adresse
		popu x
		cmp a,'?'
		jrnz _bed44
		mv [y++],(bp+p_filehdle)
		jr _bed30
_bed44:	mv [y++],a							;copier le caractère
		cmp a,0
		jrnz _bed30							;boucler tant que non fin de chaine
		ret
;
file_info:
		mv il,10							;reading various information of a file
		mv (cl),a 							;file handle
		mv a,0								;reading of file size, ptr value
		call fcs_err						;appel FCS-traitement-erreur
		mv y,(di)							;file size
		ret
;
deci_conv:
		mv (bp+7),y							;sauvegarde de la valeur à afficher
		mv a,' '
		call wrtByteScrn					;write a space
		mv x,data1							;codes de conversion
		mvw (bp+15),$0601					;6 valeurs à lire
_bed68:	mv y,[x++]
		pushu x
		mv x,(bp+7)
		mv a,255
_bed6f:	inc a
		sub x,y
		jrnc _bed6f
		add x,y
		mv (bp+7),x
		popu x
		cmp a,0
		jrnz _bed83
		cmp (bp+15),1
		jrz _bed91
_bed83:	add a,'0'							;conversion ASCII
		call wrtByteScrn					;write a byte
		mv (bp+15),0
		dec (bp+16)
		jrnz _bed68
		jr _beda1
_bed91:	dec (bp+16)
		jrz _bed9c
		mv a,' '
		call wrtByteScrn					;write a space
		jr _bed68
_bed9c:	mv a,'0'							;conversion ASCII
		call wrtByteScrn					;write a byte
_beda1:	mv a,' '
		call wrtByteScrn					;write a space
		ret
;
;--- Zone de données ---_beda7
data1:	dp 100000,10000,1000,100,10,1
;
;--- Instruction TYPE ---
TYPE_instr:									;_bedb9
		mvw (bp+$1f),$0101
		call check_token
		jrc _bee30
		mv x,filename1						;lead address of file name character string
		mv a,1								;physical end of file
		mv il,1								;opening a file
		call fcs_err						;appel FCS-traitement-erreur
		mv (bp+7),(cl)						;sauvegarde file handle
		call _bee33
		mv (bp+$1e),a 
		mv a,(bp+7)							;lecture file handle
		call file_info						;lecture file size
		inc y
_beddd:	call _bee3f
		dec y
		jrz _bee2b
		mv a,(bp+7)							;lecture file handle
		call _be951							;read byte
		ex a,b
		cmp a,0
		jrz _beddd
		ex a,b
		cmp a,LF
		jrz _beddd
		pushu a 
		call wrtByteScrn					;write a byte
		popu a 
		cmp a,CR
		jrnz _bee01
		mv a,LF
		call wrtByteScrn					;write a byte
_bee01:	mv il,8								;non destructing reading a file
		mv (cl),1							;file handle = clavier
		mv a,1								;physical end of file
		call fcs_err						;appel FCS-traitement-erreur
		ex a,b								;nombre de bits lus
		cmp a,0
		jrz _bee29							;saut si erreur
		ex a,b								;caractère lu
		call read_byte						;lecture clavier
		cmp a,$13
		jrz _bee22
		cmp a,3								;touche CTRL + C
		jrnz _bee29
		call wrtCRLF						;copie CR + LF
		jr _bee2b
_bee22:	call read_byte						;lecture clavier
		cmp a,$11							;touche CTRL + Q
		jrnz _bee22
_bee29:	jr _beddd
_bee2b:	mv a,(bp+7)
		jp closeFile
_bee30:	jp exit_cmd
;
_bee33:	mv a,[($e6)+8]
		mv il,[csry]
		add a,il
		ret
;
_bee3f:	mv a, [(BP+p_flag)]					;lecture flag
		test a,12
		jrnz _bee62
		test (bp+token),1
		jrz _bee62
		call _bee33
		sub a,(bp+$1e)
		jrnc _bee56
		jrz _bee62
		add a,8
_bee56:	cmp a,3
		jrc _bee62
		call _bee33
		mv (bp+$1e),a
		call read_byte						;lecture clavier
_bee62:	ret
;
;--- Instruction REN ---
REN_instr:									;_bee63
		mvw (bp+$1f),$0201
		call check_token					;lecture des options de la ligne de commande
		jrc _bee8c							;saut si erreur
		mvw (bp+13),0
_bee70:
		call search_file					;search file
		jrc _bee87							;saut si erreur
		call _bed23
		mv x,filename4						;lead address of file name character string before renaming
		mv y,filename3						;lead address of file name character string after renaming
		mv il,13							;rename file
		call fcs_err						;appel FCS-traitement-erreur
		jr _bee70
_bee87:	cmp a,10							;drive doesn't exist
		jrz _bee8c
		ret
_bee8c:	jp exit_cmd							;traitement-erreur

;--- Instruction COPY ---
COPY_instr: 								;_bee8f
		call closeSCRN_KYBD					;close SCRN et KYBD
		mvw (bp+$1f),$0201
		call check_token
		jrc _bef7d
		mvw (bp+13),0						;init flag
		and (bp+$13),$fc
		mv y,device1_tle					;adresse des devices
		mvp (bp+15),filename1				;sauvegarde nom fichier
		call cmp_str						;recherche du device
		jrc _beeb3
		or (bp+$13),2
_beeb3:	mv y,device1_tle
		mvp (bp+15),string1
		call cmp_str
		jrc _beec4
		or (bp+$13),1
_beec4:	call search_file					;search file
		jrc _bef76							;saut si erreur
		mv x,filename4						;lead address of file name character string			
		mv a,1								;reading-out
		mv il,1								;opening a file
		call fcs_err						;appel FCS-traitement-erreur
		mv (bp+7),(cl)						;sauvegarde file handle
		call _bed23
		mv x,filename2						;lead address of file name character string	
		mv a,0								;write protect
		mv il,0								;creating a file
		call fcs_err
		mv (bp+p_filehdle),(cl)				;sauvegarde du file handle
		test (bp+$13),2
		jrz _bef05				
_beeef:	mv a,(bp+7)							;lecture file handle
		call _be951							;lecture sur fichier
		pushu a 
		mv (cl),(bp+p_filehdle)				;lecture du file handle
		mv il,6								;writing a byte in the file
		call fcs_err						;appel FCS-traitement-erreur
		popu a 
		cmp a,EOF
		jrnz _beeef
		jr _bef7a
_bef05:	mv a,(bp+7)							;lecture du file handle
		call file_info
		inc y								;file size
		dec y
		jrz _bef2f							;saut si taille nulle
		mv (bp+15),y						;sauvegarde du file size
		test (bp+$13),1
		jrz _bef35							;copie par bloc
_bef17:	mv a,(bp+7)							;lecture du file handle
		call _be951							;lecture sur fichier
_bef1c:	pushu a 
		mv (cl),(bp+p_filehdle)				;copie du file handle
		mv il,6								;writing a byte
		call fcs_err						;appel FCS-traitement-erreur
		popu a 
		cmp a,EOF
		jrz _bef33							;saut si fin de fichier
		dec y
_bef2d:	jrnz _bef17
_bef2f:	mv a,EOF
		jr _bef1c
_bef33:	jr _beec4
;
_bef35:	mv x,bufferkbd1						;lead address to which data is transfered
		mv y,$00401							;1025 octets
		cmpp (bp+15),y						;comparer la taille de fichiers
		jrnc _bef44							;au max file size est 1025 octets
		mv y,(bp+15)						;number of bytes to be read
_bef44:	mv il,3								;reading a block of the file
		mv (cl),(bp+7)						;file handle
		mv a,1								;physical end of file
		call fcs_err						;appel FCS-traitement-erreur
		mv x,(bp+15)						
		sub x,y
		mv (bp+15),x						;number of bytes to be written
		mv il,4								;writing a block of the file
		mv (cl),(bp+p_filehdle)				;file handle
		mv x,bufferkbd1						;lead address of data
		call fcs_err						;appel FCS-traitement-erreur
		mv x,(bp+15)						;nombre de bits
		inc x
		dec x
		jrnz _bef35
		mv a,(bp+7)							;file handle
		call closeFile						;close a file
		mv a,(bp+p_filehdle)				;file handle
		call closeFile						;close a file
		jr _beec4
;
_bef76:	cmp a,10
		jrz _bef7d
_bef7a:	jp OpenSCRN_KYBD
_bef7d:	jp exit_cmd
;
;--- Instruction MAKE ---
MAKE_instr:									;_bef80
		mvw (bp+$1f),$0101
		call check_token
		jrc _befcd							;saut si erreur
		mv (bp+7),255
		mv x,filename1						;lead address of file name character string
		mv a,0								;physical end of file
		mv il,0								;creating a file
		call fcs_err						;appel FCS-traitement-erreur
		mv (bp+7),(cl)						;sauver file handle
_bef9b:	call read_byte						;lecture clavier
		jrc _befc8
		cmp a,EOF
		jrz _befc8							;saut si fin de fichier
		cmp a,0
		jrnz _befaf
		call read_byte						;lecture clavier
		jrc _befc8
		jr _bef9b
;
_befaf:	cmp a,CR
		jrz _befba
		call _befd9
		jrc _befcd
		jr _bef9b
_befba:	call _befd9
		jrc _befcd
		mv a,LF
		call _befd9
		jrc _befcd
		jr _bef9b
_befc8:	call _befd9
		jr _befd0							;closing file
_befcd:	jp exit_cmd
_befd0:	mv (cl),(bp+7)						;file handle
		mv il,2								;closing a file
		jp fcs_err							;appel FCS-traitement-erreur
;
_befd9:	pushu a 
		call wrtByteScrn					;write a byte
		popu a 
		mv (cl),(bp+7)						;lecture file handle
		mv il,6								;writing a file
		jp fcs_err							;appel FCS-traitement-erreur
;
;--- Instruction DEL ---
DEL_instr:									;_befe7
		mvw (bp+$1f),$0100
		call check_token
		jrc _bf02e
		mvw (bp+13),0
_beff4:	call search_file					;search file
		jrc _bf029							;saut si erreur
		call _bed19							;affichage chaine
		test (bp+token),4					;token='N'
		jrnz _bf01e
		mv a, [(BP+p_flag)]					;lecture flag
		test a,12
		jrnz _bf01e
		mv x,data2							;adresse 'delete ok'
		call wrtScrn						;affichage de la chaine
		call read_byte						;lecture clavier
		cmp a,CR
		jrz _bf01e							;saut si ok
		cmp a,'Y'
		jrz _bf01e							;saut si ok
		cmp a,'y'
		jrnz _beff4							;lecture fichier suivant
_bf01e:	mv il,14							;deleting a file
		mv x,filename4						;lead address of file name character string	
		call fcs_err						;appel FCS-traitement-erreur
		jr _beff4
_bf029:	cmp a,10							;le drive n'existe pas
		jrz _bf02e
		ret
_bf02e:	jp exit_cmd
;
;--- Data ---_bf031
data2:	db 'delete OK(OK:',$27,'Y',$27,'or',$27,'CR',$27,')?',CR,LF,0
;
;--- Copie d'une chaine avec zéro terminal ---
wrtScrn: 									;_bf04c
		mv a,[x++]
		cmp a,0
		jrz _bf057
		call wrtByteScrn					;write a byte
		jr wrtScrn
_bf057:	ret
;
;--- Calcul adresse fin de buffer clavier ---
endkbd:										;_bf058
		mvp (bp+p_kbd),[ptr_kbd]			;copie adresse ptr claver
		mv x,[ptr_str]						;copie adresse de la chaine
		dec x
		dec x								;se positionner deux adresses avant la fin de buffer
		mv (bp+p_kbdend),x					;sauver l'adresse
		ret
;
;
_bf068:	call endkbd
		mv a,[(bp+p_flag)+10]
		cmp a,11
		jrz _bf083							;saut si appel depuis tycom.sys
		mv y,(bp+stack_u)					;adresse pile utilisateur
		dec y
		dec y										
		mv (bp+p_kbdend),y					;sauvegarde de l'adresse fin buffer clavier
		mv a,$80							;256 octets
		sub y,a 							;calcule nouvelle adresse keyb
		mv (bp+p_kbd),y						;sauvegarde de l'adresse
		mv u,y								;nouvelle valeur de la pile utilisateur
_bf083:	mv y,(bp+p_kbd)
		ret
;
;--- Affichage invite de commande ---
cmdline:									;_bf086
		call _bf068
		call _bf14d							;lecture présence curseur
		mv x,defdrv							;drive par défaut
_bf090:	mv a,[x++]							;lecture de la valeur	
		cmp a,':'
		jrz _bf09b							;saut si ':'
		call wrtByteScrn					;write a byte
		jr _bf090							;boucler sur la lecture des valeurs
_bf09b:	mv a,'>'							;charger la valeur à afficher
		jp wrtByteScrn						;write a byte
;
;--- Exit tycom.sys ---
exit_tycom:									;_bf0a0
		mv u,(bp+stack_u)					;rétablir la pile utilisateur
		mv s,(bp+stack_s)					;rétablir la pile système
		call wrtCRLF						;copie CR + LF
		call curoff							;effacement curseur
		popu a 								;dépiler BP
		mv ($ec),a							;rétablir la valeur de BP
		or ($ea),8
		rc
		retf
;
;--- Appel FCS avec traitement des erreurs ---
fcs_err:	
		callf ptr_fcs						;_bf0b4
		jpc exit_cmd						;traitement des erreurs
		ret
;
;--- Appel FCS simple ---
fcs_spl:
		callf ptr_fcs						;_bf0bc
		ret
;--------------------------
test_int:									;_bf0c1:	
		test [softint],$80
		jrnz test_int
		and ($ea),$f7
		callf ptr_fcs
		or ($ea),8
		ret
;--------------------------
;
;--- Affichage du curseur ---
fullmark:									;_bf0d5
		mv a,$8a							;full mark cursor
		jr _bf0db							;traitement
;
curoff:										;_bf0d9
		mv a,0								;le curseur n'est pas affiché
_bf0db:	mvw (cx),0							;file handle SCRN
		mv il,$45							;fixe le type de cuseur
		callf ptr_iocs
		ret
;
close_allfiles:								;_bf0e7
		mv (bp+7),15						;fixe le compteur
_be0ea:	mv a,(bp+7)							;transfert dans a
		call closeFile
		dec (bp+7)							;décrémenter le compteur
		cmp (bp+7),1
		jrnz _be0ea							;boucler tant que supérieur à zéro
		ret
;
;--- close the files SCRN et KYBD ---
closeSCRN_KYBD:	
		mv a,0								;file handle SCRN, _bf0f7
		call closeFile						;close the SCRN
		mv a,1								;file handle KYBD
		jp closeFile						;close the KYBD
;
;--- Open the files SCRN et KYBD ---
OpenSCRN_KYBD:	
		call closeSCRN_KYBD					;close the files SCRN et KYBD, _bf101
		mv il,1
		mv a,2								;open the SCRN
		mv x,scrn_tle
		call test_int
		mv il,1
		mv a,1								;open the KYBD
		mv x,keybd_tle
		jp test_int
;
exit_cmd:	
		call OpenSCRN_KYBD					;open SCRN et KYBD
		mv u,(bp+stack_u)					;rétablir la pile utilisateur
		mv s,(bp+stack_s)					;rétablir la pile système
		call _bf14d
		test (bp+$13),16
		jpnz _be830
		mv x,error_tle						;message d'erreur
		mv y,7								;nombre de caractères
		mv il,4								;write a block of the file
		mv (cl),0							;file handle SCRN
		call test_int						;écriture du message
		jp _be830							;boucler en début de programme
;
;--- Ecriture CR + LF ---
wrtCRLF:	
		test (bp+$13),16					;_bf13e
		jrnz _bf154
		mv a,CR
		call wrtByteScrn					;write a byte
		mv a,LF
		jp wrtByteScrn						;write a byte
;
_bf14d:	test [csrx],255
		jrnz wrtCRLF
_bf154:	ret
;	
;--- Zone des variables -------------------------------------------------
tycom_tle:		db 'TY-COM V1.11 '								;_bf155
btmtycomtle:	
cmdline_tle:	db 'command line processor',CR,LF,0				;_bf162
instruct_tle:	db 'BASIC DIR COPY TYPE DEL REN CLS MAKE',0		;_bf17b
device1_tle: 	db 'COM: CAS: KYBD:',0							;_bf1a0
wild1_tle:		db ' ?????? ',0									;_bf1b0
scrn_tle: 		db 'SCRN:',0									;_bf1b9
keybd_tle:		db 'KYBD:',0									;_bf1bf
wild2_tle:		db '*.* '										;_bf1c5
auto_tle:   	db 'AUTOEXEC',0									;_bf1c9
error_tle:		db 'error',CR,LF								;_bf1d2
bytes_tle:		db 'bytes free',CR,LF,0							;_bf1d9
direct_tle:		db 'directory=',0								;_bf1e6
;--- Fin zone des variables ---------------------------------------------
;
	pre_off
	end
