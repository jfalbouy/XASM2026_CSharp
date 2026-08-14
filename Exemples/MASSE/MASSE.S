\0BD800
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; enhanced Macro ASSEmbler
;   copyright (c)1994-1997 N.Masuichi
;       All rigths reserved
+DEFMACRO CREDIT_STRING
  'MASSE/1.2.0 (c) N.Masuichi 1997.4.10^M^J'00
; 'masse/1.2.0://masse.s/1.2.0'
; 'last update:1997/4/10 23:59'
; 'object crc:1012-17BD14F1'
+ENDMACRO
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;-----------------------------------------------------------
;   section constants, variables
;-----------------------------------------------------------
sysFcs(0FFFE4)
sysDev(0FFFE8)
sysSStackTop(0BFCE1)
sysMacTop(0BFD1A)
sysArea$(0BF800)
;
bp(0EC)
BASE(050)
USER_IRRAM_LIMIT(0B0)
ssr(0FF-BASE)
brkMsk(0EA-BASE)
cl(0D6-BASE)
di(0DD-BASE)
;
DEPTH(010)
;
\PNTR sas(0),sau;save S/Ureg area
\PNTR esp;end of source pnt
; // inited iram
\PNTR cdt;system top
\PNTR oba;out buffer adr
\PNTR osa;os adr
\PNTR obp;out buffer pnt
\PNTR tnp;text nesting table pnt
\PNTR snp;struct nesting table pnt
\PNTR sna;struct nseting table adr
\BYTE lwd;last writed data
\BYTE fhi;file handle for input
\BYTE fho;file handle for output
\PNTR lnc;line counter
\BYTE opt;option
\PNTR const0;constant ZERO
;//
\PNTR lcp;lcation pnt/loc. table size
\PNTR ltp;label table pnt
\PNTR ltb;label table base
\PNTR lct;
\PNTR lad;last loc. adr
\BYTE cmk;compare work for kakko
\BYTE cmw;compare work 
\BYTE sdc;struct depth counter
\BYTE lol;length of label;p.w. sol
\PNTR sol;start adr of label
\BYTE slol;save lol;p.w. ssol
\PNTR ssol;save sol
\BYTE flg;flag
\PNTR agp;argument pnt
\BYTE argtyp;
\PNTR slc;sub location counter
\BYTE vat;variable type
\PNTR wk1,wk2,wk3;works
\PNTR slm;s_stack limit
\BYTE prio;expression priority
\BYTE piflv;preprocesser-IF level
;
\BYTE wk1l(wk1),wk1m,wk1h
\BYTE wk2l(wk2),wk2m,wk2h
\BYTE wk3l(wk3),wk3m,wk3h
\TEST(%<|USER_IRRAM_LIMIT-BASE)
;
\ENUM _FALSE_(0);この値を変更してはならない。
\ENUM _TRUE_(~_FALSE_)
;
; -- argtyp の中身 --
; コマンドラインから読んだファイル名に関する情報
\FLAG _CUR_DRIVE_(1)  ;ドライブ名は指定されていない
\FLAG _WITH_EXTENSION_;拡張子が指定されている
;
; -- flg の中身 --
\FLAG PASS_2(2);現在パス２を処理中
\FLAG DEFINED_ONLY;ラベル前方参照禁止
;
; -- opt の中身 --
\FLAG NO_HEADING(1);機械語ﾍｯﾀﾞ出力禁止
;
; -- \STRF 命令のフォーマットデータ --
\FLAG FMT_MONTH(0),FMT_dec(010),FMT_HEX,FMT_hex,FMT_ZERO
;-----------------------------------------------------------
;   section code
;-----------------------------------------------------------
asEntry
\{
 3280{bp}2832CC{bp}{BASE}A7{sas}A6{sau}
 09{initIram$e-initIram$}D3{cdt}(initIram$)
 8C(sysMacTop)08204540A4{esp}
 8C(sysSStackTop)08{100}4540A4{slm}
 71{brkMsk}F7
;-- print credit --
 08{MSG\CREDIT}04[Puts]
;-- read argument --
 CD{wk1}0000 948601
 \{0D(fname$)A4{agp}05(sysDos)1C<_usg>
  61{argtyp}{_CUR_DRIVE_}1A<_f>
  908506 60'-'1A<_f>
  ;switch
  928507 7820
   60'r'1A<_1>   74 04[ctoh]1C<_usg> A0{wk1l}13<.C>
_1 60'm'1A<_usg> 74 04[ctoh]1C<_usg> A0{wk1m}13<.C>
_usg 08{MSG\USAGE}02[retToDos]
  ;filename
_f
  0A'X 'B2850F 0A' ^@'B28511
  \{0D(fname2$)05(sysDos)1C<.B>
   0C(fname$)
   \{9025B02460001B<.C>
   \}
  \}
 \}
;-- pass0 --
 84{cdt}80{wk1l} 4001       75 0800 4D42
 A4{lct}A4{lcp}
        80{wk1m} 4001 E6 E6 75 0800 4D42
 D704{esp} 08{ERR\MEMEXH} 1E<error>
 0800
 B004 A4{ltb}  BC00{snp}
 B034 A4{ltp}
;-- pass1 --
 CC{flg}{DEFINED_ONLY}04[execPassN]
 8C(macHead$.or)4D5408{ERR\NO_OBJ}18<error>
 2D
 \{84{lct}85{lcp}4D5418<.B>
  08FF 04[_setLocTbl] 6C05
 \}3C A5{lcp} 4554 AD(macHead$.sz)
 C7{sna}{snp}08{ERR\STBNCL}1A<error>
 84{snp}85{ltb}B5246C0509{DEPTH-1}
 \{B5247C011B<.C>
 \}
;-- pass2 --
 0800 B800{ltb};マクロの初期化
 CC{flg}{PASS_2|DEFINED_ONLY}
 0C(fname$)0900080004[fcs]C8{fho}{cl}
 \{65{opt}{NO_HEADING}1A<.B>0C(macHead$)0D(010)04[fputm]
 \}
 04[execPassN] 04[flashBuf]
 \{85{lcp}7C056C0518<.B>
  84{lct}04[fputm]
 \}04[fcloseo]04[ftime]
;-- pass3 --
 8C(macHead$.or)2C 8D(macHead$.sz)45457C042C EA36{lcp}
 0C(MSG\objInfo)04[htoc3]7C04 04[htoc3]7C04 04[htoc3]
 08{MSG\OBJ_INFO}
\};finf
retToDos
\{04[Puts]86{sau}87{sas}79{brkMsk}08
 3832A0{bp}3C9024600D1B067C042C9F
\}07
ferror
\{28 0C(MSG\errNum)04[htoc]08{MSG\ERROR_FCS}04[Puts]
\}12<_error>
error
\{04[Puts]80{lnc}7F{lnc+1}7F{lnc+2}18<.B>
 0C(MSG\errLine)C0{lnc}{lnc+2}EA36{lnc}
 04[htoc3]08{MSG\ERROR_LINE}04[Puts]
\};finf
_error
\{04[fcloseo]04[fclosei]
 \{61{fho}FF18<.B>0C(fname$)090E04[forcedFcs]
 \}
 08{MSG\PERIOD}
\}13<retToDos>
;-----------------------------------------------------------
;   low level procedures
;-----------------------------------------------------------
;-- file iocs --
wrt
\{6C05 65{flg}{PASS_2}18<.B> A0{lwd}2C
 \{84{obp}B024A4{obp}D704{osa}1A<.B>04[flashBuf]CA{obp}{oba}
 \}3C
\}06
flashBuf
\{2D84{oba}85{obp}4D5418<.B>04[fputm]
\}3D06
Puts 0D(msgBase$)FD32 0A;tric
_puts 0901
\{FD45
 \{9025E41B<.C>
 \}7C011B<.C> A0{cl}4D54 7C05 0904
\};finf
forcedFcs
 05(sysFcs)06
