#include "xasm.h"

#define UU_CHUNK 45u
#define ENC6(c) ((c) ? (unsigned char)((((c) & 0x3f) + ' ')) : (unsigned char)'`')

static void die_file(const char *name)
{
   printf(" File cannot create. (%s)\n", name);
   printf(" Assemble aborted.\n");
   exit(1);
}

static const char *base_name(const char *path)
{
   const char *base = path;
   for (const char *p = path; *p; ++p) {
      if ((*p == '\\') || (*p == '/') || (*p == ':')) { base = p + 1; }
   }
   return base;
}

void default_ext(unsigned char *dst, const unsigned char *src, const char *ext)
{
   int i, slash, dot;
   strcpy(dst, src);
   slash = -1; dot = -1;
   for (i = 0; dst[i] != '\0'; i++) {
      if ((dst[i] == '\\') || (dst[i] == '/') || (dst[i] == ':')) { slash = i; dot = -1; }
      if (dst[i] == '.') { dot = i; }
   }
   if (dot > slash) { dst[dot + 1] = '\0'; strcat(dst, ext); }
   else             { strcat(dst, "."); strcat(dst, ext); }
}

void parse_option_filename(int *idx, int argc, char **argv, unsigned char *dst)
{
   if (strlen(argv[*idx]) > 2) {
      strcpy(dst, argv[*idx] + 2);
   } else if ((*idx + 1 < argc) && (argv[*idx + 1][0] != '-')) {
      (*idx)++;
      strcpy(dst, argv[*idx]);
   }
}

void reset_generated_bytes(void)
{
   generated_count = 0;
}

void record_generated_byte(sc_reg addr, unsigned char value)
{
   if (pass_sw != 3) { return; }
   if (generated_count >= generated_cap) {
      generated_cap = (generated_cap == 0) ? 4096 : generated_cap * 2;
      generated_bytes = (generated_byte_typ *)realloc(generated_bytes,
                         generated_cap * sizeof(generated_byte_typ));
      if (generated_bytes == NULL) { printf("Out of memory\n"); exit(1); }
   }
   generated_bytes[generated_count].addr = addr;
   generated_bytes[generated_count].value = value;
   generated_count++;
}

void reset_sections(void)
{
   section_count = 0;
   current_section = -1;
}

void section_finish(sc_reg end)
{
   if (current_section >= 0) { sections[current_section].end = end; }
}

void section_start(const unsigned char *name)
{
   section_finish(lc);
   if (section_count >= section_cap) {
      section_cap = (section_cap == 0) ? 16 : section_cap * 2;
      sections = (section_typ *)realloc(sections, section_cap * sizeof(section_typ));
      if (sections == NULL) { printf("Out of memory\n"); exit(1); }
   }
   stricpy(sections[section_count].name, name, 31);
   sections[section_count].start = lc;
   sections[section_count].end = lc;
   current_section = section_count++;
}

void section_report_stdout(void)
{
   int i;
   if (size_report_on == FALSE) { return; }
   printf("\n - Sections -\n");
   for (i = 0; i < section_count; i++) {
      printf(" %-16s %06lXh - %06lXh [ %ld byte(s)]\n",
             sections[i].name, sections[i].start, sections[i].end - 1,
             sections[i].end - sections[i].start);
   }
}

static unsigned char ihex_checksum(unsigned char count, sc_reg addr, unsigned char type,
                                   const unsigned char *data)
{
   unsigned int sum = count + xlow(addr / 256) + xlow(addr) + type;
   int i;
   for (i = 0; i < count; i++) { sum += data[i]; }
   return (unsigned char)((~sum + 1) & 0xff);
}

