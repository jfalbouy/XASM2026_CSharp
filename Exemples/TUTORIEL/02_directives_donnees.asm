; ==========================================================================
;  02_directives_donnees.asm - DIRECTIVES de definition et d'alignement
;
;  Illustre : EQU vs SET, les directives de donnees DB/DM/DW/DP/DS/DZ,
;  et l'alignement ALIGN/EVEN.
;  Assembler :  xasm2026-4 02_directives_donnees.asm -O -L
; ==========================================================================

	title	'Directives de donnees'	; titre en tete du listing (n'emet rien)
	org	0E000H

; --------------------------------------------------------------------------
;  EQU  = constante (une valeur, definie une fois).
;  SET (ou =) = variable d'assemblage, REDEFINISSABLE.
; --------------------------------------------------------------------------
base:	equ	0E000H		; constante
compteur:	set	0		; variable : redefinissable plus bas

; --------------------------------------------------------------------------
;  Donnees : DB (octet), DW (mot 16 bits), DP (pointeur 24 bits),
;            DM (chaine), DZ (chaine + NUL), DS (reserve).
; --------------------------------------------------------------------------
octets:	db	1, 2, 3, 4		; quatre octets
mot:	dw	1234H			; 16 bits, poids faible d'abord -> 34 12
pointeur:	dp	0BF1A5H		; 24 bits -> A5 F1 0B
texte:	dm	'XASM'			; chaine, sans terminateur -> 58 41 53 4D
chaine:	dz	'Hi'			; chaine + NUL -> 48 69 00
reserve:	ds	4			; reserve 4 octets (emis a 00)
	ds	2,0FFH			; reserve 2 octets remplis de FFh

; --------------------------------------------------------------------------
;  Redefinition avec SET : le compteur avance (impossible avec EQU).
; --------------------------------------------------------------------------
compteur:	set	compteur+1
	db	compteur		; -> 01h
compteur:	set	compteur+1
	db	compteur		; -> 02h

; --------------------------------------------------------------------------
;  Alignement : ALIGN n (multiple de n) et EVEN (multiple de 2).
;  Contrairement a un simple ajustement du compteur, XASM **emet** le
;  remplissage : l'image reste contigue.
; --------------------------------------------------------------------------
	align	16			; aligner sur 16 octets (emet le bourrage)
apres_align:	db	0AAH
	even				; aligner sur 2 octets
apres_even:	db	0BBH

	end
