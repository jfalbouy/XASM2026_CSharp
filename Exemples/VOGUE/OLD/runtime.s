initialize:	local
		popu	x
		mv	[!_argp],x
command_loop:	mv	a,[x++]
		cmp	a,$0d
		jrnz	command_loop
		dec	x
		pushu	x
		mv	[!s_stack],s
		mv	[!u_stack],u
		mv	s,!rtime_s_top
		mv	u,!rtime_u_top
		call	!interrupt1
;
		mv	a,0
		mv	[!fork_switch],a
		mv	[!latest_prcs],a
		mvp	(bp+!prcs_head),!main_top-3
		mvp	[(bp+!prcs_head)],(bp+!prcs_head)
		mvp	(bp+!productive_prcs),(bp+!prcs_head)
set_obj_pnt:	mvp	(bp+!obj_pnt),!obj_start
		mvp	(bp+!prcs_limit),(bp+!obj_pnt)
		mvp	[(bp+!prcs_head)-9],(bp+!obj_pnt)
		mvw	[(bp+!prcs_head)-11],(bp+!src_zero)
		mv	(bp+!alive_prcs),1
		endl
;
jump_to_obj:	jp	user_break!entry
;
interrupt1:	local
		pushu	imr
		mv	[!base],($ec)
		mv	($ec),$70
		mv	x,[!ir_trap]
		mv	[!_ir_trap],x
		mv	x,!prcs_switch
		mv	[!ir_trap],x
;
		mv	x,[!timerf]
		mv	[!timerf_count!_timerf+2],x
		mv	x,!timerf_count
		mv	[!timerf],x
;
		mv	x,[!timers]
		mv	[!timers_count!_timers+2],x
		mv	x,!timers_count
		mv	[!timers],x
;
		mvp	(bp+!src_zero),0
		mvp	[!fast_timer],(bp+!src_zero)
		mvp	[!slow_timer],(bp+!src_zero)
;
		popu	imr
		ret
		endl
;
interrupt2:	local
		pushu	imr	
		mv	x,[!_ir_trap]
		mv	[!ir_trap],x
		mv	x,[!timerf_count!_timerf+2]
		mv	[!timerf],x
		mv	x,[!timers_count!_timers+2]
		mv	[!timers],x
		popu	imr
		ret
		endl
;
make_frame_int:	mv	y,i
make_frame:	local
		pushs	x
		mv	x,u
		sub	x,y
		cmpp	(bp+!prcs_limit),x
		jrc	l1
l3:		mv	y,msg
l2:		mv	x,u
		pushu	y
		call	!printf
		jp	!terminate
l1:		mv	u,x
		mv	(bp+!src_work1),u
		mv	y,(bp+!src_local)
		sub	y,u
		pushu	y
		mvp	(bp+!src_local),(bp+!src_work1)
		pops	x
		ret
msg:		db	'Memory exhausted',0
		endl
;
release_int:	mv	y,i
release_frame:	local
		pushs	x
		popu	x
		add	x,u
		mv	(bp+!src_local),x
		pops	x
		add	u,y
		ret
		endl
;
prcs_switch:	local
		and	($fb),$7f
		mvp	[--u],(bp+!src_local)
		mv	[--u],(bp+!errnum)
		mvp	[--u],(bp+!random)
		mv	x,s
		mv	[(bp+!prcs_head)-6],x
		mv	[(bp+!prcs_head)-3],u
		mvp	[(bp+!prcs_head)-9],(bp+!prcs_limit)
		mv	a,[!fork_switch]
		cmp	a,0
		jrz	l1
;
		mv	a,0
		mv	[!fork_switch],a
		cmpp	(bp+!prcs_head),(bp+!productive_prcs)
		jrnz	cant_fork		;not a productive proccess
		mv	x,[!fork_size]
		mv	y,u
		sub	y,x
		mv	(bp+!src_work2),y	; y <- head address of new proccess
		mv	x,(bp+!prcs_head)
		sub	x,u			; x <- size of current proccess
		sub	y,x
		cmpp	(bp+!obj_pnt),y
		jrnc	cant_fork		;not enough core
		mv	y,(bp+!src_work2)
		mv	(bp+!src_work1),u
		mv	x,(bp+!prcs_head)
		mv	a,3
		add	x,a
l2:		mv	a,[--x]
		mv	[--y],a
		cmpp	(bp+!src_work1),x
		jrnz	l2
		mvp	[(bp+!prcs_head)-9],(bp+!src_work2)
		mv	x,[(bp+!prcs_head)]
		mv	y,(bp+!src_work2)
		mv	a,3
		sub	y,a
		mv	(bp+!src_work2),y
		mv	[(bp+!prcs_head)],y
		mv	[y],x
		mv	x,(bp+!prcs_head)
		sub	x,y
		mv	y,[(bp+!prcs_head)-3]
		sub	y,x
		mv	[(bp+!src_work2)-3],y
		mv	y,[(bp+!prcs_head)-6]
		sub	y,x
		mv	[(bp+!src_work2)-6],y
		mv	a,[(bp+!src_work2)-10]
		inc	a
		mv	[(bp+!src_work2)-10],a	;Increment proccess ID
		mv	[!latest_prcs],a
		mvp	(bp+!productive_prcs),(bp+!src_work2)
		inc	(bp+!alive_prcs)
l1:		or	($fb),$80
search_active:	mv 	x,[(bp+!prcs_head)]
		mv	(bp+!prcs_head),x
		mv	a,[(bp+!prcs_head)-11]
		test	a,4
		jrz	no_kill_prcs
		dec	(bp+!alive_prcs)
		jpz	!terminate
l3:		mv	y,x			;Gabege collection
		mv	x,[x]
		cmpp	(bp+!prcs_head),x
		jrnz	l3
		mvp	(bp+!src_work1),[x]
		mvp	[y],(bp+!src_work1)
		cmpp	(bp+!productive_prcs),y
		jrz	l4
		mvp	(bp+!src_work1),[x-9]
		mvp	[y-9],(bp+!src_work1)
l4:		cmpp	(bp+!productive_prcs),x
		jrnz	search_active
		mv	(bp+!productive_prcs),y
		mv	a,[y-10]
		mv	[!latest_prcs],a
		jr	search_active
no_kill_prcs:	test	a,1
		jrnz	search_active
		and	($fb),$7f
		mvp	(bp+!prcs_limit),[(bp+!prcs_head)-9]
		mv	u,[(bp+!prcs_head)-3]
		mv	x,[(bp+!prcs_head)-6]
		mv	s,x
		mvp	(bp+!random),[u++]
		mv	(bp+!errnum),[u++]
		mvp	(bp+!src_local),[u++]
		or	($fb),$80
		retf
