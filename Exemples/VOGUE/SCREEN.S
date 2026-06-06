div_by_8:	local
		ex	a,b			;ba = ba / 2
		rc
		shr	a
		ex	a,b
		shr	a
		ex	a,b			;ba = ba / 2
		rc
		shr	a
		ex	a,b
		shr	a
		ex	a,b			;ba = ba / 2
		rc
		shr	a
		ex	a,b
		shr	a
		ret
		endl
;
get_size:	local
		mv	ba,(bp+!src_work1)
		inc	ba
		mv	(bp+!src_work1),ba
		mv	ba,(bp+!src_work2)
		call	!div_by_8
		inc	ba
		mv	(bp+!src_work2),ba
		jp	!mul20
		endl
;
s_clear:	local
		popu	x
		call	!clear_work
		mvw	(bp+!src_work1),[x++]
		mvw	(bp+!src_work2),[x++]
		pushu	x
		call	!get_size
		mv	ba,x
		popu	y
		add	x,y
		pushu	imr
		mv	(bp+!src_work1),u
		mv	u,x
		mv	il,0
		rc
		ex	a,b
		shr	a
		ex	a,b
		shr	a
		jrnc	l1
		pushu	il
		dec	ba
		inc	ba
		jrz	l2
l1:		pushu	i
		dec	ba
		jrnz	l1
l2:		mv	u,(bp+!src_work1)
		popu	imr
		ret
		endl
;
s_point:	local
		popu	x
		mv	ba,x
		mv	(bp+!point_y),ba
		popu	x
		mv	ba,x
		mv	(bp+!point_x),ba
		popu	x
		mvw	(bp+!dest_x_size),[x++]
		mvw	(bp+!dest_y_size),[x++]
		call	!get_scrn_adrs
		jrc	err
		mv	a,[x]
		test	(bp+!dest_ring_o),a
		mv	ba,0
		jrz	exit
		mv	ba,1
exit:		ret
err:		mv	ba,-1
		ret
		endl
;
s_pixel:	local
		popu	x
		mv	a,x
		mv	(bp+!dest_opr),a
		popu	x
		mv	ba,x
		mv	(bp+!point_y),ba
		popu	x
		mv	ba,x
		mv	(bp+!point_x),ba
		popu	x
		mvw	(bp+!dest_x_size),[x++]
		mvw	(bp+!dest_y_size),[x++]
		call	!get_scrn_adrs
		jrc	err
		mv	a,[x]
		cmp	(bp+!dest_opr),1
		jrc	l1
		jrz	l2
		xor	a,(bp+!dest_ring_o)
exit:		mv	[x],a
		mv	ba,0
		ret
l2:		or	a,(bp+!dest_ring_o)
		jr	exit
l1:		xor	(bp+!dest_ring_o),$ff
		and	a,(bp+!dest_ring_o)
		jr	exit
err:		mv	ba,-1
		ret
		endl
;
s_fill:		local
		popu	x
		mv	a,x
		mv	(bp+!dest_opr),a
		popu	x
		mv	ba,x
		mv	(bp+!to_y),ba
		popu	x
		mv	ba,x
		mv	(bp+!to_x),ba
		popu	x
		mv	ba,x
		mv	(bp+!point_y),ba
		popu	x
		mv	ba,x
		mv	(bp+!point_x),ba
		popu	x
		cmpw	(bp+!point_y),(bp+!to_y)
		jrc	l1
		exw	(bp+!point_y),(bp+!to_y)
l1:		mv	il,8
		mvl	[!s_box!box_x1],(bp+!point_x)
		mv	[!s_box!box_adrs],x
		mvw	(bp+!to_y),(bp+!point_y)
		call	!s_line!entry
		jrc	exit
		mv	il,8
		mvl	(bp+!point_x),[!s_box!box_x1]
		mv	x,[!s_box!box_adrs]
		cmpw	(bp+!point_y),(bp+!to_y)
		jrz	exit1
		mv	ba,(bp+!point_y)
		inc	ba
		mv	(bp+!point_y),ba
		jr	l1
exit1:		mv	ba,0
exit:		ret
		endl
