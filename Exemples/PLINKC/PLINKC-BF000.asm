; =====================================================================
; PLINKC-BF000.asm  --  les lignes 20 a 62 de Samples/PLINKC.BAS, decodees
; =====================================================================
;
; Origine : les 43 lignes de remarque du BASIC, decodees selon le schema que
;           le stub des lignes 10-12 met en oeuvre (voir PLINKC-chargeur.asm) :
;           deux caracteres 'A'..'P' par octet, quartet de poids fort d'abord,
;           terminateur '$'. 3076 caracteres -> 1538 octets en 0BF000h.
;
; Ce n'est pas de l'uuencode : voir la note de PLINKC-chargeur.asm.
;
; VERIFICATION -- le decodage n'est pas une hypothese :
;
;   1. les 1538 octets sont IDENTIQUES a la section code de
;      Samples/PLINKC/PLINKC.OBJ (offset 16, apres l'en-tete IOCS) ;
;   2. cet en-tete annonce lui-meme code_size = 1538 et load_addr = 0BF000h,
;      soit exactement le compte obtenu et l'adresse ou le stub ecrit ;
;   3. ce fichier est identique, ligne pour ligne, au desassemblage de
;      PLINKC.OBJ par le meme outil.
;
; PLINKC (D. Mizobata, 1996, d'apres PLINK de N. Kon) fait partie du corpus de
; reference du depot : ReassemblyTests le reconstruit octet pour octet avec
; les deux assembleurs XASM.
;
; Produit par e500dasm --format raw --base BF000h --mode flow --entry BF000h
;                      --annotate
;
; REASSEMBLE : xasm2026-4 rend un fichier de 1554 octets IDENTIQUE OCTET POUR
; OCTET a Samples/PLINKC/PLINKC.OBJ, en-tete IOCS compris. La boucle est donc
; fermee : BASIC -> decodage -> desassemblage -> reassemblage -> l'objet
; d'origine.
; =====================================================================

; Constantes
txtbas:	equ	0CBh		; TEXT.BAS courant
datbas:	equ	0CEh		; DATA.BAS courant
bl:	equ	0D4h		; registre BL / BX bas
cl:	equ	0D6h		; registre CL / CX bas
ch:	equ	0D7h		; registre CH / CX haut
dl:	equ	0D8h		; registre DL / DX bas
iocsw:	equ	0E6h		; zone de travail IOCS : recopie du pointeur [0BFD17h] (3 octets) (manuel technique, IOCS Special Technique p85-86)
bp_ram:	equ	0ECh		; base pointer RAM interne
koh:	equ	0F1h		; Key Output Buffer haut (KOH) : pilote les pins KO8-KO15. Lecture/ecriture (manuel CPU p9-10)
ucr:	equ	0F7h		; UART Control Register : bit 7 BOE (break : force 0 sur TXD), bits 6-4 debit (0 reset, 1 300, 2 600, 3 1200, 4 2400, 5 4800, 6 9600, 7 19200 bps), bits 3-2 parite (00 paire, 01 impaire, 1x aucune), bit 1 longueur (0 : 8 bits, 1 : 7), bit 0 stop (0 : 1 bit, 1 : 2). 068h = 9600 8N1. Lecture/ecriture (manuel CPU p11-12)
usr:	equ	0F8h		; UART Status Register : bit 5 RXR caractere recu, bit 4 TXE emetteur au repos, bit 3 TXR tampon d'emission libre, bit 2 FE erreur de trame, bit 1 OE surcharge, bit 0 PE erreur de parite. LECTURE SEULE (manuel CPU p12)
txd:	equ	0FAh		; UART Transmit Buffer : le caractere a emettre ; peut etre ecrit pendant l'emission du precedent, TXR dit si le tampon est libre. ECRITURE SEULE (manuel CPU p14-15)
imr:	equ	0FBh		; Interrupt Mask Register : bit 7 IRM masque general, bit 6 EXM interruption EXTERNE (pin IRQ ; sur PC-E500 ce pin est cable au controleur de batterie, d'ou 'batterie faible' cote machine), bit 5 RXRM reception SIO, bit 4 TXRM emission SIO, bit 3 ONKM touche ON, bit 2 KEYM clavier, bit 1 STM timer secondes, bit 0 MTM timer millisecondes ; 0 interdit, 1 autorise. Une interruption empile l'IMR et met le bit 7 a 0. Lecture/ecriture (manuel CPU p15-16)
ssr:	equ	0FFh		; System Status Register : bit 3 ONK touche ON enfoncee, bit 2 RSF (1 : on sort d'un HALT/OFF, 0 : le pin RESET a ete active), bit 1 CI entree cassette, bit 0 TEST entree de test. LECTURE SEULE (manuel CPU p20-21)
DB_BF645:	equ	0BF645h		; donnees hors du code charge
DB_BF6C7:	equ	0BF6C7h		; donnees hors du code charge
DB_BF6CA:	equ	0BF6CAh		; donnees hors du code charge
DB_BF6CD:	equ	0BF6CDh		; donnees hors du code charge
s1_top:	equ	0BFC15h		; top of S1 (nom et libelle de REGISTER.ASM) ; lead address du slot 0 = lecteur S1:, 080000h sur PC-E500S (3 octets ; manuel technique, Parameter of memory block device)
d_link:	equ	0BFCA2h		; device link pointer / IOCSH
softint:	equ	0BFCBEh		; bit 7 = break, bit 6 = batterie faible
intv_sio_rx:	equ	0BFCD5h		; vecteur interruption reception SIO, ISR/IMR bit 5 RXRM ; reception d'un octet SIO terminee (manuel technique, List of interrupt factor p91-92)
s1_btm:	equ	0BFCDEh		; bottom of S1 (nom et libelle de REGISTER.ASM) ; le manuel dit "last address of slot 0 (S1:) + 1" et La Feuille du Sharp en fait le pointeur de la 1re zone de travail, la pile utilisateur U : trois lectures d'une meme frontiere, la fin de la zone de fichiers de S1: ou commencent les zones de travail
baswrk:	equ	0BFD0Eh		; BASIC work address
sio_baud:	equ	0BFD33h		; reglage de la liaison SIO : bits 6-4 = vitesse (001 300, 010 600, 011 1200, 100 2400, 101 4800, 110 9600 bauds ; 000 aucune), bits 3-2 = parite (00 paire, 01 impaire, 1x aucune), bit 1 = longueur (0 : 8 bits, 1 : 7), bit 0 = bits d'arret (0 : 1, 1 : 2) ; defaut 03Ch = 1200 bauds, sans parite, 8 bits, 1 stop. Apres modification, appeler la commande 043h du device 2 (manuel technique, Parameter Work du driver SIO p53)
fcs_call:	equ	0FFFE4h		; FCS call entry
iocs_call:	equ	0FFFE8h		; IOCS call entry
	org	0BF000h

start:
	pre	032h
	sub	(bp_ram),00Ch
	mv	il,000h
	call	SUB_BF112
	mv	x,0BF209h			; ref 0BF209h via x
	mv	il,000h
	call	SUB_BF14C
	mv	il,048h
	jpnc	LOC_BF10A
	mv	x,0BF1E0h			; ref 0BF1E0h via x
	mv	il,041h
	call	SUB_BF148
	mv	il,048h
	jpnc	LOC_BF10A
	mv	y,[d_link]
	mv	[plink_iocs],y			; ref 0BF201h via y
	pre	032h
	mv	(cl),009h
LOC_BF031:
	pre	032h
	inc	(cl)
	mv	il,001h
	call	SUB_BF14C
	jrnc	LOC_BF031
	pre	032h
	mv	[0BF204h],(cl)
	mv	il,047h
	call	SUB_BF148
	mv	x,[s1_top]
	mv	y,[x+012h]
LOC_BF04D:
	add	x,y
	mv	(000h),x
	mv	a,[x]
	cmp	a,0FBh
	jrnz	LOC_BF069
	mv	a,[x+00Ch]
	test	a,00Ch
LOC_BF05C:
	mv	y,[x+011h]
	jrnz	LOC_BF04D
	add	x,y
	mv	a,[x]
	cmp	a,0FBh
	jrz	LOC_BF05C
LOC_BF069:
	mv	i,003E4h
	mv	ba,(000h)
	add	ba,i
	mv	il,07Ch
	jrc	LOC_BF0FE
	mv	(003h),x
	mv	y,[s1_btm]
	sub	y,x
	dec	y
	mv	ba,00920h
	sub	y,ba
	mv	il,05Ah
	jrc	LOC_BF0FE
	mv	x,(003h)
	mv	y,(000h)
	sub	x,y
	inc	x
	pushu	imr
	mv	[--s],u
	mv	y,(003h)
	mv	u,(003h)
	add	u,ba
	inc	u
	inc	y
LOC_BF09C:
	mv	a,[--y]
	pushu	a
	dec	x
	jrnz	LOC_BF09C
	mv	u,plink_sys			; ref 0BF1DFh via u
	mv	x,(000h)
	mv	[--s],u
	sub	u,x
	mv	(009h),u
	mv	u,[s++]
	mv	i,003E4h
LOC_BF0B4:
	popu	a
	mv	[x++],a
	dec	i
	jrnz	LOC_BF0B4
	mv	y,(000h)
	mv	ba,001DFh
	sub	y,ba
LOC_BF0C2:
	popu	a
	cmp	a,0FFh
	jrz	LOC_BF0E6
	mv	il,002h
	test	a,080h
	jrz	LOC_BF0CF
	inc	il
LOC_BF0CF:
	and	a,07Fh
	cmp	a,07Eh
	jrnz	0BF0D9h
	popu	ba
	add	y,ba
	mv	ba,05045h
	mvp	(006h),[y]
	sbcl	(006h),(009h)
	mvp	[y],(006h)
	jr	LOC_BF0C2
LOC_BF0E6:
	mv	u,[s++]
	mv	x,(000h)
	mv	a,022h
	add	x,a
	mv	[d_link],x
	popu	imr
	mv	x,0BF209h			; ref 0BF209h via x
	mv	il,004h
	call	SUB_BF14C
	mv	il,06Fh
LOC_BF0FE:
	pushu	i
	call	SUB_BF127
	mv	a,000h
	pre	032h
	mv	[(iocsw)+03Ah],a
	popu	i
LOC_BF10A:
	call	SUB_BF112
	pre	032h
	add	(bp_ram),00Ch
	retf
SUB_BF112:
	mv	x,DB_BF151			; ref 0BF151h via x
	add	x,i
	mv	il,[x++]
	mv	y,i
	pre	032h
	mv	(cl),000h
	mv	il,004h
	callf	fcs_call			; FCS 004h write_block: ecriture d'un bloc ((cl) = handle, X = source, Y = nombre d'octets ; retour X = adresse suivante, Y = octets ecrits). Avec Y = 0, le bloc du pointeur jusqu'a la fin du fichier est supprime
	ret
SUB_BF127:
	pre	032h
	mv	x,[baswrk]
	mv	a,072h
	add	x,a
	call	SUB_BF142
	jrc	LOC_BF141
	pre	032h
	mv	(txtbas),y
	call	SUB_BF142
	jrc	LOC_BF141
	pre	032h
	mv	(datbas),y
	ret
LOC_BF141:
	reset
SUB_BF142:
	mv	il,041h
	pre	032h
	mv	(ch),[x++]
SUB_BF148:
	pre	032h
	mv	(cl),006h
SUB_BF14C:
	callf	iocs_call
	ret
DB_BF151:
	db	'GPLINKC ver 1.62 by Daisuke Mizobata',00Dh,00Ah
	db	'based on PLINK ver 1.04 by N.Kon',00Dh,00Ah
	db	011h
	db	'Already exists.',00Dh,00Ah
	db	014h
	db	'Not enough memory.',00Dh,00Ah
	db	00Ch
	db	'Installed.',00Dh,00Ah
	db	011h
	db	'Over two pages.',00Dh,00Ah
plink_sys:
	db	0FBh			; bloc memoire du driver PLINK   SYS (attribut 25h)
	db	'PLINK   SYS%',000h,000h,000h
	db	000h,020h,009h,000h,000h,000h,020h,009h,000h,020h,009h,000h,000h,000h,000h,000h
	db	000h,000h
plink_iocs:
	db	000h,000h,000h,000h,083h,036h,0F2h,00Bh,04Ch,03Ah,000h			; header IOCS : device 00h, entree 0BF236h, lecteur(s) L:
DB_BF20C:
	db	0F0h,080h,000h,003h,002h,000h,001h,000h,000h,008h,080h,000h,02Ch,000h,0D5h,003h
	db	00Ch,00Ch,000h,00Ch,000h
DB_BF221:
	db	0F0h,080h,000h,003h,002h,000h,001h,000h,000h,008h,080h,000h,050h,000h,0B1h,00Fh
	db	030h,030h,000h,030h,000h
plink_entry:
	pushu	imr			; flow: probable code island
	pushu	x			; flow: probable code island
	pre	030h
	sub	(bp_ram),013h			; flow: probable code island
	mv	x,[intv_sio_rx]			; flow: probable code island
	mv	(00Dh),x			; flow: probable code island
	mv	x,DB_BF4CF			; ref 0BF4CFh via x | flow: probable code island
	mv	[intv_sio_rx],x			; flow: probable code island
	popu	x			; flow: probable code island
	popu	imr			; flow: probable code island
	mv	(008h),[sio_baud]			; flow: probable code island
	and	(008h),0FDh			; flow: probable code island
	pre	022h
	ex	(bp+008h),(ucr)			; flow: probable code island
	pre	022h
	mv	(bp+009h),(koh)			; flow: probable code island
	pre	030h
	or	(koh),060h			; flow: probable code island
	call	SUB_BF302			; flow: probable code island
LOC_BF263:
	pre	030h
	test	(usr),010h			; flow: probable code island
	jrz	LOC_BF263			; flow: probable code island
	pre	030h
	mv	(ucr),(bp+008h)			; flow: probable code island
	pre	030h
	mv	(koh),(bp+009h)			; flow: probable code island
	test	(006h),002h			; flow: probable code island
	jrz	LOC_BF284			; flow: probable code island
	mv	a,002h			; flow: probable code island
	jrc	LOC_BF284			; flow: probable code island
LOC_BF27A:
	test	[softint],080h			; flow: probable code island
	jrnz	LOC_BF27A			; flow: probable code island
	mv	a,0FFh			; flow: probable code island
	sc			; flow: probable code island
LOC_BF284:
	pushu	imr			; flow: probable code island
	pushu	x			; flow: probable code island
	mv	x,(00Dh)			; flow: probable code island
	mv	[intv_sio_rx],x			; flow: probable code island
	pre	030h
	pmdf	(bp_ram),013h			; flow: probable code island
	popu	x			; flow: probable code island
	popu	imr			; flow: probable code island
	retf			; flow: probable code island
LOC_BF293:
	mv	a,[x]			; flow: probable code island
	cmp	a,031h			; flow: probable code island
	jrnz	LOC_BF29F			; flow: probable code island
	mv	x,DB_BF20C			; ref 0BF20Ch via x | flow: probable code island
	jr	LOC_BF2A7			; flow: probable code island
LOC_BF29F:
	cmp	a,035h			; flow: probable code island
	jrnz	LOC_BF2C1			; flow: probable code island
	mv	x,DB_BF221			; ref 0BF221h via x | flow: probable code island
LOC_BF2A7:
	pushu	a			; flow: probable code island
	mv	[0BF2FDh],x			; ref 0BF2FDh via x | flow: probable code island
	mv	ba,[x+00Ch]			; flow: probable code island
	mv	[0BF581h],ba			; ref 0BF581h via ba | flow: probable code island
	call	SUB_BF524			; flow: probable code island
	mv	a,053h			; flow: probable code island
	call	SUB_BF489			; flow: probable code island
	popu	a			; flow: probable code island
	call	SUB_BF489			; flow: probable code island
	jr	LOC_BF2E5			; flow: probable code island
LOC_BF2C1:
	cmp	a,044h			; flow: probable code island
	jrnz	LOC_BF2D6			; flow: probable code island
	call	SUB_BF524			; flow: probable code island
	mv	a,044h			; flow: probable code island
	call	SUB_BF489			; flow: probable code island
	mv	i,00F12h			; flow: probable code island
	mv	[SUB_BF49A],i			; ref 0BF49Ah via i | flow: probable code island
	jr	LOC_BF2E5			; flow: probable code island
LOC_BF2D6:
	cmp	a,049h			; flow: probable code island
	jrnz	LOC_BF2E5			; flow: probable code island
	mv	il,082h			; flow: probable code island
	mv	a,000h			; flow: probable code island
LOC_BF2DE:
	call	SUB_BF489			; flow: probable code island
	dec	il			; flow: probable code island
	jrnz	LOC_BF2DE			; flow: probable code island
LOC_BF2E5:
	call	SUB_BF4D8			; flow: probable code island
LOC_BF2E8:
	call	SUB_BF2F3			; flow: probable code island
	mv	[x+00Ah],i			; flow: probable code island
	mv	[x+011h],ba			; flow: probable code island
	rc			; flow: probable code island
	ret			; flow: probable code island
SUB_BF2F3:
	call	SUB_BF2FC			; flow: probable code island
	mv	ba,[x+013h]			; flow: probable code island
	mv	il,080h			; flow: probable code island
	ret			; flow: probable code island
SUB_BF2FC:
	mv	x,DB_BF20C			; ref 0BF20Ch via x | flow: probable code island
	rc			; flow: probable code island
	ret			; flow: probable code island
SUB_BF302:
	mv	(006h),000h			; flow: probable code island
	mv	a,il			; flow: probable code island
	cmp	a,010h			; flow: probable code island
	jrnz	LOC_BF30D			; flow: probable code island
	rc			; flow: probable code island
	ret			; flow: probable code island
LOC_BF30D:
	cmp	a,011h			; flow: probable code island
	jrz	SUB_BF2FC			; flow: probable code island
	cmp	a,012h			; flow: probable code island
	jrz	LOC_BF37F			; flow: probable code island
	cmp	a,013h			; flow: probable code island
	jrz	LOC_BF3BA			; flow: probable code island
	cmp	a,014h			; flow: probable code island
	jrz	LOC_BF3BA			; flow: probable code island
	cmp	a,015h			; flow: probable code island
	jrz	LOC_BF37F			; flow: probable code island
	cmp	a,016h			; flow: probable code island
	jrnz	LOC_BF32A			; flow: probable code island
	mv	ba,00000h			; flow: probable code island
	rc			; flow: probable code island
	ret			; flow: probable code island
LOC_BF32A:
	cmp	a,017h			; flow: probable code island
	jrnz	LOC_BF36F			; flow: probable code island
	mv	ba,[0BFAFDh]			; flow: probable code island
	pre	030h
	cmpw	(bl),ba			; flow: probable code island
	jrz	LOC_BF364			; flow: probable code island
	call	SUB_BF524			; flow: probable code island
	test	(006h),002h			; flow: probable code island
	jrnz	LOC_BF36E			; flow: probable code island
	pre	030h
	mv	ba,(bl)			; flow: probable code island
	mv	[0BFAFDh],ba			; flow: probable code island
	mv	(002h),ba			; flow: probable code island
	mv	x,DB_BF5C3			; ref 0BF5C3h via x | flow: probable code island
	mv	y,DB_BF645			; flow: probable code island
	mv	il,041h			; flow: probable code island
	call	SUB_BF437			; flow: probable code island
	test	(006h),002h			; flow: probable code island
	jrz	LOC_BF364			; flow: probable code island
	mv	ba,0FFFFh			; flow: probable code island
	mv	[0BFAFDh],ba			; flow: probable code island
	jr	LOC_BF36E			; flow: probable code island
LOC_BF364:
	pre	030h
	mvw	(cl),00080h			; flow: probable code island
	mv	x,DB_BF5C3			; ref 0BF5C3h via x | flow: probable code island
	rc			; flow: probable code island
LOC_BF36E:
	ret			; flow: probable code island
LOC_BF36F:
	cmp	a,018h			; flow: probable code island
	jrz	SUB_BF2F3			; flow: probable code island
	cmp	a,03Fh			; flow: probable code island
	jrz	LOC_BF293			; flow: probable code island
	cmp	a,040h			; flow: probable code island
	jrz	LOC_BF2E8			; flow: probable code island
	mv	a,003h			; flow: probable code island
	sc			; flow: probable code island
	ret			; flow: probable code island
LOC_BF37F:
	pre	022h
	mvw	(bp+002h),(bl)			; flow: probable code island
	mv	y,x			; flow: probable code island
	mv	il,040h			; flow: probable code island
	mv	ba,[0BFAFDh]			; flow: probable code island
	cmpw	(002h),ba			; flow: probable code island
	jrnz	LOC_BF39E			; flow: probable code island
	mv	y,DB_BF5C3			; ref 0BF5C3h via y | flow: probable code island
LOC_BF394:
	mv	ba,[y++]			; flow: probable code island
	mv	[x++],ba			; flow: probable code island
	dec	il			; flow: probable code island
	jrnz	LOC_BF394			; flow: probable code island
	jr	LOC_BF3A6			; flow: probable code island
LOC_BF39E:
	call	SUB_BF437			; flow: probable code island
	test	(006h),002h			; flow: probable code island
	jrnz	LOC_BF3B9			; flow: probable code island
LOC_BF3A6:
	pre	030h
	mv	ba,(bl)			; flow: probable code island
	inc	ba			; flow: probable code island
	pre	030h
	mv	(bl),ba			; flow: probable code island
	pre	030h
	mv	ba,(dl)			; flow: probable code island
	dec	ba			; flow: probable code island
	pre	030h
	mv	(dl),ba			; flow: probable code island
	jrnz	LOC_BF37F			; flow: probable code island
	rc			; flow: probable code island
LOC_BF3B9:
	ret			; flow: probable code island
LOC_BF3BA:
	pre	022h
	mvw	(bp+002h),(bl)			; flow: probable code island
	mv	il,080h			; flow: probable code island
	mv	ba,[0BFAFDh]			; flow: probable code island
	cmpw	(002h),ba			; flow: probable code island
	jrnz	LOC_BF3D7			; flow: probable code island
	mv	y,DB_BF5C3			; ref 0BF5C3h via y | flow: probable code island
LOC_BF3CD:
	mv	a,[x++]			; flow: probable code island
	mv	[y++],a			; flow: probable code island
	dec	il			; flow: probable code island
	jrnz	LOC_BF3CD			; flow: probable code island
	jr	LOC_BF3DF			; flow: probable code island
LOC_BF3D7:
	call	SUB_BF3F3			; flow: probable code island
	test	(006h),002h			; flow: probable code island
	jrnz	LOC_BF3F2			; flow: probable code island
LOC_BF3DF:
	pre	030h
	mv	ba,(bl)			; flow: probable code island
	inc	ba			; flow: probable code island
	pre	030h
	mv	(bl),ba			; flow: probable code island
	pre	030h
	mv	ba,(dl)			; flow: probable code island
	dec	ba			; flow: probable code island
	pre	030h
	mv	(dl),ba			; flow: probable code island
	jrnz	LOC_BF3BA			; flow: probable code island
	rc			; flow: probable code island
LOC_BF3F2:
	ret			; flow: probable code island
SUB_BF3F3:
	pushu	il			; flow: probable code island
	call	SUB_BF57A			; flow: probable code island
	popu	il			; flow: probable code island
	pushu	imr			; flow: probable code island
	pre	030h
	mv	(imr),0A0h			; flow: probable code island
	mv	y,(00Ah)			; flow: probable code island
	pushu	y			; flow: probable code island
LOC_BF400:
	mv	a,[x++]			; flow: probable code island
	mv	[y++],a			; flow: probable code island
	dec	il			; flow: probable code island
	jrnz	LOC_BF400			; flow: probable code island
	mv	a,057h			; flow: probable code island
	call	SUB_BF489			; flow: probable code island
	mv	a,(002h)			; flow: probable code island
	call	SUB_BF489			; flow: probable code island
	mv	a,(003h)			; flow: probable code island
	call	SUB_BF489			; flow: probable code island
	popu	y			; flow: probable code island
	mv	il,081h			; flow: probable code island
LOC_BF41A:
	mv	a,[y++]			; flow: probable code island
	call	SUB_BF489			; flow: probable code island
	dec	il			; flow: probable code island
	jrnz	LOC_BF41A			; flow: probable code island
	mv	a,0FFh			; flow: probable code island
	call	SUB_BF489			; flow: probable code island
	call	SUB_BF49A			; flow: probable code island
	test	(006h),002h			; flow: probable code island
	jrz	LOC_BF435			; flow: probable code island
	mv	ba,0FFFFh			; flow: probable code island
	mv	[y],ba			; flow: probable code island
LOC_BF435:
	popu	imr			; flow: probable code island
	ret			; flow: probable code island
SUB_BF437:
	pushu	imr			; flow: probable code island
	pushu	il			; flow: probable code island
	pre	030h
	mv	(imr),0A0h			; flow: probable code island
	call	SUB_BF57A			; flow: probable code island
	popu	il			; flow: probable code island
	jrnc	LOC_BF46B			; flow: probable code island
	pushu	il			; flow: probable code island
	pushu	x			; flow: probable code island
	mv	x,(00Ah)			; flow: probable code island
	mv	a,052h			; flow: probable code island
	call	SUB_BF489			; flow: probable code island
	mv	a,(002h)			; flow: probable code island
	call	SUB_BF489			; flow: probable code island
	mv	a,(003h)			; flow: probable code island
	call	SUB_BF489			; flow: probable code island
	rc			; flow: probable code island
	call	SUB_BF49A			; flow: probable code island
	jrc	LOC_BF469			; flow: probable code island
	mv	[x++],a			; flow: probable code island
	mv	il,080h			; flow: probable code island
LOC_BF460:
	call	SUB_BF49A			; flow: probable code island
	mv	[x++],a			; flow: probable code island
	dec	il			; flow: probable code island
	jrnz	LOC_BF460			; flow: probable code island
LOC_BF469:
	popu	x			; flow: probable code island
	popu	il			; flow: probable code island
LOC_BF46B:
	mv	[--s],u			; flow: probable code island
	mv	u,(00Ah)			; flow: probable code island
	test	(006h),002h			; flow: probable code island
	jrz	LOC_BF47C			; flow: probable code island
	mv	ba,0FFFFh			; flow: probable code island
	mv	[u+081h],ba			; flow: probable code island
	jr	LOC_BF485			; flow: probable code island
LOC_BF47C:
	popu	ba			; flow: probable code island
	mv	[x++],ba			; flow: probable code island
	mv	[y++],ba			; flow: probable code island
	dec	il			; flow: probable code island
	jrnz	LOC_BF47C			; flow: probable code island
LOC_BF485:
	mv	u,[s++]			; flow: probable code island
	popu	imr			; flow: probable code island
	ret			; flow: probable code island
SUB_BF489:
	pre	030h
	test	(usr),008h			; flow: probable code island
	jrz	SUB_BF489			; flow: probable code island
	test	(006h),002h			; flow: probable code island
	jrz	LOC_BF496			; flow: probable code island
	mv	a,000h			; flow: probable code island
LOC_BF496:
	pre	030h
	mv	(txd),a			; flow: probable code island
	ret			; flow: probable code island
SUB_BF49A:
	jr	LOC_BF4AB			; flow: probable code island
	db	0FFh,008h,01Ah,01Eh,065h,006h,001h,019h,00Bh,080h,007h,071h,006h,0FEh,006h
LOC_BF4AB:
	mv	ba,09C40h			; flow: probable code island
LOC_BF4AE:
	pre	030h
	test	(ssr),008h			; flow: probable code island
	jrnz	LOC_BF4BE			; flow: probable code island
	test	(006h),001h			; flow: probable code island
	jrnz	LOC_BF4C2			; flow: probable code island
	dec	ba			; flow: probable code island
	jrnz	LOC_BF4AE			; flow: probable code island
	sc			; flow: probable code island
LOC_BF4BE:
	or	(006h),002h			; flow: probable code island
	ret			; flow: probable code island
LOC_BF4C2:
	mv	ba,06530h			; flow: probable code island
	mv	[SUB_BF49A],ba			; ref 0BF49Ah via ba | flow: probable code island
	mv	a,(007h)			; flow: probable code island
	and	(006h),0FEh			; flow: probable code island
	ret			; flow: probable code island
DB_BF4CF:
	db	030h,080h,0F9h,0A0h,007h,079h,006h,001h,007h
SUB_BF4D8:
	mv	il,082h			; flow: probable code island
	mv	ba,00000h			; flow: probable code island
	mv	x,DB_BF5C3			; ref 0BF5C3h via x | flow: probable code island
LOC_BF4E1:
	mv	[x++],ba			; flow: probable code island
	dec	i			; flow: probable code island
	jrnz	LOC_BF4E1			; flow: probable code island
	mv	ba,0FFFFh			; flow: probable code island
	mv	[0BFAFDh],ba			; flow: probable code island
	mv	il,007h			; flow: probable code island
	mv	y,DB_BF6CD			; flow: probable code island
	mv	[DB_BF6C7],y			; flow: probable code island
	call	SUB_BF509			; flow: probable code island
	mv	il,001h			; flow: probable code island
	mv	y,0BFA77h			; flow: probable code island
	mv	[DB_BF6CA],y			; flow: probable code island
	call	SUB_BF509			; flow: probable code island
	ret			; flow: probable code island
SUB_BF509:
	mv	x,y			; flow: probable code island
	mv	[x+081h],ba			; flow: probable code island
	dec	il			; flow: probable code island
	jrz	LOC_BF51C			; flow: probable code island
	mv	ba,00086h			; flow: probable code island
	add	y,ba			; flow: probable code island
	mv	[x+083h],y			; flow: probable code island
	jr	SUB_BF509			; flow: probable code island
LOC_BF51C:
	mv	y,0FFFFFh			; flow: probable code island
	mv	[x+083h],y			; flow: probable code island
	ret			; flow: probable code island
SUB_BF524:
	mv	x,DB_BF5C3			; ref 0BF5C3h via x | flow: probable code island
	mv	il,081h			; flow: probable code island
LOC_BF52A:
	mv	(000h),[x++]			; flow: probable code island
	mv	a,[x+081h]			; flow: probable code island
	cmp	(000h),a			; flow: probable code island
	jrnz	LOC_BF539			; flow: probable code island
	dec	il			; flow: probable code island
	jrnz	LOC_BF52A			; flow: probable code island
	ret			; flow: probable code island
LOC_BF539:
	mvw	(002h),[0BFAFDh]			; flow: probable code island
	mv	x,DB_BF5C3			; ref 0BF5C3h via x | flow: probable code island
	mv	il,081h			; flow: probable code island
	pushu	x			; flow: probable code island
	call	SUB_BF3F3			; flow: probable code island
	popu	x			; flow: probable code island
	mv	ba,(002h)			; flow: probable code island
	inc	ba			; flow: probable code island
	mv	(002h),ba			; flow: probable code island
	dec	ba			; flow: probable code island
	dec	ba			; flow: probable code island
	mv	(004h),ba			; flow: probable code island
	mv	y,(00Ah)			; flow: probable code island
LOC_BF557:
	mv	ba,[y+081h]			; flow: probable code island
	cmpw	(002h),ba			; flow: probable code island
	jrnz	LOC_BF566			; flow: probable code island
	pushu	a			; flow: probable code island
	mv	a,[x+080h]			; flow: probable code island
	mv	[y],a			; flow: probable code island
	popu	a			; flow: probable code island
LOC_BF566:
	cmpw	(004h),ba			; flow: probable code island
	jrnz	LOC_BF570			; flow: probable code island
	mv	a,[x]			; flow: probable code island
	mv	[y+080h],a			; flow: probable code island
LOC_BF570:
	mv	y,[y+083h]			; flow: probable code island
	pushu	y			; flow: probable code island
	inc	y			; flow: probable code island
	popu	y			; flow: probable code island
	jrnz	LOC_BF557			; flow: probable code island
	ret			; flow: probable code island
SUB_BF57A:
	pushu	x			; flow: probable code island
	pushu	y			; flow: probable code island
	mv	x,DB_BF6CA			; flow: probable code island
	mv	ba,0002Ch			; flow: probable code island
	cmpw	(002h),ba			; flow: probable code island
	jrnc	LOC_BF58C			; flow: probable code island
	mv	x,DB_BF6C7			; flow: probable code island
LOC_BF58C:
	mv	(00Ah),x			; flow: probable code island
	mv	(010h),x			; flow: probable code island
	mv	x,[x]			; flow: probable code island
LOC_BF592:
	mv	ba,[x+081h]			; flow: probable code island
	mv	y,[x+083h]			; flow: probable code island
	cmpw	(002h),ba			; flow: probable code island
	jrz	LOC_BF5AE			; flow: probable code island
	pushu	y			; flow: probable code island
	inc	y			; flow: probable code island
	popu	y			; flow: probable code island
	sc			; flow: probable code island
	jrz	LOC_BF5AE			; flow: probable code island
	mv	a,083h			; flow: probable code island
	add	x,a			; flow: probable code island
	mv	(010h),x			; flow: probable code island
	mv	x,y			; flow: probable code island
	jr	LOC_BF592			; flow: probable code island
LOC_BF5AE:
	mv	[(010h)],y			; flow: probable code island
	mv	y,[(00Ah)]			; flow: probable code island
	mv	[x+083h],y			; flow: probable code island
	mvw	[x+081h],(002h)			; flow: probable code island
	mv	[(00Ah)],x			; flow: probable code island
	mv	(00Ah),x			; flow: probable code island
	popu	y			; flow: probable code island
	popu	x			; flow: probable code island
	ret			; flow: probable code island
DB_BF5C3:
	db	0FEh,006h,002h,0BDh,01Eh,0B9h,08Ah,085h,087h,004h,005h,004h,009h,005h,086h,00Eh
	db	007h,003h,00Bh,089h,0B2h,00Ah,08Bh,086h,084h,006h,08Bh,08Bh,09Eh,089h,00Eh,0A2h
	db	089h,00Eh,01Dh,016h,005h,005h,008h,009h,003h,015h,00Ch,005h,005h,004h,009h,0E5h
	db	098h,08Dh,086h,084h,004h,085h,084h,004h,09Fh,096h,084h,007h,0B7h,08Ch,0FFh
