;	Text Editor 'PANORAMA' ver 1.22
;	by Daisuke Mizobata
;
	pre_on
	scope_on
	org	$bd000
;
fcs:	equ	$fffe4
iocs:	equ	$fffe8
lzfcs:	equ	$bfbf8
ptrx:	equ	$ed
bx:	equ	$d4
cx:	equ	$d6
dx:	equ	$d8
si:	equ	$da
di:	equ	$dd
bwork:	equ	$d1
btext:	equ	$cb
bdata:	equ	$ce
cdrv:	equ	$bfc7d
mtop:	equ	$bfd1a
fontad:	equ	$bfc87
sym:	equ	$bfc9a
rev:	equ	$bfca1
;
base:	equ	$50
diskbuf:equ	256
uwid:	equ	79
twid:	equ	8
wwid:	equ	70
scrmgn:	equ	14	;	スクロールするときの画面右端からの幅
sclmgn:	equ	4	;		〃		左端からの幅
fndsiz:	equ	246	;	検索／置換の最大文字数
scpsiz:	equ	512	;	スクラップのバイト数
undosiz:equ	256	;	Undoできるバイト数
nhist:	equ	3	;	[↑]で保存するファイル数
prefver:equ	3	;	PANO.CFGのバージョン
;
dvwid:	equ	0	;	1行の幅
scmax:	equ	1	;	scwidの最大値
scwid:	equ	2	;	スクロールした幅
curx:	equ	3	;	カーソルX座標
cury:	equ	4	;	カーソルY座標
vx:	equ	5	;	上下移動するときのカーソルX座標
ins:	equ	6	;	0:上書きモード／2:挿入モード
filtop:	equ	7	;	文書先頭
filend:	equ	10	;	文書末尾+1
gaptop:	equ	13	;	ギャップ先頭
gapend:	equ	16	;	ギャップ末尾+1
cptr:	equ	19	;	カーソル位置のポインタ
ltptr:	equ	22	;	行先頭のポインタ
mark:	equ	25	;	ブロック指定を開始した座標
clpsiz:	equ	28	;	カットバッファの大きさ
lineno:	equ	31	;	現在の行番号
maxlin:	equ	33	;	最大行番号
mrklin:	equ	35	;	markの行番号
mode:	equ	37
margin:	equ	38	;	左マージン
u_flag:	equ	39	;	UNDOの状態
subwid:	equ	40	;	現在使っていない画面幅
tabwid:	equ	41	;	TABの幅
;wksum:	equ	42	;	ここまでのチェックサム
;
wksiz:	equ	42	;	エディットに使うワークエリアの大きさ
;
block1:	equ	42	;	ブロックの先頭アドレス
block2:	equ	45	;	ブロックの終了アドレス+1
blocks:	equ	48	;	ブロックの大きさ
dwid:	equ	51	;	実際のディスプレイの幅
dhei:	equ	52	;	実際のディスプレイの高さ
dswid:	equ	53	;	dwid+scwidとdvwidの小さいほう
scrx:	equ	54	;	処理中のX座標
scry:	equ	55	;	処理中のY座標
cry:	equ	56	;	CRが位置するY座標
fcmp:	equ	56
hdl:	equ	57	;	ファイル・ハンドル
bsize:	equ	58
poi:	equ	61
rest:	equ	64
pstsiz:	equ	64	;	ペーストするデーターの大きさ(restと共用)
eof:	equ	68	;	EOFの先まで読み込むか
smode:	equ	69
tmode:	equ	70	;	改行コードの種類、EOFの有無
keycd:	equ	71	;	キーコード
dblwk:	equ	73	;	2バイト文字を扱うときのワーク
errno:	equ	74
parawk:	equ	74
fpmode:	equ	75	;	FEPのモード
oldfnt:	equ	76
flen:	equ	79	;	検索文字列の長さ
histp:	equ	79	;	[↑]でいくつ前のファイル名を表示するか(flenと共用)
fstat:	equ	80	;	ファイルの最後まで検索したか
pstins:	equ	80	;	ペースト時に挿入するか上書きするか(fstatと共用)
fptr:	equ	81
scrapp:	equ	81	;	処理中のスクラップのポインタ(fptrと共用)
fmatch:	equ	84
ftail:	equ	87	;	検索文字列の最後の文字
fline:	equ	88	;	検索中の行番号
qline:	equ	88	;	引用符処理中の行番号(flineと共用)
wrpwid:	equ	90	;	改行挿入幅
scps:	equ	91
pref_d:	equ	93	;	プレファレンスの設定
;
m_find:	equ	1	;	検索文字列入力中
m_mdf:	equ	2	;	書き換えたかどうか
m_tab:	equ	4	;	タブを表示するか
m_cre:	equ	8	;	改行／EOFを表示するか
m_rev:	equ	16	;	反転表示しているか
m_pfmk:	equ	32	;	[PF3]を押したか
m_fnmk:	equ	64	;	検索結果を表示しているか
m_alert:equ	128	;	画面下にメッセージを表示するか
;
s_ind:	equ	1	;	オートインデント・モード
s_pf:	equ	2	;	PFキーは有効か
s_eof:	equ	4	;	テキスト末尾にEOFをつけるか
s_crlf:	equ	8	;	行末はCR+LFか
;
r_calc:	equ	1	;	x座標を再計算する
r_vx:	equ	2	;	(vx)を更新する
r_adj:	equ	4	;	はみ出しているとき書き換える
r_xadj:	equ	8	;	はみ出しを補正して全て書き換える
r_all:	equ	16	;	全て書き換える
;
c_ver:	equ	0		;	バージョンNo.
c_org:	equ	c_ver+1		;	TAB/CR/EOFの表示
c_sym:	equ	c_org+1		;	オートインデント、PFキー
c_swid:	equ	c_sym+1		;	ユーザー指定の画面幅
c_twid:	equ	c_swid+1	;	タブ幅
c_wwid:	equ	c_twid+1	;	改行挿入幅
c_scps:	equ	c_wwid+1	;	スクラップの大きさ
c_pref:	equ	c_scps+2	;	プレファレンスの設定
c_lfil:	equ	c_pref+1	;	最後にsaveしたファイル名
c_line:	equ	c_lfil+18	;	saveしたときの行番号
c_fbuf:	equ	c_line+2	;	検索文字列
c_rbuf:	equ	c_fbuf+fndsiz+1	;	置換文字列
c_nbuf:	equ	c_rbuf+fndsiz+1	;	[↑]で表示されるファイル名
c_scrap:equ	c_nbuf+33*nhist	;	スクラップ領域
c_size:	equ	c_scrap+scpsiz
;
	MACRO	SAVE_U
	pushu	imr			;	割り込み禁止
	mv	[--s],u			;	pushs u
	ENDM
;
	macro	LOAD_U
	mv	u,[s++]			;	pops u
	popu	imr
	endm
;
	macro	BEEP
	mv	a,$07
	mv	il,$0d
	call	lcdd
	endm
;
	macro	CLRFND
	test	(bp+mode),m_fnmk
	jrz	*+5			;	次の行をスキップ
	and	(bp+mode),$ff-(m_pfmk+m_fnmk+m_rev)
	endm
;
	macro	CLRFND2
	and	(bp+mode),$ff-(m_pfmk+m_fnmk+m_rev)
	endm
;
undobuf:equ	*-undosiz	;	Undo用バッファ
mend:	equ	undobuf
;
main:	local
	mv	[--s],($ec)
	mv	($ec),base
;
;	LZ 10/9erの常駐チェック
	mvw	(bp+cx-base),$08
	mv	il,$7f
	call	icall
	mv	x,fcs
	jrc	notlz
	mv	x,lzfcs
notlz:	mv	[fcall+1],x
;
	mvw	(bp+dwid),[$bfc9d]
	mvp	(bp+bsize),diskbuf
;
	mv	i,title-ms
	call	putm2
;
	call	makecfg
	mv	il,cfg_e-ms
	jpc	errend
	mv	a,[y++]			;	c_org
	or	a,m_alert
	mv	(bp+mode),a
	mv	a,[y++]			;	c_sym
	mv	(bp+smode),a
	and	a,s_eof+s_crlf
	mv	(bp+tmode),a
	mvw	(bp+subwid),[y++]	;	c_swid,c_twid
	mv	(bp+wrpwid),[y++]	;	c_wwid
	mvp	(bp+scps),[y++]		;	c_scps,c_pref
;
;	パラメーターをチェックする
	and	[fname],0
	popu	x
	call	getpara
	pushu	x
	jrnc	paraok
	mv	i,help-ms
	jp	errend
paraok:
;	test	(bp+parawk),2
;	jrz	norsm
;;	-Rオプションの処理
;	call	loadwk
;;	ワークエリアのチェックサムを検査
;	mv	(bp+ptrx-base),wksiz-2
;rloop:	mv	a,(bp+px)
;	sub	(bp+wksum),a
;	sub	(bp+ptrx-base),1
;	jrnc	rloop
;	cmp	(bp+wksum),0
;	jrz	rsmok
;	mv	il,rsm_e-ms
;	jr	errend
;;	リジューム処理
;rsmok:	mv	a,$0d
;	mv	[(bp+filtop)-1],a
;	mv	[(bp+gaptop)-1],a
;	mv	x,(bp+filend)
;	mv	[x-1],a
;	mv	y,(bp+gapend)
;	call	gapfwd3
;	mv	y,(bp+filtop)
;	mv	x,(bp+gaptop)
;	call	chkdbl
;	jr	start
;
norsm:	mv	y,mend
	mv	(bp+filend),y
	dec	y
	mv	(bp+gapend),y
	mv	x,[mtop]
	dec	y
	sub	y,x
	jrnc	memok
	mv	il,mem_e-ms
	jr	errend
memok:	sub	y,y
	mv	(bp+clpsiz),y
	mv	a,$0d
	mv	[x++],a
	mv	(bp+filtop),x
	mv	(bp+gaptop),x
;
	call	initwk
	mv	(bp+ins),2
	mvw	(bp+margin),0		;	mv (bp+u_flag),0
	mv	(bp+dvwid),(bp+dwid)
;
	mv	x,fname
	test	(bp+parawk),1
	jrz	noload
	call	load
	call	filcmp
;
noload:
	mv	x,(bp+gaptop)
	mv	a,$0d
	mv	[x++],a
	mv	(bp+gaptop),x
	mv	x,(bp+gapend)
	inc	x
	mv	(bp+gapend),x
;
start:
	mv	il,c_pref+$22
	call	getcfg
	mv	(bp+pref_d),[y]		;	Pref再読み込み(-E,Sオプションを無効)
	test	(bp+parawk),4		;	オプションに行番号を指定したか
	jrz	frmtop
	mv	y,(bp+gaptop)
	dec	y
	call	bfrcr2
	mv	(bp+ltptr),y
	mv	(bp+cptr),y
	mvw	(bp+lineno),(bp+maxlin)
	mv	i,(bp+fline)
	call	golini
	mv	(bp+cury),1
frmtop:	mv	y,(bp+cptr)
	call	gapbac2
	call	putall
	call	putsym
;
loop:
	call	keyp
	ex	a,b
	cmp	a,$05			;	[BASIC]キー
	jrz	menuok
	cmp	a,$06			;	[MENU]
	jrnz	nomenu
menuok:
	call	fpsave
	call	domenu
	shr	a
	jrc	loope
	call	putall
	call	fpres
	jr	loop
nomenu:
;	cmp	a,$cf			;	CTRL+[+/-]
;	jrnz	nodbg
;	call	gapclr			;	デバッグ用
;	jr	loop
nodbg:	ex	a,b
	mv	x,cttab
	mv	il,ctnum
	call	ed_key
	jrnc	l2
	call	dispadj
	jr	loop
l2:	shr	a
	jrnc	l4
	call	xadj
	jr	l5
l4:	shr	a
	jrnc	loop
l5:	call	putall
	jr	loop
loope:
	call	savewk
	mv	il,c_org+$22
	call	getcfg
	mv	a,(bp+mode)
	and	a,m_tab+m_cre
	mv	[y++],a			;	c_orgに保存
	mv	[y++],(bp+smode)	;	c_symに保存
	mv	il,$51			;	画面消去
	call	lcdd
	mv	(bp+smode),0
	call	putsym			;	シンボル消灯

bas:	mv	($ec),[s++]
	rc
	retf
errend:
	call	putm2
	jr	bas
	endl

domenu:	local
	mv	x,menu_m
	mv	ba,5
	mvw	(bp+bx-base),$0300
	mv	il,$58
	call	lcdd
	call	keys2
	mv	x,mntab
	mv	il,mnnum
	call	kcall
	ret
	endl

inpfnd:
;	検索文字列の入力
	mv	il,c_fbuf+$22
	call	getcfg
	mv	il,srch_m-ms
	mv	x,y

inputs:	local
;	検索／置換文字列の入力
	pushu	x
	pushu	i
	call	inputi
	mv	il,[x++]
	inc	il
loop1:	dec	il
	jrz	loop1e
	mv	a,[x++]
	mv	[y++],a
	jr	loop1
loop1e:	mv	a,$0d
	mv	[y++],a
	mv	(bp+gaptop),y
	mv	x,buf+fndsiz+2
	mv	(bp+gapend),x
	mv	(bp+filend),x
	mv	a,255
	mv	(bp+dvwid),a
	sub	a,(bp+dwid)
	mv	(bp+scmax),a
	popu	i
	call	inputl
	mv	y,[u]
	pushu	a
	jrc	l1
	dec	il
	mv	[y++],il
	jrz	l1
	call	xtoy
l1:	call	loadwk
	popu	a
	popu	y
	ret
	endl

inputn:	local
;	数字を入力する
	pushu	i
	call	fpsave
	call	inputi
	mv	a,$0d
	mv	[y++],a
	mv	(bp+gaptop),y
	mv	x,buf+32+2
	mv	(bp+gapend),x
	mv	(bp+filend),x

	mv	(bp+dvwid),40
	popu	i
	call	inputl
	jrc	l1
	dec	i
	jrz	l1
	call	str2i
	jrc	err
	cmp	a,$0d
	jrz	l2
err:	or	(bp+mode),m_alert
	mv	il,num_e-ms
	call	alert
l1:	sc
l2:	pushu	f
	pushu	i
	call	loadwk
	call	fpres
	popu	i
	popu	f
	ret
	endl

inputl:	local
;	1行入力
;	i->メッセージのオフセット
;	c=1:[リターン]で終了
;	i<-入力された文字数(最後のCRを含む)
;	x<-文字列の先頭アドレス
	mv	(bp+bx-base),0
	mv	(bp+bx-base+1),(bp+dhei)
	dec	(bp+bx-base+1)
	call	putm
	mv	a,'>'
	call	putc
	call	initwk
	mv	(bp+tabwid),1		;	TAB幅は1桁
	and	(bp+mode),m_find	;	EOFを表示しない
	mv	(bp+ins),0
	mvw	(bp+curx),(bp+bx-base)	;	編集開始座標
	mv	(bp+margin),(bp+curx)
	call	putlt
loop:	call	keyp
	cmp	a,$0d
	jrz	l4
	test	(bp+mode),m_find
	jrz	l3
	cmp	a,$1e
	jrz	l4
	cmp	a,$1f
	jrz	l4
	ex	a,b
	cmp	a,$2d
	jrnz	l5
l4:	mv	x,(bp+filtop)
	mv	y,(bp+gaptop)
	sub	y,x
	mv	i,y
	jr	l1
l3:	ex	a,b
l5:	cmp	a,$05			;	[BASIC]キー
	sc
	jrz	l1
	cmp	a,$06			;	[MENU]
	sc
	jrz	l1
	ex	a,b
	mv	x,cltab
	mv	il,clnum
	call	ed_key
	jrnc	l2
	call	xadj
	jrz	loop
	call	putlt
	jr	loop
l2:	jrz	loop
	call	xadj
	call	putlt
	jr	loop
l1:	ret
	endl

inputi:
;	inputlルーチンを実行するための初期化をする
	call	savewk
	mv	y,buf
	mv	a,$0d
	mv	[y++],a
	mv	(bp+filtop),y
	ret

ed_key:	local
	call	ed_key2
	and	[rev],$bf
	shr	a
	jrnc	l3
	pushu	a
	call	xrecalc
	popu	a
l3:	shr	a
	jrnc	l1
	mv	(bp+vx),(bp+curx)
l1:	shr	a
	ret

ed_key2:
	cmp	a,$20
	jrc	kcall
	cmp	a,$7f
	jpz	delete
	jp	keyin
	endl

kcall:	local
;	baで示すキーコードのルーチンにジャンプ
;	x->キーコードテーブル
;	i->定義されているキーの数
	mv	(bp+keycd),ba
loop:
	mv	ba,[x++]
	cmpw	(bp+keycd),ba
	mv	ba,[x++]
	jrnz	l1
	pushs	ba
	ret
l1:	dec	il
	jrnz	loop
	mv	a,0
	ret
	endl

hist:	local
;	1行入力でしか使えないルーチン
	mv	i,c_nbuf+$22
	call	getcfg
	mv	a,(bp+histp)
	mv	il,33
loop2:	sub	a,1
	jrc	loop2e
	add	y,il
	jr	loop2
loop2e:
	inc	(bp+histp)
	cmp	(bp+histp),nhist
	jrc	l2
	mv	(bp+histp),0
l2:	mv	a,[y]
	cmp	a,0
	jrz	l1
	mv	x,(bp+filtop)
	mv	(bp+cptr),x
	mv	il,[y++]
loop1:	mv	a,[y++]
	mv	[x++],a
	dec	il
	jrnz	loop1
	mv	a,$0d
	mv	[x++],a
	mv	(bp+gaptop),x
	mv	a,r_calc+r_xadj
l1:	ret
	endl

ctrq:	local
	call	putcrsb
	call	keys2
	pushu	ba
	call	clrcur
	popu	ba
l1:	mv	x,cqtab
	mv	il,cqnum
	call	kcall
	ret
	endl

asksave:local
	test	(bp+mode),m_mdf
	jrz	l1
	mv	il,end_m-ms
	call	putel
	call	putp
	call	keys2
	and	a,$df			;	大文字小文字を無視する
	cmp	a,'N'
	jrz	l1
	cmp	a,'Y'
	jrnz	l2
	call	save
	jrnc	l1
l2:	call	kclr
	mv	a,0
	ret
l1:	mv	a,1
	ret
	endl

