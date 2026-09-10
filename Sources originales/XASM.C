#include "xasm.h"

main (argc,argv)
int argc;
unsigned char *argv[];
{
   char c;
   int i;
   maxhash = MAXHASH;
   object_on  = FALSE;   listing_on = FALSE;   symbol_on  = FALSE;
   count_on   = FALSE;   fatal_err  = FALSE;   warning_on = FALSE;
   err_on = FALSE;
   title();
   if (argc < 2) {  usage();  }
   obj_typ = '\0';
   pp = isorg(argv[1]);
   if (pp == 0) {
      strcpy(source_name ,argv[1]); strcat(source_name ,".asm");
      strcpy(object_name ,argv[1]); strcat(object_name ,".obj");
      strcpy(listing_name,argv[1]); strcat(listing_name,".lst");
   } else {
      strcpy(source_name,argv[1]);
      stricpy(object_name ,argv[1],pp); strcat(object_name ,"obj");
      stricpy(listing_name,argv[1],pp); strcat(listing_name,"lst");
   }
   for (i = 2; i <= argc - 1; i++) {
      strcpy(inbuf,argv[i]);
      if (top(inbuf) == '-') {
         switch (c2upper(inbuf[1])) {
            case 'L':
               listing_on = TRUE;
               if (strlen(inbuf) > 2) {   strcpy(listing_name,inbuf+2);  }
               if ((fp_listing=fopen(listing_name,"w"))==NULL) {
                  printf(" File cannot create. (%s)\n",listing_name);
                  printf(" Assemble aborted.\n"); exit(1);
               }
               break;
            case 'O':
               object_on = TRUE;
               if (strlen(inbuf) > 2) {   strcpy(object_name,inbuf+2);   }
               if ((fp_object=fopen(object_name,"wb"))==NULL) {
                  printf(" File cannot create. (%s)\n",object_name);
                  printf(" Assemble aborted.\n"); exit(1);
               }
               break;
            case 'S':  symbol_on  = TRUE;                   break;
            case 'C':  count_on   = TRUE;                   break;
            case 'T':  obj_typ    = c2upper(inbuf[2]);      break;
            case 'W':  warning_on = TRUE;                   break;
            case 'E':  err_on     = TRUE;                   break;
            case 'H':  maxhash = 1;                         break;
         }
      }
   }
   pass_sw = 1;
   root.name[0]='\0';   root.value=0;
   root.next=NULL;      root.child=new_lblhash();
   l_stack[0] = &root;  if (root.child==NULL) { exit(1); }
   oprlevel_set();   delimiter_set();  islabel_set();
   init_hash();      set_hash();
   macros=NULL;
   printf(" [ PASS1 ]\n");
   do {
      org_set = FALSE;      lc = 0;      slc = 0;
      current_file = (file_typ *)malloc(sizeof(file_typ));
      if (current_file==NULL) {   printf("Out of memory\n"); exit(1);   }
      strcpy(current_file->name,source_name);
      current_file->pre = NIL;
      current_file->arg_cnt = 1;
      current_file->l_stack_p = 1;
      current_file->pre_stack_p = 1;
      current_file->fp_txt = fopen(current_file->name,"r");
      if (current_file->fp_txt==NULL) {
         printf(" File not found. (%s)\n",current_file->name);
         printf(" Assemble aborted.\n"); exit(1);
      }
      lines = 0;  current_file->lines = 0;  l_stack_p = 1;  pre_stack_p = 1;
      endflag   = FALSE;      defined = FALSE;      scope = FALSE;
      undefined = FALSE;      pre_on  = FALSE;      no_name_lbl = 0;
      in_macro = FALSE;       dflag   = FALSE;      mflag = FALSE;
      current_ifdef_stat = 0;  ifdef_level=0;  init_defs();
      do {
         err = 0;
         do {
            if ( (current_ifdef_stat == 0)||
                 (current_ifdef_stat == 1)||
                 (current_ifdef_stat == 12) ) {
               if (in_macro == FALSE) {
                  if ( fgets(asmtext,255,current_file->fp_txt) == NULL ) {
                     err = 18;   endflag = TRUE;
                  }
                  current_file->lines++;  lines++;
               } else {
                  strcpy(asmtext,mcr->define[mline++]); exp_macro(mcr);
                  if ((mcr->argc != mm_argc)&&(mline == 1)) { err=43; }
                  if (mline>=mcr->lnum) { in_macro=FALSE; }
               }
            } else {
               if ( fgets(asmtext,255,current_file->fp_txt) == NULL ) {
                  err = 18;   endflag = TRUE;
               }
               c=0;
               if ((asmtext[0]==' ')||(asmtext[0]=='\t')) {
                  for (i=0;i<strlen(asmtext);i++) {
                     if ((asmtext[i]!=' ')&&(asmtext[i]!='\t')) { break; }
                  }
                  if (strncmp(&asmtext[i],"IFDEF" ,5)==0) { c=1; }
                  if (strncmp(&asmtext[i],"ifdef" ,5)==0) { c=1; }
                  if (strncmp(&asmtext[i],"IFNDEF",6)==0) { c=1; }
                  if (strncmp(&asmtext[i],"ifndef",6)==0) { c=1; }
                  if (strncmp(&asmtext[i],"ELSE"  ,4)==0) { c=1; }
                  if (strncmp(&asmtext[i],"else"  ,4)==0) { c=1; }
                  if (strncmp(&asmtext[i],"ENDIF" ,5)==0) { c=1; }
                  if (strncmp(&asmtext[i],"endif" ,5)==0) { c=1; }
               }
               if (c==0) { /* if ELSE | ENDIF then skip here */
                  for (i=strlen(asmtext)+2;i>0;i--) {
                     asmtext[i+2] = asmtext[i];
                  }
                  asmtext[0]=';'; asmtext[1]=';';
               }
               current_file->lines++;  lines++;
            }
            if (asmtext[strlen(asmtext)-1]=='\n') {
               asmtext[strlen(asmtext)-1]='\0';
            }
         } while ((err != 18)&&(isnul(asmtext)));
         if (count_on == TRUE) {  printf("    %d\015",lines);  }
         strcpy(listing_name,asmtext); new_line = TRUE;
         stradd(asmtext,0x1a);
         label_exist = FALSE;
         pp = 1;
         if ((err == 0)&&(top(asmtext) != ';')) {
            if ((top(asmtext) != ' ')&&(top(asmtext) != '\t')) {
               strcpy(x_label,"");
               while (islabel2(c=c2upper(asmtext[pp-1])) == TRUE) {
                  stradd(x_label,c);  pp++;
               }
               if ((asmtext[pp-1]!=':')||(len(x_label)>16)||(isnul(x_label))) {
                  err = 10;
               } else {
                  label_exist = TRUE; top_of_line = TRUE;
                  strdel(asmtext,strlen(x_label)+1);
                  if (pass_sw == 1) {
                     err = find_label(x_label,&x,&next_pnt);
                     if (err == 11) {
                        make_label(x_label,lc /* ,next_pnt */ );  err = 0;
                     } else {
                        if (err == 0) {  err = 13;  }
                     }
                  } else {
                     i = find_label(x_label,&x,&equ_pnt); equ_pnt = equ_pnt2;
                  }
                  top_of_line = FALSE;
               }
            }
            /* generate opecode */
            if (err == 0) {
               slim(asmtext);
               if ((top(asmtext) != 0x1a)&&(top(asmtext) != ';')) {
                  pp = 1;  strcpy(inbuf,"");
                  while (delimiter(asmtext[pp-1]) == FALSE) {
                     stradd(inbuf,c2upper(asmtext[pp-1]));  pp++;
                  }
                  if (check_macro(inbuf) == NULL) {
                     i=generate_opcode(inbuf);  generate_operand(i);
                  } else {
                     if (in_macro == FALSE) {
                        mcr=check_macro(inbuf);
                        in_macro=TRUE; mline=0; mflag=TRUE;
                        mm_argc=0;
                        for (i=0;i<16;i++) { strcpy(mm_argv[i],""); }
                        while (1) {
                           if (asmtext[pp-2]==';') { break; }
                           get_operand2(&pp,inbuf); slim(inbuf); pp++;
                           if (isnul(inbuf)) { break; }
                           strcpy(mm_argv[mm_argc++],inbuf);
                           if (mm_argc>16) { break; }
                        }
                     } else {
                        err=44;
                     }
                  }
               }
            }
         }
         listing_proc(); mflag=FALSE; dflag=FALSE;
         err_handle();
      } while (endflag != TRUE);

      printf("    %d line(s)\n",lines);
      if (fatal_err == FALSE) {
         switch (pass_sw) {
            case 1:
               if (undefined==FALSE) { printf(" [ PASS2 ]\n");     pass_sw=3; }
               else                 { printf(" [ EQU define ]\n"); pass_sw=2; }
               break;
            case 2:
               if (undefined == TRUE) {
                  if (defined == FALSE) { err = 27; err_handle(); }
               } else {
                  printf(" [ PASS2 ]\n");  pass_sw=3;
               }
               break;
            case 3:
               pass_sw = 0;
               break;
         }
      }
      if ((pass_sw == 3)&&(object_on == TRUE)) {
         lc = lc - slc + 16;
         header[5]=xlow(lc-16); header[6]=xmid(lc-16); header[7]=xhigh(lc-16);
         header[8]=xlow(slc);   header[9]=xmid(slc);   header[10]=xhigh(slc);
         switch (obj_typ) {
            case 'Z':
               fprintf(fp_object,"----- ZSH FOR E500 [A.OUT]\n"); ioerr_o();
               fprintf(fp_object,"---( %d lines )---\n",
                    (int)((sc_reg)(lc - 1) / 32) + 1); ioerr_o();
               csum = 0;
               for (i = 1; i <= 16; i++) {
                  csum += header[i-1];
                  hex_write(fp_object,header[i-1]); ioerr_o();
               }
               object_cnt = 16;
               break;
            case 'H':  case 'B':
               for (i = 6; i <= 11; i++) {
                  if (obj_typ == 'H') {
                     hex_write(fp_object,header[i-1]);
                  } else {
                     fprintf(fp_object,"%c", header[i-1]);  ioerr_o();
                  }
               }
               object_cnt = 6;
               break;
            default:
               if (obj_typ == 'F') {
                  fprintf(fp_object,"%c%c%c%c%c",
                   1, xlow(lc), xmid(lc), xhigh(lc), 1);  ioerr_o();
               }
               for (i = 1; i <= 16; i++) {
                  fprintf(fp_object,"%c", header[i-1]);  ioerr_o();
               }
               break;
         }
      }
   } while ((fatal_err != TRUE)&&(pass_sw != 0));

   if (fatal_err == TRUE) {
      printf("\n Fatal error occured.\n");
      printf(" Assemble aborted.\n");  exit(1);
   } else {
      printf("\n  No fatal error.  ");
      printf("Code: %s", hex_string(slc) );
      printf(" - %s [ ", hex_string(lc - 1) );
      printf("%8ld byte(s)]\n", lc - slc);
      if (object_on == TRUE) {
         switch (obj_typ) {
            case 'Z':
            case 'H':
               if (object_cnt != 0) {
                  for (i = 1; i <= 32-object_cnt; i++) {
                     hex_write(fp_object,0); ioerr_o();
                  }
                  if (obj_typ == 'Z') {
                     hex_write(fp_object,csum); ioerr_o();
                  }
                  fprintf(fp_object,"\n"); ioerr_o();
               }
               if (obj_typ == 'Z') {
                  fprintf(fp_object,"( end of line )\n"); ioerr_o();
               }
               break;
         }
      }
      if ((symbol_on == TRUE)&&(listing_on == TRUE)) {
         fprintf(fp_listing,"\n - Symbols -\n\n"); ioerr_l();
         trace_symbol_hash(l_stack[0]->child);
      }
      if (listing_on == TRUE) {
         fprintf(fp_listing,"\n  No fatal error.  ");
         fprintf(fp_listing,"Code: %s", hex_string(slc) );
         fprintf(fp_listing," - %s [ ", hex_string(lc - 1) );
         fprintf(fp_listing,"%8ld byte(s)]\n", lc - slc);
      }
   }

   if (object_on  == TRUE) {  fclose(fp_object);   }
   if (listing_on == TRUE) {  fclose(fp_listing);  }
}
