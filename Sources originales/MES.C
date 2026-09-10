#include "xasm.h"

int title()
{
   printf("\n");
   printf("<<< XASM Ver%s for CPU-SC62015 ", VERSION );
   printf("/ (c)1990-1996 N.Kon and E.Kako >>>\n");
   printf("\n");
}

int usage()
{
   printf(" USAGE:XASM sourcefile[.ext] [options]\n");
   printf("\n");
   printf("   - OPTIONS -\n");
   printf("\n");
   printf(" -L[filename] : With listing file\n");
   printf(" -E[filename] : With error report file (use with -L)\n");
   printf(" -O[filename] : With object file\n");
   printf(" -S           : With symbol list (use with -L)\n");
   printf(" -T[type]     : Object type (type=Z: ZSH format\n");
   printf("                                  B: Binary format\n");
   printf("                                  H: Hexadecimal format\n");
   printf("                                  F: FTX format\n");
   printf("                              other: Binary format w/header)\n");
   printf(" -C           : Count line number\n");
   printf(" -W           : With warning\n");
   printf(" -H           : Hash off (use with -S)\n");
   printf("\n");
   printf("   ex. XASM sourcefile -L -E -O -S -TZ -C -W -H ...full options\n");
   exit(1);
}

int err_handle()
{
   bool warning;
   warning = FALSE;
   if (err != 0) {
      fatal_err = TRUE;
      switch (err) {
         case 1:  strcpy(inbuf,"Prebyte error");                    break;
         case 2:  strcpy(inbuf,"Division by zero");                 break;
         case 3:  strcpy(inbuf,"Operator error");                   break;
         case 4:  strcpy(inbuf,"Unevaluetable operand");            break;
         case 5:  strcpy(inbuf,"Bad internal RAM addressing");      break;
         case 6:  strcpy(inbuf,"Bad external MEMORY addressing");   break;
         case 7:  strcpy(inbuf,"Undefined instruction");            break;
         case 8:  strcpy(inbuf,"Bad separater");                    break;
         case 9:  strcpy(inbuf,"Branch too far");                   break;
         case 10: strcpy(inbuf,"Label format error");               break;
         case 11: strcpy(inbuf,"Label not found");                  break;
         case 13: strcpy(inbuf,"Duplicate label");                  break;
         case 14: strcpy(inbuf,"\"LOCAL\" not closed");             break;
         case 15: strcpy(inbuf,"No label before EQU");              break;
         case 16: strcpy(inbuf,"LOCAL nesting too deep");           break;
         case 17: strcpy(inbuf,"ENDL used without LOCAL");          break;
         case 18: strcpy(inbuf,"EOF comes before END");             break;
         case 19: strcpy(inbuf,"\' unmatch");                       break;
         case 20: strcpy(inbuf,"No label before LOCAL");            break;
         case 21: strcpy(inbuf,"Missing operand");                  break;
         case 22: strcpy(inbuf,"Missing operator");                 break;
         case 23: strcpy(inbuf,"Numeric format error");             break;
         case 24: strcpy(inbuf,"Missing numeric");                  break;
         case 25: strcpy(inbuf,"Too complex operand");              break;
         case 26: strcpy(inbuf,"Location counter wandered");        break;
         case 27: sprintf(inbuf,"EQU undefinable(suspicious label is \"%s\")",
                                undefined_pnt->name);               break;
         case 28: strcpy(inbuf,"Warning: Location counter already set");
                                warning = TRUE;                     break;
         case 29:
            strcpy(inbuf,"Warning: Used PRE while auto-prebyte is active");
                                warning = TRUE;                     break;
         case 30: strcpy(inbuf,"Too many arguments");               break;
         case 31: strcpy(inbuf,"Bad argument number");              break;
         case 32: strcpy(inbuf,"Warning: No effective code");
                                warning = TRUE;                     break;
         case 33:
            strcpy(inbuf,"Warning: LOCAL and ENDL not match in included file");
                                warning = TRUE;                     break;
         case 34:
            strcpy(inbuf,"Warning: INCLUDE argument isn\'t defined yet\n");
                                warning = TRUE;                     break;
         case 35: strcpy(inbuf,"PRE_PUSH nesting too deep");        break;
         case 36: strcpy(inbuf,"PRE_POP used without PRE_PUSH");    break;
         case 37: strcpy(inbuf,"PRE_PUSH not closed");              break;
         case 38: strcpy(inbuf,"Warning: PRE_PUSH and PRE_POP not match");
                                warning = TRUE;                     break;
         case 39: strcpy(inbuf,"Macro name error");                 break;
         case 40: strcpy(inbuf,"Dupulicate macro");                 break;
         case 41: strcpy(inbuf,"Too many lines in macro");          break;
         case 42: strcpy(inbuf,"ENDM without MACRO");               break;
         case 43: strcpy(inbuf,"Missing macro parameter");          break;
         case 44: strcpy(inbuf,"Cannot use macro in macro");        break;
         case 45: strcpy(inbuf,"DEF symbol redefined");             break;
         case 46: strcpy(inbuf,"Too many DEF symbols");             break;
         case 47: strcpy(inbuf,"UNDEF symbol not found");           break;
         case 48: strcpy(inbuf,"ELSE without IFDEF");               break;
         case 49: strcpy(inbuf,"ENDIF without IFDEF");              break;
         case 50: strcpy(inbuf,"IFDEF not closed");                 break;
      }
      if ((warning == FALSE)||(warning_on == TRUE)) {
         sprintf(asmtext,"%s\t%d\t%s",
                     current_file->name,current_file->lines,inbuf);
         printf("                 \015%s\n",asmtext);
         if (listing_on == TRUE) {
            fprintf(fp_listing,"%s\n",asmtext); ioerr_l();
         }
      }
      if (warning == TRUE) {  fatal_err = FALSE;  }
   }
}

int ioerr_o()
{
   if (ferror(fp_object) != 0) {
      printf("\n %% Object File I/O Error");
      printf("\n Assemble aborted.\n");  exit(1);
   }
}
int ioerr_l()
{
   if (ferror(fp_listing) != 0) {
      printf("\n %% Listing File I/O Error");
      printf("\n Assemble aborted.\n"); exit(1);
   }
}