pref:	local
;	プレファレンス
	sub	($ec),7
	mv	(bp+0),(pref_d+base)
	mvp	(bp+3),$010001		;	(bp+3)：マスクビット
	mv	(bp+6),0

loop4:
	mv	x,pref_m
loop3:
	pushu	x
	mv	il,$51			;	画面消去
	call	lcdd
	popu	x
	mvw	(bp+1),$0003		;	(bp+1,2)：X,Y座標
loop1:
	mvw	(bx),(bp+1)
	call	putp
	pushu	x
	call	onoff
	popu	x
	rol	(bp+3)
	inc	(bp+2)
	mv	a,[x]
	cmp	a,0
	jrnz	loop1
	mv	(bp+1),1
	mvw	(bp+2),(bp+4)

loop2:
	mvw	(bx),(bp+1)
	mv	a,'*'
	call	putc
	call	keys2
	cmp	a,$1c
	jrz	sw
	cmp	a,$1d
	jrz	sw
	cmp	a,' '
	jrnz	l2
sw:	xor	(bp+0),(bp+3)		;	ON/OFFの反転
	call	onoff
	jr	loop2
l2:	cmp	a,$0d
	jrnz	l3
	mv	(pref_d+base),(bp+0)
	mv	il,c_pref+$22
	call	getcfg
	mv	[y],(bp+0)		;	カスタマイズ内容を保存
	jr	loope
l3:	pushu	ba
	mvw	(bx),(bp+1)
	call	putspc
	popu	ba
	cmp	a,$1e
	jrnz	l4
	cmp	(bp+6),0
	jrz	loop2
	dec	(bp+6)			;	ひとつ上へ
	ror	(bp+3)			;	マスクビットをずらす
	sub	(bp+2),1
	jrnc	loop2
	mvp	(bp+3),$080301
	jr	loop4
l4:	cmp	a,$1f
	jrnz	l5
	cmp	(bp+6),5
	jrz	loop2
	inc	(bp+6)			;	ひとつ下へ
	rol	(bp+3)			;	マスクビットをずらす
	inc	(bp+2)
	cmp	(bp+2),4
	jrc	loop2
	mv	x,pref2_m
	mvp	(bp+3),$100010
	jr	loop3
l5:	mv	a,b
	cmp	a,$05
	jrz	loope
	cmp	a,$06
	jrnz	loop2
loope:
	pmdf	($ec),7
	mv	a,0
	ret
onoff:
	mv	i,onof_d-ms
	mv	a,(bp+0)
	test	(bp+3),a
	mv	(bx),20
	jr	showrev

	endl	;of pref

fform:	local
	sub	($ec),3
	mv	(bp+2),(base+tmode)
	mv	il,$51			;	画面消去
	call	lcdd
	mv	x,form_m
	mvw	(bp+0),$0003		;	(bp+0,1)：X,Y座標
loop1:
	mvw	(bx),(bp+0)
	call	putp
	pushu	x
	call	showmod
	popu	x
	inc	(bp+1)
	cmp	(bp+1),2
	jrc	loop1
	mvw	(bp+0),$0001

loop2:
	mvw	(bx),(bp+0)
	mv	a,'*'
	call	putc
	call	keys2

	cmp	a,$1c
	jrz	sw
	cmp	a,$1d
	jrz	sw
	cmp	a,' '
	jrnz	l2
sw:	cmp	(bp+1),0
	jrz	sw1
	xor	(bp+2),s_crlf
	jr	sw2
sw1:	xor	(bp+2),s_eof
sw2:	call	showmod
	jr	loop2
l2:	cmp	a,$0d
	jrnz	l3
	mv	(base+tmode),(bp+2)
	cmp	[fname],0
	jrnz	loope
	mv	a,(base+smode)
	and	a,$ff-(s_eof+s_crlf)
	or	a,(bp+2)
	mv	(base+smode),a
	jr	loope
l3:	pushu	ba
	mvw	(bx),(bp+0)
	call	putspc
	popu	ba
	cmp	a,$1e
	jrnz	l4
	mv	(bp+1),0
	jr	loop2
l4:	cmp	a,$1f
	jrnz	l5
	mv	(bp+1),1
l5:	mv	a,b
	cmp	a,$05
	jrz	loope
	cmp	a,$06
	jrnz	loop2
loope:
	mv	a,0
	add	($ec),3
	ret

showmod:
	mv	(bx),17
	mv	a,(bp+2)
	xor	a,s_crlf+s_eof
	cmp	(bp+1),0
	jrz	l1
	mv	i,cr_d-ms
	test	a,s_crlf
	jr	showrev
l1:
	mv	i,eof_d-ms
	test	a,s_eof
	endl	; of fform

showrev:local
	jrz	l1
	or	[rev],$40
l1:	call	putm
	xor	[rev],$40
	call	putp
	and	[rev],$bf
	ret
	endl

rename:	local
;	リネームしてSaveする
	call	inputi
	mv	x,fname
loop1:	mv	a,[x++]
	cmp	a,' '
	jrz	loop1
	jrc	loop1e
	mv	[y++],a
	jr	loop1
loop1e:
	mv	il,end_m-ms
	call	inputf
	jrc	l2
	call	askow
	jrnc	l2
	mv	x,subnam
	call	save2
	jrc	l2
	mv	y,fname
	mv	il,19
	call	xtoy
l2:	mv	a,0
	ret
	endl

import:	local
	call	inputi
	mv	il,impo_m-ms
	call	inputf
	jrc	l1
	and	(bp+mode),$ff-(m_pfmk+m_fnmk+m_rev)
	mv	y,(bp+cptr)
	mv	(bp+block1),y
	call	gapback
	mvp	(bp+blocks),0
	call	savundo
	mvw	[--u],(bp+maxlin)
	mv	[--u],(bp+tmode)
	mv	x,subnam
	call	load
	mv	(bp+tmode),[u++]
	popu	ba
	jrc	l3
	or	(bp+mode),m_mdf
	mv	i,(bp+maxlin)
	sub	i,ba
	pushu	f
	mv	ba,(bp+lineno)
	add	ba,i
	mv	[u_line],ba
	mvp	[u_end],(bp+gaptop)
	popu	f
	jrz	l2
	mv	y,(bp+cptr)		;	挿入ファイルにCRがあるとき
	call	gapbac2
	jr	l1
l2:	call	gapfwd			;	挿入ファイルにCRがないとき
l1:	mv	a,0
	ret
l3:	mv	il,opn_e-ms		;	ファイルが見つからないとき
	call	alert
	jr	l2
	endl

export:	local
	call	setblo
	test	(bp+mode),m_rev
	jrz	l1
	call	inputi
	mv	il,expo_m-ms
	call	inputf
	jrc	l1
	call	setblo
	call	chkow
	mv	x,subnam
	jrc	l2
	pushu	x
	call	owfile
	call	putp
;	[O]/[A]の入力
	call	keys2
	and	a,$df			;	大文字小文字を無視する
	popu	x
	cmp	a,'O'
	jrz	l2
	cmp	a,'A'
	jrnz	l1
	call	addsave
	jr	l1
l2:	call	save_b
l1:	mv	a,0
	ret
	endl

inputf:	local
;	ファイル名を入力
;	y->初期文字列終了アドレス
;	i->メッセージオフセット
	mv	a,$0d
	mv	[y++],a
	mv	(bp+gaptop),y
	mv	x,buf+32+2		;	ファイル名は32文字まで
	mv	(bp+gapend),x
	mv	(bp+filend),x

	mv	(bp+histp),0
	mv	(bp+dvwid),40
	call	inputl
	jrc	l1
	dec	il
	sc
	jrz	l1
	mv	y,subnam
	pushu	x
	pushu	il
	inc	il
	mv	a,1
	call	file
	mv	i,c_nbuf+33*(nhist-1)+$22
	call	getcfg
	mv	il,33*(nhist-1)
loop2:	mv	a,[--y]
	mv	[y+33],a
	dec	il
	jrnz	loop2
	popu	il
	popu	x
	mv	[y++],il
	call	xtoy
l1:	call	loadwk
	ret
	endl

inrplc:	local
;	置換文字列入力
	call	inpfnd
	jrc	!find!l1
	mv	i,c_rbuf+$22
	call	getcfg
	mv	x,y
	mv	il,rplc_m-ms
	or	(bp+mode),m_find
	call	inputs
	and	(bp+mode),$ff-m_find
	jrc	!find!l1
	cmp	a,$2d
	jrz	!find!l1
	and	(bp+mode),$ff-(m_pfmk+m_rev)
	cmp	a,$1e
	jrnz	fndhere
	jp	findbf
	endl

find:	local
	or	(bp+mode),m_find
	call	inpfnd
	and	(bp+mode),$ff-m_find
	jrc	l1
	cmp	a,$2d
	jrz	l1
	cmp	a,$1e
	jrnz	findnx
	jp	findbf
l1:	mv	a,r_all
	ret
	endl

rplfwd:
	call	replace

fndhere:
	mvp	(bp+fptr),(bp+cptr)
	jr	findnx!l4

findnx:	local
;	前方検索
	mv	y,(bp+cptr)
	mv	a,[y++]
	cmp	a,$0d
	jrnz	l17
	dec	y
l17:	mv	(bp+fptr),y
l4:	mv	i,(bp+lineno)
	mv	(bp+fline),i

	call	copyfnd
	jrz	l1
	mv	(bp+fstat),0
	mv	(bp+flen),il
	mv	x,buf
	mv	a,256			;	バグではない
loop1:
	mv	[x++],il
	dec	a
	jrnz	loop1
	dec	il
	pushu	il
	jrz	l3
loop2:
	mv	x,buf
	mv	a,[y++]
	test	(bp+pref_d),2
	jrz	l15
	call	toupper
l15:	add	x,a
	mv	[x],il
	dec	il
	jrnz	loop2
l3:	mv	(bp+fmatch),y
	mv	(bp+ftail),[y]
	popu	a

loop3:
	mv	y,(bp+fptr)
	add	y,a
	mv	(bp+fptr),y
loop5:	cmpp	(bp+fptr),(bp+gaptop)
	jrc	l7
	cmpp	(bp+filend),(bp+gapend)
	jrnz	l8
;	ファイルの末尾まで行ってしまった場合
	test	(bp+pref_d),1
	jrnz	l14
	mv	y,(bp+cptr)
	call	gapbac2
	jr	nfend
l14:	test	(bp+fstat),1
	jrnz	l7			;	1回戻っているとき
	or	(bp+fstat),1
	mvw	(bp+fline),0
	mv	y,(bp+filtop)
	call	gapback
	mv	a,(bp+flen)
	add	y,a
	dec	y
	dec	y
	mv	(bp+fptr),y		;	先頭に戻る
l8:	call	gapfwd
	add	(bp+fline),1
	adc	(bp+fline+1),0
	jr	loop5			;	2行以上一度に読み飛ばすこともある
l7:
	test	(bp+fstat),1
	jrz	l12
	cmpp	(bp+fptr),(bp+cptr)
	jrnc	nfend			;	何も見つからなかった

l12:	mv	y,(bp+fptr)
	mv	a,[y]
	mv	(bp+fcmp),(bp+ftail)
	call	lowcmp
	jrnz	l9
	mv	x,(bp+fmatch)
	mv	il,(bp+flen)
loop4:
	dec	il
	jrnz	l10
;	見つかったときの処理
	mv	y,(bp+fptr)
	mv	il,(bp+flen)
	dec	il
	sub	y,il
	call	found
	jrc	l11
	mv	i,(bp+fline)
	test	(bp+mode),m_pfmk
	jrnz	l18
	mv	(bp+mrklin),i
l18:	mv	(bp+lineno),i
	test	(bp+fstat),1
	jrz	fndend
	mv	il,rev_m-ms
	jr	msgend
l10:	mv	a,[--y]
	mv	(bp+fcmp),[--x]
	call	lowcmp
	jrz	loop4
l11:	mv	a,(bp+ftail)
l9:	mv	x,buf
	test	(bp+pref_d),2
	jrz	l16
	call	toupper
l16:	add	x,a
	mv	a,[x]
	jr	loop3

nfend:
	mv	il,nf_e-ms
msgend:
	call	putel
msloop:	call	keys2
	mv	i,rfkey
	sub	i,ba
	jrz	msloop
fndend:
	call	setlt
l1:	mv	a,r_calc+r_vx+r_xadj
	ret
	endl

rplbfr:
	call	replace
	mvp	(bp+cptr),(bp+block1)

findbf:	local
;	後方検索
	call	copyfnd
	jrz	l1
	add	y,il
	mv	(bp+fstat),0
	mv	(bp+flen),il
	mv	x,buf
	mv	a,256			;	バグではない
loop1:
	mv	[x++],il
	dec	a
	jrnz	loop1
	jr	l3
loop2:
	mv	x,buf
	mv	a,[--y]
	add	x,a
	mv	[x],il
l3:	dec	il
	jrnz	loop2
	mv	(bp+fmatch),y
	mv	(bp+ftail),[--y]
	mv	y,(bp+cptr)
	mv	a,[--y]
	cmp	a,$0d
	jrz	l14
	inc	y
l14:	mv	(bp+fptr),y
	mv	a,1

loop3:
	mv	y,(bp+fptr)
	sub	y,a
	mv	(bp+fptr),y
	mv	y,(bp+filtop)
	dec	y
	cmpp	(bp+fptr),y
	jrnc	l7
;	ファイルの先頭まで行ってしまった場合
	test	(bp+pref_d),1
	jrz	nfend			;	Wrap aroundがOFFの場合
	test	(bp+fstat),1
	jrnz	l7
	or	(bp+fstat),1
	mv	x,(bp+filend)
	mv	y,(bp+gapend)
	call	gapfwd3
	mv	y,(bp+gaptop)
	mv	a,(bp+flen)
	sub	y,a
	mv	(bp+fptr),y		;	末尾に戻る
l7:
	test	(bp+fstat),1
	jrz	l12
	cmpp	(bp+cptr),(bp+fptr)
	jrnc	nfend

l12:	mv	y,(bp+fptr)
	mv	a,[y++]
	mv	(bp+fcmp),(bp+ftail)
	call	lowcmp
	jrnz	l9
	mv	x,(bp+fmatch)
	mv	il,(bp+flen)
loop4:
	dec	il
	jrnz	l10
;	見つかったときの処理
	mv	y,(bp+fptr)
	call	found
	jrc	l11
	mv	il,1
	mv	x,(bp+filtop)
loop5:
	cmpp	(bp+cptr),x
	jrz	loop5e
	mv	a,[x++]
	cmp	a,$0d
	jrnz	loop5
	inc	i
	jr	loop5
loop5e:
	test	(bp+mode),m_pfmk
	jrnz	l18
	mv	(bp+mrklin),i
l18:	mv	(bp+lineno),i
	test	(bp+fstat),1
	jrz	fndend
	mv	il,rev_m-ms
	jr	msgend

l10:	mv	a,[y++]
	mv	(bp+fcmp),[x++]
	call	lowcmp
	jrz	loop4
l11:	mv	a,(bp+ftail)

l9:	mv	x,buf
	add	x,a
	mv	a,[x]
	jr	loop3

nfend:
	mv	il,nf_e-ms
msgend:
	call	putel
msloop:	call	keys2
	mv	i,rbkey
	sub	i,ba
	jrz	msloop
fndend:
	mv	y,(bp+cptr)
	call	gapbac2
	call	setlt
l1:	mv	a,r_calc+r_vx+r_xadj
	ret
	endl


replace:local
	mv	i,c_rbuf+$22
	call	getcfg
	mv	il,[y++]
	mv	x,i
	jr	paste
;	ret
	endl

spaste:
;	スクラップからのペースト
	call	getscp
	mv	x,i
	mv	(bp+pstins),1
	jr	paste!paste2

cpaste:
	CLRFND
	mv	x,(bp+clpsiz)
	inc	x
	dec	x
	jrz	paste!l7		;	カットバッファがない
	mv	y,(bp+filend)		;	カットバッファの内容をペースト
	test	(bp+mode),m_alert
	jrnz	paste
	mv	y,[wkbuf+filend]	;	1行入力中のカットバッファ

paste:	local
;	汎用ペーストルーチン
;	y->ペーストする文字列の先頭アドレス
;	x->ペーストする文字列の大きさ
	mv	(bp+pstins),0
paste2:
	mv	(bp+pstsiz),x
	test	(bp+mode),m_alert
	jrnz	l8
	call	chkcr
	jrnc	l7
l8:	pushu	y
	mvp	(bp+block1),(bp+cptr)
	mvp	(bp+block2),(bp+cptr)
	test	(bp+pstins),1
	jrnz	l9
	call	setblo
l9:	call	blosiz
	mv	x,(bp+gapend)
	mv	y,(bp+gaptop)
	sub	x,y
	mv	y,(bp+blocks)
	add	x,y
	cmpp	(bp+pstsiz),x		;	x：ペーストに使えるメモリ容量
	jrz	l2
	jrnc	l1
l2:	call	savundo
	cmpp	(bp+block1),(bp+block2)
	jrnz	l3
	mv	y,(bp+cptr)
	cmpp	(bp+mark),y
	jrnz	l4
	call	gapback
	mv	(bp+mark),y
	jr	l6
l3:	call	linsub
	mv	y,(bp+block2)
	cmpp	(bp+gaptop),y
	jrnc	l4
	mv	(bp+gapend),y
	db	$0c			;	次の命令をスキップ
l4:	call	gapback
l6:	popu	x
	SAVE_U
	mv	u,x			;	u=転送元
	mv	y,(bp+block1)
	mv	(bp+cptr),y
	mv	x,(bp+pstsiz)
	inc	x
	jr	l5
loop:	popu	a			;	mv	a,[u++]
	mv	[y++],a
	cmp	a,$0d
	jrnz	l5
	add	(bp+maxlin),1
	adc	(bp+maxlin+1),0
	add	(bp+lineno),1
	adc	(bp+lineno+1),0
	test	(bp+pstins),1
	jrz	l5
	cmpp	(bp+mark),y
	jrc	l5
	add	(bp+mrklin),1
	adc	(bp+mrklin+1),0
l5:	dec	x
	jrnz	loop
	LOAD_U
	pushu	y
	call	addcury
	popu	y
	mv	(bp+gaptop),y
	mv	(bp+cptr),y
	call	gapfwd
	or	(bp+mode),m_mdf
	test	(bp+pstins),1
	jrnz	l10
	and	(bp+mode),$ff-(m_pfmk+m_fnmk+m_rev)
l10:	call	setundo
	mv	a,r_calc+r_vx+r_xadj
	ret
