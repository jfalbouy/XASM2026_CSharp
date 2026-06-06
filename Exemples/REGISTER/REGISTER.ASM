;
;	Register checker   for PC-E500/1480U  Ver 1.2
;		(c)1990,1992   E. Kako (JM2WGN)
;
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
	org	0be000h
;
	pre_on
;
;-----------------------------------------------------------
;       DEVICE-DRIVER INSTALLER
;-----------------------------------------------------------
start:
	mv	x,msg0				;DISPLAY *TITLE* MESSAGE
	mv	y,btm0-msg0			;Longueur du texte à afficher
	mv	(cl),0				;Writing a block of the file
	mv	il,4				;x est l'adresse de la chaine
	callf	fcs_call		;affichage
;
	mv	x,[keyvct]			;lecture du vecteur d'interruption du clavier
	mv	[save_vct],x		;sauvegarde du vecteur d'origine
	mv	a,(0fbh)			;lecture de IMR
	mv	[save_imr],a		;sauvegarde de la valeur
;
	mv	(cl),6				;compress the space in each memory block
	mv	(ch),0				;"S1:"
	mv	i,47h				;lancement de la procédure
	callf	iocs_call		;compress memory
;
	mv	x,[s1_top]			;top of "S1:"
	mv	y,[x+12h]			;data block or lead address, pointe sur FB ou FF
	add	x,y					;pointer sur le début du block
	mv	(10),x				;sauvegarde de la valeur
;
init_1:	mv	a,[x]			;SEARCH  end of 'device driver'
	cmp	a,0fbh				;lecture de l'identification du nom de block
	jrnz	block_end		;saut si fin de lecture des blocks
	mv	y,block_top			;se positionner sur le début du header du nouveau driver
	mv	il,12				;nombre de caractères à lire
	pushu	x				;sauvegarde de l'adresse du header en cours
	callf	stricmp			;comparer celui installé vs celui à installer	
	popu	x				;récupérer l'adresse du header
	jrz	exit2				;"ERROR: ALREADY EXIST!!"
	mv	a,[x+12]			;lecture de l'attribut du driver: $25 (Protected)
	test	a,0ch			;check ATTR (Device & Protect)
	jrz	set_start			;saut si c'est le cas
	mv	y,[x+11h]			;lire la longueur du block jusqu'au prochain bloc
	add	x,y					;se positionner sur le début du prochain bloc
	jr	init_1				;boucler sur la lecteur des drivers blocks
;
set_start:					
	mv	(10),x				;sauvegarde de l'adresse du bloc du nouveau header
init_2:	mv	a,[x]			;SEARCH  end of 'memory block'
	cmp	a,0fbh				;la fin des blocs est indiquée par $FF
	jrnz	block_end		;saut si on a atteint le dernier bloc
	mv	y,[x+11h]			;lire la longueur du block jusqu'au prochain bloc
	add	x,y					;se positionner sur le début du prochain bloc
	jr	init_2				;boucler sur la lecteur des drivers blocks
;
block_end:
	mv	(13),x				;sauvegarde de l'adresse du dernier bloc
	mv	y,[s1_btm]			;end of "S1:" + 1
	dec	y					;se positionner sur l'adresse de fin de "S1:"
	sub	y,x					;longueur du bloc
	mv	(16),y				;sauvegarde de l'adresse
	mv	y,block_bottom - block_top	;longueur du nouveau driver
	cmpp	(16),y			;sauvegarde de l'adresse
	jrc	exit3				;"ERROR: NOT enough memory!!"
;
	mv	x,d_link			;device link pointer
	mv	a,0					
	mv	[iocs_found],a		;sauvegarde du flag
srch:	mv	y,x				;SEARCH original  iocs No.11
	mv	x,[x]				;si $FF alors fin des drivers, inc x = 0
	inc	x
	jrz	srch_end			;si zéro alors fin des drivers
	dec	x					;revenir à la valeur de départ
	mv	a,[x+3]				;lire le device number
	cmp	a,11				;DEVICE NUMBER is No.11
	jrnz	srch			;boucler tant que non atteint
	mv	x,[x+5]				;lecture de l'adresse de IOCS correspondant
	mv	[iocs_eleven],x		;sauvegarde de cette adresse
	mv	a,1					;flag = 1 car trouvé le bon device number
	mv	[iocs_found],a		;sauvegarde du flag
