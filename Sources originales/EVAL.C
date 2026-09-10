#include "xasm.h"

int eval2(txt2, z)
unsigned char *txt2;
sc_reg *z;
{
   unsigned char txt[255];
   unsigned char c_str[255];
   unsigned char tmp2[10], c;
   int minus, radix, i, x2, err, txt_p, c_str_p;
   bool set_x, txtend;
   sc_reg x;

   strcpy(txt,txt2);
   o_stack[1] = 'S';     o_stack_p = 2;   v_stack_p = 1;
   undef_flag = FALSE;   undef_flag2 = FALSE;
   slim(txt);
   if (strlen(txt) > 0) {
      stradd(txt,0x1a);  txt_p = 1;     txtend = FALSE;
      err = 0;           minus = 0;     set_x = FALSE;
      do {
         c = txt[txt_p-1];
         while ((c == '\t')||(c == ' ')) {
            txt_p++; c = txt[txt_p-1];
         }
         if ((isdigit(c))||(c == '$')) {
            if (set_x == TRUE) {
               err = 22;
            } else {
               set_x = TRUE;  c_str_p = 1;   strcpy(c_str,"");
               do {
                  stradd(c_str,c); c_str_p++; txt_p++; c = txt[txt_p-1];
               } while ((isxdigit(c))||(c=='_')||(c=='O')||(c=='H'));
               if (top(c_str) == '$') {
                  strcpy(tmp2,c_str+1); sprintf(c_str,"0%sH",tmp2); c_str_p++;
               }
               c_str_p--;
               switch (c_str[c_str_p-1]) {
                  case 'B':  radix = 2;  break;
                  case 'O':  radix = 8;  break;
                  case 'D':  radix = 10; break;
                  case 'H':  radix = 16; break;
                  default:   radix = 10; c_str_p++; break;
               }
               x = 0;
               for (i = 1; i <= c_str_p - 1; i++) {
                  if (c_str[i-1] != '_') {
                     c = c_str[i-1];
                     if (isdigit(c)) {
                        x2 = c - 48;
                     } else {
                        if ((c >= 'A')&&(c <= 'F')) { x2 = c - 55; }
                        else                        { err = 23;    }
                     }
                     if (x2 >= radix) { err = 23; }
                     else             { x = x * radix + x2; }
                  }
               }
               if (minus == 1) {  x = -x;  minus = 0;  }
               x = regular(x);
            }
         } else {
            i = oprlevel(c);
            if ((i > 2)&&(i <= 7)) {
               txt_p++;
               if (set_x == FALSE) {
                  switch (c) {
                     case '+':  break;
                     case '-':  minus = 1 - minus;  break;
                     case '*':  set_x = TRUE;  x = lc;  break;
                     default:   err = 24;  break;
                  }
               } else {
                  while ((err==0)&&(i<=oprlevel(o_stack[o_stack_p - 1]))) {
                     err = operate(&x);  o_stack_p--;  v_stack_p--;
                  }
                  o_stack[o_stack_p] = c;  v_stack[v_stack_p-1] = x;
                  o_stack_p++;  v_stack_p++;
                  if ((err == 0)&&(o_stack_p > 16)) {  err = 25;  }
                  set_x = FALSE;
               }
            } else {
               if (c == '(') {
                  if (set_x == TRUE) {
                     err = 22;
                  } else {
                     txt_p++;  o_stack[o_stack_p] = '(';  o_stack_p++;
                     if (o_stack_p > 16) {  err = 25;  }
                  }
               } else if (c == ')') {
                  if (set_x == FALSE) {
                     err = 24;
                  } else {
                     txt_p++;
                     while ((err ==0)&&(o_stack[o_stack_p - 1] != '(')) {
                        err = operate(&x);  o_stack_p--;  v_stack_p--;
                     }
                     o_stack_p--;
                  }
               } else if (c=='\'') {
                  if (set_x == TRUE) {
                     err = 22;
                  } else {
                     set_x = TRUE;  x = 0;  s_end = FALSE; txt_p++;
                     do {
                        switch (txt[txt_p-1]) {
                           case '\'':
                              if (txt[txt_p]=='\'') {
                                 x = '\'';   txt_p += 2;
                              } else {
                                 s_end = TRUE;   txt_p++;
                              }
                              break;
                           case 0x1a:
                              err = 19;   s_end = TRUE;
                              break;
                           default:
                              x = txt[txt_p-1];  txt_p++;
                              break;
                        }
                     } while (s_end != TRUE);
                  }
               } else if (c == '@') {
                  if (set_x == FALSE) {
                     txt_p++;  i = txt[txt_p-1] - 48;
                     if ((i >= 0)&&(i + 1 < current_file->arg_cnt)) {
                        x = current_file->arg[i];
                        txt_p++;  set_x = TRUE;
                     } else {
                        err = 31;
                     }
                  } else {
                     err = 22;
                  }
               } else if (c == 0x1a) {
                  if (set_x == FALSE) {
                     err = 22;
                  } else {
                     txtend = TRUE;
                     while ((err == 0)&&(o_stack_p > 2)) {
                        err = operate(&x);  o_stack_p--;  v_stack_p--;
                     }
                  }
               } else if (islabel(c) == TRUE) {
                  if (set_x == FALSE) {
                     strcpy(c_str,"");
                     while (islabel(c) == TRUE) {
                        stradd(c_str,c);  txt_p++;  c = txt[txt_p-1];
                     }
                     err = find_label(c_str,&x,&next_pnt);  set_x = TRUE;
                     if (next_pnt == equ_pnt) {
                        undef_flag2 = TRUE;
                     }
                     if ((pass_sw != 3)&&((err == 11)||(x == -1))) {
                        err = 0;  x = 0;  undef_flag = TRUE;
                     }
                     if (minus == 1) {
                        x = -x;  minus = 0;
                     }
                     x = regular(x);
                  } else {
                     err = 22;
                  }
               } else {
                  err = 4;
               }
            }
         }
      } while ((err == 0)&&(txtend != TRUE));
      *z = x;
      return err;
   } else {
      return 21;
   }
}

