;===========================================================================
;	REGISTER3.ASM - Register checker (modele DRIVER_TEMPLATE) for PC-E500/1480U
;	d'apres REGISTER.ASM Ver 1.2, (c)1990,1992 E. Kako (JM2WGN)
;
;	Reecriture pour xasm2026-4. Le code machine emis est STRICTEMENT
;	IDENTIQUE a celui de REGISTER.ASM : seules changent la lisibilite et
;	les verifications faites a l'assemblage. Rien n'a ete reordonne, aucune
;	instruction n'a ete remplacee.
;
;---------------------------------------------------------------------------
;	COMMENT CE PROGRAMME FONCTIONNE
;
;	Il installe un pilote de peripherique ("REG:") dans la RAM systeme,
;	puis rend la main. Une fois installe, SHIFT+CTRL affiche l'etat des
;	registres du CPU par-dessus l'ecran courant.
;
;	Le pilote est ASSEMBLE ici a l'adresse 0BE000h, mais il est COPIE a
;	une adresse determinee a l'execution. Toute instruction du pilote qui
;	contient une adresse absolue doit donc etre corrigee apres la copie.
;
;	C'est le role de la table de relocation en fin de fichier : chaque
;	etiquette pN designe une telle instruction, et l'installeur remplace
;	les trois octets d'operande situes en pN+1 par l'adresse recalculee.
;
;	>>> PIEGE A CONNAITRE : ajouter dans le pilote une instruction portant
;	>>> une adresse absolue OBLIGE a lui donner une etiquette pN et a
;	>>> l'inscrire dans modify_table. L'oublier ne provoque aucune erreur
;	>>> d'assemblage : le pilote s'installe et se plante a l'execution.
;	>>> Une verification en fin de fichier compte les entrees de la table.
;===========================================================================
bl:	equ	0d4h
bh:	equ	0d5h
cl:	equ	0d6h
ch:	equ	0d7h
dl:	equ	0d8h
dh:	equ	0d9h
;
s2_top:	equ	0bfc0fh		;top  of "S2:"
s2_siz:	equ	0bfc12h		;size of "S2:"
s1_top:	equ	0bfc15h		;top  of "S1:"
s1_siz:	equ	0bfc18h		;size of "S1:"
s1_btm:	equ	0bfcdeh		;bottom of "S1:"
d_link:	equ	0bfca2h		;device link pointer
baswrk:	equ	0bfd0eh		;BASIC WORK Address
keyvct:	equ	0bfccch		;key interrupt vector
;
fcs_call:  equ	0fffe4h
iocs_call: equ	0fffe8h
;
;--- Registres materiels ---------------------------------------------------
ko_lo:	equ	0f0h		;sortie de balayage clavier, poids faible
ko_hi:	equ	0f1h		;sortie de balayage clavier, poids fort
ki_in:	equ	0f2h		;entree clavier
imr_p:	equ	0fbh		;masque d'interruption (IMR)
bp_p:	equ	0ech		;registre de base BP
keym:	equ	04h		;bit KEY du masque d'interruption
;
;--- Controleur LCD --------------------------------------------------------
lcd_cl:	equ	0a004h		;commande, moitie gauche
lcd_dl:	equ	0a006h		;donnee,   moitie gauche
lcd_cr:	equ	0a008h		;commande, moitie droite
lcd_dr:	equ	0a00ah		;donnee,   moitie droite
;
;--- Emplacements BASIC ----------------------------------------------------
text_ad: equ	0cbh		;adresse du bloc TEXT.BAS
data_ad: equ	0ceh		;adresse du bloc DATA.BAS
menu_vc: equ	0ffffdh		;vecteur de retour au MENU
;
;--- Marqueurs de bloc memoire ---------------------------------------------
blk_id:	equ	0fbh		;identifiant de bloc de fichier
;
;--- Macros ----------------------------------------------------------------
;
; Depose un caractere dans le tampon d'ecran pointe par Y.
	macro	putc,ch
	mv	a,ch
	mv	[y++],a
	endm
