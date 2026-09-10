;---------------------------------------------
;	TRDOSJEF141222   for PC-E500s  Ver 2.0
;	Jean-François Albouy	15/12/2022
;---------------------------------------------
;
;--- Constantes ---------------
;-Mémoire interne --- 
bl:			equ	0d4h
bh:			equ	0d5h
cl:			equ	0d6h
ch:			equ	0d7h
dl:			equ	0d8h
dh:			equ	0d9h
cx: 		equ 0d6h
si:			equ	0dah
bp: 		equ 0ech
;
buffer:		equ 0
flagInstal:	equ 9
blockAdr:	equ 10
lstblocAdr:	equ 13
freeSpace:	equ 16
;--------------------
;
;-Utilisation --- 
keyb: 		equ 0a0h				;key data check (CTRL+Z)
;
;- Mémoire externe --
s2_top:		equ	0bfc0fh		;top  of "S2:"
s2_siz:		equ	0bfc12h		;size of "S2:"
s1_top:		equ	0bfc15h		;top  of "S1:"
s1_siz:		equ	0bfc18h		;size of "S1:"
s1_btm:		equ	0bfcdeh		;bottom of "S1:"
d_link:		equ	0bfca2h		;device link pointer
baswrk:		equ	0bfd0eh		;BASIC WORK Address
keyvct:		equ	0bfccch		;key interrupt vector
height:		equ 0bfc9eh
defdrv:		equ 0bfc7dh
fcs_call:	equ	0fffe4h
iocs_call:	equ	0fffe8h
usrwrk:		equ 0bfd1ah
reset:		equ 0ffffdh		;jump to MENU
;
KOL:		equ 0f0h
KOH:		equ 0f1h
txtbas:		equ 0cbh
datbas:		equ 0ceh
;--------------------
;-----------------------------
;
;
		org	0be000h
;
		pre_on
;
;-----------------------------------------------------------
;       DEVICE-DRIVER INSTALLER
;-----------------------------------------------------------
; Affichage du titre ---
affTitle:
		callf init_lcd				;init LCD driver ~ cls
		mv	x,msg0					;DISPLAY *TITLE* MESSAGE
		callf print					;affichage du message
;
; Recherche du drive name ---
		mv il,0						;création de fichier
		mv x,dvname					;adresse de DOS:TRDOS:
		callf iocs_call				;appel de la fonction
		jpnc exit2					;saut si déjà installé
;
; Lecture de l'entrée de IOCS ---
		mv (cx),0					;CL = device number, CH = drive number
		mv x,[d_link]				;lecture du IOCS header
		inc x
link1:	dec x
		mv a,[x+3]					;lecture du device number
		cmp (cx),a					;comparaison à la valeur recherchée
		jrnc link2					;saut si inférieur à zéro
		mv (cx),a 					;sinon copie de la valeur lue
link2:	mv x,[x]					;lecture du prochain IOCS header
		inc x						;incrémentation pour check fin de parcours
		jrnz link1					;boucler tant que la fin n'est pas atteinte
		inc (cx)					;incrémentation du device number
		mv [drvNumber],(cx)			;stockage de la valeur pour ce nouveau programme
;
;Condense la mémoire S1: ---
		mvw	(cx),6					;compress the space in each memory block of "S1:"
		mv	il,47h					;lancement de la procédure
		callf iocs_call				;compress memory
;
;Verifie l'emplacement d'installation
		mv	x,[s1_top]				;top of "S1:"
		mv	y,[x+18]				;data block or lead address, pointe sur FB ou FF
		add	x,y						;pointer sur le début du block
		mv	(blockAdr),x			;sauvegarde de l'adresse du début du bloc
loop1:	mv	a,[x]					;SEARCH  end of 'device driver'
		cmp	a,0fbh					;lecture de l'identification du nom de block
		jrnz	chksize				;saut si fin de lecture des blocks
		mv	a,[x+12]				;lecture de l'attribut du driver: $25 (Protected)
		test	a,12				;check ATTR (Device & Protect)
		jrz loop2
		mv	y,[x+17]				;lire la longueur du block jusqu'au prochain bloc
		add	x,y						;se positionner sur le début du prochain bloc
		jr loop1
loop2:	mv (blockAdr),x 
loop3:	mv a,[x]
		cmp	a,0fbh					;lecture de l'identification du nom de block
		jrnz	chksize				;saut si fin de lecture des blocks
		mv y,[x+17]
		add x,y
		jr loop3