int evalx(tmp2, gid, id, low, mid, high)
unsigned char *tmp2, *gid, *id, *low, *mid, *high;
{
   unsigned char tmp[255],pp;
   sc_reg z;
   int err, n;
   err = 0;
   strcpy(tmp,tmp2);   slim(tmp);
   if (strlen(tmp) > 0)  {
      if ((top(tmp) == '(')&&(bottom(tmp) == ')')) {
         *gid = 2;
         n = taiou(tmp);
         if (n == strlen(tmp)) {
            err = int_ram_adr(tmp,id,low);
         } else {
            *gid = 0;
            err = eval2(tmp,&z);
            if (err == 0) {
               *low = xlow(z); *mid = xmid(z); *high = xhigh(z);
            }
         }
      } else if ((top(tmp) == '[')&&(bottom(tmp) == ']')) {
         *gid = 3;
         tmp[ strlen(tmp) - 1 ]='\0';  strdel(tmp,1);
         slim(tmp);  n = regname(tmp);
         if ((n >= 0)&&(n <= 7)) {
            *id = 1;  *low = n;
         } else if ((tmp[strlen(tmp)-1] == '+')&&(tmp[strlen(tmp)-2] == '+')) {
            tmp[ strlen(tmp)-2 ] ='\0';  n = regname(tmp);
            if ((n >= 0)&&(n <= 7)) {
               *id = 4;  *low = n;
            } else {
               err = 4;
            }
         } else if ((tmp[0] == '-')&&(tmp[1] == '-')) {
            strdel(tmp,2);  n = regname(tmp);
            if ((n >= 0)&&(n <= 7)) {
               *id = 5;  *low = n;
            } else {
               *gid = 0;
               err = eval2(tmp,&z);
               if (err == 0) {
                  *low = xlow(z); *mid = xmid(z); *high = xhigh(z);
               }
            }
         } else if (top(tmp) == '(') {
            n = taiou(tmp);
            if (n == strlen(tmp)) {
               *id = 6;
               err = int_ram_adr(tmp,low,mid);
            } else if (n != 0) {
               n++;
               while ((tmp[n-1]==' ')||(tmp[n-1]=='\t')) { n++; }
               if (tmp[n-1] == '+') {
                  *id = 7;
                  stricpy(TEMP,tmp,n-1);
                  err = int_ram_adr(TEMP,low,mid);
                  if (err == 0) {
                     strdel(tmp,n);
                     err = eval2(tmp,&z);
                     if (err == 0) {  *high = xlow(z);  }
                  }
               } else if (tmp[n-1] == '-') {
                  *id = 8;
                  stricpy(TEMP,tmp,n-1);
                  err = int_ram_adr(TEMP,low,mid);
                  if (err == 0) {
                     strdel(tmp,n);
                     err = eval2(tmp,&z);
                     if (err == 0) {  *high = xlow(z);  }
                  }
               } else {
                  *id = 0;
                  err = eval2(tmp,&z);
                  if (err == 0) {
                     *low = xlow(z); *mid = xmid(z); *high = xhigh(z);
                  }
               }
            } else {
               err = 6;
            }
         } else if (xpos(tmp,id,&pp) != 0) {
            stricpy(TEMP,tmp,pp-1);
            n = regname(TEMP);
            if ((n >= 0)&&(n <= 7)) {
               *low = n;
               strdel(tmp,pp);
               err = eval2(tmp,&z);
               if (err == 0) {  *mid = xlow(z);  }
            } else {
               *id = 0;
               err = eval2(tmp,&z);
               if (err == 0) {
                  *low = xlow(z); *mid = xmid(z); *high = xhigh(z);
               }
            }
         } else {
            *id = 0;
            err = eval2(tmp,&z);
            if (err == 0) {
               *low = xlow(z); *mid = xmid(z); *high = xhigh(z);
            }
         }
      } else {
         *id = regname(tmp);
         if (*id != 255) {
            *gid = 1;
         } else {
            err = eval2(tmp,&z);
            if (err == 0) {
               *gid = 0; *low = xlow(z); *mid = xmid(z); *high = xhigh(z);
            }
         }
      }
   } else {
      err = 21;
   }
   return err;
}

