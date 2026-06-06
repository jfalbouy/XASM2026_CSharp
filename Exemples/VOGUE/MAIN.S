main:		mv	[!s_stack],s
		mv	[!u_stack],u
		call	!interrupt1
		mv	(bp+src_stat),0
		mv	(bp+prcs_head),0
		mvw	(bp+line1),(bp+src_zero)
		mvw	(bp+line2),(bp+line1)
		mv	x,table_end
		mv	a,$ff
		mv	[x],a
		mv	(bp+src_table),x
		mvp	(bp+obj_adr),obj_start
		mvp	(bp+obj_pnt),obj_start
		mv	y,symbuf+16
		pushu	y
		mv	y,start_symbol
		pushu	y
		call	strcpy		
		mv	x,!symbuf+22
		mv	[!symadr],x
		and	(bp+!src_symswitch),0
		and	[!while_links],0
		and	[!txtcount],0
		and	[!objcount],0
		call	flush_obj
;
option:		local
		popu	x
		pushu	x
l1:		mv	a,[x++]
		cmp	a,$0d
		jrz	exit
		cmp	a,'-'
		jrnz	l1
		mv	a,[x++]
		or	a,$20
l2_1:		cmp	a,'f'
		jrnz	l2
		or	(bp+!src_stat),8
		mvp	(bp+!obj_pnt),!getch
		jr	l2_2
l2:		cmp	a,'o'
		jrnz	l3
l2_2:		pushu	x
		mv	x,0
		pushu	x
		call	!fcreat
		inc ba
		jpz	!error3			;Can't open object
		dec	a
		mv	(bp+!obj_handle),a
		or	(bp+!src_stat),$10
		mvp	(bp+!obj_adr),!getch
		mv	x,(bp+!src_pnt)
		jr	l1
l3:		cmp	a,'s'
		jpnz	!error2			;Bad option
		pushu	x
		mv	x,1
		pushu	x
		call	!fopen
		inc	ba
		jpz	!error1			;Source not open
		dec	a
		mv	(bp+!src_handle),a
		or	(bp+!src_stat),1
		mv	x,(bp+!src_pnt)
		mvw	(bp+!line2),1
		jr	l1
exit:		endl
;
		dec	x
		popu	y
		pushu	x
		and	($fb),$7f
		mv	u,ctime_u_top
		or	($fb),$80
		test	(bp+!src_stat),1
		jrnz	l1_2
		mv	x,[basic_work_top]
		mv	a,$72
		add	x,a
		mv	y,symbuf
		mv	a,'S'
		mv	b,a
		mv	a,[x++]
		add	a,$31
		ex	a,b
		mv	[y++],ba
		mv	a,':'
		mv	[y++],a
		mv	il,4
copyname1:	mv	ba,[x++]
		mv	[y++],ba
		dec	il
		jrnz	copyname1
		mv	a,'.'
		mv	[y++],a
		mv	il,3
copyname2:	mv	a,[x++]
		mv	[y++],a
		dec	il
		jrnz	copyname2
		mv	a,0
		mv	[y],a
		mv	a,1
		mv	il,1
		mv	x,symbuf
		callf	fcntl
		jpc	error1			;Source not opened
;
		mv	(bp+src_handle),(cl)
		mv	il,$a
		mv	a,0
		callf	fcntl
		and	[dev_attr],0
		mv	a,b
		test	a,$20
		jrnz	l1_2			;Jump if CHAR-DEV.
		or	[dev_attr],1		
;
l1_2:		or	(bp+src_stat),1
		mv	il,8
		mv	(cl),(bp+src_handle)
		mv	a,$80
		callf	fcntl			;non-destructive char read
		cmp	a,$ff
		jrnz	l1_1
		and	(bp+src_stat),$fe
		mv	a,18
l2:		pushu	a
		call	_getch1
		popu	a
		dec	a
		jrnz	l2
		and	(bp+src_stat),$fd