cant_fork:	mv	a,[(bp+!prcs_head)-11]
		or	a,2
		mv	[(bp+!prcs_head)-11],a
		jr	l1
		endl
;
fork:		local
		popu	x
		mv	[!fork_size],x
		mv	a,1
		mv	[!fork_switch],a
		ir
		mv	a,[(bp+!prcs_head)-11]
		test	a,2
		pushu	f
		and	a,$fd
		mv	[(bp+!prcs_head)-11],a
		popu	f
		jrnz	cant_fork
		mv	ba,0
		mv	a,[(bp+!prcs_head)-10]
		ret
cant_fork:	mv	ba,-1
		ret
		endl
;
pid:		local
		mv	a,[(bp+!prcs_head)-10]
		ret
		endl
;
free:		local
		mv	x,u
		mv	y,[(bp+!prcs_head)-9]
		sub	x,y
		ret
		endl
;
sleep:		local
		popu	x
		mv	a,x
		call	!pid2adrs
		mv	ba,-1
		jrc	exit
		mv	a,[x-11]
		or	a,1
		mv	[x-11],a
		mv	ba,0
exit:		ret
		endl
;
wakeup:		local
		popu	a
		popu	i
		call	!timer_wakeup
		mv	ba,0
		jrnc	l1
		mv	ba,-1
l1:		ret
		endl
;
pstat:		local
		popu	x
		mv	a,x
		call	!pid2adrs
		mv	ba,-1
		jrc	exit
		inc	ba
		mv	a,[x-11]
		and	a,1
exit:		ret
		endl
;
getram:		local
		popu	x
		mv	a,x
		mv	($ed),a
		mv	a,(px+0)
		ret
		endl
;
setram:		local
		popu	y
		popu	x
		mv	a,x
		mv	($ed),a
		mv	a,y
		mv	(px+0),a
		ret
		endl
;
key:		local
		popu	x
		pushu	imr
		mv	ba,x
		ex	a,b
		and	a,7
		and	(!key_strobe_h),$f8
		or	(!key_strobe_h),a
		mv	a,b
		mv	(!key_strobe_l),a
		mv	a,(!key_sense)
		popu	imr
		ret
		endl
;
beep:		local
		popu	x
		popu	y
		pushu	imr
		mv	ba,y
loop:		mv	i,ba
		or	(!system_ctrl_reg),$10
		wait
		mv	i,ba
		and	(!system_ctrl_reg),$ef
		wait
		dec	x
		jrnz	loop
		popu	imr
		ret
		endl
;
abs:		local
		popu	x
		mv	ba,x
		ex	a,b
		test	a,$80
		ex	a,b
		jrz	exit
		mv	i,0
		sub	i,ba
		mv	ba,i
exit:		ret
		endl
;
sgn:		local
		popu	x
		mv	ba,x
		ex	a,b
		test	a,$80
		jrz	l1
		mv	ba,-1
		ret
l1:		cmpw	(bp+!src_zero),ba
		mv	ba,0
		jrz	exit
		inc	ba
exit:		ret
		endl
;
latest:		local
		mv	a,[!latest_prcs]
		ret
		endl
;
locate:		local
		mvp	(bp+!src_work1),[u++]
		mvp	(bp+!src_work2),[u++]
		mv	(bp+!src_work2+1),(bp+!src_work1)
		mvw	[!scrn_cur_x],(bp+!src_work2)
		ret
		endl
;
timerf_count:	local
		pushu	imr
		mv	x,[!fast_timer]
		cmpp	(!src_zero+$70),x
		jrz	_timerf
		dec	x
		mv	[!fast_timer],x
		jrnz	_timerf
		mv	a,[!timerf_pid]
		call	!timer_wakeup
_timerf:	popu	imr
		jpf	!timerf
		endl
;
timers_count:	local
		pushu	imr
		mv	x,[!slow_timer]
		cmpp	(!src_zero+$70),x
		jrz	_timers
		dec	x
		mv	[!slow_timer],x
		jrnz	_timers
		mv	a,[!timers_pid]
		call	!timer_wakeup
_timers:	popu	imr
		jpf	!timers
		endl
;
kill:		local
		popu	x
		mv	a,x
		call	!pid2adrs
		mv	ba,-1
		jrc	exit
		mv	a,[x-11]
		or	a,4
		mv	[x-11],a
		mv	ba,0
exit:		ret
		endl
;
pid2adrs:	local
		mv	x,(!prcs_head+$70)
l1:		mv	il,[x-10]
		sub	il,a
		jrz	l2
		mv	x,[x]
		cmpp	(!prcs_head+$70),x
		jrnz	l1
		sc
l2:		ret
		endl
;
timer_wakeup:	local
		call	!pid2adrs
		jrc	exit
		mv	a,[x-11]
		and	a,$fe
		mv	[x-11],a
		rc
exit:		ret
		endl
;
alarmf:		local
		popu	x
		cmpp	(bp+!src_zero),x
		jrz	l1
		mv	[!fast_timer],x
		mv	a,[(bp+!prcs_head)-10]
		mv	[!timerf_pid],a
l1:		mv	x,[!fast_timer]
		ret
		endl
;
alarms:		local
		popu	x
		cmpp	(bp+!src_zero),x
		jrz	l1
		mv	[!slow_timer],x
		mv	a,[(bp+!prcs_head)-10]
		mv	[!timers_pid],a
l1:		mv	x,[!slow_timer]
		ret
		endl
;
close_all:	local
		mv	x,!handle_table + 3	;Close all handle except STD device
		mv	(bp+!src_work1),16-3
		mv	(bp+!src_work2),3
l6:		mv	a,[x++]
		cmp	a,$ff
		jrz	l5
		mv	(!cl),(bp+!src_work2)
		mv	il,2
		pushu	x
		callf	!fcntl
		popu	x
l5:		inc	(bp+!src_work2)
		dec	(bp+!src_work1)
		jrnz	l6
		ret
		endl
;
terminate:	local
		call	!close_all
		and	($fb),$7f
		mv	s,[!s_stack]
		mv	u,[!u_stack]
		call	!interrupt2
		or	($fb),$80
		mv	($ec),[!base]
		rc
		retf
		endl
;
gets:		local
		popu	x
		mv	(bp+!key_top),x
		mv	(bp+!key_pos),x
		mvw	(bp+!org_x),[!scrn_cur_x]
		mvw	(bp+!max_x),[!scrn_max_x]
;
		mvw	(bp+!cur_x),(bp+!org_x)
;
l0:		cmp	(bp+!cur_x),(bp+!max_x)
		jrc	l1
		mv	(bp+!cur_x),0
		inc	(bp+!cur_y)