;
s_box:		local
		popu	x
		mv	a,x
		mv	(bp+!dest_opr),a
		popu	x
		mv	ba,x
		mv	(bp+!to_y),ba
		popu	x
		mv	ba,x
		mv	(bp+!to_x),ba
		popu	x
		mv	ba,x
		mv	(bp+!point_y),ba
		popu	x
		mv	ba,x
		mv	(bp+!point_x),ba
		popu	x
		mv	il,8
		mvl	[box_x1],(bp+!point_x)
		mv	[box_adrs],x
		mvw	(bp+!to_y),(bp+!point_y)
		call	!s_line!entry
		jrc	exit
		mv	il,8
		mvl	(bp+!point_x),[box_x1]
		mv	x,[box_adrs]
		mvw	(bp+!point_x),(bp+!to_x)
		call	!s_line!entry
		jrc	exit		
		mv	il,8
		mvl	(bp+!point_x),[box_x1]
		mv	x,[box_adrs]
		mvw	(bp+!point_y),(bp+!to_y)
		call	!s_line!entry
		mv	il,8
		mvl	(bp+!point_x),[box_x1]
		mv	x,[box_adrs]
		mvw	(bp+!to_x),(bp+!point_x)
		call	!s_line!entry
exit:		ret
box_x1:		ds	8
box_adrs:	ds	3
		endl
;
s_line:		local
		popu	x
		mv	a,x
		mv	(bp+!dest_opr),a
		popu	x
		mv	ba,x
		mv	(bp+!to_y),ba
		popu	x
		mv	ba,x
		mv	(bp+!to_x),ba
		popu	x
		mv	ba,x
		mv	(bp+!point_y),ba
		popu	x
		mv	ba,x
		mv	(bp+!point_x),ba
		popu	x
entry:		mvw	(bp+!dest_x_size),[x++]
		mvw	(bp+!dest_y_size),[x++]
		cmpw	(bp+!dest_x_size),(bp+!to_x)
		jpc	err
		cmpw	(bp+!dest_y_size),(bp+!to_y)
		jpc	err
		call	!get_scrn_adrs
		jpc	err
		mv	a,$7f			;OR operation
		mv	il,$1e
		cmp	(bp+!dest_opr),1
		jrz	or_opr
		jrnc	xor_opr
		xor	(bp+!dest_ring_o),$ff
		mv	a,$77			;AND operation	
		mv	il,$1c
		jr	or_opr
xor_opr:	mv	a,$6f
or_opr:		mv	[point_z1],a
		mv	[point_z2],a
		mv	[point_w1],il
		mv	[point_w2],il
		cmpw	(bp+!to_x),(bp+!point_x)
		jrz	l1
		jrc	l2
;
;set INC
;
		mv	ba,$046c		;Write 'inc x'
		pushu	ba
;
		mv	ba,(bp+!to_x)
		mv	i,(bp+!point_x)
		jr	next
l2:
;
;set DEC
;
		mv	ba,$047c		;Write 'dec x'
		pushu	ba
;
		mv	ba,(bp+!point_x)
		mv	i,(bp+!to_x)
		jr	next
l1:
;
;set NOP
;
		mv	ba,0			;Write 'nop nop'
		pushu	ba
;
		mv	ba,i
next:		sub	ba,i
		mv	i,ba
		mv	(bp+!from_x),ba
		inc	i
		mv	(bp+!x_count),i
		add	 ba,ba
		mv	(bp+!to_x),ba
		popu	ba
		mv	[point_x1],ba
		mv	[point_x2],ba
		cmpw	(bp+!to_y),(bp+!point_y)
		jrz	l1_1
		jrc	l2_1
;
;set INC
;
		mv	ba,$45e7		;Write 'rol (n) ; add r3,r'
		pushu	ba
;
		mv	ba,(bp+!to_y)
		mv	i,(bp+!point_y)
		jr	next_1
l2_1:
;
;set DEC
;
		mv	ba,$4de5		;Write 'ror (n) ; sub r3,r'
		pushu	ba
;
		mv	ba,(bp+!point_y)
		mv	i,(bp+!to_y)
		jr	next_1
