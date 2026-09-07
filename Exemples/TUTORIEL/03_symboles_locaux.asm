; ==========================================================================
;  03_symboles_locaux.asm - SYMBOLES LOCAUX et portees (LOCAL / ENDL)
;
;  Illustre : les portees LOCAL, un meme nom reutilise dans deux portees, la
;  reference au symbole parent par '..!', et la portee ANONYME (LOCAL sans
;  etiquette) qui rend uniques les labels d'un corps de macro repete.
;  Assembler :  xasm2026-4 03_symboles_locaux.asm -O -L -S
; ==========================================================================

	org	0E000H

; --------------------------------------------------------------------------
;  Un symbole global, visible partout.
; --------------------------------------------------------------------------
global:	equ	0AAH

; --------------------------------------------------------------------------
;  'LOCAL nom' ouvre une portee. Les symboles definis dedans sont prefixes
;  par la portee (nom!label en interne), donc invisibles au dehors. Le meme
;  nom 'valeur' peut ainsi exister dans deux portees sans collision.
; --------------------------------------------------------------------------
	local	premiere
valeur:	equ	011H
	db	valeur			; -> 11h  (valeur de 'premiere')
	db	..!global		; '..!' = reference au parent -> AAh
	endl

	local	seconde
valeur:	equ	022H			; meme nom, autre portee : pas de collision
	db	valeur			; -> 22h  (valeur de 'seconde')
	endl

; --------------------------------------------------------------------------
;  Portee ANONYME : 'LOCAL' sans etiquette ouvre une portee au nom genere
;  (n%05X). C'est ce qui rend uniques les labels internes quand une macro
;  est expansee plusieurs fois : chaque expansion entre dans sa propre portee,
;  donc une reference avant vers un label interne ne se lie plus par erreur a
;  l'expansion voisine.
; --------------------------------------------------------------------------
	macro	saute_par_dessus,valeur_octet
	local				; portee anonyme : 'fin' devient unique
	jr	fin			; saut avant vers 'fin' de CETTE expansion
	db	valeur_octet
fin:	nop
	endl
	endm

	saute_par_dessus 0CCH		; 1re expansion : sa propre portee
	saute_par_dessus 0DDH		; 2e expansion : une autre portee -> pas de conflit

	end
