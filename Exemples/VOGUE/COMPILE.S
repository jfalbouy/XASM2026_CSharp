getch:		local
		cmpw	(bp+!line1),(bp+!line2)
		jrz	l0
		mvw	(bp+!line1),(bp+!line2)
		mv	ba,(bp+!line1)
		mv	y,u
		mv	x,format
		pushu	x
		mv	x,ba
		pushu	x
		mv	x,y
		call	!printf
l0:		call	!_getch
		cmp	a,$0d
		jrnz	l1
		test	(bp+!src_stat),1
		jrnz	l2
		call	!_getch1
		cmp	a,$ff
		jrnz	l4
		or	(bp+!src_stat),2
		ret
l4:		mv	(bp+!line2+1),a
		call	!_getch1
		mv	(bp+!line2),a
		call	!_getch1
		and	(bp+!src_stat),$fd
		jr	l3
l2:		call	!_getch
		mv	ba,(bp+!line2)
		inc	ba
		mv	(bp+!line2),ba
		jr	!getch
l3:		call	!_getch
l1:		test	(bp+!src_symswitch),1
		jrz	exit1
		pushu	x
		mv	x,[!symadr]
		mv	[x++],a
		mv	[!symadr],x
		popu	x
exit1:		ret
format:		db	13,' %d: ',0
		endl
;
_getch:		local
		test	(bp+!src_stat),2
		jpnz	!err1
		endl
_getch1:	local
		mv	a,[!txtcount]
		cmp	a,0
		jrnz	l1
		test	(bp+!src_stat),$40
		jrnz	file_end
		mv	il,3
		mv	x,!txtbuf
		mv	[!txtpnt],x
		mv	y,128
		mv	(!cl),(bp+!src_handle)
		mv	a,[!dev_attr]
		callf	!fcntl
		mv	a,y
		and	(bp+!src_stat),$bf
		cmp	a,0
		jrz	file_end
		cmp	a,128
		jrz	l2
		or	(bp+!src_stat),$40
l2:		mv	[!txtcount],a
l1:		mv	a,[!txtcount]
		dec	a
		mv	[!txtcount],a
		mv	x,[!txtpnt]
		mv	a,[x++]
		mv	[!txtpnt],x
		jr	exit
file_end:	mv	a,$1a
		or	(bp+!src_stat),2
exit:		mv	(bp+!src_char),a
		ret
		endl	
;
getsym:		local
		and	(bp+!src_symswitch),0
		mv	x,!symbuf+16
		mv	[!symadr],x
		mv	a,(bp+!src_char)
l1:		cmp	a,$21
		jrnc	l3_4
		call	!getch
		jr	l1
;
l3_4:		cmp	a,'/'
		jrnz	l3
		call	!getch
		cmp	a,'*'
		jrnz	l3_1
l3_2:		call	!getch
l3_3:		cmp	a,'*'
		jrnz	l3_2
		call	!getch
		cmp	a,'/'
		jrnz	l3_3
		call	!getch
		jr	l1
l3_1:		or	(bp+!src_symswitch),1
		mv	b,a
		mv	a,'/'
		mv	x,[!symadr]
		mv	[x++],ba
		mv	[!symadr],x
		mv	a,b
		cmp	a,'='
		jrnz	l3_5
		call	!getch
		mv	a,$08
		jr	_exit
l3_5:		mv	a,'/'
		jr	_exit
;
l3:		or	(bp+!src_symswitch),1
		mv	x,[!symadr]
		mv	[x++],a
		mv	[!symadr],x
		cmp	a,'<'
		jrnz	l3_6
		call	!getch
		cmp	a,'<'
		jrnz	l3_7
		call	!getch
		cmp	a,'='
		jrnz	l3_8
		call	!getch
		mv	a,$ff
		jr	_exit
l3_8:		mv	a,$0e
		jr	_exit
l3_7:		cmp	a,'='
		jrnz	l3_9
		call	!getch
		mv	a,$02
		jr	_exit
l3_9:		mv	a,'<'
		jr	_exit
;
l3_6:		cmp	a,'>'
		jrnz	l6
		call	!getch
		cmp	a,'>'
		jrnz	l3_11
		call	!getch
		cmp	a,'='
		jrnz	l3_12
		call	!getch
		mv	a,$0f
		jr	_exit
l3_12:		mv	a,$0d
		jr	_exit
l3_11:		cmp	a,'='
		jrnz	l3_13
		call	!getch
		mv	a,$03
		jr	_exit
l3_13:		mv	a,'>'
_exit:		jp	exit
;
l6:		mv	x,two_ch_opr
l11:		mv	ba,[x++]
		cmp	a,$ff
		jrz	l3_10
		cmp	(bp+!src_char),a
		jrnz	l11
		pushu	ba
		call	!getch
		cmp	a,'='
		popu	ba
		jrnz	exit
		mv	a,b
		pushu	a
		call	!getch
		popu	a
		jr	exit
;
l3_10:		mv	a,(bp+!src_char)
		pushu	i
		pushu	a
		call	!isdigit
		jrz	l2
;
		mv	x,0			;decimal number
l4:		add	x,x			;x:=x*10
		pushu	x
		add	x,x
		add	x,x
		popu	y
		add	x,y
		mv	a,(bp+!src_char)	;x:=x+asc(ch)-asc('0')
		sub	a,'0'
		add	x,a
		pushu	x
		call	!getch
		popu	x
		pushu	i
		pushu	a
		call	!isdigit
		jrnz	l4
l7:		mv	a,0
		jr	exit
;
l2:		mv	a,(bp+!src_char)
		cmp	a,'$'
		jrnz	l12
;
		mv	x,0			;hexadecimal digit
l9:		pushu	x
		call	!getch
		popu	x
		pushu	i
		pushu	a
		call	!upcase
		sub	a,'0'
		jrc	l7
		cmp	a,10
		jrc	l7_1
		sub	a,7
		cmp	a,10
		jrc	l7
		cmp	a,$10
		jrnc	l7
l7_1:		add	x,x
		add	x,x
		add	x,x
		add	x,x
		add	x,a
		jr	l9
;
l12:		mvp	[--u],(bp+!src_char)
		call	!isalpha
		jrnz	l13
		cmp	(bp+!src_char),'_'
		jrz	l13
		mv	(bp+!src_sym),(bp+!src_char)
		call	!getch
		jr	exit1
l13:		mv	y,!symbuf
		mv	il,8
l14:		pushu	il
		mvp	[--u],(bp+!src_char)
		call	!upcase
		mv	[y++],a
		mv	a,0
		mv	[y],a
		popu	il
		dec	il
		jpz	!err2
		pushu	il
		pushu	y
		call	!getch
		pushu	i
		pushu	a
		call	!isalpha
		popu	y
		popu	il
		jrnz	l14
		mv	a,(bp+!src_char)
		cmp	a,'_'
		jrz	l14
		cmp	a,'0'
		jrc	l14_1
		cmp	a,'9'+1
		jrc	l14
l14_1:		mv	x,rsym
		mv	(bp+!src_sym),$10
l16:		pushu	x
		mv	x,!symbuf
		pushu	x
		call	!strcmp
		jrnz	exit1
		inc	(bp+!src_sym)
		cmp	(bp+!src_sym),$1f
		jrnz	l16
		mv	a,$1f
exit:		mv	(bp+!src_sym),a
exit1:		and	(bp+!src_symswitch),0
		ret