l1_1:
;
;set NOP
;
		mv	ba,$0808
		pushu	ba
;
		mv	ba,i
next_1:		sub	ba,i
		mv	i,ba
		mv	(bp+!from_y),ba
		inc	i
		mv	(bp+!y_count),i
		add	ba,ba
		mv	(bp+!to_y),ba
		popu	ba
		mv	[point_y1],a
		mv	[point_y2],a
		mv	a,b
		mv	[point_p1],a
		mv	[point_p2],a
		cmpw	(bp+!from_x),(bp+!from_y)
		jrc	l4_1
		mv	ba,(bp+!x_count)
		mv	y,ba
l4:		mv	a,[x]
point_z1:	or	a,(bp+!dest_ring_o)
		mv	[x],a
		mv	ba,(bp+!from_x)
		mv	i,(bp+!to_y)
		add	ba,i
		mv	(bp+!from_x),ba
		cmpw	(bp+!from_x),(bp+!to_x)
		jrc	l3
		mv	i,(bp+!to_x)
		sub	ba,i
		mv	(bp+!from_x),ba
point_y1:	rol	(bp+!dest_ring_o)
point_w1:	jrnc	l3
		mv	ba,(bp+!dest_x_size)
point_p1:	add	x,ba
l3:
point_x1:	inc	x
		dec	y
		jrnz	l4
exit:		mv	ba,0
		rc
		ret
;
l4_1:		mv	ba,(bp+!y_count)
		mv	y,ba
l4_2:		mv	a,[x]
point_z2:	or	a,(bp+!dest_ring_o)
		mv	[x],a
		mv	ba,(bp+!from_y)
		mv	i,(bp+!to_x)
		add	ba,i
		mv	(bp+!from_y),ba
		cmpw	(bp+!from_y),(bp+!to_y)
		jrc	l3_1
		mv	i,(bp+!to_y)
		sub	ba,i
		mv	(bp+!from_y),ba
point_x2:	inc	x
l3_1:
point_y2:	rol	(bp+!dest_ring_o)
point_w2:	jrnc	l3_2
		mv	ba,(bp+!dest_x_size)
point_p2:	add	x,ba
l3_2:		dec	y
		jrnz	l4_2
		jr	exit
err:		mv	ba,-1
		sc
		ret		
		endl
;
get_scrn_adrs:	local
		mv	ba,(bp+!point_x)
		cmpw	(bp+!dest_x_size),ba
		jrc	err
		cmpw	(bp+!dest_y_size),(bp+!point_y)
		jrc	err
		add	x,ba
		pushu	x
		mv	ba,(bp+!point_y)
		call	!div_by_8
		mv	x,ba
		mv	(bp+!src_work1),x
		mv	ba,(bp+!dest_x_size)
		inc	ba
		mv	x,ba
		mv	(bp+!dest_x_size),ba
		mv	(bp+!src_work2),x
		call	!mul20
		popu	y
		add	x,y
		mv	a,(bp+!point_y)
		and	a,7
		mv	y,!s_proj!table
		add	y,a
		mv	(bp+!dest_ring_o),[y]
		rc
		ret
err:		sc
		ret
		endl
;
s_proj:		local
		popu	x
		mv	a,x
		mv	(bp+!dest_opr),a
		popu	x
		mv	ba,x
		mv	(bp+!point_y),ba
		popu	x
		mv	ba,x
		mv	(bp+!point_x),ba
		popu	x
		popu	y
entry:		mvw	(bp+!source_x_size),[x++]
		mvw	(bp+!source_y_size),[x++]
		mv	(bp+!source_adrs),x
		mvw	(bp+!dest_x_size),[y++]
		mvw	(bp+!dest_y_size),[y++]
		mv	(bp+!dest_adrs),y
get_scrn_adr:	local
		mv	i,(bp+!point_x)
		mv	ba,(bp+!source_x_size)
		add	ba,i
		mv	a,b
		test	a,$80
		jpnz	..!exit
		mv	ba,i
		ex	a,b
		test	a,$80
		ex	a,b
		jrz	l1
		mv	il,0
		sub	il,ba
		mv	ba,0
		jr	next_y