l1:		cmp	(bp+!cur_y),(bp+!max_y)
		jrc	l2
		mvw	(!cx),0			;Scroll up one line
		mv	il,$47
		mvw	(!bx),0
		mv	a,1
		callf	!iocs
		mv	(bp+!cur_y),(bp+!max_y)
		dec	(bp+!cur_y)
		sub	(bp+!org_y),1
		jrnc	l2
		mvw	(bp+!org_x),0
l2:		mvw	(!cx),0			;Set cursor position
		mv	il,$44
		mvw	(!bx),(bp+!cur_x)
		callf	!iocs
		mvw	(!cx),0			;Set cursor mark
		mv	il,$45
		mv	a,$2a			;Full box & blink
		callf	!iocs
l3:		callf	getkey			;Read key
		jrc	l3
		cmp	a,0
		jrnz	l3_1			;Skip 2byte code
		callf	getkey
		jr	l3
l3_1:		cmp	a,$0d
		jrz	exit
		cmp	a,$1a
		jrz	exit
		cmp	a,$08
		jrz	back_space
		cmp	a,$1d
		jrnz	l4
back_space:	cmpp	(bp+!key_top),(bp+!key_pos)
		jrz	l3
		mv	x,(bp+!key_pos)
		dec	x
		mv	(bp+!key_pos),x
		cmp	(bp+!cur_x),0
		jrnz	l5
		mv	(bp+!cur_x),(bp+!max_x)
		sub	(bp+!cur_y),1
		jrnc	l5
		inc	(bp+!cur_y)
l5:		dec	(bp+!cur_x)		;Write SPC
		mv	a,' '
		callf	putc
		jr	l0
l4:		cmp	a,$0c
		jrnz	l6
		mvw	(bp+!cur_x),(bp+!org_x)
		mv	x,(bp+!key_pos)
		mv	y,(bp+!key_top)
		sub	x,y
		mv	(bp+!key_pos),y
		mv	ba,x
		ex	a,b
		cmp	a,0
		mv	a,b
		jrz	l7
		mv	a,$ff
l7:		mvw	(!cx),0
		mv	il,$52
		mvw	(!bx),(bp+!cur_x)
		callf	!iocs
		jr	l0
l6:		cmp	a,$20
		jrc	l3
		cmp	a,$7f
		jrz	l3
		mv	x,(bp+!key_pos)
		mv	[x++],a
		mv	(bp+!key_pos),x
		callf	putc
		inc	(bp+!cur_x)
		jr	l0
getkey:		mv	il,5
		mv	(!cl),1
		mv	a,1
		jpf	!fcntl
putc:		mvw	(!cx),0
		mv	il,$41
		mvw	(!bx),(bp+!cur_x)
		jpf	!iocs
exit:		mv	x,(bp+!key_pos)
		mv	il,0
		mv	[x++],il
		mv	x,0
		mv	(bp+!errnum),$0c
		mvw	[!scrn_cur_x],(bp+!cur_x)
		cmp	a,$1a
		jrz	l10
		mv	x,(bp+!key_top)
l10:		ret
		endl
;
fgets:		local
		popu	x
		mv	(bp+!obj_adr),x
		mv	(bp+!src_work2),x
		popu	x
		mv	(bp+!src_work1),x
l2:		mv	il,5
		mv	(!cl),(bp+!src_work1)
		mv	a,1
		callf	!fcntl
		jrnc	l1
error:		mv	(bp+!errnum),a
		mv	x,0
		ret
l1:		mv	il,a
		mv	a,b
		cmp	a,1
		mv	a,$0c
		jrnz	error
		mv	a,il
		mv	x,(bp+!src_work2)
		mv	[x++],a
		mv	(bp+!src_work2),x
		cmp	a,$0a
		jrnz	l2
		mv	a,0
		mv	[x],a
		mv	x,(bp+!obj_adr)
		ret
		endl
;
fscanf:		local
		pushu	x
		mv	y,[--x]
		pushu	y
		mv	x,!buffer
		pushu	x
		call	!fgets
		inc	x
		dec	x
		jrz	error
		popu	y
		pushu	x
		mv	[--y],x
		popu	x
		call	!sscanf
		mv	b,a
		mv	a,0
		ex	a,b
		ret
error:		popu	x
		mv	u,x
		mv	ba,-1
		ret		
		endl
;
scanf:		local
		pushu	x
		mv	x,!buffer
		pushu	x
		call	!gets
		inc	x
		dec	x
		jrz	l1
		mv	(bp+!src_work1),x
		popu	x
		pushu	x
		call	!sscanf!_sscanf
		mv	b,a
		mv	a,0
		ex	a,b
		ret
l1:		popu	x
		mv	u,x
		mv	ba,-1
		ret
		endl
;
sscanf:		local
		pushu	x
		mvp	(bp+!src_work1),[--x]
_sscanf:	mvp	(bp+!src_work2),[--x]
		mv	(bp+!obj_adr),x
		mv	(bp+!var_type),0
l3:		mv	x,(bp+!src_work2)
		mv	a,[x++]
		cmp	a,0
		jrz	exit
		mv	(bp+!src_work2),x
		cmp	a,'%'
		jrnz	l1
		mv	a,[x]
		or	a,$20
		cmp	a,'d'
		jrnz	l2
		mvp	[--u],(bp+!src_work1)
		call	!atod
l5:		mv	(bp+!src_work1),y
		cmp	a,0
		jrz	exit
		pushu	x
		mv	x,(bp+!obj_adr)
		mv	y,[--x]
		mv	(bp+!obj_adr),x
		popu	x
		mv	[y++],x
		mv	x,(bp+!src_work2)
		inc	x
		mv	(bp+!src_work2),x
		inc	(bp+!var_type)
		jr	l3
l2:		cmp	a,'x'
		jrnz	l4
		mvp	[--u],(bp+!src_work1)
		call	!atox
		jr	l5
l4:		cmp	a,'c'
		jrnz	l6
		mv	y,(bp+!src_work1)
		mv	a,0
		mv	b,a
		mv	a,[y++]
		mv	x,a
		jr	l5
l6:		cmp	a,'s'
		jrnz	exit
		mv	y,(bp+!src_work1)
		mv	x,(bp+!obj_adr)
		mv	x,[--x]
		pushu	x
		pushu	y
		call	!strcpy
		inc	(bp+!var_type)
exit:		popu	x
		mv	u,x
		mv	a,(bp+!var_type)
		ret
l1:		mv	il,a
		mv	y,(bp+!src_work1)
l8:		mv	a,[y++]
		cmp	a,0
		jrz	exit
		sub	a,il
		jrnz	l8
		dec	y
		mv	(bp+!src_work1),y
		jr	l3
		endl
;
atod:		local
		popu	y
		mv	a,0
		mv	b,a
		mv	x,0
		mv	il,0
l1:		mv	a,[y++]
		cmp	a,0
		jrz	exit
		cmp	a,'-'
		jrnz	l2
		mv	il,1
		mv	a,[y++]
		jr	l3
