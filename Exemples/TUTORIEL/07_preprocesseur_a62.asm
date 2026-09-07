; ==========================================================================
;  07_preprocesseur_a62.asm - PREPROCESSEUR A62 (dialecte Kon)
;
;  Illustre ce qui rend XASM2026-4 capable d'assembler les sources A62
;  d'origine : le prefixe 'rel' qui fait GENERER une table de relocation, la
;  macro A62 '#defmacro' a parametres positionnels %0..%9, et l'assemblage
;  conditionnel '#if / #else / #endif'.
;  Assembler :  xasm2026-4 07_preprocesseur_a62.asm -O -L
;
;  NB : la table de relocation n'est emise QUE si des 'rel' existent. Un
;  fichier sans 'rel' produit un objet identique -- l'apport est purement
;  additif.
; ==========================================================================

	org	0BF000H

; --------------------------------------------------------------------------
;  #defmacro : macro A62 a parametres positionnels %0..%9, fermee par
;  #endmacro. Ici 'bsr' = 'rel call' (un appel proche RELOGEABLE), exactement
;  comme dans les pilotes de N. Kon / D. Mizobata.
; --------------------------------------------------------------------------
#defmacro bsr
	rel call %0
#endmacro

; --------------------------------------------------------------------------
;  #if : assemblage conditionnel A62. Conditions : '#if symbole' (vrai si != 0),
;  '#if a == b', '#if a != b'.
; --------------------------------------------------------------------------
version:	equ	2

#if version == 1
	db	011H			; ecarte
#else
	db	022H			; emis (version != 1) -> 22h
#endif

; --------------------------------------------------------------------------
;  Le corps du "pilote" : quelques instructions dont des adresses ABSOLUES
;  internes marquees relogeables. 'rel' assemble l'instruction normalement
;  ET enregistre son champ d'adresse comme site de relocation.
; --------------------------------------------------------------------------
corps:
	rel	mv x,routine		; pointeur 3 octets relogeable (largeur 3)
	bsr	routine			; appel proche relogeable (via la macro, largeur 2)
	rel	dp routine		; pointeur donnee relogeable (largeur 3)
routine:
	rc
	retf

; --------------------------------------------------------------------------
;  A l'assemblage, les sites 'rel' collectes sont encodes en TABLE DE
;  RELOCATION (format Kon) ajoutee automatiquement APRES le code :
;    delta entre offsets de champ, bit 080h = largeur 3, 07Eh = delta long,
;    0FFh = fin. Regardez la fin de l'objet / du listing.
; --------------------------------------------------------------------------
	end
