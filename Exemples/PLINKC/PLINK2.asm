; ==========================================================================
;  PLINK2.asm - Pocket Link Cache Device Driver, portage sur le modele REGISTER3
;
;  Base : plinkc.native.asm (D. Mizobata 1.62, d'apres PLINK de N. Kon), dont le
;  CORPS et la ZONE DE TRAVAIL sont repris VERBATIM (byte-identiques).
;
;  Nouveautes par rapport a PLINKC (comme REGISTER3 vis-a-vis de REGISTER2) :
;    - Installation par 'CALL &BF000', desinstallation par 'CALL &BF000 "-u"'.
;    - Installateur AJOUT-EN-FIN : le pilote est place APRES les blocs existants,
;      sans les decaler -> aucun recalage des pointeurs BASIC (linkbas), donc plus
;      de reset volontaire (bomb) ni de risque de corruption de BASIC.
;    - Noms definis UNE SEULE FOIS (macros drvbase/drvext/drvdev).
;    - La TABLE DE RELOCATION d'origine de PLINKC (60 sites, format delta) est
;      REUTILISEE verbatim ; un seul octet est ajuste car le nom de device 'PL2:'
;      fait 2 octets de plus que 'L:' (le delta site0->site1 passe de 3Dh a 3Fh).
;    - Le pilote ne detourne la SIO que transitoirement (il la restaure a chaque
;      appel, jump00) : au repos il ne tient AUCUN vecteur -> la desinstallation
;      se limite au deliage de la chaine des devices.
; ==========================================================================

	org	$bf000
	pre_on				; INDISPENSABLE : adressage RAM interne absolu.

; --- constantes (reprises de plinkc.native.asm) ----------------------------
fcs:			equ	$fffe4
iocs:			equ	$fffe8
iocs_fook:		equ	$bfca2
sio_rcv_vct:	equ	$bfcd5
sio_param:		equ	$bfd33
base:			equ	$ec
bx:				equ	$d4
cx:				equ	$d6
cl:				equ	$d6
ch:				equ	$d7
dx:				equ	$d8
key_strobe_2:	equ	$f1
sio_ctrl_reg:	equ	$f7
sio_stat_reg:	equ	$f8
sio_rx_reg:		equ	$f9
sio_tx_reg:		equ	$fa
intr_mask_reg:	equ	$fb
system_stat_reg:equ	$ff

btext:	equ	$cb
bdata:	equ	$ce
bpmax:	equ	$ca
iwork:	equ	$e6
keyvec:	equ	$bfc41
s1top:	equ	$bfc15
s1end:	equ	$bfcde
cdrv:	equ	$bfc7d
rev:	equ	$bfca1
iroot:	equ	$bfca2
bworkp:	equ	$bfd0e

sectsiz:	equ	128
cache_sect:	equ	sectsiz+1
cache_next:	equ	cache_sect+2
cache_size:	equ	cache_next+3
n_fcache:	equ	7		;	Nombre de secteurs dans le cache FAT
n_dcache:	equ	1		;	Nombre de secteurs dans le cache de donnees
dtop:		equ	44
timeout:	equ	40000		; Delai d'attente (environ 1 seconde)
blk_id:	equ	0fbh			; signature d'un bloc de fichier (ajout)

; --- noms du pilote, definis UNE SEULE FOIS --------------------------------
;  Nom de FICHIER (bloc) : 'name83' au format 8.3 de l'en-tete (8 car. completes
;  d'espaces, sans point), 'namedot' au format des messages (base.ext).
	macro	drvbase
	db	'PLINK2'		; <= nom de fichier (<= 8 caracteres)
	endm
	macro	drvext
	db	'SYS'			; <= extension
	endm
	macro	name83
_n83:	drvbase
	ds	8-(*-_n83),' '
	drvext
	endm
	macro	namedot
	drvbase
	db	'.'
	drvext
	endm
;  Nom de DEVICE (chaine IOCS) : en-tete + recherche de desinstallation.
	macro	drvdev
	db	'PL2:'			; <= nom de device (termine par ':')
	endm

; ==========================================================================
;  POINT D'ENTREE : install par 'CALL &BF000', desinstall par 'CALL &BF000 "-u"'
; ==========================================================================
start:
;  Lire l'argument de CALL (entre GUILLEMETS, syntaxe BASIC). Le pointeur de
;  ligne empile sur la pile U est RESTITUE avance a la sortie (protocole
;  UUENCODE) pour que BASIC reprenne sans 'Syntax error'.
	popu	x
	mv	(0),0			; (0) = 0 : installer ; sinon : desinstaller
sc_arg:	mv	a,[x++]
	cmp	a,0
	jrz	sc_done
	cmp	a,0dh			; CR
	jrz	sc_done
	cmp	a,1ah			; fin de chaine BASIC (comme UUENCODE argskp)
	jrz	sc_done
	cmp	a,0ffh			; fin de chaine BASIC
	jrz	sc_done
	cmp	a,'-'
	jrnz	sc_arg
	mv	a,[x]
	cmp	a,'u'
	jrz	sc_setu
	cmp	a,'U'
	jrz	sc_setu
	jr	sc_arg
sc_setu:
	mv	a,1
	mv	(0),a
	jr	sc_arg
sc_done:
	dec	x
	pushu	x
	mv	a,(0)
	cmp	a,0
	jrz	install
	jp	uninstall

; ==========================================================================
;  INSTALLATEUR  (CALL &BF000) - modele AJOUT-EN-FIN
; ==========================================================================
install:
;  (1) banniere
	mv	x,msg_title
	mv	y,btm_title-msg_title
	mv	(cl),0
	mv	il,4
	callf	fcs

;  (2) sauver l'ancienne tete de la chaine des devices dans notre 'lien suivant'
	mv	x,[iroot]
	mv	[ihead],x

;  (3) numero de device : code en dur dans l'en-tete (devno). La recherche
;      dynamique via 'iocs il=1' (convention incertaine) est ecartee : elle
;      risquait une boucle infinie (figement). 10 est libre sur un systeme courant.

;  (4) compacter S1: (regrouper l'espace libre en fin de zone)
	mv	(cl),6
	mv	(ch),0
	mv	i,47h
	callf	iocs

;  (5) parcourir les blocs : detecter un doublon, trouver la FIN (point d'ajout)
	mv	x,[s1top]
	mv	y,[x+12h]		; lead address -> premier bloc
	add	x,y
walk:	mv	a,[x]
	cmp	a,blk_id
	jrnz	walk_end
	mv	y,block_top		; comparer le nom (12 octets) au notre
	mv	il,12
	pushu	x
	callf	stricmp
	popu	x
	jrz	err_exist		; deja installe
	mv	y,[x+11h]
	add	x,y
	jr	walk
walk_end:
	mv	(10),x			; (10) = fin des blocs = destination

;  (6) le CODE ne doit pas franchir la page de 64 Ko (appels internes 16 bits)
	mv	i,prgend-block_top
	mv	ba,(10)
	add	ba,i
	jrc	err_mem			; debordement 16 bits -> refus

;  (7) controle memoire : [s1end]-1 - fin_des_blocs >= taille du bloc (blen)
	mv	y,[s1end]
	dec	y
	sub	y,x
	mv	(16),y
	mv	y,blen
	cmpp	(16),y
	jrc	err_mem

;  (8) copier le CODE du pilote a la fin des blocs (la zone de travail suit,
;      reservee mais non copiee)
	mv	i,prgend-block_top
	mv	y,(10)
	mv	x,block_top
copy_lp:
	mv	a,[x++]
	mv	[y++],a
	dec	i
	jrnz	copy_lp

;  (9) RELOCATION : appliquer au pilote COPIE la table de deltas d'origine de
;      PLINKC. Chaque octet de la table avance un pointeur 'y' dans le pilote
;      copie ; on corrige la valeur 3 octets pointee de (dest - block_top).
	mv	[--s],u			; sauver le pointeur de pile U
	mv	u,reloc_table		; u -> table de deltas
	mv	x,(10)			; dest
	mv	ba,rel_dev0-block_top	; offset du 1er site (0x27) depuis block_top
	add	x,ba
	mv	ba,0206h		; 1er delta de la table (constante d'origine)
	sub	x,ba
	mv	y,x			; y = dest + (rel_dev0-block_top) - 0x206
rl:	popu	a			; a = octet de table (mv a,[u++])
	cmp	a,0ffh
	jrz	rl_end
	and	a,7fh
	cmp	a,7eh
	jrnz	rl_short
	popu	ba			; delta long sur 2 octets
	add	y,ba
	jr	rl_corr
rl_short:
	add	y,a
rl_corr:
	mv	x,[y]			; valeur 3 octets a corriger
	mv	[--s],y			; sauver le pointeur de table (u sert deja de lecteur)
	mv	y,block_top
	sub	x,y			; - base d'assemblage
	mv	y,(10)
	add	x,y			; + base de destination
	mv	y,[s++]			; restaurer le pointeur de table
	mv	[y],x
	jr	rl
rl_end:
	mv	u,[s++]			; restaurer le pointeur de pile U

;  (10) chainer le nouveau device en tete de la liste IOCS
	mv	x,(10)
	mv	ba,iocs_header-block_top
	add	x,ba
	mv	[iroot],x		; racine -> notre en-tete IOCS (copie)

;  (11) terminateur de la chaine des blocs, apres le bloc complet (dest+blen)
	mv	x,(10)
	mv	ba,blen
	add	x,ba
	mv	a,0ffh
	mv	[x],a

;  (12) l'init des parametres par 'iocs il=4' (comme PLINKC) FIGE la machine sur
;      l'emulateur (convention incertaine, 1er acces device). Ecartee : le device
;      est deja chaine (comme REGISTER3), le pilote s'initialise a la 1re commande.

;  (13) succes
	mv	x,msg_ins
	mv	y,btm_ins-msg_ins
	mv	(cl),0
	mv	il,4
	callf	fcs
	rc
	retf

;  --- erreurs : message + rendre la main (carry), sans toucher a BASIC ---
err_exist:
	mv	x,msg_exi
	mv	y,btm_exi-msg_exi
	jr	exit_err
err_mem:
	mv	x,msg_mem
	mv	y,btm_mem-msg_mem
exit_err:
	mv	(cl),0
	mv	il,4
	callf	fcs
	sc
	retf

; ==========================================================================
;  DESINSTALLATEUR  (CALL &BF000 "-u")
; ==========================================================================
;  Le pilote ne tient aucun vecteur au repos -> deliage seul. Le bloc reste en
;  memoire (protege) ; l'utilisateur le libere par SET puis KILL (la ROM met a
;  jour le repertoire et recompacte).
uninstall:
	mv	x,msg_unin
	mv	y,btm_unin-msg_unin
	mv	(cl),0
	mv	il,4
	callf	fcs
	mv	y,iroot			; y = emplacement du pointeur vers l'en-tete courant
un_find:
	mv	x,[y]
	inc	x
	jrz	un_notfound		; -1 : fin de chaine
	dec	x
	mv	(10),x			; en-tete courant
	mv	(13),y			; predecesseur
	mv	il,8
	add	x,il			; x = en-tete + 8 = nom de device
	mv	y,drv_str
	mv	il,4
	callf	stricmp
	mv	x,(10)
	mv	y,(13)
	jrz	un_found
	mv	y,x
	jr	un_find
un_found:
;  delier : [predecesseur] = notre lien suivant
	mv	x,(10)
	mv	x,[x]
	mv	y,(13)
	mv	[y],x
	mv	x,msg_uok
	mv	y,btm_uok-msg_uok
	mv	(cl),0
	mv	il,4
	callf	fcs
	rc
	retf
un_notfound:
	mv	x,msg_unf
	mv	y,btm_unf-msg_unf
	mv	(cl),0
	mv	il,4
	callf	fcs
	sc
	retf

; --- helper : comparaison de chaine sur IL octets --------------------------
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

; --- table de relocation (deltas d'origine de PLINKC ; octet 3 : 3Dh->3Fh) -
reloc_table:
	db	0FEh,006h,002h,0BFh,01Eh,0B9h,08Ah,085h,087h,004h,005h,004h,009h,005h,086h,00Eh
	db	007h,003h,00Bh,089h,0B2h,00Ah,08Bh,086h,084h,006h,08Bh,08Bh,09Eh,089h,00Eh,0A2h
	db	089h,00Eh,01Dh,016h,005h,005h,008h,009h,003h,015h,00Ch,005h,005h,004h,009h,0E5h
	db	098h,08Dh,086h,084h,004h,085h,084h,004h,09Fh,096h,084h,007h,0B7h,08Ch,0FFh

; --- messages --------------------------------------------------------------
msg_title:	db	'PLINK2 (PLINKC 1.62, D.Mizobata)',13,10
btm_title:
msg_ins:	db	'Installed.',13,10
btm_ins:
msg_exi:	db	'Error: already exist.',13,10
btm_exi:
msg_mem:	db	'Error: not enough memory.',13,10
btm_mem:
msg_unin:	db	'Uninstalling '
	drvdev
	db	13,10
btm_unin:
msg_uok:	db	'Uninstalled. To free memory :',13,10
	db	'SET  "S1:'
	namedot
	db	'"," "',13,10
	db	'KILL "S1:'
	namedot
	db	'"',13,10
btm_uok:
msg_unf:	drvdev
	db	' not installed.',13,10
btm_unf:
drv_str:	drvdev


	pre_off				; le CORPS a ses propres prebytes explicites (pre $30...)
; ==========================================================================
;  LE PILOTE RESIDENT  (copie en RAM par l'installateur)
; ==========================================================================
;----------------------------------------------------------------------
;		En-tete du fichier d'en-tete de l'appareil
;----------------------------------------------------------------------
block_top:
	db	blk_id			; signature de bloc de fichier
	name83				; nom 8.3 (complete par la macro)
		db	$25						;Attributs de bloc de memoire
		dw	0,0						;Date et heure
		dp	blen					;Nombre d'octets dans le bloc memoire
		dw	0
		dp	blen					;Nombre d'octets de l'entite de fichier
		dp	blen					;Nombre d'octets dans le bloc memoire
		dp	0,0
;----------------------------------------------------------------------
;		En-tete du pilote de peripherique
;----------------------------------------------------------------------
iocs_header:
ihead:		dp	0			;Adresse du prochain en-tete de pilote de peripherique
devno:		db	10			;Numero d'appareil (code en dur ; 10 libre en general)
		db	$83				;Attribut de peripherique (identique a E :)
rel_dev0:	dp	devmain		;Adresse du corps du pilote (site 0 de la relocation)
dvname:		drvdev			;Nom de l'appareil (defini une seule fois)
		db	0

;----------------------------------------------------------------------
;		Media parameter block
;----------------------------------------------------------------------
;Version de 128 Ko
mpb128:		db	$f0			;Descripteur de media (peut etre approprie)
		dw	sectsiz			;Nombre d'octets par secteur
		db	4-1				;(Nombre d'octets par secteur / 32) -1
		db	2				;log 2 (nombre d'octets par secteur / 32)
		db	0				;???
		db	1				;???
		dw	0				;Premier numero de secteur de zone FAT
		db	8				;???
		dw	128				;Nombre maximum de fichiers stockables
		dw	dtop			;Numero du secteur de depart de la zone de donnees
		dw	980+1			;Nombre total de secteurs dans la zone de donnees + 1
		db	12				;Nombre total de secteurs dans la zone FAT
		dw	12				;Premier numero de secteur de la zone DIR
;Donnees referencees dans DS
		dw	12				;Premier numero de secteur de la zone DIR
;Version de 512 Ko
mpb512:		db	$f0
		dw	sectsiz
		db	4-1
		db	2
		db	0
		db	1
		dw	0
		db	8
		dw	128
		dw	80			;Numero du secteur de depart de la zone de donnees
		dw	4016+1		;Nombre total de secteurs dans la zone de donnees + 1
		db	48			;Nombre total de secteurs dans la zone FAT
		dw	48			;Premier numero de secteur de la zone DIR
;
		dw	48
;----------------------------------------------------------------------
;		Corps
;----------------------------------------------------------------------
suborg		0
byte		i_work1,i_work2
word		sect_num,sect_num2
byte		flag,rxdata,i_work3,subko
pntr		cachep,vct_rsv,before
devmain:	pushu	imr				;Arretez l'interruption et reecrivez le vecteur de reception SIO
		pushu	x
		pre	$30
		sub	(base),%
		mv	x,[sio_rcv_vct]
		mv	(vct_rsv),x	
		mv	x,rcv;rel
		mv	[sio_rcv_vct],x
		popu	x
		popu	imr
		mv	(i_work3),[sio_param]   ;Charger les parametres
		and	(i_work3),$fd	   		;Ce force a 8 bits
		pre	$22
		ex	(i_work3),(sio_ctrl_reg);Parametrage de la SIO & conservation du contenu precedent
		pre	$22
		mv	(subko),(key_strobe_2)	;Enregistrer KOH
		pre	$30
		or	(key_strobe_2),$60		;Activer DTR, RR
;
		call	main
;
		{
			pre	$30
			test	(sio_stat_reg),$10
			jrz	continue				;Attendre la fin de la transmission
	}
		pre	$30
		mv	(sio_ctrl_reg),(i_work3)	;Restaurer le parametre SIO
		pre	$30
		mv	(key_strobe_2),(subko)		;Restaurer KOH
		test	(flag),2
		jrz	jump00						;[BRK] a ete presse?
		mv	a,$02
		jrc	jump00
brkloop:	test	[$bfcbe],$80		;Attendez que la pause soit liberee
		jrnz	brkloop
		mv	a,$ff						;Traitement en cas de pression
		sc
jump00:		pushu	imr					;Restaurer le vecteur de reception SIO
		pushu	x
		mv	x,(vct_rsv)
		mv	[sio_rcv_vct],x
		pre	$30
		pmdf	(base),%
		popu	x
		popu	imr
		retf
;----------------------------------------------------------------------
;		Diverses commandes
;----------------------------------------------------------------------
init:		mv	a,[x]
		cmp	a,'1'
		jrnz	cmd3f_5
		mv	x,mpb128;rel
		jr	cmd3f_15
cmd3f_5:	cmp	a,'5'
		jrnz	cmd3f_d
		mv	x,mpb512;rel
cmd3f_15:	pushu	a
		mv	[getmpb+1],x;rel
		mv	ba,[x+$c]
		mv	[secpatch+1],ba;rel
		call	check_sect
		mv	a,'S'
		call	send_one
		popu	a
		call	send_one
		jr	cmd3f_2
cmd3f_d:	cmp	a,'D'
		jrnz	cmd3f_i
		call	check_sect				;"D" commande
		mv	a,'D'
		call	send_one				;Envoyer la commande "D"
		mv	i,$12+(receive_one_s-receive_one-2)*$100
		mv	[receive_one],i		;jr receive_one_s rel
		jr	cmd3f_2
cmd3f_i:	cmp	a,'I'
		jrnz	cmd3f_2
		mv	il,130					;"Je" commande
		mv	a,0						;Envoyer 130 pieces de 00h
cmd3f_i1:	call	send_one
		dec	il
		jrnz	cmd3f_i1
cmd3f_2:	call	buffer_clr			;Nettoyer le tampon
		;bsr	root
		;ret

root:		call	getroot	
		mv	[x+$a],i
		mv	[x+$11],ba
		rc
		ret

getroot:	call	getmpb
		mv	ba,[x+$13]
		mv	il,128
		ret

getmpb:		mv	x,mpb128;rel
		rc
		ret
;----------------------------------------------------------------------
;		Corps de chaque processus
;----------------------------------------------------------------------
main:		mv	(flag),0		;Effacer le drapeau
		mv	a,il				;Analyse de commande
		cmp	a,$10
		jrnz	cmd11
		rc						;Traitement de commande 10h
		ret
cmd11:		cmp	a,$11
		jrz	getmpb				;Traitement de la commande 11h
		cmp	a,$12
		jrz	read_sect			;Traitement de commande 12h
		cmp	a,$13
		jrz	write_sect			;Traitement de la commande 13h
		cmp	a,$14
		jrz	write_sect			;Traitement de la commande 14h
		cmp	a,$15
		jrz	read_sect			;Traitement de commande 15h
		cmp	a,$16
		jrnz	cmd17
		mv	ba,0				;Traitement de commande 16h
		rc
		ret
cmd17:		cmp	a,$17
		jrnz	cmd18
		mv	ba,[sect_number]	;Traitement de commande 17h rel
		pre	$30
		cmpw	(bx),ba
		jrz	same_sect				;c'etait le meme secteur que le tampon
		call	check_sect
		test	(flag),2
		jrnz	cmd17_err
		pre	$30
		mv	ba,(bx)
		mv	[sect_number],ba;rel
		mv	(sect_num),ba
		mv	x,sect_1;rel
		mv	y,sect_2		;Faire une copie rel
		mv	il,sectsiz/2+1
		call	rcv_sect			;Lire secteur specifie
		test	(flag),2
		jrz	same_sect
		mv	ba,-1
		mv	[sect_number],ba;rel
		jr	cmd17_err
same_sect:	pre	$30
		mvw	(cx),sectsiz
		mv	x,sect_1;rel
		rc
cmd17_err:	ret
cmd18:		cmp	a,$18
		jrz	getroot				;Traitement de la commande $ 18 (pour DS)	
cmd3f:		cmp	a,$3f
		jrz	init				;Traitement de la commande 3Fh
cmd40:		cmp	a,$40
		jrz	root				;Traitement de commande 40h
cmd_err:	mv	a,3				;Commande invalide
		sc
		ret
;----------------------------------------------------------------------
;		Lecture continue de secteurs
;----------------------------------------------------------------------
read_sect:	pre	$22
		mvw	(sect_num),(bx)
		mv	y,x
		mv	il,sectsiz/2
		mv	ba,[sect_number];rel
		cmpw	(sect_num),ba    ;Secteurs tampons et
		jrnz	read_sect1	     ;Avez-vous frappe?
		mv	y,sect_1;rel
read_sect2:	mv	ba,[y++]
		mv	[x++],ba
		dec	il
		jrnz	read_sect2
		jr	read_sect3
read_sect1:	call	rcv_sect
		test	(flag),2
		jrnz	read_err
read_sect3:	pre	$30
		mv	ba,(bx)
		inc	ba
		pre	$30
		mv	(bx),ba
		pre	$30
		mv	ba,(dx)
		dec	ba
		pre	$30
		mv	(dx),ba
		jrnz	read_sect
		rc
read_err:	ret
;----------------------------------------------------------------------
;		Ecriture continue de secteurs
;----------------------------------------------------------------------
write_sect:	pre	$22
		mvw	(sect_num),(bx)
		mv	il,sectsiz
		mv	ba,[sect_number];rel
		cmpw	(sect_num),ba    ;Secteurs tampons et
		jrnz	write_sect1	     ;Avez-vous frappe?
		mv	y,sect_1;rel
write_sect2:	mv	a,[x++]
		mv	[y++],a
		dec	il
		jrnz	write_sect2
		jr	write_sect3
write_sect1:	call	send_sect
		test	(flag),2
		jrnz	write_err
write_sect3:	pre	$30
		mv	ba,(bx)
		inc	ba
		pre	$30
		mv	(bx),ba
		pre	$30
		mv	ba,(dx)
		dec	ba
		pre	$30
		mv	(dx),ba
		jrnz	write_sect
		rc
write_err:	ret
;----------------------------------------------------------------------
;		Transmission a un secteur
;----------------------------------------------------------------------
send_sect:	pushu	il
		call	send_cache	;Traitement CACHE
		popu	il
		pushu	imr
		pre	$30
		mv	(intr_mask_reg),$a0
		mv	y,(cachep)
		pushu	y
send_sect_2:	mv	a,[x++]
		mv	[y++],a		;Ecrivez a CACHE
		dec	il
		jrnz	send_sect_2
		mv	a,'W'
		call	send_one			;Envoyer la commande a ecrire
		mv	a,(sect_num)
		call	send_one			;Transmission inferieure a 1 octet du numero de secteur
		mv	a,(sect_num+1)
		call	send_one			;Envoi du 1 octet superieur du numero de secteur
		popu	y
		mv	il,sectsiz+1
send_sect_3:	mv	a,[y++]
		call	send_one			;Envoi de 129 octets de donnees CACHE
		dec	il
		jrnz	send_sect_3
		mv	a,$ff
		call	send_one			;Envoyer une marque de terminaison normale
		call	receive_one
		test	(flag),2
		jrz	send_ok
		mv	ba,-1
		mv	[y],ba				;Invalider le cache mis en cache
send_ok:	popu	imr
		ret
;----------------------------------------------------------------------
;		Reception 1 secteur
;----------------------------------------------------------------------
rcv_sect:	pushu	imr
		pushu	il
		pre	$30
		mv	(intr_mask_reg),$a0
		call	send_cache			;Traitement CACHE
		popu	il
		jrnc	read_cache		;Sautez quand vous pouvez lire de CACHE
		pushu	il
		pushu	x
		mv	x,(cachep)			;Charger dans CACHE
		mv	a,'R'
		call	send_one			;Envoyer une commande de lecture
		mv	a,(sect_num)
		call	send_one			;Transmission inferieure a 1 octet du numero de secteur
		mv	a,(sect_num+1)
		call	send_one			;Envoi du 1 octet superieur du numero de secteur
		rc
		call	receive_one			;(Taille du secteur + 1) reception octet
		jrc	rcv_sect_2
		mv	[x++],a
		mv	il,sectsiz
rcv_sect_1:	call	receive_one
		mv	[x++],a
		dec	il
		jrnz	rcv_sect_1
rcv_sect_2:	popu	x
		popu	il
read_cache:	mv	[--s],u			;Lire de CACHE
		mv	u,(cachep)
		test	(flag),2
		jrz	read_cache_1
		mv	ba,-1
		mv	[u+cache_sect],ba;Invalider le cache entrant
		jr	rcv_err
read_cache_1:	popu	ba		;mv	ba,[u++]
		mv	[x++],ba
		mv	[y++],ba
		dec	il
		jrnz	read_cache_1
rcv_err:	mv	u,[s++]
		popu	imr
		ret
;----------------------------------------------------------------------
;		Transmission sur 1 octet
;----------------------------------------------------------------------
send_one:	pre	$30
		test	(sio_stat_reg),$8
		jrz	send_one			;Attendez qu'il soit pret pour Tx
		test	(flag),2
		jrz	send_one_2			;En mode d'arret de la transmission, 00h est transmis
		mv	a,0
send_one_2:	pre	$30
		mv	(sio_tx_reg),a		;Envoyer
		ret
;----------------------------------------------------------------------
;		Recevez 1 octet
;----------------------------------------------------------------------
receive_one:	jr	receive_one_s
		db	system_stat_reg,8
;		test	(system_stat_reg),8
		jrnz	receive_one_err	;[BRK] a ete presse
		test	(flag),1
		jrz	receive_one			;Attendez qu'un octet soit recu
		mv	a,(rxdata)
		and	(flag),$fe			;Reinitialiser le drapeau
		ret
receive_one_s:	mv	ba,timeout
receive_one_lp:	pre	$30			;1
		test	(system_stat_reg),8	;4
		jrnz	receive_one_err		;2
		test	(flag),1		;4
		jrnz	receive_one_ok		;2
		dec	ba			;3
		jrnz	receive_one_lp		;3
		sc
receive_one_err:or	(flag),2	;Definir le mode d'arret de la transmission
		ret
receive_one_ok:	mv	ba,$6530	;pre $30 test (m),n
		mv	[receive_one],ba;rel
		mv	a,(rxdata)
		and	(flag),$fe			;Reinitialiser le drapeau
		ret
;----------------------------------------------------------------------
;		Recevez une routine de traitement des interruptions
;----------------------------------------------------------------------
rcv:		pre	$30
		mv	a,(sio_rx_reg)
		mv	(rxdata),a
		or	(flag),1			;Definir le drapeau de reception complete
		retf
;----------------------------------------------------------------------
;		Tampon clair
;----------------------------------------------------------------------
buffer_clr:	mv	il,sectsiz+2
		mv	ba,0
		mv	x,sect_1;rel
buffer_clr_1:	mv	[x++],ba	;Remplir le tampon avec 00h
		dec	i
		jrnz	buffer_clr_1
		mv	ba,-1
		mv	[sect_number],ba	;Initialisation du numero de secteur rel
		mv	il,n_fcache
		mv	y,fcache;rel
		mv	[fcachep],y;rel
		call	buffer_clr_3		;Initialisation du cache FAT
		mv	il,n_dcache
		mv	y,dcache;rel
		mv	[dcachep],y;rel
		call	buffer_clr_3		;Initialisation du cache de donnees
		ret

buffer_clr_3:	mv	x,y
		mv	[x+cache_sect],ba
		dec	il
		jrz	buffer_clr_2
		mv	ba,cache_size
		add	y,ba
		mv	[x+cache_next],y
		jr	buffer_clr_3
buffer_clr_2:	mv	y,$fffff
		mv	[x+cache_next],y
		ret
;----------------------------------------------------------------------
;		Verification de la correspondance du tampon pour la commande $ 17
;----------------------------------------------------------------------
check_sect:	mv	x,sect_1;rel
		mv	il,sectsiz+1
check_sect_3:	mv	(i_work1),[x++]
		mv	a,[x+sectsiz+1]
		cmp	(i_work1),a			;Comparaison du contenu de la memoire tampon
		jrnz	check_sect_4
		dec	il
		jrnz	check_sect_3
		ret
check_sect_4:
		mvw	(sect_num),[sect_number];rel
		mv	x,sect_1;rel
		mv	il,sectsiz+1
		pushu	x
		call	send_sect			;Pour expulser le tampon
		popu	x
		mv	ba,(sect_num)
		inc	ba
		mv	(sect_num),ba
		dec	ba
		dec	ba
		mv	(sect_num2),ba
		mv	y,(cachep)
check_sect_6:	mv	ba,[y+cache_sect]
		cmpw	(sect_num),ba
		jrnz	check_sect_5
		pushu	a
		mv	a,[x+sectsiz]
		mv	[y],a				;Le premier octet du secteur a cote du secteur accede
		popu	a
check_sect_5:	cmpw	(sect_num2),ba
		jrnz	check_sect_7
		mv	a,[x]
		mv	[y+sectsiz],a		;Le 129eme octet du secteur avant le secteur accede
check_sect_7:	mv	y,[y+cache_next]
		pushu	y
		inc	y
		popu	y
		jrnz	check_sect_6
		ret
;----------------------------------------------------------------------
;		Verification de la correspondance avec le cache
;----------------------------------------------------------------------
send_cache:
		pushu	x
		pushu	y
		mv	x,dcachep;rel
secpatch:	mv	ba,dtop			;Le numero du secteur principal de la zone DATA est ecrit
		cmpw	(sect_num),ba
		jrnc	send_cache_0
		mv	x,fcachep;rel
send_cache_0:	mv	(cachep),x
		mv	(before),x
		mv	x,[x]
send_cache_1:	mv	ba,[x+cache_sect]
		mv	y,[x+cache_next]
		cmpw	(sect_num),ba
		jrz	send_cache_2		;Le secteur auquel on a tente d'acceder est le meme que CACHE
		pushu	y
		inc	y
		popu	y
		sc						;Marquez qu'il ne peut pas etre lu de CACHE
		jrz	send_cache_2
		mv	a,cache_next
		add	x,a
		mv	(before),x
		mv	x,y
		jr	send_cache_1
send_cache_2:	mv	[(before)],y
		mv	y,[(cachep)]
		mv	[x+cache_next],y
		mvw	[x+cache_sect],(sect_num)
		mv	[(cachep)],x
		mv	(cachep),x
		popu	y
		popu	x
		ret

prgend:
;----------------------------------------------------------------------
;		Zone de travail
;----------------------------------------------------------------------
suborg		*
byte		sect_1[sectsiz+1+1],sect_2[sectsiz+1+1]
pntr		fcachep,dcachep
byte		fcache[cache_size*n_fcache]
byte		dcache[cache_size*n_dcache]
word		sect_number

blen:		equ	%-block_top
	end