two_ch_opr:	db	'!',1,'=',4,'+',5,'-',6,'*',7,'/',8,'%',9,'&',$a,'|',$b,'#',$c,$ff
rsym:		db	'CHAR',0,'INT',0,'PNT',0,'INLINE',0,'RETURN',0,'FUNC',0
		db	'IF',0,'ELSE',0,'WHILE',0,'DO',0,'UNTIL',0,'EXIT',0
		db	'PROTO',0,'CONST',0,'BREAK',0
		endl
;
push_work:	local
		pushu	ba
		pushu	i
		pushu	x
		pushu	y
		ret
		endl
;
putobj:		local
		call	!push_work
		pushu	a
		mv	a,[!objcount]
		cmp	a,128
		jrnz	l1
		call	!flush_obj
l1:		popu	a
		mv	x,[!objpoint]
		mv	[x++],a
		mv	[!objpoint],x
		mv	a,[!objcount]
		inc	a
		mv	[!objcount],a
		jr	!pop_work
		endl
;
flush_obj:	local
		mv	il,4
		mv	a,0
		mv	b,a
		mv	a,[!objcount]
		mv	y,a
		cmp	a,0
		jrz	l1
		pushu	a
		mv	(!cl),(bp+!obj_handle)
		mv	x,!objbuf
		callf	!fcntl
		mv	il,y
		popu	a
		sub	il,a
		jpnz	!error4
		and	[!objcount],0
l1:		mv	x,!objbuf
		mv	[!objpoint],x
		ret
		endl
;
movobj:		local
		call	!push_work
		mv	(bp+!obj_adr),x
		test	(bp+!src_stat),$10
		jrz	movobj1
		test 	(bp+!src_stat),$08
		jrz	movobj2
		pushu	x
		call	!flush_obj
		popu	x
		mv	y,!start-16
		sub	x,y
		mv	il,9
		mv	(!cl),(bp+!obj_handle)
		mv	(!si),x
		mv	a,0
		callf	!fcntl
		jr	!pop_work
movobj2:	mv	y,!obj_start-!getch
		add	x,y
movobj1:	mv	(bp+!obj_pnt),x
		endl
;
pop_work:	local
		popu	y
		popu	x
		popu	i
		popu	ba
		test	(bp+!src_stat),8
		jrz	l1
		mvp	(bp+!obj_pnt),(bp+!obj_adr)
l1:		cmpp	(bp+!obj_pnt),u
		jpnc	!make_frame!l3
		ret
		endl
;
delobj:		local
		call	!push_work
		test	(bp+!src_stat),8
		jrz	l1
		mv	a,[!objcount]
		cmp	a,0
		jrz	l2
		dec	a
		mv	[!objcount],a
		mv	x,[!objpoint]
		dec	x
		mv	[!objpoint],x
		jr	l1
l2:		mv	(!cl),(bp+!obj_handle)
		mv	il,9
		mvp	(!si),-1
		mv	a,1
		callf	!fcntl
l1:		mv	x,(bp+!obj_adr)
		dec	x
		mv	(bp+!obj_adr),x
		mv	x,(bp+!obj_pnt)
		dec	x
		mv	(bp+!obj_pnt),x
		jr	!pop_work
		endl
;
objout1:	local
		call	!push_work
		test	(bp+!src_stat),8
		jrnz	l1
		mv	y,(bp+!obj_pnt)		;Obj_adr=obj_adr+1;
		mv	[y++],a
		mv	(bp+!obj_pnt),y
l2:		mv	y,(bp+!obj_adr)
		inc	y
		mv	(bp+!obj_adr),y
		jr	!pop_work
l1:		call	!putobj
		jr	l2
		endl
;
objout2:	local
		call	!push_work
		test	(bp+!src_stat),8
		jrnz	l1
		mv	y,(bp+!obj_pnt)		;Obj_adr=obj_adr+2;
		mv	[y++],ba
		mv	(bp+!obj_pnt),y
		mv	y,(bp+!obj_adr)
		inc	y
		inc	y
		mv	(bp+!obj_adr),y
		jr	!pop_work
l1:		call	!objout1
		mv	a,b
		call	!objout1
		jr	!pop_work
		endl
;
objout3:	local
		call	!push_work
		test	(bp+!src_stat),8
		jrnz	l1
		mv	y,(bp+!obj_pnt)		;Obj_adr=obj_adr+3;
		mv	[y++],x
		mv	(bp+!obj_pnt),y
		mv	y,(bp+!obj_adr)
		mv	a,3
		add	y,a
		mv	(bp+!obj_adr),y
		jr	!pop_work
l1:		pushu	x
		popu	a
		call	!objout1
		popu	ba
		call	!objout2
		jr	!pop_work
		endl
;
getadd:		local
		mvp	(bp+!src_work1),(bp+!src_table)
		mv	(bp+!src_work2),ba
l4:		mv	x,(bp+!src_work1)
l2:		mv	a,[x++]
		cmp	a,$fe
		jrnc	l1
		test	(bp+!src_work2),a
		jrnz	type_match
		mv	a,[x+10]
		swap	a
		and	a,$f
		test	(bp+!src_work2+1),a
		jrnz	type_match
l3:		mv	x,(bp+!src_work1)
		mv	a,12
		add	x,a
		mv	(bp+!src_work1),x
		jr	l2
type_match:	pushu	x
		mv	x,!symbuf
		pushu	x
		call	!strcmp
		jrz	l3
		mv	x,(bp+!src_work1)
		mv	a,[x]
		mv	x,[x+9]
		sc
		ret
l1:		test	(bp+!src_work2),$20
		jrz	not_found
		mvp	(bp+!src_work1),!builtin_func
		cmp	a,$fe
		jrnz	l4
not_found:	rc
		ret
		endl
;
eval:		local
		cmp	a,$ff
		jrnz	l1
		mv	a,$c			;Write 'mv x,imm20'
		call	!objout1
		call	!objout3
		mv	a,4
		ret
l1:		cmp	a,$10
		jrc	exit
		pushu	a
		cmp	a,$15
		jrnc	l3
		add	a,$80			;Write 'mv a,[x]' or 'mv ba,[x]' or 'mv x,[x]'
		mv	b,a
		mv	a,$04
		ex	a,b
		call	!objout2
		popu	a
		sub	a,$10
		jr	exit
l3:		cmp	a,$1a
		jrnc	l3_1
		mv	a,$10
		call	!eval
		popu	a
		sub	a,$17
		shl 	a
		mv	b,a
		mv	a,0
l3_3:		jp	!cast
l3_1:		cmp	a,$1c
		jrnc	l3_2
		mv	a,$12
		call	!eval
		popu	a
		sub	a,$1a
		shl	a
		shl	a
		mv	b,a
		mv	a,2
		jr	l3_3
l3_2:		cmp	a,$1e
		jrnc	l2
		mv	a,$14
		call	!eval
		popu	a
		sub	a,$1c
		shl	a
		mv	b,a
		mv	a,4
		jr	l3_3
l2:		mv	ba,$0008		;Write 'mv a,0'
		call	!objout2
		mv	a,2			;Write 'JRcc +2'
		mv	b,a
		popu	a
		sub	a,$20
		add	a,a
		add	a,$18
		call	!objout2
		mv	ba,$0108		;Write 'mv a,1'
		call	!objout2
		mv	a,0
exit:		ret
		endl
;
v_acc:		local
		mv	y,8			;Make stack frame
		call	!make_frame