;	
chksize: mv	(lstblocAdr),x			;sauvegarde de l'adresse du dernier bloc
		mv	y,[s1_btm]				;end of "S1:" + 1
		dec y
		sub	y,x						;calcul de la mémoire disponible
		mv	(freeSpace),y			;sauvegarde de la taille de la mémoire restante
		mv y,block_bottom-block_top
		cmpp (freeSpace),y
		jrc	exit1					;"ERROR: NOT enough memory!!"
;
;Réallocation des adresses avant copie du nouveau driver
		mv	x,modify_table			;se positionner sur la table des vecteurs
init_3:	mv	y,[x++]					;lire une adresse dans la table	
		inc	y						;-1 indique la fin de la table sinon adresse réelle à modifier
		jrz	modify_end				;saut si fin de table
		pushu	x					;sauvegarde de l'indice prochain dans la table
		mv	x,[y]					;lire l'adresse à modifier
		pushu y						;sauvegarde de l'adresse lue dans la table
		mv	y,block_top				;se positionner sur le début du nouveau header driver
		sub	x,y						;nombre d'octets de décalage
		mv	y,(blockAdr)			;récupérer l'adresse de début du programme	
		add	x,y						;calcul de la nouvelle adresse fonction de son implantation
		popu y						;
		mv	[y],x					;implantation de l'adresse recalculée
		popu x						;se positionner sur l'indice suivant
		jr	init_3					;boucler tant que non fin de table
;
modify_end:
		mv x,[d_link]
		mv [adrs],x
		mv	x,(lstblocAdr)			;adresse du dernier block header
		mv	y,(blockAdr)			;adresse du premier IOCS header
		sub	x,y						;longueur du bloc à déplacer
		mv	(si),x					;sauvegarde de la taille
		mv	x,y						;adresse source
		mv	i,block_bottom - block_top	;taille du driver
		add	y,i						;adresse de destination
		mvw	(cx),6					;transfert de bloc
		mv	il,43h					;appel de la fonction
		callf	iocs_call			;x et y sont incrémentés de 1
		mvp	(si),block_bottom-block_top	;taille du driver
		mv	y,(blockAdr)				;adresse source du IOCS header
		mv	x,block_top				;adresse du header du nouveau bloc
		mvw	(cx),6					;transfert du bloc driver
		mv il,43h					;appel de la fonction
		callf	iocs_call			;appel de la fonction
		mv	x,(blockAdr)			;adresse source du IOCS header
		mv	il,22h
		add	x,il					;adresse source du IOCS header
		mv	[d_link],x				;modification de l'adresse
		callf init_lcd
;		
		cmp (flagInstal),1
		jrz exit
;		
		mv x,msg1					;programme installé
		jr exit4
;		
exit:	mv x,msg1+70				;ms2 = BE24A ?			
		jr exit4
;		
exit1:	cmp (flagInstal),1
		jrz exit2
;		
		mv x,msg3					;not enough memory
		jr exit4	
;		
exit2:	mv x,msg1+85
		jr exit4
;		
		cmp (flagInstal),1
		jrz exit3
;		
		mv x,msg2					;BE224, programme déjà installé
		jr exit4
;		
exit3:	mv x,msg1+105				;BE26D
exit4:	callf print					;BE2BF
;
remake_slot:
		mv	x,[baswrk]				;BASIC WORK Address
		mv	a,[x+114]
		cmp	a,0						;BTEXT$ is "S1:" ????
		jrnz	remake_data
;
remake_text:
		mv	y,115
		add	y,x						;BTEXT$ Address
		pushu	y
		mv	x,[s1_top]				;top of "S1:"
		mv	y,[x+18]
		add	x,y
		popu y
text1:	mv	a,[x]					;SEARCH  block 'TEXT.BAS'
		cmp	a,0fbh
		jrnz txtError
		mv	il,11
		pushu	y
		pushu	x
		inc	x
		callf	stricmp				;BE2A5
		popu	x
		jrz	text2
		mv	y,[x+17]
		add	x,y						;next block
		popu y
		jr	text1
text2:	popu y
		mv	(txtbas),x				;set "TEXT.BAS"  Address
;
remake_data:
		mv	x,[baswrk]				;BASIC WORK Address
		mv	a,[x+126]
		cmp	a,0						;BDATA$ is "S2:" ????
		jrnz remake_end				;BE1AB
