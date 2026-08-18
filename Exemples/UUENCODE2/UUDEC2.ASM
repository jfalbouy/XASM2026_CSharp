;
;		uudecode    for TY-DOS (PC-E500/1480U)   Ver 1.1
;			Programmed by  E. Kako (JM2WGN)
;
;			Original   is  UNIX(TM)
;
;		USAGE : uudecode filename
;
CR:	equ	0dh
LF:	equ	0ah
F_CALL:	equ	0fffe4h
CR_DRV:	equ	0bfc7dh
;
	org	0be000h
	pre_on
;
	popu	x		;get cmdlin adrs
	mv	a,(0ech)
	mv	[base],a	;BP save
;
	mv	a,0
	mv	[mode],a
	pushu	x
	mv	x,msg1		;(title message)
	call	write
;
	popu	x
	mv	y,fname
	call	arg		;argument check
	jrc	no_arg
	jr	start
;
no_arg:	pushu	x		;cmdlin_btm save
	mv	x,msg2		;(help message)
	call	write
	jp	exit
;
start:	pushu	x		;cmdlin_btm save
	mv	il,0bh
	mv	x,fname
	mv	y,finfo
	mv	a,0
	callf	F_CALL		;file_iocs_12
	jrnc	l_0
;
	mv	x,fname
	mv	a,[x++]
	cmp	a,'C'
	jrnz	f_n_f
	mv	a,[x++]
	cmp	a,'O'
	jrnz	f_n_f
	mv	a,[x++]
	cmp	a,'M'
	jrnz	f_n_f
	mv	a,[x++]
	cmp	a,':'
	jrnz	f_n_f
	jr	l_0
f_n_f:
	mv	x,msg3		;(file not found)
	call	write
	jp	exit
;
l_0:	mv	x,fname		;fopen 'fname' for input as handle0
	mv	il,1
	mv	a,1
	callf	F_CALL		;file_iocs_1
	mv	a,(0d6h)
	mv	[handl0],a
;
	mv	a,1
	mv	[mode],a	;file_open flag
;
;
l_1:
	call	get_line
	jrnc	l_2
;
	mv	x,msg4		;(no begin line)
	call	write
	jp	exit
;
l_2:
	mv	x,line_buf
	mv	a,[x++]
	cmp	a,'b'		;check == "begin "
	jrnz	l_4
	mv	a,[x++]
	cmp	a,'e'
	jrnz	l_4
	mv	a,[x++]
	cmp	a,'g'
	jrnz	l_4
	mv	a,[x++]
	cmp	a,'i'
	jrnz	l_4
	mv	a,[x++]
	cmp	a,'n'
	jrnz	l_4
	mv	a,[x++]
	cmp	a,' '
	jrnz	l_4
;
l_3:	mv	a,[x++]		;check == "644"  ... file attr
	cmp	a,' '
	jrnz	l_3
;
	jr	l_5
;
l_4:	jr	l_1
;
;
;
l_5:
	mv	y,fname
	call	arg
	jrnc	l_6
;
	mv	x,msg5		;(illegal filename)
	call	write
	mv	x,def_file
	jr	l_5
;
l_6:
	mv	x,fname
	call	uppercase
;
	mv	x,fname
	mv	y,file1
	mv	il,21
l_7:	mv	a,[x++]
	mv	[y++],a
	dec	il
	jrnz	l_7
;
	mv	x,fname
	mv	y,fname2
	mv	il,18
l_8:	mv	a,[x++]
	cmp	a,' '
	jrz	l_9
	mv	[y++],a
l_9:	dec	il
	jrnz	l_8
	mv	a,0
	mv	[y++],a
;
	call	dispname
;
	mv	il,0bh		;file exist check
	mv	x,file1
	mv	y,finfo
	mv	a,0
	callf	F_CALL		;file_iocs_12
	jrc	l_10
;
	mv	x,msg6		;(already exist)
	call	write
	jp	exit
