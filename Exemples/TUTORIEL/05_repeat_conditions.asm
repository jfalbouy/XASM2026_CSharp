; ==========================================================================
;  05_repeat_conditions.asm - REPETITION generative et ASSEMBLAGE CONDITIONNEL
;
;  Illustre : REPEAT/ENDR avec un compteur SET qui progresse d'une iteration a
;  l'autre, les conditionnelles numeriques IFEQ/IFNE/IFGT/IFLT, et ASSERT qui
;  verrouille une hypothese a l'assemblage.
;  Assembler :  xasm2026-4 05_repeat_conditions.asm -O -L
; ==========================================================================

	org	0E000H

; --------------------------------------------------------------------------
;  REPEAT n ... ENDR repete le bloc n fois. Couple a SET, il devient
;  generatif : le compteur avance a chaque tour (le bloc est re-developpe).
; --------------------------------------------------------------------------
i:	set	0
	repeat	5
	db	i			; emet 00 01 02 03 04
i:	set	i+1
	endr

; --------------------------------------------------------------------------
;  Table generee : le carre de 1 a 4.
; --------------------------------------------------------------------------
n:	set	1
	repeat	4
	db	n*n			; emet 01 04 09 10 (1,4,9,16)
n:	set	n+1
	endr

; --------------------------------------------------------------------------
;  Conditionnelles numeriques : chacune teste UN operande contre zero.
;    IFEQ (==0), IFNE (!=0), IFGT (>0), IFLT (<0). Fin par ENDIF, ELSE possible.
; --------------------------------------------------------------------------
mode:	equ	2

	ifeq	mode
	db	0E0H			; ecarte (mode != 0)
	endif

	ifne	mode
	db	0EEH			; emis (mode != 0) -> EEh
	endif

	ifgt	mode-5			; (2-5) = -3, pas > 0
	db	0F0H			; ecarte
	else
	db	0FFH			; emis (branche else) -> FFh
	endif

; --------------------------------------------------------------------------
;  ASSERT : interrompt l'assemblage si l'hypothese est fausse. N'emet rien.
;  Ici : verifier que la table des carres fait bien 4 octets.
; --------------------------------------------------------------------------
debut_table:	equ	0E000H + 5	; apres les 5 octets du 1er REPEAT
	assert	*-0E000H = 5+4+2,'taille inattendue avant les asserts'

	end