l1:		cmpw	(bp+!dest_x_size),ba
		jpc	..!exit
		mv	il,0
next_y:		mv	(bp+!from_x),i
		mv	(bp+!to_x),ba
		mv	i,(bp+!point_y)
		mv	ba,(bp+!source_y_size)
		add	ba,i
		mv	a,b
		test	a,$80
		jpnz	..!exit
		mv	ba,i
		ex	a,b
		test	a,$80
		ex	a,b
		jrz	l2
		mv	il,0
		sub	il,ba
		mv	ba,0
		jr	next
l2:		cmpw	(bp+!dest_y_size),i
		jpc	..!exit
		mv	il,0
next:		mv	(bp+!from_y),i
		mv	(bp+!to_y),ba
		mv	ba,(bp+!source_y_size)
		sub	ba,i
		inc	ba
		mv	(bp+!y_count),ba
		mv	i,(bp+!to_y)
		mv	ba,(bp+!dest_y_size)
		sub	ba,i
		inc	ba
		cmpw	(bp+!y_count),ba
		jrc	l3
		mv	(bp+!y_count),ba
l3:		mv	i,(bp+!from_x)
		mv	ba,(bp+!source_x_size)
		sub	ba,i
		inc	ba
		mv	(bp+!x_count),ba
		mv	i,(bp+!to_x)
		mv	ba,(bp+!dest_x_size)
		sub	ba,i
		inc	ba
		cmpw	(bp+!x_count),ba
		jrc	l4
		mv	(bp+!x_count),ba
l4:		mv	a,(bp+!from_y)
		and	a,7
		mv	x,..!table
		add	x,a
		mv	(bp+!source_ring_o),[x]
		mv	a,(bp+!to_y)
		and	a,7
		mv	x,..!table
		add	x,a
		mv	(bp+!dest_ring_o),[x]
		call	!clear_work
		mv	ba,(bp+!from_y)
		call	!div_by_8
		mv	(bp+!src_work1),ba
		mv	ba,(bp+!source_x_size)
		inc	ba
		mv	(bp+!source_x_size),ba
		mv	(bp+!src_work2),ba
		call	!mul20
		mv	y,(bp+!source_adrs)
		add	x,y
		mv	ba,(bp+!from_x)
		add	x,ba
		mv	(bp+!source_adrs),x
		call	!clear_work
		mv	ba,(bp+!to_y)
		call	!div_by_8
		mv	(bp+!src_work1),ba
		mv	ba,(bp+!dest_x_size)
		inc	ba
		mv	(bp+!dest_x_size),ba
		mv	(bp+!src_work2),ba
		call	!mul20
		mv	y,(bp+!dest_adrs)
		add	x,y
		mv	ba,(bp+!to_x)
		add	x,ba
		mv	(bp+!dest_adrs),x
		mv	y,x
		mv	x,(bp+!source_adrs)
		endl
;
		mv	a,(bp+!dest_opr)
		cmp	a,1
		jrnz	entry1
		mv	a,$7b
entryx:		mv	[!graphic_engine!point2],a
		mv	[!graphic_engine!point3],a
		add	a,3
		mv	[!graphic_engine!point4],a
		mv	[!graphic_engine!point5],a
		mv	[!graphic_engine!point6],a
		inc	a
		mv	[!graphic_engine!point1],a
		jr	!graphic_engine
entry1:		cmp	a,2
		jrnz	l2
		mv	a,$6b
		jr	entryx
l2:		mv	(bp+!dest_ring),(bp+!dest_ring_o)
		xor	(bp+!dest_ring),$ff
		cmp	(bp+!dest_ring_o),(bp+!source_ring_o)
		jrnz	_main
		mv	il,8
l12:		cmpw	(bp+!y_count),i
		jrc	_main
		mv	ba,(bp+!x_count)		
		call	!_transfer
		mv	x,(bp+!source_adrs)
		mv	ba,(bp+!source_x_size)
		add	x,ba
		mv	(bp+!source_adrs),x
		mv	y,(bp+!dest_adrs)
		mv	ba,(bp+!dest_x_size)
		add	y,ba
		mv	(bp+!dest_adrs),y
		mv	ba,(bp+!y_count)
		mv	il,8
		sub	ba,i
		mv	(bp+!y_count),ba
		jrnz	l12
		jr	l11