srch_end:
;
	mv	x,[d_link]			;device driver pointer
	mv	[header],x			;sauvegarde de l'ancienne adresse
	mv	x,(10)				;lecture de l'adresse du 1° header
	mv	il,022h				;
	add	x,il
	mv	[d_link],x			; Put into device link
;
;Réallocation des adresses avant copie du nouveau driver
	mv	x,modify_table		;se positionner sur la table des vecteurs
init_3:	mv	y,[x++]			;lire une adresse dans la table	
	inc	y					;-1 indique la fin de la table sinon adresse réelle à modifier
	jrz	modify_end			;saut si fin de table
	pushu	x				;sauvegarde de l'indice prochain de la table
	mv	x,[y]				;lire l'adresse à modifier
	pushu	y				;sauvegarde de l'adresse lue dans la table
	mv	y,block_top			;se positionner sur le début du nouveau header driver
	sub	x,y					;nombre d'octets de décalage
	mv	y,(10)				;récupérer l'adresse de début du programme	
	add	x,y					;calcul de la nouvelle adresse fonction de son implantation
	popu	y				;
	mv	[y],x				;implantation de l'adresse recalculée
	popu	x				;se positionner sur l'indice suivant
	jr	init_3				;boucler tant que non fin de table
;
modify_end:
	mv	x,(13)				;adresse du dernier block header
	mv	y,(10)				;adresse du premier IOCS header
	sub	x,y					;longueur du bloc à déplacer
	mv	(16),x				;sauvegarde de la valeur	
	mv	x,(13)				;adresse du dernier block header
	mv	y,x					;affectation dans y
	mv	ba,block_bottom - block_top		;taille du driver à installer
	add	y,ba				;calcul de la nouvelle adresse
	inc	x					;se positionner en +1
	inc	y					;se positionner en +1
;
init_6:	mv	a,[--x]			;move memory block
	mv	[--y],a				;
	mv	a,(16)				;lecture du compteur poids fort
	sub	a,1					;décrémentation du compteur
	mv	(16),a				;sauvegarde du compteur
	jrnc	init_6			;boucler tant que pas tout lu
	mv	a,(17)				;lecture du compteur poids moyen
	sub	a,1					;décrémentation du compteur
	mv	(17),a				;sauvegarde du compteur
	jrnc	init_6			;boucler tant que pas tout lu
	mv	a,(18)				;lecture du compteur poids faible
	sub	a,1					;décrémentation du compteur
	mv	(18),a				;sauvegarde du compteur
	jrnc	init_6			;boucler tant que pas tout lu
;
	mv	i,block_bottom - block_top		;taille du code à copier
	mv	y,(10)				;adresse du premier IOCS header
	mv	x,block_top			;adresse du header du nouveau driver
init_5:	mv	a,[x++]			;transfer device driver
	mv	[y++],a				;copie du code du nouveau driver
	dec	i					;décrémentation du compteur
	jrnz	init_5			;boucler tant que pas tout lu
;
exit:
	pushu	imr				;sauvegarde du registre du masque d'interruption
	mv	x,int_entry - block_top		;taille pour atteindre l'adresse du nouveau vecteur d'interruption clavier
	mv	y,(10)				;adresse du premier IOCS header
	add	x,y					;adresse du nouveau vecteur d'interruption
	mv	[keyvct],x			;sauvegarde de cette adresse
	popu	a				;récupérer IMR dans a
	or	a,04h				;masquer KEYM
	pushu	a				;sauvegarde de la nouvelle valeur
	popu	imr				;et la remettre dans IMR
;
exit1:	mv	x,msg1			;DISPLAY "SUCCESS" MESSAGE
	mv	y,btm1-msg1
	jr	exit4
;
exit2:	mv	x,msg2			;DISPLAY "EXIST ERROR" MESSAGE
	mv	y,btm2-msg2
	jr	exit4
;
exit3:	mv	x,msg3			;DISPLAY "MEMORY ERROR" MESSAGE
	mv	y,btm3-msg3
;
exit4:	mv	(cl),0
	mv	il,4
	callf	fcs_call
;
;
remake_slot:
	mv	x,[baswrk]			;BASIC WORK Address
	mv	a,[x+72h]
	cmp	a,0					;BTEXT$ is "S1:" ????
	jrnz	remake_data