l2:		cmp	a,'0'
		jrc	l1
		cmp	a,'9'+1
		jrnc	l1
l3:		cmp	a,'0'
		jrc	exit
		cmp	a,'9'+1
		jrnc	exit
		pushu	y
		add	x,x
		mv	y,x
		add	x,x
		add	x,x
		add	x,y
		sub	a,'0'
		add	x,a
		mv	a,1
		mv	b,a
		popu	y
		mv	a,[y++]
		jr	l3
exit:		dec	y
		pushu	y
		dec	il
		jrnz	exit1
		call	!m_pnt
exit1:		popu	y
		mv	a,b
		ret
		endl
;
atox:		local
		popu	y
		mv	a,0
		mv	b,a
		mv	x,0
		mv	il,0
l1:		mv	a,[y++]
		cmp	a,0
		jrz	!atod!exit
		cmp	a,'-'
		jrnz	l2
		mv	il,1
		mv	a,[y++]
		jr	l3
l2:		call	ishex
		jrc	l1
l3:		call	ishex
		jrc	!atod!exit
		add	x,x
		add	x,x
		add	x,x
		add	x,x
		sub	a,'0'
		cmp	a,10
		jrc	l4
		sub	a,7
l4:		add	x,a
		mv	a,1
		mv	b,a
		mv	a,[y++]
		jr	l3
ishex:		cmp	a,'0'
		jrc	no_hex
		cmp	a,'9'+1
		jrc	hex
		and	a,$df
		cmp	a,'A'
		jrc	no_hex
		cmp	a,'F'+1
		jrc	hex
no_hex:		sc
		ret
hex:		rc
		ret
		endl
;
strcpy:		local
		popu	y
		popu	x
		pushu	x
l1:		mv	a,[y++]
		mv	[x++],a
		cmp	a,0
		jrnz	l1
		popu	x
		ret
		endl
;
strcat:		local
		popu	y
		popu	x
		pushu	x
l1:		mv	a,[x++]
		cmp	a,0
		jrnz	l1
		dec	x
l2:		mv	a,[y++]
		mv	[x++],a
		cmp	a,0
		jrnz	l2
		popu	x
		ret
		endl
;
_fname:		local
		popu	y
		popu	x
		mv	(bp+!src_work1),0
l3:		mv	il,0
		mv	(bp+!src_work2),y
l1:		mv	(bp+!src_pnt),y
		mv	a,[y++]
		mv	(bp+!src_work1+1),a
		cmp	a,0
		jrz	f_end
		cmp	a,' '
		jrz	f_end
		cmp	a,$0d
		jrz	f_end
		cmp	a,'.'
		jrz	f_end
		cmp	a,':'
		jrz	drive
		inc	il
		jr	l1
drive:		test	(bp+!src_work1),2
		jrnz	error			;Drive name was already written
		mv	a,il
		cmp	a,0
		jrz	error			;No drive name specified
		cmp	a,6
		jrnc	error			;Too long drive name
		or	(bp+!src_work1),2
		mv	y,(bp+!src_work2)
l2:		mv	a,[y++]			;Write drive name
		mv	[x++],a
		cmp	a,':'
		jrnz	l2
		jr	l3
f_end:		test	(bp+!src_work1),2
		jrnz	l4
		mv	y,!default_drive
l5:		mv	a,[y++]			;Write default drive name
		mv	[x++],a
		cmp	a,':'
		jrnz	l5
		or	(bp+!src_work1),2
l4:		mv	y,(bp+!src_work2)
		test	(bp+!src_work1),1
		jrnz	l6
		pushu	y
		pushu	x
		mv	x,space
		pushu	x
		call	!strcpy
		popu	y
		mv	a,il
		cmp	a,9
		jrnc	error			;Too long primaly name
		or	(bp+!src_work1),1
		cmp	a,0
		jrz	l11			;No primaly name specified
		pushu	x
l7:		mv	a,[y++]			;Write primaly name
		mv	[x++],a
		dec	il
		jrnz	l7
		popu	x
l11:		inc	y
		mv	a,9
		add	x,a
l6:		mv	a,(bp+!src_work1+1)
		cmp	a,'.'
		mv	a,il
		jrz	l8
		cmp	a,4
		jrnc	error			;Too long extention
l9:		cmp	a,0
		jrz	l10
		mv	il,[y++]
		mv	[x++],il
		dec	a
		jr	l9
l10:		mv	a,1
		ret
l8:		cmp	a,0
		jrz	l3
error:		mv	a,0
		ret
space:		db	'        .   ',0
		endl
;
getc:		local
		mv	(!cl),1
		jr	!fgetc!l1
		endl
;
fgetc:		local
		popu	x
		mv	(!cl),x
l1:		mv	il,5
		mv	a,1
		callf	!fcntl
		jrnc	exit
error:		mv	(bp+!errnum),a		;error
		mv	ba,-1
		ret
exit:		mv	(bp+!src_work1),ba
		cmp	(bp+!src_work1+1),1
		mv	a,$0c
		jrnz	error
		dec	(bp+!src_work1+1)
		mv	ba,(bp+!src_work1)
		ret
		endl
;
putc:		local
		mv	(!cl),0
		popu	x
		mv	a,x
		jr	!fputc!l1
		endl
;
fputc:		local
		popu	x
		mv	a,x
		popu	x
		mv	(!cl),x
l1:		mv	il,6
		callf	!fcntl
		jrnc	exit
error:		mv	(bp+!errnum),a		;error
		mv	ba,-1
		ret
exit:		mv	a,b
		cmp	a,1
		mv	a,$0c
		jrnz	error
		mv	ba,0
		ret
		endl
;
puts:		local
		popu	x
		pushu	x
		pushu	x
		call	!strlen
		mv	y,x
		popu	x
		mv	il,4
		mv	(!cl),0
		callf	!fcntl
		jrnc	exit
error:		mv	(bp+!errnum),a
		mv	ba,-1
		ret
exit:		mv	x,newline
		mv	y,u
		pushu	x
		mv	x,y
		call	!printf
		mv	ba,0
		ret
newline:	db	13,10,0
		endl
;
fputs:		local
		popu	x
		pushu	x
		pushu	x
		call	!strlen
		mv	y,x
		popu	x
		mvp	(!cl),[u++]
		mv	il,4
		callf	!fcntl
		jrnc	exit
		mv	(bp+!errnum),a
		mv	ba,-1
		ret
exit:		mv	ba,0
		ret
		endl
;
fcreat:		mv	(bp+!var_type),0
		jr	_fopen
