#include "xasm.h"

int get_operand(p, txt)
int *p;
unsigned char *txt;
{
   unsigned char c;
   txt[0]='\0';
   c = asmtext[ *p - 1 ];
   while ((c!=',')&&(c != ';')&&(c!=0x1a)&&(c!='\0')) {
      if (c=='\'') {
         do {
            stradd(txt,c);     (*p)++;   c = asmtext[*p - 1];
         } while ((c!='\'')&&(c!=0x1a));
         if (c == 0x1a) {  (*p)--;  }
      }
      stradd(txt,c2upper(c));  (*p)++;   c = asmtext[*p - 1];
   }
}

int get_operand2(p, txt)
int *p;
unsigned char *txt;
{
   unsigned char c;
   txt[0]='\0';
   c = asmtext[ *p - 1 ];
   while ((c!=',')&&(c != ';')&&(c!=0x1a)&&(c!='\0')) {
      if (c=='\'') {
         do {
            stradd(txt,c);     (*p)++;   c = asmtext[*p - 1];
         } while ((c!='\'')&&(c!=0x1a));
         if (c == 0x1a) {  (*p)--;  }
      }
      stradd(txt,c);  (*p)++;   c = asmtext[*p - 1];
   }
}

int set_op(x)
unsigned char x;
{
   if ((pass_sw == 3)&&(listing_on == TRUE)&&(err_on == FALSE)) {
      if ((new_line == TRUE)||(listing_count == 6)) { write_adr(); }
      hex_write(fp_listing,x);  ioerr_l();
      fprintf(fp_listing," ");  ioerr_l();
      if (++listing_count == 6) {
         fprintf(fp_listing,"\t%s\n",listing_name);  ioerr_l();
         strcpy(listing_name,"");
      }
   }
   if ((pass_sw == 3)&&(object_on == TRUE)) {
      switch (obj_typ) {
         case 'Z':  case 'H':
            csum += x;
            hex_write(fp_object,x);  ioerr_o();
            if (++object_cnt == 32) {
               if ((obj_typ == 'Z')) { hex_write(fp_object,csum); ioerr_o(); }
               fprintf(fp_object,"\n");  ioerr_o();
               csum = 0;  object_cnt = 0;
            }
            break;
         default:
            fprintf(fp_object,"%c",x);  ioerr_o();
            break;
      }
   }
   lc++;
}

int set_reg_opecode(a, b, c, d)
unsigned char a, b, c, d;
{
   set_op(b);
   if (a > 1) { set_op(c); }
   if (a > 3) { set_op(d); }
}

unsigned char no_operand(offset)
unsigned char offset;
{
   set_op(offset);
   return 69;
}

int set_r3_opecode(a, b, c)
unsigned char a, b, c;
{
   switch (a) {
      case 1:  set_op(b);      break;
      case 2:  set_op(128+b);  set_op(c);  break;
      case 3:  set_op(192+b);  set_op(c);  break;
      case 4:  set_op(32 +b);  break;
      case 5:  set_op(48 +b);  break;
      case 6:  set_op(0);      set_op(b);  break;
      case 7:  set_op(128);    set_op(b);  set_op(c);  break;
      case 8:  set_op(192);    set_op(b);  set_op(c);  break;
   }
}

int set_mn_opecode(a, b, c, d)
unsigned char a,b,c,d;
{
   switch (a) {
      case 1:  set_op(b);      set_op(c);  break;
      case 2:  set_op(128+b);  set_op(c);  set_op(d);  break;
      case 3:  set_op(192+b);  set_op(c);  set_op(d);  break;
      case 4:  set_op(32 +b);  set_op(c);  break;
      case 5:  set_op(48 +b);  set_op(c);  break;
      case 6:  set_op(0);      set_op(b);  set_op(c);  break;
      case 7:  set_op(128);    set_op(b);  set_op(c);  set_op(d);  break;
      case 8:  set_op(192);    set_op(b);  set_op(c);  set_op(d);  break;
   }
}