;
		mv	a,0
		mv	[(bp+!src_local)+1],a	;Clear global var. flag
		mv	a,(bp+!src_sym)
		cmp	a,'@'
		mv	il,$10
		jrz	l5
		cmp	a,'*'
		mv	il,$12
		jrz	l5
		cmp	a,'^'
		mv	il,$14
		jrz	l5
		cmp	a,$1f
		jpnz	!err9			;Syntax error
		mv	ba,$18			;Sreach global/local var.
		call	!getadd
		jpnc	!err4			;Undefined identifier
		pushu	a
		test	a,$8
		jrnz	global_var		;jump if global var.
		mv	(bp+!src_work1),x
		cmp	(bp+!src_work1+2),0
		jrnz	pnt_offset
		mv	ba,x
		pushu	ba
		cmp	(bp+!src_work1+1),0
		jrnz	int_offset
		mv	a,$8			;char_offset
		call	!objout1		;Write 'mv a,imm8'
		popu	ba
		call	!objout1
		mv	a,$04			;Write 'call v_adr1'
		call	!objout1
		mv	ba,!v_adr1
		call	!objout2
		jr	l3
int_offset:	mv	a,$a			;Write 'mv ba,imm16'
		call	!objout1
		popu	ba
		call	!objout2
		mv	a,$04			;Write 'call v_adr2'
		call	!objout1
		mv	ba,!v_adr2
		call	!objout2
		jr	l3
pnt_offset:	mv	a,$c			;Write 'mv x,imm20'
		call	!objout1
		call	!objout3
		mv	a,$04			;Write 'call v_adr3'
		call	!objout1
		mv	ba,!v_adr3
		call	!objout2
		jr	l3
global_var:	mv	a,$0c			;Write 'mv x,imm20'
		mv	[(bp+!src_local)+1],a	;Set global var. flag
		call	!objout1
		mvp	[(bp+!src_local)+2],(bp+!obj_adr)
		mv	[(bp+!src_local)+5],x
		call	!objout3
l3:		call	!getsym
		popu	a
		and	a,7
		or	a,$10
		jr	l4
l5:		pushu	il
		call	!getsym
		call	!exp5
		call	!eval
		mv	b,a
		mv	a,4
		ex	a,b
		call	!cast
		popu	a
l4:		mv	[(bp+!src_local)],a
		mv	a,(bp+!src_sym)
		cmp	a,'['
		jrnz	l7
		mv	a,$2c			;Evaluate expression in [] and calculate offset
		call	!objout1		;Write 'pushu x'
		call	!getsym
		call	!exp
		cmp	a,$ff
		jrnz	l8
		call	!delobj			;Constant offset
		mv	a,[(bp+!src_local)]
		cmp	a,$12
		jrc	l9
		mv	y,x
		add	x,x
		cmp	a,$14
		jrc	l9
		add	x,y
l9:		mv	a,[(bp+!src_local)+1]
		cmp	a,0
		jrz	l9_1
		pushu	x
		mv	x,[(bp+!src_local)+2]
		call	!movobj			;Back to 'mv x,imm20'
		popu	x
		mv	y,[(bp+!src_local)+5]
		add	x,y
		call	!objout3
		jr	l10		
l9_1:		mv	(bp+!src_work1),x
		cmp	(bp+!src_work1+2),0
		jrnz	l9_2
		mv	ba,x
		pushu	ba
		cmp	(bp+!src_work1+1),0
		jrnz	l9_3
		mv	a,$08			;char range offset
		call	!objout1
		popu	ba
		call	!objout1
		mv	a,$40
		jr	l9_4
l9_3:		mv	a,$0a			;int range offset
		call	!objout1
		popu	ba
		call	!objout2
		mv	a,$42
		jr	l9_4
l9_2:		mv	a,$0d			;Write 'mv y,imm20'
		call	!objout1
		call	!objout3
		mv	a,$45			;Write 'add x,y'
l9_4:		call	!make_add
		jr	l10
l8:		call	!eval
		cmp	a,4
		jrnz	l11
		mv	a,[(bp+!src_local)]	;Pointer offset
		cmp	a,$10
		jrnz	l12
		mv	a,$3d			;Write 'popu y'
		call	!objout1
		mv	a,$45			;Write 'add x,y'
		call	!make_add
		jr	l10
l12:		mv	ba,$54fd		;Write 'mv y,x'
		call	!objout2
		mv	a,$45
l14:		pushu	a
		mv	a,$3c			;Write 'popu x'
		call	!objout1
		mv	a,[(bp+!src_local)]
		sub	a,$e
		mv	il,a
		popu	a
l13:		call	!make_add		;Write 'add x,ba' or 'add x,a'
		dec	il
		dec	il
		jrnz	l13
l10:		mv	a,(bp+!src_sym)
		cmp	a,']'
		jpnz	!err3
		call	!getsym
l7:		mv	a,[(bp+!src_local)]
		mv	y,8			;Release stack frame
		jp	!release_frame
;
l11:		add	a,$40
		jr	l14
		endl
;
exp5:		local
		mv	a,(bp+!src_sym)
		cmp	a,0
		jrnz	l2
l9:		mv	a,$ff			;constant value
		jp	exit
l2:		cmp	a,'"'
		jrnz	l3
		mvp	[--u],(bp+!obj_adr)	;String
		call	!objout2		;Write dummy of 'jp imm16'
		mv	il,1
		mv	a,(bp+!src_char)
l5:		cmp	a,'"'
		jrz	l4
		pushu	il
		call	change
		call	!objout1
		call	!getch
		popu	il
		inc	il
		jr	l5
l4:		mv	a,0			;Write terminater
		call	!objout1
		pushu	il
		call	!getch
		popu	a
		mv	b,a
		popu	x
		mvp	[--u],(bp+!obj_adr)
		call	!movobj
		mv	a,$12			;Write 'jr imm8'
		call	!objout2
		mv	y,(bp+!obj_adr)
		popu	x
		call	!movobj
		mv	a,$0c			;Write 'mv x,imm20'
		call	!objout1
		mv	x,y
		call	!objout3
		mv	a,4			;be handled as PTR
		jr	exit
l3:		cmp	a,''''
		jrnz	l20
		mv	a,(bp+!src_char)
		mv	il,0
l7:		cmp	a,''''
		jrz	l8
		call	change
		pushu	a
		call	!getch
		popu	il
		jr	l7
l8:		pushu	il
		call	!getch
		popu	il
		mv	x,il
		jr	l9
l6:		cmp	a,$1f
		jpnz	!v_acc
		mv	ba,$20
		call	!getadd
		jrc	function
		mv	ba,$100
		call	!getadd
		jpnc	!v_acc
		mv	a,$ff
		jr	exit
;
function:	local
		pushu	a			;Save func type
		pushu	x			;Save entry address
		test	a,$40
		pushs	f
		jrz	l1
		mv	ba,$37b6		;Write 'mv [--s],u'
		call	!objout2
l1:		call	!getsym
		cmp	(bp+!src_sym),'('
		jrnz	l2
l6:		call	!getsym
		call	!exp
		call	!eval
		cmp	a,4
		jrnc	l3
		pushu	a
		mv	ba,$0009		;Write 'mv il,0'
		call	!objout2
		popu	a
		cmp	a,0
		mv	ba,$282b		;Write 'pushu i;pushu a'
		jrz	l4
		mv	ba,$2a29		;Write 'pushu il;pushu ba'
l4:		call	!objout2
		jr	l5
l3:		mv	a,$2c			;Write 'pushu x'
		call	!objout1
l5:		cmp	(bp+!src_sym),','
		jrz	l6
		cmp	(bp+!src_sym),')'
		jpnz	!err11			;')' expected
		call	!getsym
l2:		pops	f
		jrz	l7
		mv	ba,$2794		;Write 'mv x,[s++]'
		call	!objout2
l7:		mv	a,$04			;Write 'call imm16'
		call	!objout1
		popu	x
		mv	ba,x
		call	!objout2
		popu	a
		and	a,7
		ret
		endl