void write_ihex_file(void)
{
   FILE *fp;
   int i, n;
   unsigned char data[16], chk;
   sc_reg addr;
   if (ihex_on == FALSE) { return; }
   fp = fopen(ihex_name, "w");
   if (fp == NULL) { die_file((char *)ihex_name); }
   i = 0;
   while (i < generated_count) {
      addr = generated_bytes[i].addr;
      n = 0;
      while ((i + n < generated_count) && (n < 16) &&
             (generated_bytes[i + n].addr == addr + n)) {
         data[n] = generated_bytes[i + n].value;
         n++;
      }
      chk = ihex_checksum((unsigned char)n, addr, 0, data);
      fprintf(fp, ":%02X%04lX00", n, addr & 0xffffL);
      for (int j = 0; j < n; j++) { fprintf(fp, "%02X", data[j]); }
      fprintf(fp, "%02X\n", chk);
      i += n;
   }
   fprintf(fp, ":00000001FF\n");
   fclose(fp);
}

void write_srec_file(void)
{
   FILE *fp;
   int i, n, j;
   unsigned int sum;
   sc_reg addr;
   if (srec_on == FALSE) { return; }
   fp = fopen(srec_name, "w");
   if (fp == NULL) { die_file((char *)srec_name); }
   fprintf(fp, "S0030000FC\n");
   i = 0;
   while (i < generated_count) {
      addr = generated_bytes[i].addr & 0xffffL;
      n = 0;
      while ((i + n < generated_count) && (n < 16) &&
             ((generated_bytes[i + n].addr & 0xffffL) == addr + n)) { n++; }
      sum = (unsigned int)(n + 3 + ((addr >> 8) & 0xff) + (addr & 0xff));
      fprintf(fp, "S1%02X%04lX", n + 3, addr);
      for (j = 0; j < n; j++) {
         fprintf(fp, "%02X", generated_bytes[i + j].value);
         sum += generated_bytes[i + j].value;
      }
      fprintf(fp, "%02X\n", (~sum) & 0xff);
      i += n;
   }
   fprintf(fp, "S9030000FC\n");
   fclose(fp);
}

static void map_symbols(FILE *fp, label_typ **hash, const char *prefix)
{
   int h;
   label_typ *p;
   char next_prefix[256];
   for (h = 0; h < maxhash; h++) {
      p = hash[h];
      while (p != NIL) {
         fprintf(fp, "%06lXh  %s%s\n", p->value, prefix, p->name);
         if (p->child != NIL) {
            snprintf(next_prefix, sizeof(next_prefix), "%s%s!", prefix, p->name);
            map_symbols(fp, p->child, next_prefix);
         }
         p = p->next;
      }
   }
}

void write_map_file(void)
{
   FILE *fp;
   int i;
   if (map_on == FALSE) { return; }
   fp = fopen(map_name, "w");
   if (fp == NULL) { die_file((char *)map_name); }
   fprintf(fp, "; XASM MAP file - %s\n", source_name);
   fprintf(fp, "; Code: %06lXh - %06lXh [%ld bytes]\n\n", slc, lc - 1, lc - slc);
   fprintf(fp, "; Sections:\n");
   for (i = 0; i < section_count; i++) {
      fprintf(fp, ";   %-16s %06lXh  %06lXh  %ld\n",
              sections[i].name, sections[i].start, sections[i].end - 1,
              sections[i].end - sections[i].start);
   }
   fprintf(fp, "\n; Symbols:\n");
   map_symbols(fp, root.child, "");
   fclose(fp);
}

void record_dependency(const unsigned char *name)
{
   int i;
   for (i = 0; i < dependency_count; i++) {
      if (strcmp((char *)dependencies[i], (char *)name) == 0) { return; }
   }
   if (dependency_count >= dependency_cap) {
      dependency_cap = (dependency_cap == 0) ? 16 : dependency_cap * 2;
      dependencies = (unsigned char **)realloc(dependencies,
                     dependency_cap * sizeof(unsigned char *));
      if (dependencies == NULL) { printf("Out of memory\n"); exit(1); }
   }
   dependencies[dependency_count] = (unsigned char *)malloc(strlen((char *)name) + 1);
   if (dependencies[dependency_count] == NULL) { printf("Out of memory\n"); exit(1); }
   strcpy((char *)dependencies[dependency_count], (char *)name);
   dependency_count++;
}