unsigned char two_operand(typ, offset, pnt)
unsigned char typ, offset;
int *pnt;
{
   unsigned char gid_1,gid_2, id_1,id_2, op1_1,op1_2, op2_1,op2_2, op3_1,op3_2;
   unsigned char oprtxt[255];
   int err;
   err = 0;
   get_operand(pnt,oprtxt);
   if (asmtext[*pnt-1] == ',') {
      err = evalx(oprtxt,&gid_1,&id_1,&op1_1,&op2_1,&op3_1);
      if (err == 0) {
         (*pnt)++;
         get_operand(pnt,oprtxt);
         if (asmtext[*pnt-1] != ',') {
            err = evalx(oprtxt,&gid_2,&id_2,&op1_2,&op2_2,&op3_2);
            if (err == 0) {
               if ((  ( ((typ==1)||(typ==2)||(typ==3))&&(gid_1 == 1))
                    &&(id_1 == 0) )&&(gid_2 == 0)  ) {
                  set_op(offset);
                  set_op(op1_2);
               } else if ( ( ((typ==1)||(typ==2)||(typ==3)||(typ==7))
                         &&(gid_1 == 2) )&&(gid_2 == 0)  ) {
                  err = prebyte(id_1,0);
                  if (err == 0) {
                     if (typ == 7) {  set_op(71);  }
                     else          {  set_op(offset + 1);  }
                     set_op(op1_1);   set_op(op1_2);
                  }
               } else if ( (  ( ((typ==2)||(typ==3))&&(gid_1 == 3) )
                             &&(id_1 == 0) )&&(gid_2 == 0)  ) {
                  set_op(offset + 2);
                  set_reg_opecode(4,op1_1,op2_1,op3_1);
                  set_op(op1_2);
               } else if ((((((typ>=1)&&(typ<=4))||(typ==7))
                              &&(gid_1 == 2))&&(gid_2 == 1))&&(id_2 == 0)) {
                  err = prebyte(id_1,0);
                  if (err == 0) {
                     switch (typ) {
                        case 4:   set_op(offset + 5);  break;
                        case 7:   set_op(87);          break;
                        default:  set_op(offset + 3);  break;
                     }
                     set_op(op1_1);
                  }
               } else if (((((typ==1)||(typ==2))&&(gid_1 == 1))
                                   &&(id_1 == 0))&&(gid_2 == 2)) {
                  err = prebyte(id_2,0);
                  if (err == 0) {
                     switch (typ) {
                        case 1:  set_op(offset + 2);  break;
                        case 2:  set_op(offset + 7);  break;
                     }
                     set_op(op1_2);
                  }
               } else if ((((typ==2)||(typ==4)||(typ==5)||(typ==6)||(typ==8)
                   ||(typ==9))||(offset == 96))&&(gid_1 == 2)&&(gid_2 == 2)) {
                  err = prebyte(id_1,id_2);
                  if (err == 0) {
                     switch (typ) {
                        case 2:  set_op(offset + 6);     break;
                        case 3:  set_op(offset + 87);    break;
                        case 4:  set_op(offset + 4);     break;
                        case 5:
                        case 6:  set_op(offset);         break;
                        case 8:
                        case 9:  set_op(198 + typ - 8);  break;
                     }
                     set_op(op1_1);  set_op(op1_2);
                  }
               } else if (((typ == 1)&&((offset==64)||(offset==72)))
                              &&(gid_1 == 1)&&(gid_2 == 1)&&(id_2 <= 7)) {
                  if      ((id_1==0)||(id_1==1)) {  set_op(offset + 6);  }
                  else if ((id_1==2)||(id_1==3)) {  set_op(offset + 4);  }
                  else if ((id_1>=4)&&(id_1<=7)) {  set_op(offset + 5);  }
                  else                           {  err = 7;  }
                  if (err == 0) {  set_op(id_1 * 16 + id_2);  }
               } else if (((typ == 10)&&((offset==64)||(offset==72)))
                              &&(gid_1 == 1)&&(gid_2 == 1)&&(id_2 <= 7)) {
                  set_op(offset + 6); set_op(id_1 * 16 + id_2); /* addb */
               } else if (((typ == 11)&&((offset==64)||(offset==72)))
                              &&(gid_1 == 1)&&(gid_2 == 1)&&(id_2 <= 7)) {
                  set_op(offset + 4); set_op(id_1 * 16 + id_2); /* addw */
               } else if (((typ == 12)&&((offset==64)||(offset==72)))
                              &&(gid_1 == 1)&&(gid_2 == 1)&&(id_2 <= 7)) {
                  set_op(offset + 5); set_op(id_1 * 16 + id_2); /* addp */
               } else if ((((typ == 6)&&(gid_1 == 1))&&(gid_2 == 1))) {
                  if (((id_1 == 0)&&(id_2 == 8))) {
                     set_op(221);
                  } else {
                     if (((id_1 <= 7)&&(id_2 <= 7))) {
                        set_op(237);  set_op(id_1 * 16 + id_2);
                     } else {
                        err = 7;
                     }
                  }
               } else if (((typ==8)||(typ==9))&&(gid_1 == 2)&&(gid_2 == 1)
                                                             &&(id_2 <= 7)) {
                  err = prebyte(id_1,0);
                  if (err == 0) {
                     set_op(214 + typ - 8);  set_op(id_2);  set_op(op1_1);
                  }
               } else {
                  err = 7;
               }
            }
         } else {
            err = 8;
         }
      }
   } else {
      err = 8;
   }
   return err;
}

