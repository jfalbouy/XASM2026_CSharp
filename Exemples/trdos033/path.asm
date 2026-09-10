;--------------------------------------------------
;	DOS for PC-E500S  					Ver 0.33
;		(c)1990,1992   T.Kobayashi - JF ALBOUY
;
; PATH.ASM  						   05/12/2022
; 
; LOADM "F:PATH.OBJ"
; Installation par call &BF400
;
; A installer avec TRDOS.OBJ
;--------------------------------------------------

;--- Constantes -----------------------------------
CR:		equ $0d
LF:		equ $0a
EOF:	equ $1a

adr:	equ mem+1

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
start:	mv il,0						;Searching for the drive name
		mv x,data1					;adresse du drive
		callf iocs_call				; retour : cl = device number, ch = drive number
		jrc error					;saut si error
		mv il,$4a					
		callf iocs_call
		mv i,32
		add x,i
		mv y,x
		mv [mem+1],x
		popu x
		mv il,32
st1:	mv a,[x++]					;lecture d'un caractère
		cmp a,' '				
		jrz st1						;saut si SPACE
		cmp a,CR
		jrz st2						;saut si fin de ligne
		cmp a,'"'
		jrz st3						;saut si "
		dec x						;se positionner sur le caractère précédent
st3:	mv a,[x++]					;lire le dernier caractère
		cmp a,'"'
		jrz st4						;saut si "
		cmp a,CR
		jrz st5						;saut si fin de ligne
		mv [y++],a 					;stockage du caractère
		dec il						;décrémenter le compteur
		jrz st6						;saut si zéro
		jr st3						;boucler tant que non NUL
st5:	dec x						;se positionner sur le dernier caractère
st4:	pushu x						;sauver l'adresse
		mv a,0
		dec il
		jrnz st7					;saut si non fin de ligne
		inc il						;rétablir la valeur
st7:	mv [y++],a					;copier le zéro terminal
		dec i 
		jrnz st7					;boucler tant que non NUL
		rc
		retf
;
		;fin de ligne
st2:	dec x						;se positionner sur le dernier caractère
		pushu x						;sauver l'adresse
; mem:	db 13
		; db 0,0,0
;
		;Writing a block of the file
mem:	mv x,0						;adresse de la chaine, variable en cours d'éxécution
		mv y,32						;nombre de caractères
		mv il,4						;write a block
		mv (cx),0					;file handle
		callf fcs_call
		mv x,data4					;adresse de la chaine
		mv y,2						;nombre de caractères
		mv il,4						;write a block
		mv (cx),0					;file handle
		callf fcs_call
		rc
		retf
		
st6:	mv a,[x++]					;lire un caractère
		cmp a,'"'
		jrz st8						;saut si "
		cmp a,CR
		jrnz st6					;boucler tant que non fin de ligne
		dec x						;se positionner sur le dernier caractère
st8:	pushu x						;sauver l'adresse
		mv a,0
		mv [--y],a 					;empiler la valeur de a 
		mv x,data2					;adresse message erreur
		mv y,11						;nombre de caractères
		jr st9						;afficher la chaine de caractères
		
error:	mv x,data3					;adresse message erreur
		mv y,18						;nombre de caractères
st9:	mv il,4						;write a block
		mv (cx),0					;file handle
		callf fcs_call
		sc
		retf
		
data1:	db 'DOS:',0
data2:	db 'Data over',CR,LF
data3:	db 'TR-DOS not found'
data4:  db CR,LF

		end
		