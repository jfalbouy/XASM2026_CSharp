;
;		ish file encoder for TY-DOS (PC-E500/1480U)   Ver 1.21
;			Programmed  by  E. Kako (JM2WGN)
;
;		ORIGIANAL MS-DOS VERSION
;			Copyright (c) 1986, 1987, 1989  by  M. ishizuka
;			All rights reserved.
;
;		USAGE : ishe filename     ...  create and store ish_file
;			ishe filename -s  ...  output ish_file to SIO
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
	mv	a,0
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
	mv	a,0
	call	write
	jp	exit
;
start:	pushu	x		;cmdlin_btm save
	mv	x,msg3		;(opening message)
	mv	a,0
	call	write
	mv	il,0bh
	mv	x,fname
	mv	y,finfo
	mv	a,0
	callf	F_CALL		;file_iocs_12
	jrnc	lbl1
;
	mv	x,msg4		;(file not found)
	mv	a,0
	call	write
	jp	exit
;
lbl1:	mv	x,[size]
	dec	x
	jrz	lbl2
	dec	x
	jrz	lbl2
	jr	lbl3
;
lbl2:	mv	x,msg5		;(too short file)
	mv	a,0
	call	write
	jp	exit
;
lbl3:	mv	x,fname
	mv	y,file1
	mv	il,15
	mv	a,[outsio]
	cmp	a,0
	jrnz	lbl5
lbl4:	mv	a,[x++]
	mv	[y++],a
	dec	il
	jrnz	lbl4
	mv	a,'I'
	mv	[y++],a
	mv	a,'S'
	mv	[y++],a
	mv	a,'H'
	mv	[y++],a
	mv	a,0
	mv	[y++],a
;
	mv	il,0bh
	mv	x,file1
	mv	y,finfo2
	mv	a,0
	callf	F_CALL		;file_iocs_12
	jrc	lbl5
;
	mv	x,msg6		;(ish file exist)
	mv	a,0
	call	write
	jp	exit
;
lbl5:	mv	x,fname		;fopen 'fname' for input as handle0
	mv	il,1
	mv	a,1
	callf	F_CALL		;file_iocs_1
	mv	a,(0d6h)
	mv	[handl0],a
;
	mv	x,file1		;fopen 'file1' for output as handle1
	mv	a,[outsio]
	cmp	a,0
	jrz	lbl5a
	mv	x,sio
lbl5a:	mv	il,0
	mv	a,0
	callf	F_CALL		;file_iocs_0
	mv	a,(0d6h)
	mv	[handl1],a
;
	mv	a,1
	mv	[mode],a
;
	mv	x,fname+6
	mv	y,file2
	mv	il,13
lbl6:	mv	a,[x++]
	dec	il
	jrz	lbl7
	cmp	a,' '
	jrz	lbl6
	mv	[y++],a
	jr	lbl6
lbl7:	mv	a,0
	mv	[y++],a
	mv	x,msg7		;( <<< )
	mv	a,[handl1]
	call	write
	mv	x,file2		;( encode filename )
	mv	a,[handl1]
	call	write
	mv	x,msg8		;( for TYDOS ( use ish ) )
	mv	a,[handl1]
	call	write
;
	mv	x,[size]
	inc	x
	mv	y,66
	mv	il,0
lbl8:	sub	x,y
	inc	i
	jrnc	lbl8
	mv	x,i
	mv	[size2],x
	mv	i,0
lbl9:	sub	x,y
	inc	i
	jrnc	lbl9
	mv	x,[size2]
	add	x,i
	add	x,i
	inc	x
	inc	x
	inc	x
	inc	x
	mv	[size2],x
	mv	y,50
	mv	il,0
lbl10:	sub	x,y
	inc	i
	jrnc	lbl10
	mv	x,[size2]
	add	x,i
	mv	[size2],x
	call	number		;( [ x )
	mv	a,[handl1]
	call	write
	mv	x,msg9		;( lines ] >>> )
	mv	a,[handl1]
	call	write
;
	mv	x,i_buf		;store ish_header
	mv	il,67
	mv	a,0
lbl11:	mv	[x++],a
	dec	il
	jrnz	lbl11
	mv	x,[size]
	mv	[i_buf+2],x	;file size
	mv	il,69
	mv	[i_buf+6],i	;data number in 1 line
	mv	il,68
	mv	[i_buf+8],i	;line number in 1 block
	mv	i,0808h
	mv	[i_buf+10],i	;code length / org:jis8, ish:jis8
	mv	x,fname+6
	mv	y,i_buf+12
	mv	il,8