void write_dep_file(void)
{
   FILE *fp;
   int i;
   if (dep_on == FALSE) { return; }
   fp = fopen(dep_name, "w");
   if (fp == NULL) { die_file((char *)dep_name); }
   fprintf(fp, "%s: %s", object_name, source_name);
   for (i = 0; i < dependency_count; i++) { fprintf(fp, " %s", dependencies[i]); }
   fprintf(fp, "\n");
   fclose(fp);
}

static void make_decname(char decname[13], const char *name)
{
   char tmp[128], name8[9] = {0}, ext3[4] = {0};
   char *dot;
   int i, name_len, ext_len;
   strncpy(tmp, base_name(name), sizeof(tmp) - 1);
   tmp[sizeof(tmp) - 1] = '\0';
   for (i = 0; tmp[i]; i++) { tmp[i] = (char)toupper((unsigned char)tmp[i]); }
   dot = strchr(tmp, '.');
   if (dot != NULL) { *dot++ = '\0'; } else { dot = ""; }
   name_len = (int)strlen(tmp);
   ext_len = (int)strlen(dot);
   for (i = 0; i < 8; i++) { name8[i] = (i < name_len) ? tmp[i] : ' '; }
   for (i = 0; i < 3; i++) { ext3[i] = (i < ext_len) ? dot[i] : ' '; }
   memcpy(decname, name8, 8); decname[8] = '.'; memcpy(decname + 9, ext3, 3);
   decname[12] = '\0';
}

static void uu_decoder(FILE *out, const char decname[13])
{
   time_t now = time(NULL);
   struct tm *tmv = localtime(&now);
   fprintf(out, "100 '\n110 ' UUENCODE SELF-DECODER Ver1.20\n120 '\n");
   fprintf(out, "130   FNAME$=\"%s\"  ' Submitted %02d/%02d/%04d\n",
           decname, tmv->tm_mday, tmv->tm_mon + 1, tmv->tm_year + 1900);
   fprintf(out, "140 '\n150 PRINT \"UUENCODE SELF-DECODER\"\n160 A$=\"\"\n");
   fprintf(out, "170 ADR=&BFC7D:FOR I=1 TO 6:A$=A$+CHR$ (PEEK (ADR+I-1)):NEXT I\n");
   fprintf(out, "180 IF A$=\"E:    \" OR A$=\"F:    \" THEN 220\n190 INPUT \"DRIVE(E/F) =\";A$\n");
   fprintf(out, "200 IF RIGHT$ (A$,1)<>\":\" THEN A$=A$+\":\"\n210 A$=LEFT$ (A$+\"     \",6)\n220 A$=A$+FNAME$+CHR$ (0)\n");
   fprintf(out, "230 POKE &BFFB0,&3C,&2C,&0D,&00,&FE,&0B,&90,&24,&60,&0D,&1B,&06,&90,&24,&60,&FF\n");
   fprintf(out, "240 POKE &BFFC0,&18,&37,&6C,&04,&6C,&04,&6C,&04,&90,&24,&60,&27,&1B,&18,&6C,&04\n");
   fprintf(out, "250 POKE &BFFD0,&6C,&04,&90,&24,&60,&23,&18,&26,&60,&25,&1A,&1D,&09,&20,&90,&24\n");
   fprintf(out, "260 POKE &BFFE0,&48,&41,&EE,&30,&A0,&00,&90,&24,&48,&41,&30,&7B,&00,&30,&E8,&25\n");
   fprintf(out, "270 POKE &BFFF0,&00,&7C,&01,&1B,&17,&7C,&04,&13,&43,&7A,&00,&FE,&0B,&FF,&9F,&07\n");
   fprintf(out, "280 CALL &BFFB0\n");
   fprintf(out, "290 '%%DMKMKBPPALCMAECGPPBOADACAEPPIMKBPPALJACEGAGCBLBCJACEGAGFBLBIJACE\n");
   fprintf(out, "300 '%%BLBMJACEGAGJBLCCJACEGAGOBLCIJACEGACABLCOAMIBPPALAJAAAIAAAFOEPPAP\n");
   fprintf(out, "310 '%%DAIANGKIIAPPALBOADACAEPPAECGPPBOADACAEPPIMKBPPALJACEEICAHADPGAAA\n");
   fprintf(out, "320 '%%BIKODAMMAEAAPNBADAKAAFANKEPPALJACEEICAHADPOGOGDAKAAAJACEEICAHADP\n");
   fprintf(out, "330 '%%OODAKAABJACEEICAHADPOEOEDAKAACJACEEICAHADPDAKAADDAIAABHAADDAHPAA\n");
   fprintf(out, "340 '%%DAEDAELACFDAIAACHAAPDAHBABPADAHPABDAEDAELACFDAIAACHAMADAHPADDAED\n");
   fprintf(out, "350 '%%AELACFHMABBIAKHMABBIAGHMABBIACBDGCDAHBAEDPJACEEICABMAKHADPDAGDAE\n");
   fprintf(out, "360 '%%BIADACAEPPAIAALACFAMKEPPALDAMNAGAAAADAIFAFIIIAPPALDAKANGAJAEAFOE\n");
   fprintf(out, "370 '%%PPAPBOAKAMGPPPALAEFEPPACBHPPBDMEAMHFPPALAEFEPPIIIAPPALDAKANGAJAC\n");
   fprintf(out, "380 '%%AFOEPPAPJPAHIMKBPPALJACEGAANBLAGJACEGAPPBKAGKMKBPPALJHAGGMAEGMAE\n");
   fprintf(out, "390 '%%GMAEJACEGACHBIACBDCAGMAEGMAEKMKBPPALJPAGDAMMNGAACMANAAAAAAJACEGM\n");
   fprintf(out, "400 '%%AFGAAABLAIHMAFDMAJAEAFOEPPAPAGEFHCHCANAKAAFDHFGDGDGFHDHDANAKAAAA\n");
   fprintf(out, "410 '%%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n420 '#\n");
   fprintf(out, "430 ADR=&BFF81:FOR I=1 TO LEN (A$):POKE (ADR+I-1),ASC (MID$ (A$,I,1)):NEXT I\n");
   fprintf(out, "440 PRINT \"DATA_FILE='\";FNAME$;\"'\"\n450 B$=\"\":INPUT \"OK? (Y/N) =\";B$\n");
   fprintf(out, "460 IF B$=\"Y\" THEN 480 ELSE IF B$=\"N\" THEN END\n470 GOTO 440\n480 CALL &BFE00\n");
}

