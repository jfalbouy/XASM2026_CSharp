;
;		ish file decoder for TY-DOS (PC-E500/1480U)   Ver 1.02
;			Programmed  by  E. Kako (JM2WGN)
;
;		ORIGIANAL MS-DOS VERSION
;			Copyright (c) 1986 - 1990  by  M. ishizuka
;			All rights reserved.
;
;		USAGE : ishd filename     ...  restore ish_file
;
CR:	equ	0dh
LF:	equ	0ah
F_CALL:	equ	0fffe4h
CR_DRV:	equ	0bfc7dh
;
	org	0bc000h
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
	mv	x,msg3		;(opening message)
	call	write
	mv	il,0bh
	mv	x,fname
	mv	y,finfo
	mv	a,0
	callf	F_CALL		;file_iocs_12
	jrnc	lbl1
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
	jr	lbl1
f_n_f:
	mv	x,msg4		;(file not found)
	call	write
	jp	exit
;
lbl1:	mv	x,fname		;fopen 'fname' for input as handle0
	mv	il,1
	mv	a,1
	callf	F_CALL		;file_iocs_1
	mv	a,(0d6h)
	mv	[handl0],a
;
	mv	a,1
	mv	[mode],a
	mv	x,0
	mv	[reading_line],x
;
search_line:
	call	get_line	;analyze header line
	jrnc	srch1
	jp	all_extract
srch1:	mv	a,[i_buf]
	cmp	a,0
	jrnz	search_line
;
	mv	x,i_buf+12	;get filename 'file2'
	mv	y,file2
	mv	il,8
lbl2:	mv	a,[x++]
	mv	[y++],a
	dec	il
	jrnz	lbl2
	mv	a,'.'
	mv	[y++],a
	mv	il,3
lbl2a:	mv	a,[x++]
	mv	[y++],a
	dec	il
	jrnz	lbl2a
	mv	a,0
	mv	[y++],a
;
	mv	il,6		;filename in iocs format
	mv	x,CR_DRV
	mv	y,file1
lbl2b:	mv	a,[x++]
	mv	[y++],a
	dec	il
	jrnz	lbl2b
	mv	il,13
	mv	x,file2
lbl2c:	mv	a,[x++]
	mv	[y++],a
	dec	il
	jrnz	lbl2c
;
	mv	x,file2
	mv	y,x
	mv	il,13
lbl2d:	mv	a,[x++]
	cmp	a,' '
	jrz	lbl2e
	mv	[y++],a
lbl2e:	dec	il
	jrnz	lbl2d
;
	mv	x,file2		;(restoring filename)
	call	write
	mv	x,msg5
	call	write
;
lbl3:
	mv	il,0bh		;file exist check
	mv	x,file1
	mv	y,finfo
	mv	a,0
	callf	F_CALL		;file_iocs_12
	jrc	lbl3a
;
	mv	x,msg6		;(already exist)
	call	write
	jp	srch_next
;
lbl3a:
	mv	x,[i_buf+2]	;ish format check
	mv	[size],x
	inc	x
	inc	x
	mv	[restsize],x
	mv	ba,[i_buf+6]
	cmp	a,69
	jrnz	use_upper_ver
	mv	ba,[i_buf+8]
	cmp	a,68
	jrnz	use_upper_ver
	mv	ba,[i_buf+10]
	cmp	a,8
	jrnz	use_upper_ver
	ex	a,b
	cmp	a,8
	jrnz	use_upper_ver
	jr	lbl3b
;
use_upper_ver:
	mv	x,msg7		;(use upper version)
	call	write
	jp	srch_next
;
lbl3b:
	mv	il,0fh		;file size check
	mv	x,CR_DRV
	mv	a,0
	callf	F_CALL		;file_iocs_15
	mv	y,(0dah)
	mv	x,[size]
	sub	x,y
	jrc	lbl4
;
	mv	x,msg8		;(disk full)
	call	write
	jp	srch_next
;
srch_next:
	call	get_line
	jrnc	srch_n
	jp	all_extract
srch_n:	mv	a,[i_buf]
	cmp	a,0
	jrz	srch_next
	jp	search_line
;
lbl4:
	mv	x,[size]	;(_____)
	inc	x
	mv	y,66
	mv	il,0
lbl4a:	inc	i
	sub	x,y
	jrnc	lbl4a
	mv	x,i
	mv	[total_lines],x
	mv	il,0
lbl4b:	inc	i
	sub	x,y
	jrz	lbl4b2
	jrnc	lbl4b
lbl4b2:	add	x,y
	mv	(0),x
	mv	[rest_lines],(0)
	mv	y,i
	mv	[total_pages],y
	mv	x,y
lbl4c:	mv	a,'_'
	call	write2
	dec	x
	jrnz	lbl4c
lbl4d:	mv	a,29		;cursor move left
	call	write2
	dec	y
	jrnz	lbl4d
;
lbl5:
	call	get_line
	jrnc	lbl5a
	mv	x,msg14		;body is not found
	call	write
	jp	all_extract
