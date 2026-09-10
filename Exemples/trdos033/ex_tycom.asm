;--------------------------------------------------
;	DOS for PC-E500S  					Ver 0.33
;		(c)1990,1992   T.Kobayashi - JF ALBOUY
;
; EX_TYCOM.ASM  					 04/12/2022
; 
; LOADM "F:EX_TYCOM.OBJ"
; Installation par call &BF200
;
; A installer avec TRDOS.OBJ
;--------------------------------------------------
;Adresses non définies
;check_scrut:equ  $0BE872
;$$0BE872
;$BE890
;$BEA1F
;$BEC64
;$BEC69
;$BEC70
;$BF04C
;$BF11A
;$BF15F
;$BF17B
				;BF2E0
				;BF3EB

;$BFBF1
;$BFBFC
;$BFCBE
;$F379
;
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
scr: equ $fd

;--- Routines ---
fcs_call:  	equ	0fffe4h
iocs_call: 	equ	0fffe8h
keyrep: 	equ 0bfcbfh
;---------------------------------------------------
;
	org	0bf200h
;
	pre_on
;
start: 	mv il,0						;searching for the drive name
		mv x,drive					;drive name address
		callf iocs_call
		mv x,fileName2				;file name address
		jrc st1						;saut si error
;
		mv il,$4a
		callf iocs_call
		mv i,32						;nombre de caractères	
		add x,i						;calcul de la nouvelle adresse
		mv [mem+1],x				;copie de la nouvelle adresse
		mv x,fileName1
st1:	mv il,2						;checking the header address
		mv y,endprg
		callf $BFBFC
		mv x,endprg
		call mem
		jrc BF2CF
		mv [fileHandle],(cx)		;sauve le file handle
		mv a,(cx)
		mv il,1
		callf $BFBFC
		jrc BF2C3
;
		cmp a,1
		jrnz BF2C3
;
		;reading a block of file
		mv [--s],x					;empiler l'adresse dans la pile système
		mv (cx),[fileHandle]		;cl = file number
		mv il,3
		mv a,1						;physical end of file
		callf fcs_call
		jrc BF2C1					;saut si error
;
		;closing a file	
		mv (cx),[fileHandle]		;cl = file number
		mv il,2
		callf fcs_call
;
		mv ba,[$BF15F]
		cmp a,'1'
		jrnz BF2CF
		ex a,b
		cmp a,'1'
		jrnz BF2CF
;
		;modification du code
		mv a,3						;code de JPF
		mv x,BF2FB
		mv y,$0BE88C
		mv [y++],a 					;copie du code JPF
		mv [y++],x					;copie de l'adresse
		mv i,$F379
		mv [$BEA1F],i
;
		;modification du code
		mv a,3						;code de JPF
		mv x,BF357
		mv y,$BEC64
		mv [y++],a 					;copie du code JPF
		mv [y++],x					;copie de l'adresse
		mv i,$3333
		mv [$BF15F],i 
;
		;Copie de 4 caractères
		mv x,$BF17B
		mv y,exit
		mv il,4
BF2AA:	mv a,[y++]
		mv [x++],a 
		dec il
		jrnz BF2AA					;boucler tant que non NUL
;
		;Copie de 32 caractères
		mv y,x						;y = adresse de fin de copie
		inc y						;adresse suivante pour copie
		mv il,32					;compteur
BF2B8:	mv a,[y++]
		mv [x++],a
		dec il
		jrnz BF2B8					;boucler tant que non NUL
		retf
;
		;closing a file
BF2C1:	mv x,[s++]					;dépiler l'adresse
BF2C3:	mv (cx),[fileHandle]		;file handle
		mv il,2						;closing a file
		callf fcs_call
BF2CF:	mv x,ErrorFile
		call BF2E0
		mv x,[$BFBF1]
		mv a,2						;copie du code JP
		mv [x],a
		rc
		retf
;
		;writing a block of the file
BF2E0:	mv (cx),0					;file handle
		pushu x						;sauver l'adresse
		mv y,0						;compteur
BF2E9:	mv a,[x++]					;lire un caractère
		inc y						;incrémenter le compteur
		cmp a,0
		jrnz BF2E9					;boucler tant que non fin de chaine
		dec y						;fixer le nombre de caractères lu
		popu x						;récupérer l'adresse de la chaine
		mv il,4						;writing the bloc
		callf 	fcs_call
		retf
;	
BF2FB:	cmp a,5
		jpz $BE890
		cmp a,4
		jpz BF317
		cmp a,15
		jpz BF317
		cmp a,$60
		jpz BF343
		cmp a,$61
		jpz BF34F
		jp $BE872
;
		;setting of display state
BF317:	and (scr),$0f
		mvw (cx),0
		mv a,0							;OFF display
		mv il,$50
		callf iocs_call
;	
		;power OFF
		mvw (cx),8
		mv il,$41
		callf iocs_call
;
		;setting of display state
		mvw (cx),0
		mv a,1							;ON display
		mv il,$50
		callf iocs_call
		jp $BE872
;		
BF343:	and (scr),15
		xor [keyrep],$10
		jp $BE872
BF34F:	xor [keyrep],$80
		jp $BE872
;		
BF357:	mv ($20),a
		cmp a,2
		jrz BF367
		cmp a,8
		jpnz $BF11A
		jpf $BEC69
;
BF367:	mv x,nDriver
		call $BF04C
BF36E:	test [$BFCBE],$80
		jrnz BF36E
		jpf $BEC70
		call mem
		jpc $BF11A
		ret
;
		;opening a file
mem:	mv y,lstDrive
mem1:	pushu y
		pushu x 						;lead address of file name
		mv il,1
		mv a,1							;file is opened for reading-out
		callf fcs_call
;
		popu x
		popu y
		jrnc mem4						;retour si no error
;
		;reading a byte of the file : the drive name
		mv il,5							;initialiser le compteur
		pushu x 						;sauver l'adresse du file name
mem2:	mv a,[y++]						;parcourir les caractères
		cmp a,0
		jrz mem3						;saut si fin de chaine
		cmp a,':'						;caractère du drive
		jrz mem5						;saut pour lire le file name
		mv [x++],a 						;sauver le caractère
		dec il							;décrémenter le compteur
		jrnz mem2						;boucler tant que non tout lu
mem3:	popu x							;récupérer l'adresse
		sc 
mem4:	ret
;		
mem5:	mv [x++],a						;copier le ":"
		mv a,32
		dec il
		jrnz mem5						;boucler tant que le drive name est non NUL
		popu x							;récupérer l'adresse
		jr mem1
;		
;		
fileName1:	db 'TYCOM.SYS',CR
fileName2:	db 'TYCOM1.SYS',CR
ErrorFile:	db 'TYCOM.SYS  read error',0
nDriver:	db ' Driver ',0
exit:		db 'EXIT'
fileHandle:	db 0
drive:		db 'DOS:',0
lstDrive:	db 'S1:S2:S3:D:E:F:',0

endprg:	

		end