fcloseo
 C8{cl}{fho}12<fclose>
fclosei
 C8{cl}{fhi}CC{fhi}FF;finf
fclose
 090213<forcedFcs>
fputm
 0904C8{cl}{fho};finf
fcs
 05(sysFcs)1D<ferror>06
;--
putTarFilenameWithPassNum
\{2C2D
 \{08{MSG\PASS1}65{flg}{PASS_2}18<.B>08{MSG\PASS2}
 \}04[Puts]85{tnp}04[_puts]08{MSG\CLOSE_BRACE}04[Puts]
 3D3C
\}06
;-- charToHex, hexToChar --
lctoh 9024;finf
ctoh
\{4830600A1C<.B>481160401E<stc>701F60061E<stc>400A
\}9F06
;
htoc3 04[htoc]04[htoc];finf
htoc
\{382804[.B]38EE
\}700F600A1C0240074030B034;finf
stc 9706
;--
memcpy
\{9024B025 7C01 1B<.C>
\}06
;--
ftime
\{0900 0C(devClockName) 05(sysDev) 1C<.B>
 0800 0946 0D(fileInfo$) 0820 B005 05(sysDev) 1C<.B>
 0C(fname$) 0801 090B 04[forcedFcs]
\}06
;-----------------------------------------------------------
;   expression evalution
;-----------------------------------------------------------
expressionK 4002;finf
expression  A0{cmk} CC{prio}{operaTable\prioMax};finf
recExpression
\{04[_recExprPrioN]
 902463{cmk}1A<serr>71{flg}{~DEFINED_ONLY}
\}06
_recExprPrioN
\{D707{slm}08{ERR\COMPLX}1E<err>
 61{prio}001A<_binaryOp>04[primary]12<.B>
_binaryOp
 7D{prio}04[_recExprPrioN]6D{prio}  ;第一引き数を読む
 \{04[getOperator]1E<.B>
  0A[.C]B237 B337 EA36{wk1}         ;作用素の実行準備
  7D{prio}04[_recExprPrioN]6D{prio} ;第二引き数を読む
  CA{wk2}{wk1} E226{wk1} 06;as call ;作用素の実行
 \}
\}06
;
getOperator
\{2D
 0D(operaTable)80{prio}455090054550
 E104{wk3}
 \{9225 9325 6000 18<.B>
   63{wk3l}1B<.C> 74 60' '18<_1>1E<_2>
   B7{wk3l}{wk3m}19<.C>12<_1>
_2 63{wk3m}1B<.C> 6C04
_1 6C04 97
 \}
\}3D 06
;
serr 08{ERR\SYNTAX}
err  02[error]
;
primary
\{D707{slm}08{ERR\COMPLX}1F<err>
 CA{wk1}{const0}
_ident
 9004 60'~'18<_ones>             ; '~' <primary>
 48'0'1C<_extra>18<_hexnum>480A1E<_label>
_decnum                          ;１０進数定数
 \{04[lctoh]1C<_retnum>600A1E<_retnum>
  2C2D 84{wk1}4544FD544544454445454540A4{wk1} 3D3C13<.C>
 \}
_extra
 6C04
 60{021-030}18<_logNot>          ; '!' <primary>
 60{028-030}18<_kakko>           ; '(' <expression> ')'
 60{02D-030}18<_twos>            ; '-' <primary>
 60{02B-030}19<_ident>           ; '+' <primary>
 60{027-030}18<_char>            ;文字定数
 A5{wk1}60{02A-030}18<.B>        ;ロケーションカウンタ
 CA{wk1}{slc}60{025-030}18<.B>   ;サブロケーションカウンタ
 7C04
_label
 04[getLabelValue]12<.B>         ;ラベル
_char
 \{04[getChrAsConst]1D<serr>
  A2{wk1}
  9024 60'\''1B<serr>
 \}12<.B>
_kakko
 CC{prio}{operaTable\prioMax}
 04[_recExprPrioN] 902460')'1B<serr>
 CC{prio}00 12<.B>
_ones   6C04 04[primary]02[opera\onesCompl]
_twos        04[primary]02[opera\uMinus]
_logNot      04[primary]02[opera\logNot]
_hexnum                          ;１６進数定数
 \{04[lctoh]1C<.B>0903EC{wk1+2}7B{wk1h}13<.C>
 \}C0{wk1l}{wk1h}
_retnum
 7C04
\}06
;
getLabelValue
\{9004 65{flg}{PASS_2|DEFINED_ONLY}18<.pass1>
.pass2
 \{60'\\'18<rootSeek>60':'18<relSeek>
autoSeek
  04[setLabel]19<serr>
  2D2C 84{snp}
  \{04[_seekLabel]1C<value> D704{sna}18<.B>953413<.C>
  \}
.undlb 08{ERR\UDFLBL}0B;tric
.iptlb 08{ERR\LBLPTH}13<err>
rootSeek
  6C04 04[setLabel]
@sserr 19<serr>
  2D2C 84{sna}12<_seek>
relSeek
  CC{wk1}00
  \{902441{wk1}031D<.iptlb>60':'19<.C>7C04
  \} 04[setLabel]19<@sserr>
  2D2C 84{snp}80{wk1}48064D40 D704{sna}18<_seek>1F<.iptlb>
_seek 04[_seekLabel]1F<.undlb>
value
  \{3C E235{wk1} 9004 60'\\'1A<.B>
   6C04 04[setLabel] 19<@sserr>
   2C
   9035   6001 1B<.iptlb>
   94C506 D704{wk1}1B<.iptlb>
   0C(dummyPnt)
   B504 04[_seekLabel]1D<.C>
   13<.undlb>
  \}3D
 \}06
.pass1
 \{60'\\'18<rootSeek>60':'1A<autoSeek>
relSeek
  \{9024 60':'19<.C>7C04
  \}0B;tric
rootSeek 6C04
autoSeek
  04[setLabel]19<@sserr>900460'\\'19<rootSeek>
 \}
\}06
;-----------------------------------------------------------
;   label control system
;-----------------------------------------------------------
isLblChr
\{60'{'1E<.u>60'a'1E<.B>60'_'18<.B>60'['1E<.r>60'?'1E<.B>
 60':'1E<.r>60'0'1E<.B>60'.'18<.B>60'$'18<.B>60'#'18<.B>
.r 9706
.u 60801C<.B>60FD1F<.r>9F
\}06
;
setLabel
\{CC{lol}02A4{sol}2D
 \{6D{lol}18<err52>902404[isLblChr]1F<.C>
 \}3D7C04 49{lol}03
\}06
;
skipLabel DC{sol}(lblSkp$)84{snp};finf
_seekLabel
\{2C9504CC{sdc}01
 \{903548031E<.lb> 60FE1C<.B>18<.sp>
.sm 7D{sdc}18<.B>13<.C>
.sp 6D{sdc}      13<.C>
.lb 63{lol}1A<.s7>
  \{2890C50160'@'3818<.B>61{sdc}011A<.s7>
  \}84{sol}81{lol}
  \{E035{cmw}902463{cmw}1A<.B>7C011B<.C>973C06;/* labelfound
  \}FD237C00
.s7 4003 4D5013<.C>
 \}9F3C
\}06
;
defineLabel
\{84{snp}
 \{9800{sol}60'@'1A<.B>84{sna}
 \}
 04[_seekLabel]08{ERR\DUPLBL}1C<errHk1>
 84{sol}81{lol}08034601B005
 \{9024B035 D705{esp}08{ERR\MEMEXH}1E<errHk1>7C011B<.C>
 \}EA35{wk1}0800B035 A5{ltp}
\}06
;
_setLocTbl
\{84{lcp}D704{cdt}18<err21>B024A4{lcp}
\}06
;
setLocTbl
\{65{flg}{PASS_2}1A<.B>
 \{9004090060'['18<.B>098060'('08{ERR\SYNTAX}1A<errHk1>
 \}FD23
 2C2D
 \{84{lad}4D54A5{wk2}0C(07E)4D541E<.long>
.short 7F{wk2l}12<.B>
.long  787E 04[_setLocTbl]80{wk2l}04[_setLocTbl]80{wk2m}
 \}04[_setLocTbl]
 3D3C A5{lad}
\}02[dataAsm]
;
err52 08{ERR\LNGLBL}12<errHk1>
err81 49{tnp}2008{ERR\FN_EXP}12<errHk1>
err21 08{ERR\RELTBL}
errHk1 02[error]
;-----------------------------------------------------------
;   main procedure: exec_pass_n
;-----------------------------------------------------------
execPassN
 08{MSG\CRLFSP}04[Puts] 84{agp};finf
recPassN
\{;-- ｿ-ｽ ﾌｧｲﾙ ﾖﾐｺﾐ --
 2D85{tnp}05(sysDos)1D<err81>
 E885{piflv}16 CC{piflv}00
 B4851A EA85{esp}17 EA85{lnc}1D CA{lnc}{const0}
 04[putTarFilenameWithPassNum]
 ;-- get file size --
 84{tnp}090B0800 0D(fileInfo$)04[fcs]
 948505 85{esp} 2D 2C 2D 455408204550
 08{ERR\MEMEXH}D705{ltp}1D<errHk1>
 A5{esp}
 ;-- file load --
 84{tnp}0901080104[fcs]C8{fhi}{cl}
 3C3D   0903080004[fcs]
 08'^Z'B024 04[fclosei]
 3C3D
 ;-- org ｷﾞｼﾞ ﾒｲﾚｲ ｼｮﾘ --
 6D{lnc+2}
 65{flg}{DEFINED_ONLY}18<lineAssembler\_topOfLine>
 902460'\\'08{ERR\LCCUDF}1A<errHk0>
 \{92040B'nh'4C231A<.B>
  9224902460'\\'08{ERR\LCCUDF}1A<errHk0>
  79{opt}{NO_HEADING}
 \}
 85{const0}A5{slc}
 CC{prio}{operaTable\prioMax} 04[_recExprPrioN]
 85{wk1} A5{lad}A5{slc}AD(macHead$.or)
 71{flg}{~DEFINED_ONLY}
\};finf
lineAssembler
\{;アセンブラの主駆動部
_skipComment
 \{902460' '1F<.C>
 \}
_checkEOL;行末を確認して、lncを１増やす
 \{60'^J'18<.B> 60'^M'1A<checkEOF> 902460'^J'18<.B> 7C04
 \}
 08010903C5{lnc+2}
_topOfLine
 ;行頭の処理
 9004
 60'+'14[transcendencyCmdMan];超越疑似命令？
 ;
 \{60301C<.lbl>603C1C<.B>;-- ﾗﾍﾞﾙ ﾃｲｷﾞ
.lbl
  \{04[setLabel]18<.B>A5{wk1}
   \{900460'('1A<.B>
    08')' 0904CB{slol}{lol}6C04
    79{flg}{DEFINED_ONLY}04[expression]
    0904CB{lol}{slol}
   \}
   \{65{flg}{PASS_2}1A<.B>
    2C2D04[defineLabel]3D3C
   \}
  \}
 \}
\};finf
dataAsm
\{65{ssr}0808{ERR\BREAK}1A<errHk0>
 9024 60' '19<.C> 1D<lineAssembler\_checkEOL>
 60'\\'14[stBrace] 602718<stringData> 60'('18<pntData>
 60'['18<wordData> 60'{'18<byteData> 60'<'18<relData>
 60'*'14[setLocTbl] 60';'19<lineAssembler\_skipComment>
 ;directData
 04[ctoh]1C<SERR>EEA0{wk1l}
 04[lctoh]1C<SERR>7F{wk1l}04[wrt]13<.C>
\}
;
checkEOF
\{60'^Z'1A<SERR>;-- ｿ-ｽ ｴﾝﾄﾞ --
 61{piflv}001A<errPRCLSE>
 2D 85{tnp} 94851A E285{esp}17 E285{lnc}1D E085{piflv}16 3D
\}06
;
errPRCLSE 08{ERR\PRCLSE}0B;tric
SERR      08{ERR\SYNTAX}
errHk0    02[error]
;
pntData 08')'04[expression];finf
_pntData
\{80{wk1l}04[wrt]80{wk1m}04[wrt]80{wk1h}04[wrt]
\}13<dataAsm>
wordData
\{04[expressionK]80{wk1l}04[wrt]80{wk1m}04[wrt]
\}13<dataAsm>
byteData
 04[expressionK];finf
byteData2
 80{wk1l}04[wrt]13<dataAsm>
;
stringData
\{04[getChrAsConst]1C<.B>
 2A 04[wrt]
 3A 74 6000 19<.C> 04[wrt] 13<.C>
\}19<dataAsm>08{ERR\SYNTAX}13<errHk0>
relData
\{04[expressionK]65{flg}{PASS_2}19<byteData2>
 08{ERR\BRDRFL}
 2C2D84{wk1}
 \{4D546C05 65{lwd}011C<.rp>
.rm 19<errHk0>A5{wk1}12<.B>   ;JRnn -
.rp 1B<errHk0>0C(0)4D45A4{wk1};JRnn +
 \}08{ERR\BR_FAR}0900D603{wk1m}1B<errHk0>
 3D3C
\}13<byteData2>
;
stBrace
\{A5{wk1}CC{lol}02 9024 2C2D
 60'{'18<.bra>60'}'1A<escCmdMan>
.ace
 \{65{flg}{PASS_2}1A<.p2>
.p1 C7{sna}{snp}
    08{ERR\STBMPA}19<errHk0>
    DC{sol}(lblBrk$)04[defineLabel]
    0802B0050800B035A5{ltp}
.p2 84{snp}9534A4{snp}
 \}12<.B>
.bra
 \{65{flg}{PASS_2}1A<.p2>
.p1 0D(stNestTbl$+3*(DEPTH-1))
  D705{snp}08{ERR\STBNST}19<errHk0>
  04[skipLabel] 0801B00584{snp}B58403
  0800B035 9524A4{snp}
  DC{sol}(lblCnt$)04[defineLabel]12<.B>
.p2
  \{84{snp}95242D9504 A4{snp}3C
   4D451C<.e>04[skipLabel]12<.B>
.e 84{snp}9534
  \}
  \{903560031C<.B>4D5013<.C>
  \}84{snp}B504
 \}
\}3D3C02[dataAsm]
;
escCmdMan
\{3D3C 7C0404[setLabel]18<serr00>
 2D2C 0D(escCmdList)04[_searchMacroName]1C<_inMacro>
 ;ユーザ定義マクロの処理
 \{85{ltb}04[_searchMacroName]1E<errUDFLBL>
  9225 A5{wk1}; as wk1 <- Y+2 ;マクロ本体のアドレスを保存
  ;仮引き数の準備
  3C 0D(macroArg) 0910 9024 60'('1A<serr00>
  \{B425
   \{04[getChrAsParam]1F<.C>1A<serr00>
   \}60')'18<_close>
   7C01 1B<.C>12<errMCRPRA>
_close 7C04 7C01 1B<.C> 6C04
  \}
  ;各ポインタの保存
  41{tnp}20 08{ERR\INCNST}18<errHk00>
  85{tnp}
  E885{piflv}16 CC{piflv}00
  B4851A EA85{esp}17 EA85{lnc}1D CA{lnc}{const0}
  ;マクロ名を疑似的にファイル名に見せかける
  85{tnp}0C(macroDrive)09{19}04[memcpy]
  08{13}4D50 84{sol}
  \{090C 61{lol}0C 1E<.B> 81{lol}
  \}04[memcpy]
  04[putTarFilenameWithPassNum];マクロ名の表示
  85{esp} 84{wk1}
  \{9024 60'%'1A<_chr>04[lctoh]1C<_qch>
_rep;-- %0 .. %F の置き替え
   2C 2D 0D(macroArg)4550 E6 4550 9405 3D
   \{04[getChrAsParam]1C<.B>
    B025 D705{ltp}1C<errMEMEXH> 13<.C>
   \}
   3C13<.C>
_qch 90C401
_chr B025 D705{ltp}1C<errMEMEXH> 60'^Z'1B<.C>
  \}
  08204550 D705{ltp}1C<errMEMEXH>
  84{esp} A5{esp}
  ;マクロ実行
  3D 6D{lnc+2} 04[lineAssembler\_topOfLine]
  49{tnp}20
  ;元の処理対象を表示して、処理をわたす
  04[putTarFilenameWithPassNum]
 \}02[dataAsm]
 ;内部マクロの処理
_inMacro 908502 A0{vat}
 3C3D
 60041C<defineLabelsCStyle>18<inequCheck>
 600518<dataNumFormated>
\}08{ERR\INTERL}0B;tric,finf
errMEMEXH 08{ERR\MEMEXH}0B;tric
errUDFLBL 08{ERR\UDFLBL}0B;tric
errMCRPRA 08{ERR\MCRPRA}0B;tric
inequErr  08{ERR\LBLTST}0B;tric
serr00    08{ERR\SYNTAX}
errHk00   02[error]
;
inequCheck
\{902460'('1B<serr00>
 08')'04[expression]
 \{65{flg}{PASS_2}18<.B>
  C7{wk1}{const0}19<inequErr>
 \}
\}02[dataAsm]
;
defineLabelsCStyle
\{902460' '1B<serr00>
 \{9004 60301C<.l>603C1D<serr00>
.l 04[setLabel]19<serr00>
  \{900460'('1A<.B>
   08')' 0904CB{slol}{lol}6C04
   79{flg}{DEFINED_ONLY}04[expression]
   0904CB{lol}{slol}
   CA{slc}{wk1}
  \}CA{wk1}{slc}
  \{65{flg}{PASS_2}1A<.B>
   2C2D04[defineLabel]3D3C
  \}
  \{61{vat}0018<_sft>
   DC{wk1}(1)
   \{900460'['1A<.B>
    6C04 79{flg}{DEFINED_ONLY}
    04[expressionK]
   \}
   80{vat}
   \{090354{slc}{wk1}7C001B<.C>
   \}12<.B>
_sft
   ;9F;ｽﾃﾞﾆ cf == 0 ﾃﾞｱﾙ
   F7{slc}F7{slc+1}F7{slc+2}
  \}
  902460','19<.C>7C04
 \}
\}02[dataAsm]
;
dataNumFormated
\{902460'('1B<serr00>
 ; 書式を解析する
 CC{vat}00
 \{9024 09{FMT_MONTH}60'M'18<.B>
  \{60'0'1A<.B> 79{vat}{FMT_ZERO}9024
  \}
  \{60'1'1C<.B>60':'1E<.B> 700F7B{vat}9024
  \}
  09{FMT_dec}60'u'18<.B> 09{FMT_HEX}60'X'18<.B>
  09{FMT_hex}60'x'18<.B> 08{ERR\STRFER}13<errHk00>
 \}FD237B{vat}
 902460','1B<serr00>
 ; 式の値を求める
 79{flg}{DEFINED_ONLY}08')'04[expression]CA{wk2}{wk1}
 65{vat}{FMT_dec|FMT_HEX|FMT_hex}1A<_num>
_month
 ; 例外処理:英語名の月に直す
 82{wk1+1}6C027C021A<_err>80{wk1}7C00 600C1E<_err>
 2C 0C(monthTable)4540 E6 4540 E204{wk1}
 3C 02[_pntData]
_err 08{ERR\ILLPAR}02[error]
_num
 ; 基数を決定する
 \{DC{wk1}(10) 65{vat}{FMT_dec}1A<.B> CC{wk1}10
 \}
 ; 文字列に変換する
 08FF 28
 \{C2{wk1}{wk2} 04[opera\_dv]
  \{80{wk3}40'0'60':'1C<.B>4007 65{vat}{FMT_hex}18<.B>4020
  \}28
  \{65{vat}0F18<.B>7D{vat}
  \}
  80{wk2}7F{wk2+1}7F{wk2+2}1B<.C>
 \}
 ; 余ったフィールドを埋める
 \{80{vat}
  \{09' '64{FMT_ZERO}18<.B>09'0'
  \}700F18<.B>
  \{29 7C00 1B<.C>
  \}
 \}
 ; オブジェクトファイルに出力する
 \{3860FF18<.B>04[wrt]13<.C>
 \}
\}02[dataAsm]
;-----------------------------------------------------------
;   超越疑似命令の処理
;-----------------------------------------------------------
transcendencyCmdMan
\{6C04 04[getTrnCmdCode]
 ;-----------------------------------
 60{TRN_INCLUDE}1A<_1>;-- +INCLUDE --
 \{41{tnp}20 08{ERR\INCNST}18<_errHk2> 04[recPassN]
  49{tnp}20 04[putTarFilenameWithPassNum]
 \}02[lineAssembler]
 ;-----------------------------------
_1 60{TRN_ERROR}1A<_2>;-- +ERROR ----
 \{0D(ERR\userErrorMsg)09{25}
  \{04[getChrAsConst]1C<.B> 7C0118<.B>
   B025 74 6000 19<.C> B025 7C011B<.C>
  \}
 \}0800 B025 08{ERR\USRERR}
_errHk2 12<errHk2>
 ;---------------------------------------
_2 60{TRN_DEFMACRO}1A<_3>;-- +DEFMACRO --
 \{2D
  04[skipSpc]04[setLabel]18<errPREPER>
  \{;マクロ名の登録
   2C 85{ltb}04[_searchMacroName]1C<errDUPMAN>
   81{lol}84{sol} B1C501
   \{9024B025 D705{lct}1C<errMTBEXH>;<--大まかな溢れ検査
    7C01 1B<.C>
   \}
   3C 04[skipLine]
  \}
  \{;マクロ本体の登録
   2D;<--マクロ本体の大きさを書きこむ位置を保存しておく
   B225;<--ワード領域を確保
   0901
   \{900460'+'1A<_macrobody>
    2B2C 6C04 04[getTrnCmdCode] 3C3B 60{TRN_ENDMACRO}18<.B>
_macrobody
    \{9024B025 D705{lct}1C<errMTBEXH>;<--大まかな溢れ検査
     6C03 60' '1F<.C>
    \}
    60'^Z'18<errUEXEOF>
    \{60'^J'18<.B> 60'^M'1A<errSYNTAX>
     9024  60'^J'18<.B> 7C04
    \}
    2B 08010903C5{lnc+2}
    3B 13<.C>
   \}
   ;エンドマークの書き込みと、空き領域の厳密な検査
   0A1A00 B225 D705{lct}18<errMTBEXH>1C<errMTBEXH>
   ;マクロ本体の大きさの書きこみ
   3D B325
  \}
  3D
 \}02[lineAssembler]
_3 64{TRN_IF}18<_4>;-- +IF, +IFDEF, +IFNDEF --
 \{2D 6D{piflv}18<errPRIFOV>
  \{04[trnIfCond]1C<.B>;条件成立-->終了
   04[trnSerachCorsp]
   64{TRN_ELSEIF}1B<.C>
   3D12<_endif>
  \}3D 02[lineAssembler]
 \}
_4 64{TRN_ELSEIF}18<_5>;-- +ELSEIF..., +ELSE
 \{2D 61{piflv}0018<errPRELSE>
  \{04[trnIfCondSkip]
   04[trnSerachCorsp]
   64{TRN_ELSEIF}1B<.C>
   3D12<_endif>
  \}3D 02[lineAssembler]
 \}
_5 64{TRN_ENDIF}18<_6>;-- +ENDIF
_endif 49{piflv}011C<errPREDIF> 02[lineAssembler]
_6;-- エラーです --
\};finf
errPREPER 08{ERR\PREPER}0B;tric
errMTBEXH 08{ERR\MTBEXH}0B;tric
errDUPMAN 08{ERR\DUPLBL}0B;tric
errSYNTAX 08{ERR\SYNTAX}0B;tric
errPRELSE 08{ERR\PRELSE}0B;tric
errPREDIF 08{ERR\PREDIF}0B;tric
errPRIFOV 08{ERR\PRIFOV}0B;tric
errUEXEOF 08{ERR\UEXEOF}
errHk2    02[error]
;
getTrnCmdCode
\{04[skipSpc]04[setLabel]19<errPREPER>
 2C2D 0D(trnCmdList)04[_searchMacroName]1F<errPREPER>
      908502
 3D3C
\}06
;
trnSerachCorsp
\{CC{wk1}00
 \{04[skipLine]900460'+'1B<.C>
  6C04 04[getTrnCmdCode]
  64{TRN_IF}18<_1>     6D{wk1}19<errPRIFOV>13<.C>;+IF...
_1 64{TRN_ENDIF}18<_2> 49{wk1}011F<.C>06         ;+ENDIF
_2 64{TRN_ELSEIF}19<.C>  61{wk1}001B<.C>06         ;+ELSE..
 \}
\}
;
trnIfCond; c=1 is TRUE;
\{700318<_num>
  600218<_ndef>1E<_t>
_def; IFDEF or ELSEIFDEF
  04[skipSpc]04[setLabel]19<errPREPER>
  2C 85{ltb}04[_searchMacroName]
  3C 06
_ndef; IFNDEF or ELSEIFNDEF
  04[skipSpc]04[setLabel]19<errPREPER>
  2C 85{ltb}04[_searchMacroName]
  3C 1C<.B>
_t 9706; ELSE
_num; IF() or ELSEIF()
  9024 60'('1B<errSYNTAX>
  08')' 79{flg}{DEFINED_ONLY}04[expression]
  C7{wk1}{const0}1B<_t>
\}9F06
;
trnIfCondSkip
\{700318<_num>600318<.B>
 ; IFDEF or ELSEIFDEF or IFNDEF or ELSEIFNDEF
  04[skipSpc]04[setLabel]19<errPREPER> 12<.B>
_num; IF or ELSEIF
  9024 60'('1B<errSYNTAX>04[expression]
  9024 60')'1B<errSYNTAX>
\}06
;-----------------------------------------------------------
skipLine
\{
 \{902460' '1F<.C>
 \}
 60'^Z'19<errUEXEOF>
 \{60'^J'18<.B> 60'^M'1B<errSYNTAX> 902460'^J'18<.B> 7C04
 \}
 08010903C5{lnc+2}
\}06
;
skipSpc
\{9024 60' '19<.C> 7C04
\}06
;
_searchMacroName; ret.val. is (c=1 ? found : notfound)
\{9025600018<.B>
 \{63{lol}1A<.B>84{sol}FD32
  \{E025{cmw}90244A{cmw}1A<.B>7C011B<.C>9706
  \}FD237C00
 \}4550 9225 4552 13<.C>
\}06
;-----------------------------------------------------------
getChrAsParam
\{0A[0]
 ; ','(comma) --> C:1 Z:1
 902460','18<getChrAsConst\_sc>
 ; ')' --> C:1 Z:1
     60')'12<getChrAsConst\_GCAP>
\};ltnf (link to next function)
getChrAsConst
\{0A[0]
 ; $27 --> C:1 Z:1
 90246027
_GCAP     18<_sc>
 ; $00-$1F --> C:1 Z:0
     60201C<.B>
 ; '^?' - '^_'
     60'\^'1A<_1>
       9024603F1C<_q>60601E<_scrz>68409F06
 ; '\ ' - '\~'
_1   60'\\'1A<_2>
       902460201C<_q>607F1E<_scrz>    9F06
_2   60811C<_ok>60A01C<_sji>
     60E01C<_ok>60FD1E<_scrz>
_sji 75 9024
     60401C<_q>607F18<_scrz>60FD1E<_scrz>
     DD
_ok  9F06
_scrz 6027
_sc   97
_q
\}06
;-----------------------------------------------------------
opera
\{;次のように演算が行われる wk1 op. wk2 --> wk1
add    0903 54{wk1}{wk2}06
sub    0903 5C{wk1}{wk2}06
mul    \{0818 CA{wk3}{wk2} CA{wk2}{const0}
        \{
         \{090654{wk2}{wk2}1E<.B>090354{wk2}{wk1}
         \}7C001B<.C>
        \}
       \}CA{wk1}{wk2}06
div    04[_dv]CA{wk1}{wk2}06
mod    04[_dv]CA{wk1}{wk3}06
_dv    \{; wk1 / wk2 --> wk2 ... wk3
        0818 CA{wk3}{const0} C2{wk1}{wk2}
        \{0906 54{wk2}{wk2}
         \{0903 5C{wk3}{wk1}1C<_a>6D{wk2l}12<.B>
_a        0903 54{wk3}{wk1}
         \}7C001B<.C>
        \}
       \}06
shl    C6{wk2m}{const0}1A<zero>
       \{80{wk2l}600018<.B>
        \{9F F7{wk1l}F7{wk1m}F7{wk1h} 7C00 1B<.C>
        \}
       \}06
shr    C6{wk2m}{const0}1A<zero>
       \{80{wk2l}600018<.B>
        \{9F F5{wk1h}F5{wk1m}F5{wk1l} 7C00 1B<.C>
        \}
       \}06
onesCompl
       DC{wk2}(-1);finf
bitXor 6E{wk1l}{wk2l}6E{wk1m}{wk2m}6E{wk1h}{wk2h}06
bitOr  7E{wk1l}{wk2l}7E{wk1m}{wk2m}7E{wk1h}{wk2h}06
bitAnd 76{wk1l}{wk2l}76{wk1m}{wk2m}76{wk1h}{wk2h}06
uMinus CA{wk2}{wk1}CA{wk1}{const0}09035C{wk1}{wk2};finf
uPlus  06
logNot CA{wk2}{const0};finf
equ    C7{wk1}{wk2}18<_T_>
_F_    ;finf
zero   CA{wk1}{const0}06
_T_    DC{wk1}(_TRUE_)06
neq    C7{wk1}{wk2}1B<_T_>13<_F_>
grt    C7{wk2}{wk1}1D<_T_>13<_F_>
leq    C7{wk2}{wk1}1F<_T_>13<_F_>
les    C7{wk1}{wk2}1D<_T_>13<_F_>
geq    C7{wk1}{wk2}1F<_T_>13<_F_>
logOr  C7{wk1}{const0}1B<_T_>C7{wk2}{const0}1B<_T_>13<_F_>
logAnd C7{wk1}{const0}19<_F_>C7{wk2}{const0}19<_F_>13<_T_>
\}
;-----------------------------------------------------------
;  dos request 02h
;              (EVE/62015 ver1.30-948A)
;  copyright (c)1990-1994 N.Masuichi
;      all rights reserved
;   last update 1994/08/28 10:22
;-----------------------------------------------------------
sysCurDrv$(0BFC7D)
sysDos
\{2D CC{argtyp}00
 \{04[isVchrL]19<.C>
  7C04 08811C<abort> FD54
  \{04[isVchrL]1F<.C>68':'18<.B>
   FD450D(sysCurDrv$) CC{argtyp}{_CUR_DRIVE_}
  \}2CFD459586030906
  \{9024B02568':'18<.a>
   7C011B<.C>080A3C12<abort>
.s B025
.a 0A'  '7C011B<.s>
  \}3C
  \{900404[isVchr]1E<.B>
   60'.'18<.B>0A' ?'
  \}090804[nameCopy]
  \{60'.'1A<.B>6C04 79{argtyp}{_WITH_EXTENSION_}
  \}08'.'B025090304[nameCopy]B125
 \}0801 9F
abort
\}3D07
;
nameCopy
\{900404[isVchr]
 \{68'*'08'?'18<.B>741C<.B>9024
 \}B0257C011B<.C>
\};finf
skip
\{04[isVchrL]1F<.C>7C04
\}06
;
isVchrL 9024;finf
isVchr
\{60FF18<rzsc>60'"'18<sc>
 60'<'18<sc>60'>'18<sc>
 60':'18<sc>60'.'18<sc>602018<sc>06
rzsc 6000
sc 97
\}06
;-----------------------------------------------------------
;   section data
;-----------------------------------------------------------
;
; 式評価のための作用素テーブル
;
operaTable
\{{00}     {prio1-*}{prio2-*}{prio3-*}{prio4-*}{prio5-*}
  {prio6-*}{prio7-*}{prio8-*}{prio9-*}{prioA-*}
prio1 '* '[opera\mul]'/ '[opera\div]'% '[opera\mod] 00
prio2 '+ '[opera\add]'- '[opera\sub] 00
prio3 '<<'[opera\shl]'>>'[opera\shr] 00
prio4 '<='[opera\leq]'<|'[opera\les]
      '>='[opera\geq]'|>'[opera\grt] 00
prio5 '!='[opera\neq]'=='[opera\equ] 00
prio6 '&'1F[opera\bitAnd] 00
prio7 '\^'1F[opera\bitXor] 00
prio8 '|'1F[opera\bitOr] 00
prio9 '&&'[opera\logAnd] 00
prioA '||'[opera\logOr] 00
prioMax(0A)
\}
;
; ￥エスケープコマンドのリスト
;
escCmdList
 04 'BYTE' [1] 01
 04 'ENUM' [1] 01
 04 'WORD' [1] 02
 04 'PNTR' [1] 03
 04 'FLAG' [1] 00
 04 'TEST' [1] 04
 04 'STRF' [1] 05
 00
;
;   超越擬似命令のリスト

trnCmdList
\ENUM TRN_INCLUDE(080)  07'INCLUDE'   [1]{TRN_INCLUDE}
\ENUM TRN_ERROR(081)    05'ERROR'     [1]{TRN_ERROR}
\ENUM TRN_DEFMACRO(040) 08'DEFMACRO'  [1]{TRN_DEFMACRO}
\ENUM TRN_ENDMACRO(041) 08'ENDMACRO'  [1]{TRN_ENDMACRO}
\ENUM TRN_IF(020)       02'IF'        [1]{TRN_IF}
\ENUM TRN_IFDEF(021)    05'IFDEF'     [1]{TRN_IFDEF}
\ENUM TRN_IFNDEF(022)   06'IFNDEF'    [1]{TRN_IFNDEF}
\ENUM TRN_ELSEIF(010)     06'ELSEIF'     [1]{TRN_ELSEIF}
\ENUM TRN_ELSEIFDEF(011)  09'ELSEIFDEF'  [1]{TRN_ELSEIFDEF}
\ENUM TRN_ELSEIFNDEF(012) 0A'ELSEIFNDEF' [1]{TRN_ELSEIFNDEF}
\ENUM TRN_ELSE(013)       04'ELSE'       [1]{TRN_ELSE}
\ENUM TRN_ENDIF(008)    05'ENDIF'      [1]{TRN_ENDIF}
                        00
;
monthTable
 'JanFebMarAprMayJunJulAugSepOctNovDec'
;-----------------------------------------------------------
initIram$
 (asEntry)
 (outBuf$)
 (sysArea$)
 (outBuf$);obp
 (txNestTbl$)
 (stNestTbl$)
 (stNestTbl$)
 00;lwd
 FF;fhi
 FF;fho
 (0);lnc
 00;opt
 (0);const0
initIram$e
;
lblBrk$ '.B'00
lblCnt$ '.C'00
lblSkp$ '++'00
;
;-----------------12345678.123---
macroDrive '_ﾏｸﾛ_:            '00
;
devClockName 'CLOCK:'00
;
macHead$    FF00060110
macHead$.sz 000000
macHead$.or 000000 FFFFFF 000F
;-----------------------------------------------------------
; 各種メッセージ
;-----------------------------------------------------------
msgBase$
MSG
\{
 \ENUM CREDIT(1)
              \CREDIT_STRING()
 \ENUM USAGE  'USAGE : MASSE [-Mx/-Rx] source [object]^M^J'00
 \ENUM ERROR_LINE
              ' in 000000'
errLine                  00
 \ENUM ERROR_FCS
              'Error 00'
errNum                ' in fcs'00
 \ENUM PERIOD '.^M^J'00
 \ENUM CRLFSP ' ^M^J'00
 \ENUM PASS1  '^^Pass 1 ['00
 \ENUM PASS2  '^^Pass 2 ['00
 \ENUM CLOSE_BRACE
              ']^M^J'00
 \ENUM OBJ_INFO
              'Object:000000-000000[000000'
objInfo                                  ']^M^J'00
\};find
ERR
\{
 \ENUM SYNTAX 'Syntax error'00
 \ENUM MEMEXH 'Memory exhausted'00
 \ENUM RELTBL 'Relocation table exhausted'00
 \ENUM LCCUDF 'Location counter undefined'00
 \ENUM INCNST 'Include nest over'00
 \ENUM STBNCL 'Struct brace not closed'00
 \ENUM STBMPA '\'\\}\' used without \'\\{\''00
 \ENUM STBNST 'Struct brace nest over'00
 \ENUM COMPLX 'Too complex expression'00
 \ENUM UDFLBL 'Undefined identifier'00
 \ENUM DUPLBL 'Duplicate identifier'00
 \ENUM LNGLBL 'Too long idenitfier'00
 \ENUM UEXEOF 'Unexpected EOF'00
 \ENUM MTBEXH 'Macro table exhausted'00
 \ENUM NO_OBJ 'No object'00
 \ENUM BRDRFL 'Branch direction false'00
 \ENUM BR_FAR 'Branch too far'00
 \ENUM FN_EXP 'Filename expected'00
 \ENUM LBLPTH 'Illegal label path'00
 \ENUM BREAK  'User break'00
 \ENUM INTERL 'Sorry, internal error'00
 \ENUM LBLTST '\'\\TEST\' error'00
 \ENUM STRFER '\'\\STRF\' format error'00
 \ENUM ILLPAR 'Data out of range'00
 \ENUM MCRPRA 'Macro parameter error'00
 \ENUM PREPER '\'+\' command error'00
 \ENUM PRCLSE '\'+IF\'-\'+ENDIF\' not closed'00
 \ENUM PRIFOV '\'+IF\'-\'+ENDIF\' nest over'00
 \ENUM PRELSE '\'+ELSE\' used without \'+IF\''00
 \ENUM PREDIF '\'+ENDIF\' used without \'+IF\''00
 \ENUM USRERR
userErrorMsg  ;about 30 chars
\}
\TEST(%<|256)
;-----------------------------------------------------------
;   section storage
;-----------------------------------------------------------
dummyPnt;pnt
;
\TEST(*+3<|0BF000)
;
\BYTE fname$(0BF000)[32],fname2$[32],fileInfo$[8]
;
\PNTR macroArg(0BF100)[16]
\BYTE stNestTbl$(0BF200)[256]
\BYTE txNestTbl$(0BF300)[256]
\BYTE outBuf$(0BF400)[sysArea$-0BF400]
;-----------------------------------------------------------
;   end of source
;-----------------------------------------------------------