;
remake_text:
	mv	y,73h
	add	y,x					;BTEXT$ Address
	pushu	y
	mv	x,[s1_top]			;top of "S1:"
	mv	y,[x+12h]
	add	x,y
	popu	y
text1:	mv	a,[x]			;SEARCH  block 'TEXT.BAS'
	cmp	a,0fbh
	jrnz	text_err
	mv	il,11
	pushu	y
	pushu	x
	inc	x
	callf	stricmp
	popu	x
	jrz	text2
	mv	y,[x+11h]
	add	x,y		;next block
	popu	y
	jr	text1
text2:	popu	y
	mv	(0cbh),x			;set "TEXT.BAS"  Address
;
remake_data:
	mv	x,[baswrk]			;BASIC WORK Address
	mv	a,[x+7eh]
	cmp	a,0					;BDATA$ is "S2:" ????
	jrnz	remake_end
;
	mv	y,7fh				;BDATA$ Address
	add	y,x
	pushu	y
	mv	x,[s1_top]			;top of "S1:"
	mv	y,[x+12h]
	add	x,y
	popu	y
data1:	mv	a,[x]			;SEARCH  block 'DATA.BAS'
	cmp	a,0fbh
	jrnz	data_err
	mv	il,11
	pushu	y
	pushu	x
	inc	x
	callf	stricmp
	popu	x
	jrz	data2
	mv	y,[x+11h]
	add	x,y					;next block
	popu	y
	jr	data1
data2:	popu	y
	mv	(0ceh),x			;set "DATA.BAS"  Address
remake_end:
	rc
	retf
;
text_err:					;remake failed.
data_err:
	mv	x,msg4				;"--- PUSH ANY KEY ---"
	mv	y,btm4-msg4
	mv	(cl),0
	mv	il,4
	callf	fcs_call
;
	pushu	imr
kw1:	mv	(0f0h),$ff		;KEY WAIT   until any key
	and	(0f1h),$f8
	nop
	nop
	mv	a,($f2)
	cmp	a,$00				;no key ??
	jrz	kw1
	mv	(0f0h),$00
	and	(0f1h),$f8
	popu	imr
;
	mv	x,[0ffffdh]			;jmp to MENU
	jp	x
;
stricmp:
	mv	(0),[x++]			;compare string (length = IL bytes )
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
;
msg0:	db	'REGISTER V1.2 by E.Kako',13,10
btm0:
msg1:	db	'Installed.',13,10
btm1:
msg2:	db	'Error: REGISTER already exist.',13,10
btm2:
msg3:	db	'Error: Not enough memory.',13,10
btm3:
msg4:	db	'--- PUSH ANY KEY ---',13,10
btm4:
;
;-----------------------------------------------------------
;       DEVICE-DRIVER
;-----------------------------------------------------------
block_top:
	db	0fbh,'REGISTERSYS'		;block name
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
	db	'REG:',0
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
	or	a,04h
	pushu	a
	popu	imr
iocs40a:rc
	retf
;
;
int_entry:
	mv	(0f0h),01h		;strove for key matrix
	and	(0f1h),$f8
	nop
	mv	a,(0f2h)
	and	a,0c0h
	xor	a,0c0h			;key data check (SHIFT+CTRL)
	jrz	begin
	mv	(0f0h),0
	and	(0f1h),$f8
;
	pushu	x
	pushu	a
p5:	mv	a,[save_imr]
	and	a,04h
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
	mv	[--u],(0ech)		;BP save
	mv	(0ech),0h		;BP=0
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
waitky:	mv	(0f0h),02h
	and	(0f1h),$f8
	nop
	mv	a,(0f2h)
	cmp	a,04h
	jrz	disp_s			;[S] key
	mv	(0f0h),08h
	and	(0f1h),$f8
	nop
	mv	a,(0f2h)
	cmp	a,02h
	jrz	disp_u			;[U] key
	mv	(0f0h),04h
	and	(0f1h),$f8
	nop
	mv	a,(0f2h)
	cmp	a,01h
	jrz	disp_r			;[R] key
	mv	(0f0h),01h
	and	(0f1h),$f8
	nop
	mv	a,(0f2h)
	and	a,0c0h
	xor	a,0c0h
	jrz	waitky
