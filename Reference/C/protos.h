/* protos.h - Prototypes complets generes automatiquement */
/* Fonctions de INIT.C */
int oprlevel_set(void);
int islabel_set(void);
int delimiter_set(void);
int set_hash(void);
/* Fonctions de HASH.C */
int init_hash(void);
int add_hash(unsigned char *id_name, int id_num);
int check_hash(unsigned char *id_name);
unsigned char find_label(unsigned char *label_name2, sc_reg *value, label_typ ***start_pnt);
int make_label(unsigned char *label_name, sc_reg value);
int trace_symbol_hash(label_typ **hash);
/* Fonctions de MES.C */
int title(void);
int usage(void);
int err_handle(void);
int ioerr_o(void);
int ioerr_l(void);
/* Fonctions de MISC.C */
int slim(unsigned char *tmp);
int listing_proc(void);
int exp_macro(macro_typ *mcr);
int hex_write(FILE *fp, unsigned char x);
/* Fonctions de OPR.C */
int get_operand(int *p, unsigned char *txt);
int get_operand2(int *p, unsigned char *txt);
int set_op(unsigned char x);
/* Fonctions de GENOP.C */
int generate_opcode(char *inbuf);
int generate_operand(int i);
/* Fonctions de EVAL.C */
int eval2(unsigned char *txt2, sc_reg *z);
int evalx(unsigned char *tmp2, unsigned char *gid, unsigned char *id,
          unsigned char *low, unsigned char *mid, unsigned char *high);
int operate(sc_reg *x);
/* Fonctions de MISC.C (suite) */
unsigned char isorg(unsigned char *tmp);
int int_ram_adr(unsigned char *tmp_, unsigned char *id, unsigned char *n);
unsigned char prebyte(unsigned char a, unsigned char b);
unsigned char regname(unsigned char *tmp);
unsigned char xpos(unsigned char *tmp, unsigned char *id, unsigned char *pp);
sc_reg regular(sc_reg x);
unsigned char xlow(sc_reg x);
unsigned char xmid(sc_reg x);
unsigned char xhigh(sc_reg x);
unsigned char *hex_string(sc_reg m);