int operate(x)
sc_reg *x;
{
   unsigned int ih1,ih2,il1,il2,op;
   op = 0;
   switch (o_stack[o_stack_p - 1]) {
      case '+':
         *x = v_stack[v_stack_p - 2] + (*x);         break;
      case '-':
         *x = v_stack[v_stack_p - 2] - (*x);         break;
      case '*':
         r_to_i32(v_stack[v_stack_p - 2],&ih1,&il1); r_to_i32(*x,&ih2,&il2);
         *x =   ( (sc_reg)ih1*(sc_reg)ih2 ) *16777216L
              + ( (sc_reg)il1*(sc_reg)ih2 + (sc_reg)ih1*(sc_reg)il2 ) *65536L
              + ( (sc_reg)il1*(sc_reg)il2 );
         break;
      case '/':
         if (*x != 0) {  *x = (sc_reg)v_stack[v_stack_p - 2] / (*x);  }
         else         {  op = 2;  }
         break;
      case '|':
         r_to_i32(v_stack[v_stack_p - 2],&ih1,&il1); r_to_i32(*x,&ih2,&il2);
         i32_to_r((ih1 | ih2),(il1 | il2),x);
         break;
      case '&':
         r_to_i32(v_stack[v_stack_p - 2],&ih1,&il1); r_to_i32(*x,&ih2,&il2);
         i32_to_r(ih1 & ih2,il1 & il2,x);
         break;
      case '%':
         if (*x != 0) {
            *x = v_stack[v_stack_p - 2]
            - (int)((sc_reg)v_stack[v_stack_p - 2] / (*x)) * (*x);
         } else {
            op = 2;
         }
         break;
      default:
         op = 3;
         break;
   }
   if (op == 0) {  *x = regular(*x);  }
   return op;
}