;
		mv	y,127					;BDATA$ Address
		add	y,x
		pushu	y
		mv	x,[s1_top]				;top of "S1:"
		mv	y,[x+18]
		add	x,y
		popu y
data1:	mv	a,[x]					;SEARCH  block 'DATA.BAS'
		cmp	a,0fbh
		jrnz	txtError			;BE1AD
		mv	il,11
		pushu	y
		pushu	x
		inc	x
		callf	stricmp				;BE2A5
		popu	x
		jrz	data2					;BE1A7
		mv	y,[x+17]
		add	x,y						;next block
		popu	y
		jr	data1
data2:	popu	y
		mv	(datbas),x				;set "DATA.BAS"  Address
remake_end:
		rc
		retf
;
txtError:	
		cmp (flagInstal),01
		jrz kw2
		mv x,msg4				;BE1BD, push any key
		jr kw3
kw2:	mv x,init_lcd				
kw3:	callf print				;BE2BF
		pushu	imr
;
keywait:	
		mv	(KOL),$ff			;KEY WAIT   until any key
		and	(KOH),$f8			;111110000b
		nop
		nop
		mv	a,($f2)				;11110010b
		cmp	a,$00				;no key ??
		jrz	keywait
		mv	(KOL),$00
		and	(KOH),$f8			;11111000b
		popu	imr
;
		mv	x,[reset]			;jmp to MENU
		jp	x
;
;-----------------------------------------------------------------------------------
;ZONE DES MESSAGES
msg0:	db	'TR-DOS V0.33 by T.Kobayashi(Ryu)',13,10
btm0:
msg1:	db	'Installed.',13,10
btm1:
msg3:	db	'Not enough memory.',13,10
btm3:
msg2:	db	'already exist.',13,10
btm2:
msg4:	db	'--- PUSH ANY KEY ---',13,10
btm4:	
;
msg5:	
	db $8F, $ED, $92, $93, $82, $B5, $82, $DC, $82, $B5, $82, $BD, $2E, $0D, $0A
	db $83, $81, $83, $82, $83, $8A, $82, $AA, $91, $AB, $82, $E8, $82, $DC, $82, $B9, $82, $F1, $0D, $0A
	db $8A, $F9, $82, $C9, $8F, $ED, $92, $93, $82, $B5, $82, $C4, $82, $A2, $82, $DC, $82, $B7, $0D, $0A
	db $2D, $2D, $2D, $20, $89, $BD, $82, $A9, $83, $4C, $81, $5B, $82, $F0, $89, $9F, $82
	db $82, $B5, $C4, $82, $AD, $82, $BE, $82, $B3, $82, $A2, $20, $2D, $2D, $2D, $0D, $0A
;
ckm: db $0D, $00
;-----------------------------------------------------------------------------------
;
;
;--------------------------------------------------
; Comparaison de deux chaines de caractères
;
; il : longueur de la chaine
;  x : adresse de la chaine 1
;  y : adresse de la chaine 2
;--------------------------------------------------
;
stricmp:
		mv	(buffer),[x++]				;stockage du caractère en mémoire interne
		mv	a,[y++]
		cmp	(buffer),0					;vérification fin de chaine par zéro
		jrz	stricmp1					;saut si fin de chaine	
		cmp	(buffer),a					;comparaison des caractères
		jrnz stricmp2					;retour si différent
		dec	il							;décrémenter le compteur
		jrnz stricmp					;boucler sur le traitement
		retf
stricmp1:
		cmp	(buffer),a			;stocker le zéro terminal
stricmp2:
		retf
;
;--------------------------------------------------
; Affichage d'une chaine de caractères
;
;  x : adresse de la chaine à afficher
;  y : nombre de caractères
;--------------------------------------------------
;
print:	pushu x							;stockage de l'adresse
		mv y,0							;compteur à zéro
print1:	inc y							;incrémenter le compteur
		mv a,[x++]						;lecture du caractère
		cmp a,$0a						;checke fin de chaine
		jrnz print1						;boucler sur tous les caractères
		popu x							;récupérer l'adresse de la chaine
		mvw (cx),0						;cl = file handle
		mv il,4							;afficher la chaine
		callf fcs_call
		retf
