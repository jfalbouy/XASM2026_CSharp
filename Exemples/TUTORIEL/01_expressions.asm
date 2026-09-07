; ==========================================================================
;  01_expressions.asm - les EXPRESSIONS de XASM2026-4
;
;  Illustre : le radix par caractere de fin, les operateurs, le compteur de
;  localisation '*', et l'extraction d'octets d'une adresse 20 bits.
;  Assembler :  xasm2026-4 01_expressions.asm -O -L
; ==========================================================================

	org	0E000H

; --------------------------------------------------------------------------
;  1. Le RADIX est donne par le caractere de fin du nombre (regle de eval.c)
;     B = binaire, O = octal, D = decimal, H = hexa, aucun = decimal.
;     Un nombre doit commencer par un chiffre ou '$'. Le '_' est ignore.
; --------------------------------------------------------------------------
	db	1010B		; binaire  -> 0Ah
	db	17O		; octal    -> 0Fh (1*8 + 7 = 15)
	db	25D		; decimal  -> 19h
	db	1Fh		; hexa     -> 1Fh
	db	42		; decimal par defaut -> 2Ah
	db	$2A		; '$' = hexa -> 2Ah
	db	1010_1010B	; '_' ignore, juste pour la lisibilite -> 0AAh

; --------------------------------------------------------------------------
;  2. Operateurs arithmetiques et binaires (precedence de eval.c)
;     * / ont la priorite sur + - ; & | ^ ~ << >> completent l'arithmetique.
; --------------------------------------------------------------------------
	db	2+3*4		; = 0Eh (14 : * avant +)
	db	(2+3)*4		; = 14h (20 : parentheses)
	db	20/3		; division entiere -> 06h
	db	20%3		; modulo (% entre deux valeurs) -> 02h
	db	0FFh & 0Fh	; ET   -> 0Fh
	db	0F0h | 0Fh	; OU   -> 0FFh
	db	0FFh ^ 0Fh	; XOR  -> 0F0h
	db	~0Fh		; NON (complement, tronque a l'octet) -> 0F0h
	db	1 << 4		; decalage a gauche -> 10h
	db	80h >> 3	; decalage a droite -> 10h

; --------------------------------------------------------------------------
;  3. Operateurs de comparaison : rendent 1 (vrai) ou 0 (faux).
;     Utiles dans les conditionnelles.  = <> < > <= >=
; --------------------------------------------------------------------------
	db	5 = 5		; -> 01h
	db	5 <> 5		; -> 00h
	db	3 < 5		; -> 01h
	db	5 >= 9		; -> 00h

; --------------------------------------------------------------------------
;  4. Le compteur de localisation '*' vaut l'adresse courante.
;     En position de terme c'est le LC ; entre deux valeurs '*' est la
;     multiplication -- la position le desambiguise.
; --------------------------------------------------------------------------
ici:	dw	*		; emet l'adresse de 'ici' (16 bits, poids faible)
	db	*-ici		; distance depuis 'ici' (ici on a deja emis 2 octets) -> 02h
	db	3*4		; ici '*' est bien la multiplication -> 0Ch

; --------------------------------------------------------------------------
;  5. Extraire les octets d'une adresse 20 bits : LOW / MID / HIGH
; --------------------------------------------------------------------------
cible:	equ	0BF1A5H
	db	LOW cible	; poids faible  -> A5h
	db	MID cible	; octet median -> F1h
	db	HIGH cible	; poids fort   -> 0Bh

	end