lbl5a:	mv	a,[i_buf]
	cmp	a,0
	jrz	lbl5
;
	mv	x,file1		;create 'file1' for output as handle1
	mv	il,0
	mv	a,0
	callf	F_CALL		;file_iocs_1
	jrc	lbl5b
	mv	a,(0d6h)
	mv	[handl1],a
	jr	lbl6
;
lbl5b:	mv	[handl1],a
	mv	x,msg15		;('file1' cannot create)
	call	write
	jp	all_extract
;
;
lbl6:	mv	a,0
	mv	[crc_g_f],a
;
;
read_page_0:
	mv	a,1
	mv	[wanted],a
	mv	a,0
	mv	[deterr],a
	call	buffer_init
	jr	read_page_2
;
read_page_0a:
	mv	a,1
	mv	[wanted],a
	mv	a,0
	mv	[deterr],a
	call	buffer_init
;
read_page_1:
	call	get_line
	jrnc	read_page_2
	mv	a,255
	mv	[i_buf],a
	jr	readpz
;
read_page_2:
	mv	a,[i_buf]
	mv	(0),[wanted]
	cmp	(0),a
	jrz	no_error
;
readpz:	call	det1		;error has detected !!!!!
	jrnc	readpy
	jp	fatal_err
;
readpy:	mv	a,[wanted]
	cmp	a,69
	jrnz	readp0
	call	write_page
	jrnc	read_page_0
	mv	il,1
	mv	[already_read],il
	jr	final
readp0:	cmp	a,67
	jrnz	readp1
	mv	a,69
	mv	[wanted],a
	jr	read_page_2
readp1:	mv	x,[total_pages]
	dec	x
	jrnz	readp2			;last page and ..
	mv	(0),[rest_lines]	;              last line
	cmp	(0),a
	jrnz	readp2
	mv	a,66
readp2:	inc	a
	mv	[wanted],a
	jr	read_page_2
;
no_error:
	call	set_buffer	;error is not detected !!!
	mv	a,[wanted]
	cmp	a,69
	jrnz	no_e0
	call	write_page
	jrnc	read_page_0a
	mv	il,0
	mv	[already_read],il
	jr	final
no_e0:	cmp	a,67
	jrnz	no_e1
	mv	a,69
	mv	[wanted],a
	jr	read_page_1
no_e1:	mv	x,[total_pages]
	dec	x
	jrnz	no_e2			;last page and ..
	mv	(0),[rest_lines]	;              last line
	cmp	(0),a
	jrnz	no_e2
	mv	a,66
no_e2:	inc	a
	mv	[wanted],a
	jr	read_page_1
;
final:	cmp	a,0
	jrz	fina0		;wrote all  successfully
	cmp	a,1
	jrz	fina1		;file write error
	cmp	a,2
	jrz	fina2		;crc error detect
;
fina0:
	mv	x,msg9		;(restored successfully.)
	call	write
	mv	a,[handl1]
	mv	(0d6h),a
	mv	il,2		;fclose 'file1'
	callf	F_CALL
	jp	final_final
;
fina1:
	mv	x,msg10		;(file write error)
	call	write
	jr	tag_del
fina2:
	mv	x,msg11		;(crc error detect)
	call	write
	jr	tag_del
;
fatal_err:
	mv	x,msg13
	call	write
	call	disp_errors
;
tag_del:
	mv	a,[handl1]
	mv	(0d6h),a
	mv	il,2		;fclose 'file1'
	callf	F_CALL
	mv	x,file1
	mv	il,0eh
	callf	F_CALL		;delete 'file1'
	jp	final_final
;
;
final_final:
	mv	a,[i_buf]
	cmp	a,255
	jrz	all_extract
	mv	a,[already_read]
	cmp	a,1		;a=1 .. already read a line
	jrz	f_f_1
	call	get_line
	jrc	all_extract
f_f_1:	jp	srch1
;
;
all_extract:
;
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
get_line:			;get 1 ish_line
st0:	mv	il,0
	mv	[line_buf_ptr],i
;
st1:	call	f_read		;skip control code
	jrc	f_err
	cmp	a,01ah
	jrz	f_eof
	ex	a,b
	cmp	a,0
	jrz	f_eof
	ex	a,b
	cmp	a,CR
	jrnz	st1a
	mv	x,[reading_line]
	inc	x
	mv	[reading_line],x
st1a:	cmp	a,21h
	jrc	st1
;
st2:	mv	il,a		;store data
	mv	x,line_buf
	mv	ba,[line_buf_ptr]
	add	x,ba
	inc	ba
	cmp	a,80
	jrz	st3
	mv	[line_buf_ptr],ba
	mv	[x],il
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
	jrnz	st2a
	mv	x,[reading_line]
	inc	x
	mv	[reading_line],x
st2a:	cmp	a,21h
	jrnc	st2
;
	mv	ba,[line_buf_ptr]
	cmp	a,79
	jrz	st4
	cmp	a,78
	jrz	st5
	jr	st0