fopen:		mv	(bp+!var_type),1
_fopen:		local
		popu	x
		mv	(bp+!var_size),x
		popu	y
		mv	x,!buffer
		pushu	x
		pushu	y
		call	!_fname
		cmp	a,0
		mv	a,1
		jrz	error
		mv	il,(bp+!var_type)
		mv	a,(bp+!var_size)
		mv	x,!buffer
		callf	!fcntl
		jrc	error
		mv	b,a
		mv	a,(!cl)
		ret
error:		mv	(bp+!errnum),a
		mv	ba,-1
		ret
		endl
;
fclose:		local
		popu	x
		mv	(!cl),x
		mv	il,2
entry:		callf	!fcntl
		jrc	!_fopen!error
		mv	ba,0
		ret		
		endl
;
fseek:		local
		popu	x
		mv	a,x
		mvp	(!si),[u++]
		test	(!si+2),$08
		jrz	l1
		or	(!si+2),$f0
l1:		mvp	(!cl),[u++]
		mv	il,9
		callf	!fcntl
		jrc	error
		mv	x,(!si)
		ret
error:		mv	(bp+!errnum),a
		mv	x,-1
		ret
		endl
;
fread:		local
		mv	il,3
entry:		popu	y
		popu	x
		mvp	(!cl),[u++]
		mv	a,1
		callf	!fcntl
		jrc	!fseek!error
		mv	x,y
		ret
		endl
;
fwrite:		local
		mv	il,4
		jr	!fread!entry
		endl
;
remove:		local
		popu	y
		mv	x,!buffer
		pushu	x
		pushu	y
		call	!_fname
		cmp	a,0
		mv	a,1
		jrz	!_fopen!error
		mv	il,$e
		mv	x,!buffer
		jr	!fclose!entry
		endl
;
_fcntl:		local
		popu	x
		mv	(bp+!src_work1),x
		call	!pre_iocs
		callf	!fcntl
		endl
;
post_iocs:	local
		mv	[(bp+!src_work1)+4],x
		mv	x,(bp+!src_work1)
		mv	[x+7],y
		mv	[x+2],i
		mv	[x],ba
		mv	il,12
		mvl	[(bp+!src_work1)+10],(!bl)
		jrc	error
		mv	ba,0
		ret
error:		mv	ba,-1
		ret
		endl
;
pre_iocs:	local
		mv	il,12
		mvl	(!bl),[(bp+!src_work1)+10]
		mv	ba,[x]
		mv	i,[x+2]
		mv	y,[x+7]
		mv	x,[x+4]
		ret
		endl
;
_iocs:		local
		popu	x
		mv	(bp+!src_work1),x
		call	!pre_iocs
		callf	!iocs
		jr	!post_iocs
		endl
;
sbrk:		local
		popu	x
		mv	y,(bp+!obj_pnt)
		add	x,y
		mv	(bp+!src_work1),x
		mv	y,[(bp+!productive_prcs)-3]
		cmpp	(bp+!src_work1),y
		jrnc	error
		mv	y,(bp+!obj_pnt)
		mv	(bp+!obj_pnt),x
		mv	[(bp+!productive_prcs)-9],x
		mv	a,32
		sub	y,a
		mv	x,y
		ret
error:		mv	x,-1
		ret
		endl
;
rand:		local
		call	_rand
		mv	[--u],(bp+!random+1)
		call	_rand
		mv	a,(bp+!random+1)
		and	a,$7f
		mv	b,a
		popu	a
		ret
_rand:		mvp	(bp+!src_work1),(bp+!random)
		mvp	(bp+!src_work2),19537
		call	!mul20
		inc	x
		mv	(bp+!random),x
		ret
		endl
;
srand:		local
		popu	x
		mv	(bp+!random),x
		ret
		endl
;
kscan:		local
		mvw	(!cl),1
		mv	il,$43
		mv	a,0
		callf	!iocs
		dec	il
		jrz	key_pressed
		mv	ba,-1
key_pressed:	ret
		endl
;
perror:		local
		mv	a,(bp+!errnum)
		ret
		endl
;
mul16:		local
		mv	i,(bp+!src_work2)
		mv	(bp+!src_work2),$80
		mv	ba,0
l1_1:		shr	(bp+!src_work1)
		jrnc	no_add_1
		add	ba,i
no_add_1:	add	i,i
		ror	(bp+!src_work2)
		jrnc	l1_1
l1_2:		shr	(bp+!src_work1+1)
		jrnc	no_add_2
		add	ba,i
no_add_2:	add	i,i
		ror	(bp+!src_work2)
		jrnc	l1_2
		ret
		endl
;
mul20:		local
		mv	y,(bp+!src_work2)
		mv	a,$80
		mv	x,0
l1_1:		shr	(bp+!src_work1)
		jrnc	no_add_1
		add	x,y
no_add_1:	add	y,y
		ror	a
		jrnc	l1_1
l1_2:		shr	(bp+!src_work1+1)
		jrnc	no_add_2
		add	x,y
no_add_2:	add	y,y
		ror	a
		jrnc	l1_2
		mv	a,$08
l1_3:		shr	(bp+!src_work1+2)
		jrnc	no_add_3
		add	x,y
no_add_3:	add	y,y
		ror	a
		jrnc	l1_3
		ret
		endl
;
div16:		local
		call	!_div16
		test	(bp+!src_work1+2),2
		jrz	l1
l2:		mv	i,0
		sub	i,ba
		mv	ba,i
l1:		ret
		endl
;
mod16:		local
		call	!_div16
		mv	ba,(bp+!src_work1)
		test	(bp+!src_work1+2),1
		jrnz	!div16!l2
		ret
		endl
;
_div16:		local
		mv	x,0
		mv	ba,(bp+!src_work1)
		mv	i,ba
		add	ba,ba
		jrnc	l1
		mv	(bp+!src_work1+2),3	;Work1 is negative 
		mv	ba,0
		sub	ba,i
		mv	i,ba
l1:		mv	(bp+!src_work1),i
		mv	i,(bp+!src_work2)
		inc	i
		dec	i
		jrz	!div_by_0
		mv	ba,i
		add	i,i
		jrnc	l4
		xor	(bp+!src_work1+2),2	;Work2 is negative
		mv	i,0
		sub	i,ba
		mv	ba,i
l4:		mv	(bp+!src_work2),ba
		add	ba,ba
		inc	x
		cmpw	(bp+!src_work1),ba
		jrnc	l4
		mv	ba,0
l6:		add	ba,ba
		cmpw	(bp+!src_work1),(bp+!src_work2)
		jrc	l5
		inc	ba
		mv	il,2
		sbcl	(bp+!src_work1),(bp+!src_work2)
l5:		rc
		shr	(bp+!src_work2+1)
		shr	(bp+!src_work2)
		dec	x
		jrnz	l6
		ret
		endl
;
div20:		local
		mv	a,1
		mv	x,(bp+!src_work2)
		inc	x
		dec	x
		jrz	!div_by_0
