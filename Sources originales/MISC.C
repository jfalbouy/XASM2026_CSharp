#include "xasm.h"

unsigned char xlow(x)
sc_reg x;
{
   return  (unsigned char)( x % 256 );
}

unsigned char xmid(x)
sc_reg x;
{
   return  (unsigned char)( (x/256L) % 256 );
}

unsigned char xhigh(x)
sc_reg x;
{
   return  (unsigned char)( (x/65536L) % 256 );
}

int write_adr()
{
   sprintf(object_name,"%d",lines);
   hex_write(fp_listing,xhigh(lc));   ioerr_l();
   hex_write(fp_listing,xmid(lc));    ioerr_l();
   hex_write(fp_listing,xlow(lc));    ioerr_l();
   fprintf(fp_listing," ");           ioerr_l();
   new_line = FALSE;
   listing_count = 0;
}

sc_reg regular(x)
sc_reg x;
{
   if (x < 0) {  x = 1048575L + (x + 1);  }
   return x;
}

int hex_write(fp, x)
FILE *fp;
unsigned char x;
{
   fprintf(fp,"%02X",x);
}

unsigned char *hex_string(m)
sc_reg m;
{
   static unsigned char st[16], x, y, z;
   x = xhigh(m);   y = xmid(m);   z = xlow(m);
   sprintf(st,"%02X%02X%02Xh",x,y,z);
   return st;
}

int r_to_i32(x, ih, il)
sc_reg x;
int *ih, *il;
{
   *il =   (int) ( x % 256L );         x =  x / 256L  ;
   *il += ((int) ( x % 256L ) ) << 8;  x =  x / 256L  ;
   *ih =   (int) ( x % 256L );         x =  x / 256L  ;
   *ih += ((int) ( x % 256L ) ) << 8;
}

int i32_to_r(ih, il, x)
int ih, il;
sc_reg *x;
{
   *x =   ( (sc_reg)(ih/256) * 256 + (sc_reg)(ih%256) ) * 65536L
      +     (sc_reg)(il/256) * 256 + (sc_reg)(il%256) ;
}

int slim(tmp)
unsigned char *tmp;
{
   int p;
   if (strlen(tmp) != 0) {
      p = 1;
      while ((tmp[p-1] == ' ')||(tmp[p-1] == '\t')) { p++; }
      strdel(tmp,p-1);
      p = strlen(tmp);
      while ((tmp[p-1] == ' ')||(tmp[p-1] == '\t')) { p--; }
      tmp[p]='\0';
   }
}

int taiou(tmp)
unsigned char *tmp;
{
   int i, s, last;
   s = 2;
   for (i=1;i<strlen(tmp);i++) {
      if (tmp[i]=='\'') {
         i++;  while (tmp[i]!='\'') {  i++;  }
      } else if (tmp[i] == '(') {
         s++;
      } else if (tmp[i] == ')') {
         last = i+1;
         if (--s <= 1) break;
      }
   }
   if (s == 1) {  return last;  }
   else        {  return 0;     }
}

unsigned char isorg(tmp)
unsigned char *tmp;
{
   int i, j, k;
   j=0; k=0;
   for (i = 0; i < strlen(tmp); i++) {
      if (tmp[i] == '\\') { j = i; }
   }
   for (i = j; i < strlen(tmp); i++) {
      if (tmp[i] == '.') { k = i; }
   }
   return k+1;
}

unsigned char xpos(tmp, id, pp)
unsigned char *tmp;
unsigned char *id, *pp;
{
   int i;
   *pp=0;
   for (i=0;i<strlen(tmp);i++) {
      if      (tmp[i]=='+') {  *id=2; *pp=i+1; break;   }
      else if (tmp[i]=='-') {  *id=3; *pp=i+1; break;   }
   }
   return *pp;
}

unsigned char regname(tmp)
unsigned char *tmp;
{
   unsigned char c0,c1,c2;
   slim(tmp);
   if (tmp[1]=='\0') {
      c0=tmp[0];
      if (c0=='A')                         { return 0; }  /* A reg   */
      if (c0=='I')                         { return 3; }  /* I reg   */
      if (c0=='X')                         { return 4; }  /* X reg   */
      if (c0=='Y')                         { return 5; }  /* Y reg   */
      if (c0=='U')                         { return 6; }  /* U reg   */
      if (c0=='S')                         { return 7; }  /* S reg   */
      if (c0=='B')                         { return 8; }  /* B reg   */
      if (c0=='F')                         { return 9; }  /* Flag    */
   } else if (tmp[2]=='\0') {
      c0=tmp[0]; c1=tmp[1];
      if ((c0=='I')&&(c1=='L'))            { return 1; }  /* IL reg  */
      if ((c0=='B')&&(c1=='A'))            { return 2; }  /* BA reg  */
   } else if (tmp[3]=='\0') {
      c0=tmp[0]; c1=tmp[1]; c2=tmp[2];
      if ((c0=='I')&&(c1=='M')&&(c2=='R')) { return 10; } /* IMR     */
   }
   return 255;
}

#define ISID1(s) (strcmp(tmp,s)==0)