_main:		mv	ba,(bp+!x_count)
		rc
		ex	a,b
		shr	a
		ex	a,b
		shr	a
		mv	i,ba
		jrnc	l0
		mv	a,[x++]
		mv	(bp+!src_work1),[y]
		test	(bp+!source_ring_o),a
		jrz	no_dot
		or	(bp+!src_work1),(bp+!dest_ring_o)
		jr	skip1
no_dot:		and	(bp+!src_work1),(bp+!dest_ring)
skip1:		mv	[y++],(bp+!src_work1)
		inc	i
		dec	i
		jrz	l15
l0:		mv	ba,[x++]
		mvw	(bp+!src_work1),[y]
		test	(bp+!source_ring_o),a
		jrz	no_dot1
		or	(bp+!src_work1),(bp+!dest_ring_o)
		jr	skip2
no_dot1:	and	(bp+!src_work1),(bp+!dest_ring)
skip2:		mv	a,b
		test	(bp+!source_ring_o),a
		jrz	no_dot2
		or	(bp+!src_work1+1),(bp+!dest_ring_o)
		jr	skip3
no_dot2:	and	(bp+!src_work1+1),(bp+!dest_ring)
skip3:		mvw	[y++],(bp+!src_work1)
		dec	i
		jrnz	l0
l15:		mv	x,(bp+!source_adrs)
		mv	y,(bp+!dest_adrs)
		rol	(bp+!source_ring_o)
		jrnc	l1
		mv	i,(bp+!source_x_size)
		add	x,i
		mv	(bp+!source_adrs),x
l1:		rol	(bp+!dest_ring)
		rol	(bp+!dest_ring_o)
		jrnc	next
		mv	i,(bp+!dest_x_size)
		add	y,i
		mv	(bp+!dest_adrs),y
next:		dec	(bp+!y_count)
		jrnz	_main
		sub	(bp+!y_count+1),1
		jrnc	_main
l11:		mv	ba,0
		ret
exit:		mv	ba,-1
		ret
table:		db	$01,$02,$04,$08,$10,$20,$40,$80
		endl
;
graphic_engine:	local
		cmp	(bp+!dest_ring_o),(bp+!source_ring_o)
		jrnz	_main
		mv	il,8
l12:		cmpw	(bp+!y_count),i
		jrc	_main
		mv	ba,(bp+!x_count)
		rc
		ex	a,b
		shr	a
		ex	a,b
		shr	a
		mv	i,ba
		jrnc	l13
		mv	(bp+!src_work1),[x++]
		mv	a,[y]
point1:		or	a,(bp+!src_work1)
		mv	[y++],a
		inc	i
		dec	i
		jrz	l14
l13:		mv	ba,[x++]
		mvw	(bp+!src_work1),[y]
point2:		or	(bp+!src_work1),a
		mv	a,b
point3:		or	(bp+!src_work1+1),a
		mvw	[y++],(bp+!src_work1)
		dec	i
		jrnz	l13
l14:		mv	x,(bp+!source_adrs)
		mv	ba,(bp+!source_x_size)
		add	x,ba
		mv	(bp+!source_adrs),x
		mv	y,(bp+!dest_adrs)
		mv	ba,(bp+!dest_x_size)
		add	y,ba
		mv	(bp+!dest_adrs),y
		mv	ba,(bp+!y_count)
		mv	il,8
		sub	ba,i
		mv	(bp+!y_count),ba
		jrnz	l12
		jr	l11
_main:		mv	ba,(bp+!x_count)
		rc
		ex	a,b
		shr	a
		ex	a,b
		shr	a
		mv	i,ba
		jrnc	l0
		mv	a,[x++]
		mv	(bp+!src_work1),[y]
		test	(bp+!source_ring_o),a
		jrz	no_dot
point4:		or	(bp+!src_work1),(bp+!dest_ring_o)
no_dot:		mv	[y++],(bp+!src_work1)
		inc	i
		dec	i
		jrz	l15
