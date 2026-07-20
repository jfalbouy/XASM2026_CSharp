;=====================================================================
;			SmartMedia Driver Ver 1.20
;		       (c)1997,1999 Kenji Takamatsu
;=====================================================================

		PRE_ON

;I/O base address
io_base:	equ	$0e000
exchange:	equ	1

;I/O address
dat:		equ	io_base
cmd:		equ	io_base+5
adr:		equ	io_base+10

cache_size:	equ	ssect + 2

nmpb:		equ	8	;num of mpb

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

eof:		equ	$1a
cr:		equ	$0d
lf:		equ	$0a

		IFNE	exchange

		macro	ale
		or	($f3),00100000B		;ALE -> H
		endm
		macro	ald
		and	($f3),11011111B		;ALE -> L
		endm

		macro	disable
		or	($f1),10000000B		;#CE -> H
		endm
		macro	enable
		and	($f1),01111111B		;#CE -> L
		endm

		ELSE

		macro	disable
		or	($f3),00100000B		;#CE -> H
		endm
		macro	enable
		and	($f3),11011111B		;#CE -> L
		endm

		macro	ale
		or	($f1),10000000B		;ALE -> H
		endm
		macro	ald
		and	($f1),01111111B		;ALE -> L
		endm

		ENDIF

block_top:

memoryBlockHeading:
		db	$fb
		db	'SSFDC   SYS'
		db	00100101B
		dw	0,0
		dp	block_bottom - block_top + cache_size + smpb*(nmpb-1)
		dw	0
		dp	creditMsg
		dp	0
		dp	checkProg
		dp	relTbl

iocsHeader:
		dp	0
		db	$ff
		db	$83
iocsEntry:
		dp	init ;rel
		db	'S:SA:SB:SC:SD:SE:SF:SG:',$00

;最初の１度だけ実行
init:
		pushu	i
		pushu	ba
		pushu	x
		pushu	y

		call	check24 ;rel
		mv	x,iocsEntry ;rel
		mv	y,main ;rel
		mv	[x],y

		call	copy_mpb ;rel

		mv	x,cache ;rel
		mv	ba,$ffff	;Sector number
		mv	[x++],ba
		rc

		popu	y
		popu	x
		popu	ba
		popu	i

;=====================================================================
;			Main Program
;=====================================================================
main:
		ex	ba,i		; Command Number

		ex	a,b
		mv	a,0
		test	[invalid],3 ;rel
		jrz	main0
		mv	a,1
main0:
		ex	a,b

		sub	a,$10
		jrz	cmd10		; $10 (Media Check)
		dec	a
		jrz	cmd11		; $11 (Get Media Parametor)
		dec	a
		jpz	cmd12		; $12 (Read Sector) ;rel
		dec	a
		jpz	cmd13		; $13 (Write Sector) ;rel
		dec	a
		jpz	cmd14		; $14 (Write & Verify Sector) ;rel
		dec	a
		jpz	cmd15		; $15 (Verify Sector) ;rel
		dec	a
		jrz	cmd16		; $16 (Read Status)
		dec	a
		jrz	cmd17		; $17 (Get Sector Address)
		dec	a
		jrz	cmd18		; $18 (Extend Command)
		sub	a,$27
		jrz	cmd3f		; $3F (Initial)
		dec	a
		jrz	cmd40		; $40 (On/Off/Reset)
		dec	a
		jrz	cmd41		; $41 (Change I/O address)
		dec	a
		jrz	cmd42		; $42 (Get Status)

		mv	a,3
		sc
		retf

;=====================================================================
;			10h	Media Check
;=====================================================================
cmd10:
		rc
		retf

;=====================================================================
;			11h	Get MPB
;=====================================================================
cmd11:
		mv	a,b
		shr	a
		jrc	exit02

		mv	x,mpb		; Media Parameter Block address ;rel
		mv	a,(ch)		; drive number
		mv	il,smpb
		inc	a
cmd111:
		dec	a
		jrz	cmd112
		add	x,i
		jr	cmd111
cmd112:
		rc
cmd11e:
		retf

;=====================================================================
;			16h	Get Status
;=====================================================================
cmd16:
		enable
		call	read_st ;rel
		disable
		rol	a
		and	a,00000001B
		xor	a,00000001B
		rc
		retf

