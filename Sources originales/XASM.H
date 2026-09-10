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

#ifdef      SYSV
#include    <malloc.h>  /* UNIX System V */
#endif

#ifdef      HUMAN68K
#include    <malloc.h>  /* X680x0 libc */
#endif

#ifdef      TURBOC
#include    <alloc.h>   /* Borland Turbo-C */
#endif

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
typedef int bool;
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
        unsigned char name[16], argc, argv[16][16], *define[32], lnum;
        struct macro_record *next;
}       macro_typ;
extern bool listing_on, object_on, symbol_on, count_on, warning_on, err_on;
extern bool new_line, undef_flag2, fatal_err, undef_flag, pre_on, top_of_line;
extern bool org_set, endflag, label_exist, s_end, defined, undefined, scope;
extern unsigned char asmtext[256], inbuf[256], x_label[256], oprtxt[256];
extern unsigned char obj_typ, TEMP[256];
extern unsigned char source_name[128], object_name[128], listing_name[128];
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
extern int current_ifdef_stat,ifdef_level,dflag,ifdef_stat[16];
extern unsigned char ifdef_name[16][80];
extern sc_reg slc, lc, x, y;
extern file_typ *current_file, *new_file;
extern label_typ *next_pnt, *equ_pnt, *equ_pnt2, *undefined_pnt;
extern rlist *reshash[MAXHASH2];
extern label_typ **lblhash, root;
extern macro_typ *macros, *mcr;
extern FILE *fp_object, *fp_listing;

extern sc_reg regular();
extern unsigned char xlow(), xmid(), xhigh();
extern unsigned char *hex_string(), isorg(), find_label(), xpos();
extern unsigned char no_operand(), prebyte(), regname(), mv_operand();
extern unsigned char two_operand(), one_operand();
extern label_typ **new_lblhash(), *add_lblhash(), *chk_lblhash();
extern macro_typ *new_macro(), *check_macro();
extern void init_defs();
extern int chk_defs(),add_defs(),del_defs();
