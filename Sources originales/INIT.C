#include "xasm.h"

int oprlevel_set()
{
   int i;
   for (i=0;i<256;i++) { oprlevel_table[i]=0; }
   oprlevel_table['S']=1;
   oprlevel_table['(']=2;
   oprlevel_table['|']=3;
   oprlevel_table['&']=4;
   oprlevel_table['%']=5;
   oprlevel_table['+']=6;
   oprlevel_table['-']=6;
   oprlevel_table['*']=7;
   oprlevel_table['/']=7;
}

/*
#define   oprlevel(c)   oprlevel_table[c]
*/


int islabel_set()
{
   int i;
   for (i=0;i<256;i++)     { islabel_table[i]=FALSE; }
   for (i='A';i<='Z';i++)  { islabel_table[i]=TRUE;  }
   for (i='0';i<='9';i++)  { islabel_table[i]=TRUE;  }
   islabel_table['_']=TRUE;
   for (i=0;i<256;i++)     { islabel2_table[i]=islabel_table[i]; }
   islabel_table['.']=TRUE;
   islabel_table['!']=TRUE;
}

/*
#define   islabel(c)    islabel_table[c]
#define   islabel2(c)   islabel2_table[c]
*/

int delimiter_set()
{
   int i;
   for (i=0;i<256;i++) { delimiter_table[i]=FALSE; }
   delimiter_table[ ' '  ]=TRUE;
   delimiter_table[ ';'  ]=TRUE;
   delimiter_table[ '\t' ]=TRUE;
   delimiter_table[ 0x1a ]=TRUE;
}

/*
#define   delimiter(c)   delimiter_table[c]
*/

int set_hash()
{
   add_hash( "MV"       , 0  );   add_hash( "MVW"      , 1  );
   add_hash( "MVP"      , 2  );   add_hash( "MVL"      , 3  );
   add_hash( "MVLD"     , 4  );   add_hash( "EX"       , 5  );
   add_hash( "EXW"      , 6  );   add_hash( "EXP"      , 7  );
   add_hash( "EXL"      , 8  );   add_hash( "SWAP"     , 9  );
   add_hash( "ADD"      , 10 );   add_hash( "SUB"      , 11 );
   add_hash( "ADC"      , 12 );   add_hash( "SBC"      , 13 );
   add_hash( "AND"      , 14 );   add_hash( "OR"       , 15 );
   add_hash( "XOR"      , 16 );   add_hash( "CMP"      , 17 );
   add_hash( "TEST"     , 18 );   add_hash( "ADCL"     , 19 );
   add_hash( "SBCL"     , 20 );   add_hash( "DADL"     , 21 );
   add_hash( "DSBL"     , 22 );   add_hash( "INC"      , 23 );
   add_hash( "DEC"      , 24 );   add_hash( "ROR"      , 25 );
   add_hash( "ROL"      , 26 );   add_hash( "SHR"      , 27 );
   add_hash( "SHL"      , 28 );   add_hash( "DSRL"     , 29 );
   add_hash( "DSLL"     , 30 );   add_hash( "PMDF"     , 31 );
   add_hash( "CMPW"     , 32 );   add_hash( "CMPP"     , 33 );
   add_hash( "JP"       , 34 );   add_hash( "JPF"      , 35 );
   add_hash( "JPZ"      , 36 );   add_hash( "JPNZ"     , 37 );
   add_hash( "JPC"      , 38 );   add_hash( "JPNC"     , 39 );
   add_hash( "CALL"     , 40 );   add_hash( "CALLF"    , 41 );
   add_hash( "PUSHS"    , 42 );   add_hash( "PUSHU"    , 43 );
   add_hash( "POPS"     , 44 );   add_hash( "POPU"     , 45 );
   add_hash( "JR"       , 46 );   add_hash( "JRZ"      , 47 );
   add_hash( "JRNZ"     , 48 );   add_hash( "JRC"      , 49 );
   add_hash( "JRNC"     , 50 );   add_hash( "RET"      , 51 );
   add_hash( "RETF"     , 52 );   add_hash( "RETI"     , 53 );
   add_hash( "WAIT"     , 54 );   add_hash( "NOP"      , 55 );
   add_hash( "TCP"      , 56 );   add_hash( "HALT"     , 57 );
   add_hash( "OFF"      , 58 );   add_hash( "IR"       , 59 );
   add_hash( "RESET"    , 60 );   add_hash( "SC"       , 61 );
   add_hash( "RC"       , 62 );   add_hash( "END"      , 63 );
   add_hash( "ORG"      , 64 );   add_hash( "EQU"      , 65 );
   add_hash( "LOCAL"    , 66 );   add_hash( "ENDL"     , 67 );
   add_hash( "DB"       , 68 );   add_hash( "DM"       , 69 );
   add_hash( "PRE"      , 70 );   add_hash( "DW"       , 71 );
   add_hash( "DP"       , 72 );   add_hash( "DS"       , 73 );
   add_hash( "PRE_ON"   , 74 );   add_hash( "PRE_OFF"  , 75 );
   add_hash( "INCLUDE"  , 76 );   add_hash( "PRE_PUSH" , 77 );
   add_hash( "PRE_POP"  , 78 );   add_hash( "ADDB"     , 79 );
   add_hash( "ADDW"     , 80 );   add_hash( "ADDP"     , 81 );
   add_hash( "SUBB"     , 82 );   add_hash( "SUBW"     , 83 );
   add_hash( "SUBP"     , 84 );   add_hash( "SCOPE_ON" , 85 );
   add_hash( "SCOPE_OFF", 86 );   add_hash( "MACRO"    , 87 );
   add_hash( "ENDM"     , 88 );   add_hash( "DEF"      , 89 );
   add_hash( "UNDEF"    , 90 );   add_hash( "IFDEF"    , 91 );
   add_hash( "IFNDEF"   , 92 );   add_hash( "ELSE"     , 93 );
   add_hash( "ENDIF"    , 94 );
}