l4:		mv	(bp+!src_work2),x
		cmpp	(bp+!src_work1),x
		jrc	l4_1
		add	x,x
		jrc	l4_1
		inc	a
		jr	l4
l4_1:		mv	x,0
l6:		add	x,x
		cmpp	(bp+!src_work1),(bp+!src_work2)
		jrc	l5
		inc	x
		mv	il,3
		sbcl	(bp+!src_work1),(bp+!src_work2)
l5:		rc
		shr	(bp+!src_work2+2)
		shr	(bp+!src_work2+1)
		shr	(bp+!src_work2)
		dec	a
		jrnz	l6
		ret
		endl
;
div_by_0:	local
		mv	y,msg
		jp	!make_frame!l2
msg:		db	'Division by zero',0
		endl
user_break:	local
		test	(!system_stat_reg),8
		jrz	exit
entry:		mv	y,msg
		jp	!make_frame!l2
msg:		db	'User break',0
exit:		ret
		endl
;
mod20:		local
		call	!div20
		mv	x,(bp+!src_work1)
		ret
		endl
;
and16:		local
		and	(bp+!src_work1),(bp+!src_work2)
		and	(bp+!src_work1+1),(bp+!src_work2+1)
		mv	ba,(bp+!src_work1)
		ret
		endl
;
and20:		local
		and	(bp+!src_work1),(bp+!src_work2)
		and	(bp+!src_work1+1),(bp+!src_work2+1)
		and	(bp+!src_work1+2),(bp+!src_work2+2)
		mv	x,(bp+!src_work1)
		ret
		endl
;
or16:		local
		or	(bp+!src_work1),(bp+!src_work2)
		or	(bp+!src_work1+1),(bp+!src_work2+1)
		mv	ba,(bp+!src_work1)
		ret
		endl
;
or20:		local
		or	(bp+!src_work1),(bp+!src_work2)
		or	(bp+!src_work1+1),(bp+!src_work2+1)
		or	(bp+!src_work1+2),(bp+!src_work2+2)
		mv	x,(bp+!src_work1)
		ret
		endl
;
xor16:		local
		xor	(bp+!src_work1),(bp+!src_work2)
		xor	(bp+!src_work1+1),(bp+!src_work2+1)
		mv	ba,(bp+!src_work1)
		ret
		endl
;
xor20:		local
		xor	(bp+!src_work1),(bp+!src_work2)
		xor	(bp+!src_work1+1),(bp+!src_work2+1)
		xor	(bp+!src_work1+2),(bp+!src_work2+2)
		mv	x,(bp+!src_work1)
		ret
		endl
;
shl16:		local
		mv	ba,(bp+!src_work1)
		cmp	(bp+!src_work2),0
		jrz	exit
l1:		add	ba,ba
		dec	(bp+!src_work2)
		jrnz	l1
exit:		ret
		endl
;
shl20:		local
		mv	x,(bp+!src_work1)
		cmp	(bp+!src_work2),0
		jrz	exit
l1:		add	x,x
		dec	(bp+!src_work2)
		jrnz	l1
exit:		ret
		endl
;
shr16:		local
		cmp	(bp+!src_work2),0
		jrz	exit
l1:		shr	(bp+!src_work1+1)
		shr	(bp+!src_work1)
		dec	(bp+!src_work2)
		jrnz	l1
exit:		mv	ba,(bp+!src_work1)
		ret
		endl
;
shr20:		local
		cmp	(bp+!src_work2),0
		jrz	exit
l1:		shr	(bp+!src_work1+2)
		shr	(bp+!src_work1+1)
		shr	(bp+!src_work1)
		dec	(bp+!src_work2)
		jrnz	l1
exit:		mv	x,(bp+!src_work1)
		ret
		endl
;
modify_int:	mv	x,$8000
		add	ba,x
		add	i,x
		ret
clear_work:	mvw	(bp+!src_work1+1),0
		mvw	(bp+!src_work2+1),0
		ret
v_adr1:		mv	x,(bp+!src_local)
		add	x,a
		ret
v_adr2:		mv	x,(bp+!src_local)
		add	x,ba
		ret
v_adr3:		mv	y,(bp+!src_local)
		add	x,y
		ret
m_char:		mv	il,a
		mv	a,0
		sub	a,il
		ret
m_int:		mv	i,ba
		mv	ba,0
		sub	ba,i
		ret
m_pnt:		mv	y,x
		mv	x,0
		sub	x,y
		ret
n_char:		local
		cmp	a,0
		jrz	zero
		mv	a,-1
zero:		inc	a
		ret
		endl
n_int:		local
		cmpw	(bp+!src_zero),ba
		jrz	zero
		mv	ba,-1
zero:		inc	ba
		ret
		endl
n_pnt:		local
		cmpp	(bp+!src_zero),x
		jrz	zero
		mv	x,-1
zero:		inc	x
		ret
		endl
;
strlen:		local
		popu	y
		mv	x,-1
l1:		inc	x
		mv	a,[y++]
		cmp	a,0
		jrnz	l1
		ret
		endl
;
fprintf:	local
		mvp	(bp+!obj_adr),[--x]
		mv	y,!buffer
		mv	[x++],y
		call	!sprintf
		pushu	a
		mvp	[--u],(bp+!obj_adr)
		mv	x,!buffer
		pushu	x
		call	!fputs
		inc	ba
		jrnz	exit
		popu	a
		mv	ba,-1
		ret
exit:		mv	a,0
		mv	b,a
		popu	a
		ret
		endl
;
printf:		local
		call	printf_
		pushu	a
		mv	x,!buffer
		pushu	x
		call	!strlen
		mv	y,x
		mv	x,!buffer
		mv	il,4
		mv	(!cl),0
		callf	!fcntl
		jrc	error
		mv	a,0
		mv	b,a
		popu	a
		ret
error:		popu	a
		mv	ba,-1
		ret
printf_:	mv	(bp+!var_type),0
		and	($fb),$7f
		pushs	x
		mv	u,x
		mv	y,!buffer
		jr	!sprintf!sprintf_
		endl
;
sprintf:	local
		mv	(bp+!var_type),0
		and	($fb),$7f
		pushs	x			;save U-reg
		mv	u,x
		mv	y,[--u]			;y <- ^buffer
sprintf_:	mv	x,[--u]			;x <- ^format
l1:		mv	a,[x++]
		cmp	a,0
		jrz	exit
		cmp	a,'%'
		jrz	l4
		mv	[y++],a
		jrnz	l1
exit:		mv	[y++],a
		mv	u,[s++]
		or	($fb),$80
		mv	a,(bp+!var_type)
		ret
;
l4:		mv	a,[x++]			;'%' controll char.
		cmp	a,0
		jrz	exit
		mv	i,0