;
l20:		cmp	a,'('
		jrnz	l6			;'(' expected
		call	!getsym			;'( [expression] )'
		call	!exp
		cmp	a,$ff
		jrz	skip_eval
		call	!eval
skip_eval:	cmp	(bp+!src_sym),')'
		jpnz	!err11			;')' expected
exit:		pushu	a
		pushu	x
		call	!getsym
		popu	x
		popu	a
		ret
change:		cmp	a,'^'
		jrnz	l7_
		call	!getch
		cmp	a,'?'
		jrc	l7_
		cmp	a,'Z'+1
		jrnc	l7_
		sub	a,$40
		and	a,$7f
l7_:		ret
		endl
;
exp4:		local
		mv	a,(bp+!src_sym)
		cmp	a,'+'
		jrnz	l0
		call	!getsym			;'+' routine (No code will be generated)
		jr	!exp4
l0:		cmp	a,'-'
		jrnz	l2
		call	!getsym			;'-' routine
		call	!exp4
l8:		cmp	a,$10
		jrnc	l6
		pushu	a
		pushu	a
		mv	a,$04
		call	!objout1
		popu	a
		cmp	a,2
		jrnc	l3
		mv	ba,!m_char		;Write 'call m_char'
		jr	l4
l3:		jrnz	l5		
		mv	ba,!m_int		;Write 'call m_int'
		jr	l4
l5:		mv	ba,!m_pnt		;Write 'call m_pnt'
l4:		call	!objout2
		popu	a
		ret
l6:		cmp	a,$ff
		jrnz	l7
		jp	!m_pnt			;Constant value
l7:		call	!eval
		jr	l8
l2:		cmp	a,'~'
		jrnz	l9
		call	!getsym			;'~' routine
		call	!exp4
l14:		cmp	a,$10
		jrnc	l10
		pushu	a
l11:		mv	b,a
		mv	a,$6c			;Write 'inc r'
		call	!objout2
		popu	a
		jr	l8			;continue to '-' routine
l10:		cmp	a,$ff
		jrnz	l13
		inc	x			;Constant value
		jr	l8
l13:		call	!eval
		jr	l14
l9:		cmp	a,'!'
		jrnz	l30
		call	!getsym			;'!' routine
		call	!exp4
		cmp	a,$20
		jrnc	l16
		call	!eval
		pushu	a
		pushu	a
		mv	a,$04
		call	!objout1
		popu	a
l17:		cmp	a,2
		jrnc	l18
		mv	ba,!n_char		;Write 'call n_char'
		jr	l19
l18:		jrnz	l20
		mv	ba,!n_int		;Write 'call n_int'
		jr	l19
l20:		mv	ba,!n_pnt		;Write 'call n_pnt'
l19:		call	!objout2
		popu	a
		ret
l16:		cmp	a,$ff
		jrnz	l21
		jp	!n_pnt
l21:		xor	a,1
		ret
l30:		cmp	a,$10
		jrnz	l40
		call	!getsym			;Cast to char
		call	!exp4
		mv	b,a
		mv	a,0
l31:		ex	a,b
		jp	!cast
l40:		cmp	a,$11
		jrnz	l50
		call	!getsym			;Cast to int
		call	!exp4
		mv	b,a
		mv	a,2
		jr	l31
l50:		cmp	a,$12
		jrnz	l60
		call	!getsym			;Cast to pnt
		call	!exp4
		mv	b,a
		mv	a,4
		jr	l31
l60:		cmp	a,'&'
		jpnz	!exp5
		call	!getsym
		call	!v_acc
		cmp	a,$10
		jpc	!err9
		cmp	a,$15
		jpnc	!err9
		mv	a,4
		ret
		endl
;
make_add:	local
		pushu	il
		pushu	ba
		mv	b,a
		mv	il,$46
		cmp	a,$20
		jrc	l1
		mv	il,$44
		cmp	a,$40
		jrc	l1
		mv	il,$45
l1:		mv	a,0
		add	ba,il
		call	!objout2
		popu	ba
		popu	il
		ret
		endl
;
make_sub:	local
		pushu	il
		pushu	ba
		mv	b,a
		mv	il,$4e
		cmp	a,$20
		jrc	l1
		mv	il,$4c
		cmp	a,$40
		jrc	l1
		mv	il,$4d
l1:		mv	a,0
		add	ba,il
		call	!objout2
		popu	ba
		popu	il
		ret
		endl
;
cast:		local
		cmp	a,$10
		jrnc	cast2
		cmp	a,2
		mv	a,b
		jrnc	l2
		cmp	a,2
		jrc	char			;char to char
		jrnz	c_to_p
		call	!make_cast		;char to int
		jr	int
c_to_p:		call	!make_cast
		mv	ba,$40fd		;char to pnt
		call	!objout2
		jr	pnt
char:		mv	a,0
		ret
;
l2:		jrnz	l3
		cmp	a,2
		jrc	char			;int to char
		jrz	int			;int to int
		mv	ba,$42fd		;int to pnt
		call	!objout2
		jr	pnt
int:		mv	a,2
		ret
;
l3:		cmp	a,2			
		jrz	p_to_i			;pnt to int
		jrnc	pnt			;pnt to pnt
		mv	ba,$04fd		;pnt to char
		call	!objout2
		jr	char
p_to_i:		mv	ba,$24fd
		call	!objout2
		jr	int
pnt:		mv	a,4
		ret
cast2:		cmp	a,$18
		jrnc	exit
		cmp	a,$12
		mv	a,b
		jrnc	cast3
		cmp	a,2
		mv	a,$10
		jrc	exit			;@ to char (No effect)
		mv	a,$18
		jrz	exit			;@ to int
		mv	a,$19
		jr	exit			;@ to pnt
cast3:		jrnz	cast4
		cmp	a,2
		mv	a,$12
		jrz	exit			;* to int (No effect)
		mv	a,$1a
		jrc	exit			;* to char
		mv	a,$1b
		jr	exit			;* to pnt
cast4:		cmp	a,2
		mv	a,$1c
		jrc	exit			;^ to char
		mv	a,$1d
		jrz	exit			;^ to int
		mv	a,$14			;^ to pnt (No effect)
exit:		ret
		endl
;
make_cast:	local
		pushu	ba
		mv	ba,$0875		;Write 'mv b,a;mv a,0;ex a,b'
		call	!objout2
		mv	ba,$dd00
		call	!objout2
		popu	ba
		ret
		endl
;
make_opr:	local
		mv	a,[(bp+!src_local)+1]
		cmp	a,$ff
		jrz	l1
		mv	a,[(bp+!src_local)+5]
		cmp	a,$ff
		jrc	l1
		call	!delobj			;Erase 'push r'
l1:		mv	a,[(bp+!src_local)]
		cmp	a,'*'
		jpnz	op_div
op_mul:		local
		mv	a,[(bp+!src_local)+1]
		cmp	a,$ff
		jrz	l1
		mv	a,[(bp+!src_local)+5]
		cmp	a,$ff
		jrz	l2
set_work:	call	..!make_clr_work	;Write 'call clear_work'
		mv	a,[(bp+!src_local)+5]	;Write 'mv (work2),r'
		pushu	a
		add	a,$a0
		mv	b,a
		mv	a,!src_work2
		ex	a,b
		call	!objout2
		mv	a,[(bp+!src_local)+1]	;Write 'mv (work1),[u++]'
		pushu	a
		rc
		shr	a
		add	a,$e0
		mv	b,a
		mv	a,$26
		ex	a,b
		call	!objout2
		mv	a,!src_work1
		call	!objout1
		mv	a,$04
		call	!objout1
		popu	a
		mv	(bp+!src_work1),[u++]
		or	(bp+!src_work1),a
		test	(bp+!src_work1),7
		mv	ba,[(bp+!src_local)+9]
		mv	il,0
		jrz	set_work1
		mv	il,2
		test	(bp+!src_work1),4
		jrz	set_work1
		mv	ba,[(bp+!src_local)+12]
		mv	il,4