l0:		mv	ba,[x++]
		mvw	(bp+!src_work1),[y]
		test	(bp+!source_ring_o),a
		jrz	no_dot1
point5:		or	(bp+!src_work1),(bp+!dest_ring_o)
no_dot1:	mv	a,b
		test	(bp+!source_ring_o),a
		jrz	no_dot2
point6:		or	(bp+!src_work1+1),(bp+!dest_ring_o)
no_dot2:	mvw	[y++],(bp+!src_work1)
		dec	i
		jrnz	l0
l15:		mv	x,(bp+!source_adrs)
		mv	y,(bp+!dest_adrs)
		rol	(bp+!source_ring_o)
		jrnc	l1
		mv	i,(bp+!source_x_size)
		add	x,i
		mv	(bp+!source_adrs),x
l1:		rol	(bp+!dest_ring_o)
		jrnc	next
		mv	i,(bp+!dest_x_size)
		add	y,i
		mv	(bp+!dest_adrs),y
next:		dec	(bp+!y_count)
		jrnz	_main
		sub	(bp+!y_count+1),1
		jrnc	_main
l11:		mv	ba,0
		ret
exit:		mv	ba,-1
		ret
		endl
;
s_copy:		local
		call	!clear_work
		popu	x
		popu	y
		mvw	(bp+!src_work1),[x++]
		mv	ba,[y++]
		cmpw	(bp+!src_work1),ba
		jrnz	err
		mvw	(bp+!src_work2),[x++]
		mv	ba,[y++]
		cmpw	(bp+!src_work2),ba
		jrnz	err
		pushu	x
		pushu	y
		call	!get_size
		mv	ba,x
		popu	y
		popu	x
		call	!_transfer
		mv	ba,0
		ret
err:		mv	ba,-1
		ret
		endl
;
_transfer:	local
		rc
		ex	a,b
		shr	a
		ex	a,b
		shr	a
		jrnc	l1
		mv	il,[x++]
		mv	[y++],il
		inc	ba
		dec	ba
		jrz	l2
l1:		mv	i,[x++]
		mv	[y++],i
		dec	ba
		jrnz	l1
l2:		ret
		endl
;
s_shift:	local
		mvp	(bp+!src_work1),[u++]
		mvw	(bp+!point_y),(bp+!src_work1)
		mvp	(bp+!src_work1),[u++]
		mvw	(bp+!point_x),(bp+!src_work1)
		popu	x
		mvw	(bp+!source_x_size),[x++]
		mvw	(bp+!source_y_size),[x++]
		mv	(bp+!source_adrs),x
		call	!clear_work
		mvw	(bp+!src_work1),(bp+!source_x_size)
		mvw	(bp+!src_work2),(bp+!source_y_size)
		call	!get_size
		pushu	imr
		mv	ba,x
		mv	(bp+!src_work2),ba
;
		test	(bp+!point_x+1),$80
		jrnz	l1
		cmpw	(bp+!point_x),(bp+!src_zero)
		jrz	next
		mv	i,(bp+!src_work2)	;Move X to plus direction
		mv	y,(bp+!source_adrs)
		add	y,i
		mv	x,y
		mv	ba,(bp+!point_x)
		sub	x,ba
		sub	i,ba
		mv	ba,i
		rc
		ex	a,b
		shr	a
		ex	a,b
		shr	a
		jrnc	_l1
		mv	il,[--x]
		mv	[--y],il
		inc	ba
		dec	ba
		jrz	next
_l1:		mv	i,[--x]
		mv	[--y],i
		dec	ba
		jrnz	_l1
		jr	next
l1:		mv	y,(bp+!source_adrs)
		mv	x,y
		mv	i,(bp+!point_x)
		mv	ba,0
		sub	ba,i			;Set X at ba
		add	x,ba
		mv	i,(bp+!src_work2)
		sub	i,ba
		mv	ba,i
		call	!_transfer
next:		mv	(bp+!dest_adrs),u
		mv	ba,(bp+!source_y_size)
		call	!div_by_8
		inc	ba
		mv	u,ba
		mv	(bp+!src_work1),u
		mv	i,(bp+!source_x_size)
		inc	i
		test	(bp+!point_y),$80
		jrnz	next1
		cmpw	(bp+!point_y),(bp+!src_zero)
		jrz	exit
		mv	y,(bp+!source_adrs)
