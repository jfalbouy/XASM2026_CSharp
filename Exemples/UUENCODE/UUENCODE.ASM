;
;		uuencode    for TY-DOS (PC-E500/1480U)   Ver 1.0
;			Programmed by  E. Kako (JM2WGN)
;
;			Original   is  UNIX(TM)
;
;		USAGE : uuencode filename
;		      : uuencode filename -s   ...output to "COM:"
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
	mv	a,0
	mv	[outsio],a
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
	mv	x,msg3		;(file not found)
	call	write
	jp	exit
;
l_0:
	mv	x,[size]
	mv	[code_size],x
	mv	[code_size2],x
;
	mv	x,fname
	mv	y,file1
	mv	il,15
	mv	a,[outsio]
	cmp	a,0
	jrnz	l_2
l_1:	mv	a,[x++]
	mv	[y++],a
	dec	il
	jrnz	l_1
	mv	a,'U'
	mv	[y++],a
	mv	a,'U'
	mv	[y++],a
	mv	a,'E'
	mv	[y++],a
	mv	a,0
	mv	[y++],a
;
	mv	il,0bh
	mv	x,file1
	mv	y,finfo2
	mv	a,0
	callf	F_CALL		;file_iocs_12
	jrc	l_2
;
	mv	x,msg4		;(uue file exist)
	call	write
	jp	exit
;
l_2:	mv	x,fname		;fopen 'fname' for input as handle0
	mv	il,1
	mv	a,1
	callf	F_CALL		;file_iocs_1
	jrc	l_2z
	mv	a,(0d6h)
	mv	[handl0],a
;
	mv	x,file1		;fopen 'file1' for output as handle1
	mv	a,[outsio]
	cmp	a,0
	jrz	l_2a
	mv	x,sio
l_2a:	mv	il,0
	mv	a,0
	callf	F_CALL		;file_iocs_0
	jrnc	l_3
;
l_2z:	mv	x,msg5		;(file open error)
	call	write
	jp	exit
;
l_3:	mv	a,(0d6h)
	mv	[handl1],a
;
	mv	a,1
	mv	[mode],a
;
	mv	x,fname+6
	mv	y,fname2
	mv	il,12
l_5:	mv	a,[x++]
	cmp	a,' '
	jrz	l_7
	cmp	a,'A'
	jrc	l_6
	cmp	a,'Z'+1
	jrnc	l_6
	add	a,20h
l_6:	mv	[y++],a
l_7:	dec	il
	jrnz	l_5
	mv	a,CR
	mv	[y++],a
	mv	a,LF
	mv	[y++],a
	mv	a,0
	mv	[y++],a
;
;
	mv	a,[handl1]
	mv	(0d6h),a
	mv	x,msg6		;(begin 644 )
	call	writef
	jrc	werr
;
l_9:	mv	a,[handl1]
	mv	(0d6h),a
	mv	x,fname2
	call	writef
	jrc	werr
;
main:
	mv	x,[code_size]
	mvp	(0),45
	cmpp	(0),x
	jrnc	m_2		; 1 .. 45
m_1:	mv	y,45
	sub	x,y
	mv	[code_size],x
	call	encode_line
	mv	a,[handl1]
	mv	(0d6h),a
	call	writef
	jrc	werr
	jr	main
;
m_2:	mv	y,x
	call	encode_line
	mv	a,[handl1]
	mv	(0d6h),a
	call	writef
	jrc	werr
;
	mv	a,[handl1]
	mv	(0d6h),a
	mv	x,msg9		;(end)
	call	writef
	jrc	werr
;
	mv	a,[handl1]
	mv	(0d6h),a
	mv	x,msg10		;(size)
	call	writef
	jrc	werr
;
	mv	x,[code_size2]
	call	number		;(%d)
	mv	a,[handl1]
	mv	(0d6h),a
	call	writef
	jrc	werr
;
	mv	a,[handl1]
	mv	(0d6h),a
	mv	x,msg11		;(eof)
	call	writef
	jrc	werr
;
	mv	x,msg12		;(decoded.)
	call	write
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
werr:	mv	x,msg7
	call	write
	jp	exit0
;
;
;
;
;
;
encode_line:
	pushu	y
	mv	x,in_buf
	mv	il,3
	mv	a,[handl0]
	mv	(0d6h),a
	mv	a,1		;file block read
	callf	F_CALL
	popu	y
	jrnc	enc1
	pops	a
	pops	a
	mv	x,msg8		;(file read error)
	call	write
	jp	exit0
;
enc1:	mv	(0),y
	mv	il,(0)
	mv	x,in_buf
	mv	y,line_buf
;
	mv	a,(0)
	and	a,3fh
	jrnz	enc2
	mv	a,40h
enc2:	add	a,' '
	mv	[y++],a		;store n bytes
