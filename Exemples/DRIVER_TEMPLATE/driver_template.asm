; ==========================================================================
;  driver_template.asm - squelette de pilote resident pour SHARP PC-E500(S)
;
;  Voir Documentation/Modele_Pilotes_Resident_PC-E500S.md pour l'architecture.
;
;  Modele d'installation : AJOUT EN FIN de la chaine des blocs de S1: (pas de
;  decalage des fichiers existants -> aucun recalage des pointeurs BASIC, donc
;  pas de corruption possible de BASIC). Plus simple et plus sur que l'insertion
;  avec decalage employee par REGISTER.
;
;  A ADAPTER : le nom (DRIVER  SYS), le numero de device (number), la chaine de
;  noms ('DRV:'), et le CORPS (a partir de iocs_entry). Toute adresse absolue
;  interne au pilote DOIT etre emise par 'reldp' (voir la discipline).
;
;  EXPERIMENTAL : a valider sur emulateur. En cas d'echec, l'installateur rend
;  la main proprement (message + carry), sans toucher a BASIC.
; ==========================================================================

	org	0be000h			; adresse de chargement de l'installateur

; --- constantes systeme (voir Exemples/INCLUDE/pce500.inc) -----------------
blk_id:		equ	0fbh		; signature d'un bloc de fichier
d_link:		equ	0bfca2h		; racine de la chaine des devices
s1_top:		equ	0bfc15h		; haut de S1:
s1_btm:		equ	0bfcdeh		; bas de S1: + 1
cl:		equ	0d6h
ch:		equ	0d7h
fcs_call:	equ	0fffe4h		; appel FCS
iocs_call:	equ	0fffe8h		; appel IOCS

; --- discipline de relocation ---------------------------------------------
;  reldp cible  : emet un pointeur relogeable DANS le pilote et le compte.
;  relref site  : declare, dans la table, le site (adresse du pointeur de 3
;                 octets) et le compte. L'assertion _nrel = _ntbl echoue si
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

;  (2) compacter S1: (regrouper l'espace libre en fin de zone)
	mv	(cl),6
	mv	(ch),0
	mv	i,47h
	callf	iocs_call

;  (3) parcourir les blocs : detecter un doublon, trouver la FIN (point d'ajout)
	mv	x,[s1_top]
	mv	y,[x+12h]		; lead address -> premier bloc
	add	x,y
walk:	mv	a,[x]
	cmp	a,blk_id		; encore un bloc ?
	jrnz	walk_end
	mv	y,block_top		; comparer le nom au notre
	mv	il,12
	pushu	x
	callf	stricmp
	popu	x
	jrz	exit2			; deja installe
	mv	y,[x+11h]		; sinon bloc suivant
	add	x,y
	jr	walk
walk_end:
	mv	(10),x			; (10) = fin des blocs = destination (ajout en fin)

;  (4) controle memoire : libre = bas_de_S1 - fin_des_blocs >= taille du pilote
	mv	y,[s1_btm]
	dec	y
	sub	y,x
	mv	(16),y
	mv	y,block_bottom-block_top
	cmpp	(16),y
	jrc	exit3

;  (5) chainer le nouveau device en tete de la liste IOCS
	mv	x,[d_link]		; ancienne tete
	mv	[header],x		; -> champ 'lien suivant' du nouvel en-tete
	mv	x,(10)
	mv	il,iocs_header-block_top
	add	x,il
	mv	[d_link],x		; racine -> nouvel en-tete IOCS

;  (6) relocation : corriger chaque pointeur du bloc SOURCE pour l'adresse de
;      DESTINATION (10), AVANT la copie.
	mv	x,modify_table
	mv	ba,[x]			; ba = nombre d'entrees
	mv	x,modify_table+2	; sauter le compte
reloc_lp:
	mv	y,[x++]			; site = adresse d'un pointeur 3 octets
	pushu	x
	pushu	ba
	mv	x,[y]			; valeur assemblee du pointeur
	pushu	y
	mv	y,block_top
	sub	x,y			; - base d'assemblage
	mv	y,(10)
	add	x,y			; + base de destination
	popu	y
	mv	[y],x			; reecrire le pointeur relocalise
	popu	ba
	popu	x
	dec	ba
	jrnz	reloc_lp

;  (7) copier le pilote a la fin des blocs, puis ecrire le terminateur $ff
	mv	i,block_bottom-block_top
	mv	y,(10)
	mv	x,block_top
copy_lp:
	mv	a,[x++]
	mv	[y++],a
	dec	i
	jrnz	copy_lp
	mv	a,0ffh			; nouveau terminateur de la chaine des blocs
	mv	[y],a

;  (8) succes : afficher 'Installed.' et rendre la main. Aucun fichier n'a ete
;      decale, donc AUCUN recalage des pointeurs BASIC (pas de risque pour BASIC).
	mv	x,msg1
	mv	y,btm1-msg1
	mv	(cl),0
	mv	il,4
	callf	fcs_call
	rc
	retf

;  --- erreurs : afficher le message et rendre la main (carry), sans toucher a BASIC ---
exit2:	mv	x,msg2
	mv	y,btm2-msg2
	jr	exit_err
exit3:	mv	x,msg3
	mv	y,btm3-msg3
exit_err:
	mv	(cl),0
	mv	il,4
	callf	fcs_call
	sc
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
	db	25h			; attributs de bloc (device + protege)
	dw	0,0			; date, heure
	dp	block_bottom-block_top	; taille du bloc  (offset 011h : lien vers le bloc suivant)
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
;    Stub minimal : renvoie 'commande non geree' (carry).
;    Toute adresse absolue interne emise ici doit passer par 'reldp' et etre
;    inscrite dans modify_table via 'relref'.
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