;
		mv	ba,!user_break!entry
		mv	[!jump_to_obj+1],ba
;
l1_1:		test	(bp+src_stat),$08
		jrz	l__1
		mv	il,9			;Seek to next of Header+Runtime
		mv	(cl),(bp+obj_handle)
		mvp	(si),getch - start + 16
		mv	a,0
		callf	fcntl
l__1:		call	getch
		call	getsym
;
program_begin:	local
;
constant:	mv	a,(bp+!src_sym)
		cmp	a,$1d
		jrnz	define_var
_constant:	local
		call	!getsym
		cmp	(bp+!src_sym),$1f
		jpnz	!err9			;Identifier expected
		mv	ba,$100
		call	!getadd
		jpc	!err5			;Duplicate ID
		mv	a,0
		mv	(bp+!var_type),$10
		call	..!make_table
		call	!getsym
		call	!exp
		cmp	a,$ff
		jpnz	!err8			;constant number expected
		mv	(bp+!src_work1),x
		or	(bp+!src_work1+2),$10
		mvp	[(bp+!src_table)+9],(bp+!src_work1)
		cmp	(bp+!src_sym),';'
		jpnz	!err6			;';' expected
		call	!getsym
		jr	..!constant
		endl
;
define_var:	mv	a,(bp+!src_sym)
		cmp	a,$10
		jrc	define_proto
		cmp	a,$13
		jrnc	define_proto
;
_define_var:	local
		mv	(bp+!var_type),a
l8:		call	!getsym
		cmp	(bp+!src_sym),$1f
		jpnz	!err9			;var_id expected
		mv	ba,$108
		call	!getadd
		jpc	!err5			;Duplicate id
		mv	a,8
		call	..!make_table
		mvp	[y++],(bp+!obj_adr)	;Write address on table
		mvp	[--u],(bp+!obj_adr)
		call	!getsym
		cmp	(bp+!src_sym),'['
		jrnz	l2
		call	!getsym
		call	!exp
		cmp	a,$ff
		jpnz	!err8			;contant expected
		mvp	(bp+!src_work1),(bp+!var_size)
		mv	(bp+!src_work2),x
		call	!mul20
		mv	(bp+!var_size),x
		cmp	(bp+!src_sym),']'
		jpnz	!err3			;']' expected
		call	!getsym
l2:		cmp	(bp+!src_sym),'='
		jrnz	l3
		call	!getsym			;Initialive var
		cmp	(bp+!src_sym),'{'
		jpnz	!err3			;'{' expected
l7:		call	!getsym
		call	!exp
		cmp	a,$ff
		jpnz	!err8			;constant expected
		cmp	(bp+!var_type),$11
		jrnc	l4
		mv	a,x
		call	!objout1
		jr	l5
l4:		jrnz	l6
		mv	ba,x
		call	!objout2
		jr	l5
l6:		call	!objout3
l5:		cmp	(bp+!src_sym),','
		jrz	l7
		cmp	(bp+!src_sym),'}'
		jpnz	!err3			;'}' expected
		call	!getsym
l3:		popu	x
		mv	y,(bp+!var_size)
		add	x,y
		call	!movobj
		cmp	(bp+!src_sym),','
		jrz	l8
		cmp	(bp+!src_sym),';'
		jpnz	!err6			;';' expected
		call	!getsym
		jr	..!define_var
		endl
;
define_proto:	cmp	a,$1c
		jrnz	define_func
_define_proto:	local
		call	!getsym
		mv	a,(bp+!src_sym)
		cmp	a,$10
		jpc	!err7
		cmp	a,$13
		jpnc	!err7
		mv	(bp+!func_type),a
		mv	(bp+!var_type),a
		call	!getsym
		cmp	(bp+!src_sym),$1f
		jpnz	!err9			;ID expected
		mv	ba,$188
		call	!getadd
		jpc	!err5			;Duplicate identifier
		mv	a,$a0
		call	..!make_table
		mvp	[y++],(bp+!obj_adr)
		mv	a,$02
		call	!objout1		;Write 'JP xxxx'
		call	!objout2
		call	!getsym
