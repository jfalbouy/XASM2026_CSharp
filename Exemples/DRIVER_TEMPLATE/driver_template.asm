; ==========================================================================
;  driver_template.asm - squelette de pilote resident pour SHARP PC-E500(S)
;
;  Modele generalise a partir de REGISTER2 (valide sur materiel). Voir
;  Documentation/Modele_Pilotes_Resident_PC-E500S.md pour l'architecture.
;
;  A ADAPTER : le nom du pilote (DRIVER  SYS), le numero de device (number),
;  la chaine de noms de device ('DRV:'), et le CORPS (a partir de iocs_entry).
;  Chaque adresse absolue interne au pilote DOIT etre emise par 'reldp' (voir
;  la discipline de relocation plus bas), sinon elle ne sera pas corrigee a la
;  copie et le pilote plantera a l'execution.
;
;  A VALIDER sur emulateur avant emploi reel, comme tout pilote de ce corpus.
; ==========================================================================

	org	0be000h			; adresse de chargement de l'installateur

; --- constantes systeme (voir Exemples/INCLUDE/pce500.inc) -----------------
blk_id:		equ	0fbh		; signature d'un bloc de fichier
d_link:		equ	0bfca2h		; racine de la chaine des devices
s1_top:		equ	0bfc15h		; haut de S1:
s1_btm:		equ	0bfcdeh		; bas de S1: + 1
baswrk:		equ	0bfd0eh		; zone de travail BASIC
text_ad:	equ	0cbh		; adresse du bloc TEXT.BAS
data_ad:	equ	0ceh		; adresse du bloc DATA.BAS
cl:		equ	0d6h
ch:		equ	0d7h
fcs_call:	equ	0fffe4h		; appel FCS
iocs_call:	equ	0fffe8h		; appel IOCS

; --- discipline de relocation ---------------------------------------------
;  reldp cible  : emet un pointeur relogeable DANS le pilote et le compte.
;  relref site  : declare, dans la table, le site (= adresse du pointeur de
;                 3 octets) et le compte. L'assertion _nrel = _ntbl echoue si
;                 l'un des deux est oublie -> l'oubli devient une erreur
;                 d'assemblage (la ou REGISTER2 ne le detectait pas).
_nrel:	set	0
_ntbl:	set	0
	macro	reldp,cible
	dp	cible
_nrel:	set	_nrel+1
	endm
	macro	relref,site
	dp	site
_ntbl:	set	_ntbl+1
	endm

; ==========================================================================
;  INSTALLATEUR  (lance par CALL &BE000)
; ==========================================================================
start:
;  (1) banniere
	mv	x,msg0
	mv	y,btm0-msg0
	mv	(cl),0
	mv	il,4
	callf	fcs_call

;  (2) compacter la zone S1: pour recuperer l'espace libre
	mv	(cl),6
	mv	(ch),0
	mv	i,47h
	callf	iocs_call

;  (3) parcourir les blocs : detecter un doublon, trouver le point d'insertion
	mv	x,[s1_top]
	mv	y,[x+12h]		; lead address -> premier bloc
	add	x,y
	mv	(10),x			; (10) = destination du nouveau bloc
init_1:	mv	a,[x]
	cmp	a,blk_id		; encore un bloc de fichier ?
	jrnz	block_end
	mv	y,block_top		; comparer le nom au notre
	mv	il,12
	pushu	x
	callf	stricmp
	popu	x
	jrz	exit2			; deja installe
	mv	a,[x+12]		; attribut du bloc
	test	a,0ch			; device & protege ?
	jrz	set_start
	mv	y,[x+11h]		; sinon bloc suivant
	add	x,y
	jr	init_1
set_start:
	mv	(10),x			; insertion apres le dernier bloc device/protege
init_2:	mv	a,[x]
	cmp	a,blk_id
	jrnz	block_end
	mv	y,[x+11h]
	add	x,y
	jr	init_2
block_end:
	mv	(13),x			; (13) = fin de la zone des blocs

;  controle memoire
	mv	y,[s1_btm]
	dec	y
	sub	y,x
	mv	(16),y			; espace libre
	mv	y,block_bottom-block_top
	cmpp	(16),y
	jrc	exit3			; pas assez de memoire

;  (4) chainer le nouveau device en tete de la liste IOCS
	mv	x,[d_link]		; ancienne tete
	mv	[header],x		; -> champ 'lien suivant' du nouvel en-tete
	mv	x,(10)
	mv	il,iocs_header-block_top
	add	x,il
	mv	[d_link],x		; racine -> nouvel en-tete IOCS

;  (5) relocation : corriger chaque pointeur du bloc SOURCE pour l'adresse
;      de DESTINATION (10), avant la copie.
	mv	x,modify_table
	mv	ba,[x]			; ba = nombre d'entrees
	mv	x,modify_table+2	; sauter le compte, pointer le 1er site
reloc_lp:
	mv	y,[x++]			; site = adresse d'un pointeur 3 octets
	pushu	x
	pushu	ba
	mv	x,[y]			; valeur assemblee du pointeur
	pushu	y			; sauver le site
	mv	y,block_top
	sub	x,y			; - base d'assemblage
	mv	y,(10)
	add	x,y			; + base de destination
	popu	y			; recuperer le site
	mv	[y],x			; reecrire le pointeur relocalise
	popu	ba
	popu	x
	dec	ba
	jrnz	reloc_lp