static unsigned char uu3(FILE *out, unsigned char a, unsigned char b, unsigned char c)
{
   fputc(ENC6(a >> 2), out);
   fputc(ENC6(((a << 4) & 0x30) | ((b >> 4) & 0x0f)), out);
   fputc(ENC6(((b << 2) & 0x3c) | ((c >> 6) & 0x03)), out);
   fputc(ENC6(c), out);
   return (unsigned char)((a + b + c) % 64u);
}

static void uu_emit_line(FILE *fp, unsigned *line, const unsigned char *buf, int n)
{
   unsigned char checksum = 0;
   fprintf(fp, "%u '%c", ++(*line), ENC6(n));
   for (int j = 0; j < n; j += 3) {
      unsigned char a = buf[j];
      unsigned char b = (j + 1 < n) ? buf[j + 1] : 0;
      unsigned char c = (j + 2 < n) ? buf[j + 2] : 0;
      checksum = (unsigned char)((checksum + uu3(fp, a, b, c)) % 64u);
   }
   fputc(ENC6(checksum), fp);
   fputc('\n', fp);
}

void write_basic_uu_file(void)
{
   FILE *fp, *in;
   char decname[13];
   unsigned line = 1000;
   int i = 0;
   unsigned char buf[UU_CHUNK];
   if (basic_uu_on == FALSE) { return; }
   if (object_on == TRUE) { fflush(fp_object); }
   fp = fopen(basic_uu_name, "w");
   if (fp == NULL) { die_file((char *)basic_uu_name); }
   make_decname(decname, (char *)object_name);
   uu_decoder(fp, decname);
   fprintf(fp, "%u 'begin 644 %s\n", ++line, base_name((char *)object_name));
   if (object_on == TRUE) {
      in = fopen(object_name, "rb");
      if (in == NULL) { fclose(fp); die_file((char *)object_name); }
      while (1) {
         int n = (int)fread(buf, 1, UU_CHUNK, in);
         if (n <= 0) { break; }
         uu_emit_line(fp, &line, buf, n);
      }
      fclose(in);
   } else {
      while (i < generated_count) {
         int n = generated_count - i;
         if (n > (int)UU_CHUNK) { n = UU_CHUNK; }
         for (int j = 0; j < n; j++) { buf[j] = generated_bytes[i + j].value; }
         uu_emit_line(fp, &line, buf, n);
         i += n;
      }
   }
   fprintf(fp, "%u '``\n", ++line);
   fprintf(fp, "%u 'end\n", ++line);
   fclose(fp);
}