l5:		cmp	a,'0'			;set max columns#
		jrc	l6
		cmp	a,'9'+1
		jrnc	l6
		pushs	a
		add	i,i
		pushs	i
		add	i,i
		add	i,i
		pops	ba
		add	i,ba
		pops	a
		sub	a,'0';
		add	i,a
		mv	a,[x++]
		cmp	a,0
		jrnz	l5
		jr	exit
l6:		pushs	x			;analize CTRL char.
		mvp	(bp),[--u]
		or	a,$20
		cmp	a,'d'
		jrnz	l7
;
		mv	(bp+2),0		;'d'
		test	(bp+1),$80
		jrz	l8
		mv	ba,(bp)
		pushs	i
		mv	i,0
		sub	i,ba	
		mv	(bp),i
		pops	i
		mv	a,'-'
		mv	[y++],a
		mv	a,1
		call	dsub
l8:		call	tsub
		jr	fill_
;
l7:		cmp	a,'u'
		jrz	l8			;'u'
		cmp	a,'x'
		jrnz	l9
		pushs	i			;'x'
		mv	il,0
		mvp	(bp+3),$10
hex_1:		cmpp	(bp),(bp+3)
		jrc	hex_2
		call	hsub
		pushs	a
		inc	il
		mv	a,4
hex_3:		rc
		shr	(bp+2)
		shr	(bp+1)
		shr	(bp)
		dec	a
		jrnz	hex_3
		jr	hex_1
hex_2:		call	hsub
		pushs	a
		inc	il
		mv	a,il
		mv	b,a
hex_4:		pops	a
		add	a,'0'
		mv	[y++],a
		dec	il
		jrnz	hex_4
		pops	i
		mv	a,b
		call	dsub
		jr	fill_
;
l9:		cmp	a,'c'
		jrnz	l10
		mv	[y++],(bp)		;'c'
		mv	a,1
		call	dsub
		jr	fill_
;
l10:		cmp	a,'s'
		jrnz	fill_0
		mv	x,(bp)			;'s'
l10_1:		mv	a,[x++]
		cmp	a,0
		jrz	fill_
		mv	[y++],a
		mv	a,1
		call	dsub
		jr	l10_1
;
fill_0:		dec	(bp+!var_type)
fill_:		inc	(bp+!var_type)
		mv	a,' '			;fill blanks
		inc	i
fill_1:		dec	i
		jrz	fill_2
		mv	[y++],a
		jr	fill_1
fill_2:		pops	x
		jr	l1
;
tsub:		mv	a,0
		pushs	x
		pushs	i
tsub_5:		mv	x,10
		cmpp	(bp),x
		jrc	tsub_4
		mvp	(bp+3),$a0000
		mv	x,0
tsub_3:		mv	il,3
		add	x,x
		sbcl	(bp),(bp+3)
		jrnc	tsub_2
		mv	il,3
		adcl	(bp),(bp+3)
		jr	tsub_1
tsub_2:		inc	x
tsub_1:		rc
		shr	(bp+5)
		shr	(bp+4)
		shr	(bp+3)
		cmp	(bp+3),5
		jrnz	tsub_3
		mv	(bp+3),x
		exp	(bp),(bp+3)
		mv	[--s],(bp+3)
		inc	a
		jr	tsub_5
tsub_4:		mv	[--s],(bp)
		inc	a
		mv	b,a
		mv	il,a
tsub_6:		pops	a
		add	a,'0'
		mv	[y++],a
		dec	il
		jrnz	tsub_6
		pops	i
		pops	x
		mv	a,b
dsub:		sub	i,a
		jrnc	dsub_1
		mv	i,0
dsub_1:		ret
hsub:		mv	a,(bp)
		and	a,$f
		cmp	a,10
		jrc	hsub_1
		add	a,7
hsub_1:		ret
;
		endl
;
upcase:		local
		popu	a
		popu	i
		cmp	a,'a'
		jrc	exit
		cmp	a,'z'+1
		jrnc	exit
		sub	a,$20
exit:		ret
		endl
;
isdigit:	local
		popu	a
		popu	i
		cmp	a,'0'
		jrc	nodigit
		cmp	a,'9'+1
		jrnc	nodigit
digit:		or	a,1
		ret
nodigit:	and	a,0
		ret
		endl
;
isalpha:	local
		call	!upcase
		cmp	a,'A'
		jrc	!isdigit!nodigit
		cmp	a,'Z'+1
		jrnc	!isdigit!nodigit
		jr	!isdigit!digit
		endl
;
strcmp:		local
		popu	y
		popu	x
l1:		mv	a,[x++]
		mv	il,[y++]
		sub	il,a
		jrnz	exit
		cmp	a,0
		jrnz	l1
		jr	!isdigit!digit
exit:		cmp	a,0
		jrz	!isdigit!nodigit
		mv	a,[x++]
		jr	exit
		endl
;
miditx:		local
;
midi_term:	equ	$f4
on:		equ	4
off:		equ	$fb
;
		popu	x
		mv	(bp+!src_work1),[x++]
midi_trans:	pushu	imr
		mv	a,[x++]
		or	(midi_term),on
		mv	il,7
		wait
		mv	(bp+!src_work2),8
trans:		ror	a
		jrc	trans1
		nop
		or	(midi_term),on
		jr	trans2
trans1:		and	(midi_term),off
		jr	trans2
trans2:		mv	il,1
		wait
		dec	(bp+!src_work2)
		jrnz	trans
		mv	il,3
		wait
		and	(midi_term),off
		mv	il,$ff
		wait
;
		popu	imr
		dec	(bp+!src_work1)
		jrnz	midi_trans
		ret
		endl
;
atof:		local
		popu	x
		popu	y
		pushu	y
		pushu	y
		mv	il,15
		mv	a,0
l1:		mv	[y++],a
		dec	il
		jrnz	l1
		popu	y
		mv	a,1
		mv	[y++],a
		mv	ba,[y++]
l3:		mv	a,[x++]
		cmp	a,0
		jrz	end
		cmp	a,'-'
		jrz	l2
		cmp	a,'0'
		jrc	l3
		cmp	a,'9'+1
		jrnc	l3
		dec	x
l4:		mv	a,[x++]
		cmp	a,'0'
		jrz	l4
		dec	x
		mv	(bp+!src_work1),0
		call	sub
		mv	(bp+!src_work1+1),(bp+!src_work1)
		cmp	a,0
		jrz	exit
		cmp	a,'.'
		jrnz	expo
		call	sub
		cmp	a,0
		jrz	exit
expo:		or	a,$20
		cmp	a,'e'
		jrnz	exit
		pushu	x
		call	!atod
		mv	a,x
		mv	il,(bp+!src_work1+1)
		add	a,il
		mv	(bp+!src_work1+1),a
exit:		mv	a,(bp+!src_work1+1)
		popu	x
		dec	a
		mv	[x+1],a
		ret