l1:	call	memerr
	popu	y
l7:	mv	a,r_all
	ret
	endl

undo:	local
	cmp	(bp+u_flag),0
	jrnz	l5
	mv	il,undo_e-ms
	call	alert
	mv	a,r_all
	jr	end
l5:
	and	(bp+mode),$ff-(m_pfmk+m_fnmk+m_rev)
	mv	x,(bp+gapend)
	mv	y,(bp+gaptop)
	sub	x,y

	mv	y,[u_end]
	add	y,x
	mv	(bp+mark),y

	mv	y,[u_stat]
	pushu	y
	cmpp	(bp+cptr),y
	jrc	l7
	call	subcury
	jr	l8
l7:	call	addcury
l8:	popu	y
	cmpp	(bp+gaptop),y
	jrnc	l1
	add	x,y
	mv	y,(bp+gapend)
	call	gapfwd3
	jr	l2
l1:
	call	gapback
l2:
	SAVE_U
	mv	u,undobuf
	mv	y,(bp+gaptop)
	mv	x,[u_siz]
	inc	x
	dec	x
	jrz	l4
	call	utoy
l4:
	LOAD_U
	mv	(bp+u_flag),0
	mv	(bp+cptr),y
	mv	(bp+gaptop),y
	mv	[u_end],y
	pushu	y
	call	addcury
	popu	y
	cmpp	(bp+gapend),y
	jrc	l9			;	redoできない

	SAVE_U
	mv	x,(bp+mark)
	mv	u,(bp+gapend)
	sub	x,u
	mv	[u_siz],x
	jrz	l6
	mv	y,undosiz-1
	sub	y,x
	jrc	l3			;	redoできない
	mv	y,undobuf
	call	utoy
l6:	inc	(bp+u_flag)
l3:	LOAD_U
l9:	mvp	(bp+gapend),(bp+mark)
	mv	ba,[u_max]
	mv	i,(bp+maxlin)
	mv	(bp+maxlin),ba
	mv	[u_max],i
	sub	ba,i
	mv	i,[u_line]
	add	i,ba
	mv	(bp+lineno),i
	mv	[u_line],i
	call	gapfwd
	or	(bp+mode),m_mdf
	mv	a,r_calc+r_vx+r_xadj
end:	ret
	endl

defscp:	local
	call	inpscp
	jrnc	li2
	mv	a,0
	ret

li2:	call	setblo
	mvw	(bp+blocks),0
	test	(bp+mode),m_rev
	jrz	l1
	call	blosiz
	cmp	(bp+blocks+2),0		;	選択領域が64KB以上のとき
	jrnz	l2
l1:	call	getscp
	sub	($ec),17
	mv	(bp+9),y
	mv	(bp+15),i
	mv	(bp+0),x
	mv	ba,(base+scps)
	add	x,ba
	mv	(bp+6),x

;	スクラップの最後部を探す
	add	y,i
	mv	(bp+3),y
	mv	a,sckey+9
	sub	a,(base+keycd+1)
loop:	jrz	loope
	mv	i,[y++]
	add	y,i
	dec	a
	jr	loop
loope:	mv	(bp+12),y
	SAVE_U
	mv	i,(base+blocks)
	cmpw	(bp+15),i
	jrc	bigger
;	これから登録するデーターのほうが小さい
	call	movscp
	mv	u,(bp+3)
	mv	x,(bp+12)
	sub	x,u
	jrz	end
	call	utoy
	jr	end

bigger:
;	これから登録するデーターのほうが大きい
	mv	x,y
	mv	u,(bp+3)
	sub	x,u
	jrz	l4
	mv	u,y
	mv	ba,(bp+15)
	sub	u,ba
	add	u,i
	cmpp	(bp+6),u
	jrc	errend
	call	ytou
l4:	call	movscp

end:	LOAD_U
	add	($ec),17
l3:	mv	a,r_all
	ret

errend:	LOAD_U
	add	($ec),17
l2:	call	memerr
	jr	l3

movscp:
;	選択範囲をスクラップにコピーする
	mv	y,(bp+9)
	mv	[y-2],i
	mv	u,(base+block1)
	inc	i
loop2:	dec	i
	jrz	loop2e
	popu	a
	mv	[y++],a
	cmpp	(base+gaptop),u
	jrnz	loop2
	mv	u,(base+gapend)
	jr	loop2
loop2e:	ret

	endl	;of defscp

quoman:
	mv	ba,qmmain
	jr	sellin2

wrpquo:
	mv	ba,wrpqum
	jr	sellin2

dquman:
	mv	ba,dqumm

sellin2:
	and	[sellin!ptch],$df	;	mv (n),y → mv y,(n)
	call	sellin
	or	[sellin!ptch],$20	;	mv y,(n) → mv (n),y
	ret

quote:
	mv	ba,quomain
	jr	sellin

delquo:	local
	call	inpscp
	jrnc	l1
	mv	a,0
	ret
l1:	mv	ba,dqumain
	jr	sellin
	endl

wraplin:
	mv	ba,wrpmain
	jr	sellin

tabspc:
	mv	ba,tabspm

sellin:	local
;	カーソルまたは、選択範囲のある行を全て選択して
;	コールバックを呼び出す
	mv	i,retad
	pushs	i			;	リターンアドレスをpush
	pushs	ba			;	コールバックルーチンのアドレス
	test	(bp+mode),m_pfmk+m_fnmk
	jrnz	l1
	mvp	(bp+mark),(bp+cptr)
	mvw	(bp+mrklin),(bp+lineno)
l1:	cmpp	(bp+cptr),(bp+mark)
	pushu	f
	jrc	l2
;	必ず(bp+mark)が(bp+cptr)より後ろに来るようにする
	exp	(bp+cptr),(bp+mark)
	exw	(bp+mrklin),(bp+lineno)
l2:
	call	bfrcr
ptch:	mv	(bp+cptr),y

	mv	y,(bp+mark)
	cmpp	(bp+cptr),y
	jrz	loop
	cmpp	(bp+gapend),y
	jrnz	l4
	mv	y,(bp+gaptop)
l4:	mv	a,[--y]
	cmp	a,$0d
	jrnz	loop
	mv	(bp+mark),y
	sub	(bp+mrklin),1
	sbc	(bp+mrklin+1),0
loop:	mv	a,[y++]
	cmp	a,$0d
	jrnz	loop
	dec	y
	mv	(bp+mark),y
	or	(bp+mode),m_pfmk+m_fnmk

	ret				;	コールバックを呼び出す

retad:	popu	f
	jrc	l3
	call	gapfwd4
	exp	(bp+cptr),(bp+mark)
	exw	(bp+mrklin),(bp+lineno)
l3:	call	setlt
	call	gapbac2
	cmpp	(bp+cptr),(bp+mark)
	jrnz	end
	and	(bp+mode),$ff-(m_pfmk+m_fnmk+m_rev)
end:	mv	a,r_calc+r_vx+r_xadj
	ret
	endl

qmmain:	local
	call	getquo
	jrnc	end
loop:	mv	a,[y++]
	cmp	a,$0d
	jrnz	loop
	mv	(bp+cptr),y
	mv	i,(bp+lineno)
	pushu	i
	inc	i
	mv	(bp+lineno),i
	call	savund3
	mv	[--u],(bp+u_flag)
	call	!quomain!start
	mv	(bp+u_flag),[u++]
	call	setund2
	mvw	(bp+lineno),[u++]
end:	mvp	(bp+cptr),[u++]
	ret
	endl

quomain:local
	call	getscp
	inc	i
	dec	i
	jrz	end			;	スクラップの文字数が0の場合
	mv	(bp+scrapp),y
	mv	x,i
	mv	(bp+pstsiz),x
	call	chkcr
	jrnc	end

	mv	y,(bp+cptr)
	mv	i,(bp+lineno)
start:	mv	ba,(bp+mrklin)
	sub	ba,i
	jrc	end
	mv	(bp+qline),ba

	call	gapback
;	mv	y,(bp+gaptop)
qloop:	mv	a,[(bp+gapend)]
	cmp	a,$0d
	jrz	l1			;	空行には引用符を挿入しない
	mv	x,(bp+gapend)
	sub	x,y
	cmpp	(bp+pstsiz),x		;	メモリ不足か？
	jrc	l2
	jrz	l2
	call	memerr
	call	gapfwd
	mv	ba,(bp+mrklin)
	mv	i,(bp+lineno)
	sub	ba,i
	mv	i,(bp+qline)
	sub	ba,i
	jrz	end
	dec	ba
	mv	(bp+qline),ba
	jr	!dqumain!l2		;	挿入した引用符を削除
l2:	SAVE_U
	mv	u,(bp+scrapp)
	mv	x,(bp+pstsiz)
	call	utoy
	LOAD_U
	mv	(bp+gaptop),y
l1:	call	gapfwd
;	mv	y,(bp+gaptop)
	sub	(bp+qline),1
	sbc	(bp+qline+1),0
	jrnc	qloop
	or	(bp+mode),m_mdf
	mv	(bp+u_flag),0		;	undo不可
end:	ret
	endl

dqumm:	local
	call	bfrcr
	mv	x,(bp+cptr)
	sub	x,y
	jrz	end
	mv	(bp+pstsiz),x
	mv	il,0
	cmpw	(bp+pstsiz+1),i
	jrnz	end			;	引用符は255文字まで
	mv	(bp+cptr),y
	SAVE_U
	mv	u,y
	mv	y,buf
	mv	(bp+scrapp),y
	call	utoy
	LOAD_U
	call	savund3
	mv	[--u],(bp+u_flag)
	call	!dqumain!start
	mv	(bp+u_flag),[u++]
	call	setund2
end:	ret
	endl

dqumain:local
	call	getscp
	inc	i
	dec	i
	jrz	end			;	スクラップの文字数が0の場合
	mv	(bp+scrapp),y
	mv	x,i
	mv	(bp+pstsiz),x
	call	chkcr
	jrnc	end
start:	mv	ba,(bp+mrklin)
	mv	i,(bp+lineno)
	sub	ba,i
	mv	(bp+qline),ba
l2:
	mv	y,(bp+cptr)
	call	gapback
loop1:
	mv	y,(bp+gapend)
	mv	x,(bp+scrapp)
	mv	i,(bp+pstsiz)
loop2:	mv	a,[y++]
	mv	(bp+fcmp),[x++]
	cmp	(bp+fcmp),a
	jrnz	l1
	dec	il
	jrnz	loop2
	mv	(bp+gapend),y
l1:	call	gapfwd
	sub	(bp+qline),1
	sbc	(bp+qline+1),0
	jrnc	loop1
	or	(bp+mode),m_mdf
	mv	(bp+u_flag),0		;	undo不可
end:	ret
	endl

wrpqum:	local
	call	getquo
	jrnc	noquo
	mv	x,(bp+cptr)
	mv	(bp+cptr),y
	call	calccur
	cmp	(bp+scrx),(bp+wrpwid)
	jrnc	noquo
	xor	[!wrpmain!ptch],$1b	;	jr -n → mv a,n
	call	wrpmain
	xor	[!wrpmain!ptch],$1b	;	mv a,n → jr -n
noquo:
	mvp	(bp+cptr),[u++]
	ret
	endl

wrpmain:local
	mv	[--u],(bp+dvwid)
	mv	(bp+dvwid),255
	call	savund3
	call	gapback
	mv	y,(bp+gapend)
loop2:	mv	(bp+scrx),0
loop1:	mv	a,(bp+wrpwid)
	call	calcwid
	mv	x,y
	mv	y,(bp+gapend)
	call	gapfwd3
	mv	y,(bp+gapend)
	cmpp	(bp+mark),y
	jrz	end
	mv	a,[y]
	cmp	a,$0d
	jrnz	l1
;	空行があるか調べる
	mv	x,y
	inc	x
	mv	a,[x]
	cmp	a,$0d
	jrnz	l3
loop3:	cmpp	(bp+mark),x
	jrz	end
	mv	a,[x++]
	cmp	a,$0d
	jrz	loop3
	dec	x
	call	gapfwd3
	mv	y,(bp+gapend)
	jr	ptch
;	既にある改行は削除する
l3:	inc	y
	mv	(bp+gapend),y
	sub	(bp+mrklin),1
	sbc	(bp+mrklin+1),0
	sub	(bp+maxlin),1
	sbc	(bp+maxlin+1),0
	jr	loop1
;	改行を挿入する
l1:	cmpp	(bp+gaptop),(bp+gapend)
	jrnc	l2
;	ワードラップ処理
	test	(bp+pref_d),$10
	jrz	l6
;	mv	a,[y]
	cmp	a,' '
	jrc	l6
	cmp	a,$80
	jrnc	l6
	mv	y,(bp+gaptop)
loop4:	mv	a,[--y]
	cmp	a,$0d
	jrz	l4
	cmp	a,' '+1
	jrc	loop4e
	cmp	a,'-'
	jrz	loop4e
	cmp	a,$80
	jrc	loop4
loop4e:	inc	y
	call	isjis2
	jrz	l5
	inc	y
l5:	call	gapback
l4:	mv	y,(bp+gapend)
l6:
	mv	x,(bp+gaptop)
	mv	a,$0d
	mv	[x++],a
	mv	(bp+gaptop),x
	add	(bp+mrklin),1
	adc	(bp+mrklin+1),0
	add	(bp+maxlin),1
	adc	(bp+maxlin+1),0
ptch:	jr	loop2
;	引用符処理
	mv	x,(bp+pstsiz)
	sub	y,x
	cmpp	(bp+gaptop),y		;	メモリ不足か？
	jrz	l7
	jrnc	l2
l7:	mv	(bp+gapend),y
	SAVE_U
	mv	u,(bp+scrapp)
	call	utoy
	LOAD_U
	mv	y,(bp+gapend)
	jr	loop2
end:
	call	gapfwd
	call	setund2
	mv	(bp+dvwid),[u++]
	or	(bp+mode),m_mdf
	ret
l2:	call	memerr
	jr	end
	endl

tabspm:	local
	mv	[--u],(bp+dvwid)
	mv	(bp+dvwid),255
	call	savund3
	call	gapback
	mv	x,(bp+gapend)
loop2:	mv	(bp+scrx),0
loop1:	cmpp	(bp+mark),x
	jrz	end
	mv	a,[x]
	cmp	a,$0d
	jrz	l1
	cmp	a,$09
	jrz	l2
	call	chrwid
	jrc	l1
	add	(bp+scrx),a
	add	x,il
	jr	loop1
l2:	mv	y,(bp+gapend)
	call	gapfwd3
	mv	y,(bp+gaptop)
	mv	x,(bp+gapend)
	mv	a,[x++]
	call	chrwid

	pushu	x
	sub	x,y
	sub	x,a
	popu	x
	jrc	l3
	add	(bp+scrx),a

	mv	il,' '
loop3:	mv	[y++],il
	dec	a
	jrnz	loop3

	mv	(bp+gaptop),y
	mv	(bp+gapend),x
	jr	loop1

l1:	call	gapfwd
	mv	x,(bp+gapend)
	jr	loop2

end:
	call	gapfwd
	call	setund2
	mv	(bp+dvwid),[u++]
	or	(bp+mode),m_mdf
	ret
l3:	call	memerr
	jr	end
	endl

clrblo:
	test	(bp+mode),m_pfmk+m_fnmk
	jrnz	revs!l2
	mv	a,0
	ret

revs:	local
	test	(bp+mode),m_pfmk
	jrnz	copy
	mv	a,r_adj
	test	(bp+mode),m_fnmk
	jrz	l3
	and	(bp+mode),$ff-m_fnmk
	mv	a,r_xadj
l3:	mvp	(bp+mark),(bp+cptr)
	mvw	(bp+mrklin),(bp+lineno)
	or	(bp+mode),m_pfmk
	ret
copy:	call	setblo
	test	(bp+mode),m_rev
	jrz	l1
	call	copy_m
	jrnz	l1
l2:	and	(bp+mode),$ff-(m_pfmk+m_fnmk+m_rev)
l1:	mv	a,r_all
	ret
	endl

cut:	local
	test	(bp+mode),m_pfmk
	jrnz	l3
	test	(bp+mode),m_fnmk
	jrnz	!revs!l2
	jr	l1
l3:	call	setblo
	call	copy_m
	jrnz	l1
	test	(bp+mode),m_rev
	jrnz	delblo
	and	(bp+mode),$ff-(m_pfmk+m_fnmk)
l1:	mv	a,r_all
	ret
	endl

copy_m:	local
;	コピールーチン
;	z=1：正常終了／z=0：メモリ不足
	call	blosiz
	mv	x,(bp+gapend)
	mv	y,(bp+gaptop)
	sub	x,y
	mv	y,(bp+clpsiz)
	add	x,y
	cmpp	(bp+blocks),x		;	x：コピーに使えるメモリ容量
	jrz	l3
	jrc	l3
	call	memerr
	or	a,$ff			;	z=0
	jr	l2
l3:	SAVE_U
	call	sftclp
	test	(bp+mode),m_rev
	jrz	l4
	mv	u,(bp+block1)
	mv	y,(bp+filend)
	mv	x,(bp+blocks)
	call	copygap
l4:	LOAD_U
l2:	ret
	endl

ctry:
	test	(bp+mode),m_pfmk
	jrnz	delblo

dell:	local
;	1行削除
	CLRFND
	call	bfrcr
	call	sbcury2
	mv	(bp+cptr),y
	mv	x,(bp+gaptop)
	cmpp	(bp+filend),(bp+gapend)
	pushu	f
	jrnz	l3
	dec	x
l3:	call	savund2
	popu	f
	jrz	l1
	mv	(bp+gaptop),y
	sub	(bp+maxlin),1
	sbc	(bp+maxlin+1),0
	call	gapfwd
	jr	l2
l1:	mv	a,$0d
	mv	[y++],a
	mv	(bp+gaptop),y
l2:	call	setundo
	or	(bp+mode),m_mdf
	mv	a,r_calc+r_vx+r_xadj
	ret
	endl

delblo:	local
	call	setblo
	call	blosiz
	call	savundo
	and	(bp+mode),$ff-(m_pfmk+m_fnmk+m_rev)
	call	linsub
	mv	a,r_all
	jrz	l1
	or	(bp+mode),m_mdf
	jrnc	l2

;	(mark) > (cptr)
	mv	x,(bp+mark)
	mv	y,(bp+cptr)
	cmpp	(bp+gaptop),x
	jrnc	l6
	mv	(bp+gapend),x
	mv	(bp+gaptop),y
	call	gapfwd
	jr	l7