;
st3:	call	f_read		;skip non-control code
	jrc	f_err
	cmp	a,01ah
	jrz	f_eof
	ex	a,b
	cmp	a,0
	jrz	f_eof
	ex	a,b
	cmp	a,21h
	jrnc	st3
	cmp	a,CR
	jrnz	st3a
	mv	x,[reading_line]
	inc	x
	mv	[reading_line],x
st3a:	jr	st0
;
st4:	call	ish_decode	;decode & crc check
	jrc	st0
	mv	il,65
	call	calc_crc_1
	mv	ba,[c1]
	mvw	(0),[crc1]
	cmpw	(0),ba
	jrnz	st0
	rc
	ret
st5:
	call	decode_jis7
	jrc	st0
	mv	il,59
	call	calc_crc_1
	mv	ba,[c1]
	mvw	(0),[i_buf+61]
	cmpw	(0),ba
	jrnz	st0
	rc
	ret
;
f_err:	mv	a,0
	sc
	ret
;
f_eof:	mv	a,1
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
ish_decode:
	mv	x,line_buf	;jis8code->7bit
	mv	il,79
	mv	ba,0
dec1:	mv	y,decode_table
	mv	a,[x]
	add	y,ba
	mv	a,[y]
	cmp	a,0ffh
	jrz	dec_err
	mv	[x++],a
	dec	il
	jrnz	dec1
	jr	dec2
dec_err:
	sc
	ret
;
dec2:	mv	x,line_buf	;7bit->8bit
	mv	y,i_buf
	mv	il,10
;
dec3:	mv	(0),[x++]
	and	(0),7fh
	mv	a,[x]
	and	a,01h
	ror	a
	or	a,(0)
	mv	[y++],a
;
	mv	(0),[x++]
	and	(0),7eh
	ror	(0)
	mv	a,[x]
	and	a,03h
	ror	a
	ror	a
	or	a,(0)
	mv	[y++],a
;
	mv	(0),[x++]
	and	(0),7ch
	ror	(0)
	ror	(0)
	mv	a,[x]
	and	a,07h
	ror	a
	ror	a
	ror	a
	or	a,(0)
	mv	[y++],a
;
	mv	(0),[x++]
	and	(0),78h
	ror	(0)
	ror	(0)
	ror	(0)
	mv	a,[x]
	and	a,0fh
	swap	a
	or	a,(0)
	mv	[y++],a
;
	mv	a,[x++]
	and	a,70h
	swap	a
	mv	(0),[x]
	and	(0),1fh
	rol	(0)
	rol	(0)
	rol	(0)
	or	a,(0)
	mv	[y++],a
;
	mv	a,[x++]
	and	a,60h
	rol	a
	rol	a
	rol	a
	mv	(0),[x]
	and	(0),3fh
	rol	(0)
	rol	(0)
	or	a,(0)
	mv	[y++],a
;
	mv	a,[x++]
	and	a,40h
	rol	a
	rol	a
	mv	(0),[x++]
	and	(0),7fh
	rol	(0)
	or	a,(0)
	mv	[y++],a
;
	dec	il
	jrnz	dec3
	rc
	ret
;
;
decode_jis7:
	mv	x,line_buf	;jis7code->13bit(6.5bit)
	mv	il,78
	mv	ba,0
dec7_1:	mv	y,jis7_table
	mv	a,[x]
	add	y,ba
	mv	a,[y]
	cmp	a,0ffh
	jrz	dec7_err
	mv	[x++],a
	dec	il
	jrnz	dec7_1
	jr	dec7_2
dec7_err:
	sc
	ret
dec7_2:
	mv	x,line_buf	;13bit(6.5bit)->8bit
	mv	y,i_buf
;
	mv	(0),[x++]	;No.1  byte   (6+2 bit)
	and	(0),03fh
	mv	a,[x]
	and	a,03h
	ror	a
	ror	a
	or	a,(0)
	mv	[y++],a
;
	mv	(0),[x++]	;No.2  byte   (4+4 bit)
	and	(0),03ch
	ror	(0)
	ror	(0)
	mv	a,[x]
	and	a,0fh
	swap	a
	or	a,(0)
	mv	[y++],a
;
	mv	a,[x++]		;No.3  byte   (2+6 bit)
	and	a,030h
	mv	(0),[x++]
	and	(0),03fh
	ror	(0)
	ror	(0)
	or	a,(0)
	swap	a
	mv	[y++],a
;
	mv	(2),60		;No.4 .. 63 byte  (13bit)
	call	get13
	mv	(3),13
;
dec13:	mv	(4),0
	mv	(5),8
dec13a:	shr	(1)
	shr	(0)
	shr	(4)
	dec	(3)
	jrnz	dec13b
	call	get13
	mv	(3),13
dec13b:	dec	(5)
	jrnz	dec13a
;
	mv	[y++],(4)
	dec	(2)
	jrnz	dec13
	ret