set_work1:	call	!objout2
		mv	a,il
		ret
l1:		mv	a,[(bp+!src_local)+5]
		cmp	a,$ff
		jrz	l3			;Both A and B are constant
		mv	x,[(bp+!src_local)+2]
		mv	[(bp+!src_local)+6],x
		mv	[(bp+!src_local)+1],a
l2:		mv	ba,[(bp+!src_local)+7]	;A is coded,B is constant
		inc	ba
		dec	ba
		jrnz	l4			;constant >= 256
		mv	a,[(bp+!src_local)+6]
		cmp	a,2
		jrc	l4			;constant <= 1
		mv	il,[(bp+!src_local)+1]
l6:		rc
		shr	a
		jrc	l5
		pushu	a
		call	set_rr
		call	!make_add
		popu	a
		jr	l6
l5:		cmp	a,0
		jrz	l7
		pushu	a			;Write 'mv r1,r2'
		call	set_rr
		add	a,$10
		mv	b,a
		mv	a,$fd
		call	!objout2
		popu	a
l9:		pushu	a			;Write 'add r,r'
		call	set_rr
		add	a,$11
		call	!make_add
		popu	a
		rc
		shr	a
		jrnc	l8
		pushu	a			;Write 'add r1,r2'
		call	set_rr
		add	a,1
		call	!make_add
		popu	a
l8:		cmp	a,0
		jrnz	l9
l7:		mv	a,il
		ret
l4:		mv	a,[(bp+!src_local)+1]	;A is coded , B is constant
		pushu	a
		pushu	a
		pushu	a
		call	..!make_clr_work
		cmp	a,2
		jrnc	l4__3
		mv	ba,$cc+!src_work2*256
		call	!objout2
		mv	a,[(bp+!src_local)+6]
		call	!objout1
		jr	l4_2
l4__3:		jrz	l4_1
		mv	ba,$dc+!src_work2*256
		call	!objout2
		mv	x,[(bp+!src_local)+6]
		call	!objout3
		jr	l4_2
l4_1:		mv	ba,$cd+!src_work2*256
		call	!objout2
		mv	ba,[(bp+!src_local)+6]
		call	!objout2
l4_2:		popu	a
		add	a,$a0
		mv	b,a
		mv	a,!src_work1
		ex	a,b
		call	!objout2
		mv	a,$04
		call	!objout1
		popu	a
		cmp	a,4
		mv	ba,[(bp+!src_local)+9]
		jrnz	l4_3
		mv	ba,[(bp+!src_local)+12]
l4_3:		call	!objout2
		popu	a
		ret
l3:		mvp	(bp+!src_work1),[(bp+!src_local)+2]
		mvp	(bp+!src_work2),[(bp+!src_local)+6]
		mv	x,[(bp+!src_local)+12]
		call	call_opr
		mv	a,$ff
		ret
;
call_opr:	jp	x
;
set_rr:		mv	a,il
		mv	(bp+!src_work1),a
		swap	a
		add	(bp+!src_work1),a
		mv	a,(bp+!src_work1)
		ret
		endl
;
make_clr_work:	local
		pushu	ba
		mv	a,$04			;Write 'call clear_work'
		call	!objout1
		mv	ba,!clear_work
		call	!objout2
		popu	ba
		ret
		endl
;
op_div:		cmp	a,'/'
		jrz	op_ops
		cmp	a,'%'
		jrz	op_ops
		cmp	a,'&'
		jrz	op_ops
		cmp	a,'#'
		jrz	op_ops
		cmp	a,'|'
		jrz	op_ops
		cmp	a,$0e			;shl
		jrz	op_ops
		cmp	a,$0d			;shr
		jrnz	op_plus
op_ops:		local
		mv	a,[(bp+!src_local)+1]
		cmp	a,$ff
		jrz	l1
		mv	a,[(bp+!src_local)+5]
		cmp	a,$ff
		jpnz	..!op_mul!set_work	;Both A and B are coded
		jr	..!op_mul!l4		;A is coded,B is constant
l1:		mv	a,[(bp+!src_local)+5]
		cmp	a,$ff
		jrz	..!op_mul!l3		;Both A and B are constant
		pushu	a
		pushu	a
		pushu	a
		call	..!make_clr_work	;Write 'call clear_work'
		cmp	a,2			;A is constant,B is coded
		jrnc	l4__3
		mv	ba,$cc+!src_work1*256
		call	!objout2
		mv	a,[(bp+!src_local)+2]
		call	!objout1
		jr	l4_2
l4__3:		jrz	l4_1
		mv	ba,$dc+!src_work1*256
		call	!objout2
		mv	x,[(bp+!src_local)+2]
		call	!objout3
		jr	l4_2
l4_1:		mv	ba,$cd+!src_work1*256
		call	!objout2
		mv	ba,[(bp+!src_local)+2]
		call	!objout2
l4_2:		popu	a
		add	a,$a0
		mv	b,a
		mv	a,!src_work2
		ex	a,b
		call	!objout2
		mv	a,$04
		call	!objout1
		popu	a
		cmp	a,4
		mv	ba,[(bp+!src_local)+9]
		jrnz	l4_3
		mv	ba,[(bp+!src_local)+12]
l4_3:		call	!objout2
		popu	a
		ret
		endl
op_plus:	local
		mv	(bp+!src_work1+1),[(bp+!src_local)+15]
		mv	(bp+!src_work2),[(bp+!src_local)+5]
		cmp	a,'+'
		mv	a,[(bp+!src_local)+1]
		mv	(bp+!src_work1),a
		jrz	l0
		test	(bp+!src_work1+1),1
		jrz	l0
		mv	(bp+!src_work2+1),(bp+!src_work2)
		or	(bp+!src_work2+1),a
		inc	(bp+!src_work2+1)
		jrnz	l0
		mv	il,[(bp+!src_local)+5]
		mv	[(bp+!src_local)+5],a
		mv	[(bp+!src_local)+1],il
		mv	x,[(bp+!src_local)+2]
		mv	y,[(bp+!src_local)+6]
		mv	[(bp+!src_local)+2],y
		mv	[(bp+!src_local)+6],x
		mv	a,il
		ex	(bp+!src_work1),(bp+!src_work2)
l0:		cmp	a,$ff
		jrz	l6
		cmp	(bp+!src_work2),$ff
		jrz	l9
		cmp	(bp+!src_work2),2
		mv	a,$54
		jrnc	l0_1
		mv	a,$10
		cmp	(bp+!src_work1),2
		jrc	l0_3
		call	!make_cast
		mv	a,$32
		cmp	(bp+!src_work1),2
		jrz	l0_3
		mv	a,$52
		jr	l0_3
l0_1:		jrnz	l0_3
		mv	a,$32			;B is int
		cmp	(bp+!src_work1),4
		jrnz	l0_3
		mv	a,$52
l0_3:		mv	b,a
		mv	a,$fd
		call	!objout2
		mv	a,b
		swap	a
		and	a,6
		mv	(bp+!src_work2),a
		mv	a,(bp+!src_work1)
		add	a,$38			;Write 'popu r'
		call	!objout1
		cmp	(bp+!src_work1),2
		jrnc	l0_4
		cmp	(bp+!src_work2),2
		jrc	l1
		call	!make_cast
		cmp	(bp+!src_work2),4
		mv	(bp+!src_work1),2
		jrnz	l1