l1:		cmp	(bp+!src_sym),':'
		jpnz	!err13			;':' expected
		call	!getsym
		mv	a,(bp+!src_sym)
		jr	..!define_proto
		endl
;
define_func:	cmp	a,$15
		jpnz	write_main
_define_func:	local
		call	!getsym
		mv	a,(bp+!src_sym)
		cmp	a,$10
		jpc	!err7
		cmp	a,$13
		jpnc	!err7
		mv	(bp+!func_type),a
		mv	(bp+!var_type),a
		call	!getsym
		cmp	(bp+!src_sym),$1f
		jpnz	!err9			;ID expected
		mv	ba,$100
		call	!getadd
		jpc	!err5			;Duplicate identifier
		mv	ba,$80
		call	!getadd
		jrnc	non_proto
		pushu	x
		mv	x,(bp+!src_work1)
		mv	a,[x]
		and	a,7
		rc
		shr	a
		add	a,$10
		cmp	(bp+!func_type),a
		jpnz	!err14
		mv	a,0
		mv	[x],a
		mv	x,[x+9]
		inc	x
		mvp	[--u],(bp+!obj_adr)
		call	!movobj
		popu	x
		mv	ba,x
		call	!objout2
		call	!movobj
		popu	x
non_proto:	mv	ba,$28
		call	!getadd
		jpc	!err5			;Duplicate identifier
		mv	a,$20
		call	..!make_table
		mvp	[y++],(bp+!obj_adr)
		mvp	(bp+!release_adr),(bp+!src_table)
		mvp	(bp+!release_size),(bp+!src_zero)
		call	!getsym
		cmp	(bp+!src_sym),'('
		jrnz	l1
l2:		call	!getsym
		mv	(bp+!define_type),0
		call	..!define_l_var
		cmp	(bp+!src_sym),';'
		jrz	l2
		cmp	(bp+!src_sym),')'
		jpnz	!err11			;')' expected
		call	!getsym
l1:		cmp	(bp+!src_sym),':'
		jpnz	!err13			;':' expected
		call	!getsym
		mvp	(bp+!make_size),(bp+!src_zero)
l4:		cmp	(bp+!src_sym),'{'
		jrz	l3
		mv	(bp+!define_type),1
		call	..!define_l_var
		cmp	(bp+!src_sym),';'
		jpnz	!err6			;';' expected
		call	!getsym
		jr	l4
l3:		mvp	(bp+!src_work1),(bp+!src_table)	;Modify table
l6:		cmpp	(bp+!src_work1),(bp+!release_adr)
		jrz	l5
		mv	x,(bp+!release_size)
		mv	y,[(bp+!src_work1)+9]
		sub	x,y
		mv	[(bp+!src_work1)+9],x
		mv	x,(bp+!src_work1)
		mv	a,12
		add	x,a
		mv	(bp+!src_work1),x
		jr	l6
l5:		cmp	(bp+!make_size+2),0	;Write suitable object for make_frame!
		jrnz	l5_pnt
		cmp	(bp+!make_size+1),0
		jrnz	l5_int
		mv	a,(bp+!make_size)	;Char range make_frame
		mv	b,a
		mv	a,$09
		jr	l5_make_int
l5_int:		mv	a,$0b			;Int range make_frame
		call	!objout1
		mv	ba,(bp+!make_size)
l5_make_int:	call	!objout2
		mv	a,$04
		call	!objout1
		mv	ba,!make_frame_int
		jr	l5_call		
l5_pnt:		mv	a,$0d			;Write 'mv y,imm20'
		call	!objout1
		mv	x,(bp+!make_size)
		call	!objout3
		mv	a,$04			;Write 'call make_frame'
		call	!objout1
		mv	ba,!make_frame