;	(mark) < (cptr)
l2:	mv	x,(bp+cptr)
	mv	y,(bp+mark)
	mv	(bp+cptr),y
l6:	SAVE_U
	mv	u,(bp+gaptop)
	sub	u,x
	jrz	l5
	ex	x,u
	call	utoy
	mv	(bp+gaptop),y
l5:	LOAD_U
l7:	call	setundo
	mv	a,r_calc+r_vx+r_xadj
l1:	ret
	endl

delc:	local
;	行頭からカーソル位置まで削除する
	call	bfrcr
	cmpp	(bp+cptr),y
	mv	a,0
	jrz	l1
	mv	x,(bp+cptr)
	call	savund2

	call	sbcury2
	SAVE_U
	test	(bp+mode),m_pfmk+m_fnmk
	jrz	l2
	mv	x,(bp+mark)
	cmpp	(bp+ltptr),x
	jrnc	l2
	cmpp	(bp+cptr),x
	jrc	l3
	mv	(bp+mark),y
	jr	l2
l3:	cmpp	(bp+gaptop),x
	jrc	l2
	mv	u,(bp+cptr)
	sub	u,y
	sub	x,u
	mv	(bp+mark),x
l2:	mv	u,(bp+cptr)
	mv	(bp+cptr),y
	mv	x,(bp+gaptop)
	sub	x,u
	call	utoy
	mv	(bp+gaptop),y
	LOAD_U
	call	setundo
	or	(bp+mode),m_mdf
	mv	a,r_calc+r_vx+r_xadj
l1:	ret
	endl

ctre:	local
;	CTRL+Eの処理
	call	findcr
	mv	y,(bp+cptr)
	mv	a,[y]
	cmp	a,$0d
	jrz	!delete!l1
	mv	x,(bp+gaptop)
	dec	x
	call	savund2
	call	tstmk
	jrnc	l1
	mvp	(bp+mark),(bp+cptr)
l1:	mv	a,$0d
	mv	[y++],a
	call	setundo
	jr	!delete!l5
	endl

bs:
;	バックスペース
	cmpp	(bp+filtop),(bp+cptr)
	jrc	bs_ok
	mv	a,0
	ret
bs_ok:	call	c_left
;	call	delete
;	ret

delete:	local
;	カーソル位置の1文字を削除
	call	findcr
	mv	y,(bp+cptr)
	mv	a,[y]
	cmp	a,$0d
	jrz	l1
	mv	x,(bp+gaptop)
	call	isjis1
	jrc	l2

;	1バイト文字の削除
	mv	a,1
	call	sftmkp
	dec	x
	sub	x,y
loop:	mv	a,[y+1]
	mv	[y++],a
	dec	x
	jrnz	loop
	jr	l7

;	改行の削除
l1:	cmpp	(bp+filend),(bp+gapend)	;	ファイル・エンドか？
	mv	a,0
	jrz	l3
	sub	(bp+maxlin),1
	sbc	(bp+maxlin+1),0
	cmpp	(bp+cptr),(bp+mark)
	jrnc	l6
	sub	(bp+mrklin),1
	sbc	(bp+mrklin),0
l6:	mv	y,(bp+gaptop)
	dec	y
	mv	(bp+gaptop),y
	call	gapfwd
	mv	(bp+cry),(bp+dhei)	;	カーソル位置から全て書き直させる
	mv	(bp+u_flag),0		;	undo不可
	jr	l4

;	2バイト文字の削除
l2:	mv	a,2
	call	sftmkp
	mv	i,[--x]			;	sub x,2
	sub	x,y
	call	isjis1
loop2:	mv	a,[y+2]
	mv	[y++],a
	dec	x
	jrnz	loop2
l7:	mv	(bp+u_flag),0		;	undo不可
l5:	mv	(bp+gaptop),y
l4:	call	setblo
	call	addbfr
	call	putcur
	or	(bp+mode),m_mdf
	mv	a,r_vx+r_adj
l3:	ret
	endl

ctrlin:	local
;	コントロールコードの入力
	call	putcrsb
	call	keys2
	pushu	ba
	call	clrcur
	popu	ba
	cmp	a,0
	jrz	l1
	cmp	a,$20
	jrnc	l1
	cmp	a,$0d
	jrnz	keyin
l1:	ret
	endl

retkey:
;	改行の挿入（オートインデントあり）
	test	(bp+smode),s_ind
	db	$0a			;	次の命令をスキップ
ins_cr:	local
;	改行コードのみの挿入
	and	a,0			;	z=1
	pushu	f
	cmpp	(bp+gaptop),(bp+gapend)
	jrz	l1			;	メモリ不足
	mv	y,(bp+cptr)
	call	gapback
	cmpp	(bp+mark),(bp+gapend)	;	カーソル位置と(mark)が同じとき
	jrnz	l5
	mvp	(bp+mark),(bp+gaptop)	;	gapの後ろにずれてしまうので戻す
l5:	add	(bp+maxlin),1
	adc	(bp+maxlin+1),0
	add	(bp+lineno),1
	adc	(bp+lineno+1),0
	cmpp	(bp+cptr),(bp+mark)
	jrnc	l2
	add	(bp+mrklin),1
	adc	(bp+mrklin),0
l2:	mv	y,(bp+gaptop)
	mv	a,$0d
	mv	[y++],a
	popu	f
	pushu	y
	jrz	loop1e			;	オートインデントモードでない場合
	call	bfrcr
	mv	x,y
	mv	y,[u]
loop1:	cmpp	(bp+cptr),x
	jrz	loop1e
	cmpp	(bp+gapend),y
	jrz	loop1e
	mv	a,[x++]
	cmp	a,$09
	jrz	l3
	cmp	a,' '
	jrnz	loop1e
l3:	mv	[y++],a
	jr	loop1
loop1e:	mv	(bp+gaptop),y
	call	addbfr
	mvp	[--u],(bp+cptr)
	mvp	(bp+cptr),(bp+gaptop)
	call	gapfwd
	call	setblo
	popu	y
	mvw	(bp+scrx),(bp+curx)
	call	putlin2
	popu	y
	call	down
	jrnc	l4
	mv	(bp+scry),(bp+cury)
loop2:	cmpp	(bp+filend),y
	jrz	l4
	call	putline
	inc	(bp+scry)
	cmp	(bp+scry),(bp+dhei)
	jrc	loop2
l4:	or	(bp+mode),m_mdf
	mv	(bp+u_flag),0		;	undo不可
	call	xrecalc
	jrc	l6
	cmp	(bp+curx),(bp+dvwid)
	jrnc	l6
	mv	a,r_vx+r_adj
	ret
l6:	call	addcury
	mv	a,r_calc+r_vx+r_xadj
	ret
l1:	popu	f
	mv	a,0
	ret
	endl

tab:
;	TABの入力
	mv	a,$09

keyin:	local
;	1文字入力
	pushu	a
	call	findcr
	popu	a
	test	(bp+ins),2
	jrnz	insert

	mv	y,(bp+cptr)
	mv	b,a
	mv	a,[y]
	cmp	a,$0d
	ex	a,b
	jrz	insert
	call	isjis1
	jrc	o1
;	1バイト文字の上書き
	ex	a,b
	call	isjis1			;	カーソル位置の文字を調べる
	mv	a,b
	mv	[y++],a
	jrnc	o3
	mv	a,' '
	mv	[y],a
o3:	call	setblo
	call	addbfr
	jr	l3
;	2バイト文字の上書き
o1:	mv	(bp+dblwk),a
	call	iskey
	jrc	l4
	call	keyr
	mv	y,(bp+cptr)
	mv	b,a
	mv	a,[y++]			;	カーソル位置の文字
	call	isjis1
	jrc	o2
	mv	a,[y]			;	カーソル位置の次の文字
	cmp	a,$0d
	jrnz	o4
	cmpp	(bp+gaptop),(bp+gapend)
	jrnc	l4			;	メモリ不足
	pushu	y
	inc	y
	mv	[y++],a
	mv	(bp+gaptop),y
	popu	y
	jr	o2
o4:	call	isjis1
	jrnc	o2
	mv	a,' '
	mv	[y+1],a
o2:	dec	y
	mv	a,b
	jr	l11

insert:
;	1文字挿入
	call	isjis1
	jrc	l6

;	1バイト文字の挿入
	mv	x,(bp+gaptop)
	cmpp	(bp+gapend),x
	jrz	l4			;	メモリ不足
	mv	y,(bp+cptr)
	sub	x,y
	pushu	a
	mv	a,1
	call	sftmkf
	mv	y,(bp+gaptop)
	inc	y
	mv	(bp+gaptop),y
	dec	y
loop:	mv	a,[--y]
	mv	[y+1],a
	dec	x
	jrnz	loop
	popu	a
	mv	[y],a
l10:	call	setblo
	call	addbfr
	jrnc	l2
	jr	l3

;	2バイト文字の挿入
l6:	mv	(bp+dblwk),a
	call	iskey
	jrc	l4
	call	keyr
	mv	x,(bp+gaptop)
	mv	i,[x++]			;	add x,2
	cmpp	(bp+gapend),x
	jrnc	l1
l4:	mv	a,0
	ret
l1:	pushu	a
	mv	a,2
	call	sftmkf
	mv	(bp+gaptop),x
	mv	y,(bp+cptr)
	mv	i,[--x]			;	sub x,2
	pushu	x
	sub	x,y
	popu	y
loop2:	mv	a,[--y]
	mv	[y+2],a
	dec	x
	jrnz	loop2
	popu	a
l11:	mv	[y++],(bp+dblwk)
	cmpp	(bp+mark),y
	mv	[y++],a
	jrnz	l12
	mv	(bp+mark),y
l12:	call	setblo

l3:	call	putcur
l2:
	or	(bp+mode),m_mdf
	mv	(bp+u_flag),0		;	undo不可
	and	[rev],$bf
	call	c_right
	call	iskey
	mv	a,r_vx+r_adj
	jrc	l5
	mv	a,r_vx			;	キーバッファに文字があるとき
l5:	ret
	endl

scdown:	call	c_down
	and	a,$ff-r_adj
	ret

scup:	call	c_up
	and	a,$ff-r_adj
	ret

scleft:
	cmp	(bp+scwid),0
	jrz	scright!end
	CLRFND
	dec	(bp+scwid)
	jr	pgright!l3

scright:local
	cmp	(bp+dwid),(bp+dvwid)
	jrnc	end			;	実際の画面幅より1行の幅が狭いとき
	cmp	(bp+scwid),(bp+scmax)
	jrc	l1
end:	mv	a,0
	ret
l1:	CLRFND
	inc	(bp+scwid)
	jr	!pgright!l3
	endl

pgleft:	local
	cmp	(bp+dwid),(bp+dvwid)
	jrnc	clntop			;	実際の画面幅より1行の幅が狭いとき
	CLRFND
	cmp	(bp+scwid),0
	jrnz	l1
	mv	y,(bp+ltptr)
	mv	a,[y-1]
	cmp	a,$0d
	jrnz	l2
	cmpp	(bp+filtop),y
	mv	a,0
	jrnc	!pgright!l1
	sub	(bp+lineno),1
	sbc	(bp+lineno+1),0
	call	gapback
	mv	y,(bp+ltptr)
l2:	mv	x,y
	dec	x
	mv	(bp+cptr),x
	call	bfrlin
	call	up
	mv	(bp+scwid),(bp+scmax)
	jr	!pgright!l3
l1:	mv	a,(bp+dwid)
	dec	a			;	スクロール幅は画面幅-1
	sub	(bp+scwid),a
	jrnc	!pgright!l3
	mv	(bp+scwid),0
	jr	!pgright!l3
	endl

pgright:local
	cmp	(bp+dwid),(bp+dvwid)
	jrnc	clnend			;	実際の画面幅より1行の幅が狭いとき
	CLRFND
	cmp	(bp+scwid),(bp+scmax)
	jrnc	l5
	mv	a,(bp+dwid)
	dec	a			;	スクロール幅は画面幅-1
	add	(bp+scwid),a
	jrc	l2
	cmp	(bp+scmax),(bp+scwid)
	jrnc	l3
l2:	mv	(bp+scwid),(bp+scmax)
l3:	mv	y,(bp+ltptr)
	mv	(bp+scrx),(bp+margin)
l4:	mv	a,(bp+scwid)
	add	a,sclmgn
	mv	(bp+vx),a
	call	calcwd2
	mv	(bp+cptr),y
	mv	(bp+curx),(bp+scrx)
	mv	a,r_all
l1:	ret
;	次の行へ移動する
l5:	mv	y,(bp+cptr)
	mv	(bp+scrx),(bp+curx)
	call	nxtlin
	jrnc	l6
	call	gonext
	jrnc	l1
l6:	mv	(bp+cptr),y
	call	down
	mv	a,r_calc+r_vx+r_xadj
	ret
	endl

clntop:	local
;	crで切られた行頭へ
	CLRFND
	call	bfrcr
	cmpp	(bp+cptr),y
	jrz	c_left
	call	sbcury2
	mv	(bp+cptr),y
	mv	a,r_calc+r_vx+r_xadj
	ret
	endl

lintop:	local
;	画面上の行頭へ
	cmp	(bp+curx),(bp+margin)
	jrz	c_left			;	すでに左端に到達しているときは前の行に
	mvp	(bp+cptr),(bp+ltptr)
	test	(bp+mode),m_fnmk
	jrz	l2
	CLRFND2
	mv	a,r_calc+r_vx+r_xadj
	ret
l2:	test	(bp+mode),m_pfmk
	jrz	l1
	call	setblo
	mv	(bp+scry),(bp+cury)
	mv	y,(bp+cptr)
	call	putline
l1:	mv	a,r_calc+r_vx+r_adj
	ret
	endl

c_left:	local
	test	(bp+mode),m_fnmk
	jrz	l0
	CLRFND2
	call	putall
l0:	mv	y,(bp+ltptr)
	mv	x,(bp+cptr)
	mv	a,[--x]
	cmp	a,$0d
	jrnz	l3
	cmpp	(bp+filtop),y
	jrnc	l1
	sub	(bp+lineno),1
	sbc	(bp+lineno+1),0
	mv	(bp+cptr),x
	call	gapback
	mv	y,(bp+ltptr)
	call	bfrlin
	mv	(bp+curx),a
	mv	(bp+scrx),a
	call	up
	mv	y,(bp+cptr)
	jr	l4
l3:	cmp	(bp+curx),(bp+margin)
	jrnz	l2
	call	bfrlin
	mv	(bp+curx),a
	call	up
l2:	mv	a,(bp+curx)
	mv	(bp+scrx),(bp+margin)
	dec	a
	call	calcwid
	mv	(bp+curx),(bp+scrx)
	mv	(bp+cptr),y
l4:	test	(bp+mode),m_pfmk+m_fnmk
	jrz	l1
	call	setblo
	mv	(bp+scry),(bp+cury)
	call	putlin2
l1:	mv	a,r_vx+r_adj
	ret
	endl

clnend:	local
;	crで切られた行末へ
	CLRFND
	mv	y,(bp+cptr)
	mv	a,[y++]
	cmp	a,$0d
	jrz	c_right
loop:	mv	a,[y++]
	cmp	a,$0d
	jrnz	loop
	dec	y
	pushu	y
	call	addcury
	popu	y
	mv	(bp+cptr),y
	mv	a,r_calc+r_vx+r_xadj
	ret
	endl

linend:	local
;	画面上の行末へ
	mv	y,(bp+cptr)
	mvw	(bp+scrx),(bp+curx)
	call	nxtlin
	jrc	l1
	mv	a,(bp+scrx)
	dec	a
	mv	y,(bp+cptr)
	mv	(bp+scrx),(bp+curx)
	call	calcwid
l1:	cmp	(bp+scrx),(bp+curx)
	jrz	c_right			;	すでに右端に到達しているときは次の行へ
	test	(bp+mode),m_pfmk
	jrz	l2
	mv	x,(bp+cptr)
	mv	(bp+cptr),y
	ex	(bp+scrx),(bp+curx)
	call	setblo
	mv	y,x
	call	putlin2
	jr	l3
l2:	mv	(bp+cptr),y
	mv	(bp+curx),(bp+scrx)
	test	(bp+mode),m_fnmk
	jrz	l3
	CLRFND2
	mv	a,r_vx+r_xadj
	ret
l3:	mv	a,r_vx+r_adj
	ret
	endl

c_right:local
	test	(bp+mode),m_fnmk
	jrz	l0
	CLRFND2
	call	putall
l0:	mvw	(bp+scrx),(bp+curx)
	mv	y,(bp+cptr)
	mv	a,[y]
	cmp	a,$0d
	jrnz	l2
	call	gonext
	jrnc	l1
	test	(bp+mode),m_pfmk+m_fnmk
	jrz	l6
	mv	x,y
	mv	y,(bp+cptr)
	mv	(bp+cptr),x
	call	setblo2
	call	putlin2
	jr	l3
l6:	mv	(bp+cptr),y
	jr	l3
l2:	call	chrwid
	test	(bp+mode),m_pfmk+m_fnmk
	jrz	l4
	pushu	a
	mv	x,y
	add	x,il
	mv	(bp+cptr),x
	call	setblo2
	call	putlin2
	popu	a
	mv	y,(bp+cptr)
	jr	l5
l4:	add	y,il
	mv	(bp+cptr),y
l5:	add	(bp+curx),a
	jrc	l3
	mv	a,[y]
	call	isjis1
	mv	a,(bp+dvwid)
	sbc	a,0
	cmp	(bp+curx),a
	jrc	l1
l3:	mv	(bp+curx),(bp+margin)	;	次の行へ
	call	down
l1:	mv	a,r_vx+r_adj
	ret
	endl

c_down:	local
	test	(bp+mode),m_fnmk
	jrz	l0
	CLRFND2
	call	putall
l0:	mv	y,(bp+cptr)
	mv	(bp+scrx),(bp+curx)
	call	nxtlin
	jrnc	l4
	call	gonext
	jrnc	l2
l4:	test	(bp+mode),m_pfmk+m_fnmk
	jrz	l1
	mvp	[--u],(bp+cptr)
	mvw	[--u],(bp+curx)
	call	setcurx
	call	setblo
	mvw	(bp+scrx),[u++]
	popu	y
	call	putlin2
	call	down
	jrnc	l2
	mv	(bp+scry),(bp+cury)
	call	putline
	jr	l2
l1:	pushu	y
	call	setcurx
	popu	y
	call	down