;=====================================================================
;			17h	Get Sector Address
;=====================================================================
cmd17:
		mv	a,b
		shr	a
		jrc	exit02

		pmdf	($ec),-5
		mv	ba,(bx)
		mv	(bp+0),ba
		mv	x,cache+2 ;rel
		mv	(bp+2),x

		mv	i,[x-2]
		sub	i,ba
		jrz	cmd171		;キャッシュと一致

;１セクタをキャッシュに読み込む
		call	flash ;rel
		jrc	cmd17e
		call	read_block ;rel
		jrc	cmd17e
		mvw	[(bp+2)-2],(bp+0)
		jr	cmd172

cmd171:
		mv	y,cachehit ;rel
		mv	x,[y]
		inc	x
		mv	[y],x

cmd172:
		mv	x,(bp+2)
		mvw	(cx),[mpb+1] ;rel
		mv	(di),x
		rc
cmd17e:
		pmdf	($ec),5
cmd17e2:
		retf

;=====================================================================
;			18h	Read Directory Information
;=====================================================================
cmd18:
		mv	i,nroot		;Dir Count
		mv	ba,tdir		;Dir Sector
		rc
		retf

;=====================================================================
;			3fh	Initialize
;=====================================================================
cmd3f:
		pushu	i
		call	check24 ;rel
		popu	ba

		jrc	exit02

		mv	x,initcmd ;rel
		mv	b,a
		mv	a,[x]
		ex	a,b
		mv	[x],a
		mv	i,$60d0
		sub	ba,i
		jrnz	c3f3

		call	format ;rel
		jrc	c3fe2

c3f3:
		call	flash ;rel
c3fe:
		jrnc	cmd401
c3fe2:
		retf


;dirve not ready で終了
exit02:
		mv	a,2
		sc
		retf

;=====================================================================
;			40h	Reset
;=====================================================================
cmd40:
		pushu	i
		call	reset ;rel
		call	flash ;rel

		popu	ba
		cmp	a,2
		jrnc	cmd40e
cmd401:
		mv	x,mpb ;rel

		mv	ba,tdir		;Dir Top Sector
		mv	[x+17],ba
		mv	i,nroot		;Num of Root Dir
		mv	[x+10],i

cmd40e:
		ald
		retf

;=====================================================================
;			41h	Change I/O address
;=====================================================================
;Ver1.20から廃止しました。

cmd41:
		mv	x,io_base
		rc
		retf

;=====================================================================
;			42h	Get Status
;=====================================================================
;entry
;	a:0:read status
;	  1:set media type as b register
;	  2:media type auto detect
;	b:media type(1:2MB,2:4MB...)
;return
;	x:read count
;	y:program count
;	(si):chache hit count
;	a:status
;	b:media type(1:2MB,2:4MB...)
;	(bl):maker code
;	(bh):device code
;	(dl):?
;	(dh):?
cmd42:
		mv	ba,i
		cmp	a,1
		jrnz	cmd420
		mv	a,b
		IFEQ	(media_type)-(0)
		cmp	a,1
		sc
		jrnz	cmd423
		ENDIF
		mv	[capacity],a ;rel
		and	[autodetect],$fe ;rel
cmd420:
		cmp	a,2
		jrnz	cmd2401
		or	[autodetect],1 ;rel
cmd2401:
		call	check24 ;rel
		call	read_id ;rel

		enable
		call	read_st ;rel
		disable

		mv	b,a
		mv	a,[capacity] ;rel
		ex	a,b

		mv	x,[read_count] ;rel
		mv	y,[program_count] ;rel
		mvp	(si),[cachehit] ;rel

		rc
		test	[invalid],3 ;rel
		jrz	cmd423
		sc
cmd423:
		retf

;=====================================================================
;			12-15h	Read/Write/Verify Sector
;=====================================================================
;read
cmd12:
		inc	a
;write
cmd13:
		inc	a
;write & verify
cmd14:
		inc	a
;verify
cmd15:
		inc	a

		ex	a,b
		shr	a
		jrc	exit02
		ex	a,b

		pmdf	($ec),-10
		mv	(bp+0),x
		mvw	(bp+3),(dx)
		mvw	(bp+5),(bx)
		mv	(bp+7),a
		pushu	y
		mv	y,cache ;rel
		mvw	(bp+8),[y]

		mv	i,(bp+3)
		mv	ba,(bp+5)