l5_call:	call	!objout2
l8:		call	!getsym
		cmp	(bp+!src_sym),'}'
		jrz	l7
		call	!statement
		cmp	(bp+!src_sym),';'
		jpnz	!err6			;';' expected
		jr	l8
l7:		call	!make_release
		mvp	(bp+!src_table),(bp+!release_adr)
		call	!getsym
		mv	a,(bp+!src_sym)
		jp	..!define_func
		endl
;
write_main:	mv	x,(bp+!src_table)
check_func:	local				;Check if there is still undefined function
		mv	a,[x]
		cmp	a,$ff
		jrz	..!write_main2
		test	a,$80
		jpnz	!err15
		mv	a,12
		add	x,a
		jr	..!check_func
		endl
;
write_main2:	cmp	(bp+!src_sym),'{'
		jpnz	!err3			;'{' expected
		mvw	[!main_start],(bp+!obj_adr)
		mv	(bp+!func_type),0
;
_write_main:	local
		call	!getsym
		cmp	(bp+!src_sym),'}'
		jrz	!program_end
		call	!statement
		cmp	(bp+!src_sym),';'
		jpnz	!err6			;';' expected
		jr	..!_write_main
		endl
;
define_l_var:	local
		mv	(bp+!var_type),(bp+!src_sym)
l4:		call	!getsym
		cmp	(bp+!src_sym),$1f
		jpnz	!err9			;var_id expected
		mv	ba,$30
		call	!getadd
		jpc	!err5			;Duplicate id
		mv	a,$10
		call	..!make_table
		mv	[y++],x			;Write dummy address
		cmp	(bp+!define_type),0
		jrnz	l3			;Argument size is always 3bytes
		mv	(bp+!var_size),3
l3:		call	!getsym
		cmp	(bp+!src_sym),'['
		jrnz	l2
		call	!getsym
		call	!exp
		cmp	a,$ff
		jpnz	!err8			;contant expected
		cmp	(bp+!define_type),0
		jpz	!err3			;can't make array in argument
		mvp	(bp+!src_work1),(bp+!var_size)
		mv	(bp+!src_work2),x
		call	!mul20
		mv	(bp+!var_size),x
		cmp	(bp+!src_sym),']'
		jpnz	!err3			;']' expected
		call	!getsym
l2:		mv	y,(bp+!var_size)
		mv	x,(bp+!release_size)
		add	x,y
		mv	(bp+!release_size),x
		mv	[(bp+!src_table)+9],x
		mv	x,(bp+!make_size)
		add	x,y
		mv	(bp+!make_size),x
		cmp	(bp+!src_sym),','
		jrz	l4
		ret
		endl
;
make_table:	local
		mv	y,(bp+!src_table)
		mv	il,12
		sub	y,il
		pushu	x
		mv	x,!ctime_u_top
		sub	x,y
		jpnc	!err12			;Table overflow
		popu	x
		mv	(bp+!src_table),y
		pushu	a
		mv	a,(bp+!var_type)
		sub	a,$10
		shl	a
		popu	il
		add	a,il
		mv	[y++],a			;Write ID on table
		mv	il,8
		mv	x,!symbuf
l1:		mv	a,[x++]			;Copy symbol on table
		mv	[y++],a
		dec	il
		jrnz	l1
		mvp	(bp+!var_size),(bp+!src_zero)
		mv	a,(bp+!var_type)
		sub	a,$f
		mv	(bp+!var_size),a
		ret
		endl
;
		endl
;
program_end:	mv	a,$fe			;Write 'IR'
		call	objout1
		mv	a,$02			;Write 'jp terminate'
		call	objout1
		mv	ba,terminate
		call	objout2
		test	(bp+!src_stat),8
		jrz	no_flush_obj
		call	flush_obj
no_flush_obj:	mv	x,(bp+!obj_adr)
		mv	a,32
		add	x,a
		mv	[initialize!set_obj_pnt+2],x
		mv	ba,[!main_start]
		mv	[!jump_to_obj+1],ba
		mv	x,u
		mv	y,endmsg
		pushu	y
		mv	y,(bp+!obj_adr)
		dec	y
		pushu	y
		call	!printf