l2:	mv	a,r_adj
	ret
	endl

c_up:	local
	test	(bp+mode),m_fnmk
	jrz	l0
	CLRFND2
	call	putall
l0:	mv	y,(bp+ltptr)
	cmpp	(bp+filtop),y
	jrnc	l1
	test	(bp+mode),m_pfmk+m_fnmk
	jrz	l2
	pushu	y
	mv	x,y
	call	setblo2
	mv	(bp+scry),(bp+cury)
	call	putline
	popu	y
l2:	mv	a,[y-1]
	cmp	a,$0d
	jrnz	l3
	sub	(bp+lineno),1
	sbc	(bp+lineno+1),0
	call	gapback
	mv	y,(bp+ltptr)
l3:	call	bfrlin
	call	up
	call	setcurx
	test	(bp+mode),m_pfmk+m_fnmk
	jrz	l1
	call	setblo
	mv	(bp+scry),(bp+cury)
	call	putlin2
l1:	mv	a,r_adj
	ret
	endl

pgdown:	local
	mv	y,(bp+ltptr)
	mv	(bp+scry),(bp+dhei)	;	scryはカウンタとして使う
loop:	mv	(bp+scrx),(bp+margin)
	call	nxtlin
	jrnc	l1
	call	gonext
	jrnc	l2
l1:	mv	(bp+ltptr),y
	dec	(bp+scry)
	jrnz	loop
l2:	jr	!pgup!l2
	endl

pgup:	local
	mv	y,(bp+ltptr)
	mv	(bp+scry),(bp+dhei)
loop:	cmpp	(bp+filtop),y
	jrnc	l1
	mv	a,[y-1]
	cmp	a,$0d
	jrnz	l3
	sub	(bp+lineno),1
	sbc	(bp+lineno+1),0
l3:	call	bfrlin
	mv	(bp+ltptr),y
	dec	(bp+scry)
	jrnz	loop
l1:	mv	y,(bp+ltptr)
	call	gapbac2
l2:	mv	y,(bp+ltptr)
	call	setcurx
	CLRFND
	mv	a,r_all
	ret
	endl

alltop:
	CLRFND
	mvw	(bp+lineno),1
	mv	y,(bp+filtop)
	mv	(bp+cptr),y
	mv	(bp+ltptr),y
	call	gapbac2
	mvw	(bp+curx),(bp+margin)
	mv	a,r_vx+r_xadj
	ret

allend:	local
	CLRFND
	mvw	(bp+lineno),(bp+maxlin)
	mv	x,(bp+filend)
	mv	y,(bp+gapend)
	call	gapfwd3
	mv	y,(bp+gaptop)
	dec	y
	mv	(bp+cptr),y
	call	srchlt
	mv	(bp+ltptr),y
	mv	(bp+curx),a
	mv	a,(bp+dhei)
	dec	a
	mv	(bp+cury),a
	mv	a,r_vx+r_xadj
	ret
	endl

goline:
;	指定した行番号へジャンプする
	mv	il,line_m-ms
	call	inputn
	jrc	golini!l1
	CLRFND

golini:	local
	cmpw	(bp+maxlin),i
	jrnc	l2
	mv	i,(bp+maxlin)
	jr	l3
l2:	inc	i
	dec	i
	jrnz	l3
	inc	i
l3:	cmpw	(bp+lineno),i
	jrnz	l7
l1:	mv	a,r_all
	ret

l7:	jrc	l4
;	現在の行より前に移動する
	mv	y,(bp+cptr)
	jr	l6
loop1:	dec	y
	sub	(bp+lineno),1
	sbc	(bp+lineno+1),0
l6:	call	bfrcr2
	cmpw	(bp+lineno),i
	jrnz	loop1
	call	sbcury2
	mv	(bp+cptr),y
	call	gapbac2
	jr	l5
l4:
;	現在の行よりあとに移動する
	mv	(bp+fline),i
loop2:	mvp	(bp+cptr),(bp+gaptop)
	call	gapfwd
	add	(bp+lineno),1
	adc	(bp+lineno+1),0
	cmpw	(bp+lineno),(bp+fline)
	jrnz	loop2
	mv	y,(bp+cptr)
	call	addcury

l5:	mv	a,r_calc+r_vx+r_xadj
	ret
	endl

swapmk:	local
;	カーソル⇔ブロック指定開始位置
	test	(bp+mode),m_pfmk+m_fnmk
	mv	a,0
	jrz	l1
	cmpp	(bp+cptr),(bp+mark)
	jrz	l1
	jrnc	l2

;	(mark) > (cptr)
	call	gapfwd4
	mv	y,(bp+mark)
	call	addcury
	exp	(bp+cptr),(bp+mark)
	jr	l4

;	(mark) < (cptr)
l2:	exp	(bp+cptr),(bp+mark)
	mv	y,(bp+cptr)
	call	subcury
	call	gapbac2

l4:	exw	(bp+lineno),(bp+mrklin)
	mv	a,r_calc+r_vx+r_xadj
	test	(bp+mode),m_pfmk
	jrz	l1
	and	(bp+mode),$ff-m_fnmk
l1:	ret
	endl

case:	local
	mv	y,(bp+cptr)
;	スペースを読み飛ばす
loop1:	mv	a,[--y]
	cmp	a,' '
	jrz	loop1
	cmp	a,$09
	jrz	loop1
	pushu	y