cmd120:

		pushu	i
		pushu	ba

		mv	il,(bp+7)
		dec	il
		jrnz	cmd121

;Verify Sector
		call	verify_sector ;rel
		jr	cmd122

cmd121:
		dec	il
		jrnz	cmd1211

;Write & Verify Sector
		pushu	x
		pushu	ba
		call	write_sector ;rel
		popu	ba
		popu	x
		jrc	cmd122
		call	verify_sector ;rel
		jr	cmd122

cmd1211:
		dec	il
		jrnz	cmd1212

;Write Sector
		call	write_sector ;rel
		jr	cmd122

cmd1212:
		dec	il
		jrnz	cmd122

;Read Sector
		call	read_sector ;rel

cmd122:
		popu	ba
		popu	i
		jrc	cmd12e
		inc	ba
		dec	i
		jrnz	cmd120

		mv	(bx),ba
		mvw	(dx),(bp+3)

		rc
cmd12e:
		popu	y
		pmdf	($ec),10
cmd12e2:
		retf


read_sector:
		cmpw	(bp+8),ba
		jrnz	rs1
		call	flash ;rel
rs1:
		call	read_block ;rel
		ret

verify_sector:
		cmpw	(bp+8),ba
		jrnz	vs1
		call	flash ;rel
vs1:
		call	verify_block ;rel
		ret

write_sector:
		cmpw	(bp+8),ba
		jrnz	ws1
		mv	i,$ffff
		mv	[cache],i ;rel
ws1:
		call	write_block ;rel
		ret

;=====================================================================
;			Cache Flash
;=====================================================================
flash:
		pushu	x
		pushu	ba

		enable
		call	read_st ;rel
		disable
		test	a,10000000B
		rc
		jrz	flash_e		;ライトプロテクトされている
		mv	x,cache ;rel
		mv	ba,[x++]
		inc	ba
		jrz	flash_e		;cache無効
		dec	ba
		pushu	ba
		pushu	x
		call	verify_block	;cacheが書き換えられたか？ ;rel
		popu	x
		popu	ba
		jrnc	flash_e		;書き換えられていない
		call	write_block ;rel

flash_e:
		popu	ba
		popu	x
		
		ret

;=====================================================================
;			Read One Block
;=====================================================================
;entry
;	x:destination address
;	ba:sector number
;return
;	x:next address
read_block:
		enable
		pmdf	($ec),-6
		mv	(bp+3),x
		call	sect2adr ;rel
		mv	(bp+0),0
		mv	(bp+1),ba

		pushu	x
		mv	y,read_count ;rel
		mv	x,[y]
		inc	x
		mv	[y],x
		popu	x

		mv	a,$00
		call	cmd_out ;rel
		mvp	(si),(bp+0)
		call	adr3_out ;rel

		mv	x,(bp+3)
		mv	y,dat

		mv	il,[pages] ;rel

rb0:
		pushu	il

		mv	il,15
		wait

		mv	i,[p8size] ;rel
rb1:
		mv	ba,[y]
		mv	[x++],ba
		mv	ba,[y]
		mv	[x++],ba
		mv	ba,[y]
		mv	[x++],ba
		mv	ba,[y]
		mv	[x++],ba
		dec	i
		jrnz	rb1

;spare area を読み飛ばす
		mv	il,[sasize] ;rel
rb2:
		mv	a,[y]
		dec	il
		jrnz	rb2

		popu	il
		dec	il
		jrnz	rb0

		pmdf	($ec),6
		disable
		rc
		ret

;=====================================================================
;			Verify One Block
;=====================================================================
;entry
;	x:destination address
;	ba:sector number
;return
;	x:next address
;	cy=1:verify error
verify_block:
		enable
		pmdf	($ec),-8
		mv	(bp+3),x
		call	sect2adr ;rel
		mv	(bp+0),0
		mv	(bp+1),ba

		mv	a,$00
		call	cmd_out ;rel
		mvp	(si),(bp+0)
		call	adr3_out ;rel

		mv	x,(bp+3)
		mv	y,dat

		mv	(bp+7),[pages] ;rel

vb0:
		mv	il,15
		wait

		mv	(bp+6),[p8size] ;rel