;
		mv	y,symbuf+16
		pushu	y
		mv	y,start_symbol
		pushu	y
		call	strcpy		
		mv	x,!symbuf+22
		mv	[!symadr],x
;
		test	(bp+!src_stat),$10
		jrz	compile_end
		mv	il,9
		mv	(!cl),(bp+!obj_handle)	;Reset FilePointer
		mvp	(si),0
		mv	a,0
		callf	!fcntl
		mvp	(bp+!src_work1),[!start]
		mvp	[!start],(bp+!src_zero)
		mv	x,(bp+!obj_adr)		;Write object to file
		mv	y,!start
		sub	x,y
		mv	[!header+5],x
		mv	il,04
		mv	(!cl),(bp+!obj_handle)
		mv	x,!header
		mv	y,16
		pushu	y
		callf	!fcntl			;Write header
		popu	x
		sub	x,y
		jpnz	!error4			;Object write error
		mv	il,04
		mv	(!cl),(bp+!obj_handle)
		mv	x,!start
		mv	y,!getch-!start
		pushu	y
		callf	!fcntl			;Write runtime-routine
		popu	x
		sub	x,y
		jpnz	!error4
		test	(bp+!src_stat),8
		jrnz	obj_type2		;Body had been already written
		mv	y,(bp+!obj_pnt)
		mv	x,!obj_start
		sub	y,x
		pushu	y
		mv	il,04
		mv	(!cl),(bp+!obj_handle)
		mv	x,!obj_start
		callf	!fcntl			;Write body
		popu	x
		sub	x,y
		jpnz	!error4
obj_type2:	mvp	[!start],(bp+!src_work1)
;
compile_end:	and	($fb),$7f
		mv	s,[!s_stack]
		mv	u,[!u_stack]
		call	!interrupt2
		or	($fb),$80
		call	!close_all
		mv	($ec),[!base]
		rc
		retf
;
exit:		mv	x,u
		pushu	y
		call	printf
		mv	x,u
		mv	y,sus_symbol
		pushu	y
		mv	y,[symadr]
		dec	y
		mv	a,0
		mv	[y],a
		mv	y,symbuf+16
		pushu	y
		call	printf
		jr	compile_end
sus_symbol:	db	' (%s)',0
error1:		mv	y,errmsg1
		jr	exit2
error2:		mv	y,errmsg2
		jr	exit2
error3:		mv	y,errmsg3
		jr	exit2
error4:		mv	y,errmsg4
		mv	u,[!u_stack]
exit2:		popu	x
exit2_2:	mv	a,[x]
		cmp	a,$0d
		jrnz	exit2_1
		pushu	x
		jr	exit
exit2_1:	inc	x
		jr	exit2_2
;
err1:		mv	y,emsg1			;Unexpected EOF
		jr	exit
err2:		mv	y,emsg2			;Too long identifier
		jr	exit
err3:		mv	y,emsg3			;Syntax error
		jr	exit
err4:		mv	y,emsg4			;Undefined identifier
		jr	exit
err5:		mv	y,emsg5			;Duplicate identifier
		jr	exit
err6:		mv	y,emsg6			;';' expected
		jr	exit
err7:		mv	y,emsg7			;Type specifier expected
		jr	exit
err8:		mv	y,emsg8			;Constant number expected
		jr	exit
err9:		mv	y,emsg9			;Illegal identifier
		jr	exit
err10:		mv	y,emsg10		;'(' expected
		jr	exit
err11:		mv	y,emsg11		;')' expected
		jr	exit
err12:		mv	y,emsg12		;Table overflow
		jr	exit
err13:		mv	y,emsg13		;':' expected
		jr	exit
err14:		mv	y,emsg14		;Type conflict
		jr	exit
err15:		mv	y,emsg15		;Undefined function exist
		jr	exit
;
		end