next3:		mv	u,(bp+!src_work1)
		mv	x,y
next2:		mv	a,[x]
		shl	a
		mv	[x],a
		shr	a
		add	x,i
		shl	a
		dec	u
		jrnz	next2
		inc	y
		sub	(bp+!source_x_size),1
		jrnc	next3
		sub	(bp+!source_x_size+1),1
		jrnc	next3
exit:		mv	ba,0
		mv	u,(bp+!dest_adrs)
		popu	imr
		ret
next1:		mv	ba,(bp+!src_work2)
		mv	y,(bp+!source_adrs)
		add	y,ba
		dec	y
next3_1:	mv	u,(bp+!src_work1)
		mv	x,y
next2_1:	mv	a,[x]
		shr	a
		mv	[x],a
		shl	a
		sub	x,i
		shr	a
		dec	u
		jrnz	next2_1
		dec	y
		sub	(bp+!source_x_size),1
		jrnc	next3_1
		sub	(bp+!source_x_size+1),1
		jrnc	next3_1
		jr	exit
		endl
;
s_real:		local
		popu	x
		mv	a,x
		mv	(bp+!src_work1+2),a
		popu	x
		mv	ba,[x++]
		mv	i,239
		sub	ba,i
		jrnz	err
		mv	ba,[x++]
		mv	i,31
		sub	ba,i
		jrnz	err
		pushu	imr
		mv	(bp+!src_work1+1),4
		mv	(bp+!src_work1),[($e6)+8]
		or	(bp+!src_work1),$b8
l0:		mv	[$2000],(bp+!src_work1)	;Set X page
		mvw	(bp+!src_work2),$3840
		mv	a,$40
		mv	[$2000],a		;Set Y adrs
		test	(bp+!src_work1+2),1
		jrz	skip_l1
		mv	y,$2006
l1:		mv	a,[x++]
		mv	[y],a
		dec	(bp+!src_work2)
		jrnz	l1
return_l1:	test	(bp+!src_work1+2),2
		jrz	skip_l2
		mv	y,$200a
l2:		mv	a,[x++]
		mv	[y],a
		dec	(bp+!src_work2+1)
		jrnz	l2
return_l2:	add	(bp+!src_work1),4
		and	(bp+!src_work1),7
		or	(bp+!src_work1),$b8
		mv	[$2000],(bp+!src_work1)	;Set X page
		mv	a,120
		add	x,a
		mvw	(bp+!src_work2),$3840
		mv	a,$40
		mv	[$2000],a		;Set Y adrs
		test	(bp+!src_work1+2),8
		jrz	skip_l3
		mv	y,$2006
l3:		mv	a,[--x]
		mv	[y],a
		dec	(bp+!src_work2)
		jrnz	l3
return_l3:	test	(bp+!src_work1+2),4
		jrz	skip_l4
		mv	y,$200a
l4:		mv	a,[--x]
		mv	[y],a
		dec	(bp+!src_work2+1)
		jrnz	l4
return_l4:	sub	(bp+!src_work1),3
		and	(bp+!src_work1),7
		or	(bp+!src_work1),$b8
		mv	a,120
		add	x,a
		dec	(bp+!src_work1+1)
		jrnz	l0
		mv	ba,0
		popu	imr
		ret
err:		mv	ba,-1
		ret
skip_l1:	mv	a,(bp+!src_work2)
		add	x,a
		jr	return_l1
skip_l2:	mv	a,(bp+!src_work2+1)
		add	x,a
		jr	return_l2
skip_l3:	mv	a,(bp+!src_work2)
		sub	x,a
		jr	return_l3
skip_l4:	mv	a,(bp+!src_work2+1)
		sub	x,a
		jr	return_l4
		endl
;
s_take:		local
		popu	x
		mv	ba,[x++]
		mv	i,239
		sub	ba,i
		jrnz	err
		mv	ba,[x++]
		mv	i,31
		sub	ba,i
		jrnz	err
		pushu	imr
		mv	(bp+!src_work1+1),4
		mv	(bp+!src_work1),[($e6)+8]
		or	(bp+!src_work1),$b8