vb1:
		mv	ba,[y]
		mv	i,[x++]
		sub	i,ba
		jrnz	vb3
		mv	ba,[y]
		mv	i,[x++]
		sub	i,ba
		jrnz	vb3
		mv	ba,[y]
		mv	i,[x++]
		sub	i,ba
		jrnz	vb3
		mv	ba,[y]
		mv	i,[x++]
		sub	i,ba
		jrnz	vb3

		dec	(bp+6)
		jrnz	vb1

;spare srea を読み飛ばす
		mv	il,[sasize] ;rel
vb2:
		mv	a,[y]
		dec	il
		jrnz	vb2

		dec	(bp+7)
		jrnz	vb0
		rc
		jr	vb4
vb3:
		sc
vb4:
		pmdf	($ec),8
		disable
		ret

;=====================================================================
;			Write One Block
;=====================================================================
;entry
;	x:source address
;	ba:sector number
;return
;	x:next address
;	cy=1:error
;	     a:error code
write_block:
		enable
		pmdf	($ec),-7
		mv	(bp+3),x
		call	sect2adr ;rel
		mv	(bp+0),0
		mv	(bp+1),ba

		call	read_st ;rel
		test	a,10000000B
		sc
		mv	a,0
		jrz	wb_e

		pushu	x
		mv	y,program_count ;rel
		mv	x,[y]
		inc	x
		mv	[y],x
		popu	x

		mv	a,$60		;ブロック消去
		call	cmd_out ;rel
		mv	ba,(bp+1)
		call	adr2_out ;rel
		mv	a,$d0
		call	cmd_out ;rel

		call	wait ;rel
		mv	a,$05
		jrc	wb_e

		mv	(bp+6),[pages] ;rel
wb0:
		mv	a,$80		;ページ書き込み
		call	cmd_out ;rel
		mvp	(si),(bp+0)
		inc	(bp+1)
		call	adr3_out ;rel

		mv	x,(bp+3)
		mv	y,dat

		mv	i,[p8size] ;rel
wb1:
		mv	ba,[x++]
		mv	[y],ba
		mv	ba,[x++]
		mv	[y],ba
		mv	ba,[x++]
		mv	[y],ba
		mv	ba,[x++]
		mv	[y],ba
		dec	i
		jrnz	wb1

		mv	(bp+3),x

		mv	a,$10		;ページプログラム
		call	cmd_out ;rel
		call	wait ;rel
		mv	a,$05
		jrc	wb_e

		dec	(bp+6)
		jrnz	wb0

wb_e:
		mv	x,(bp+3)
		pmdf	($ec),7
		disable
		ret

;=====================================================================
;			Other Subroutines
;=====================================================================

;セクタ番号をSmartmediaのアドレスに変換
;entry
;	ba:sector number
;return
;	a:A1
;	b:A2
		IFEQ	(media_type)-(0)
sect2adr:
		mv	il,4
		rc
sect2adr1:
		rc
		shl	a
		ex	a,b
		shl	a
		ex	a,b
		dec	il
		jrnz	sect2adr1
		ret
		ELSE
sect2adr:
		mv	il,[pages] ;rel
		call	mul2n ;rel
		ret
		ENDIF

;Ready になるまで待つ
;cy=1 error
wait:
		mv	il,0
wait1:
		dec	il
		mv	a,2
		jrz	wait_e
		call	read_st ;rel
		test	a,01000000B	;0:busy 1:ready
		jrz	wait1

		call	read_st ;rel
		test	a,00000001B	;0:success 1:fail
		mv	a,5
		jrnz	wait_e
		rc
		ret
wait_e:
		sc
		ret

;コマンド書き込み
;a:command
cmd_out:
		ald			;ALE -> L
		mv	[cmd],a
		ret

;３バイトアドレス書き込み
;(si):address
adr3_out:
		call	adr_out1 ;rel
		mv	[x],(si)
		mv	[x],(si+1)
		mv	[x],(si+2)
		jr	adr_out2

;２バイトアドレス書き込み
;ba:address
adr2_out:
		call	adr_out1 ;rel
		mv	[x],a
		mv	a,b
		mv	[x],a
		jr	adr_out2

;１バイトアドレス書き込み
;a:address
adr1_out:
		call	adr_out1 ;rel
		mv	[x],a
		jr	adr_out2

adr_out1:
		ale			;ALE -> H
		mv	x,adr
		ret
adr_out2:
		ald			;ALE -> L
		ret