;	単語の先頭を探す（単語：英数字と"_"、"'"、"-"、"/"、"."で構成される文字列）
loop2:	call	isalph
	jrnc	l3
	call	isnum
	jrnc	l3
	cmp	a,'_'
	jrz	l3
	cmp	a,$27			;	シングルクォート(''''でもOKだが)
	jrz	l3
	cmp	a,'-'
	jrz	l3
	cmp	a,'/'
	jrz	l3
	cmp	a,'.'
	jrnz	loop2e
l3:	mv	a,[--y]
	jr	loop2
loop2e:	inc	y
	call	isjis2
	jrz	l1
	inc	y
l1:	popu	x
	inc	x
	sub	x,y
	jrz	loop3e
	jrc	loop3e
	or	(bp+mode),m_mdf
	mv	(bp+u_flag),0		;	undo不可
;	大文字と小文字を入れ替える
loop3:	mv	a,[y]
	call	isalph
	jrc	l2
	xor	a,$20			;	大文字⇔小文字
l2:	mv	[y++],a
	dec	x
	jrnz	loop3
loop3e:
	mv	a,r_xadj
	ret
	endl

chgind:	xor	(bp+smode),s_ind
	jr	putsym
;	ret

chgpf:	xor	(bp+smode),s_pf
;	call	putsym
;	ret

putsym:	local
;	シンボル点／消灯
	mv	a,(bp+smode)
	dec	($ec)
	and	a,3
	mv	(bp+0),[sym]
	and	(bp+0),$fc
	or	a,(bp+0)
	inc	($ec)
	mv	(bp+bx-base),3
	mv	il,$46
	call	lcdd
	mv	a,0
	ret
	endl

displn:	local
;	現在の行番号/最終行番号/X座標/メモリ容量/属性を左上に表示する
	or	[rev],$40
	mvw	(bp+bx-base),0

;	現在の行番号
	mv	i,(bp+lineno)
	call	puti

;	最終行番号
	mv	a,'/'
	call	putc
	mv	i,(bp+maxlin)
	call	puti

;	X座標
	mv	il,h_m-ms
	call	putm
	mv	il,(bp+curx)
	call	puti
	call	bfrcr
	mv	x,(bp+cptr)
	mv	[--u],(bp+dvwid)
	mv	(bp+dvwid),255
	call	calccur
	mv	(bp+dvwid),[u++]
	jrc	l2
	cmp	(bp+scrx),(bp+curx)
	jrz	l2
	mv	a,'/'
	call	putc
	mv	il,(bp+scrx)
	call	puti

;	残りメモリ容量
l2:	mv	x,(bp+gapend)
	mv	y,(bp+gaptop)
	sub	x,y
	mv	(bp+di-base),x
	call	putdi
	mv	a,'B'
	call	putc

;	属性
	call	putspc
	mv	a,'*'
	test	(bp+mode),m_mdf
	call	putst
	mv	a,'C'
	test	(bp+mode),m_cre
	call	putst
	mv	a,'U'
	cmp	(bp+u_flag),0
	call	putst
	and	[rev],$bf

loop2:	mv	il,$41
	call	keyd
	test	a,$80
	jrz	loop2			;	キーが押された場合ループ
	call	kclr
	mv	a,r_xadj
	ret
	endl

save:
	mv	x,fname
	mv	a,[x]
	cmp	a,0
	jrnz	save2
	call	rename			;	ファイル名を設定していないとき
	mv	a,r_all
	ret

save2:	local
	pushu	x
	mvp	(bp+block1),(bp+filtop)
	mv	y,(bp+filend)
	cmpp	(bp+gapend),y
	jrnz	l2
	mv	y,(bp+gaptop)
l2:	dec	y			;	最後の$0dはSaveしない
	mv	(bp+block2),y
	call	save_b
	jrc	l1
	and	(bp+mode),$ff-m_mdf
	mv	il,c_lfil+$22
	call	getcfg
	mv	x,[u]
	mv	il,18
	call	xtoy
	mvw	[y],(bp+lineno)
l1:	popu	x
	mv	a,r_all
	ret
	endl

kalku:	local
;	Kalku（(c)Ｍasa氏）に選択文字列を渡して起動
	call	setblo
	mv	a,0
	test	(bp+mode),m_rev
	jrz	l2
	mv	y,(bp+block1)
	mv	x,(bp+block2)
	sub	x,y
	pushu	x
	call	chkcr
	popu	x
	mv	ba,$100
	jrnc	l1
	sub	x,ba
	jrnc	l1
	mv	a,x
	cmpp	(bp+cptr),(bp+mark)
	jrnc	l4
	pushu	a
	mv	y,(bp+mark)
	call	addcury
	popu	a
l4:	mvp	(bp+cptr),(bp+block2)
l2:	mv	x,(bp+block1)
	mv	il,$60
	call	keyd
	call	iskey
	jrnc	l5
	and	(bp+mode),$ff-(m_pfmk+m_fnmk+m_rev)
l5:	mv	a,r_calc+r_vx+r_xadj
l1:	ret
	endl

settab:
	mv	il,tab_m-ms
	xor	[inpwid!ptch+1],3
	call	inpwid
	xor	[inpwid!ptch+1],3
	jrc	setwid!l1
	mv	(bp+tabwid),a

	cmp	[fname],0
	jrnz	ltend
	pushu	a
	mv	il,c_twid+$22
	call	getcfg
	popu	a
	mv	[y],a
	jr	ltend

setwid:	local
	mv	il,wid_m-ms
	call	inpwid
	jrc	l1
	mv	(bp+dvwid),a
	mv	(bp+subwid),(bp+dwid)

	cmp	[fname],0
	jrnz	chgwid2
	pushu	a
	mv	il,c_swid+$22
	call	getcfg
	popu	a
	mv	[y],a
	jr	chgwid2
l1:	mv	a,r_all
	ret
	endl

chgcol:	local
	cmp	(bp+dwid),(bp+dvwid)
	jrnz	l1
	ex	(bp+dvwid),(bp+subwid)
l1:	mv	x,ini60
	mv	a,'6'
	cmp	(bp+dwid),60
	jrnz	l2
	mv	a,'4'
l2:	mv	[x+1],a
	mv	il,$3f
	call	lcdd

	mv	(bp+dwid),[$bfc9d]
	mv	(bp+subwid),(bp+dwid)
	endl

chgwid:
	ex	(bp+dvwid),(bp+subwid)
chgwid2:
	mv	a,(bp+dvwid)
	sub	a,(bp+dwid)
	mv	(bp+scmax),a
	mv	(bp+scwid),0
ltend:	call	setlt
	mv	a,r_calc+r_vx+r_xadj
	ret

setwwid:local
	mv	il,wrp_m-ms
	call	inpwid
	jrc	l1

	mv	(bp+wrpwid),a
	mv	i,c_wwid+$22
	call	getcfg
	mv	[y],(bp+wrpwid)

l1:	mv	a,r_all
	ret
	endl

inpwid:	local
	call	inputn
	jrc	l1
	call	i2a
	jrc	l2
ptch:	cmp	a,2
	jrnc	l1
l2:	mv	il,num_e-ms
	call	alert
	sc
l1:	ret
	endl

chgins:	xor	(bp+ins),2
	mv	a,0
	ret

chgorg:
	xor	(bp+mode),m_cre+m_tab
	mv	a,r_all
	ret

addbfr:	local
;	現在位置の文字を前の行に追加する必要があるかか調べ、
;	必要なときは前の行に追加する
;	c=0：追加した
	mv	y,(bp+cptr)
	cmp	(bp+curx),(bp+margin)
	jrnz	l3
	cmpp	(bp+filtop),y
	jrz	l3
	mv	a,[y]
	cmp	a,$0d
	jrnz	l1
	call	srchlt
	cmpp	(bp+cptr),y
	jrz	l3
	jr	l2
l1:	call	bfrlin
	pushu	y
	mv	(bp+scrx),(bp+margin)
	call	nxtlin
	popu	x
	jrc	l3
	cmpp	(bp+cptr),y
	jrnc	l3
	mv	y,x
	dec	(bp+scrx)
l2:	mv	(bp+curx),(bp+scrx)
	call	up
	jrc	l4
	mv	(bp+scry),(bp+cury)
	mv	y,(bp+cptr)
	call	putlin2
l4:	rc
	ret
l3:	sc
	ret
	endl

dispadj:
;	カーソルが画面に収まらない場合画面を書き換える
	call	xadj
	jrnz	putall
	ret

xrecalc:
;	現在位置からx座標を再計算する
	mv	y,(bp+ltptr)
	mv	x,(bp+cptr)
	call	calccur
	mv	(bp+curx),(bp+scrx)
	ret

xadj:	local
;	現在のカーソル位置が画面内に収まるように(scwid)を調節する
;	z=0(nz):調節した
	mv	il,1
	cmp	(bp+dwid),(bp+dvwid)	;	実際の画面幅より1行の幅が狭いとき
	jrnc	l1
	mv	a,(bp+margin)
	add	a,sclmgn+1
	cmp	(bp+curx),a
	jrnc	l5
	cmp	(bp+scwid),0
	mv	(bp+scwid),0
	jr	l4
l5:	mv	a,(bp+dvwid)
	sub	a,scrmgn
	cmp	(bp+curx),a
	jrc	l3
	cmp	(bp+scwid),(bp+scmax)
	mv	(bp+scwid),(bp+scmax)
	jr	l4
l3:	mv	a,(bp+scwid)
	add	a,(bp+margin)
	add	a,sclmgn
	sub	a,(bp+curx)
	jrc	l2
	jrz	l4
	sub	(bp+scwid),a
	mv	il,0
	jr	l1
l2:	mv	a,(bp+scwid)
	add	a,(bp+dwid)
	sub	a,scrmgn		;	a=(dwid)+(scwid)-scrmgn
	mv	(bp+scrx),(bp+curx)
	sub	(bp+scrx),a
	jrc	l1
	jrz	l4
	mv	a,(bp+scrx)
	add	(bp+scwid),a
	mv	il,0
l1:	dec	il
l4:	ret
	endl

putall:	local
;	現在のカーソル位置を(curx)(cury)に示した位置にして表示する
;	指定位置に表示できない場合はY座標を調整する
	mv	y,(bp+ltptr)
	mv	(bp+scry),(bp+cury)
loop:	cmpp	(bp+filtop),y
	jrc	l1
	mv	a,(bp+scry)
	sub	(bp+cury),a
	jr	loope
l1:	sub	(bp+scry),1
	jrc	loope
	call	bfrlin
	jr	loop
loope:	mv	(bp+scry),0
	call	setblo

loop2:	call	putline
	cmpp	(bp+filend),y
	jrz	loop2e
pn:	inc	(bp+scry)
	cmp	(bp+scry),(bp+dhei)
	jrnz	loop2
loop2e:	and	[rev],$bf
	ret
	endl

putcur:	local
;	カーソル位置から必要なだけ表示する
;	カーソル位置に表示できないときは次の行に移動させる
	mv	y,(bp+cptr)
	mvw	(bp+scrx),(bp+curx)
	mv	a,[y]
	call	chrwid
	add	a,(bp+scrx)
	jrc	l2
	cmp	(bp+dvwid),a
	jrnc	l5
l2:	call	putlin2
	mv	(bp+curx),(bp+margin)
	mv	y,(bp+cptr)
	call	down
	jrnc	l1
	mvw	(bp+scrx),(bp+curx)
l5:	call	putlin2
	mv	x,y
	call	findcr
	mv	y,x
	jrz	l7
	mv	a,(bp+dhei)
	dec	a
	mv	(bp+cry),a
l7:
	mv	(bp+scry),(bp+cury)
loop:	cmpp	(bp+filend),y
	jrz	l1
	inc	(bp+scry)
	cmp	(bp+cry),(bp+scry)
	jrc	l1
	call	putline
	jr	loop
l1:	ret
	endl

gonext:	local
;	次の物理行へ移動する処理
;	c=1：移動できた／c=0：最終行
	cmpp	(bp+filend),(bp+gapend)
	jrz	l1
	add	(bp+lineno),1
	adc	(bp+lineno+1),0
	inc	y
	pushu	y
	call	gapfwd
	popu	y
	sc
l1:	ret
	endl

down:	local
;	ひとつ下の行に移動する
;	y->行先頭アドレス
	inc	(bp+cury)
	mv	(bp+ltptr),y
	cmp	(bp+cury),(bp+dhei)
	jrc	l1
l2:	pushu	y
	mv	a,1
	mvw	(bx),0
	mv	il,$47
	call	lcdd
	popu	y
	dec	(bp+cury)
	mv	(bp+scry),(bp+cury)
	call	putline
	rc
l1:	ret
	endl

up:	local
;	ひとつ上の行に移動する
;	y->上の行の先頭
	mv	(bp+ltptr),y
	sub	(bp+cury),1
	jrnc	l2
	mv	a,1
	mvw	(bx),0
	mv	il,$48
	call	lcdd
	inc	(bp+cury)
	call	putlt
	mv	y,(bp+ltptr)
	sc
l2:	ret
	endl

putlin2:
	mv	ba,(bp+scrx)
	sub	a,(bp+scwid)		;	x座標-scwid
	mv	(bp+bx-base),ba
	jrnc	putline!l5
	mv	(bp+bx-base),(bp+margin);	(bx)が左にはみ出す
	mv	a,(bp+scwid)
	jr	putline!l9

putlt:	mv	(bp+scry),(bp+cury)
	mv	y,(bp+ltptr)

putline:local
;	yレジスタで指定した位置（行頭）から行末まで表示する
;	y->開始位置
;	y<-次の行の先頭位置
	mv	(bp+scrx),(bp+margin)
	mvw	(bp+bx-base),(bp+scrx)
	mv	a,(bp+scwid)
	cmp	a,0
	jrz	l5
	add	a,(bp+margin)
l9:	call	calcwd2
	pushu	f
	call	tstrev
	popu	f
	jrc	crend2
	mv	a,(bp+scrx)
	sub	a,(bp+margin)
	sub	a,(bp+scwid)		;	(scrx)が(scwid)+(margin)を越えた幅
	jrz	l5
	pushu	y
	call	clrn2
	popu	y
l5:	call	tstrev
	mv	x,y
	mv	a,(bp+dwid)
	add	a,(bp+scwid)
	cmp	(bp+dvwid),a
	jrnc	l6
	mv	a,(bp+dvwid)
l6:	mv	(bp+dswid),a
	cmp	(bp+scrx),(bp+dswid)
	jrnc	l8
loop:
	test	(bp+mode),m_rev
	jrz	l1
	cmpp	(bp+block2),y
	jrnz	l2
	call	putlsb2
	jrc	l8
	and	[rev],$bf		;	ブロック領域から外に出た
	jr	l1
l2:	cmpp	(bp+block1),y
	jrnz	l1
	call	putlsb2
	jrc	l8
	or	[rev],$40		;	ブロック領域に入った
l1:	mv	a,[y]
	cmp	a,$0d
	jrz	crend
	cmp	a,$09
	jrnz	l4
	call	putlsub
	mv	y,x
	mv	a,$09
	call	chrwid
	add	y,il
	add	(bp+scrx),a
	pushu	y
	pushu	a
	mv	a,$00
	call	puttab
	popu	a
	dec	a
	call	clrn2
	popu	y
	cmp	(bp+scrx),(bp+dswid)
	jrnc	l8
	mv	x,y
	jr	loop
l4:	call	chrwid
	add	(bp+scrx),a
	jrc	l10
	add	y,il
	cmp	(bp+dswid),(bp+scrx)
	jrz	l3
	jrnc	loop
	sub	y,il
l10:	sub	(bp+scrx),a
l3:	pushu	f
	call	putlsub
	popu	f
	pushu	x
	jrz	l11
	mv	a,$03
	call	putof
l11:	popu	y
l8:	mv	a,(bp+dvwid)
	cmp	(bp+scrx),a
	jrnc	l7
	call	calcwid
	jrc	crend2
l7:	;call	delsub
	;ret

delsub:
	mv	a,(bp+dwid)
	sub	a,(bp+bx-base)
	jrz	clrn2!l6
;	call	clrn2
;	ret

clrn2:	local
	dec	($ec)
	mv	(bp+0),a
	mv	a,(base+dwid)
	sub	a,(bx)
	cmp	(bp+0),a
	jrnc	l1
	mv	a,(bp+0)
l1:	inc	($ec)		;	aは(dwid)-(bx)と(bp+0)の小さいほう
	test	[rev],$40
	jpz	clrn
	jr	loop3l
loop3:	pushu	a
	call	putspc
	popu	a
loop3l:	sub	a,1
	jrnc	loop3
l6:	ret
	endl

crend:
	call	putlsub
	call	crsub
	pushu	x
	call	putcr
	call	delsub
	popu	y
	sc
	ret
crend2:
	test	(bp+mode),m_rev
	jrz	l13
	cmpp	(bp+block2),y
	jrnz	l12
	and	[rev],$bf
	jr	l13
l12:	cmpp	(bp+block1),y
	jrnz	l13
	or	[rev],$40
l13:	mv	x,y
	call	crsub
	pushu	x
	call	delsub
	popu	y
	sc
	ret

putlsb2:local
	call	putlsub
	mv	a,[x]
	cmp	a,$09
	jrz	l2
	call	chrwid
	add	a,(bp+scrx)
	jrc	l1
	cmp	(bp+dswid),a
	jrnc	l2
l1:	pushu	x
	mv	a,$03
	call	putof
	popu	x
	sc
l2:	mv	y,x
	ret
	endl

putlsub:
	pushu	y
	sub	y,x
	call	putn
	popu	x
	ret

crsub:	local
	inc	x
	cmpp	(bp+gaptop),x
	jrnz	l1
	mv	x,(bp+gapend)
l1:	mv	a,$01
	cmpp	(bp+filend),x
	pushu	x
	jrnz	l2
	mvw	[--u],(bp+bx-base)
	mv	(bp+bx-base+1),(bp+scry)
loop2:	inc	(bp+bx-base+1)
	mv	a,(bp+dhei)
	cmp	(bp+bx-base+1),a
	jrnc	loop2e
	call	clrl			;	1行全て消去
	jr	loop2
loop2e:	mvw	(bp+bx-base),[u++]
	mv	a,$02
l2:	popu	x
	ret
	endl
	endl	;putline

savund3:
	mv	y,(bp+cptr)
	mv	x,(bp+mark)
savund2:
	pushu	x
	pushu	y
	mv	(bp+block1),y
	mv	(bp+block2),x
	call	blosiz
	call	savundo
	popu	y
	popu	x
	ret

savundo:local
;	undo対象文字列をundoバッファに保存
	test	(bp+mode),m_alert
	jrz	end
	mv	(bp+u_flag),0
	mv	x,undosiz+1
	cmpp	(bp+blocks),x
	jrnc	end			;	undoできない
	mvw	[u_max],(bp+maxlin)
	inc	(bp+u_flag)
	SAVE_U
	mv	u,(bp+block1)
	mv	[u_stat],u
	mv	x,(bp+blocks)
	mv	[u_siz],x
	mv	y,undobuf
	call	copygap
end2:	LOAD_U
end:	ret
	endl

setundo:local
	test	(bp+mode),m_alert
	jrz	end
	mvp	[u_end],(bp+cptr)
	mvw	[u_line],(bp+lineno)
end:	ret
	endl

setund2:
	mvp	[u_end],(bp+mark)
	mvw	[u_line],(bp+mrklin)
	ret

copygap:local
;	gapをまたいで転送する
	inc	x
	jr	l1
loop:	popu	a			;	mv	a,[u++]
	mv	[y++],a
	cmpp	(bp+gaptop),u
	jrnz	l1
	mv	u,(bp+gapend)
l1:	dec	x
	jrnz	loop
	ret
	endl

setblo2:
	mv	(bp+block1),x
	jr	setblo!l4

setblo:	local
	test	(bp+mode),m_pfmk+m_fnmk
	jrz	l1
	mvp	(bp+block1),(bp+cptr)
l4:	mvp	(bp+block2),(bp+mark)
	cmpp	(bp+block2),(bp+block1)
	jrz	l3
	jrnc	l2
	exp	(bp+block1),(bp+block2)
l2:	or	(bp+mode),m_rev
l1:	ret
l3:	and	(bp+mode),$ff-m_rev
	and	[rev],$bf
	ret
	endl

tstrev:	local
;	yで示すアドレスがブロック内に入っているか調べ、
;	反転表示フラグをセット／リセットする
	test	(bp+mode),m_rev
	jrz	l3
	cmpp	(bp+block2),y
	jrc	l1
	cmpp	(bp+block1),y
	jrnc	l1
l2:	or	[rev],$40
l3:	ret
l1:	and	[rev],$bf
	ret
	endl

sftmkp:
;	文字を削除したときそれに伴って(mark)をずらす
;	a<-文字のバイト数
	or	[sftmkf!ptch],$08	;	adclをsbclに
	jr	sftmkf!l2

sftmkf:	local
;	文字を挿入したときそれに伴って(mark)をずらす
;	a<-文字のバイト数
	and	[ptch],$f7		;	sbclをadclに
l2:	call	tstmk
	jrnc	l1
	mv	il,3
ptch:	adcl	(bp+mark),a
l1:	ret
	endl

tstmk:	local
;	挿入・削除で(mark)を移動しなければならないか調べる
;	c=1:移動しなければならない
	rc
	test	(bp+mode),m_pfmk+m_fnmk
	jrz	l1
	cmpp	(bp+cptr),(bp+mark)
	jrnc	l1
	cmpp	(bp+mark),(bp+gaptop)
l1:	ret
	endl

chkcr:	local
;	yレジスタで示すアドレスからxレジスタのバイト数のあいだに
;	改行があるか調べる
;	c<-0：改行がある／c<-1：改行がない
	pushu	y
loop:	mv	a,[y++]
	cmp	a,$0d
	jrz	l2
	dec	x
	jrnz	loop
	sc
l2:	popu	y
	ret
	endl


blosiz:	local
;	ブロックの大きさを求める
	mv	x,(bp+block1)
	mv	y,(bp+gaptop)
	cmpp	(bp+block2),y
	jrnc	l1
	mv	y,(bp+block2)
l1:	sub	y,x
	mv	(bp+blocks),y
	mv	y,(bp+block2)
	mv	x,(bp+gapend)
	sub	y,x
	jrc	l2
	mv	x,(bp+blocks)
	add	y,x
	mv	(bp+blocks),y
l2:	ret
	endl

sftclp:	local
;	カットバッファの大きさを調節する
;	割り込みを禁止し、uレジスタを待避しておく
	mv	u,(bp+filend)
	mv	x,(bp+gapend)
	sub	u,x
	mv	x,(bp+blocks)
	jrnz	l3
	mv	y,mend			;	最後の行を編集中の場合
	sub	y,x
	mv	(bp+filend),y
	mv	(bp+gapend),y
	jr	l6
l3:	mv	y,(bp+clpsiz)
	sub	x,y
	jrz	l1
	mv	[--s],u			;	pushs u
	mv	u,(bp+gapend)
	jrc	l2

;	(blocks)>(clpsiz)
	cmpp	(bp+mark),u
	jrc	l4
	mv	y,(bp+mark)
	sub	y,x			;	markもずらす
	mv	(bp+mark),y
l4:	mv	y,u
	sub	y,x
	pops	x
	mv	(bp+gapend),y
	call	utoy
	mv	(bp+filend),y
	jr	l6

;	(blocks)<(clpsiz)
l2:	mv	x,(bp+blocks)
	sub	y,x
	mv	x,y
	cmpp	(bp+mark),u
	jrc	l5
	mv	y,(bp+mark)
	add	y,x			;	markもずらす
	mv	(bp+mark),y
l5:	mv	u,(bp+filend)
	mv	y,u
	add	u,x
	pops	x
	mv	(bp+filend),u
	call	ytou
	mv	(bp+gapend),u

l6:	mvp	(bp+clpsiz),(bp+blocks)
l1:	ret
	endl

linsub:	local
;	ブロック削除・ペーストに伴って行番号を調節するルーチン
	cmpp	(bp+cptr),(bp+mark)
	pushu	f
	jrz	l1
	mv	ba,(bp+lineno)
	mv	i,(bp+mrklin)
	jrnc	l2

;	(mark) > (cptr)
	sub	i,ba
	mv	ba,(bp+maxlin)
	sub	ba,i
	mv	(bp+maxlin),ba
	jr	l1

;	(mark) < (cptr)
l2:	mv	(bp+lineno),i
	sub	ba,i
	mv	i,(bp+maxlin)
	sub	i,ba
	mv	(bp+maxlin),i
	mv	y,(bp+mark)
	call	subcury

l1:	popu	f
	ret
	endl

subcury:
;	カーソルがyレジスタで示す位置に来るとき(cury)、(ltptr)を上に補正する
	call	srchlt
sbcury2:local
;	yがすでに行先頭にあるとき
	pushu	y
loop:	cmpp	(bp+ltptr),y
	jrz	loope
	sub	(bp+cury),1
	jrc	l1
	mv	(bp+scrx),0
	call	nxtlin
	jrnc	loop
	inc	y
	jr	loop
l1:	inc	(bp+cury)
loope:	popu	y
	mv	(bp+ltptr),y
	ret
	endl

addcury:local
;	カーソルがyレジスタで示す位置に来るとき(cury),(ltptr)を下に補正する
	sub	($ec),7
	mv	(bp+0),y
	mv	(bp+6),(base+dhei)
	dec	(bp+6)
	mv	y,(base+ltptr)
loop:	mv	(base+scrx),0
	mv	(bp+3),y
	call	nxtlin
	jrnc	l1
	inc	y
	cmpp	(bp+0),y
	jrc	loope
l1:	cmpp	(bp+0),y
	jrc	loope
	cmp	(base+cury),(bp+6)
	jrnc	loop
	inc	(base+cury)
	jr	loop
loope:	mvp	(base+ltptr),(bp+3)
	pmdf	($ec),7
	ret
	endl

inpscp:	local
	call	putcrsb
	call	keys2
	pushu	ba
	call	clrcur
	popu	ba
	mv	(bp+keycd),ba
	cmp	(bp+keycd+1),sckey
	jrc	l1
	cmp	(bp+keycd+1),sckey+10
	jrc	l2
	sc
l1:	ret
l2:	rc
	ret
	endl

putcrsb:
	xor	[!putcurs!ptch+1],$08	;	カーソルの点滅を止める
	call	putcurs
	xor	[!putcurs!ptch+1],$08
	ret

putcurs:local
	mvw	(bp+bx-base),(bp+curx)
	mv	a,(bp+scwid)
	sub	(bp+bx-base),a
	jrnc	l1
	mv	(bp+bx-base),0
	mv	a,$24			;	インサートマーク、点滅なし
	jr	l2
l1:	mv	a,(bp+ins)
ptch:	add	a,$2a
l2:	pushu	a
	mv	il,$44
	call	lcdd
	popu	a
	call	curs
	ret

	endl

setlt:
	mv	y,(bp+cptr)
	call	srchlt
	mv	(bp+ltptr),y
	ret

bfrlin:
;	yレジスタに入れた行先頭アドレスより前の行を探す
	dec	y
srchlt:	local
;	yレジスタに入れたアドレスより前にある行先頭を探す
;	a<-その行の幅
	sub	($ec),6
	mv	(bp+0),y
loop:
	mv	a,[--y]
	cmp	a,$0d
	jrnz	loop
	inc	y
loop3:
	mv	(bp+3),y
	mv	(base+scrx),(base+margin)
	call	nxtlin
	jrc	l2
l1:	cmpp	(bp+0),y
	jrnc	loop3
l2:	mv	y,(bp+3)
	mv	a,(base+scrx)
	pmdf	($ec),6
	ret
	endl

findcr:	local
;	カーソル位置からCRがある行を検索する
;	画面内にないときは(dhei)を返す
;	(cry)<-CRがある行
;	F<-前回の(cry)との比較結果
	mv	y,(bp+cptr)
	mvw	(bp+scrx),(bp+curx)
loop:	call	nxtlin
	jrc	l2
	cmpp	(bp+gaptop),y
	jrnz	l1
	mv	y,(bp+gapend)
l1:	mv	(bp+scrx),(bp+margin)
	inc	(bp+scry)
	cmp	(bp+scry),(bp+dhei)
	jrc	loop
l2:	cmp	(bp+cry),(bp+scry)
	mv	(bp+cry),(bp+scry)
	ret
	endl

setcurx:
;	yレジスタで始まる行の(vx)で示される位置に近い位置に
;	カーソルをセットする
	mv	(bp+scrx),(bp+margin)
	mv	a,(bp+vx)
	call	calcwid
	mv	(bp+curx),(bp+scrx)
	mv	(bp+cptr),y
	ret

calcwd2:
	xor	[calcwid!ptch],$0a	;	jrzをjrに書き換える
	call	calcwid
	xor	[calcwid!ptch],$0a	;	jrをjrzに書き換える
	ret

nxtlin:
;	次の行の先頭アドレスを求める
	mv	a,(base+dvwid)

calcwid:local
;	x座標がaに近づくアドレスを探す
;	y->開始アドレス
;	(base+scrx)->開始x座標
;	y<-見つかったアドレス
;	(base+scrx)<-aを越えない最大のx座標
;	c=1:途中でCRが来た
	dec	($ec)
	mv	(bp+0),a
loop:	mv	a,[y]
	cmp	a,$0d
	sc
	jrz	l1
	call	chrwid
	add	(base+scrx),a
	jrc	l2
	add	y,il
	cmp	(base+scrx),(bp+0)
	jrc	loop
ptch:	jrz	l1
	sub	y,il
l2:	sub	(base+scrx),a
	rc
l1:	inc	($ec)
	ret
	endl

calccur:local
;	yレジスタで始まる行のxレジスタの位置のx座標を求める
;	(base+scrx)<-x座標
	sub	($ec),3
	mv	(bp+0),x
	mv	(base+scrx),(base+margin)
loop:	cmpp	(bp+0),y
	jrz	l1
	mv	a,[y]
	cmp	a,$0d
	jrz	l1
	call	chrwid
	add	(base+scrx),a
	jrc	l1
	add	y,il
	jr	loop
l1:	pmdf	($ec),3
	ret
	endl

chrwid:	local
;	文字の幅と、バイト数を求める
;	a<-文字の幅
;	il<-バイト数
;	(base+scrx)<-X座標
	cmp	a,$09
	jrz	l1
	call	isjis1
	mv	a,1
	adc	a,0
	pushu	a			;	2行で
	popu	il			;	mv il,a
	ret
l1:
;	TABコードのとき
	mv	a,0
loop:	add	a,(base+tabwid)
	jrc	l3
	cmp	(base+scrx),a
	jrnc	loop
	cmp	(base+dvwid),a
	jrnc	l2
l3:	mv	a,(base+dvwid)
l2:	sub	a,(base+scrx)		;	a=次のTAB停止位置-scrx
	mv	il,1
	ret
	endl

bfrcr:
	mv	y,(bp+cptr)
bfrcr2:	local
loop:	mv	a,[--y]
	cmp	a,$0d
	jrnz	loop
	inc	y
	ret
	endl

gapbac2:
;	yレジスタで指定した位置の次の行から(gaptop)までを
;	ギャップ領域の後ろへ寄せる
	mv	a,[y++]
	cmp	a,$0d
	jrnz	gapbac2

gapback:local
;	yレジスタで指定した位置から(gaptop)までを
;	ギャップ領域の後ろへ寄せる
	SAVE_U
	test	(bp+mode),m_pfmk+m_fnmk
	jrz	l1
	cmpp	(bp+mark),y
	jrc	l1
	mv	u,(bp+gapend)
	cmpp	(bp+mark),u
	jrnc	l1
	mv	x,(bp+gaptop)
	sub	u,x
	mv	x,(bp+mark)
	add	x,u			;	ブロック開始位置をずらす
	mv	(bp+mark),x
l1:	mv	u,(bp+gapend)
	mv	x,(bp+gaptop)
	pushs	x
	sub	x,y
	pops	y
	jrz	loope
	call	ytou
	mv	(bp+gapend),u
loope:	mv	(bp+gaptop),y
	LOAD_U
	ret
	endl

gapfwd4:local
;	(mark)のある行がギャップ領域の前にあるか調べて
;	後ろにあるなら前に寄せる
	mv	x,(bp+mark)
	mv	y,(bp+gapend)
	cmpp	(bp+mark),y
	jrc	l1
loop1:	mv	a,[x++]
	cmp	a,$0d
	jrnz	loop1
	jr	gapfwd3
l1:	ret
	endl

gapfwd:	local
;	(gapend)から改行までをギャップ領域の前に寄せる
	mv	x,(bp+gapend)
	mv	y,x
loop:	mv	a,[x++]
	cmp	a,$0d
	jrnz	loop
	endl

gapfwd3:local
	sub	x,y
	jrz	l1
	SAVE_U
	mv	u,(bp+gapend)
	mv	y,(bp+gaptop)
	call	utoy
	test	(bp+mode),m_pfmk+m_fnmk
	jrz	l2
	cmpp	(bp+mark),(bp+gapend)	;	移動前の(gapend)
	jrc	l2
	cmpp	(bp+mark),u		;	移動後の(gapend)
	jrnc	l2
	mv	(bp+gapend),u
	sub	u,y
	mv	x,(bp+mark)
	sub	x,u
	mv	(bp+mark),x
	db	$0a			;	次の2バイトをスキップする
l2:	mv	(bp+gapend),u
	mv	(bp+gaptop),y
	LOAD_U
l1:	ret
	endl

;gapclr:	local
;	mv	x,(bp+gaptop)
;	mv	y,(bp+gapend)
;	sub	y,x
;	mv	a,0
;loop:	mv	[x++],a
;	dec	y
;	jrnz	loop
;	ret
;	endl

addsave:
;	既存のファイルに追加Saveする
	call	blocmp2
	pushu	x
	mv	a,3
	call	fopen
	jrc	save_b!e1
	call	fpinit
	mv	(bp+hdl),(bp+cx-base)
	mv	a,2			;	ファイル末尾+1からの相対値
	mvp	(bp+si-base),1
	mv	il,$09			;	ファイルポインタの移動
	call	fcall
	mv	a,0			;	$1Aだったら読み進まない
	mv	(bp+cx-base),(bp+hdl)
	mv	il,$05			;	ファイルのバイト読みだし
	call	fcall
	jr	save_b!l4

save_b:	local
;	(block1)から(block2)までをSaveする
	pushu	x
	call	ffcreat
	jrc	e1
	mv	(bp+hdl),(bp+cx-base)
l4:	mv	il,save_m-ms
	call	putel
	mv	x,(bp+block1)
	mv	y,(bp+gaptop)
	cmpp	(bp+block2),y
	jrnc	l1
	mv	y,(bp+block2)
l1:	sub	y,x
	jrz	l2
	call	save_s
	jrc	e2
	mv	y,(bp+block2)
	mv	x,(bp+gapend)
	sub	y,x
	jrc	l2
	jrz	l2
	call	save_s
	jrc	e2
l2:	test	(bp+tmode),s_eof
	jrnz	l6
	mv	a,$1a
	call	fputc
	jrc	e2
l6:	call	fflush
	jrc	e2
	mv	(bp+cx-base),(bp+hdl)
	call	fclose
	popu	x
	jr	settim
	;ret
e1:	mv	il,opn_e-ms
	jr	l3
e2:	mv	il,fil_e-ms
	cmp	(bp+errno),$0c
	jrnz	l5
	mv	il,ful_e-ms
l5:	pushu	il
	mv	(bp+cx-base),(bp+hdl)
	call	fclose
	popu	il
l3:	call	alert
	popu	x
	call	settim
	sc
	ret
	endl

save_s:	local
;	xレジスタで示されるアドレスから
;	yレジスタで示されるバイト数だけSaveする
loop:	mv	a,[x++]
	pushu	a
	call	fputc2
	popu	a
	jrc	l1
	cmp	a,$0d
	jrnz	l2
	test	(bp+tmode),s_crlf
	jrnz	l2
	mv	a,$0a
	call	fputc2
	jrc	l1
l2:	dec	y
	jrnz	loop
	rc
l1:	ret

fputc2:
	pushu	x
	pushu	y
	call	fputc
	popu	y
	popu	x
	ret
	endl

askow:	local
;	subnamで示すファイルが存在するか調べ、
;	存在するなら上書きするかどうか尋ねる
;	c=1：上書きする
	call	chkow
	jrc	l1
	call	owfile
	mv	il,ok_m-ms
	call	putm
loop:	call	keys2
	and	a,$df			;	大文字小文字を無視する
	cmp	a,'Y'
	sc
	jrz	l1
	cmp	a,'N'
	jrnz	loop
l1:	ret
	endl

chkow:
	mv	x,subnam
	pushu	x
	call	wild
	popu	x
	mv	a,0
	jp	finfo
	;ret

owfile:	local
;	上書きするファイル名を表示する
	mv	x,subnam+6
	mv	y,buf+1
	mv	il,3
	pushu	y
	mv	a,'"'
	mv	[y++],a
loop:	mv	a,[x++]
	cmp	a,' '
	jrz	loop
	cmp	a,$00
	jrz	loope
	mv	[y++],a
	inc	il
	jr	loop
loope:
	mv	ba,$2022
	mv	[y++],ba
	popu	y
	mv	[--y],il
	mv	i,buf-ms
	call	putel
	mv	il,ow_m-ms
	jp	putm
;	ret
	endl

settim:	local
;	タイムスタンプの設定
devno:	equ	0	;2
cfname:	equ	2	;3

isize:	equ	5

	sub	($ec),isize
	mv	(bp+cfname),x

;	"CLOCK:"を探す
	mv	x,clock
	mv	il,0
	call	icall
	jrc	end
	mvw	(bp+devno),(cx)

	mv	x,(bp+cfname)
	mv	a,0
	call	finfo
	jrc	end
	mv	a,[y]
	test	a,1
	jrnz	end			;ライトプロテクトされているとき

	mv	il,$46
	mvw	(cx),(bp+devno)
	call	icall
	jrc	end

	mv	a,1
	mv	x,(bp+cfname)
	call	finfo
end:	add	($ec),isize
	ret
	endl

load:	local
;	テキストを読み込んでギャップ領域に収める
	call	wild
	jrc	ldend
	mv	a,$81
	mvp	(bp+rest),0
	call	fopen
	jrc	ldend
	mv	(bp+hdl),(bp+cx-base)
	mv	(bp+eof),0
	or	(bp+tmode),s_eof+s_crlf
	mv	il,load_m-ms
	call	putel
	test	(bp+pref_d),8
	jrz	l7
	inc	(bp+eof)
l7:	mv	x,(bp+gaptop)
loop:
	call	fgetc
	jrc	loope
l2:	cmp	a,$1a
	jrz	l6
	jrnc	l3			;	a>=$1bのとき
	test	(bp+pref_d),4
	jrz	l3
	cmp	a,$20
	jrnc	l3
	cmp	a,$0d
	jrz	l3
	cmp	a,$09
	jrnz	loop
l3:	cmpp	(bp+gapend),x
	jrz	e1			;	メモリ不足
	cmp	a,$0d
	jrnz	l1
l4:	add	(bp+maxlin),1
	adc	(bp+maxlin+1),0
	mv	[x++],a
	call	fgetc
	jrc	loope
	cmp	a,$0a
	jrnz	l2
	and	(bp+tmode),$ff-s_crlf	;	CR+LFで行が終わる
	jr	loop
l1:	mv	[x++],a
	jr	loop
l6:	and	(bp+tmode),$ff-s_eof	;	EOFが存在する
	cmp	(bp+eof),0
	jrnz	loop
loope:
l5:	mv	y,(bp+gaptop)
	mv	(bp+gaptop),x
	call	chkdbl
	mv	(bp+cx-base),(bp+hdl)
	call	fclose
	cmpw	(bp+maxlin),(bp+lineno)	;	最終行が1行=改行がない
	jrnz	ldend
	mv	a,(bp+smode)
	and	a,s_crlf
	and	(bp+tmode),$ff-s_crlf
	or	(bp+tmode),a
ldend:	ret
e1:	pushu	x
	call	memerr
	popu	x
	jr	l5
	endl

fgetc:	local
;	ギャップ領域を使ってファイルを読み出す
;	a<-DATA
	mv	a,1
	mv	il,3
	sbcl	(bp+rest),a
	jrc	l1
	mv	a,[y++]
	ret
l1:
	pushu	x
	test	($ff),8
	jrnz	l2
	mv	a,(bp+eof)
	mv	(bp+cx-base),(bp+hdl)
	mv	y,(bp+gapend)
	sub	y,x
	jrnz	l3			;	ギャップ領域はあるか？
	mv	a,$ff			;	ダミー
	jr	l2
l3:	mv	il,$03
	call	fcall
	jrc	l2
	mv	a,1
	sub	y,a
	mv	(bp+rest),y
	mv	y,[u]
	mv	a,[y++]
l2:	popu	x
	ret
	endl

chkdbl:	local
	sub	x,y			;	必ずc=0になる
	jrz	l1
loop:	mv	a,[y++]
	jrnc	l2			;	2バイトコードのときc=1
	cmp	a,$40
	jrnc	l3			;	シフトJISは2バイト目が$40～
	mv	a,' '
	mv	[y-2],a
	rc
	jr	l3
l2:	call	isjis1
l3:	dec	x
	jrnz	loop
	jrnc	l1
	mv	a,' '
	mv	[--y],a
l1:	ret
	endl

savewk:	local
;	mv	(bp+wksum),(bp+0)
;	mv	(bp+ptrx-base),wksiz-2
;loop:	mv	a,(bp+px)
;	add	(bp+wksum),a
;	dec	(bp+ptrx-base)
;	jrnz	loop
	mv	il,wksiz
	mvl	[wkbuf],(bp+0)
	ret
	endl

loadwk:
	mv	il,wksiz
	mvl	(bp+0),[wkbuf]
	ret

initwk:
;	ワークエリアの初期化
;	(filtop),(filend),(gaptop),(gapend)は初期化されない
	mv	x,(bp+filtop)
	mv	(bp+cptr),x
	mv	(bp+ltptr),x
	mvw	(bp+lineno),1
	mvw	(bp+maxlin),(bp+lineno)
	mv	il,0
	mv	(bp+scwid),il
	mv	(bp+curx),i
	mv	(bp+vx),il
	ret

copyfnd:local
;	検索文字列を変形する
	sub	($ec),2
	mv	il,c_fbuf+$22
	call	getcfg
	mv	(bp+0),[y++]		;	長さ
	cmp	(bp+0),0
	jrz	l6
	mv	x,fbuf2
	pushu	x
	mv	a,[y++]
	cmp	a,'^'			;	行頭の'^'
	jrnz	l4
	mv	a,$0d
	jr	l2
loop:	mv	a,[y++]
l4:	test	(pref_d+base),2
	jrz	l7
	call	toupper
l7:	cmp	a,'\'
	jrnz	l3
	dec	(bp+0)
	jrz	l1
	mv	a,[y++]
	jr	l2
l3:	cmp	a,'$'
	jrnz	l2
	cmp	(bp+0),1		;	行末か？
	jrnz	l8
	mv	a,$0d
l2:	call	isjis1
	jrnc	l8
	dec	(bp+0)
	jrz	l1			;	シフトJISの1バイト目で終わる場合
	mv	[x++],a
	mv	a,[y++]
l8:	mv	[x++],a
	dec	(bp+0)
	jrnz	loop
l1:	popu	y
	sub	x,y
	mv	i,x
	dec	i
	jrnz	l5
	mv	a,[y]
	cmp	a,$0d
	jrz	l6			;	^または$1文字のみの時
l5:	inc	i
l6:	pmdf	($ec),2
	ret
	endl

found:	local
;	検索文字列が見つかったときの処理
;	y->発見文字列の先頭アドレス
	call	isjis2
	jrnz	l13			;	先頭がシフトJISの2バイト目のとき
	test	(bp+pref_d),2
	jrz	l1
;	シフトJISの2バイト目を大文字小文字を無視していないか確かめる
	pushu	y
	mv	x,fbuf2
	mv	il,(bp+flen)
loop:	mv	a,[x++]
	inc	y
	call	isjis1
	jrnc	loopn
	dec	il
	jrz	loope
	mv	a,[x++]
	mv	(bp+fcmp),[y++]
	cmp	(bp+fcmp),a
	jrnz	l2
loopn:	dec	il
	jrnz	loop
loope:
	popu	y
l1:	mv	x,y
	mv	a,[x++]
	cmp	a,$0d			;	'^'を置き換えた$0dを取る
	jrz	lc2
	dec	x
lc2:	mv	(bp+cptr),x
	mv	il,(bp+flen)
	add	y,il
	test	(bp+mode),m_pfmk
	jrnz	l3
	mv	a,[--y]
	cmp	a,$0d			;	'$'を置き換えた$0dを取る
	jrz	lc1
	inc	y
lc1:	mv	(bp+mark),y
	or	(bp+mode),m_fnmk
l3:	rc
	ret
l2:	popu	y
l13:	sc
	ret
	endl

lowcmp:	local
;	Ignore caseがONの場合
;	(fcmp)が小文字でなければaを大文字に変換する
;	aと(fcmp)を比較する
	test	(bp+pref_d),2
	jrz	l1
	cmp	(bp+fcmp),'a'
	jrnc	l1
	call	toupper
l1:	cmp	(bp+fcmp),a
	ret
	endl

filcmp:	local
	test	(bp+pref_d),$20
	jrz	end
	test	(bp+parawk),4
	jrnz	end
	mv	il,c_lfil+$22
	call	getcfg
	mv	x,fname
	mv	il,18
loop:	mv	a,[y++]
	mv	(bp+fcmp),[x++]
	cmp	(bp+fcmp),a
	jrnz	end
	dec	il
	jrnz	loop
	mvw	(bp+fline),[y]
	or	(bp+parawk),4
end:	ret
	endl

isjis2:	local
;	yレジスタの位置の文字がシフトJISの2バイト目ならz=0(nz)
	mv	x,y
	call	bfrcr2
	sub	x,y			;	必ずc=0になる
	jrz	l1
	inc	x
loop:	mv	a,[y++]
	jrnc	l2			;	2バイトコードのときc=1
	mv	il,0
	rc
	jr	l3
l2:	call	isjis1
	mv	il,1
l3:	dec	x
	jrnz	loop
	dec	y
	dec	il
l1:	ret
	endl

isjis1:
;	aレジスタがシフトJISの1バイト目ならc=1、そうでなければc=0
	cmp	a,$81
	jrc	hnka
	cmp	a,$9f+1
	jrc	znka
	cmp	a,$e0
	jrc	hnka
	cmp	a,$fc+1
	jrnc	hnka
znka:	sc
	db	$64
hnka:	rc
	ret

fputc:	local
;	ファイル書き出しルーチン
;	入力 a->DATA
;	Static IRAM:(bsize).p (poi).p (rest).w
	mv	x,(bp+poi)
	mv	[x++],a
	mv	(bp+poi),x
	add	(bp+rest),1
	adc	(bp+rest+1),0
	cmpw	(bp+bsize),(bp+rest)
	jrz	fflush
	ret
	endl

fflush:
	mv	x,buf
	mv	i,(bp+rest)
	mv	y,i
	mv	(bp+cx-base),(bp+hdl)
	call	fputs
	jrnc	fpinit
	mv	(bp+errno),a
	ret

ffcreat:
	call	blocmp2
	mv	a,0
	mv	il,$00
	call	fcall
fpinit:
	mvp	(bp+poi),buf
	mvw	(bp+rest),0
	ret

blocmp2:local
;	xレジスタで示されたファイルが"S?:"上のものならblocmpを呼ぶ
	pushu	x
	mv	il,0
	call	icall			;	ドライブ名のサーチ
	jrc	l1			;	fcallを呼んでもエラーだが…
	cmp	(bp+cx-base),6		;	メモリ・ブロックの場合
	jrnz	l1
	call	blocmp
l1:	popu	x
	ret
	endl

getquo:	local
;	現在のカーソルの左側を引用符とする
;	(bp+cptr)をスタックにpushする
;	c=0：引用符がない
	call	bfrcr
	mv	x,(bp+cptr)
	pushu	x
	sub	x,y
	jrz	end
	mv	(bp+scrapp),y
	mv	(bp+pstsiz),x
	sc
end:	ret
	endl

getscp:	local
;	押されたキーに対応するスクラップのアドレスと長さを求める
;	y<-アドレス
;	x<-スクラップの先頭アドレス
;	i<-長さ
	mv	i,c_scrap+$22
	call	getcfg
	mv	a,(bp+keycd+1)		;	キーコードの2バイト目から読み込む
	sub	a,sckey
	mv	x,y
loop:	mv	i,[y++]
	jrz	loope
	add	y,i
	dec	a
	jr	loop
loope:	ret
	endl

getcfg:	local
;	PANO.CFGのアドレスを求め、レコードのアドレスを返す
;	PANO.CFGが見つからない場合Resetする
;	i->求めるレコードのオフセット+$22
;	y<-レコードのPANO.CFG内のアドレス
	mv	x,CFG
	pushu	i
	call	bsearch
	popu	i
	jrc	bomb
	add	y,i
	ret
bomb:	reset
	endl

makecfg:local
;	"S?:"にPANO.CFGがあるか調べ、ない場合は"S1:"に新たに作る
	mv	a,2			;	"S3:"
loop:	mv	x,CFG
	mv	[x],a
	pushu	a
	call	bsearch			;	PANO.CFGを探す
	popu	a
	jrnc	end
	sub	a,1
	jrnc	loop
	call	blocmp
	mv	x,CFG
	pushu	x
	mv	a,0
	mv	il,$2f
	call	memd2			;	"S?:"の空き容量を調べる
	popu	x
	jrc	errend
	mv	y,c_size+$22
	cmpp	(bp+si-base),y
	jrc	errend
	pushu	y
	pushu	x
	mv	il,$45
	call	memd2			;	PANO.CFGを作る
	popu	x
	pushu	y
	mv	y,c_size
	mv	a,0
	mv	il,$42
	call	memd2			;	PANO.CFGの後ろを空ける
	popu	y
	popu	x
	jrc	errend

	pushu	y
	mv	[y+$16],x		;	ファイルサイズを設定する
	mv	a,$22
	add	y,a

	mv	x,dflt
	mv	il,c_lfil
	call	xtoy

	mv	i,c_scrap-c_lfil+2*9
	mv	a,0
loop2:	mv	[y++],a			;	クリアする
	dec	i
	jrnz	loop2

	mv	i,[x++]
	mv	[y++],i
	call	xtoy

	popu	y
end:	mv	a,$22+c_ver
	add	y,a
	mv	a,[y++]
	cmp	a,prefver		;	PANO.CFGのバージョンをチェックする
	jrz	errend
	sc
errend:	ret
	endl

blocmp:	local
;	メモリブロックを圧縮し、BTEXT$とBDATA$のポインタを張り直す
	mv	il,$47
	call	memd
	mv	x,(bp+bwork-base)
	mv	a,$72
	add	x,a
	call	bsearch
	jrc	bomb
	mv	(bp+btext-base),y
	call	bsearch
	jrc	bomb
	mv	(bp+bdata-base),y
	ret
bomb:	reset
	endl

getpara:local
	mv	(bp+parawk),0
	mv	a,[x++]
	cmp	a,'"'
	jrz	loop
	dec	x
loop:
	mv	a,[x++]
parl2:	cmp	a,' '
	jrz	loop
	cmp	a,'/'
	jrz	optl
	cmp	a,'-'
	jrnz	l1
optl:	call	str2i
	jrc	l8
	mv	(bp+fline),i
	or	(bp+parawk),4
l8:	cmp	a,'W'
	jrnz	l2
	call	str2a
	jrc	endpara
	cmp	a,2
	jrc	endpara			;	2文字以上
	mv	(bp+subwid),a
	dec	x
	jr	optl
l2:	cmp	a,'T'
	jrnz	l4
	call	str2a
	jrc	endpara
	cmp	a,1
	jrc	endpara			;	1文字以上
	mv	(bp+tabwid),a
	dec	x
	jr	optl
l4:	cmp	a,'E'
	jrnz	l7
	or	(bp+pref_d),8
	mv	a,[x++]
	cmp	a,'0'
	jrnz	l10
	and	(bp+pref_d),$f7
	jr	optl
l7:	cmp	a,'S'
	jrnz	l5
	or	(bp+pref_d),4
	mv	a,[x++]
	cmp	a,'0'
	jrnz	l10
	and	(bp+pref_d),$fb
	jr	optl
l10:	dec	x
	jr	optl
l5:;	cmp	a,'R'
;	jrnz	l6
;	test	(bp+parawk),1
;	jrnz	endpara
;	or	(bp+parawk),3
;	jr	optl
l6:	cmp	a,' '+1
	jrc	parl2
	jr	endpara
l1:
	dec	x
	cmp	a,$0d
	jrz	pare
	test	(bp+parawk),1
	jrnz	endpara
	mv	y,fname
	mv	a,0
	call	file
	or	(bp+parawk),1
	jr	loop
endpara:
	dec	x
	sc
pare:	ret
	endl

file:	local
;	入力ファイル名->FCSファイル名(ワイルドカード展開付)
;	x->パラメータアドレス
;	A->0:スペース、CRで終わる文字列　1:il->文字数+1
tctr:	equ	0
pmax:	equ	1
tlen:	equ	2
drvd:	equ	3
	sub	($ec),4
	pushu	y
	mvw	(bp+tctr),$06ff
	mvw	(bp+tlen),0
	pushu	a
	pushu	il
	pushu	x
;	':'の有無、ファイルの終末を調べる
loop1:	inc	(bp+tlen)
	mv	a,[x++]
	cmp	a,':'
	jrnz	l1
	mv	(bp+drvd),1
	jr	loop1
l1:	cmp	a,' '+1
	jrc	loop1e
	cmp	a,'/'
	jrnz	loop1
loop1e:
	popu	x
	popu	il
	popu	a
	cmp	a,0
	jrz	l6
	mv	(bp+tlen),il
l6:	mv	il,15
	dec	(bp+drvd)
	jrz	floop2
;	ドライブが入力されていない
	pushu	x
	mv	x,cdrv
dloop:	inc	(bp+tctr)
	mv	a,[x++]
	mv	[y++],a
	cmp	a,':'
	jrnz	dloop
	inc	(bp+tctr)
	popu	x
;	メイン部分
l5:	mv	a,' '
	call	fill
	mv	(bp+pmax),il
floop2:	dec	(bp+tlen)
	jrz	fend
	inc	(bp+tctr)
	mv	a,[x++]
	cmp	a,'*'
	jrnz	l3
	mv	a,'?'
	call	fill
	jr	floop2
l3:	mv	il,18
	cmp	a,'.'
	jrz	l5
	cmp	(bp+tctr),(bp+pmax)
	jrnc	floop2
	mv	[y++],a
	mv	il,15
	cmp	a,':'
	jrnz	floop2
	inc	(bp+tctr)
	jr	l5
fend:
	popu	y
	mv	a,'.'
	mv	[y+14],a
	mv	a,0
	mv	[y+18],a
	add	($ec),4
	ret
fill:
;	ファイル名の終わりまでaレジスタで指定された文字で埋める
;	ついでにyはデリミタの次に合わせておく
	pushu	y
sloop1:	cmp	(bp+tctr),(bp+pmax)
	jrnz	l4
	mv	[u],y
l4:
	cmp	(bp+tctr),18
	jrnc	sloop1e
	inc	(bp+tctr)
	mv	[y++],a
	jr	sloop1
sloop1e:
	popu	y
	mv	(bp+tctr),(bp+pmax)
	dec	(bp+tctr)
	ret
	endl	;of file

ytou:
	mv	a,[--y]
	pushu	a			;	mv [--u],a
	dec	x
	jrnz	ytou
	ret

utoy:
	popu	a			;	mv	a,[u++]
	mv	[y++],a
	dec	x
	jrnz	utoy
	ret

xtoy:
	mv	a,[x++]
	mv	[y++],a
	dec	il
	jrnz	xtoy
	ret

str2a:
	call	str2i
	jrc	i2a!l1
i2a:	local
	mv	ba,i
	mv	il,255
	sub	i,ba
l1:	ret
	endl

str2i:	local
	mv	il,0
	mv	a,[x++]
	call	isnum
	jrc	l1
loop:	sub	a,'0'
	add	i,i
	pushu	i
	add	i,i
	add	i,i
	add	i,a
	popu	ba
	add	i,ba			;	i=i*10+a
	mv	a,[x++]
	call	isnum
	jrnc	loop
	rc
l1:	ret
	endl

isnum:	local
	cmp	a,'9'+1
	jrnc	l1
	cmp	a,'0'
	ret
l1:	sc
	ret
	endl

toupper:local
	call	isalph
	jrc	l1
	and	a,$df			;	大文字に変換
l1:	ret
	endl

isalph:	local
	cmp	a,'A'
	jrc	l1
	cmp	a,'z'+1
	jrnc	l2
	cmp	a,'a'
	jrnc	l1
	cmp	a,'Z'+1
	jrnc	l2
	rc
l1:	ret
l2:	sc
	ret
	endl

iskey:	local
;	キーバッファにコントロールコードでない文字が入力されているか調べる
;	c=0：文字がある/c=1：文字はない
	test	(bp+smode),s_pf
	jrnz	pfok
	or	[$bfc3f],$02		;	ファンクションキーを無効に
pfok:	mv	a,1
	mv	il,$0e
	call	keyd			;	キーバッファの次の文字を調べる
	cmp	a,' '+1			;	コントロールコード
	jrc	l1
	mv	a,b
	cmp	a,0			;	入力されていない
	jrz	l1
	ret				;	必ずc=0
l1:	sc
	ret
	endl

puti:
;	iを10進左詰めで表示
	mv	(bp+di-base),i
	mv	(bp+di-base+2),0

putdi:	local
;	diを10進左詰めで表示
	sub	($ec),17
	mvw	(bp+15),(bx)
	mv	(bp+0),0
	mvp	(bp+1),(di)
	mv	il,$7f
	call	func
	mv	[--s],u			;	pushs u
	mv	il,$78
	call	func
	mv	x,(bp+1)
	mv	il,(bp+4)
	mvw	(bx),(bp+15)
	add	($ec),17
	call	putn2
	mv	u,[s++]			;	pops u
	ret
func:	mvw	(cx),9
	jr	icall
	endl

memerr:
	mv	il,mem_e-ms
alert:	local
	test	(base+mode),m_alert
	jrz	l1
	call	putel
	jr	keys2
l1:	ret
	endl

keyp:	local
;	カーソルを表示して入力待ち、終わったらカーソルを消す
	call	putcurs
	test	(bp+smode),s_pf
	jrnz	pfok
	or	[$bfc3f],$02		;	ファンクションキーを無効に
pfok:	call	keys
	pushu	ba
	call	clrcur
	popu	ba
	ret
	endl

keys2:
	or	[$bfc3f],$02		;	ファンクションキーを無効に
keys:
;	キーボードから入力：2バイトコード、パワーオフ対応
	call	keyr
	mv	i,$0100
	sub	i,ba
	jrnz	ksbyte
	call	keyr
	cmp	a,$04
	jrz	poff
	cmp	a,$0f
	jrz	poff
	ex	a,b
	mv	a,0
ksbyte:	and	[$bfc3f],$fd		;	ファンクションキーを有効に
	ret
poff:	mv	a,0
	call	onof
	mvw	(cx),8
	mv	il,$41
	call	icall
	mv	a,1
	call	onof
	jr	keys

fpsave:
;	FEPの状態を保存してOFFする
	mv	il,$7e
	call	keyd
	mv	(base+fpmode),a
	mv	a,0
	jr	fpset

fpres:	mv	a,(base+fpmode)
fpset:	mv	il,$7f
	jr	keyd

kclr:	mv	il,$45
	jr	keyd
keyr:	mv	a,$01
	mv	il,$0c
keyd:	mvw	(cx),1
	jr	icall

bsearch:mv	il,$41
memd2:	mv	(cx+1),[x++]
memd:	mv	(cx),6
	jr	icall

puttab:	test	(bp+mode),m_tab
	jrnz	putspc
	jr	putof

putcr:	test	(bp+mode),m_cre
	jrz	putspc

putof:	mvp	(base+oldfnt),[fontad]
	mv	x,fdat
	mv	[fontad],x
	call	putc
	mvp	[fontad],(base+oldfnt)
	ret

putel:
;	画面のいちばん下の行に表示
	pushu	i
	mv	(bx+1),(base+dhei)
	dec	(bx+1)
	call	clrl
	popu	i
	mv	(bx),0
	jr	putm

onof:	mv	il,$50
	jr	lcdd
clrcur:	mv	a,0
curs:	mv	il,$45
	jr	lcdd
clrl:	mv	il,$49
	jr	lcdd
clrn:	mv	il,$52
	jr	lcdd
putst:	jrnz	putc
	mv	a,'-'
	jr	putc
putspc:	mv	a,' '
putc:	mv	il,$57
	jr	lcdd
putm:	mv	x,ms
	add	x,i
putp:	mv	il,[x++]
putn2:	mv	y,i
putn:	mv	il,$42
lcdd:	mvw	(cx),0
icall:	callf	iocs
	ret

finfo:	mv	y,buf
	mv	il,$0b
	jr	fcall
wild:	mv	y,x
	mv	a,$80
	mvw	(bx),0
	mv	il,$0c
	jr	fcall
putm2:	mv	x,ms
	add	x,i
	mv	il,[x++]
	mv	y,i
	mv	(cx),0
fputs:	mv	il,$04
	jr	fcall
fopen:	mv	il,$01
	jr	fcall
fclose:	test	[$bfcbe],$80		;	Breakが離されるまで待つ
	jrnz	fclose
	mv	il,$02
fcall:	callf	fcs
	ret

;	特殊コードフォント
fdat:	db	$20,$20,$30,$20,$00,$00	;	TABコード
	db	$20,$30,$20,$20,$3c,$3c	;	CRコード
	db	$08,$14,$22,$7f,$00,$00	;	EOFコード
	db	$00,$00,$08,$08,$00,$00	;	漢字が次の行にまたがるときのハイフン

cltab:
;	1行入力でしか使えないキー
	dw	$010c,ctry,   $011e,hist
cttab:
;	1行入力と編集の両方で使えるキー
	dw	$011c,c_right,$011d,c_left, $3c00,linend,$3d00,lintop
	dw	$0105,ctre,   $0104,delc,   $0119,ctry,  $0108,bs
	dw	$0112,chgins, $0109,tab,    $9100,tab,   $8b00,ctrlin
	dw	$5c00,pgright,$5d00,pgleft
	dw	$1700,cpaste, $0e00,chgpf,  $8a00,chgind, $8f00,case

sckey:	equ	$60
	dw	sckey*256,    spaste,(sckey+1)*256,spaste,(sckey+2)*256,spaste
	dw	(sckey+3)*256,spaste,(sckey+4)*256,spaste,(sckey+5)*256,spaste
	dw	(sckey+6)*256,spaste,(sckey+7)*256,spaste,(sckey+8)*256,spaste
	dw	(sckey+9)*256,spaste
clnum:	equ	(*-cltab)/4	;	1行入力で使えるキーの数

;	編集でしか使えないキー
rfkey:	equ	$7100	;	置換 & 前方検索
rbkey:	equ	$6c00	;	置換 & 後方検索
	dw	$010d,retkey, $2d00,ins_cr, $011f,c_down,$011e,c_up
	dw	$5f00,allend, $5e00,alltop, $3f00,pgdown,$3e00,pgup
	dw	$8500,scleft, $8700,scright,$8c00,scdown,$8100,scup
	dw	$a500,pgleft, $a700,pgright,$ac00,pgdown,$a100,pgup
	dw	$1500,revs,   $1600,cut,    $010c,clrblo,$0118,defscp
	dw	$1300,find,   $0106,find,   $1400,inrplc,$d000,undo
	dw	$0107,findnx, $0114,findbf, rfkey,rplfwd,rbkey,rplbfr
	dw	$010a,goline, $0113,save,   $8400,displn,$0111,ctrq
	dw	$010b,wraplin,$6d00,delquo, $5200,quoman,$4800,dquman
	dw	$011b,wrpquo, $2600,kalku
ctnum:	equ	(*-cttab)/4	;	コントロールキーの数

cqtab:
;	[CTRL]+Q ??? のキー
	dw	$0104,setwid, $0109,settab, $010b,setwwid,$010a,swapmk
	dw	$0117,chgwid, $0103,chgorg, $0105,chgcol, $d100,tabspc 
	dw	$5c00,clnend, $5d00,clntop, $0112,replace

	dw	sckey*256,    quote,(sckey+1)*256,quote,(sckey+2)*256,quote
	dw	(sckey+3)*256,quote,(sckey+4)*256,quote,(sckey+5)*256,quote
	dw	(sckey+6)*256,quote,(sckey+7)*256,quote,(sckey+8)*256,quote
	dw	(sckey+9)*256,quote
cqnum:	equ	(*-cqtab)/4


mntab:
mnnum:	equ	6
	dw	$1300,asksave,$1400,rename,$1500,import,$1600,export
	dw	$1700,pref,   $3700,fform

CFG:	db	0,'PANO    CFG'
clock:	db	'CLOCK:',0
ini60:	db	'W4'

ms:
load_m:	db	12,'Now loading.'
save_m:	db	11,'Now saving.'
h_m:	db	3,' h:'
ow_m:	db	9,'Overwrite'
	db	16,' or Append?(O/A)'
end_m:	db	4,'Save'
ok_m:	db	9,' ok?(Y/N)'
impo_m:	db	6,'Import'
expo_m:	db	6,'Export'
line_m:	db	4,'Line'
srch_m:	db	6,'Search'
rplc_m:	db	7,'Replace'
wid_m:	db	5,'Width'
tab_m:	db	3,'Tab'
wrp_m:	db	4,'Wrap'
rev_m:	db	9,'Reversed.'
nf_e:	db	10,'Not found!'
num_e:	db	13,'Number error.'
opn_e:	db	16,'File can''t open.'
fil_e:	db	11,'File error.'
ful_e:	db	10,'Disk full.'
mem_e:	db	18,'Not enough memory.'
;rsm_e:	db	13,'Can''t resume.'
cfg_e:	db	15,'PANO.CFG error.'
undo_e:	db	11,'Can''t undo.'
onof_d:	db	4,' ON ',5,' OFF '
eof_d:	db	7,'  EOF  ',6,' none '
cr_d:	db	7,' CR+LF ',6,'  CR  '

title:	db	33+21,'Text Editor ''PANORAMA'' ver 1.22',$0d,$0a
	db	'by Daisuke Mizobata',$0d,$0a
help:	db	34,'usage: PANO [filename] [-option]',$0d,$0a
menu_m:	db	' Quit',$ff,'Rename',$ff,'Import',$ff,'Export',$ff,' Pref',$ff
pref_m:	db	11,'Wrap around'
	db	11,'Ignore case'
	db	15,'Strip ctrl code'
	db	14,'Read after EOF'
	db	0
pref2_m:db	 9,'Word wrap'
	db	16,'Go to saved line'
	db	0
form_m:	db	11,'End of File'
	db	11,'End of Line'

dflt:
;	PANO.CFGの初期値
	db	prefver,m_cre,0,uwid,twid,wwid
	dw	scpsiz
	db	$30

	dw	25,'BXR00012@niftyserve.or.jp'

u_stat:	equ	*
u_end:	equ	u_stat+3
u_siz:	equ	u_end+3
u_line:	equ	u_siz+3
u_max:	equ	u_line+2

fname:	equ	u_max+2		;	編集ファイル名
subnam:	equ	fname+19	;	rename、import、exportするファイル名
wkbuf:	equ	subnam+19	;	ワークエリアのバッファ
fbuf2:	equ	wkbuf+wksiz	;	検索文字列（コンバート済み）
buf:	equ	fbuf2+fndsiz	;	各種バッファ(256バイト)
;	equ	buf+256

	end	;	fname+595