;
; Selectionne une colonne du clavier et laisse le resultat lisible en (ki_in).
; Le NOP est un delai de stabilisation : ne pas le retirer.
	macro	kscan,colonne
	mv	(ko_lo),colonne
	and	(ko_hi),$f8
	nop
	endm
;
;
	org	0be000h
;
	pre_on
;
;-----------------------------------------------------------
;       DEVICE-DRIVER INSTALLER
;-----------------------------------------------------------
;-----------------------------------------------------------
;       DEVICE-DRIVER INSTALLER  (modele du template : ajout en fin)
;-----------------------------------------------------------
start:
;  (0) lire l'argument de CALL : la chaine "-u" (ou "-U") lance la
;      desinstallation, sinon on installe. L'argument doit etre entre
;      GUILLEMETS (syntaxe BASIC), comme pour UUENCODE :
;          CALL &BE000          -> installe
;          CALL &BE000 "-u"     -> desinstalle
;      La ligne de commande (avec ses guillemets) est en tete de la pile U ;
;      le scan saute le guillemet ouvrant et cherche "-u".
	popu	x			; x = pointeur de ligne (empile par CALL)
	mv	(0),0			; (0) = 0 : installer ; sinon : desinstaller
sc_arg:	mv	a,[x++]
	cmp	a,0
	jrz	sc_done
	cmp	a,0dh
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
;      RESTITUER a BASIC le pointeur de ligne AVANCE au-dela de l'argument
;      (protocole UUENCODE : popu a l'entree, pushu du pointeur avance a la
;      sortie). Sans ce pushu, BASIC ne retrouve pas ou reprendre -> 'Syntax
;      error' au retour d'un CALL suivi d'un argument.
	dec	x			; revenir sur le terminateur de l'argument
	pushu	x
	mv	a,(0)
	cmp	a,0
	jrz	sc_install
	jp	uninstall
sc_install:
;  (1) banniere
	mv	x,msg0
	mv	y,btm0-msg0
	mv	(cl),0
	mv	il,4
	callf	fcs_call
;  sauver le vecteur clavier et IMR (le pilote les restaure)
	mv	x,[keyvct]
	mv	[save_vct],x
	mv	a,(imr_p)
	mv	[save_imr],a