static void hxd_emit_line(FILE *fp, unsigned long offset, const unsigned char *buf, int n)
{
   int i;
   fprintf(fp, "%08lX  ", offset);
   for (i = 0; i < 16; i++) {
      if (i < n) { fprintf(fp, "%02X ", buf[i]); }
      else       { fprintf(fp, "   "); }
   }
   fputc(' ', fp);
   for (i = 0; i < n; i++) {
      unsigned int cp = 0;
      if ((buf[i] >= 32) && (buf[i] <= 126)) {
         cp = buf[i];
      } else if (buf[i] >= 160) {
         cp = buf[i];
      } else {
         switch (buf[i]) {
            case 0x80: cp = 0x20AC; break;
            case 0x82: cp = 0x201A; break;
            case 0x83: cp = 0x0192; break;
            case 0x84: cp = 0x201E; break;
            case 0x85: cp = 0x2026; break;
            case 0x86: cp = 0x2020; break;
            case 0x87: cp = 0x2021; break;
            case 0x88: cp = 0x02C6; break;
            case 0x89: cp = 0x2030; break;
            case 0x8A: cp = 0x0160; break;
            case 0x8B: cp = 0x2039; break;
            case 0x8C: cp = 0x0152; break;
            case 0x8E: cp = 0x017D; break;
            case 0x91: cp = 0x2018; break;
            case 0x92: cp = 0x2019; break;
            case 0x93: cp = 0x201C; break;
            case 0x94: cp = 0x201D; break;
            case 0x95: cp = 0x2022; break;
            case 0x96: cp = 0x2013; break;
            case 0x97: cp = 0x2014; break;
            case 0x98: cp = 0x02DC; break;
            case 0x99: cp = 0x2122; break;
            case 0x9A: cp = 0x0161; break;
            case 0x9B: cp = 0x203A; break;
            case 0x9C: cp = 0x0153; break;
            case 0x9E: cp = 0x017E; break;
            case 0x9F: cp = 0x0178; break;
            default:   cp = '.';
         }
      }
      if (cp < 0x80) {
         fputc(cp, fp);
      } else if (cp < 0x800) {
         fputc(0xC0 | (cp >> 6), fp);
         fputc(0x80 | (cp & 0x3F), fp);
      } else {
         fputc(0xE0 | (cp >> 12), fp);
         fputc(0x80 | ((cp >> 6) & 0x3F), fp);
         fputc(0x80 | (cp & 0x3F), fp);
      }
   }
   fputc('\n', fp);
}

