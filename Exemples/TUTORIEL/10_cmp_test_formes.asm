; ==========================================================================
;  10_cmp_test_formes.asm - CMP ET TEST : LES FORMES QUI EXISTENT,
;                           ET CELLES QUI N'EXISTENT PAS
;
;  Presque toutes les familles arithmetiques et logiques du SC62015 ont une
;  forme "A,(n)" (l'accumulateur face a un octet de RAM interne) :
;      ADD 42h   SUB 4Ah   ADC 52h   SBC 5Ah   AND 77h   OR 7Fh   XOR 6Fh
;  CMP et TEST, NON : il n'existe ni "CMP A,(n)" ni "TEST A,(n)". Et TEST
;  n'a pas non plus de forme "(m),(n)" (CMP l'a : B7h).
;
;  L'assembleur doit donc REFUSER ces formes ("Undefined instruction"),
;  comme le moteur C de reference. Avant le correctif du 2026-09-15,
;  XASM2026-4 les acceptait et emettait l'opcode d'une AUTRE instruction :
;      cmp  a,(n)     -> 62 nn      = CMP [lmn],n  (5 octets, 2 emis)
;      test a,(n)     -> 6B nn      = XOR (n),A    (ECRIT en memoire !)
;      test (m),(n)   -> 6A mm nn   = XOR [lmn],n  (5 octets, 3 emis)
;  Sans aucun message : le defaut n'apparaissait qu'a l'execution, le CPU
;  avalant les octets suivants et partant n'importe ou (retour au MENU).
;
;  CE FICHIER :
;    1-2. assemble toutes les formes VALIDES de CMP et TEST (lire le .lst) ;
;    3.   montre comment reecrire "cmp a,(n)" avec la forme qui existe,
;         "cmp (n),a", SANS se tromper de condition : le sens s'inverse ;
;    4.   garde les formes INVALIDES dans un bloc desactive : passer
;         'demo_refus' a 1 et reassembler -> "Undefined instruction".
;
;  Ce n'est PAS un programme a executer (pas de .uu) : il sert a lire les
;  octets. Il donne un objet IDENTIQUE avec xasm2026-4 et xasm2026-1-2.
;
;    xasm2026-4 10_cmp_test_formes.asm -O -L
; ==========================================================================

	org	0E000H
	pre_on				; (n) = absolu -> prebit emis ; (bp+n) -> sans prebit

work:		equ	010H		; un octet de RAM interne
ext:		equ	0BF800H		; une adresse de memoire externe (20 bits)
demo_refus:	equ	0		; 1 = assembler les formes INVALIDES (refus attendu)

; ==========================================================================
;  1. CMP : les formes qui existent (positionnent C et Z, n'ecrivent rien)
; ==========================================================================
	cmp	a,05AH			; 60 5A            A - n
	cmp	(work),05AH		; 30 61 10 5A      (m) - n
	cmp	[ext],05AH		; 62 00 F8 0B 5A   [lmn] - n : 5 octets
	cmp	(work),a		; 30 63 10         (n) - A
	cmp	(bp+5),a		; 63 05            (BP+5) - A, sans prebit
	cmp	(work),(work+1)		; 32 B7 10 11      (m) - (n)

; ==========================================================================
;  2. TEST : les formes qui existent (ET logique : positionne Z, n'ecrit rien)
; ==========================================================================
	test	a,080H			; 64 80
	test	(work),080H		; 30 65 10 80
	test	[ext],080H		; 66 00 F8 0B 80
	test	(work),a		; 30 67 10

;  Pour comparaison, les familles qui ONT une forme A,(n) (resultat dans A) :
	add	a,(work)		; 30 42 10
	sub	a,(work)		; 30 4A 10
	adc	a,(work)		; 30 52 10
	sbc	a,(work)		; 30 5A 10
	and	a,(work)		; 30 77 10
	or	a,(work)		; 30 7F 10
	xor	a,(work)		; 30 6F 10

; ==========================================================================
;  3. REECRIRE "cmp a,(n)" : la forme reelle "cmp (n),a" INVERSE LE SENS
;
;  "cmp (n),a" calcule (n) - A. La retenue (emprunt) signifie (n) < A,
;  autrement dit A > (n). Selon ce qu'on veut savoir de A face a (n) :
;
;      condition voulue   "cmp a,(n)" (n'existe pas)   "cmp (n),a" (reel)
;      A =  (n)           jrz                          jrz        identique
;      A <> (n)           jrnz                         jrnz       identique
;      A >  (n)           NC et NZ                     jrc
;      A <= (n)           C ou Z                       jrnc
;      A <  (n)           jrc                          NC et NZ
;      A >= (n)           jrnc                         C ou Z
;
;  Piege : recopier "jrc" tel quel apres avoir retourne les operandes
;  teste A > (n) au lieu de A < (n). L'egalite, elle, ne change pas.
;
;  Exemple : aller a 'plus_petit' si A < (work), sinon a 'pas_plus_petit'.
; ==========================================================================
	cmp	(work),a		; (work) - A
	jrz	pas_plus_petit		; A = (work)
	jrc	pas_plus_petit		; A > (work)   (retenue : (work) < A)
plus_petit:				; ici : NC et NZ, donc A < (work)
	mv	a,1
	jr	suite
pas_plus_petit:				; ici : A >= (work)
	mv	a,0
suite:

; ==========================================================================
;  4. LES FORMES QUI N'EXISTENT PAS : bloc desactive (demo_refus = 0).
;     Avec demo_refus = 1, l'assemblage echoue sur "Undefined instruction".
; ==========================================================================
	ifne	demo_refus
	cmp	a,(work)		; REFUSE (le port emettait 30 62 10)
	cmp	a,(bp+5)		; REFUSE (le port emettait 62 05)
	test	a,(work)		; REFUSE (le port emettait 30 6B 10 = XOR (n),A)
	test	(work),(work+1)		; REFUSE (le port emettait 32 6A 10 11)
	endif

	end