;  (2) compacter S1: (regrouper l'espace libre en fin de zone)
	mv	(cl),6
	mv	(ch),0
	mv	i,47h
	callf	iocs_call
;  (3) parcourir jusqu'a la FIN des blocs ; detecter un doublon par le nom
	mv	x,[s1_top]
	mv	y,[x+12h]
	add	x,y
walk:	mv	a,[x]
	cmp	a,blk_id
	jrnz	walk_end
	mv	y,block_top
	mv	il,12
	pushu	x
	callf	stricmp
	popu	x
	jrz	exit2
	mv	y,[x+11h]
	add	x,y
	jr	walk
walk_end:
	mv	(10),x			; destination = fin des blocs (ajout en fin)
;  (4) controle memoire : libre = bas_de_S1 - fin_des_blocs >= taille
	mv	y,[s1_btm]
	dec	y
	sub	y,x
	mv	(16),y
	mv	y,block_bottom-block_top
	cmpp	(16),y
	jrc	exit3
;  (5) sauver le handler device #11 d'origine (pour le chainage de 'RG3:')
	mv	x,d_link
	mv	a,0
	mv	[iocs_found],a
srch:	mv	y,x
	mv	x,[x]
	inc	x
	jrz	srch_end
	dec	x
	mv	a,[x+3]
	cmp	a,11
	jrnz	srch
	mv	x,[x+5]
	mv	[iocs_eleven],x
	mv	a,1
	mv	[iocs_found],a
srch_end:
;  (6) chainer le nouveau device en tete de la liste IOCS
	mv	x,[d_link]
	mv	[header],x
	mv	x,(10)
	mv	il,iocs_header-block_top
	add	x,il
	mv	[d_link],x
;  (7) relocation (mecanisme de REGISTER : site pN, l'installateur lit [pN+1])
	mv	x,modify_table
init_3:	mv	y,[x++]
	inc	y
	jrz	modify_end
	pushu	x
	mv	x,[y]
	pushu	y
	mv	y,block_top
	sub	x,y
	mv	y,(10)
	add	x,y
	popu	y
	mv	[y],x
	popu	x
	jr	init_3
modify_end:
;  (8) copier le pilote en fin de chaine, puis ecrire le terminateur $ff
	mv	i,block_bottom-block_top
	mv	y,(10)
	mv	x,block_top
init_5:	mv	a,[x++]
	mv	[y++],a
	dec	i
	jrnz	init_5
	mv	a,0ffh
	mv	[y],a
;  (9) accrocher le vecteur clavier au handler du pilote (adresse relocalisee)
	pushu	imr
	mv	x,int_entry-block_top
	mv	y,(10)
	add	x,y
	mv	[keyvct],x
	popu	a
	or	a,keym
	pushu	a
	popu	imr
;  succes : aucun fichier decale -> aucun recalage BASIC
	mv	x,msg1
	mv	y,btm1-msg1
	mv	(cl),0
	mv	il,4
	callf	fcs_call
	rc
	retf
;  erreurs : message + retour (carry), sans toucher a BASIC
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
;  helper : comparaison de chaine sur IL octets
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
;  messages
msg0:	db	'REGISTER3 (template)',13,10
btm0:
msg1:	db	'Installed.',13,10
btm1:
msg2:	db	'Error: already exist.',13,10
btm2:
msg3:	db	'Error: not enough memory.',13,10
btm3:

;-----------------------------------------------------------
;       DESINSTALLATEUR  (CALL &BE000 -u)
;
;  Defait ce que l'installation a fait : delie le device de la chaine et
;  restaure le vecteur clavier depuis la copie sauvegardee dans le pilote.
;  Verifie d'abord etre au SOMMET de la pile de hooks (le vecteur clavier
;  pointe-t-il encore vers NOTRE handler ?) : sinon un pilote a ete charge
;  ensuite et le retrait casserait sa chaine -> refus propre.
;-----------------------------------------------------------
uninstall:
	mv	x,msg_un
	mv	y,btm_un-msg_un
	mv	(cl),0
	mv	il,4
	callf	fcs_call
;  chercher notre device dans la chaine, en gardant le predecesseur
	mv	y,d_link		; y = emplacement du pointeur vers l'en-tete courant
un_find:
	mv	x,[y]
	inc	x
	jrz	un_notfound		; -1 : fin de chaine, non trouve
	dec	x
	mv	(10),x			; (10) = en-tete courant
	mv	(13),y			; (13) = predecesseur (emplacement du pointeur)
	mv	il,8
	add	x,il			; x = en-tete + 8 = nom de device
	mv	y,drv_str
	mv	il,4
	callf	stricmp
	mv	x,(10)
	mv	y,(13)
	jrz	un_found
	mv	y,x			; avancer : predecesseur = en-tete courant
	jr	un_find
un_found:
;  x = notre en-tete ; (13) = predecesseur
;  securite : le vecteur clavier pointe-t-il encore vers NOTRE int_entry ?
	mv	ba,int_entry-iocs_header
	add	x,ba			; x = notre int_entry (dans la copie)
	mv	y,[keyvct]
	sub	y,x
	jrnz	un_notsafe		; non -> un autre pilote a hooke apres nous
;  restaurer le vecteur clavier depuis la copie (save_vct)
	mv	x,(10)
	mv	ba,save_vct-iocs_header
	add	x,ba			; x = save_vct (dans la copie)
	mv	x,[x]			; x = vecteur clavier d'origine
	mv	[keyvct],x
;  delier de la chaine : [predecesseur] = notre lien suivant
	mv	x,(10)
	mv	x,[x]			; x = notre lien suivant (3 premiers octets de l'en-tete)
	mv	y,(13)
	mv	[y],x
;  rendre le bloc supprimable par KILL : effacer les bits Device+Protect de
;  l'attribut du bloc (offset 0Ch). Le pilote n'etant plus dans la chaine des
;  devices, il redevient un simple fichier que l'utilisateur retire par
;  KILL "S1:REGIST3.SYS" ; la ROM libere alors la memoire (recompactage).
	mv	x,(10)			; en-tete IOCS = block_top + 22h
	mv	ba,022h-0ch		; distance en-tete -> octet d'attribut du bloc
	sub	x,ba
	mv	a,[x]
	and	a,0f3h			; ~0Ch : oter Device & Protect
	mv	[x],a
;  succes
	mv	x,msg_ok
	mv	y,btm_ok-msg_ok
	mv	(cl),0
	mv	il,4
	callf	fcs_call
	rc
	retf
un_notsafe:
	mv	x,msg_ns
	mv	y,btm_ns-msg_ns
	jr	un_err
un_notfound:
	mv	x,msg_nf
	mv	y,btm_nf-msg_nf
un_err:
	mv	(cl),0
	mv	il,4
	callf	fcs_call
	sc
	retf

msg_un:	db	'Uninstalling RG3:',13,10
btm_un:
msg_ok:	db	'Uninstalled.',13,10
	db	'KILL "S1:REGIST3.SYS" to free mem.',13,10
btm_ok:
msg_ns:	db	'Cannot: hooked by another.',13,10
btm_ns:
msg_nf:	db	'RG3: not installed.',13,10
btm_nf:
drv_str:	db	'RG3:'

block_top:
	db	blk_id,'REGIST3 SYS'		;block name
	db	25h				;block attr
	dw	0,0				;date,time
	dp	block_bottom - block_top	;block size
	dw	0
	dp	block_bottom - block_top	;file size
	dp	block_bottom - block_top	;block size
	dp	0,0
;
iocs_header:
header:	dp	0
number:	db	11
attr:	db	063h
adrs:	dp	iocs_entry
	db	'RG3:',0
;
iocs_found:
	db	0		;flag of following icos.11 adress effective
iocs_eleven:
	dp	0		;original  iocs No.11 adress
;
;
iocs_entry:
	pushu	a
	mv	a,il
	cmp	a,40h
	jrz	iocs_40h
	popu	a
;
org_iocs_call:
	pushu	a
p0:	mv	a,[iocs_found]
	cmp	a,0
	popu	a
	jrz	no_org_iocs
	pushu	x
p1:	mv	x,return_adrs
	pushs	x
p2:	mv	x,[iocs_eleven]
	pushs	x
	popu	x
	retf
return_adrs:
	retf
;
no_org_iocs:
	rc
	retf
;
iocs_40h:
	popu	a
	mv	x,[keyvct]
p3:	mv	y,int_entry
	sub	x,y
	jrz	iocs40a
	pushu	imr
p4:	mv	x,int_entry
	mv	[keyvct],x
	popu	a
	or	a,keym
	pushu	a
	popu	imr
iocs40a:rc
	retf
;
;
int_entry:
	mv	(ko_lo),01h		;strove for key matrix
	and	(ko_hi),$f8
	nop
	mv	a,(ki_in)
	and	a,0c0h
	xor	a,0c0h			;key data check (SHIFT+CTRL)
	jrz	begin
	mv	(ko_lo),0
	and	(ko_hi),$f8
;
	pushu	x
	pushu	a
p5:	mv	a,[save_imr]
	and	a,keym
	jrnz	jump_org_int
	popu	a
	popu	x
	rc
	retf
;
jump_org_int:
p6:	mv	x,[save_vct]
	pushs	x
	popu	a
	popu	x
	retf
;
;
begin:
	pushu	imr
	mv	[--u],(bp_p)		;BP save
	mv	(bp_p),0h		;BP=0
;
	pre_off
;
	mvp	[--u],(0)
	mvp	[--u],(3)
	mvp	[--u],(6)
;
p7:	callf	save_vram		;VRAM save
;
p8:	callf	get_regs
;
p9:	callf	disp_regs
;
waitky:	kscan	02h
	mv	a,(ki_in)
	cmp	a,04h
	jrz	disp_s			;[S] key
	kscan	08h
	mv	a,(ki_in)
	cmp	a,02h
	jrz	disp_u			;[U] key
	kscan	04h
	mv	a,(ki_in)
	cmp	a,01h
	jrz	disp_r			;[R] key
	kscan	01h
	mv	a,(ki_in)
	and	a,0c0h
	xor	a,0c0h
	jrz	waitky
;
p10:	callf	restore_vram		;VRAM restore
;
	mvp	(6),[u++]
	mvp	(3),[u++]
	mvp	(0),[u++]
	mv	(bp_p),[u++]		;restore BP
	popu	imr
	retf
;
disp_s:
p11:	callf	s_rgstr
	jr	waitky
;
disp_u:
p12:	callf	u_rgstr
	jr	waitky
;
disp_r:
p13:	callf	disp_regs
	jr	waitky
;
;
disp_regs:
p14:	callf	clrscrn
;
p15:	mv	x,stacks
p16:	mv	y,chars
;
	mv	a,'P'			;'PS:PC=xxxxxx '
	mv	[y++],a
	putc	'S'
	putc	':'
	putc	'P'
	putc	'C'
	putc	'='
	mv	a,[x+4]
p17:	callf	hexwrite
	mv	a,[x+3]
p18:	callf	hexwrite
	mv	a,[x+2]
p19:	callf	hexwrite
	putc	' '
;
	mv	a,'S'			;'S=xxxxxx '
	mv	[y++],a
	putc	'='
	mv	a,[x+7]
p20:	callf	hexwrite
	mv	a,[x+6]
p21:	callf	hexwrite
	mv	a,[x+5]
p22:	callf	hexwrite
	putc	' '
;
	mv	a,'U'			;'U=xxxxxx'
	mv	[y++],a
	putc	'='
	mv	a,[x+21]
p23:	callf	hexwrite
	mv	a,[x+20]
p24:	callf	hexwrite
	mv	a,[x+19]
p25:	callf	hexwrite
;
p26:	mv	y,chars+40
;
	mv	a,'X'			;'X=xxxxxx '
	mv	[y++],a
	putc	'='
	mv	a,[x+14]
p27:	callf	hexwrite
	mv	a,[x+13]
p28:	callf	hexwrite
	mv	a,[x+12]
p29:	callf	hexwrite
	putc	' '
;
	mv	a,'Y'			;'Y=xxxxxx '
	mv	[y++],a
	putc	'='
	mv	a,[x+11]
p30:	callf	hexwrite
	mv	a,[x+10]
p31:	callf	hexwrite
	mv	a,[x+9]
p32:	callf	hexwrite
	putc	' '
;
	mv	a,'I'			;'I=xxxx '
	mv	[y++],a
	putc	'='
	mv	a,[x+16]
p33:	callf	hexwrite
	mv	a,[x+15]
p34:	callf	hexwrite
	putc	' '
;
	mv	a,'B'			;'BA=xxxx'
	mv	[y++],a
	putc	'A'
	putc	'='
	mv	a,[x+18]
p35:	callf	hexwrite
	mv	a,[x+17]
p36:	callf	hexwrite
;
p37:	mv	y,chars+80
;
	mv	a,'F'			;'FLAGS=xx '
	mv	[y++],a
	putc	'L'
	putc	'A'
	putc	'G'
	putc	'S'
	putc	'='
	mv	a,[x+1]
p38:	callf	hexwrite
	putc	' '
;
	mv	a,'B'			;'BP=xx '
	mv	[y++],a
	putc	'P'
	putc	'='
	mv	a,[x+8]
p39:	callf	hexwrite
	putc	' '
;
	mv	a,'I'			;'IMR=xx'
	mv	[y++],a
	putc	'M'
	putc	'R'
	putc	'='
	mv	a,[x]
p40:	callf	hexwrite
;
p41:	callf	mk_scrn
	retf
;
mk_scrn:
p42:	mv	x,chars
p43:	mv	y,VRAM
	mv	il,160
;
d0:	mv	ba,0
	mv	a,[x++]
	sub	a,20h
	pushu	x
	mv	x,[0bfc90h]	;font pointer
	add	a,a
	add	x,a
	add	a,a
	add	x,a
	pushu	il
;
	mv	il,6
d1:	mv	a,[x++]
	mv	[y++],a
	dec	il
	jrnz	d1
;
	popu	il
	popu	x
	dec	il
	jrnz	d0
;
p44:	mv	x,VRAM
p45:	callf	disp
	retf
;
;
get_regs:
p46:	mv	y,stacks
	mv	x,s
	inc	x
	inc	x			;RETURN ADRS of "get_regs"
	inc	x
	inc	x
	inc	x			;RETURN ADRS = F2098h  in INT_SERVICE
	inc	x
	mv	a,[x++]			;IMR
	mv	[y++],a
	mv	a,[x++]			;FLAGS
	mv	[y++],a
	mvp	(0),[x++]		;PS:PC
	mvp	[y++],(0)
	mv	[y++],x			;S-STACK register
;
	mv	x,u
	mv	il,9
	add	x,i			;(0) .. (8)
	mv	a,[x++]			;BP
	mv	[y++],a
	mv	a,[x++]			;IMR (already masked ,bit7=0)
	mv	a,[x++]			;isr/issr mask pattern (key=FBh)
	mvp	(0),[x++]		;Y
	mvp	[y++],(0)
	mvp	(0),[x++]		;X
	mvp	[y++],(0)
	mvw	(0),[x++]		;I
	mvw	[y++],(0)
	mvw	(0),[x++]		;BA
	mvw	[y++],(0)
	mv	[y++],x			;U-STACK register
	retf
;
;
s_rgstr:
p47:	callf	clrscrn
;
p48:	mv	y,chars
p49:	mv	x,stacks
	mv	x,[x+5]
	mv	(4),4
dsp00:	mv	il,8
	mv	(0),x
	mv	a,(2)
p50:	callf	hexwrite
	mv	a,(1)
p51:	callf	hexwrite
	mv	a,(0)
p52:	callf	hexwrite
	putc	' '
dsps0:	mv	a,[x++]
p53:	callf	hexwrite
	putc	' '
	dec	il
	jrnz	dsps0
	mv	ba,9
	add	y,ba
	dec	(4)
	jrnz	dsp00
;
p54:	callf	mk_scrn
	retf
;
;
u_rgstr:
p55:	callf	clrscrn
;
p56:	mv	y,chars
p57:	mv	x,stacks
	mv	x,[x+19]
	mv	(4),4
	jr	dsp00
;
;
clrscrn:
p58:	mv	y,chars
	mv	a,' '
	mv	il,160
clrs0:	mv	[y++],a
	dec	il
	jrnz	clrs0
	retf
;
;
hexwrite:
	pushu	a
	swap	a
	and	a,0fh
	cmp	a,10
	jrc	hx0
	add	a,'A'-'0'-10
hx0:	add	a,'0'
	mv	[y++],a
	popu	a
	and	a,0fh
	cmp	a,10
	jrc	hx1
	add	a,'A'-'0'-10
hx1:	add	a,'0'
	mv	[y++],a
	retf
;
;
save_vram:
p59:	mv	x,VRAM2			;VRAM save
p60:	callf	vcopy
	retf
;
;
restore_vram:
p61:	mv	x,VRAM2			;VRAM restore
p62:	callf	disp
	retf
;
;
disp:					;transfer virtual VRAM --> LCD
	mv	(3),4
	mv	(0),[(0e6h)+8]
	or	(0),0b8h
l0:	mv	[lcd_cl],(0)
	mv	[lcd_cr],(0)
	mvw	(1),3840h
	mv	[lcd_cl],(1)
	mv	[lcd_cr],(1)
l5:	mv	a,[x++]
	mv	[lcd_dl],a
	dec	(1)
	jrnz	l5
l6:	mv	a,[x++]
	mv	[lcd_dr],a
	dec	(2)
	jrnz	l6
	mvw	(1),3840h
	mv	[lcd_cl],(1)
	mv	[lcd_cr],(1)
	mv	a,(0)
	sub	a,4
	or	a,0b8h
	mv	[lcd_cl],a
	mv	[lcd_cr],a
	mv	il,78h
	add	x,il
l1:	mv	a,[--x]
	mv	[lcd_dl],a
	dec	(1)
	jrnz	l1
l2:	mv	a,[--x]
	mv	[lcd_dr],a
	dec	(2)
	jrnz	l2
	add	x,il
	sub	(0),7
	or	(0),0b8h
	dec	(3)
	jrnz	l0
	retf
;
vcopy:					;transfer LCD --> virtual VRAM
	mv	ba,0
	mv	(3),10h
	mv	(0),[(0e6h)+8]
	mvp	(4),lcd_cl
	mvw	(1),0100h
	mv	il,40h
vcpy1:
	mv	a,(0)
	add	a,(1)
	or	a,0b8h
	mv	[(04)],a
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	mv	a,40h
	mv	[(04)],a
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	add	(4),03h
	mv	a,[(4)]
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
vcpy2:	mv	a,[(4)]
	mv	[x++],a
	test	(2),01h
	jrnz	vcpy3
	dec	x
	dec	x
vcpy3:	dec	il
	jrnz	vcpy2
	sub	(4),03h
	mv	a,(3)
	test	a,02h
	jrnz	case1
case0:
	test	a,01h
	jrnz	case01
case00:	
	mv	(4),08h
	mv	il,38h
	mv	(2),01h
	jr	vcpy4
case01:	
	sub	(1),03h
	mv	il,40h
	mv	(2),01h
	mv	a,41h
	add	x,a
	jr	vcpy4
case1:
	test	a,01h
	jrnz	case11
case10:
	mv	(4),04h
	mv	il,40h
	mv	(2),0h
	mv	a,78h
	add	x,a
	jr	vcpy4
case11:
	add	(1),4
	mv	il,38h
	mv	(2),0
	mv	a,37h
	add	x,a
;
vcpy4:	dec	(3)
	jrnz	vcpy1
	retf
;
;
;
save_vct:
	dp	0		;original  key interrupt vector
save_imr:
	db	0		;original  IMR
;
stacks:	ds	22,0
chars:	ds	160,0
VRAM:	ds	960,0
VRAM2:	ds	960,0
;
;
block_bottom:
;
;-----------------------------------------------------------
;       DEVICE-DRIVER RELOCATE-TABLE
;-----------------------------------------------------------
modify_table:
	dp	attr,p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15
	dp	p16,p17,p18,p19,p20,p21,p22,p23,p24,p25,p26,p27,p28,p29
	dp	p30,p31,p32,p33,p34,p35,p36,p37,p38,p39,p40,p41,p42,p43
	dp	p44,p45,p46,p47,p48,p49,p50,p51,p52,p53,p54,p55,p56,p57
	dp	p58,p59,p60,p61,p62
	dp	-1
modify_end_tbl:
;
;---------------------------------------------------------------------------
;	VERIFICATIONS A L'ASSEMBLAGE
;
;	Elles n'emettent aucun octet : elles ne font qu'interrompre
;	l'assemblage si une hypothese du programme cesse d'etre vraie.
;---------------------------------------------------------------------------
;
; La table contient attr, p0..p62 et le terminateur -1, soit 65 entrees de
; 3 octets. Si ce total change sans que ce soit voulu, c'est qu'une entree a
; ete ajoutee ou perdue par megarde.
	assert	modify_end_tbl-modify_table = 65*3,'table de relocation : nombre d entrees inattendu'
;
; Chaque point de relocation doit se trouver a l'interieur du pilote : un pN
; hors bloc serait corrige a tort lors de la copie.
	assert	p0 >= block_top,'p0 hors du bloc pilote'
	assert	p62 < block_bottom,'p62 hors du bloc pilote'
	assert	attr >= block_top,'attr hors du bloc pilote'
;
; Le pilote est copie tel quel : sa taille doit rester non nulle et tenir dans
; ce que l'installeur sait deplacer.
	assert	block_bottom > block_top,'taille du pilote nulle'
;
	end