;フォーマット
format:
;キャッシュを０にクリア
		mv	ba,[mpb+1] ;rel
		rc
		ex	a,b
		shr	a
		ex	a,b
		shr	a
		mv	i,ba

		sub	ba,ba
		mv	y,cache+2 ;rel
format2:
		mv	[y++],ba	;BA = 0
		dec	i
		jrnz	format2

;キャッシュをFAT,DIRセクタに書き出す
		mv	il,nfat+nrootb	;Fat & Dir Sector
format4:
		mv	y,cache ;rel
		dec	i
		jrnz	format5
		mv	a,$ff
		mv	[y+2],a
format5:
		mv	[y++],i
		inc	i
		pushu	i
		call	flash ;rel
		popu	i
		jrc	formate
		dec	i
		jrnz	format4
formate:
		ret

;ステータス読み込み
;return a
;	b7 0:write protect/1:write enable
;	b6 0:busy/1:ready
;	b0 0:success/1:fail
read_st:
		pushu	x
		mv	a,$70
		call	cmd_out ;rel
		mv	a,[dat]
		popu	x
		ret

;read ID
;(bl):maker code
;(bh):device code
;(dl):?
;(dh):?
read_id:
		call	reset ;rel
		enable
		pushu	x
		call	read_id1 ;rel
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
		call	cmd_out ;rel
		mv	a,0
		call	adr1_out ;rel
		mv	il,20
		wait
		mv	x,dat
		ret

;reset
reset:
		enable
		pushu	x
		mv	a,$ff
		call	cmd_out ;rel
		disable
		popu	x
		rc
		ret

copy_mpb:
		mv	x,mpb+smpb ;rel
		mv	y,mpb ;rel
		mv	il,smpb*(nmpb-1)

mpbcp1:		mv	a,[y++]
		mv	[x++],a
		dec	il
		jrnz	mpbcp1

		ret

;容量の判別
check24:
		and	[invalid],$fe ;rel
		test	[autodetect],1 ;rel
		jrz	check243

		call	read_id ;rel
		mv	x,dev_id ;rel
		mv	y,capacity ;rel
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
		or	[invalid],1 ;rel
		sc
		jr	check242
check241:
		mv	il,[y]
		sub	il,a
		rc
		jrz	check242
		mv	[y],a
check243:
		IFNE	(media_type)-(0)
		call	make_mpb ;rel
		ENDIF
check242:
		ret

		IFNE	(media_type)-(0)
make_mpb:
		mv	a,[capacity] ;rel
		mv	x,mpb ;rel
		mv	y,mpb_list ;rel
		mv	il,mpb_4 - mpb_2
make_mpb0:
		dec	a
		jrz	make_mpb1
		add	y,i
		mv	b,a
		mv	a,[y]
		inc	a
		jrz	make_mpb3
		mv	a,b
		jr	make_mpb0
make_mpb1:
		mv	ba,[y]		;page size
		mv	il,[y+3]	;pages
		call	mul2n ;rel
		mv	i,ssect
		sub	i,ba
		jrnc	make_mpb2
make_mpb3:
		or	[invalid],2 ;rel
		jr	make_mpbe	;cache size < sector size
make_mpb2:
		and	[invalid],$fd ;rel
		mv	[x+1],ba
		mv	il,[y+3]	;pages
		mv	[pages],il ;rel
		mv	il,32
		call	div2n ;rel
		dec	ba
		ex	a,b
		mv	a,0		;255以上->255
		ex	a,b
		mv	[x+3],a
		inc	ba
		call	log ;rel
		mv	[x+4],a

		mv	ba,[y+4]	;blocks
		mv	i,tdat
		sub	ba,i
		inc	ba
		mv	[x+$e],ba

		mv	a,[y+2]		;apare area size
		mv	[sasize],a ;rel

		mv	ba,[y]		;page size
		mv	il,8
		call	div2n ;rel
		mv	[p8size],ba ;rel

		call	copy_mpb ;rel

		rc
make_mpbe:
		ret

;2^n倍
;ba=ba*il (il=2^n)
mul2n:
		pmdf	($ec),-2

		mv	(bp+0),ba
		mv	ba,i
		cmp	a,0
		jrz	mul2ne
mul2n0:
		shr	a
		jrc	mul2n1
		shl	(bp+0)
		shl	(bp+1)
		jr	mul2n0