lbl12:	mv	a,[x++]		;filename
	mv	[y++],a
	dec	il
	jrnz	lbl12
	inc	x
	mv	il,3
lbl13:	mv	a,[x++]
	mv	[y++],a
	dec	il
	jrnz	lbl13
	mv	i,01ffh		; os_type : 0feh ... other OSs
	mv	[i_buf+24],i	; ish_ext :  01h ... 2 line correction
;
;	byte	[i_buf+26] : 0...timestamp not available / 1...available
;	word	[i_buf+27] : date...msdos file control block format
;	word	[i_buf+29] : time...cf. msdos programmer's reference manual
;
	mv	il,59
	call	crc7
	mv	x,i_buf+61
	mv	a,[crc1]
	mv	[x++],a
	mv	a,[crc2]
	mv	[x++],a
	mv	a,0
	mv	[x++],a
	call	encode_jis7
	mv	x,o_buf
	mv	a,[handl1]
	call	write		;(header lines)
	mv	x,o_buf
	mv	a,[handl1]
	call	write		;(header lines)
	mv	x,o_buf
	mv	a,[handl1]
	call	write		;(header lines)
;
	mv	x,5
	mv	[lines],x
	mv	a,0
	mv	[first],a
	mv	[rest],a
	mv	[eof_f],a
;
loop1:	mv	a,1		;init sum
	mv	[seq],a
	mv	il,68
	mv	x,sum1
	mv	y,sum3
	mv	a,0
loop1a:	mv	[x++],a
	mv	[y++],a
	dec	il
	jrnz	loop1a
;
loop2:	mv	il,69		;init input line buffer
	mv	x,i_buf
	mv	a,0
loop2a:	mv	[x++],a
	dec	il
	jrnz	loop2a
loop2b:	mv	a,[seq]
	mv	[i_buf],a
	cmp	a,67
	jrnz	loop4
;
loop3:	mv	il,66		;output vertical sum
	mv	x,sum1+1
	mv	y,i_buf+1
loop3a:	mv	(0),[x++]
	mv	a,0
	sub	a,(0)
	mv	[y++],a
	dec	il
	jrnz	loop3a
	jp	loop7b
;
loop4:	cmp	a,68		;dummy for vertical interval sum
	jrnz	loop6
	mv	a,69
	mv	[seq],a
	mv	[i_buf],a
;
loop5a:	mv	il,66		;output slope sum
	mv	x,sum3
	mv	y,i_buf+1
loop5b:	mv	(0),[x++]
	mv	a,0
	sub	a,(0)
	mv	[y++],a
	dec	il
	jrnz	loop5b
	jp	loop7g
;
loop6:	mv	a,[rest]
	cmp	a,1
	jrnz	loop6a
	mv	a,0
	mv	[rest],a	;crc 1 byte rest (last half)
	mv	a,[g_crc2]
	mv	[i_buf+1],a
	mv	a,1
	mv	[eof_f],a
	jr	loop7
;
loop6a:	mv	a,[handl0]	;read from 'fname'
	mv	(0d6h),a
	mv	il,3
	mv	x,i_buf+1
	mv	y,66
	mv	a,1
	callf	F_CALL		;file_iocs_3
	mv	x,[size]
	mv	y,66
	sub	x,y
	jrc	loop6b
;
	mv	[size],x	;not touch eof
	mv	il,66
	call	calc_crc_2
	jr	loop7
;
loop6b:	mv	y,[size]
	mv	a,y		;touch eof
	cmp	a,0
	jrnz	loop6c
;
	call	calc_crc_3	;(case of  rest 0 byte)
	mv	a,[g_crc1]	;crc 2 bytes rest
	mv	[i_buf+1],a
	mv	a,[g_crc2]
	mv	[i_buf+2],a
	mv	a,1
	mv	[eof_f],a
	jr	loop7
;
loop6c:	cmp	a,65
	jrnz	loop6d
	mv	il,65
	call	calc_crc_2
	call	calc_crc_3	;(case of  rest 65 bytes)
	mv	a,[g_crc1]	;crc 1 byte rest (prevent half)
	mv	[i_buf+66],a
	mv	a,1
	mv	[rest],a
	jr	loop7
;
loop6d:	mv	il,a
	call	calc_crc_2
	call	calc_crc_3	;(case of  rest 1,,64 bytes)
	mv	x,i_buf+1
	mv	y,[size]
	add	x,y
	mv	a,[g_crc1]
	mv	[x++],a
	mv	a,[g_crc2]
	mv	[x++],a
	mv	a,1
	mv	[eof_f],a
	jr	loop7
;
loop7:	mv	il,66		;calc vertical sum
	mv	x,i_buf+1
	mv	y,sum1+1