;
p10:	callf	restore_vram		;VRAM restore
;
	mvp	(6),[u++]
	mvp	(3),[u++]
	mvp	(0),[u++]
	mv	(0ech),[u++]		;restore BP
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
	mv	a,'S'
	mv	[y++],a
	mv	a,':'
	mv	[y++],a
	mv	a,'P'
	mv	[y++],a
	mv	a,'C'
	mv	[y++],a
	mv	a,'='
	mv	[y++],a
	mv	a,[x+4]
p17:	callf	hexwrite
	mv	a,[x+3]
p18:	callf	hexwrite
	mv	a,[x+2]
p19:	callf	hexwrite
	mv	a,' '
	mv	[y++],a
;
	mv	a,'S'			;'S=xxxxxx '
	mv	[y++],a
	mv	a,'='
	mv	[y++],a
	mv	a,[x+7]
p20:	callf	hexwrite
	mv	a,[x+6]
p21:	callf	hexwrite
	mv	a,[x+5]
p22:	callf	hexwrite
	mv	a,' '
	mv	[y++],a
;
	mv	a,'U'			;'U=xxxxxx'
	mv	[y++],a
	mv	a,'='
	mv	[y++],a
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
	mv	a,'='
	mv	[y++],a
	mv	a,[x+14]
p27:	callf	hexwrite
	mv	a,[x+13]
p28:	callf	hexwrite
	mv	a,[x+12]
p29:	callf	hexwrite
	mv	a,' '
	mv	[y++],a
;
	mv	a,'Y'			;'Y=xxxxxx '
	mv	[y++],a
	mv	a,'='
	mv	[y++],a
	mv	a,[x+11]
p30:	callf	hexwrite
	mv	a,[x+10]
p31:	callf	hexwrite
	mv	a,[x+9]
p32:	callf	hexwrite
	mv	a,' '
	mv	[y++],a
;
	mv	a,'I'			;'I=xxxx '
	mv	[y++],a
	mv	a,'='
	mv	[y++],a
	mv	a,[x+16]
p33:	callf	hexwrite
	mv	a,[x+15]
p34:	callf	hexwrite
	mv	a,' '
	mv	[y++],a
;
	mv	a,'B'			;'BA=xxxx'
	mv	[y++],a
	mv	a,'A'
	mv	[y++],a
	mv	a,'='
	mv	[y++],a
	mv	a,[x+18]
p35:	callf	hexwrite
	mv	a,[x+17]
p36:	callf	hexwrite
;
p37:	mv	y,chars+80
;
	mv	a,'F'			;'FLAGS=xx '
	mv	[y++],a
	mv	a,'L'
	mv	[y++],a
	mv	a,'A'
	mv	[y++],a
	mv	a,'G'
	mv	[y++],a
	mv	a,'S'
	mv	[y++],a
	mv	a,'='
	mv	[y++],a
	mv	a,[x+1]
p38:	callf	hexwrite
	mv	a,' '
	mv	[y++],a
;
	mv	a,'B'			;'BP=xx '
	mv	[y++],a
	mv	a,'P'
	mv	[y++],a
	mv	a,'='
	mv	[y++],a
	mv	a,[x+8]
p39:	callf	hexwrite
	mv	a,' '
	mv	[y++],a
;
	mv	a,'I'			;'IMR=xx'
	mv	[y++],a
	mv	a,'M'
	mv	[y++],a
	mv	a,'R'
	mv	[y++],a
	mv	a,'='
	mv	[y++],a
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
	mv	a,' '
	mv	[y++],a
dsps0:	mv	a,[x++]
p53:	callf	hexwrite
	mv	a,' '
	mv	[y++],a
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
l0:	mv	[0a004h],(0)
	mv	[0a008h],(0)
	mvw	(1),3840h
	mv	[0a004h],(1)
	mv	[0a008h],(1)
l5:	mv	a,[x++]
	mv	[0a006h],a
	dec	(1)
	jrnz	l5
l6:	mv	a,[x++]
	mv	[0a00ah],a
	dec	(2)
	jrnz	l6
	mvw	(1),3840h
	mv	[0a004h],(1)
	mv	[0a008h],(1)
	mv	a,(0)
	sub	a,4
	or	a,0b8h
	mv	[0a004h],a
	mv	[0a008h],a
	mv	il,78h
	add	x,il
l1:	mv	a,[--x]
	mv	[0a006h],a
	dec	(1)
	jrnz	l1
l2:	mv	a,[--x]
	mv	[0a00ah],a
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
	mvp	(4),0a004h
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
;
	end

