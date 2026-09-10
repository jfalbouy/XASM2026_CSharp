#include "xasm.h"

int calc_hash(name)
unsigned char *name;
{
   int sum = 0;
   unsigned char *p = name;
   while ( *p!='\0' ) {   sum += *(p++);  }
   return sum % maxhash;
}

int calc_hash2(name)
unsigned char *name;
{
   int sum = 0;
   unsigned char *p = name;
   while ( *p!='\0' ) {   sum += *(p++);  }
   return sum % MAXHASH2;
}

label_typ **new_lblhash()
{
   label_typ *l,**hash;
   int i;
   hash = (label_typ **)malloc(maxhash*sizeof(label_typ *));
   if (hash==NULL) { printf("Out of memory\n"); return NULL; }
   for (i=0;i<maxhash;i++) {   hash[i]=NIL;   }
   return hash;
}

label_typ *add_lblhash(hash,id_name,id_value)
label_typ **hash;
unsigned char *id_name;
sc_reg id_value;
{
   label_typ *p,*l;
   int h;
   h=calc_hash(id_name);
   l = hash[h];
   if (l != NIL) {
      while (l->next != NIL) { l= l->next; }
   }
   p = (label_typ *)malloc(sizeof(label_typ)+strlen(id_name));
   if (p==NULL) { printf("Out of memory\n"); return NULL; }
   strcpy( p->name , id_name );  p->value = id_value;
   p->child = NIL;  p->next = NIL;
   if (l == NIL) { hash[h] = p; }
   else          { l->next = p; }
   return p;
}

label_typ *chk_lblhash(hash,id_name,id_value)
label_typ **hash;
unsigned char *id_name;
sc_reg *id_value;
{
   label_typ *p;
   int h;
   h=calc_hash(id_name);   p = hash[h];
   while (1) {
      if (p==NIL) {  break;  }
      if (strcmp(p->name,id_name)==0) {
         *id_value = p->value;   return p;
      }
      p=p->next;
   }
   return NULL;
}

int init_hash()
{
   rlist *l;
   int i;
   for (i=0;i<MAXHASH2;i++) {
      l = reshash[i] = (rlist *)malloc(sizeof(rlist));
      l->id_num = -1;  l->id_name[0] = '\0';  l->next = NULL;
   }
}

int add_hash(id_name,id_num)
unsigned char *id_name;
int id_num;
{
   rlist *p,*l;
   int h;
   h = calc_hash2(id_name);
   l = reshash[h]; p = reshash[h] = (rlist *)malloc(sizeof(rlist));
   p->id_num  = id_num; strcpy( p->id_name , id_name ); p->next = l;
}

int check_hash(id_name)
unsigned char *id_name;
{
   rlist *l;
   int h,num;
   h = calc_hash2(id_name);   l = reshash[h];   num = -1;
   while ( l->next!=NULL ) {
      if (strcmp( l->id_name, id_name )==0)  { num = l->id_num; break; }
      l=l->next;
   }
   return num;
}

