errmsg1:	db	'Source not opened',0
errmsg2:	db	'Bad option',0
errmsg3:	db	'Object not opened',0
errmsg4:	db	13,10,'Object write error',0
emsg1:		db	'Unexpected EOF',0
emsg2:		db	'Too long identifier',0
emsg3:		db	'Syntax error',0
emsg4:		db	'Undefined identifier',0
emsg5:		db	'Duplicate identifier',0
emsg6:		db	''';'' expected',0
emsg7:		db	'Type specifier expected',0
emsg8:		db	'Constant number expected',0
emsg9:		db	'Illegal type of identifier',0
emsg10:		db	'''('' expected',0
emsg11:		db	''')'' expected',0
emsg12:		db	'Table overflow',0
emsg13:		db	''':'' expected',0
emsg14:		db	'Type conflict',0
emsg15:		db	'Undefined function exist',0
endmsg:		db	'Compile end  [ End = $%x ]',0
;
builtin_func:	db	$62,'FPRINTF',0
		dp	fprintf
		db	$62,'PRINTF',0,0
		dp	printf
		db	$60,'SPRINTF',0
		dp	sprintf
		db	$20,'STRCMP',0,0
		dp	strcmp
		db	$24,'STRLEN',0,0
		dp	strlen
		db	$20,'ISDIGIT',0
		dp	isdigit
		db	$20,'ISALPHA',0
		dp	isalpha
		db	$20,'UPCASE',0,0
		dp	upcase
		db	$22,'GETC',0,0,0,0
		dp	getc
		db	$22,'PUTC',0,0,0,0
		dp	putc
		db	$22,'FGETC',0,0,0
		dp	fgetc
		db	$22,'FPUTC',0,0,0
		dp	fputc
		db	$24,'GETS',0,0,0,0
		dp	gets
		db	$22,'PUTS',0,0,0,0
		dp	puts
		db	$24,'FGETS',0,0,0
		dp	fgets
		db	$22,'FPUTS',0,0,0
		dp	fputs
		db	$62,'FSCANF',0,0
		dp	fscanf
		db	$60,'SSCANF',0,0
		dp	sscanf
		db	$62,'SCANF',0,0,0
		dp	scanf
		db	$24,'ATOD',0,0,0,0
		dp	atod
		db	$24,'ATOX',0,0,0,0
		dp	atox
		db	$24,'STRCPY',0,0
		dp	strcpy
		db	$24,'STRCAT',0,0
		dp	strcat
		db	$20,'_FNAME',0,0
		dp	_fname
		db	$22,'FCREAT',0,0
		dp	fcreat
		db	$22,'FOPEN',0,0,0
		dp	fopen
		db	$22,'FCLOSE',0,0
		dp	fclose
		db	$24,'FSEEK',0,0,0
		dp	fseek
		db	$24,'FREAD',0,0,0
		dp	fread
		db	$24,'FWRITE',0,0
		dp	fwrite
		db	$22,'REMOVE',0,0
		dp	remove
		db	$22,'FCNTL',0,0,0
		dp	_fcntl
		db	$22,'IOCS',0,0,0,0
		dp	_iocs
		db	$24,'SBRK',0,0,0,0
		dp	sbrk
		db	$22,'RAND',0,0,0,0
		dp	rand
		db	$20,'SRAND',0,0,0
		dp	srand
		db	$22,'KSCAN',0,0,0
		dp	kscan
		db	$20,'ERRNUM',0,0
		dp	perror
		db	$22,'FORK',0,0,0,0
		dp	fork
		db	$20,'PID',0,0,0,0,0
		dp	pid
		db	$24,'FREE',0,0,0,0
		dp	free
		db	$22,'SLEEP',0,0,0
		dp	sleep
		db	$22,'WAKEUP',0,0
		dp	wakeup
		db	$22,'PSTAT',0,0,0
		dp	pstat
		db	$22,'KILL',0,0,0,0
		dp	kill
		db	$20,'GETRAM',0,0
		dp	getram
		db	$20,'SETRAM',0,0
		dp	setram
		db	$22,'S_PROJ',0,0
		dp	s_proj
		db	$22,'S_PIXEL',0
		dp	s_pixel
		db	$22,'S_POINT',0
		dp	s_point
		db	$22,'S_LINE',0,0
		dp	s_line
		db	$22,'S_BOX',0,0,0
		dp	s_box
		db	$22,'S_FILL',0,0
		dp	s_fill
		db	$20,'S_CLEAR',0
		dp	s_clear
		db	$22,'S_COPY',0,0
		dp	s_copy
		db	$22,'S_REAL',0,0
		dp	s_real
		db	$22,'S_TAKE',0,0
		dp	s_take
		db	$20,'S_SHIFT',0
		dp	s_shift
		db	$22,'S_PUTS',0,0
		dp	s_puts
		db	$22,'S_PUTC',0,0
		dp	s_putc
		db	$20,'KEY',0,0,0,0,0
		dp	key
		db	$20,'BEEP',0,0,0,0
		dp	beep
		db	$22,'ABS',0,0,0,0,0
		dp	abs
		db	$22,'SGN',0,0,0,0,0
		dp	sgn
		db	$20,'LOCATE',0,0
		dp	locate
		db	$24,'ALARMF',0,0
		dp	alarmf
		db	$24,'ALARMS',0,0
		dp	alarms
		db	$20,'LATEST',0,0
		dp	latest
		db	$20,'MIDITX',0,0
		dp	miditx
		db	$24,'ATOF',0,0,0,0
		dp	atof
		db	$24,'FTOA',0,0,0,0
		dp	ftoa
		db	$24,'_MATH1',0,0
		dp	_math1
		db	$24,'_MATH2',0,0
		dp	_math2
		db	$24,'ITOF',0,0,0,0
		dp	itof
		db	$22,'FTOI',0,0,0,0
		dp	ftoi
		db	$24,'MOVE',0,0,0,0
		dp	move
		db	$24,'MOVEZ',0,0,0
		dp	movez
		db	$24,'ARGP',0,0,0,0
		dp	argp
		db	$20,'CBREAK',0,0
		dp	user_break
		db	$fe
;
start_symbol:	db	'file?',0
main_start:	ds	2
symadr:		ds	3
while_out:	ds	3
while_links:	ds	1
txtpnt:		ds	3
txtcount:	ds	1
dev_attr:	ds	1
objpoint:	ds	3
objcount:	ds	1
header:		db	$ff,$00,$06,$01,$10,$00,$00,$00
		db	!start,!start/256,$0b,$ff,$ff,$ff,$00,$0f
;
		end