;
;--------------------------------------------------
;				Format processing 
;
;Card is initialized in RAM file
;Format is called out with INIT in BASIC program
;--------------------------------------------------
;
init_lcd:
		mv il,$3f						;commande Format
		mvw (cx),0						;cl = file handle
		mv x,ckm						;adresse de la chaine CR + LF
		callf iocs_call					;Reset
		mv a,[s-7]						;empiler
		cmp a,$0c						;checke erreur
		jrnc lcd1						;saut si pas d'erreur
		mv (flagInstal),01				;flag = 1 si erreur
		retf
lcd1:	mv (flagInstal),00				;flag = 0 si non erreur
		retf
;
;-----------------------------------------------------------
;       DEVICE-DRIVER
;-----------------------------------------------------------
block_top:
			db	0fbh,'TR-DOS  SYS'			;block name
			db	25h							;block attr
			dw	0,0							;date,time
			dp	block_bottom - block_top	;block size
			dw	0
			dp	block_bottom - block_top	;file size
			dp	block_bottom - block_top	;block size
			dp	0,0
header:		dp	0
drvNumber:	db	11
p0:
attr:		db	063h
adrs:		dp	iocs_entry
dvname:		db	'DOS:TRDOS:',0
;-----------------------------------------------------------
;
p51:	test [flag],1
		jrnz _0be3ae
p48:	mv [oldbp],($ec)		;_be335
		pushu x
		pushu y
		pushu i
		pushu ba
p1:		mv [stacks],s
p2:		mv [stacku],u 
p3:		and [flag],0
		mv a,4
		mv [height],a 
p44:	mv x,drvNames
		mv y,defdrv
		mv il,6
_be35c:	mv a,[x++]
		mv [y++],a 
		dec il 
		jrnz _be35c
;
		mv a,1
		mv il,$10
		callf fcs_call
		mv (cx),2
		mv il,2
		callf fcs_call
p4:
_be376:	mv x,modify_table
		mv y,$bfbeb
		mvp (si),$15
		mv (cx),6
		mv il,$43
		callf iocs_call
p5:		test [flag],2
		jrnz _be3d9
;
p6:		test [flag],1
		jrnz _0be3ae
;
p7:		mv x,title
		mv y,$28
		mv (cx),0
		mv il,4
		callf fcs_call
p8:
_0be3ae: 
		mv x,_be6f4
p9:		mv  y,_be6a0
		pushu y
p10:	callf _be522
		popu x
		mv a,1
		mv il,1
		callf fcs_call
		jrc _be3d9
;
		mv a,(cx)
		pushu a 
p11:	callf checkFile
		jrc _be3d9
;
		cmp a,0
		jrz _be3d9
		popu a 
p12:	callf readBlock
_be3d9:	mv a,1
		mv il,$10
		callf fcs_call
p45:	callf cpyDRV
p13:	mv s,[stacks]
p14:	mv u,[stacku]
		popu ba
		popu i 
		popu y
		popu x
p49:	mv ($ec),[oldbp]			;_be3f1
		rc
		retf
;
cpyDRV: mv x,defdrv
p46:	mv y,drvNames
		mv il,6
_be403:	mv a,[x++]
		mv [y++],a
		dec il
		jrnz _be403
p47:	and [flag],0
		retf
;			
iocs_entry:
		pushu ba
		mv ba,$40
		sub i,ba
		popu ba
		jrc p51
		jrz cpyDRV
entry1:	dec il
		jrz checkFile
		dec il
		jrz _be522
		dec il
		jrz readBlock
		dec il
		jrz _be4f9
		dec il
		jrz _be4ff
		dec il
		jrz _be4f9
		dec il
		jrz _be505
		dec il
		jrz _be3d9
		dec il
		jrz _be50b
		dec il
		jrz _be510
		dec il
		jrz _be516
		dec il
		jrz _be51c
		mv a,$80
		sc
		retf
;
;--------------------------------------------------
;				Verifying a file
;
;cl = file handle
;x = lead address to be verified
;y = nb bytes to be verified
;--------------------------------------------------
;
checkFile:	
		pushu a		
		mv (cx),a					;file handle
		mv a,1						;physical end of file
p15:	mv x,fileHeader				;header to be verified
		mv y,5						;5 bytes to read
		mv il,7						;check file
		callf fcs_call
;
		jrnc _be485					;jump if no carry	
		cmp a,0ch					;lecture bit insuffisant
		jrz _be46e					;retour si correspondance	
		cmp a,0bh					;error in data verification
		jrnz _be4ae					;set carry and return