;
get13:	mv	(0),[x++]	;(6.5bit + 6.5bit -> 13bit)
	mv	(1),[x++]	;   91   *   91   -> 8192
	inc	(0)
	mv	ba,0
	mv	il,91
mul_a:	add	ba,i
	dec	(0)
	jrnz	mul_a
	sub	ba,i
	mv	il,(1)
	add	ba,i
	mv	(0),ba
	ret
;
;
calc_crc_1:			;calculate crc
	mv	x,i_buf
	mv	a,[x++]
	xor	a,0ffh
	mv	[c1],a
	mv	a,[x++]
	xor	a,0ffh
	mv	[c2],a
	call	csub1
	call	csub2
	call	csub2
	mv	a,[c1]
	xor	a,0ffh
	mv	[c1],a
	mv	a,[c2]
	xor	a,0ffh
	mv	[c2],a
	ret
;
csub1:	mv	y,crc_data_table
	mv	ba,0
	mv	a,[c1]
	add	ba,ba
	add	y,ba
	mvw	(0),[y++]
	mv	a,[x++]
	xor	(0),a
	mv	a,[c2]
	xor	(1),a
	mv	[c1],(1)
	mv	[c2],(0)
	dec	il
	jrnz	csub1
	ret
csub2:	mv	y,crc_data_table
	mv	ba,0
	mv	a,[c1]
	add	ba,ba
	add	y,ba
	mvw	(0),[y++]
	mv	a,[c2]
	xor	(1),a
	mv	[c1],(1)
	mv	[c2],(0)
	ret
;
;
buffer_init:
	mv	x,dec_buf
	mv	a,0
	mv	(0),1
bfint1:	mv	[x++],(0)
	mv	il,66
bfint2:	mv	[x++],a
	dec	il
	jrnz	bfint2
	inc	(0)
	cmp	(0),70
	jrnz	bfint1
	ret
;
;
set_buffer:
	mv	x,i_buf
	mv	y,dec_buf
	mv	ba,67
	mv	il,[x]
stbuf1:	add	y,ba
	dec	il
	jrnz	stbuf1
	sub	y,ba
	mv	il,67
stbuf2:	mv	a,[x++]
	mv	[y++],a
	dec	il
	jrnz	stbuf2
	ret
;
;
det1:
	mv	a,[deterr]
	cmp	a,0
	jrnz	det1a
	mv	a,1
	mv	[deterr],a
	mv	a,[wanted]
	mv	[ersq1],a
	mv	x,[reading_line]
	mv	[erln1],x
	rc
	ret
det1a:	cmp	a,1
	jrnz	det1b
	mv	a,2
	mv	[deterr],a
	mv	a,[wanted]
	mv	[ersq2],a
	mv	x,[reading_line]
	mv	[erln2],x
	rc
	ret
det1b:	mv	a,3
	mv	[deterr],a
	mv	a,[wanted]
	mv	[ersq3],a
	mv	x,[reading_line]
	mv	[erln3],x
	sc
	ret
;
;
write_page:
	call	correct
	mv	x,[total_pages]
	dec	x
	mv	[total_pages],x
	jrz	wrtpg1
	call	write_page_2
	jrc	wrtpg2
	rc
	ret
wrtpg1:	call	write_page_2
	jrc	wrtpg2
	mv	a,0		;0...wrote final page !!!!
wrtpg2:	sc			;1...file write error
	ret			;2...crc error detect
;
;
write_page_2:
	mv	a,1
	mv	[write_seq],a
	mv	x,[restsize]
	mv	y,66*66
	sub	x,y
	jrnc	w_p_1
	mv	y,[restsize]
w_p_1:	mv	[page_size],y
;
;
write_line:
	mv	x,[page_size]
	mv	y,66
	sub	x,y
	jrc	w_l_2
	jrz	w_l_2
;
w_l_1:	mv	[line_size],y		;line (1) .. (n-1)
	call	write_line_2
	jrc	w_l_3
	mv	x,[restsize]
	mv	y,[line_size]
	sub	x,y
	mv	[restsize],x
	mv	x,[page_size]
	sub	x,y
	mv	[page_size],x
	jr	write_line
;
w_l_2:	mv	y,[page_size]		;final line (=66?)
	mv	[line_size],y
	call	write_line_2
	jrc	w_l_3
	mv	x,[restsize]
	mv	y,[line_size]
	sub	x,y
	mv	[restsize],x
	rc
	ret
;
w_l_3:	sc
	ret
;
;
write_line_2:
	mv	x,[restsize]
	dec	x
	jrz	w_l_4		;                 crc last 1byte
	inc	x
	mv	y,67
	sub	x,y
	jrc	w_l_5		;(0..64) data   + crc 2byte
	jrz	w_l_6		;   (65) data   + crc prevent 1byte
	jr	w_l_7		;   (66) data only                  + more data
;
w_l_4:	call	req_seq_adr
	mv	a,[x+1]
	mv	[g_c2],a
	jr	w_l_9