l0_5:		mv	ba,$42fd
		call	!objout2
		mv	(bp+!src_work1),4
		jr	l1
l0_4:		jrnz	l1
		cmp	(bp+!src_work2),4
		jrz	l0_5
l1:		cmp	(bp+!src_work1),2
		jrnz	skip_modify
		call	modify_int		;If both are INT, then modify
skip_modify:	mv	a,(bp+!src_work1)
		swap	a
		add	a,(bp+!src_work1)
		inc	a
		test	(bp+!src_work1+1),1
		jrz	l1_1
		swap	a
l1_1:		mv	b,a
		mv	a,[(bp+!src_local)]
		cmp	a,'+'
		mv	a,b
		jrnz	l4
		call	!make_add
		jr	l5
l4:		call	!make_sub
l5:		mv	a,(bp+!src_work1)
		ret
l6:		cmp	(bp+!src_work2),$ff
		jrz	l7
		mv	a,[(bp+!src_local)]	;A is constant,B is coded
		cmp	a,'-'
		jrz	l8
		ex	(bp+!src_work1),(bp+!src_work2)
		mv	x,[(bp+!src_local)+2]
		mv	[(bp+!src_local)+6],x		
l9:		mv	x,[(bp+!src_local)+6]
		mv	a,[(bp+!src_local)]
		cmp	a,'+'
		pushs	f
		cmp	(bp+!src_work1),2
		jrnc	l10		
		mv	a,x			;Write 'add a,imm8' or 'sub a,imm8'
		mv	b,a
		mv	a,$40
		jr	l10_2
l10:		jrnz	l11
		dec	x
		jrz	l10_3
l10_6:		inc	x
		mv	a,$b			;Write 'mv i,imm16'
		call	!objout1
		mv	ba,x
		call	!objout2
		call	modify_int
		mv	ba,$2344		;Write 'add ba,i' or 'sub ba,i'
l10_2:		pops	f
		jrz	l10_1
		add	a,8
l10_1:		call	!objout2
		mv	a,(bp+!src_work1)
		ret
l10_3:		test	(bp+!src_work1+1),2
		jrnz	l10_6
		mv	ba,$026c		;Write 'inc ba' or 'dec ba'
l10_5:		pops	f
		jrz	l10_1
		add	a,$10
l10_4:		jr	l10_1
l11:		dec	x
		jrz	l11_1
l11_2:		inc	x
		mv	a,$d			;Write 'mv y,imm20'
		call	!objout1
		call	!objout3
		mv	ba,$4545
		jr	l10_2
l11_1:		test	(bp+!src_work1+1),2
		jrnz	l11_2
		mv	ba,$046c		;Write 'inc x' or 'dec x'
		jr	l10_5
l8:		mv	a,(bp+!src_work2)	;A is constant,B is coded,sub
		mv	il,a			;Write 'mv r,r'
		swap	a
		add	a,il
		add	a,$10
		mv	b,a
		mv	a,$fd
		call	!objout2
		cmp	(bp+!src_work2),2
		jrnc	l8_1
		mv	a,[(bp+!src_local)+2]	;Write 'mv a,imm8'
		mv	b,a
		mv	a,$08
		call	!objout2
		mv	ba,$014e
		jr	l8_2
l8_1:		jrnz	l8_3
		mv	a,$0a			;Write 'mv ba,imm16'
		call	!objout1
		mv	ba,[(bp+!src_local)+2]
		call	!objout2
		call	modify_int
		mv	ba,$234c
l8_2:		call	!objout2
		mv	a,(bp+!src_work2)
		ret
l8_3:		mv	a,$0c			;Write 'mv x,imm20'
		call	!objout1
		mv	x,[(bp+!src_local)+2]
		call	!objout3
		mv	ba,$454d
		jr	l8_2
l7:		mv	a,[(bp+!src_local)]	;Both A and B are constants
		mv	x,[(bp+!src_local)+2]
		mv	y,[(bp+!src_local)+6]
		cmp	a,'+'
		jrnz	l7_1
		add	x,y
		jr	l7_2
l7_1:		sub	x,y
l7_2:		mv	a,$ff
_return:	ret
modify_int:	test	(bp+!src_work1+1),2
		jrz	_return
		mv	a,$04
		call	!objout1
		mv	ba,!modify_int
		jp	!objout2
		endl
;
		endl
;
exp3:		local
		mv	y,16			;Make stack frame
		call	!make_frame
;
		call	!exp4
l5:		mv	[(bp+!src_local)+1],a
		mv	[(bp+!src_local)+2],x
		mv	a,(bp+!src_sym)
		mv	[(bp+!src_local)],a
		mv	x,!mul16
		mv	y,!mul20
		cmp	a,'*'
		jrz	l2
		mv	x,!div16
		mv	y,!div20
		cmp	a,'/'
		jrz	l2
		mv	x,!mod16
		mv	y,!mod20
		cmp	a,'%'
		jrz	l2
		mv	x,!and16
		mv	y,!and20
		cmp	a,'&'
		jrz	l2
		mv	a,[(bp+!src_local)+1]
		mv	x,[(bp+!src_local)+2]
		jr	exit
l2:		mv	[(bp+!src_local)+9],x
		mv	[(bp+!src_local)+12],y
		mv	a,[(bp+!src_local)+1]
		cmp	a,$ff
		jrz	l3
		call	!eval
		mv	[(bp+!src_local)+1],a
		add	a,$28
		call	!objout1
l3:		call	!getsym
		call	!exp4
		cmp	a,$ff
		jrz	l4
		call	!eval
l4:		mv	[(bp+!src_local)+5],a
		mv	[(bp+!src_local)+6],x
		mv	[(bp+!src_local)+15],(bp+!src_zero)
		call	!make_opr
		jr	l5
exit:		mv	y,16			;Release stack frame
		jp	!release_frame
		endl
;
exp2:		local
		mv	y,16			;Make stack frame
		call	!make_frame
;
		call	!exp3
l5:		mv	[(bp+!src_local)+1],a
		mv	[(bp+!src_local)+2],x
		mv	a,(bp+!src_sym)
		mv	[(bp+!src_local)],a
		cmp	a,'+'
		jrz	l2
		cmp	a,'-'
		jrz	l2
		mv	x,!or16
		mv	y,!or20
		cmp	a,'|'
		jrz	l2
		mv	x,!xor16
		mv	y,!xor20
		cmp	a,'#'
		jrz	l2
		mv	x,!shl16
		mv	y,!shl20
		cmp	a,$0e
		jrz	l2
		mv	x,!shr16
		mv	y,!shr20
		cmp	a,$0d
		jrz	l2
		mv	a,[(bp+!src_local)+1]
		mv	x,[(bp+!src_local)+2]
		jr	exit
l2:		mv	a,[(bp+!src_local)+1]
		mv	[(bp+!src_local)+9],x
		mv	[(bp+!src_local)+12],y
		cmp	a,$ff
		jrz	l3
		call	!eval
		mv	[(bp+!src_local)+1],a
		add	a,$28
		call	!objout1
l3:		call	!getsym
		call	!exp3
		cmp	a,$ff
		jrz	l4
		call	!eval
l4:		mv	[(bp+!src_local)+5],a
		mv	[(bp+!src_local)+6],x
		mv	[(bp+!src_local)+15],(bp+!src_zero)
		call	!make_opr
		jr	l5
exit:		mv	y,16			;Release stack frame
		jp	!release_frame
		endl
;
exp1:		local
		mv	y,17			;Make stack frame
		call	!make_frame
;
		call	!exp2