;
		;moving a file pointer
_be46e:	popu a
		mv (cx),a 					;cl = file handle
		mvp (si),0					;number of bytes to move
		mv a,0						;from the file top
		mv il,9						;move the file pointer
		callf fcs_call
;
		jrc _be4ae					;jump if error
		mv a,0						;flag zero if no error
		retf
;
		;reading a block of the file
_be485:	popu a
		mv (cx),a 					;cl = file handle
		mv a,1						;physical end of the file
p16:	mv x,_be6a0					;buffer to store the data
		mv y,11						;11 bytes to read
		mv il,3						;read the bloc
		callf fcs_call
		jrc _be4ae					;jp if error
;
p17:	mv x,[_be6a6]
p18:	mv [_be6c5],x
p19:	mv x,[_be6a3]
p20:	mv y,[_be6a0]
		mv a,1
		retf
_be4ae: sc
		retf
;--------------------------------------------------
;
;--------------------------------------------------
;		     Reading a block of a file
;
;cl = file handle
;x = lead address to be verified
;y = nb bytes to be verified
;--------------------------------------------------
;
readBlock:	
		pushu x
		pushu a
		mv (cx),a					;file handle
		mv a,1						;physical end of the file
		mv il,3						;read the bloc
		callf fcs_call
		jrc _be4ed					;jump if error
;
		;close file
		popu a
		mv (cx),a					;file handle
		mv il,2						;close file
		callf fcs_call
		jrc _be4ed					;jump if error
;
p21:	mv x,_be4ed
		mv [--s],x					;empiler l'adresse de retour
		popu x
p22:	mv y,[_be6b5]
		pushu y
p50:	mv ($ec),[oldbp]			;restaurer bp, _be4d7
p23:	mv y,[_be6c5]
		inc y
		jrz _be4e9
;
		dec y
		jp y
;		
_be4e9:	mv y,x
		jp y
p24:
_be4ed:	mv s,[stacks]				;restaurer la pile système
p25:	mv u,[stacku]				;restaurer la pile utilisateur
p26:	jpf _be376
;
_be4f9:	mv x,[usrwrk]				;récupérer l'adresse LM
		rc
		retf
;
_be4ff:	mv x,$0bfbff
		rc
		retf
;
_be505:	mv x,entry1
		rc
		retf
;
_be50b:	mv ba,$33
		rc
		retf
;
p52:
_be510:	mv x,flag
		rc
		retf
;
p53:
_be516:	mv x,keyBuffer+7
		rc
		retf
;
p54:
_be51c:	mv x,p55					;keyBuffer	+ $63
		rc
		retf
;
;--------------------------------------------------
; Remplissage buffer avec 18 espaces
;
_be522:	mv a,1
p28:	mv [_be6a0],a
		pushu y
		mv ba,2020h
		mv il,9						;compteur
_be52e:	mv [y++],ba
		dec il
		jrnz _be52e					;boucler tant que non nul
;
		popu y
		pushu y
_be536:	mv a,[x++]
p29:	callf checkKey1
		jrc _be614
;
		cmp a,'-'
		jrz _be624
		cmp a,'/'
		jrz _be624
		cmp a,'<'
		jrz _be54e
		cmp a,'>'
		jrnz _be555
_be54e:	sub a,$38
		ror a
p30:	mv [_be6a0],a
p31:
_be555:	callf checkKey2
		jrc _be536
;
		popu y
		dec x
		pushu x
_be55f:	mv a,[x++]
		cmp a,':'
		jrz _be57d
p32:	callf checkKey2
		jrnc _be55f
;
		mv x,defdrv
		pushu y
_be570:	mv a,[x++]
		mv [y++],a
		cmp a,':'
		jrnz _be570
		popu y
		popu x
		pushu y
		jr _be58f
;
;Recopie Drive Name -------------
_be57d:	popu x
		pushu y
		mv il,6						;6 caractères du Drive incluant ':'
_be581:	mv a,[x++]
		mv [y++],a
		cmp a,':'
		jrz _be58f					;saut si ':'
		dec il
		jrnz _be581					;boucler tant que non nul
		jr _be614
;
_be58f:	mv il,8						;8 caractères pour le nom de fichier
		popu y
		pushu y
		mv a,6						
		add y,a						;se positionner sur l'emplacement
		mv a,[x]