mul2n1:
		mv	ba,(bp+0)
mul2ne:
		pmdf	($ec),2
		ret

;1/2^n
;ba=ba/il (il=2^n)
div2n:
		pmdf	($ec),-2

		mv	(bp+0),ba
		mv	ba,i
		cmp	a,0
		jrz	div2ne
div2n0:
		shr	a
		jrc	div2n1
		shr	(bp+1)
		shr	(bp+0)
		jr	div2n0
div2n1:
		mv	ba,(bp+0)
div2ne:
		pmdf	($ec),2
		ret

;a=log2ba
log:
		inc	ba
		dec	ba
		jrz	loge
		mv	il,-1
log0:
		inc	il
		ex	a,b
		shr	a
		ex	a,b
		shr	a
		jrnc	log0

		mv	a,il
loge:
		ret
		ENDIF

;=====================================================================
;			Static Variables
;=====================================================================

cachehit:	dp	0
read_count:	dp	0
program_count:	dp	0

initcmd:	db	0

capacity:	db	1
autodetect:	db	1

invalid:	db	0

p8size:		dw	256/8		;page size/8
sasize:		db	8		;spare area size
pages:		db	16		;pages

;1:2MB 2:4MB 3:8MB 4:16MB 5:32MB
dev_id:
		db	$ec,$64,1	;SAMSUNG 2MB-5V
		db	$ec,$ea,1	;SAMSUNG 2MB-3.3V
		db	$98,$64,1	;TOSHIBA 2MB-5V
		db	$98,$ea,1	;TOSHIBA 2MB-3.3V

		IFNE	(media_type)-(0)
		db	$ec,$e5,2	;SAMSUNG 4MB-5V
		db	$ec,$e3,2	;SAMSUNG 4MB-3.3V
		db	$98,$6b,2	;TOSHIBA 4MB-5V
		db	$98,$e5,2	;TOSHIBA 4MB-3.3V

		db	$ec,$e6,3	;SAMSUNG 8MB-3.3v
		db	$98,$e6,3	;TOSHIBA 8MB-3.3v
		ENDIF

		IFEQ	(media_type)-(2)
		db	$ec,$73,4	;SAMSUNG 16MB-3.3v
		db	$98,$73,4	;TOSHIBA 16MB-3.3v

		db	$ec,$75,5	;SAMSUNG 32MB-3.3v
		ENDIF

		db	-1,-1,-1

;=====================================================================
;			Media Parameter Block
;=====================================================================
		IFNE	(media_type)-(0)
mpb_list:
mpb_2:
		dw	256		;page size
		db	8		;spare area size
		db	16		;pages
		dw	512		;blocks
mpb_4:
		dw	512		;page size
		db	16		;spare area size
		db	16		;pages
		dw	512		;blocks
mpb_8:
		dw	512		;page size
		db	16		;spare area size
		db	16		;pages
		dw	1024		;blocks
		ENDIF

		IFEQ	(media_type)-(2)
mpb_16:
		dw	512		;page size
		db	16		;spare area size
		db	32		;pages
		dw	1024		;blocks
mpb_32:
		dw	512		;page size
		db	16		;spare area size
		db	32		;pages
		dw	2048		;blocks
		ENDIF
		db	-1

nroot:		equ	256		;num of root dir
nrootb:		equ	2		;num of root dir blocks
nfat:		equ	1		;num of fat sector
tdir:		equ	nfat
tdat:		equ	nfat+nrootb

mpb:
		db	$ff		; Fat Id
		dw	ssect		; Sector Size
		db	128-1		; Dir - 1
		db	7		; 2^7 = Dir
		db	$00,$01		; ?
		dw	$0000		; Fat Sector
		db	$08		; ?
		dw	nroot		; Root Dirs
		dw	tdat		; Data Top Sector
		dw	$0200-tdat+1	; Total Dat Sector (1010) + 1
		db	nfat		; Total Fat sector
		dw	tdir		; Dir Top sector
mpb_bottom:

smpb:		equ	mpb_bottom-mpb	;mpb size
mpbe:		equ	mpb+smpb*nmpb

cache:		equ	mpbe

block_bottom:

checkProg:
		rc
		retf

creditMsg:	db	'Smartmedia driver/1.20 (c)K.Takamatsu',$0d,$0a,$00

relTbl:
		end
