/*********************************************************************
***                                                                ***
***  XASM Ver1.40  [ Absolute-type Cross Assembler for SC-62015 ]  ***
***    XASM Ver1.40 is written in C  Copyright(c)1995-1996 E.Kako  ***
***                                                                ***
***  XASM  is  Copyright(c)1990-1993 N.Kon                         ***
***    original XASM is written in Turbo-Pascal Ver3.0             ***
***                                                                ***
*********************************************************************/

#define   VERSION   "1.40 "

#include    <stdio.h>
#include    <stdlib.h>
#include    <string.h>
#include    <ctype.h>
#include    <stdbool.h>
#include    <stdint.h>
#include    <time.h>




#define  stricpy(s,t,l)   (strncpy(s,t,l),s[l]='\0');
#define  stradd(s,c)      ((s[strlen(s)+1]='\0'),(s[strlen(s)]=c))
#define  strdel(s,l)      (strcpy(s,s+l))
#define  top(s)           (s[0])
#define  bottom(s)        (s[strlen(s)-1])
#define  isnul(s)         (*(s)=='\0')
#define  isXnul(s)        (*(s)!='\0')
#define  len(s)           (strlen(s))
#define  c2upper(c)       ((((c)>='a')&&((c)<='z'))?((c)-'a'+'A'):(c))

#define  islabel(c)       islabel_table[c]
#define  islabel2(c)      islabel2_table[c]
#define  oprlevel(c)      oprlevel_table[c]
#define  delimiter(c)     delimiter_table[c]

#ifndef  NULL
#define  NULL             ((void *)0)
#endif
#ifndef  TRUE
#define  TRUE             1
#endif
#ifndef  FALSE
#define  FALSE            0
#endif
#define  NIL              NULL

#define  MAXHASH          64
#define  MAXHASH2         256

typedef long int  sc_reg;

typedef unsigned char byte;
typedef struct label_typ_record {
        sc_reg value; struct label_typ_record **child, *next;
        unsigned char name[1];
}       label_typ;
typedef struct file_typ_record {
        unsigned char name[128];  int lines;  FILE *fp_txt;
        struct file_typ_record *pre;
        sc_reg arg[10];  unsigned char arg_cnt; int l_stack_p, pre_stack_p;
}       file_typ;
typedef struct reslist {
        unsigned char id_name[10];  int id_num;
        struct reslist *next;
}       rlist;
typedef struct macro_record {
        unsigned char name[16], argc, argv[16][16], *define[256], lnum;
        struct macro_record *next;
}       macro_typ;
typedef struct generated_byte_record {
        sc_reg addr; unsigned char value;
}       generated_byte_typ;
typedef struct section_record {
        unsigned char name[32]; sc_reg start, end;
}       section_typ;
extern bool listing_on, object_on, symbol_on, count_on, warning_on, err_on;
extern bool ihex_on, srec_on, map_on, dep_on, verbose_on, size_report_on, basic_uu_on, hxd_on;
extern bool struct_on;
extern bool new_line, undef_flag2, fatal_err, undef_flag, pre_on, top_of_line;
extern bool org_set, endflag, label_exist, s_end, defined, undefined, scope;
extern unsigned char asmtext[256], inbuf[256], x_label[256], oprtxt[256];
extern unsigned char obj_typ, TEMP[256];
extern unsigned char source_name[128], object_name[128], listing_name[128], listing_line[256];
extern unsigned char ihex_name[128], srec_name[128], map_name[128], dep_name[128], basic_uu_name[128], hxd_name[128];
extern unsigned char struct_name[32];
extern unsigned char header[16];
extern unsigned char oprlevel_table[256], delimiter_table[256];
extern unsigned char islabel_table[256], islabel2_table[256];
extern unsigned char mm_argc,mm_argv[16][80];
extern unsigned char csum, offset, typ, pass_sw, mflag;
extern label_typ *l_stack[16];
extern unsigned char o_stack[17];
extern sc_reg v_stack[16];
extern unsigned char pre_stack[16];
extern int l_stack_p, o_stack_p, v_stack_p, pre_stack_p, mline, maxhash;
extern int pp, err, lines,  object_cnt, listing_count, no_name_lbl, in_macro;
extern int generated_count, generated_cap, section_count, section_cap, current_section;
extern int dependency_count, dependency_cap;
extern int current_ifdef_stat,ifdef_level,dflag,ifdef_stat[16];
extern unsigned char ifdef_name[16][80];
extern sc_reg slc, lc, x, y, struct_size;
extern file_typ *current_file, *new_file;
extern label_typ *next_pnt, *equ_pnt, *equ_pnt2, *undefined_pnt;
extern rlist *reshash[MAXHASH2];
extern label_typ **lblhash, root;
extern macro_typ *macros, *mcr;
extern FILE *fp_object, *fp_listing;
extern generated_byte_typ *generated_bytes;
extern section_typ *sections;
extern unsigned char **dependencies;

extern sc_reg regular(sc_reg x);
extern unsigned char xlow(sc_reg x);
extern unsigned char xmid(sc_reg x);
extern unsigned char xhigh(sc_reg x);
extern unsigned char *hex_string(sc_reg m);
extern unsigned char no_operand(unsigned char offset);
extern unsigned char prebyte(unsigned char a, unsigned char b);
extern unsigned char regname(unsigned char *tmp);
extern unsigned char mv_operand(unsigned char mvflag, int *pnt);
extern unsigned char two_operand(unsigned char typ, unsigned char offset, int *pnt);
extern unsigned char one_operand(unsigned char typ, unsigned char offset);
extern label_typ **new_lblhash(void), *add_lblhash(), *chk_lblhash();
extern macro_typ *new_macro(void), *check_macro();
extern void init_defs(void);
extern int chk_defs(unsigned char *s);
extern int add_defs(unsigned char *s);
extern int del_defs(unsigned char *s);
extern int write_adr(void);
extern int taiou(unsigned char *tmp);
extern int r_to_i32(sc_reg x, int *ih, int *il);
extern int i32_to_r(int ih, int il, sc_reg *x);
extern int set_op(unsigned char x);
extern int set_reg_opecode(unsigned char a, unsigned char b, unsigned char c, unsigned char d);
extern int set_r3_opecode(unsigned char a, unsigned char b, unsigned char c);
extern int set_mn_opecode(unsigned char a, unsigned char b, unsigned char c, unsigned char d);
extern int replace(unsigned char *pat, int pos, int l);
extern int strmatch(unsigned char *txt, unsigned char *pat);
extern int compf(unsigned char *pat, int m, int *f);
extern void default_ext(unsigned char *dst, const unsigned char *src, const char *ext);
extern void parse_option_filename(int *idx, int argc, char **argv, unsigned char *dst);
extern void record_generated_byte(sc_reg addr, unsigned char value);
extern void reset_generated_bytes(void);
extern void reset_sections(void);
extern void section_start(const unsigned char *name);
extern void section_finish(sc_reg end);
extern void section_report_stdout(void);
extern void write_ihex_file(void);
extern void write_srec_file(void);
extern void write_map_file(void);
extern void write_dep_file(void);
extern void write_basic_uu_file(void);
extern void write_hxd_file(void);
extern void record_dependency(const unsigned char *name);
extern int emit_repeat_block(void);
extern int enter_numeric_if(int mode);
extern int close_struct(void);
#include "protos.h"