int int_ram_adr(tmp_, id, n)
unsigned char *tmp_, *id, *n;
{
   unsigned char tmp[255], tmp2[255];
   sc_reg z;
   int err;
   strcpy(tmp,tmp_);
   err = 0;
   slim(tmp);  tmp[ strlen(tmp) - 1]='\0';  strdel(tmp,1);  slim(tmp);
   strcpy(tmp2,tmp);
   *n = 0;
   if      (ISID1("BP"))    {  *id = 0;  }
   else if (ISID1("PX"))    {  *id = 1;  }
   else if (ISID1("PY"))    {  *id = 2;  }
   else if (ISID1("BP+PX")) {  *id = 3;  }
   else if (ISID1("BP+PY")) {  *id = 4;  }
   else if (strncmp(tmp,"#",1) == 0) {
      *id = 6;    strdel(tmp,1);       slim(tmp);
                  err=eval2(tmp,&z);   if (err==0) { *n = xlow(z); }
   } else if (strncmp(tmp,"BP",2) == 0) {
      *id = 0;    strdel(tmp,2);       slim(tmp);
      if ((top(tmp) == '+')||(top(tmp) == '-')) {
                  err=eval2(tmp,&z);   if (err==0) { *n = xlow(z); }
      } else {
         *id =5;  err=eval2(tmp2,&z);  if (err==0) { *n = xlow(z); }
      }
   } else if (strncmp(tmp,"PX",2) == 0) {
      *id =1;     strdel(tmp,2);       slim(tmp);
      if ((top(tmp) == '+')||(top(tmp) == '-')) {
                  err=eval2(tmp,&z);   if (err==0) { *n = xlow(z); }
      } else {
         *id =5;  err=eval2(tmp2,&z);  if (err==0) { *n = xlow(z); }
      }
   } else if (strncmp(tmp,"PY",2) == 0) {
      *id=2;    strdel(tmp,2);       slim(tmp);
      if ((top(tmp) == '+')||(top(tmp) == '-')) {
                  err=eval2(tmp,&z);   if (err==0) { *n = xlow(z); }
      } else {
         *id =5;  err=eval2(tmp2,&z);  if (err==0) { *n = xlow(z); }
      }
   } else {
         *id =5;  err=eval2(tmp,&z);   if (err==0) { *n = xlow(z); }
   }
   if (err != 0) {  return 5;  }
   else          {  return 0;  }
}

unsigned char prebyte(a, b)
unsigned char a, b;
{
   unsigned char c, d,e;
   c = 255;   d = 0;   e = 0;
   switch (b) {
      case 6:   c = 50;  e = 1;   break;   /* (#n) */
      case 5:   c = 50;  break;
      case 0:   c = 48;  break;
      case 2:   c = 51;  break;
      case 4:   c = 49;  break;
      default:  d = 1;   break;
   }
   switch (a) {
      case 6:   e = 1;      break;    /* (#n) */
      case 5:   break;
      case 0:   c = c - 16; break;
      case 1:   c = c + 4;  break;
      case 3:   c = c - 12; break;
      default:  d = 1;      break;
   }
   if ((d==0)&&(c!=32)&&((pre_on == TRUE)||(e==1)))  {  set_op(c); }
   return d;
}

int listing_proc()
{
   if ( (pass_sw == 3)&&(listing_on == TRUE)&&(err_on == FALSE)) {
      if (new_line == TRUE) {
         write_adr();
      }
      if (listing_count < 6) {
         while (listing_count < 6) {
            fprintf(fp_listing,"   "); ioerr_l();
            listing_count++;
         }
         if ((mflag==TRUE)||(dflag==TRUE)) {
            fprintf(fp_listing,"\t;;%s\n",listing_name); ioerr_l();
         } else {
            fprintf(fp_listing,"\t%s\n",listing_name); ioerr_l();
         }
      }
   }
}

int exp_macro(mcr)
macro_typ *mcr;
{
   int i,p,l,bp,mml,mcl;
   for (i=0;i<mcr->argc;i++) {
      bp=0;
      mml=strlen(mm_argv[i]);
      mcl=strlen(mcr->argv[i]);
      while ((p=strmatch(asmtext+bp,mcr->argv[i])) != -1) {
		bp+=p;
        replace(mm_argv[i],bp,mcl);
        bp+=mml-1;
      }
   }
}

int replace(pat,pos,l)
unsigned char *pat;
int pos,l;
{
   unsigned char ttt[256];
   strcpy(ttt,&asmtext[pos+l-1]);
   asmtext[pos-1]='\0';
   strcat(asmtext,pat); strcat(asmtext,ttt);
}

int strmatch(txt,pat)
unsigned char *txt,*pat;
{
   int i,j,m,n,f[256];
   n=strlen(txt); m=strlen(pat);
   compf(pat,m,f);
   i=1; j=1;
   while ((i<=m)&&(j<=n)) {
      if ((i==0)||(pat[i-1]==txt[j-1])) {
         i++; j++;
      } else {
         i=f[i];
      }
   }
   if (i == m+1) return j-m;
   return -1;
}

int compf(pat,m,f)
unsigned char *pat;
int m,*f;
{
   int i,j;
   i=0; j=1; f[1]=0;
   while (j<m) {
      if ((i==0)||(pat[i-1]==pat[j-1])) {
         i++; j++; f[j]=i;
      } else {
         i=f[i];
      }
   }
}
