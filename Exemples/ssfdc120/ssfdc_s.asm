;SmartMedia subroutines
		org	$be000
; (c)1999 K.Takamatsu

		pre_on

;I/O base address
io_base:	equ	$0e000

;I/O address
dat:		equ	io_base
cmd:		equ	io_base+5
adr:		equ	io_base+10

fcs:		equ	$fffe4
iocs:		equ	$fffe8

bx:		equ	$d4
bl:		equ	$d4
bh:		equ	$d5
cx:		equ	$d6
cl:		equ	$d6
ch:		equ	$d7
dx:		equ	$d8
dl:		equ	$d8
dh:		equ	$d9
si:		equ	$da
di:		equ	$dd
iocsw:		equ	$e6
imr:		equ	$fb

		macro	ale
		or	($f3),0010_0000b	;ALE -> H
		endm

		macro	ald
		and	($f3),1101_1111b	;ALE -> L
		endm

		macro	disable
		or	($f1),1000_0000b	;#CE -> H
		endm

		macro	enable
		and	($f1),0111_1111b	;#CE -> L
		endm

start:
		jr	cmd42
		jr	call_iocs

call_iocs:
		mv	il,0
		mv	x,drv_name
		callf	iocs
		jrc	exit

		mv	i,(0)
		mv	ba,(2)
		mv	x,(4)
		mv	y,(7)
		mvw	(bx),(10)
		mvw	(dx),(12)
		mvp	(si),(14)
		mvp	(di),(17)
		callf	iocs
exit:
		pushu	f
		mv	(20),[u++]
		mvp	(17),(di)
		mvp	(14),(si)
		mvw	(12),(dx)
		mvw	(10),(bx)
		mv	(0),i
		mv	(2),ba
		mv	(4),x
		mv	(7),y

		rc
		retf

;=====================================================================
;			42h	Get Status
;=====================================================================
;return
;	a:status
;	b:media type(1:2MB,2:4MB...)
;	(bl):maker code
;	(bh):device code
;	(dl):?
;	(dh):?
cmd42:
		call	check24
		call	read_id

		enable
		call	read_st
		disable

		mv	b,a
		mv	a,[capacity]
		ex	a,b

		rc
		jr	exit

;=====================================================================
;			Other Subroutines
;=====================================================================
;コマンド書き込み
;a:command
cmd_out:
		ald			;ALE -> L
		pushu	x
		mv	x,cmd
		mv	[x],a
		popu	x
		ret

;３バイトアドレス書き込み
;(si):address
adr3_out:
		call	adr_out1
		mv	[x],(si)
		mv	[x],(si+1)
		mv	[x],(si+2)
		jr	adr_out2

;２バイトアドレス書き込み
;ba:address
adr2_out:
		call	adr_out1
		mv	[x],a
		mv	a,b
		mv	[x],a
		jr	adr_out2

;１バイトアドレス書き込み
;a:address
adr1_out:
		call	adr_out1
		mv	[x],a
		jr	adr_out2

adr_out1:
		ale			;ALE -> H
		mv	x,adr
		ret
adr_out2:
		ald			;ALE -> L
		ret

;ステータス読み込み
;return a
;	b7 0:write protect/1:write enable
;	b6 0:busy/1:ready
;	b0 0:success/1:fail
read_st:
		pushu	x
		mv	a,$70
		call	cmd_out
		mv	a,[dat]
		popu	x
		ret

;read ID
;(bl):maker code
;(bh):device code
;(dl):?
;(dh):?
read_id:
		enable
		pushu	x
		call	read_id1
		mv	(bl),[x]
		mv	(bh),[x]
		mv	(dl),[x]
		mv	(dh),[x]
		popu	x
		disable
		rc
		ret
read_id1:
		mv	a,$90
		call	cmd_out
		mv	a,0
		call	adr1_out
		mv	il,20
		wait
		mv	x,dat
		ret

;reset
reset:
		enable
		pushu	x
		mv	a,$ff
		call	cmd_out
		disable
		popu	x
		rc
		ret

;容量の判別
check24:
		call	reset
		call	read_id
		mv	x,dev_id
		mv	y,capacity
check240:
		mv	ba,[x++]
		cmp	a,-1
		jrz	check2401
		cmpw	(bx),ba
		mv	a,[x++]
		jrz	check241
		jr	check240
check2401:
		mv	a,0		;容量不明
		mv	[y],a
		sc
		jr	check242
check241:
		mv	il,[y]
		sub	il,a
		rc
		jrz	check242
		mv	[y],a
check242:
		ret

;=====================================================================
;			Static Variables
;=====================================================================
drv_name:	db	'S:',0

capacity:	db	1

;1:2MB 2:4MB 3:8MB 4:16MB 5:32MB
dev_id:
		db	$ec,$64,1	;SAMSUNG 2MB-5V
		db	$ec,$ea,1	;SAMSUNG 2MB-3.3V
		db	$98,$64,1	;TOSHIBA 2MB-5V
		db	$98,$ea,1	;TOSHIBA 2MB-3.3V

		db	$ec,$e5,2	;SAMSUNG 4MB-5V
		db	$ec,$e3,2	;SAMSUNG 4MB-3.3V
		db	$98,$6b,2	;TOSHIBA 4MB-5V
		db	$98,$e5,2	;TOSHIBA 4MB-3.3V

		db	$ec,$e6,3	;SAMSUNG 8MB-3.3v
		db	$98,$e6,3	;TOSHIBA 8MB-3.3v

		db	$ec,$73,4	;SAMSUNG 16MB-3.3v
		db	$98,$73,4	;TOSHIBA 16MB-3.3v

		db	$ec,$75,5	;SAMSUNG 32MB-3.3v

		db	-1

		end
