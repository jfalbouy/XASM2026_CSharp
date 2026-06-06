;=======================================================================
;	This  is  a sample program  for XASM  Ver 1.32
;=======================================================================
;
;	small bugs shown as follows  are  fixed.
;
pce:	equ	1			;PC-E500/E550/E650
zau:	equ	1 - pce			;PI-3000/4000/5000 Zaurus + PI-3C95 Basic card
fcs:	equ	zau * $5FFF0   +   pce * $FFFE4
iocs:	equ	zau * $5FFF4   +   pce * $FFFE8
	org	zau * $3F000   +   pce * $BF000
;
	pre_on
	mv	[(bp+5)-6],(7)		;XASM v1.31 made an incorrect code (v1.30 and olders are correct.)
;
	macro	STRLEN,_ptr
	mv	y,_ptr_btm-_ptr_top
	endm
	mv	x,str_top
	strlen	str			;x = string length
	mv	il,4
	callf	fcs
str_top:	db	'TEST!'
str_btm:
;
	end