loop7a:	mv	(0),[x++]
	mv	a,[y]
	add	a,(0)
	mv	[y++],a
	dec	il
	jrnz	loop7a
;
loop7b:	mv	il,67		;calc slope sum
	mv	x,i_buf
	mv	y,sum3
	mv	(0),[seq]
	dec	(0)
loop7c:	pushu	y
	mv	a,(0)
	mv	y,x
	add	y,a
	mv	a,[y]
	popu	y
	mv	(1),[y]
	add	(1),a
	mv	[y++],(1)
	inc	(0)
	cmp	(0),67
	jrnz	loop7d
	mv	(0),0
loop7d:	dec	il
	jrnz	loop7c
	mv	a,[eof_f]
	cmp	a,0
	jrz	loop7g
;
loop7e:	mv	a,[seq]
	cmp	a,66
	jrz	loop7g
	mv	(0),a		;add seq_number to slope sum 
	inc	(0)
	mv	x,sum3
loop7f:	mv	a,68
	sub	a,(0)
	mv	y,x
	add	y,a
	mv	a,[y]
	add	a,(0)
	mv	[y],a
	inc	(0)
	cmp	(0),67
	jrnz	loop7f
	mv	a,66
	mv	[seq],a
	mv	a,0
	mv	[eof_f],a
;
loop7g:	call	calc_crc_1	;output 1 line to ish_file!!!!!!!!!!!
	call	ish_encode
	mv	x,o_buf
	mv	a,[handl1]
	call	write
;
loop8:	mv	a,[seq]
	inc	a
	mv	[seq],a
	mv	x,[lines]
	inc	x
	mv	[lines],x
	mv	y,[size2]
	sub	x,y
	jrz	loop9
;
	mv	x,[lines]
	mv	y,50
loop8a:	sub	x,y
	jrz	loop8b
	jrnc	loop8a
	jr	loop8c
;
loop8b:	mv	x,[lines]	;[lines] mod 50 equal zero
	mv	y,[size2]
	call	remark_line	;(remark)
	mv	x,[lines]
	inc	x
	mv	[lines],x
	mv	y,[size2]
	sub	x,y
	jrz	loop9a
loop8c:	mv	a,[seq]
	cmp	a,70
	jpnz	loop2
	jp	loop1
;
loop9:	mv	x,[lines]	;output final lines
	call	remark_line	;(remark)
loop9a:	mv	x,o_buf
	mv	a,01ah		;EOF code
	mv	[x++],a
	mv	a,0
	mv	[x++],a
	mv	x,o_buf		;output eof
	mv	a,[handl1]
	call	write
;
	mv	x,msg14		;(success message)
	mv	a,0
	call	write
;
exit:	mv	a,[mode]
	cmp	a,0
	jrz	exit1
	mv	a,[handl0]	;close file 'fname'
	mv	(0d6h),a
	mv	il,2
	callf	F_CALL		;file_iocs_2
;
	mv	a,[handl1]	;close file 'file1'
	mv	(0d6h),a
	mv	il,2
	callf	F_CALL		;file_iocs_2
;
exit1:	mv	a,[base]
	mv	(0ech),a	;BP restore
	rc			;reset CF
	retf
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
remark_line:
	mv	x,msg10
	mv	a,[handl1]
	call	write
	mv	x,file2
	mv	a,[handl1]
	call	write
	mv	x,msg11
	mv	a,[handl1]
	call	write
	mv	x,[lines]
	call	number
	mv	a,[handl1]
	call	write
	mv	x,msg12
	mv	a,[handl1]
	call	write
	mv	x,[size2]
	call	number
	mv	a,[handl1]
	call	write
	mv	x,msg13
	mv	a,[handl1]
	call	write
	ret
;
;
ish_encode:			;8bit->7bit
	mv	x,i_buf
	mv	y,o_buf
	mv	il,10
;
enc1:	mv	a,[x]
	and	a,07fh
	mv	[y++],a
;
	mv	a,[x++]
	and	a,080h
	mv	(0),[x]
	and	(0),03fh
	or	a,(0)
	rol	a
	mv	[y++],a
;
	mv	a,[x++]
	and	a,0c0h
	mv	(0),[x]
	and	(0),01fh
	or	a,(0)
	rol	a
	rol	a
	mv	[y++],a
;
	mv	a,[x++]
	and	a,0e0h
	mv	(0),[x]
	and	(0),0fh
	or	a,(0)
	rol	a
	rol	a
	rol	a
	mv	[y++],a