;
w_l_5:	call	req_seq_adr
	inc	x
	mv	y,[line_size]
	dec	y
	dec	y
	call	write_line_3
	jrc	write_error
	mv	a,[x++]
	mv	[g_c1],a
	mv	a,[x++]
	mv	[g_c2],a
	jr	w_l_9
;
w_l_6:	call	req_seq_adr
	inc	x
	mv	y,[line_size]
	dec	y
	call	write_line_3
	jrc	write_error
	mv	a,[x++]
	mv	[g_c1],a
	jr	w_l_8
;
w_l_7:	call	req_seq_adr
	inc	x
	mv	y,[line_size]
	call	write_line_3
	jrc	write_error
;
w_l_8:	rc
	ret
;
w_l_9:	call	calc_g_crc2
	mvw	(0),[g_c1]
	mv	ba,[g_crc1]
	cmpw	(0),ba
	jrnz	w_l_10
	rc
	ret
;
w_l_10:	mv	a,2		;crc error
	sc
	ret
;
write_error:
	mv	a,1		;write error
	sc
	ret
;
;
write_line_3:
	pushu	x		;adrs
	pushu	y		;size
	mv	il,4
	mv	a,[handl1]
	mv	(0d6h),a
	callf	F_CALL		;file_block_write to 'file1'
	jrnc	w_l_11
	popu	y
	popu	x
	sc
	ret
w_l_11:
	popu	y
	popu	x
	call	calc_g_crc
	rc
	ret
;
;
req_seq_adr:
	mv	a,[write_seq]
	inc	a
	mv	[write_seq],a
	dec	a
	call	seq_adrs
	ret
;
;
calc_g_crc:			;calculate crc
	mv	(0),y
	mv	il,(0)		;size
	mv	a,[crc_g_f]
	cmp	a,0
	jrnz	c_g_c1
;
	mv	a,1
	mv	[crc_g_f],a
	mv	a,[x++]
	xor	a,0ffh
	mv	[g_crc1],a
	mv	a,[x++]
	xor	a,0ffh
	mv	[g_crc2],a
	dec	il
	dec	il
;
c_g_c1:	mv	a,il
	cmp	a,0
	jrz	c_g_c3
;
c_g_c2:	mv	y,crc_data_table
	mv	ba,0
	mv	a,[g_crc1]
	add	ba,ba
	add	y,ba
	mvw	(0),[y++]
	mv	a,[x++]
	xor	(0),a
	mv	a,[g_crc2]
	xor	(1),a
	mv	[g_crc1],(1)
	mv	[g_crc2],(0)
	dec	il
	jrnz	c_g_c2
;
c_g_c3:	ret
;
;
calc_g_crc2:
	call	g_csub2
	call	g_csub2
	mv	a,[g_crc1]
	xor	a,0ffh
	mv	[g_crc1],a
	mv	a,[g_crc2]
	xor	a,0ffh
	mv	[g_crc2],a
	ret
;
g_csub2:
	mv	y,crc_data_table
	mv	ba,0
	mv	a,[g_crc1]
	add	ba,ba
	add	y,ba
	mvw	(0),[y++]
	mv	a,[g_crc2]
	xor	(1),a
	mv	[g_crc1],(1)
	mv	[g_crc2],(0)
	ret
;
;
correct:
	mv	a,[deterr]
	cmp	a,0
	jrz	non_correct
	cmp	a,1
	jrz	crct_1
crct_2:
	mv	a,'2'
	call	write2
	call	correct_2_errors
	ret
crct_1:
	mv	a,'1'
	call	write2
	call	correct_1_error
	ret
non_correct:
	mv	a,'o'
	call	write2
	ret
;
;
correct_1_error:
	mv	a,[ersq1]
	cmp	a,67
	jrz	cr1_z
	cmp	a,69
	jrz	cr1_z
;
	mv	y,sum1
	mv	il,66
	mv	a,0
cr1_a:	mv	[y++],a
	dec	il
	jrnz	cr1_a
;
	mv	(1),1
cr1_b:	mv	a,(1)
	call	seq_adrs
	inc	x
	mv	y,sum1
	mv	il,66
cr1_c:	mv	(0),[x++]
	mv	a,[y]
	sub	a,(0)
	mv	[y++],a
	dec	il
	jrnz	cr1_c
	inc	(1)
	cmp	(1),68
	jrnz	cr1_b
;
	mv	a,[ersq1]
	call	seq_adrs
	inc	x
	mv	y,sum1
	mv	il,66
cr1_d:	mv	a,[y++]
	mv	[x++],a
	dec	il
	jrnz	cr1_d
cr1_z:
	ret
;
;
;
correct_2_errors:
	mv	a,[ersq2]
	cmp	a,69
	jrz	correct_1_error
;
	mv	a,[ersq1]
	call	seq_adrs
	mv	[er_adrs1],x
	mv	a,0
	mv	[x],a
	mv	a,[ersq2]
	call	seq_adrs
	mv	[er_adrs2],x
	mv	a,0
	mv	[x],a