;
	mv	a,0		;sum init (= 0)
;
;
enc3:	mvp	(1),0
	mv	(1),[x++]
	dec	il
	jrz	enc4
	mv	(2),[x++]
	dec	il
	jrz	enc4
	mv	(3),[x++]
	dec	il
	jrz	enc4
	call	enc_sub
	jr	enc3
;
enc4:
	call	enc_sub
;
	and	a,3fh
	jrnz	enc5
	mv	a,40h
enc5:	add	a,' '
	mv	[y++],a		;store checksum
	mv	a,CR
	mv	[y++],a
	mv	a,LF
	mv	[y++],a
	mv	a,0
	mv	[y++],a
;
	mv	x,line_buf
	ret
;
;
;
enc_sub:
	add	a,(1)
	add	a,(2)		;calc sum
	add	a,(3)
;
	pushu	a
	ror	(1)
	ror	(1)
	mv	(0),(1)
	and	(0),3fh		;enc No.1
	jrnz	es1
	mv	(0),40h
es1:	add	(0),' '
;
	ror	(1)
	ror	(1)
	and	(1),030h
	mv	a,(2)
	swap	a
	and	a,0fh
	or	(1),a		;enc No.2
	jrnz	es2
	mv	(1),40h
es2:	add	(1),' '
;
	rol	(2)
	rol	(2)
	and	(2),03ch
	mv	a,(3)
	rol	a
	rol	a
	and	a,03h
	or	(2),a		;enc No.3
	jrnz	es3
	mv	(2),40h
es3:	add	(2),' '
;
	and	(3),3fh		;enc No.4
	jrnz	es4
	mv	(3),40h
es4:	add	(3),' '
;
	mv	[y++],(0)
	mv	[y++],(1)
	mv	[y++],(2)
	mv	[y++],(3)
	popu	a
	ret
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
	jrz	arg7
	mv	[y++],a
	inc	(0)
	cmp	(0),4
	jrnz	arg6
	jr	argerr
arg7:	mv	a,[x++]
	cmp	a,' '
	jrz	arg7
	cmp	a,'-'
	jrnz	arg_ok
	mv	a,[x++]
	cmp	a,'S'
	jrz	arg8
	cmp	a,'s'
	jrz	arg8
	jr	argerr
arg8:	mv	a,1
	mv	[outsio],a
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
number:	mv	y,tenbuf	;convert decimal
	mv	[deci],y
	mv	y,100000
	call	num1
	mv	y,10000
	call	num1
	mv	y,1000
	call	num1
	mv	y,100
	call	num1
	mv	y,10
	call	num1
	mv	y,1
	call	num1
	mv	x,[deci]
	mv	a,10
	mv	[x++],a
	mv	x,tenbuf
	mv	y,ten
nm1:	mv	a,[x++]
	cmp	a,0
	jrz	nm1
	add	a,'0'
	mv	[y++],a
nm2:	mv	a,[x++]
	add	a,'0'
	mv	[y++],a
	cmp	a,'0'+10
	jrnz	nm2
	mv	a,0
	mv	[--y],a
	mv	x,ten
	ret
;
num1:	mv	a,0
num2:	sub	x,y
	inc	a
	jrnc	num2
	add	x,y
	dec	a
	pushu	x
	mv	x,[deci]
	mv	[x++],a
	mv	[deci],x
	popu	x
	ret
;
;
;
writef:	mv	(0d6h),a
	jr	wrt0
write:	mv	(0d6h),0
wrt0:	pushu	x		;display message
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
;
sio:	db	'COM:        .   ',0
;
msg1:	db	'uuencode V1.0 by E.Kako',CR,LF,0
msg2:	db	'USAGE : uuencode infile [-s]',CR,LF,0
msg3:	db	'File not found.',CR,LF,0
msg4:	db	'File already exist.',CR,LF,0
msg5:	db	'File open found.',CR,LF,0
msg6:	db	'begin 644 ',0
msg7:	db	'File write error',CR,LF,0
msg8:	db	'File read error',CR,LF,0
msg9:	db	60h,60h,CR,LF,'end',CR,LF,0
msg10:	db	'size ',0
msg11:	db	CR,LF,01ah,0
msg12:	db	'encoded.',CR,LF,0
;
;
base:	db	0
;
outsio:	db	0
mode:	db	0
handl0:	db	0
handl1:	db	0
fname:	ds	21,0
fname2:	ds	21,0
file1:	ds	21,0
finfo:	db	0
date:	ds	4,0
size:	dp	0
finfo2:	ds	8,0
deci:	dp	0
tenbuf:	ds	7,0
ten:	ds	7,0
code_size:
	dp	0
code_size2:
	dp	0
;
line_buf_ptr:
	dw	0
line_buf:
	ds	80,0
;
in_buf:
	ds	80,0
;
	pre_off
	end