void write_hxd_file(void)
{
   FILE *fp, *in;
   unsigned long offset = 0;
   unsigned char buf[16];
   int i = 0;
   if (hxd_on == FALSE) { return; }
   if (object_on == TRUE) { fflush(fp_object); }
   fp = fopen(hxd_name, "w");
   if (fp == NULL) { die_file((char *)hxd_name); }
   fprintf(fp, "Offset(h) 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F\n\n");
   if (object_on == TRUE) {
      in = fopen(object_name, "rb");
      if (in == NULL) { fclose(fp); die_file((char *)object_name); }
      while (1) {
         int n = (int)fread(buf, 1, sizeof(buf), in);
         if (n <= 0) { break; }
         hxd_emit_line(fp, offset, buf, n);
         offset += (unsigned long)n;
      }
      fclose(in);
   } else {
      while (i < generated_count) {
         int n = generated_count - i;
         if (n > 16) { n = 16; }
         for (int j = 0; j < n; j++) { buf[j] = generated_bytes[i + j].value; }
         hxd_emit_line(fp, offset, buf, n);
         offset += (unsigned long)n;
         i += n;
      }
   }
   fclose(fp);
}

int emit_repeat_block(void)
{
   static macro_typ repeat_macro;
   int n, l_no = 0, total = 0;
   unsigned char linebuf[256];
   unsigned char *block[64];
   get_operand(&pp, inbuf);
   slim(inbuf);
   err = eval2(inbuf, &x);
   if ((err != 0) || (undef_flag == TRUE) || (x < 0)) { return (err != 0) ? err : 25; }
   while (1) {
      if (fgets((char *)linebuf, 255, current_file->fp_txt) == NULL) { return 18; }
      current_file->lines++; lines++;
      if (linebuf[strlen((char *)linebuf) - 1] == '\n') {
         linebuf[strlen((char *)linebuf) - 1] = '\0';
      }
      strcpy((char *)TEMP, (char *)linebuf);
      slim(TEMP);
      for (n = 0; TEMP[n] && !delimiter(TEMP[n]); n++) { TEMP[n] = c2upper(TEMP[n]); }
      if (strncmp((char *)TEMP, "ENDR", 4) == 0) { break; }
      if (l_no >= 64) { return 41; }
      block[l_no] = (unsigned char *)malloc(strlen((char *)linebuf) + 1);
      if (block[l_no] == NULL) { printf("Out of memory\n"); exit(1); }
      strcpy((char *)block[l_no++], (char *)linebuf);
   }
   for (n = 0; n < x; n++) {
      for (int j = 0; j < l_no; j++) {
         if (total >= 255) { return 41; }
         repeat_macro.define[total] = (unsigned char *)malloc(strlen((char *)block[j]) + 1);
         if (repeat_macro.define[total] == NULL) { printf("Out of memory\n"); exit(1); }
         strcpy((char *)repeat_macro.define[total], (char *)block[j]);
         total++;
      }
   }
   for (n = 0; n < l_no; n++) { free(block[n]); }
   repeat_macro.argc = 0;
   repeat_macro.lnum = (unsigned char)total;
   mcr = &repeat_macro;
   mline = 0;
   in_macro = TRUE;
   return 0;
}

int enter_numeric_if(int mode)
{
   bool active;
   dflag = TRUE;
   get_operand(&pp, inbuf);
   slim(inbuf);
   err = eval2(inbuf, &x);
   if (err != 0) { return err; }
   switch (mode) {
      case 0: active = (x == 0); break;
      case 1: active = (x != 0); break;
      case 2: active = (x > 0);  break;
      default: active = (x < 0); break;
   }
   ifdef_stat[ifdef_level++] = current_ifdef_stat;
   if ((current_ifdef_stat == 2) || (current_ifdef_stat == 11) ||
       (current_ifdef_stat == -1)) {
      current_ifdef_stat = -1;
   } else {
      current_ifdef_stat = active ? 1 : 2;
   }
   return 0;
}

int close_struct(void)
{
   unsigned char size_label[64];
   struct_on = FALSE;
   snprintf((char *)size_label, sizeof(size_label), "%s_SIZE", struct_name);
   if (strlen((char *)size_label) > 16) { return 10; }
   if (pass_sw == 1) {
      err = find_label(size_label, &x, (label_typ ***)&next_pnt);
      if (err == 11) { make_label(size_label, struct_size); return 0; }
      return (err == 0) ? 13 : err;
   }
   err = find_label(size_label, &x, (label_typ ***)&equ_pnt);
   if (err == 0) { equ_pnt2->value = struct_size; }
   return err;
}