;
	mv	x,sum1
	mv	il,67
	mv	ba,0
cr2_a:	mv	[x++],a
	dec	il
	jrnz	cr2_a
;
	mv	(1),1		;calc vt sum
cr2_b:	mv	a,(1)
	call	seq_adrs
	inc	x
	mv	y,sum1+1
	mv	il,66
cr2_c:	mv	(0),[x++]
	mv	a,[y]
	sub	a,(0)
	mv	[y++],a
	dec	il
	jrnz	cr2_c
	inc	(1)
	cmp	(1),68
	jrnz	cr2_b
;
	mv	a,69		;last (seq69)    slope sum
	call	seq_adrs
	inc	x
	mv	y,sum3+1
	mv	il,66
	mv	(2),0
cr2_d:	mv	a,[x++]
	add	(2),a
	mv	(0),a
	mv	a,0
	sub	a,(0)
	mv	[y++],a
	dec	il
	jrnz	cr2_d
	mv	a,(2)
	add	a,0e6h
	mv	[y++],a
	mv	(2),a
	mv	a,0
	sub	a,(2)
	mv	[x++],a
;
	mv	(1),1		;calc slope sum
cr2d1:	mv	a,(1)
	call	seq_adrs
	mv	y,sum3+1
	mv	il,67
	mv	(2),(1)
	dec	(2)
	mv	ba,0
cr2d2:	mv	a,(2)
	pushu	x
	add	x,ba
	mv	(0),[x]
	popu	x
	mv	a,[y]
	sub	a,(0)
	mv	[y++],a
	inc	(2)
	cmp	(2),67
	jrnz	cr2d3
	mv	(2),0
cr2d3:	dec	il
	jrnz	cr2d2
	inc	(1)
	cmp	(1),68
	jrnz	cr2d1
;
	mv	a,[ersq2]
	mv	(0),[ersq1]
	sub	a,(0)
	mv	(5),a		;(5) ... step
	mv	a,68
	sub	a,(0)
	cmp	a,67
	jrc	cr2_e
	sub	a,67
cr2_e:	mv	(4),a		;(4) ... slope sum adrs
	mv	(3),0		;(3) ... vt sum adrs
	mv	a,[ersq1]
	mv	(0),a		;(0) .,. slope sum elm (ersq1)
	mv	il,66
;
cr2_f:	mv	ba,0
	mv	a,(4)
	mv	x,sum3+1
	add	x,ba
	mv	(1),[x]		;slope sum value  ==  (sum 1) + (sum elm2)
;
	mv	a,(1)
	sub	a,(0)
	mv	(2),a		;(slope sum elm2)
;
	mv	a,(4)
	add	a,(5)		;(slope adrs) += (step)
	cmp	a,67
	jrc	cr2_g
	sub	a,67
cr2_g:	mv	(4),a
;
	mv	a,(3)
	add	a,(5)		;(vt adrs) += (step)
	cmp	a,67
	jrc	cr2_h
	sub	a,67
cr2_h:	mv	(3),a
;
	mv	ba,0
	mv	a,(3)
	mv	x,[er_adrs2]
	add	x,ba		;set
	mv	[x],(2)		; slope sum elm (ersq2) == (vt sum elm2)
;
	mv	ba,0
	mv	a,(3)
	mv	x,sum1
	add	x,ba
	mv	(1),[x]		;vt sum value ==  (vt1) + (vt2)
;
	mv	a,(1)
	sub	a,(2)
	mv	(0),a		;(v sum elm1 )
;
	mv	ba,0
	mv	a,(3)
	mv	x,[er_adrs1]
	add	x,ba		;set
	mv	[x],(0)		; v sum elm (eqsr1) == next slope sum
;
	dec	il
	jrnz	cr2_f
;
	ret
;
;
;
seq_adrs:
	mv	il,a
	mv	x,dec_buf
	mv	ba,67
s_a_1:	add	x,ba
	dec	il
	jrnz	s_a_1
	sub	x,ba
s_a_2:	ret
;
;
disp_errors:
	mv	x,msg12		;(ERROR : )
	call	write
;
	mv	x,[erln1]
	call	disp_err_sub2
	mv	a,[ersq1]
	call	disp_err_sub1
	mv	x,[erln2]
	call	disp_err_sub2
	mv	a,[ersq2]
	call	disp_err_sub1
	mv	x,[erln3]
	call	disp_err_sub2
	mv	a,[ersq3]
	call	disp_err_sub1
	mv	a,CR
	call	write2
	mv	a,LF
	call	write2
	ret
;
disp_err_sub1:
	mv	il,0
	mv	x,decode_table
dispe1:	mv	(0),[x++]
	inc	il
	cmp	(0),a
	jrnz	dispe1
	dec	il
	mv	a,il
	call	write2
	mv	a,')'
	call	write2
	mv	a,' '
	call	write2
	ret
