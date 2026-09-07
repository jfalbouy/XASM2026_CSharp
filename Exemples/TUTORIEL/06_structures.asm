; ==========================================================================
;  06_structures.asm - STRUCT, zone de travail SUBORG, blocs structures { }
;
;  Illustre : la definition d'une structure (STRUCT/ENDS) et l'usage de ses
;  champs comme offsets, la zone de travail A62 (SUBORG + BYTE/WORD/PNTR) qui
;  nomme des champs sans emettre d'octet, et les boucles structurees { } avec
;  continue / break.
;  Assembler :  xasm2026-4 06_structures.asm -O -L -S
; ==========================================================================

	org	0E000H

; --------------------------------------------------------------------------
;  STRUCT nom ... ENDS : decrit une disposition de champs. Les etiquettes
;  internes valent l'offset du champ ; le nom de la structure vaut sa taille.
;  Rien n'est emis : c'est une description reutilisable.
; --------------------------------------------------------------------------
point:	struct
px:	ds	1			; offset 0
py:	ds	1			; offset 1
pcouleur:	ds	2		; offset 2 (2 octets)
	ends

	db	px			; offset de px  -> 00h
	db	py			; offset de py  -> 01h
	db	pcouleur		; offset       -> 02h
	db	point			; TAILLE de la structure -> 04h

; --------------------------------------------------------------------------
;  Zone de travail A62 (SUBORG) : un COMPTEUR SECONDAIRE nomme des champs a
;  des offsets successifs, 1/2/3 octets (BYTE/WORD/PNTR), tableaux via nom[n].
;  N'emet AUCUN octet et ne touche pas le compteur principal. La taille du
;  cadre se relit par '%' en position de terme.
; --------------------------------------------------------------------------
	suborg	0			; base du cadre a 0
etat:	byte	drapeau,mode		; deux champs de 1 octet : offsets 0 et 1
sect:	word	numero			; un champ de 2 octets : offset 2
buf:	byte	tampon[8]		; un tableau de 8 octets : offset 4
ptr:	pntr	suivant			; un pointeur de 3 octets : offset 12

	db	drapeau			; -> 00h
	db	mode			; -> 01h
	db	numero			; -> 02h
	db	tampon			; -> 04h
	db	suivant			; -> 0Ch (12)
	db	%			; taille totale du cadre -> 0Fh (15 octets)

; --------------------------------------------------------------------------
;  Blocs structures { } (dialecte A62) : boucle ou 'continue' vise le debut du
;  bloc et 'break' la sortie. Reserves SEULEMENT a l'interieur d'un bloc, donc
;  un vrai label 'continue:' hors bloc resterait intact. Ici, un simple corps
;  qui emet un octet (les octets de saut dependent du CPU ; on illustre la
;  structure, pas le detail des sauts).
; --------------------------------------------------------------------------
	{
	db	0AAH			; corps du bloc
	nop
	}

	end