l0:		mv	[$2000],(bp+!src_work1)	;Set X page
		mvw	(bp+!src_work2),$3941
		mv	a,$40
		mv	[$2000],a		;Set Y adrs
		mv	y,$2007
		mv	a,[y]
		jr	l1_1
l1:		mv	a,[y]
		mv	[x++],a
l1_1:		dec	(bp+!src_work2)
		jrnz	l1
		mv	y,$200b
		mv	a,[y]
		jr	l2_1
l2:		mv	a,[y]
		mv	[x++],a
l2_1:		dec	(bp+!src_work2+1)
		jrnz	l2
		add	(bp+!src_work1),4
		and	(bp+!src_work1),7
		or	(bp+!src_work1),$b8
		mv	[$2000],(bp+!src_work1)	;Set X page
		mv	a,120
		add	x,a
		mvw	(bp+!src_work2),$3941
		mv	a,$40
		mv	[$2000],a		;Set Y adrs
		mv	y,$2007
		mv	a,[y]
		jr	l3_1
l3:		mv	a,[y]
		mv	[--x],a
l3_1:		dec	(bp+!src_work2)
		jrnz	l3
		mv	y,$200b
		mv	a,[y]
		jr	l4_1
l4:		mv	a,[y]
		mv	[--x],a
l4_1:		dec	(bp+!src_work2+1)
		jrnz	l4
		sub	(bp+!src_work1),3
		and	(bp+!src_work1),7
		or	(bp+!src_work1),$b8
		mv	a,120
		add	x,a
		dec	(bp+!src_work1+1)
		jrnz	l0
		mv	ba,0
		popu	imr
		ret
err:		mv	ba,-1
		ret
		endl
;
s_puts:		local
		call	!s_putc_init
		mv	(bp+!obj_handle),$ff
l1:		mv	x,[!s_putc!str_adrs]
		mv	a,[x++]
		mv	[!s_putc!str_adrs],x
		cmp	a,0
		jrz	exit
		call	!s_putc!entry
		and	(bp+!obj_handle),a
		mv	x,[!s_putc!x_axis]
		mv	a,6
		add	x,a
		mv	[!s_putc!x_axis],x
		jr	l1
exit:		mv	a,(bp+!obj_handle)
		mv	b,a
		ret
		endl
;
s_putc:		local
		call	!s_putc_init
		mv	a,[str_adrs]		
entry:		mv	x,table
l2:		mv	il,[x++]
		mv	y,[x++]
		sub	il,a
		jrc	l2
		mv	y,[y]
		mv	il,[x-8]
		sub	a,il
		dec	a
		mv	b,a			;y += ba * 6;
		mv	a,0
		ex	a,b
		add	ba,ba
		mv	i,ba
		add	ba,ba
		add	ba,i
		add	y,ba
		mv	x,char_data
		mv	ba,[y++]
		mv	[x++],ba
		mv	ba,[y++]
		mv	[x++],ba
		mv	ba,[y++]
		mv	[x++],ba
		mv	x,[scrn_adrs]
		pushu	x
		mv	x,sub_scrn
		pushu	x
		mv	x,[x_axis]
		pushu	x
		mv	x,[y_axis]
		pushu	x
		mv	x,[mode]
		pushu	x
		jp	!s_proj
		db	-1
		dp	0
table:		db	$1f
		dp	!char_adrs_1
		db	$7f
		dp	!char_adrs_2
		db	$9f
		dp	!char_adrs_3
		db	$df
		dp	!char_adrs_4
		db	$ff
		dp	!char_adrs_5
sub_scrn:	db	5,0,7,0
char_data:	ds	6
scrn_adrs:	ds	3
str_adrs:	ds	3
x_axis:		ds	3
y_axis:		ds	3
mode:		ds	3
		endl
;
s_putc_init:	local
		mv	il,5
		mv	y,!s_putc!mode+3
l0:		popu	x
		mv	[--y],x
		dec	il
		jrnz	l0
		ret
		endl
;
		end