;
	mv	a,[x++]
	and	a,0f0h
	mv	(0),[x]
	and	(0),07h
	or	a,(0)
	swap	a
	mv	[y++],a
;
	mv	a,[x++]
	and	a,0f8h
	mv	(0),[x]
	and	(0),03h
	or	a,(0)
	ror	a
	ror	a
	ror	a
	mv	[y++],a
;
	mv	a,[x++]
	and	a,0fch
	mv	(0),[x]
	and	(0),01h
	or	a,(0)
	ror	a
	ror	a
	mv	[y++],a
;
	mv	a,[x++]
	and	a,0feh
	ror	a
	mv	[y++],a
;
	dec	il
	jrnz	enc1
	mv	x,o_buf		;7bit->jis8code
	mv	il,79
	mv	ba,0
enc2:	mv	a,[x]
	mv	y,encode_table
	add	y,ba
	mv	a,[y]
	mv	[x++],a
	dec	il
	jrnz	enc2
	mv	a,CR
	mv	[x++],a
	mv	a,LF
	mv	[x++],a
	mv	a,0
	mv	[x++],a
	ret
;
;
;
encode_jis7:
	mv	x,i_buf		;8bit ---> 13bit (6.5bit)
	mv	y,o_buf
;
	mv	a,[x]		;No. 1   byte (6bit)
	and	a,03fh
	mv	[y++],a
;
	mv	a,[x++]		;No. 2   byte (6bit)
	and	a,0c0h
	mv	(0),[x]
	and	(0),0fh
	or	a,(0)
	rol	a
	rol	a
	mv	[y++],a
;
	mv	a,[x++]		;No. 3   byte (6bit)
	and	a,0f0h
	mv	(0),[x]
	and	(0),03h
	or	a,(0)
	swap	a
	mv	[y++],a
;
	mv	a,[x++]		;No. 4   byte (6bit)
	and	a,0fch
	ror	a
	ror	a
	mv	[y++],a
;
	mv	(9),74		;No. 5 .. 78 byte   ( 13bit (6.5bit) )
	mv	(0),[x++]
	mv	(1),8
enc13:
	mvw	(3),0
	mv	(2),13
enc13a:	ror	(0)
	shr	(4)
	shr	(3)
	dec	(1)
	jrnz	enc13b
	mv	(0),[x++]
	mv	(1),8
enc13b:	dec	(2)
	jrnz	enc13a
	rc
	shr	(4)
	shr	(3)
	shr	(4)
	shr	(3)
	shr	(4)
	shr	(3)
div91:
	mv	ba,(3)
	mv	il,91
	mv	(5),0
div_a:	sub	ba,i
	jrc	div_b
	inc	(5)
	jr	div_a
div_b:	add	ba,i
	mv	(6),a
	mv	[y++],(5)
	mv	[y++],(6)
	dec	(9)
	jrnz	enc13
;
	mv	x,o_buf		;13bit (6.5bit) --> jis7code
	mv	il,78
	mv	ba,0
enc7a:	mv	a,[x]
	mv	y,table_jis7
	add	y,ba
	mv	a,[y]
	mv	[x++],a
	dec	il
	jrnz	enc7a
	mv	a,CR
	mv	[x++],a
	mv	a,LF
	mv	[x++],a
	mv	a,0
	mv	[x++],a
	ret
;
;
calc_crc_1:			;calculate crc
	mv	il,65
crc7:	mv	x,i_buf
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
	mv	a,[c1]
	mv	[crc1],a
	mv	a,[c2]
	mv	[crc2],a
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
calc_crc_2:
	mv	x,i_buf+1
	mv	a,[first]
	cmp	a,0
	jrnz	crc_2a
	mv	a,1
	mv	[first],a
	mv	a,[x++]
	xor	a,0ffh
	mv	[g_crc1],a
	mv	a,[x++]
	xor	a,0ffh
	mv	[g_crc2],a
	dec	il
	dec	il
crc_2a:	mv	y,crc_data_table
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
	jrnz	crc_2a
	ret
;
calc_crc_3:
	mv	il,2
crc_3a:	mv	y,crc_data_table
	mv	ba,0
	mv	a,[g_crc1]
	add	ba,ba
	add	y,ba
	mvw	(0),[y++]
	mv	a,[g_crc2]
	xor	(1),a
	mv	[g_crc1],(1)
	mv	[g_crc2],(0)
	dec	il
	jrnz	crc_3a
	mv	a,[g_crc1]
	xor	a,0ffh
	mv	[g_crc1],a
	mv	a,[g_crc2]
	xor	a,0ffh
	mv	[g_crc2],a
	ret
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
write:	mv	(0d6h),a
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
	jrc	wrt2
	ret
