; ==========================================================================
;  09_memoire_interne_prebits.asm - MEMOIRE INTERNE (n) ET OCTET "PRE",
;                                    DEMONTRE ET TESTABLE SUR LE SHARP
;
;  Le point le plus deroutant du SC62015 : un operande "(n)" ne designe PAS
;  toujours l'octet absolu n de la RAM interne. Le CPU a un mode par defaut,
;  et c'est un octet PREfixe (dit "prebit"/"prebyte") place AVANT l'opcode
;  qui decide du mode reel :
;
;    - AVEC prebit (ici 030h)  ->  (n)      = octet ABSOLU n
;    - SANS prebit (defaut CPU) -> (n) vaut (BP+n) = octet  BP + n
;
;  Autrement dit : sans prebit, l'adresse depend de BP (RAM interne 0ECh).
;  Si BP n'est pas nul, on lit AILLEURS que prevu -- bug classique.
;
;  En XASM, sous 'pre_on' :
;    - ecrire (n)      => l'assembleur EMET le prebit  -> absolu
;    - ecrire (bp+n)   => AUCUN prebit (mode par defaut) -> BP+n
;  (Regardez le .lst : la 1re forme a un octet 30h en tete, pas la 2nde.)
;
;  CE QUE FAIT CE PROGRAMME (pour rendre la difference VISIBLE) :
;    1. fixe BP = 010h (non nul, c'est ce qui revele le piege) ;
;    2. ecrit 'A' a l'adresse ABSOLUE 040h, et 'Z' a l'adresse 050h ;
;    3. lit le MEME operande (040h) de deux facons et affiche le resultat :
;         AVEC prebit : (040h)        -> 'A'
;         SANS prebit : (bp+040h)=050h -> 'Z'
;  Deux octets DIFFERENTS pour la meme ecriture "(40h)", uniquement selon
;  la presence du prebit : c'est la lecon.
;
;  Tout est sauve/restaure (BP et les 2 octets touches) : retour propre a BASIC.
;
;  Deployer :
;    xasm2026-4 09_memoire_interne_prebits.asm -O PREBIT.OBJ -B 09_memoire_interne_prebits.uu
;  Sur le Sharp / l'emulateur :
;    LOADM "x:PREBIT.OBJ"   puis   CALL &BF000
; ==========================================================================

	org	0BF000H
	pre_on				; (n) = absolu (avec prebit) ; (bp+n) = sans prebit

; --- constantes systeme ---
fcs_call:	equ	0FFFE4H		; appel FCS (affichage)
cl:		equ	0D6H		; handle FCS : 0 = ecran
bp_ram:		equ	0ECH		; Base Pointer, en RAM interne

; --- parametres de la demonstration ---
var:		equ	040H		; "ma variable" : octet absolu 040h
base:		equ	010H		; base BP choisie (non nulle)
					; => sans prebit, (var) devient (bp+var)=050h

; ==========================================================================
;  PROGRAMME (lance par CALL &BF000)
; ==========================================================================
start:
	popu	x			; pointeur de ligne BASIC
	pushu	x			; ... restitue -> retour propre (pas de Syntax error)

; --- (0) SAUVER ce qu'on va modifier : BP, puis les octets absolus 040h et 050h.
;         On lit en ABSOLU (donc AVEC prebit) pour ne pas dependre de BP courant.
	mv	a,(bp_ram)		; BP courant   (30 .. : prebit present)
	pushu	a
	mv	a,(var)			; octet absolu 040h
	pushu	a
	mv	a,(var+base)		; octet absolu 050h
	pushu	a

; --- (1) FIXER BP = base (non nul) : c'est ce qui rend le piege visible. ---
	mv	(bp_ram),base		; (0ECh) <- 010h   (prebit present : absolu)

; --- (2) ECRIRE deux marqueurs DIFFERENTS a deux adresses absolues. ---
	mv	a,'A'
	mv	(var),a			; absolu 040h <- 'A'   (AVEC prebit)
	mv	a,'Z'
	mv	(bp+var),a		; (bp+040h)=050h <- 'Z' (SANS prebit)

; --- (3) LIRE le MEME operande (var) de deux facons, capturer dans le message. ---
	mv	a,(var)			; AVEC prebit -> absolu 040h  -> 'A'
	mv	[res_avec],a
	mv	a,(bp+var)		; SANS prebit -> (bp+040h)=050h -> 'Z'
	mv	[res_sans],a

; --- (4) RESTAURER l'etat interne (ordre inverse des empilements). ---
	popu	a
	mv	(var+base),a		; restaurer absolu 050h
	popu	a
	mv	(var),a			; restaurer absolu 040h
	popu	a
	mv	(bp_ram),a		; restaurer BP (fait avant l'appel FCS)

; --- (5) AFFICHER le resultat. ---
	mv	x,msg
	mv	y,btm-msg
	mv	(cl),0			; handle 0 = ecran
	mv	il,4			; fonction FCS 04h = write_block
	callf	fcs_call
	rc				; carry clair -> retour propre a BASIC
	retf

; ==========================================================================
;  MESSAGE (en memoire EXTERNE : pointe par X, syntaxe [..], pas (..))
;  Les deux octets 'res_avec'/'res_sans' sont remplis a l'execution.
; ==========================================================================
msg:		db	'PRE present (n)=40h    -> '
res_avec:	db	'?',13,10
		db	'PRE absent (bp+n)=50h  -> '
res_sans:	db	'?',13,10
		db	'Meme (n), octet different!',13,10
btm:
	end