end:		popu	x
		ret
l2:		mv	a,9
		mv	[y-3],a
		jr	l4
sub:		local
		mv	a,[x++]
		cmp	a,'0'
		jrc	exit
		cmp	a,'9'+1
		jrnc	exit
		cmp	(bp+!src_work1),20
		jrnc	l2
		sub	a,'0'
		test	(bp+!src_work1),1
		jrnz	l1
		swap	a
		mv	[y],a
		jr	l2
l1:		mv	il,[y]
		add	il,a
		mv	[y++],il
l2:		inc	(bp+!src_work1)
		jr	..!sub
exit:		ret
		endl
		endl
;
ftoa:		local
		popu	x
		mv	(bp+!src_work1),x
		popu	y
		pushu	y
		mv	a,[x++]
		cmp	a,9
		jrnz	l1
		mv	a,'-'
		mv	[y++],a
l1:		mv	(bp+!src_work2),[x++]
		call	get_valid_digit
		cmp	a,0
		jrnz	non_zero
		mvw	(bp+!src_work2),$100
non_zero:	cmp	(bp+!src_work2),$80
		jrnc	small
		cmp	(bp+!src_work2),20
		jrnc	exp
		inc	(bp+!src_work2)
		cmp	(bp+!src_work2+1),(bp+!src_work2)
		jrnc	l3_1
		mv	(bp+!src_work2+1),(bp+!src_work2)
l3_1:		mv	a,0
l3:		pushu	a
		call	get_digit
		mv	[y++],a
		popu	a
		inc	a
		dec	(bp+!src_work2)
		jrnz	l2
		mv	il,'.'
		mv	[y++],il
l2:		dec	(bp+!src_work2+1)
		jrnz	l3
		jr	exit
small:		sub	a,(bp+!src_work2)
		cmp	a,21
		jrnc	exp
		mv	ba,'.' * 256 + '0'
		mv	[y++],ba
l5:		inc	(bp+!src_work2)
		jrz	l4
		mv	[y++],a
		jr	l5		
l4:		mv	a,0
l6:		pushu	a
		call	get_digit
		mv	[y++],a
		popu	a
		inc	a
		dec	(bp+!src_work2+1)
		jrnz	l6
		jr	exit
exp:		mv	a,0
		call	get_digit
		mv	[y++],a
		mv	a,'.'
		mv	[y++],a
		mv	a,1
l7:		dec	(bp+!src_work2+1)
		jrz	l8
		pushu	a
		call	get_digit
		mv	[y++],a
		popu	a
		inc	a
		jr	l7
l8:		mv	a,[y-1]
		cmp	a,'.'
		jrnz	l11
		dec	y
l11:		mv	a,'E'
		mv	[y++],a
		mv	a,'+'
		cmp	(bp+!src_work2),$80
		jrc	l9
		mv	a,0
		sub	a,(bp+!src_work2)
		mv	(bp+!src_work2),a
		mv	a,'-'
l9:		mv	[y++],a
		mv	(bp+!src_work1),0
		mv	a,(bp+!src_work2)
l10:		inc	(bp+!src_work1)
		sub	a,10
		jrnc	l10
		add	a,'0'+10
		mv	b,a
		mv	a,(bp+!src_work1)
		add	a,'0'-1
		mv	[y++],ba
exit:		mv	a,0
		mv	[y++],a
		popu	x
		ret
;
get_digit:	local
		mv	x,(bp+!src_work1)
		pushu	a
		rc
		shr	a
		add	a,3
		add	x,a
		popu	a
		shr	a
		mv	a,[x]
		jrc	l1
		swap	a
l1:		and	a,15
		add	a,'0'
		ret
		endl
;
get_valid_digit:local
		mv	a,19
l2:		pushu	a
		call	..!get_digit
		cmp	a,'0'
		popu	a
		jrnz	l1
		sub	a,1
		jrnc	l2
l1:		inc	a
		mv	(bp+!src_work2+1),a
		ret
		endl
;
		endl
;
_math1:		local
		popu	x
		mv	a,x
		popu	x
entry:		mv	il,15
		mvl	(bp+0),[x++]
entry2:		mvw	(!cx),9
		mv	il,a
		callf	!iocs
		popu	x
		pushu	x
		mv	il,15
		mvl	[x++],(bp+0)
		popu	x
		jrnc	exit
		mv	x,0
exit:		mv	($ec),$70
		ret
		endl
;
_math2:		local
		popu	x
		mv	a,x
		popu	x
		popu	y
		mv	il,15
		mvl	(bp+15),[y++]
		jr	..!_math1!entry
		endl
;
itof:		local
		call	!abs
		pushs	f
		mv	(bp+1),ba
		mv	(bp+3),0
		mv	a,$7f		
		call	..!_math1!entry2
		jrc	exit
		mv	a,1
		pops	f
		jrz	exit1
		mv	a,9
exit1:		mv	[x],a
exit:		ret
		endl
;
ftoi:		local
		popu	x
		pushu	x
		pushu	imr
		mv	il,15
		mvl	(bp+0),[x++]
		mvw	(!cx),9
		mv	il,$7e
		callf	!iocs
		mv	($ec),$70
		popu	imr
		mv	x,(bp+1)
		pushu	x
		call	!abs
		popu	x
		mv	il,[x]
		dec	il
		jrz	exit
		mv	i,0
		sub	i,ba
		mv	ba,i
exit:		ret
		endl
;
movez:		local
		call	!move
		mv	[y],(bp+!src_zero)
		ret
		endl
;
move:		local
		popu	x
		mv	i,x
		popu	x				;source
		popu	y				;dest
		cmpw	(bp+!src_zero),i
		jrz	exit				;no move
		mv	(bp+!src_work1),x
		cmpp	(bp+!src_work1),y
		jrc	l1
loop1:		mv	a,[x++]				;source is higher than dest
		mv	[y++],a
		dec	i
		jrnz	loop1
exit:		ret
l1:		add	x,i				;dest is higher than source
		add	y,i
		pushu	y
		pushu	x
loop2:		mv	a,[--x]
		mv	[--y],a
		dec	i
		jrnz	loop2
		popu	x
		popu	y
		ret
		endl
;
argp:		local
		mv	x,[!_argp]
		ret
		endl
;
;
		include	screen.s
;
;
buffer:		ds	256
txtbuf:		equ	buffer+128
symbuf:		equ	buffer+64
base:		ds	1
s_stack:	ds	3
u_stack:	ds	3
fork_switch:	ds	1
fork_size:	ds	3
_ir_trap:	ds	3
fast_timer:	ds	3
slow_timer:	ds	3
timerf_pid:	ds	1
timers_pid:	ds	1
latest_prcs:	ds	1
_argp:		ds	3
;
		end
