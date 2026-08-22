#!/usr/bin/env python3
# Genere PLINK2.asm : portage de PLINKC sur le modele REGISTER3
#  - installateur AJOUT-EN-FIN (pas de decalage BASIC, pas de reset/bomb)
#  - desinstallation par CALL &BF000 "-u"
#  - noms definis une seule fois (macros)
#  - table de relocation d'origine reutilisee VERBATIM (1 octet ajuste : nom device +2)
#  - corps du pilote + zone de travail VERBATIM depuis plinkc.native.asm
import io, re

SRC = r"C:\Claude\xasm2026-4\Exemples\PLINKC\plinkc.native.asm"
OUT = r"C:\Claude\xasm2026-4\Exemples\PLINKC\PLINK2.asm"

nat = open(SRC, encoding='latin-1').read().split('\n')
def L(a, b):  # lignes a..b (1-based, inclus)
    return '\n'.join(nat[a-1:b])

# --- table de relocation d'origine (63 o), octet index 3 : BD -> BF (nom device +2) ---
RELOC = [0xFE,0x06,0x02,0xBF,0x1E,0xB9,0x8A,0x85,0x87,0x04,0x05,0x04,0x09,0x05,0x86,0x0E,
0x07,0x03,0x0B,0x89,0xB2,0x0A,0x8B,0x86,0x84,0x06,0x8B,0x8B,0x9E,0x89,0x0E,0xA2,
0x89,0x0E,0x1D,0x16,0x05,0x05,0x08,0x09,0x03,0x15,0x0C,0x05,0x05,0x04,0x09,0xE5,
0x98,0x8D,0x86,0x84,0x04,0x85,0x84,0x04,0x9F,0x96,0x84,0x07,0xB7,0x8C,0xFF]
def reloc_db():
    out=[]
    for i in range(0,len(RELOC),16):
        row=','.join('0%02Xh'%b for b in RELOC[i:i+16])
        out.append('\tdb\t'+row)
    return '\n'.join(out)

import os
DEBUG = os.environ.get('PLINK2_DEBUG') == '1'
def mark(n):
    if not DEBUG: return ''
    return "\tmv\ta,'%s'\n\tcallf\tputc\n" % n

# ================= PROLOGUE : org, pre_on, constantes, macros =================
prologue = r'''; ==========================================================================
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
''' + L(18, 56) + r'''
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
''' + reloc_db() + r'''

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

'''

# ================= EN-TETE DU BLOC (renomme) =================
header = r'''	pre_off				; le CORPS a ses propres prebytes explicites (pre $30...)
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
'''

# ================= MEDIA + CORPS + ZONE DE TRAVAIL (VERBATIM 288..806) =======
body = L(288, 806)

# ================= blen (renomme btop -> block_top) =================
tail = 'blen:\t\tequ\t%-block_top\n\tend\n'

if DEBUG:
    # helper putc : imprime le caractere A, en preservant x/y/i/ba
    putc = (
        "\n; --- DEBUG : imprime le caractere A (preserve x/y/i/ba) ------------------\n"
        "putc:\n\tpushu\tx\n\tpushu\ty\n\tpushu\ti\n\tpushu\tba\n"
        "\tmv\t[dbgbuf],a\n\tmv\tx,dbgbuf\n\tmv\ty,1\n\tmv\t(cl),0\n\tmv\til,4\n\tcallf\tfcs\n"
        "\tpopu\tba\n\tpopu\ti\n\tpopu\ty\n\tpopu\tx\n\tretf\ndbgbuf:\tdb\t0\n")
    prologue = prologue.replace("; --- table de relocation", putc + "\n; --- table de relocation")
    # marqueurs au debut de chaque etape
    for anchor, n in [
        (";  (4) compacter S1:", '1'),
        (";  (5) parcourir les blocs", '2'),
        (";  (8) copier le CODE", '3'),
        (";  (9) RELOCATION", '4'),
        (";  (10) chainer", '5'),
        (";  (12) initialiser les parametres", '6'),
        (";  (13) succes", '7'),
    ]:
        prologue = prologue.replace(anchor, mark(n) + anchor, 1)

open(OUT, 'w', encoding='latin-1', newline='\r\n').write(
    prologue + '\n' + header + '\n' + body + '\n\n' + tail)
print("ecrit:", OUT, "(DEBUG)" if DEBUG else "")
