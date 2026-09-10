;
;
;	Vogue  -- An concurrent exclusive compiler based on ESPRIT --
;
;
;	(Vogue will come into vogue because of its incredible power!)
;
;
;	Usage: CALL &B9800
;
;
;
;	Last change: May 17th,1992
;
;	(c)1991/1992 Narihito Kon
;
;
		org	$b9800
;
		pre_on
;
src_work1:	equ	0
src_work2:	equ	3
src_symswitch:	equ	6
src_pnt:	equ	7
src_handle:	equ	10
src_stat:	equ	11
line1:		equ	12
line2:		equ	14
src_char:	equ	17
src_sym:	equ	18
make_size:	equ	19
src_table:	equ	22
obj_adr:	equ	25
release_size:	equ	28
func_type:	equ	31
var_type:	equ	32
var_size:	equ	33
release_adr:	equ	36
src_zero:	equ	39
src_local:	equ	42
prcs_head:	equ	45
prcs_limit:	equ	48
define_type:	equ	51
obj_pnt:	equ	52
errnum:		equ	55
random:		equ	56
productive_prcs:equ	59
obj_handle:	equ	62
alive_prcs:	equ	63
;
cur_x:		equ	0
cur_y:		equ	1
org_x:		equ	2
org_y:		equ	3
key_top:	equ	5
key_pos:	equ	8
max_x:		equ	12
max_y:		equ	13
bl:		equ	$d4
bh:		equ	$d5
bx:		equ	$d4
cl:		equ	$d6
ch:		equ	$d7
cx:		equ	$d6
dl:		equ	$d8
dh:		equ	$d9
dx:		equ	$d8
si:		equ	$da
di:		equ	$dd
key_strobe_l:	equ	$f0
key_strobe_h:	equ	$f1
key_sense:	equ	$f2
system_ctrl_reg:equ	$fd
system_stat_reg:equ	$ff
table_end:	equ	$bf7ff
fcntl:		equ	$fffe4
iocs:		equ	$fffe8
scrn_cur_x:	equ	$bfc27
scrn_max_x:	equ	$bfc9d
default_drive:	equ	$bfc7d
basic_work_top:	equ	$bfd0e
char_adrs_1:	equ	$bfc87
char_adrs_2:	equ	$bfc90
char_adrs_3:	equ	$bfc8a
char_adrs_4:	equ	$bfc93
char_adrs_5:	equ	$bfc8d
handle_table:	equ	$bfc6d
ctime_u_top:	equ	$bf000
main_top:	equ	$bf800
rtime_s_top:	equ	main_top-16
rtime_u_top:	equ	main_top-$400-16
ir_trap:	equ	$bfcdb
timerf:		equ	$bfcc6
timers:		equ	$bfcc9
;
from_x:		equ	6
from_y:		equ	8
source_x_size:	equ	10
source_y_size:	equ	12
dest_x_size:	equ	14
dest_y_size:	equ	16
point_x:	equ	18
point_y:	equ	20
to_x:		equ	22
to_y:		equ	24
x_count:	equ	26
y_count:	equ	28
source_ring_o:	equ	30
dest_ring_o:	equ	31
source_adrs:	equ	32
dest_adrs:	equ	35
dest_opr:	equ	38
;
dest_ring:	equ	18
source_data:	equ	19
dest_data:	equ	20
y_count_t:	equ	21
;
start:		jp	main
;
		include	runtime.s
		include	compile.s
obj_start:
objbuf:
;
		end