l5:		mv	[(bp+!src_local)+1],a
		mv	[(bp+!src_local)+2],x
		mv	a,(bp+!src_sym)
		mv	[(bp+!src_local)],a
		mv	il,0
		cmp	a,1			;A != B
		jrz	l2
		mv	il,4
		cmp	a,4			;A == B
		jrz	l2
		mv	il,15
		cmp	a,'>'			;A > B
		jrz	l2
		mv	il,14
		cmp	a,'<'			;A < B
		jrz	l2
		mv	il,10
		cmp	a,3			;A >= B
		jrz	l2
		mv	il,11
		cmp	a,2			;A <= B
		jrz	l2
		mv	a,[(bp+!src_local)+1]
		mv	x,[(bp+!src_local)+2]
		jr	exit
l2:		mv	a,'-'
		mv	[(bp+!src_local)],a
		mv	a,il
		mv	[(bp+!src_local)+16],a
		and	a,3
		mv	[(bp+!src_local)+15],a
		mv	a,[(bp+!src_local)+1]
		cmp	a,$ff
		jrz	l3
		call	!eval
		mv	[(bp+!src_local)+1],a
		add	a,$28
		call	!objout1
l3:		call	!getsym
		call	!exp2
		cmp	a,$ff
		jrz	l4
		call	!eval
l4:		mv	[(bp+!src_local)+5],a
		mv	[(bp+!src_local)+6],x
l4_1:		call	!make_opr
		pushs	f
		cmp	a,$ff
		mv	a,[(bp+!src_local)+16]
		jrz	const_relative
		pops	f
		rc
		shr	a
		rc
		shr	a
		add	a,$20
		jr	l5
exit:		mv	y,17			;Release stack frame
		jp	!release_frame
const_relative:	rc
		shr	a
		rc
		shr	a
		rol	a
		add	a,$18
		mv	[jump],a
		mv	x,0
		pops	f
jump:		jr	jump1
		mv	x,1
jump1:		mv	a,$ff
		jr	l5		
		endl
;
exp:		local
		mv	y,16			;Make stack frame
		call	!make_frame
;
		call	!exp1
l5:		mv	[(bp+!src_local)+1],a
		mv	[(bp+!src_local)+2],x
		mv	a,(bp+!src_sym)
		mv	[(bp+!src_local)],a
		mv	il,'='
		cmp	a,'='			;A = B
		jrz	l2
		mv	il,'+'
		cmp	a,5			;A += B
		jrz	l2
		mv	il,'-'
		cmp	a,6			;A -= B
		jrz	l2
		mv	il,'*'
		mv	x,!mul16
		mv	y,!mul20
		cmp	a,7			;A *= B
		jrz	l2
		mv	il,'/'
		mv	x,!div16
		mv	y,!div20
		cmp	a,8			;A /= B
		jrz	l2
		mv	il,'%'
		mv	x,!mod16
		mv	y,!mod20
		cmp	a,9			;A %= B
		jrz	l2
		mv	il,'&'
		mv	x,!and16
		mv	y,!and20
		cmp	a,10			;A &= B
		jrz	l2
		mv	il,'|'
		mv	x,!or16
		mv	y,!or20
		cmp	a,11			;A |= B
		jrz	l2
		mv	il,'#'
		mv	x,!xor16
		mv	y,!xor20
		cmp	a,12			;A #= B
		jrz	l2
		mv	il,$0e
		mv	x,!shl16
		mv	y,!shl20
		cmp	a,$ff			;A <<= B
		jrz	l2
		mv	il,$0d
		mv	x,!shr16
		mv	y,!shr20
		cmp	a,$0f			;A >>= B
		jrz	l2
		mv	a,[(bp+!src_local)+1]
		mv	x,[(bp+!src_local)+2]
		jr	exit
l2:		mv	[(bp+!src_local)],il
		pushu	il
		mv	[(bp+!src_local)+9],x
		mv	[(bp+!src_local)+12],y
		mv	a,[(bp+!src_local)+1]
		mv	il,a
		cmp	a,$10
		jpc	!err9			;Can't equ
		cmp	a,$1e
		jpnc	!err9
		mv	a,$2c			;Write 'pushu x'
		call	!objout1
		popu	a
		cmp	a,'='
		jrnz	equ_with_opr
		mv	a,il
		mv	il,2
		cmp	a,$18
		jrc	l2_0
		jrz	l2_1
		cmp	a,$1c
		jrz	l2_1
		mv	il,4
		cmp	a,$19
		jrz	l2_1
		cmp	a,$1b
		jrz	l2_1
		mv	il,0
l2_1:		mv	a,il
l2_0:		and	a,7
		mv	[(bp+!src_local)+1],a
		call	!getsym			;pure assignment
		call	!exp
		cmp	a,$ff
		jrz	l2_2
		call	!eval
		jr	l2_3
l2_2:		mv	a,[(bp+!src_local)+1]
		pushu	a
		add	a,8
		call	!objout1
		cmp	a,$0a
		jrnc	l2_5
		mv	a,x
		call	!objout1
		jr	l2_4
l2_5:		jrnz	l2_6
		mv	ba,x
		call	!objout2
		jr	l2_4
l2_6:		call	!objout3		
l2_4:		popu	a
l2_3:		jr	exit1
;
equ_with_opr:	mv	a,[(bp+!src_local)+1]
		call	!eval
		mv	[(bp+!src_local)+1],a
		add	a,$28			;Write 'pushu r'
		call	!objout1
		call	!getsym
		call	!exp
		cmp	a,$ff
		jrz	lx
		call	!eval
lx:		mv	[(bp+!src_local)+5],a
		mv	[(bp+!src_local)+6],x
		mv	[(bp+!src_local)+15],(bp+!src_zero)
		call	!make_opr
exit1:		mv	b,a
		mv	a,[(bp+!src_local)+1]
		ex	a,b
		call	!cast
		pushu	a
		mv	a,$3d			;Write 'popu y'
		call	!objout1
		popu	a
		pushu	a
		add	a,$b0			;Write	'mv [y],r'
		mv	b,a
		mv	a,5
		ex	a,b
		call	!objout2
		popu	a
;		
exit:		mv	y,16			;Release stack frame
		jp	!release_frame
		endl
;
cond_exp:	local
		cmp	(bp+!src_sym),'('
		jpnz	!err10			;'(' expected
		call	!getsym
		call	!exp
		cmp	(bp+!src_sym),')'
		jpnz	!err11			;')' expected
		pushu	a
		pushu	x
		call	!getsym
		popu	x
		popu	a
		cmp	a,$ff
		jrnz	l1
		cmpp	(bp+!src_zero),x
		mv	a,0			;Always TRUE
		jrnz	l2
		mv	a,1			;Always FALSE
l2:		ret
l1:		cmp	a,$20
		jrnc	exit
		call	!eval
		cmp	a,2
		jrnc	l3
		mv	ba,$0060		;Write 'cmp a,0'
		call	!objout2
		jr	l4
l3:		mv	ba,$02d6
		jrz	l5
		mv	ba,$04d7
l5:		call	!objout2
		mv	a,!src_zero
		call	!objout1
l4:		mv	a,$20
exit:		ret
		endl
;
make_release:	local
		cmp	(bp+!release_size+2),0	;Write suitable object for release_frame!
		jrnz	l7_pnt
		cmp	(bp+!release_size+1),0
		jrnz	l7_int
		mv	a,(bp+!release_size)	;Char range release_frame
		mv	b,a
		mv	a,$09
		jr	l7_rel_int
l7_int:		mv	a,$0b			;Int range release_frame
		call	!objout1
		mv	ba,(bp+!release_size)