;
disp_err_sub2:
	mv	a,'['
	call	write2
	dec	x
	call	number
	call	write
	mv	a,']'
	call	write2
	mv	a,'-'
	call	write2
	mv	a,'>'
	call	write2
	mv	a,'('
	call	write2
	ret
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
;
write2:
	mv	(0d6h),0
	mv	il,6
	callf	F_CALL
	ret
;
;
;
msg1:	db	'ish file decoder V1.0 by E.Kako',CR,LF,0
msg2:	db	'USAGE : ishd filename ',CR,LF,0
msg3:	db	'[ restore <JIS8 format> ]',CR,LF,0
msg4:	db	'ish_file not found.',CR,LF,0
msg5:	db	' : ',0
msg6:	db	'already exist.',CR,LF,0
msg7:	db	'use upper version.',CR,LF,0
msg8:	db	'disk full.',CR,LF,0
msg9:	db	CR,LF,'file restored successfully.',CR,LF,0
msg10:	db	CR,LF,'file write error.',CR,LF,0
msg11:	db	CR,LF,'crc error detected.',CR,LF,0
msg12:	db	'ERROR: ',0
msg13:	db	'x',CR,LF,0
msg14:	db	'extremely damaged.',CR,LF,0
msg15:	db	'file cannot create.',CR,LF,0
;
decode_table:
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	db	0ffh,0ffh,0ffh, 00h,0ffh, 01h, 02h, 03h
	db	0ffh, 04h,0ffh, 05h, 06h,0ffh,0ffh, 08h
	db	0ffh,0ffh, 09h,0ffh, 0ah, 0bh, 0ch, 0dh
	db	 0eh, 0fh, 10h, 11h, 12h, 13h, 14h, 07h
	db	0ffh, 15h, 16h, 17h, 18h, 19h, 1ah, 1bh
	db	 1ch, 1dh,0ffh, 1eh, 1fh,0ffh, 20h, 21h
	db	0ffh,0ffh, 22h,0ffh, 23h, 24h, 25h, 26h
	db	 27h, 28h, 29h, 2ah, 2bh, 2ch, 2dh,0ffh
	db	0ffh, 2eh, 2fh, 30h, 31h, 32h, 33h, 34h
	db	 35h, 36h, 37h, 38h, 39h, 3ah, 3bh,0ffh
	db	 3ch, 3dh, 3eh, 3fh, 40h, 41h, 42h,0ffh
	db	 43h, 44h, 45h,0ffh, 46h,0ffh,0ffh,0ffh
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	db	0ffh, 47h, 48h, 49h, 4ah, 4bh, 4ch, 4dh
	db	 4eh, 4fh, 50h, 51h, 52h,0ffh, 53h, 54h
	db	 55h, 56h, 57h,0ffh, 58h, 59h, 5ah, 5bh
	db	 5ch, 5dh, 5eh, 5fh, 60h, 61h, 62h,0ffh
	db	 63h, 64h, 65h, 66h, 67h, 68h, 69h, 6ah
	db	 6bh, 6ch, 6dh, 6eh, 6fh,0ffh, 70h, 71h
	db	 72h, 73h, 74h,0ffh, 75h, 76h, 77h, 78h
	db	 79h, 7ah, 7bh, 7ch, 7dh, 7eh, 7fh,0ffh
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
;
jis7_table:
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	db	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	db	0ffh, 00h, 01h,0ffh, 02h, 03h, 04h, 05h
	db	 06h, 07h, 08h, 09h, 0ah, 0bh,0ffh, 0ch
	db	 0dh, 0eh, 0fh, 10h, 11h, 12h, 13h, 14h
	db	 15h, 16h, 17h, 18h, 19h, 1ah, 1bh, 1ch
	db	 1dh, 1eh, 1fh, 20h, 21h, 22h, 23h, 24h
	db	 25h, 26h, 27h, 28h, 29h, 2ah, 2bh, 2ch
	db	 2dh, 2eh, 2fh, 30h, 31h, 32h, 33h, 34h
	db	 35h, 36h, 37h, 38h, 39h, 3ah, 3bh, 3ch
	db	0ffh, 3dh, 3eh, 3fh, 40h, 41h, 42h, 43h
	db	 44h, 45h, 46h, 47h, 48h, 49h, 4ah, 4bh
	db	 4ch, 4dh, 4eh, 4fh, 50h, 51h, 52h, 53h
	db	 54h, 55h, 56h, 57h, 58h, 59h, 5ah,0ffh
