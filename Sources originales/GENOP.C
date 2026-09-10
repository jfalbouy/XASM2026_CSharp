#include "xasm.h"

int generate_opcode(inbuf)
char *inbuf;
{
   int i,j,k,l,opnum,l_no,argc;
   macro_typ *mac;
   i = 255;
   if ((inbuf[0]=='M')&&(inbuf[1]=='V')&&(inbuf[2]=='\0')) {
      opnum=0;
   } else {
      opnum=check_hash(inbuf);
   }
   switch (opnum) {
      case 0:    i = 0;  break;  /* MV */
      case 1:    i = 1;  break;  /* MVW */
      case 2:    i = 2;  break;  /* MVP */
      case 3:    i = 3;  break;  /* MVL */
      case 4:    i = 7;  break;  /* MVLD */
      case 5:    i = 8;  break;  /* EX */
      case 6:    i = 9;  break;  /* EXW */
      case 7:    i = 10; break;  /* EXP */
      case 8:    i = 11; break;  /* EXL */
      case 9:    i = 41; offset = 238; break;  /* SWAP */
      case 10:   i = 16; offset = 64;  break;  /* ADD */
      case 11:   i = 16; offset = 72;  break;  /* SUB */
      case 12:   i = 16; offset = 80;  break;  /* ADC */
      case 13:   i = 16; offset = 88;  break;  /* SBC */
      case 14:   i = 17; offset = 112; break;  /* AND */
      case 15:   i = 17; offset = 120; break;  /* OR */
      case 16:   i = 17; offset = 104; break;  /* XOR */
      case 17:   i = 20; offset = 96;  break;  /* CMP */
      case 18:   i = 20; offset = 100; break;  /* TEST */
      case 19:   i = 22; offset = 80;  break;  /* ADCL */
      case 20:   i = 22; offset = 88;  break;  /* SBCL */
      case 21:   i = 22; offset = 192; break;  /* DADL */
      case 22:   i = 22; offset = 208; break;  /* DSBL */
      case 23:   i = 42; offset = 108; break;  /* INC */
      case 24:   i = 42; offset = 124; break;  /* DEC */
      case 25:   i = 43; offset = 228; break;  /* ROR */
      case 26:   i = 43; offset = 230; break;  /* ROL */
      case 27:   i = 43; offset = 244; break;  /* SHR */
      case 28:   i = 43; offset = 246; break;  /* SHL */
      case 29:   i = 44; offset = 251; break;  /* DSRL */
      case 30:   i = 44; offset = 235; break;  /* DSLL */
      case 31:   i = 30; break;  /* PMDF */
      case 32:   i = 31; break;  /* CMPW */
      case 33:   i = 32; break;  /* CMPP */
      case 34:   i = 45; break;  /* JP */
      case 35:   i = 46; break;  /* JPF */
      case 36:   i = 47; break;  /* JPZ */
      case 37:   i = 48; break;  /* JPNZ */
      case 38:   i = 49; break;  /* JPC */
      case 39:   i = 50; break;  /* JPNC */
      case 40:   i = 51; break;  /* CALL */
      case 41:   i = 52; break;  /* CALLF */
      case 42:   i = 53; break;  /* PUSHS */
      case 43:   i = 54; break;  /* PUSHU */
      case 44:   i = 55; break;  /* POPS */
      case 45:   i = 56; break;  /* POPU */
      case 46:   i = 59; break;  /* JR */
      case 47:   i = 61; break;  /* JRZ */
      case 48:   i = 63; break;  /* JRNZ */
      case 49:   i = 65; break;  /* JRC */
      case 50:   i = 67; break;  /* JRNC */
      case 51:   i = no_operand(6);   break;  /* RET */
      case 52:   i = no_operand(7);   break;  /* RETF */
      case 53:   i = no_operand(1);   break;  /* RETI */
      case 54:   i = no_operand(239); break;  /* WAIT */
      case 55:   i = no_operand(0);   break;  /* NOP */
      case 56:   i = no_operand(206); break;  /* TCL */
      case 57:   i = no_operand(222); break;  /* HALT */
      case 58:   i = no_operand(223); break;  /* OFF */
      case 59:   i = no_operand(254); break;  /* IR */
      case 60:   i = no_operand(255); break;  /* RESET */
      case 61:   i = no_operand(151); break;  /* SC */
      case 62:   i = no_operand(159); break;  /* RC */
      case 63:                       /* END */
         i = 69;
         if (current_file->pre != NIL) {
            new_file = current_file->pre; 
            fclose(current_file->fp_txt); free(current_file);
            current_file = new_file;
         } else {
            endflag = TRUE;
            if (l_stack_p != 1) {  err = 14;  }
            if (pre_stack_p != 1) {  err = 37;  }
            if (ifdef_level != 0) {  err = 50;  }
         }
         if ((err == 0)&&(current_file->l_stack_p!=l_stack_p)) {
            err = 33;
         }
         if ((err == 0)&&(current_file->pre_stack_p!=pre_stack_p)) {
            err = 38;
         }
         break;
      case 64:                       /* ORG */
         get_operand(&pp,oprtxt);
         if (asmtext[pp-1] != ',') {
            err = eval2(oprtxt,&x);
            if (err == 0) {
               if (undef_flag == FALSE) {
                  if ( org_set == FALSE )  {
                     lc = x; slc = x; org_set = TRUE;
                  } else {
                     if (x < lc) {           err = 26;  }
                     else        {  lc = x;  err = 28;  }
                  }
               } else {
                  err = 26;
               }
            }
         } else {
            err = 8;
         }
         i = 60;
         break;
      case 65:                       /* EQU */
         i = 60;
         get_operand(&pp,oprtxt);
         if (asmtext[pp-1] != ',') {
            err = eval2(oprtxt,&x);
            if (err == 0) {
               if (label_exist == TRUE) {
                  if ((undef_flag==FALSE)&&(undef_flag2==FALSE)) {
                     if (pass_sw == 1) {
                        equ_pnt->value = x;
                     } else {
                        if (equ_pnt->value == -1) {
                           defined = TRUE;  equ_pnt->value = x;
                        }
                     }
                  } else {
                     equ_pnt->value = -1;
                     undefined = TRUE;  undefined_pnt = equ_pnt;
                  }
               } else {
                  err = 15;
               }
            }
         } else {
            err = 8;
         }
         break;
      case 66:                       /* LOCAL */
         i = 69;
         if (label_exist == FALSE) {
            no_name_lbl++;  sprintf(x_label,"n%05X",no_name_lbl);
            if (pass_sw == 1) {
               err = find_label(x_label,&x,&next_pnt);
               if (err == 11) {
                  make_label(x_label,lc /* ,next_pnt */ );  err = 0;
               } else {
                  if (err == 0) {  err = 13; }
               }
            } else {
               err = find_label(x_label,&x,&equ_pnt); equ_pnt=equ_pnt2;
            }
         }
         l_stack_p++;
         if (l_stack_p<=16) {
            if (pass_sw == 1)   {
               l_stack[l_stack_p-1]=equ_pnt; equ_pnt->child=new_lblhash();
               if (equ_pnt->child==NULL) {
                  printf("Cannot create local block(%s)\n",equ_pnt->name);
                  exit(1);
               }
            } else {
               l_stack[l_stack_p-1]=equ_pnt;
            }
         } else {
            err = 16;
         }
         break;
      case 67:                       /* ENDL */
         i = 69;  l_stack_p--;
         if (l_stack_p <= 0) {  err = 17;  }
         break;
      case 68:   i = 68;  offset = 0; break;  /* DB */
      case 69:   i = 68;  offset = 0; break;  /* DM */
      case 70:   i = 68;  offset = 1; break;  /* PRE */
      case 71:   i = 68;  offset = 2; break;  /* DW */
      case 72:   i = 68;  offset = 4; break;  /* DP */
      case 73:                       /* DS */
         y = 0;
         get_operand(&pp,inbuf);
         err = eval2(inbuf,&x);
         if ((err == 0)&&(undef_flag == FALSE)) {
            if (asmtext[pp-1] == ',') {
               pp++;  get_operand(&pp,inbuf);
               if (asmtext[pp-1]!=',') { err=eval2(inbuf,&y); }
               else                      { err=8; }
            }
            if (err == 0) {
               if (x != 0) {
                  while(x-- >0) { set_op(xlow(y)); }
               } else {
                  err = 32;
               }
            }
         } else if (err == 0) {
            err = 26;
         }
         i = 60;
         break;
      case 74:   i = 69; pre_on = TRUE;  break;  /* PRE_ON  */
      case 75:   i = 69; pre_on = FALSE; break;  /* PRE_OFF */
      case 76:                       /* INCLUDE */
         get_operand2(&pp,inbuf);
         new_file = (file_typ *)malloc(sizeof(file_typ));
         if (new_file==NULL){printf("Out of memory\n");exit(1);}
         slim(inbuf);
         new_file->fp_txt = fopen(inbuf,"r");
         if (new_file->fp_txt == NULL) {
            printf(" File not found. (%s)\n",inbuf);
            printf(" Assemble aborted.\n"); exit(1);
         }
         new_file->pre = current_file;
         strcpy(new_file->name,inbuf);
         new_file->lines = 0;
         new_file->arg_cnt = 1;
         new_file->l_stack_p = l_stack_p;
         new_file->pre_stack_p = pre_stack_p;
         current_file = new_file;
         while ((asmtext[pp-1] == ',')&&(err == 0)) {
            pp++;
            get_operand(&pp,inbuf);
            err = eval2(inbuf,&y);
            if (err == 0) {
               if (undef_flag == TRUE) {
                  err=34;
               }
               i = current_file->arg_cnt;
               if (i <= 10) { current_file->arg[i-1] = y; }
               else         { err = 30; }
               current_file->arg_cnt = i + 1;
            }
         }
         if ((err != 0)&&(current_file->pre != NIL)) {
            new_file = current_file->pre;
            free(current_file);
            current_file = new_file;
         }
         i = 60;
         break;
      case 77:                       /* PRE_PUSH */
         i = 69;
         if ( pre_stack_p == 17 ) { err=35;  break; }
         pre_stack[pre_stack_p-1]=pre_on;  pre_stack_p++;
         break;
      case 78:                       /* PRE_POP  */
         i = 69; pre_on = FALSE;
         if ( pre_stack_p == 1 )  { err=36;  break; }
         pre_stack_p--;  pre_on=pre_stack[pre_stack_p-1];
         break;
      case 79:   i = 70; offset = 64;  break;  /* ADDB */
      case 80:   i = 71; offset = 64;  break;  /* ADDW */
      case 81:   i = 72; offset = 64;  break;  /* ADDP */
      case 82:   i = 70; offset = 72;  break;  /* SUBB */
      case 83:   i = 71; offset = 72;  break;  /* SUBW */
      case 84:   i = 72; offset = 72;  break;  /* SUBP */
      case 85:   i = 69; scope= TRUE;  break;  /* SCOPE_ON  */
      case 86:   i = 69; scope= FALSE; break;  /* SCOPE_OFF  */
      case 87:   i = 60;             /* MACRO  */
         mflag=TRUE; listing_proc();
         get_operand(&pp,inbuf); slim(inbuf); pp++;
         if (pass_sw == 1) {
            if (strchr(inbuf,' ')!=NULL)    {  err=39; break;  }
            if (check_hash(inbuf) != -1)    {  err=39; break;  }
            if (check_macro(inbuf) != NULL) {  err=40; break;  }
            mac=new_macro();
            if (mac==NULL) { printf("Cannot make macro(%s)\n",inbuf);exit(1); }
            strcpy(mac->name,inbuf);  mac->next=macros; macros=mac;
         }
         l_no=0; argc=0;
         while (1) {
            if (asmtext[pp-2]==';') { break; }
            get_operand2(&pp,inbuf); slim(inbuf); pp++;
            if (isnul(inbuf)) { break; }
            if (pass_sw == 1) {  strcpy(mac->argv[argc] , inbuf);  }
            argc++;
         }
         if (pass_sw == 1) {  mac->argc=argc;  }
         while (1) {
            if (   fgets(asmtext,255,current_file->fp_txt) == NULL ) {
               err = 18;   endflag = TRUE;   break;
            }
            current_file->lines++;  lines++;
            if (asmtext[strlen(asmtext)-1]=='\n') {
               asmtext[strlen(asmtext)-1]='\0';
            }
            strcpy(listing_name,asmtext); new_line = TRUE;
            if (count_on == TRUE) {  printf("    %d\015",lines);  }
            j=0; inbuf[0]='\0';
            if (isalpha(asmtext[0])) {
               for (j=0;j<len(asmtext);j++) {
                  if (asmtext[j]==':') {  j++; break;  }
               }
            }
            for (;j<len(asmtext);j++) {
               if ((asmtext[j]!=' ')&&(asmtext[j]!='\t')) { break; }
            }
            for (k=0;j<len(asmtext);j++) {
               if ((asmtext[j]==' ')||(asmtext[j]=='\t')) { break; }
               inbuf[k++]=c2upper(asmtext[j]);
            }
            inbuf[k]='\0'; slim(inbuf); if (strcmp(inbuf,"ENDM")==0) break;
            if (pass_sw == 1) {
               l=len(listing_name)+1;
               mac->define[l_no]=(unsigned char *)malloc(l*sizeof(char));
               strcpy(mac->define[l_no],listing_name);
            }
            l_no++;  listing_proc();  if (l_no>16) {  err=41; l_no--; }
         }
         if (pass_sw == 1) {  mac->lnum=l_no;  }
         break;
      case 88:   i = 60;             /* ENDM  */
         err=42; break;
      case 89:   i = 60;             /* DEF  */
         dflag=TRUE;
         get_operand(&pp,inbuf); slim(inbuf); pp++;
         k=add_defs(inbuf);
         if (k== 1 ) { err=45; /* redef */ }
         if (k== -1) { err=46; /* too many */ }
         break;
      case 90:   i = 60;             /* UNDEF  */
         dflag=TRUE;
         get_operand(&pp,inbuf); slim(inbuf); pp++;
         if (del_defs(inbuf)!=0) { err=47; /* not found */ }
         break;
      case 91:   i = 60;             /* IFDEF  */
         dflag=TRUE;
         get_operand(&pp,inbuf); slim(inbuf); pp++;
         if (chk_defs(inbuf)==1) {
            ifdef_stat[ifdef_level++]=current_ifdef_stat;
            if ( (current_ifdef_stat == 2)  ||
                 (current_ifdef_stat == 11) ||
                 (current_ifdef_stat == -1) )  {
               current_ifdef_stat= -1;
			} else {
               current_ifdef_stat=1;
            }
         } else {
            ifdef_stat[ifdef_level++]=current_ifdef_stat;
            if ( (current_ifdef_stat == 2)  ||
                 (current_ifdef_stat == 11) ||
                 (current_ifdef_stat == -1) )  {
               current_ifdef_stat= -1;
			} else {
               current_ifdef_stat=2;
            }
         }
         break;
      case 92:   i = 60;             /* IFNDEF  */
         dflag=TRUE;
         get_operand(&pp,inbuf); slim(inbuf); pp++;
         if (chk_defs(inbuf)==0) {
            ifdef_stat[ifdef_level++]=current_ifdef_stat;
            if ( (current_ifdef_stat == 2)  ||
                 (current_ifdef_stat == 11) ||
                 (current_ifdef_stat == -1) )  {
               current_ifdef_stat= -1;
			} else {
               current_ifdef_stat=1;
            }
         } else {
            ifdef_stat[ifdef_level++]=current_ifdef_stat;
            if ( (current_ifdef_stat == 2)  ||
                 (current_ifdef_stat == 11) ||
                 (current_ifdef_stat == -1) )  {
               current_ifdef_stat= -1;
			} else {
               current_ifdef_stat=2;
            }
         }
         break;
      case 93:   i = 60;             /* ELSE  */
         dflag=TRUE;
         if (ifdef_level == 0) { err=48; break; }
         if (current_ifdef_stat > 10) { err=48; break; }
         if (current_ifdef_stat == -1) { break; }
         current_ifdef_stat += 10;
         break;
      case 94:   i = 60;             /* ENDIF  */
         dflag=TRUE;
         if (ifdef_level == 0) { err=49; break; }
         current_ifdef_stat = ifdef_stat[--ifdef_level];
         break;
      default:
         break;
   }
   return i;
}

