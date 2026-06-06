#include "xasm.h"

bool listing_on, object_on, symbol_on, count_on, warning_on, err_on;
bool ihex_on, srec_on, map_on, dep_on, verbose_on, size_report_on, basic_uu_on, hxd_on;
bool struct_on;
bool new_line, undef_flag2, fatal_err, undef_flag, pre_on, top_of_line;
bool org_set, endflag, label_exist, s_end, defined, undefined, scope;
unsigned char asmtext[256], inbuf[256], x_label[256], oprtxt[256];
unsigned char obj_typ, TEMP[256];
unsigned char source_name[128], object_name[128], listing_name[128], listing_line[256];
unsigned char ihex_name[128], srec_name[128], map_name[128], dep_name[128], basic_uu_name[128], hxd_name[128];
unsigned char struct_name[32];
unsigned char header[16] = {
    255, 0, 6, 1, 16, 0, 0, 0, 0, 0, 0, 255, 255, 255, 0, 15
};
unsigned char oprlevel_table[256], delimiter_table[256];
unsigned char islabel_table[256], islabel2_table[256];
unsigned char mm_argc,mm_argv[16][80];
unsigned char csum, offset, typ, pass_sw, mflag;
label_typ *l_stack[16];
unsigned char o_stack[17];
sc_reg v_stack[16];
unsigned char pre_stack[16];
int l_stack_p, o_stack_p, v_stack_p, pre_stack_p, mline, maxhash;
int i, pp, err, lines,  object_cnt, listing_count, no_name_lbl, in_macro;
int generated_count, generated_cap, section_count, section_cap, current_section;
int dependency_count, dependency_cap;
int current_ifdef_stat,ifdef_level,dflag,ifdef_stat[16];
unsigned char ifdef_name[16][80];
sc_reg slc, lc, x, y, struct_size;
file_typ *current_file, *new_file;
label_typ *next_pnt, *equ_pnt, *equ_pnt2, *undefined_pnt;
rlist *reshash[MAXHASH2];
label_typ **lblhash, root;
macro_typ *macros, *mcr;
FILE *fp_object, *fp_listing;
generated_byte_typ *generated_bytes;
section_typ *sections;
unsigned char **dependencies;
