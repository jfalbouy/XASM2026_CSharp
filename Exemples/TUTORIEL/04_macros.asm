; ==========================================================================
;  04_macros.asm - MACROS et repetition sur liste (IRP / IRPC)
;
;  Illustre : la definition d'une macro a parametres, l'expansion, EXITM
;  (sortie anticipee), et les repetitions IRP (sur une liste de valeurs) et
;  IRPC (sur les caracteres d'une chaine).
;  Assembler :  xasm2026-4 04_macros.asm -O -L
; ==========================================================================

	org	0E000H

; --------------------------------------------------------------------------
;  MACRO nom,param1,param2 ... ENDM
;  Le corps est re-developpe a chaque appel : les conditionnelles, REPEAT et
;  macros imbriquees y sont donc resolues au moment de l'expansion.
; --------------------------------------------------------------------------
;  NB : donner aux parametres des noms NON AMBIGUS. La substitution est
;  textuelle : un parametre nomme 'b' remplacerait aussi le 'b' de 'db' !
	macro	deux_octets,octet1,octet2
	db	octet1
	db	octet2
	endm

	deux_octets 011H,022H		; -> 11 22
	deux_octets 033H,044H		; -> 33 44

; --------------------------------------------------------------------------
;  EXITM : interrompt l'expansion de la macro. Combine a une conditionnelle,
;  il rend le corps generatif. Ici : n'emettre l'octet que si le drapeau
;  est non nul, sinon sortir sans rien emettre.
; --------------------------------------------------------------------------
	macro	emet_si,drapeau,valeur
	ifeq	drapeau			; si drapeau == 0
	exitm				; ... sortir : rien n'est emis
	endif
	db	valeur
	endm

	emet_si 0,0AAH			; drapeau 0 -> EXITM -> aucun octet
	emet_si 1,0BBH			; drapeau 1 -> emet -> BBh

; --------------------------------------------------------------------------
;  IRP nom,v1,v2,... : repete le bloc pour chaque valeur (separees par virgule).
;  IRPC nom,chaine   : repete le bloc pour chaque caractere de la chaine ;
;                      chaque caractere est injecte comme litteral, donc 'DB nom'
;                      (SANS guillemets) emet son code ASCII.
;  Tous deux se ferment par ENDR.
; --------------------------------------------------------------------------
	irp	valeur,010H,020H,030H
	db	valeur			; -> 10 20 30
	endr

	irpc	lettre,'AB'
	db	lettre			; code ASCII du caractere -> 41 42
	endr

	end