;
wrt2:	pops	a
	pops	a
	mv	x,msg15
	mv	a,0
	call	write
	jp	exit
;
;
sio:	db	'COM:        .   ',0
;
msg1:	db	'ish file encoder V1.2  by E.Kako',CR,LF,0
msg2:	db	'USAGE : ishe filename [-s]',CR,LF,0
msg3:	db	'[ store <JIS8 format> (*) ]',CR,LF,0
msg4:	db	'source file not found.',CR,LF,0
msg5:	db	'source file too short.',CR,LF,0
msg6:	db	'ish_file already exist.',CR,LF,0
msg7:	db	'<<< ',0
msg8:	db	' for TY-DOS/PC-E500/1480U ( use ish ) [ ',0
msg9:	db	' lines ] >>>',CR,LF,0
msg10:	db	'--- ',0
msg11:	db	' (',0
msg12:	db	'/',0
msg13:	db	') ---',CR,LF,0
msg14:	db	'ish_file is created.',CR,LF,0
msg15:	db	'disk output error.',CR,LF,0
;
encode_table:
	db	 23h, 25h, 26h, 27h, 29h, 2bh, 2ch, 3fh
	db	 2fh, 32h, 34h, 35h, 36h, 37h, 38h, 39h
	db	 3ah, 3bh, 3ch, 3dh, 3eh, 41h, 42h, 43h
	db	 44h, 45h, 46h, 47h, 48h, 49h, 4bh, 4ch
	db	 4eh, 4fh, 52h, 54h, 55h, 56h, 57h, 58h
	db	 59h, 5ah, 5bh, 5ch, 5dh, 5eh, 61h, 62h
	db	 63h, 64h, 65h, 66h, 67h, 68h, 69h, 6ah
	db	 6bh, 6ch, 6dh, 6eh, 70h, 71h, 72h, 73h
	db	 74h, 75h, 76h, 78h, 79h, 7ah, 7ch,0a1h
	db	0a2h,0a3h,0a4h,0a5h,0a6h,0a7h,0a8h,0a9h
	db	0aah,0abh,0ach,0aeh,0afh,0b0h,0b1h,0b2h
	db	0b4h,0b5h,0b6h,0b7h,0b8h,0b9h,0bah,0bbh
	db	0bch,0bdh,0beh,0c0h,0c1h,0c2h,0c3h,0c4h
	db	0c5h,0c6h,0c7h,0c8h,0c9h,0cah,0cbh,0cch
	db	0ceh,0cfh,0d0h,0d1h,0d2h,0d4h,0d5h,0d6h
	db	0d7h,0d8h,0d9h,0dah,0dbh,0dch,0ddh,0deh
;
table_jis7:
	db	 21h, 22h, 24h, 25h, 26h, 27h, 28h, 29h
	db	 2ah, 2bh, 2ch, 2dh, 2fh, 30h, 31h, 32h
	db	 33h, 34h, 35h, 36h, 37h, 38h, 39h, 3ah
	db	 3bh, 3ch, 3dh, 3eh, 3fh, 40h, 41h, 42h
	db	 43h, 44h, 45h, 46h, 47h, 48h, 49h, 4ah
	db	 4bh, 4ch, 4dh, 4eh, 4fh, 50h, 51h, 52h
	db	 53h, 54h, 55h, 56h, 57h, 58h, 59h, 5ah
	db	 5bh, 5ch, 5dh, 5eh, 5fh, 61h, 62h, 63h
	db	 64h, 65h, 66h, 67h, 68h, 69h, 6ah, 6bh
	db	 6ch, 6dh, 6eh, 6fh, 70h, 71h, 72h, 73h
	db	 74h, 75h, 76h, 77h, 78h, 79h, 7ah, 7bh
	db	 7ch, 7dh, 7eh
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
outsio:	db	0
handl0:	db	0
handl1:	db	0
fname:	ds	21,0
file1:	ds	21,0
file2:	ds	13,0
finfo:	db	0
date:	ds	4,0
size:	dp	0
size2:	dp	0
finfo2:	ds	8,0
deci:	dp	0
tenbuf:	ds	7,0
ten:	ds	7,0
lines:	dp	0
seq:	db	0
first:	db	0
rest:	db	0
eof_f:	db	0
;
sum1:	ds	68,0
sum3:	ds	68,0
;
i_buf:	db	0
	ds	66,0
crc1:	db	0
crc2:	db	0
e_dmy:	db	0
;
c1:	db	0
c2:	db	0
;
g_crc1:	db	0
g_crc2:	db	0
;
o_buf:	ds	82,0
;
;
	pre_off
	end