p33:	callf checkKey2
		jrnc _be5af					;saut si non carry
;
p34:	callf QuesMark
		mv a,'.'
		mv [y++],a
		mv il,3
p35:	callf QuesMark
		jr _be603
_be5af: mv a,[x++]
		cmp a,'*'
		jrnz _be5bb
p36:	callf QuesMark
		jr _be5cb
;
p37:
_be5bb:	callf checkKey2
		jrc _be5c9
		mv [y++],a
		dec il
		jrnz _be5af
;
		jr _be5cb
_be5c9:	dec x
_be5cb:	mv a,[x++]
		cmp a,'.'
		jrz _be5d3
		dec x
_be5d3:	popu y
		pushu y
		mv a,$0e
		add y,a
		mv a,'.'
		mv [y++],a
		mv il,3
_be5df:	mv a,[x++]
		cmp a,'*'
		jrnz _be5eb
p38:	callf QuesMark
		jr _be5f7
;
p39:
_be5eb:	callf checkKey2
		jrc _be5f7
		mv [y++],a
		dec il
		jrnz _be5df
;
_be5f7:	dec x
_be5f9:	mv a,[x++]
p40:	callf checkKey2
		jrnc _be5f9
		dec x
_be603:	popu y
		pushu y
		mv a,18
		add y,a
		mv a,0
		mv [y++],a
p43:	mv a,[_be6a0]
		popu y
		rc
		retf
;
_be614:	dec x
		popu y
		mv a,$81
		sc
		retf
;
;------------------------------------
;	 Remplissage buffer avec ?
;
QuesMark:	
		mv a,'?'
_be61d:	mv [y++],a
		dec il
		jrnz _be61d
		retf
;------------------------------------
;
;------------------------------------
;	 Conversion majuscule
;
_be624:	mv il,15				;compteur
_be626:	mv a,[x++]
p41:	callf checkKey2
		jrc _be646
		cmp a,'a'				;$61
		jrc _be638
		cmp a,'z'				;$7b
		jrnc _be638
		sub a,$20				;conversion en majuscule
_be638:	mv [y++],a
		dec il
		jrnz _be626
_be63e:	mv a,[x++]
p42:	callf checkKey2
		jrnc _be63e
_be646:	dec x
		mv a,0
		popu y
		rc
		retf
;
checkKey1:	
		cmp a,' '
		jrc _be671
		cmp a,$ff
		jrz _be671
		jr _be66f
checkKey2:	
		cmp a,'!'
		jrc _be671
		cmp a,'+'
		jrc _be66f
		cmp a,'0'
		jrc _be671
		cmp a,':'
		jrc _be66f
		cmp a,'?'
		jrc _be671
		cmp a,$ff
		jrz _be671
_be66f:	rc
		retf
_be671:	sc
		retf
;
attrb:		db 0
title:		db 'TR-DOS V0.33 (C)1993 T.Kobayashi(Ryu)',13,10
fileHeader: db $ff,$00,$06,$01,$10
_be6a0:		dp 0
_be6a3:		dp 0
_be6a6: 	dp 0
_be6a9: 	ds 11,0
flag:   	db 0		;BE6B4h
_be6b5: 	dp 0
stacks:		dp 0		;BE6B8h
stacku:		dp 0		;BE6BBh
_be6be: 	ds 6,0
oldbp:		db 0		;BE6C4h
_be6c5: 	ds 9,0
drvNames: 	db 'S1:   S1:S2:S3:D:E:F:'
_be6e3: 	ds 17,0
_be6f4: 	db 'S1:EX_TYCOM',13
keyBuffer: 	ds 99,0
p55:		dp 0
p56:		dp 0
p57:		ds 11,0
p58:		ds 4,0
block_bottom:
;
;-----------------------------------------------------------
;       DEVICE-DRIVER RELOCATE-TABLE
;-----------------------------------------------------------
modify_table:		;BE778
	dp	p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18
	dp	p19,p20,p21,p22,p23,p24,p25,p26,_be505,p28,p29,p30,p31,p32,p33
	dp	p34,p35,p36,p37,p38,p39,p40,p41,p42,p43,p44,p45,p46,p47
	dp	p48+1,p49+2,p50+2,p51,p52,p53,p54,p55-1,p56-1,p57-1,p58
	dp	-1
;
	end