;
crc_data_table:
	dw	00000h,01021h,02042h,03063h,04084h,050A5h,060C6h,070E7h
	dw	08108h,09129h,0A14Ah,0B16Bh,0C18Ch,0D1ADh,0E1CEh,0F1EFh
	dw	01231h,00210h,03273h,02252h,052B5h,04294h,072F7h,062D6h
	dw	09339h,08318h,0B37Bh,0A35Ah,0D3BDh,0C39Ch,0F3FFh,0E3DEh
	dw	02462h,03443h,00420h,01401h,064E6h,074C7h,044A4h,05485h
	dw	0A56Ah,0B54Bh,08528h,09509h,0E5EEh,0F5CFh,0C5ACh,0D58Dh
	dw	03653h,02672h,01611h,00630h,076D7h,066F6h,05695h,046B4h
	dw	0B75Bh,0A77Ah,09719h,08738h,0F7DFh,0E7FEh,0D79Dh,0C7BCh
	dw	048C4h,058E5h,06886h,078A7h,00840h,01861h,02802h,03823h
	dw	0C9CCh,0D9EDh,0E98Eh,0F9AFh,08948h,09969h,0A90Ah,0B92Bh
	dw	05AF5h,04AD4h,07AB7h,06A96h,01A71h,00A50h,03A33h,02A12h
	dw	0DBFDh,0CBDCh,0FBBFh,0EB9Eh,09B79h,08B58h,0BB3Bh,0AB1Ah
	dw	06CA6h,07C87h,04CE4h,05CC5h,02C22h,03C03h,00C60h,01C41h
	dw	0EDAEh,0FD8Fh,0CDECh,0DDCDh,0AD2Ah,0BD0Bh,08D68h,09D49h
	dw	07E97h,06EB6h,05ED5h,04EF4h,03E13h,02E32h,01E51h,00E70h
	dw	0FF9Fh,0EFBEh,0DFDDh,0CFFCh,0BF1Bh,0AF3Ah,09F59h,08F78h
	dw	09188h,081A9h,0B1CAh,0A1EBh,0D10Ch,0C12Dh,0F14Eh,0E16Fh
	dw	01080h,000A1h,030C2h,020E3h,05004h,04025h,07046h,06067h
	dw	083B9h,09398h,0A3FBh,0B3DAh,0C33Dh,0D31Ch,0E37Fh,0F35Eh
	dw	002B1h,01290h,022F3h,032D2h,04235h,05214h,06277h,07256h
	dw	0B5EAh,0A5CBh,095A8h,08589h,0F56Eh,0E54Fh,0D52Ch,0C50Dh
	dw	034E2h,024C3h,014A0h,00481h,07466h,06447h,05424h,04405h
	dw	0A7DBh,0B7FAh,08799h,097B8h,0E75Fh,0F77Eh,0C71Dh,0D73Ch
	dw	026D3h,036F2h,00691h,016B0h,06657h,07676h,04615h,05634h
	dw	0D94Ch,0C96Dh,0F90Eh,0E92Fh,099C8h,089E9h,0B98Ah,0A9ABh
	dw	05844h,04865h,07806h,06827h,018C0h,008E1h,03882h,028A3h
	dw	0CB7Dh,0DB5Ch,0EB3Fh,0FB1Eh,08BF9h,09BD8h,0ABBBh,0BB9Ah
	dw	04A75h,05A54h,06A37h,07A16h,00AF1h,01AD0h,02AB3h,03A92h
	dw	0FD2Eh,0ED0Fh,0DD6Ch,0CD4Dh,0BDAAh,0AD8Bh,09DE8h,08DC9h
	dw	07C26h,06C07h,05C64h,04C45h,03CA2h,02C83h,01CE0h,00CC1h
	dw	0EF1Fh,0FF3Eh,0CF5Dh,0DF7Ch,0AF9Bh,0BFBAh,08FD9h,09FF8h
	dw	06E17h,07E36h,04E55h,05E74h,02E93h,03EB2h,00ED1h,01EF0h
;
base:	db	0
;
mode:	db	0
handl0:	db	0
handl1:	db	0
fname:	ds	21,0
file1:	ds	21,0
file2:	ds	13,0
finfo:	ds	8,0
size:	dp	0
restsize:
	dp	0
page_size:
	dp	0
line_size:
	dp	0
write_seq:
	db	0
deci:	dp	0
tenbuf:	ds	7,0
ten:	ds	7,0
total_lines:
	dp	0
total_pages:
	dp	0
rest_lines:
	db	0
reading_line:
	dp	0
wanted:	db	0
deterr:	db	0
ersq1:	db	0
erln1:	dp	0
ersq2:	db	0
erln2:	dp	0
ersq3:	db	0
erln3:	dp	0
;
lines:	dp	0
seq:	db	0
first:	db	0
rest:	db	0
eof_f:	db	0
already_read:
	db	0
;
er_adrs1:
	dp	0
er_adrs2:
	dp	0
;
sum1:	ds	68,0
sum3:	ds	68,0
;
line_buf_ptr:
	dw	0
line_buf:
	ds	80,0
i_buf:	db	0
	ds	66,0
crc1:	db	0
crc2:	db	0
d_dmy:	db	0
;
c1:	db	0
c2:	db	0
;
g_crc1:	db	0
g_crc2:	db	0
;
;
g_c1:	db	0
g_c2:	db	0
;
crc_g_f:
	db	0
;
;
dec_buf:
	ds	67*69,0
	pre_off
	end