unsigned char find_label(label_name2, value, start_pnt)
unsigned char *label_name2;
sc_reg *value;
label_typ ***start_pnt;
{
   unsigned char *label_name, err, lbl_tree, name[17];
   int tmp_stack, x;
   label_typ  *p  /* , *last */ ;
   err = 0;  tmp_stack = l_stack_p;
   label_name = label_name2;
   *start_pnt = l_stack[tmp_stack-1]->child;
   /* last = NIL; */
   lbl_tree = FALSE;
   switch (top(label_name)) {
      case '!':
         label_name++;   *start_pnt = l_stack[0]->child;  lbl_tree = TRUE;
         break;
      case '.':
         label_name++;   lbl_tree = TRUE;
         while ((top(label_name) == '.')&&(err == 0)) {
            label_name++;    tmp_stack--;
            if (tmp_stack > 0) {  *start_pnt=l_stack[tmp_stack-1]->child;  }
            else               {  err = 10;  }
         }
         if (top(label_name) == '!') {  label_name++;  }
         else                        {  err = 10;  }
         break;
   }
   if (strchr(label_name,'!')!=NULL) { lbl_tree = TRUE; }
   if ((scope == FALSE)||(lbl_tree == TRUE)||(top_of_line == TRUE)) {
      while(1) {
         x = strcspn(label_name,"!")+1;
         if (strchr(label_name,'!')!=NULL) {
            stricpy(name,label_name,x-1);  label_name += x;
         } else {
            strcpy(name,label_name);       label_name += strlen(name);
         }
         p=chk_lblhash(*start_pnt,name,value);
         if (p!=NULL) {
            if (isXnul(label_name)) {  *start_pnt = p->child;  }
            else                    {  err=0; equ_pnt2=p; return 0;   }
         } else {
            err = 11;  return err;
         }
      }
   } else {
      strcpy(name,label_name);
      while(1) {
         *start_pnt=l_stack[tmp_stack-1]->child;
         p=chk_lblhash(*start_pnt,name,value);
         if (p!=NULL) {   err=0; equ_pnt2=p; return 0;  }
         if (--tmp_stack == 0) { err = 11; return err; }
      }
   }
}

int make_label(label_name, value /* , start_pnt */ )
unsigned char *label_name;
sc_reg value;
/* label_typ *start_pnt; */
{
   label_typ *p, **hash;
   hash = l_stack[l_stack_p-1]->child;
   p = add_lblhash(hash,label_name,value);
   if (p==NULL) {
      printf("Cannot make label(%s)\n",label_name); exit(1);
   }
   equ_pnt = p;
}

int trace_symbol_hash(hash)
label_typ **hash;
{
   label_typ *p;
   int h,i;
   for (h=0;h<maxhash;h++) {
      p = hash[h];
      while (1) {
         if (p==NIL) {  break;  }
         hex_write(fp_listing,xhigh(p->value)); ioerr_l();
         hex_write(fp_listing,xmid(p->value));  ioerr_l();
         hex_write(fp_listing,xlow(p->value));  ioerr_l();
         strcpy(asmtext," : ");
         for (i = 1; i <= l_stack_p - 1; i++) {
            strcat(asmtext,l_stack[i-1]->name); strcat(asmtext," ! ");
         }
         fprintf(fp_listing,"%s%s\n",asmtext,p->name);  ioerr_l();
         if (p->child!=NIL) {
            l_stack[l_stack_p-1] = p;  l_stack_p++;
            trace_symbol_hash(p->child);
         }
         p=p->next;
      }
   }
   l_stack_p--;
}

macro_typ *new_macro()
{
   macro_typ *m;
   m = (macro_typ *)malloc(sizeof(macro_typ));
   if (m==NULL) { printf("Out of memory\n"); return NULL; }
   return m;
}

macro_typ *check_macro(name)
unsigned char *name;
{
   macro_typ *m = macros;
   while (1) {
      if (m == NULL) { break; }
      if (strcmp(m->name,name)==0) { break; }
      m = m->next;
   }
   return m;
}

void init_defs()
{
   int i;
   for (i=0;i<16;i++) {
      ifdef_name[i][0]='\0';
   }
}

int chk_defs(s)
unsigned char *s;
{
   int i;
   for (i=0;i<16;i++) {
      if (strcmp(s,ifdef_name[i])==0) { return 1; }
   }
   return 0;
}

int add_defs(s)
unsigned char *s;
{
   int i;
   if (chk_defs(s)==1) { return 1; }
   for (i=0;i<16;i++) {
      if (ifdef_name[i][0]=='\0') {
         strcpy(ifdef_name[i],s); return 0;
      }
   }
   return -1;
}

int del_defs(s)
unsigned char *s;
{
   int i;
   for (i=0;i<16;i++) {
      if (strcmp(s,ifdef_name[i])==0) {
         ifdef_name[i][0]='\0';
         return 0;
      }
   }
   return 1;
}