l7_rel_int:	call	!objout2
		mv	a,$02
		call	!objout1
		mv	ba,!release_int
		jr	l7_jump
l7_pnt:		mv	a,$0d			;Write 'mv y,imm20'
		call	!objout1
		mv	x,(bp+!release_size)
		call	!objout3
		mv	a,$02			;Write 'jp release_frame'
		call	!objout1
		mv	ba,!release_frame
l7_jump:	jp	!objout2
		endl
;
statement:	local
		mv	y,9			;Make stack frame
		call	!make_frame
;
		call	!user_break
		cmp	(bp+!prcs_head),0
		jrnz	statement2
		mv	a,$fe
		call	!objout1		;Write 'IR'
statement2:	mv	a,(bp+!src_sym)
		cmp	a,'{'
		jrnz	block2
;
block:		local
		call	!getsym			; { [statement ;]* }
		cmp	(bp+!src_sym),'}'
		jrz	l1
		call	!statement
		cmp	(bp+!src_sym),';'
		jrz	..!block
		jp	!err6
l1:		call	!getsym
		jp	..!exit
		endl
;
block2:		cmp	a,'['
		jrnz	if
		inc	(bp+!prcs_head)
_block2:	local
		call	!getsym			; [ [statement ;]* ]
		cmp	(bp+!src_sym),']'
		jrz	l1
		call	!statement
		cmp	(bp+!src_sym),';'
		jrz	..!_block2
		jp	!err6
l1:		call	!getsym
		dec	(bp+!prcs_head)
		jp	..!exit
		endl
;
if:		cmp	a,$16
		jrnz	while
_if:		local
		call	!getsym			;if cond_exp ...
		call	!cond_exp
		cmp	a,0
		jrnz	l1
		mv	a,$0a+$0c
		jr	l2
l1:		cmp	a,1
		jrnz	l2
		mv	a,$02+$0c
l2:		sub	a,$c
		call	!objout1		;Write 'JPcc' on FALSE
		mvp	[(bp+!src_local)],(bp+!obj_adr)
		call	!objout2
		call	!statement
		cmp	(bp+!src_sym),$17
		jrz	l3
		mv	y,(bp+!obj_adr)		;No 'ELSE'
		mv	x,[(bp+!src_local)]
		call	!movobj
		mv	ba,y
		call	!objout2		;Write Jump address on FALSE
		mv	x,y
		call	!movobj
		jp	..!exit
l3:		mv	a,$02			;With 'ELSE'
		call	!objout1
		mvp	[(bp+!src_local)+3],(bp+!obj_adr)
		call	!objout2
		mv	y,(bp+!obj_adr)
		mv	x,[(bp+!src_local)]
		call	!movobj
		mv	ba,y
		call	!objout2		;Write Jump address on FALSE
		mv	x,y
		call	!movobj
		call	!getsym
		call	!statement
		mv	y,(bp+!obj_adr)
		mv	x,[(bp+!src_local)+3]
		call	!movobj
		mv	ba,y
		call	!objout2		;Write Jump address on TURE
		mv	x,y
		call	!movobj
		jp	..!exit
		endl
;
while:		cmp	a,$18
		jrnz	do
_while:		local
		mv	a,[!while_links]
		inc	a
		mv	[!while_links],a
		mvp	[(bp+!src_local)],(bp+!obj_adr)
		call	!getsym
		call	!cond_exp
		cmp	a,0
		jrnz	l1
		mv	a,$12
		jr	l2
l1:		cmp	a,1
		jrnz	l2_1
		mv	a,$08
		jr	l2
l2_1:		sub	a,$20
		xor	a,1
		add	a,a
		add	a,$18			;Make 'JR!cc +3'
l2:		mv	b,a
		mv	a,3
		ex	a,b
		call	!objout2
		mv	x,[!while_out]
		mv	[(bp+!src_local)+6],x
		mvp	[!while_out],(bp+!obj_adr)
		mv	a,$02
		call	!objout1
		mvp	[(bp+!src_local)+3],(bp+!obj_adr)
		call	!objout2		;Write 'JP' on LOOP OUT
		call	!statement
		call	..!length
		jrnc	l3
		mv	a,x
		mv	b,a
		mv	a,$13			;Write 'JR- imm8'
		call	!objout2
		jr	l4
l3:		mv	a,$02			;Write 'JP imm16'
		call	!objout1
		mv	ba,[(bp+!src_local)]
		call	!objout2
l4:		mv	y,(bp+!obj_adr)
		mv	x,[(bp+!src_local)+3]
		call	!movobj
		mv	ba,y
		call	!objout2
		mv	x,y
		call	!movobj
		mv	a,[!while_links]
		dec	a
		mv	[!while_links],a
		mv	x,[(bp+!src_local)+6]
		mv	[!while_out],x
		jr	..!exit
		endl
;
do:		cmp	a,$19
		jrnz	inline
_do:		local
		mvp	[(bp+!src_local)],(bp+!obj_adr)
		call	!getsym
		call	!statement
		cmp	(bp+!src_sym),$1a
		jpnz	!err3			;'UNTIL' expected
		call	!getsym
		call	!cond_exp
		pushu	a
		call	..!length
		mv	a,x
		mv	b,a
		popu	a
		jrnc	l1
		cmp	a,1
		jrc	..!exit
		jrnz	l2
		mv	a,($13-$19)/2+$20	;Write 'JR- imm8'
l2:		sub	a,$20
		rc
		shl	a
		add	a,$19
		call	!objout2
		jr	..!exit
l1:		cmp	a,1
		jrc	..!exit
		jrnz	l3
		mv	a,$02+$0c
l3:		sub	a,$0c
		call	!objout1		;Write 'JPcc' on FALSE
		mv	ba,y
		call	!objout2
		jr	..!exit
		endl
;
inline:		cmp	a,$13
		jrnz	return
_inline:	local
		call	!getsym
		cmp	(bp+!src_sym),'('
		jpnz	!err10			;'(' expected
l2:		call	!getsym
		call	!exp
		cmp	a,$ff
		jrnz	l1
		mv	a,x
		call	!objout1
l1:		cmp	(bp+!src_sym),','
		jrz	l2
		cmp	(bp+!src_sym),')'
		jpnz	!err11			;')' expected
		call	!getsym
		jr	..!exit
		endl
;
return:		cmp	a,$14
		jrnz	p_exit
;
_return:	local
		call	!getsym
		call	!exp
		call	!eval
		mv	b,a
		mv	a,(bp+!func_type)
		cmp	a,0
		jpz	!err3			;Can't use 'return' in main
		sub	a,$10
		shl	a
		ex	a,b
		call	!cast
		call	!make_release
		jr	..!exit
		endl
;
p_exit:		cmp	a,$1b
		jrnz	break
;
_p_exit:	local
		mv	a,$02
		call	!objout1
		mv	ba,!terminate
		call	!objout2
		call	!getsym
		jr	..!exit
		endl
;
break:		cmp	a,$1e
		jrnz	expression
;
_break:		local
		mv	a,[!while_links]
		cmp	a,0
		jpz	!err3			;Used BREAK out of WHILE
		mv	a,$02
		call	!objout1
		mv	ba,[!while_out]
		call	!objout2
		call	!getsym
		jr	..!exit
		endl
;
expression:	call	!exp
;
exit:		mv	y,9			;Release stack frame
		jp	!release_frame
;
length:		mv	x,(bp+!obj_adr)
		mv	y,[(bp+!src_local)]
		sub	x,y
		inc	x
		inc	x
		pushu	x
		mv	a,255
		sub	x,a
		popu	x
		ret
;
		endl
;
		include	main.s
		include	database.s
;
;
		end