unsigned char one_operand(typ, offset)
unsigned char typ, offset;
{
   unsigned char gid_1, id_1, op1_1, op2_1, op3_1, oprtxt[255];
   sc_reg x;
   int err;
   get_operand(&pp,oprtxt);
   if (asmtext[pp-1] != ',') {
      err = evalx(oprtxt,&gid_1,&id_1,&op1_1,&op2_1,&op3_1);
      if (err == 0) {
         if (((typ==1)||(typ==3))&&(gid_1==1)&&(id_1==0)) {
            set_op(offset);
         } else if ((typ>=2)&&(typ<=5)&&(gid_1 == 2)) {
            err = prebyte(id_1,0);
            if (err == 0) {
               if (typ == 5) {  set_op(16);  }
               else          {  set_op(offset + 1);  }
               set_op(op1_1);
            }
         } else if (((typ==2)||(typ==5))&&(gid_1==1)&&(id_1<=7)) {
            if (typ == 5) {  set_op(17);  }
            else          {  set_op(offset);  }
            set_op(id_1);
         } else if (((typ==5)||((typ>=7)&&(typ<=11)))&&(gid_1 == 0)) {
            switch (typ) {
               case 5:
                  set_op(2);  break;
               case 7:  case 8:  case 9:  case 10:
                  set_op(20 + typ - 7);  break;
               case 11:
                  set_op(4);  break;
            }
            set_reg_opecode(2,op1_1,op2_1,op3_1);
         } else if (((typ==6)||(typ==12))&&(gid_1 == 0)) {
            switch (typ) {
               case 6:
                  set_op(3); break;
               case 12:
                  set_op(5); break;
            }
            set_reg_opecode(4,op1_1,op2_1,op3_1);
         } else if (((typ==14)||(typ==16))&&(gid_1 == 1)) {
            switch (id_1) {
               case 0:  case 1:  case 2:  case 3:  case 4:
               case 5:
                  set_op(40 + id_1 + 8 * (typ - 14)); break;
               case 9:  case 10:
                  set_op(46 + id_1 - 9 + 8 * (typ - 14));  break;
               default:
                  err = 7; break;
            }
         } else if (((typ==13)||(typ==15))&&(gid_1 == 1)) {
            if (id_1 == 9) {
               set_op(79 + 8 * (typ - 13));
            } else {
               switch (id_1) {
                  case 0:  case 1:  case 2:  case 3:  case 4:
                  case 5:
                     set_op(176 + id_1 - 16 * (typ - 13));
                     set_op(55 - 8 * (typ - 13));
                     break;
                  case 10:
                     set_op(48);      set_op(232 - 4 * (typ - 13));
                     set_op(55 - 8 * (typ - 13));      set_op(251);
                     break;
                  default:
                     err = 7;  break;
               }
            }
         } else if (((typ==17)||(typ==18))&&(gid_1 == 0)) {
            x = (op3_1 * 256.0 + op2_1) * 256.0 + op1_1 - lc - 2;
            if (pass_sw == 3) {
               if ((x >= 0)&&(x <= 255)) {
                  switch (typ) {
                     case 17:  set_op(offset + 24); break;
                     case 18:  set_op(18); break;
                  }
                  set_op((int)(x));
               } else if ((x < 0)&&(x >= -255)) {
                  switch (typ) {
                     case 17:  set_op(offset + 25); break;
                     case 18:  set_op(19); break;
                  }
                  set_op((int)(-x));
               } else {
                  err = 9;
               }
            } else {
               set_reg_opecode(2,0,0,0);
            }
         } else {
            err = 7;
         }
      }
   } else {
      err = 8;
   }
   return err;
}