;
l_10:
	mv	x,file1		;fcreate 'file1' for input as handle1
	mv	il,0
	mv	a,0
	callf	F_CALL		;file_iocs_1
	mv	a,(0d6h)
	mv	[handl1],a
	jrnc	loop
;
	mv	x,msg7		;(can't create)
	call	write
	jp	exit
;
loop:
	call	get_line
	jrnc	lbl1
;
	mv	x,msg8		;(short file)
	call	write
	jp	exit0
;
lbl1:
	mv	x,line_buf
	mv	a,[x++]		;
	sub	a,20h		;uudecode a char
	and	a,3fh		;
	cmp	a,0
	jrz	e_of_sq		;end of seq.
;
	mv	(4),0		;checksum == 0 (init)
;
	mv	il,a		;size of line
	mv	(5),a
	mv	y,out_buf
;
lbl2:
	mv	a,[x++]
	sub	a,20h		;dec No.1
	and	a,3fh
	rol	a
	rol	a
	mv	(0),a
	mv	a,[x++]
	sub	a,20h		;dec No.2
	and	a,3fh
	swap	a
	mv	(1),a
	mv	a,[x++]
	sub	a,20h		;dec No.3
	and	a,3fh
	ror	a
	ror	a
	mv	(2),a
	mv	a,[x++]
	sub	a,20h		;dec No.4
	and	a,3fh
	mv	(3),a
;
	mv	a,(1)
	and	a,03h
	or	a,(0)		;out No.1
	add	(4),a
	mv	[y++],a
	mv	a,(2)
	and	a,0fh
	and	(1),0f0h
	or	a,(1)		;out No.2
	add	(4),a
 	mv	[y++],a
	mv	a,(2)
	and	a,0c0h
	or	a,(3)		;out No.3
	add	(4),a
	mv	[y++],a
	dec	il
	jrz	lbl3
	dec	il
	jrz	lbl3
	dec	il
	jrz	lbl3
;
	jr	lbl2
;
lbl3:
	and	(4),3fh
	mv	a,[x++]
	sub	a,20h
	jrc	lbl4
	and	a,3fh
	cmp	(4),a
	jrz	lbl4
;
	mv	x,msg10		;(checksum error)
	call	write
	jp	exit0
;
lbl4:
	mv	a,0
	mv	[y++],a
;
	mv	x,out_buf
	mvw	(6),0
	mv	y,(5)		;write-size
	mv	a,[handl1]
	mv	(0d6h),a
	mv	il,4		;fwrite block
	callf	F_CALL
	jrnc	lbl4a
;
	mv	x,msg11
	call	write
	jp	exit0
lbl4a:
;
	jr	loop
;
e_of_sq:
	call	get_line
	jrnc	lbl6
;
lbl5:
	mv	x,msg9		;(no end)
	call	write
	jp	exit0
lbl6:
;
	mv	x,line_buf	;check == "end"
	mv	a,[x++]
	cmp	a,'e'
	jrnz	lbl5
	mv	a,[x++]
	cmp	a,'n'
	jrnz	lbl5
	mv	a,[x++]
	cmp	a,'d'
	jrnz	lbl5
;
	call	get_line	;size (dummy)
	call	get_line	;eof (dummy)
;
exit0:
	mv	a,[handl1]
	mv	(0d6h),a
	mv	il,2
	callf	F_CALL		;file_iocs_2
;
exit:	mv	a,[mode]
	cmp	a,0
	jrz	exit1
	mv	a,[handl0]	;close file 'fname'
	mv	(0d6h),a
	mv	il,2
	callf	F_CALL		;file_iocs_2
;
exit1:	mv	a,[base]
	mv	(0ech),a	;BP restore
	mv	a,0
	rc			;reset CF
	retf
;
;
;
;
;
;
;
arg:	mv	y,fname		;analyze argument characters
	mv	(0),18
	mv	a,' '
arg0:	mv	[y++],a		;fill space
	dec	(0)
	jrnz	arg0
	mv	a,0
	mv	[y++],a
	mv	y,fname
arg1:	mv	(0),0
	mv	a,[x++]		;skip space codes
	cmp	a,0
	jrz	arg1a
	cmp	a,CR
	jrz	arg1a
	cmp	a,01ah
	jrz	arg1a
	cmp	a,0ffh
	jrz	arg1a
	cmp	a,'<'
	jrz	arg1a
	cmp	a,'>'
	jrz	arg1a
	cmp	a,'"'
	jrz	arg1
	cmp	a,' '
	jrz	arg1
	jr	arg2a
arg1a:	jp	argerr
arg2:	mv	a,[x++]		;search drive or filename
	cmp	a,0
	jrz	arg4z
	cmp	a,CR
	jrz	arg4z
	cmp	a,01ah
	jrz	arg4z
	cmp	a,0ffh
	jrz	arg4z
	cmp	a,' '
	jrz	arg4z
	cmp	a,'"'		;closing quote ends the drive/name (UUDEC2)
	jrz	arg4z
arg2a:	cmp	a,':'
	jrz	arg2c
	cmp	a,'.'
	jrz	arg4
	mv	[y++],a
	inc	(0)
	cmp	(0),9
	jrnz	arg2
	jr	argerr
arg2c:	mv	[y++],a		;found drive
	cmp	(0),0
	jrz	argerr
	cmp	(0),6
	jrnc	argerr
	mv	y,fname+6
arg3:	mv	(0),0
	mv	a,[x++]		;search filename
	cmp	a,0
	jrz	arg5z
	cmp	a,CR
	jrz	arg5z
	cmp	a,01ah
	jrz	arg5z
	cmp	a,0ffh
	jrz	arg5z
	cmp	a,' '
	jrz	arg5z
	cmp	a,'"'		;closing quote ends the filename (UUDEC2)
	jrz	arg5z
	cmp	a,'.'
	jrz	arg5
	mv	[y++],a
	inc	(0)
	cmp	(0),9
	jrnz	arg3
	jr	argerr
arg4z:	dec	x
arg4:	cmp	(0),0		;found filename without drive
	jrz	argerr
	mv	a,0
	pushu	a
arg4a:	mv	a,[--y]
	pushu	a		;string copy drive to filename
	dec	(0)
	cmp	(0),0
	jrnz	arg4a
	mv	y,fname
	mv	(0),6
	mv	a,' '
arg4b:	mv	[y++],a
	dec	(0)
	jrnz	arg4b
arg4c:	popu	a
	cmp	a,0
	jrz	arg4d
	mv	[y++],a
	jr	arg4c
arg4d:	pushu	x		;store default drive
	mv	x,CR_DRV
	mv	y,fname
	mv	(0),6
arg4e:	mv	a,[x++]
	mv	[y++],a
	dec	(0)
	jrnz	arg4e
	popu	x
	jr	arg5
arg5z:	dec	x
arg5:	mv	a,'.'
	mv	y,fname+14
	mv	[y++],a
	mv	(0),0
arg6:	mv	a,[x++]		;search extention
	cmp	a,0
	jrz	arg_ok
	cmp	a,CR
	jrz	arg_ok
	cmp	a,01ah
	jrz	arg_ok
	cmp	a,0ffh
	jrz	arg_ok
	cmp	a,' '
	jrz	arg_ok
	cmp	a,'"'		;closing quote ends the extension (UUDEC2)
	jrz	arg_ok
	mv	[y++],a
	inc	(0)
	cmp	(0),4
	jrnz	arg6
	jr	argerr
arg_ok:	call	argskp
	rc
	ret
argerr:	call	argskp		;no argument or illegal one
	sc
	ret
argskp:	dec	x
argsk1:	mv	a,[x++]
	cmp	a,0
	jrz	argsk2
	cmp	a,CR
	jrz	argsk2
	cmp	a,01ah
	jrz	argsk2
	cmp	a,0ffh
	jrz	argsk2
	jr	argsk1
argsk2:	dec	x
	ret
;
;
;
;
get_line:			;get 1 line
st0:	mv	x,line_buf
	mv	il,0
	mv	[line_buf_ptr],i
;
st1:	call	f_read		;skip CR/LF code
	jrc	f_err
	cmp	a,01ah
	jrz	f_eof
	ex	a,b
	cmp	a,0
	jrz	f_eof
	ex	a,b
	cmp	a,CR
	jrz	st1
	cmp	a,LF
	jrz	st1
;
st2:	mv	il,a		;store data
	mv	ba,[line_buf_ptr]
	inc	ba
	cmp	a,80
	jrz	st3
	mv	[line_buf_ptr],ba
	mv	[x++],il
;
	call	f_read
	jrc	f_err
	cmp	a,01ah
	jrz	f_eof
	ex	a,b
	cmp	a,0
	jrz	f_eof
	ex	a,b
	cmp	a,CR
	jrz	st4
	cmp	a,LF
	jrz	st4
	jr	st2
st4:	mv	a,0
	mv	[x++],a
	rc
	ret
;
st3:	call	f_read		;skip CR/LF code
	jrc	f_err
	cmp	a,01ah
	jrz	f_eof
	ex	a,b
	cmp	a,0
	jrz	f_eof
	ex	a,b
	cmp	a,CR
	jrz	st5
	cmp	a,LF
	jrz	st5
st5:	jr	st0
;
f_err:	mv	a,0
	mv	[x++],a
	sc
	ret
;
f_eof:	mv	a,0
	mv	[x++],a
	mv	a,1
	sc
	ret
;
f_read:	mv	a,[handl0]	;read from 'fname'
	mv	(0d6h),a
	mv	il,5
	mv	a,0
	callf	F_CALL		;file_iocs_5
	ret
;
;
uppercase:
	mv	il,18
uc1:	mv	a,[x]
	cmp	a,'a'
	jrc	uc2
	cmp	a,'z'+1
	jrnc	uc2
	sub	a,20h
uc2:	mv	[x++],a
	dec	il
	jrnz	uc1
	ret
;
;
dispname:
	mv	x,msg20
	call	write
	mv	x,fname2
	call	write
	mv	x,msg21
	call	write
 	ret
;
;
write:	mv	(0d6h),0
	pushu	x		;display message
	mv	y,0
wrt1:	mv	a,[x++]
	inc	y
	cmp	a,0
	jrnz	wrt1
	dec	y
	popu	x
	mv	il,4
	callf	F_CALL		;file_iocs_4
	ret
;
;
def_file:
	db	'uudecode.$$$',0	;if BAD_FILENAME then  this is used.
;
msg1:	db	'uudecode V1.1 by E.Kako',CR,LF,0
msg2:	db	'USAGE : uudecode infile',CR,LF,0
msg3:	db	'File not found.',CR,LF,0
msg4:	db	'No begin line.',CR,LF,0
msg5:	db	'Bad filename !',CR,LF,0
msg6:	db	'Already exist.',CR,LF,0
msg7:	db	'File cannot create.',CR,LF,0
msg8:	db	'Too short file.',CR,LF,0
msg9:	db	'No end line.',CR,LF,0
msg10:	db	'Checksum mismatch.',CR,LF,0
msg11:	db	'Disk output error.',CR,LF,0
;
msg20:	db	'filename = ',27h,0
msg21:	db	27h,CR,LF,0
;
base:	db	0
;
mode:	db	0
handl0:	db	0
handl1:	db	0
fname:	ds	21,0
fname2:	ds	21,0
file1:	ds	21,0
finfo:	ds	8,0
size:	dp	0
;
line_buf_ptr:
	dw	0
line_buf:
	ds	80,0
;
out_buf:
	ds	80,0
;
	pre_off
	end