;  (6) faire de la place (decaler les blocs existants vers le haut) puis
;      copier le pilote a sa destination. (Adapte de REGISTER2.)
	mv	x,(13)
	mv	y,(10)
	sub	x,y			; longueur a decaler
	mv	(16),x
	mv	x,(13)
	mv	y,x
	mv	ba,block_bottom-block_top
	add	y,ba			; destination du decalage
	inc	x
	inc	y
init_6:	mv	a,[--x]			; decalage bloc par bloc, du haut vers le bas
	mv	[--y],a
	mv	a,(16)
	sub	a,1
	mv	(16),a
	jrnc	init_6
	mv	a,(17)
	sub	a,1
	mv	(17),a
	jrnc	init_6
	mv	a,(18)
	sub	a,1
	mv	(18),a
	jrnc	init_6

	mv	i,block_bottom-block_top	; copier le pilote
	mv	y,(10)
	mv	x,block_top
init_5:	mv	a,[x++]
	mv	[y++],a
	dec	i
	jrnz	init_5

;  (7) messages de fin
exit1:	mv	x,msg1
	mv	y,btm1-msg1
	jr	exit4
exit2:	mv	x,msg2
	mv	y,btm2-msg2
	jr	exit4
exit3:	mv	x,msg3
	mv	y,btm3-msg3
exit4:	mv	(cl),0
	mv	il,4
	callf	fcs_call

;  (8) recaler les pointeurs BTEXT$ / BDATA$ de BASIC, decales par l'insertion
remake_slot:
	mv	x,[baswrk]
	mv	a,[x+72h]
	cmp	a,0			; BTEXT$ dans "S1:" ?
	jrnz	remake_data
	mv	y,73h
	add	y,x
	pushu	y
	mv	x,[s1_top]
	mv	y,[x+12h]
	add	x,y
	popu	y
text1:	mv	a,[x]
	cmp	a,blk_id
	jrnz	remake_end
	mv	il,11
	pushu	y
	pushu	x
	inc	x
	callf	stricmp
	popu	x
	jrz	text2
	mv	y,[x+11h]
	add	x,y
	popu	y
	jr	text1
text2:	popu	y
	mv	(text_ad),x
remake_data:
	mv	x,[baswrk]
	mv	a,[x+7eh]
	cmp	a,0			; BDATA$ dans "S2:" ?
	jrnz	remake_end
	mv	y,7fh
	add	y,x
	pushu	y
	mv	x,[s1_top]
	mv	y,[x+12h]
	add	x,y
	popu	y
data1:	mv	a,[x]
	cmp	a,blk_id
	jrnz	remake_end
	mv	il,11
	pushu	y
	pushu	x
	inc	x
	callf	stricmp
	popu	x
	jrz	data2
	mv	y,[x+11h]
	add	x,y
	popu	y
	jr	data1
data2:	popu	y
	mv	(data_ad),x
remake_end:
	rc
	retf

; --- helper : comparaison de chaine sur IL octets -------------------------
stricmp:
	mv	(0),[x++]
	mv	a,[y++]
	cmp	(0),0
	jrz	stricmp1
	cmp	(0),a
	jrnz	stricmp2
	dec	il
	jrnz	stricmp
	retf
stricmp1:
	cmp	(0),a
	retf
stricmp2:
	retf

; --- messages -------------------------------------------------------------
msg0:	db	'DRIVER template',13,10
btm0:
msg1:	db	'Installed.',13,10
btm1:
msg2:	db	'Error: already exist.',13,10
btm2:
msg3:	db	'Error: not enough memory.',13,10
btm3:

; ==========================================================================
;  LE PILOTE RESIDENT  (copie en RAM par l'installateur)
; ==========================================================================
block_top:
; -- en-tete de bloc memoire --
	db	blk_id,'DRIVER  SYS'	; signature + nom 8.3 (complete d'espaces)
	db	25h			; attributs de bloc
	dw	0,0			; date, heure
	dp	block_bottom-block_top	; taille du bloc
	dw	0
	dp	block_bottom-block_top	; taille du fichier
	dp	block_bottom-block_top
	dp	0,0
; -- en-tete IOCS (maillon de chaine) --
iocs_header:
header:	dp	0			; lien suivant (rempli a l'installation)
number:	db	20			; numero de device (a adapter)
attr:	db	63h			; attribut de device
adrs:
	reldp	iocs_entry		; point d'entree (pointeur relogeable)
	db	'DRV:',0			; nom de device (a adapter)

; -- CORPS (a remplacer par vos fonctions) --
;    Ici un stub minimal : renvoie 'commande non geree' (carry).
;    Toute adresse absolue interne emise ici doit passer par 'reldp' et etre
;    inscrite dans modify_table via 'relref' (voir la discipline).
iocs_entry:
	sc
	retf
block_bottom:

; ==========================================================================
;  TABLE DE RELOCATION  +  VERIFICATIONS A L'ASSEMBLAGE
; ==========================================================================
modify_table:
	dw	_nrel			; nombre d'entrees (lu par l'installateur)
	relref	adrs			; site du pointeur d'entree IOCS
modify_end_tbl:

	assert	_nrel = _ntbl,'table de relocation incomplete (reldp vs relref)'
	assert	adrs >= block_top,'site de relocation hors du pilote'
	assert	adrs < block_bottom,'site de relocation hors du pilote'
	assert	block_bottom > block_top,'pilote de taille nulle'
	end
