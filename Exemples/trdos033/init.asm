;--------------------------------------------------
;	DOS for PC-E500S  					Ver 0.33
;		(c)1990,1992   T.Kobayashi - JF ALBOUY
;
; INIT.ASM  						   04/12/2022
; 
; LOADM "F:INIT.OBJ"
; Installation par call &BF400
;
; A installer avec TRDOS.OBJ
;--------------------------------------------------

;--- Constantes -----------------------------------
CR:		equ $0d
LF:		equ $0a
EOF:	equ $1a

;---Mémoire interne ---
bl:	equ	0d4h
bh:	equ	0d5h
cl:	equ	0d6h
ch:	equ	0d7h
dl:	equ	0d8h
dh:	equ	0d9h
cx: equ 0d6h
;
;--- Routines ---
fcs_call:  equ	0fffe4h
iocs_call: equ	0fffe8h
;---------------------------------------------------
;
	org	0bf400h
;
	pre_on
;
;--------------------------------------------------
;			Parcours ligne de commande
;
;--------------------------------------------------
start: 	popu x						;récupérer adresse ligne de commande
		pushu x						;sauvegarder pour retour de la routine
st1:	mv a,[x]					;lire le caractère en cours
		cmp a,':'	
		jrz st2						;saut si trouvé ':'
		cmp a, '""'					
		jrz st1						;saut si trouvé "
		cmp a,CR
		jrnz st1					;boucler tant que non fin de ligne
		;erreur dans la ligne de commande
st11:	mv il,4						;écriture un bloc dans un fichier
		mv (cx),00h					;file handle
		mv x,data					;adresse de la chaine à afficher
		mv y,16						;commpteur, 16 caractères pour le file name	
		callf fcs_call				;5 bits / Drive name + 8 bits / file name + 3 bits / extension
		sc
		retf
		
st2:	popu x						;adresse de la ligne de commande
		mv y,endprg					;addresse de fin de programme
		mv il,6						;écriture un bit dans le fichier
st3:	mv a,[x++]					;lire un caractère de la ligne de commande
		cmp a,' '
		jrz st3						;boucler tant que SPACE
		cmp a,'""'
		jrz st3						;boucler tant que "
		cmp a,':'
		jrz st4						;saut si lecture drive
		mv [y++],a					;copie du caractère dans le buffer
		dec il						;décrémenter le compteur
		jrnz st3					;boucler tant que non NUL
		mv a,[x++]					;lire ":" après DRIVE
		cmp a,':'
		jrnz st4
st4:	mv [y++],a					;copie le caractère ':' dans le buffer
		mv a,0
		mv [y++],a 					;copie du zéro terminal
		mv [--s],x					;empilement dans la pile système
st5:	mv a,[x++]
		cmp a, '""'
		jrz st7						;boucler tant que "
		cmp a,CR
		jrz st6						;saut si fin de ligne
		cmp a,0
		jrnz st5					;boucler tant que non NUL
st6:	dec x						;adresse de fin de chaine
st7:	pushu x						;sauvegarde l'addresse
		mv i,0						;création du fichier
		mv x,endprg					;adresse du file name
		callf iocs_call			
		mv x,[s++]					;dépiler l'adresse de la fin de chaine 
		jrc st11					;boucler en début de programme
		mv i,$3f					;formating LCD driver
		callf iocs_call
		rc
		retf
;
data:	db 'Bad drive name',CR,LF

endprg:	

		end