int generate_operand(i)
int i;
{
   switch (i) {
      case 0:  case 1:  case 2:  case 3:  case 4:
      case 5:  case 6:  case 7:
         err = mv_operand(i,&pp);  break;
      case 8:
         err = two_operand(6,192,&pp);  break;
      case 9:  case 10: case 11:
         err = two_operand(5,192 + i - 8,&pp);  break;
      case 16:
         err = two_operand(1,offset,&pp);  break;
      case 17:
         err = two_operand(2,offset,&pp);  break;
      case 20:
         err = two_operand(3,offset,&pp);  break;
      case 22:
         err = two_operand(4,offset,&pp);  break;
      case 30:  case 31:  case 32:
         err = two_operand(i - 23,0,&pp);  break;
      case 41:  case 42:  case 43:  case 44:  case 45:
      case 46:  case 47:  case 48:  case 49:  case 50:
      case 51:  case 52:  case 53:  case 54:  case 55:
      case 56:
         err = one_operand(i - 40,offset);  break;
      case 60:
         break;
      case 59:
         err = one_operand(18,0);  break;
      case 61:  case 62:  case 63:  case 64:  case 65:
      case 66:  case 67:
         err = one_operand(17,i - 61);  break;
      case 68:
         do {
            get_operand(&pp,inbuf);
            slim(inbuf);   i=1;
            if (inbuf[0]=='\'') {
               stradd(inbuf,0x1a);
               i = 2;
               s_end = FALSE;
               do {
                  switch (inbuf[i-1]) {
                     case '\'':
                        if (inbuf[i]=='\'') {
                           set_op('\'');  i += 2;
                        } else {
                           s_end = TRUE;  i++;
                        }
                        break;
                     case 0x1a:
                        err = 19; s_end = TRUE; break;
                     default:
                        set_op(inbuf[i-1]); i++; break;
                  }
               } while (s_end != TRUE);
               if (i == 3) { set_op(0); }
               if (inbuf[i-1] != 0x1a) { err = 8; }
            } else {
               err = eval2(inbuf,&x);
               if (err == 0) {
                  set_reg_opecode(offset,xlow(x),xmid(x),xhigh(x));
               }
               if (offset == 1) {
                  if (((x<33)||(x>39))&&((x<48)||(x>55))) {
                     err = 1;
                  } else if (pre_on == TRUE) {
                     err = 29;
                  }
               }
            }
            pp++;
         } while ((asmtext[pp - 2] == ',')&&(err == 0));
         break;
      case 69:
         get_operand(&pp,inbuf);  slim(inbuf);
         if ((asmtext[pp-1]==',')||(isXnul(inbuf))) {
            err = 8;
         }
         break;
      case 70:
         err = two_operand(10,offset,&pp);  break;
      case 71:
         err = two_operand(11,offset,&pp);  break;
      case 72:
         err = two_operand(12,offset,&pp);  break;
      default:
         err = 7;  break;
   }
}
