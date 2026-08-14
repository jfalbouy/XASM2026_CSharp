; Constantes
bp_ram:	equ	0ECh		; base pointer RAM interne
DB_BEB6F:	equ	0BEB6Fh		; donnees hors du code charge
swork:	equ	0BFCE1h		; pointeur de zone de travail : pile systeme S ; taille de la zone U = [0BFCE1h] - [0BFCDEh]
usrwrk:	equ	0BFD1Ah		; machine language area ; fin de la zone de travail IOCS et debut de la zone langage machine de l'utilisateur (manuel technique, IOCS Special Technique p85-86)
fcs_call:	equ	0FFFE4h		; FCS call entry
iocs_call:	equ	0FFFE8h		; IOCS call entry
	org	0BD800h

start:
	pre	032h
	mv	a,(bp_ram)
	pushu	a
	pre	032h
	mv	(bp_ram),050h
	mv	(000h),s
	mv	(003h),u
	mv	il,01Fh
	mvl	(009h),[DB_BE80F]
	mv	x,[usrwrk]
	mv	a,020h
	add	x,a
	mv	(006h),x
	mv	x,[swork]
	mv	a,064h
	add	x,a
	mv	(054h),x
	and	(09Ah),0F7h
	mv	a,001h
	call	SUB_BD9F0
	mvw	(04Bh),00000h
	mv	x,[u+001h]
LOC_BD836:
	mv	y,0BF000h
	mv	(043h),x
	callf	SUB_BE626
	jrc	LOC_BD86F
	cmp	(046h),001h
	jrnz	LOC_BD874
	mv	a,[y+006h]
	cmp	a,02Dh
	jrnz	LOC_BD874
	mv	ba,[y+007h]
	or	a,020h
	cmp	a,072h
	jrnz	LOC_BD861
	mv	a,b
	call	SUB_BDA49
	jrc	LOC_BD86F
	mv	(04Bh),a
	jr	LOC_BD836
LOC_BD861:
	cmp	a,06Dh
	jrnz	LOC_BD86F
	mv	a,b
	call	SUB_BDA49
	jrc	LOC_BD86F
	mv	(04Ch),a
	jr	LOC_BD836
LOC_BD86F:
	mv	a,002h
	jp	LOC_BD967
LOC_BD874:
	mv	ba,02058h
	mv	[y+00Fh],ba
	mv	ba,00020h
	mv	[y+011h],ba
	mv	y,0BF020h
	callf	SUB_BE626
	jrc	LOC_BD896
	mv	x,0BF000h
LOC_BD88E:
	mv	a,[y++]
	mv	[x++],a
	cmp	a,000h
	jrnz	LOC_BD88E
LOC_BD896:
	mv	x,(009h)
	mv	a,(04Bh)
	add	a,001h
	mv	b,a
	mv	a,000h
	sub	x,ba
	mv	(031h),x
	mv	(028h),x
	mv	a,(04Ch)
	add	a,001h
	rol	a
	rol	a
	mv	b,a
	mv	a,000h
	sub	x,ba
	cmpp	(006h),x
	mv	a,00Ch
	jrnc	LOC_BD990
	mv	a,000h
	mv	[x],a
	mv	(02Eh),x
	mv	[(018h)],x
	mv	[--x],a
	mv	(02Bh),x
	mv	(042h),004h
	call	SUB_BDDC2
	mv	x,[DB_BE859]			; ref 0BE859h via x
	sub	y,x
	mv	a,019h
	jrz	LOC_BD990
	pushu	y
	mv	x,(031h)
	mv	y,(028h)
	sub	y,x
	jrz	LOC_BD8E4
	mv	a,0FFh
	call	SUB_BDD65
	inc	y
LOC_BD8E4:
	popu	x
	mv	(028h),y
	add	y,x
	mv	[DB_BE856],y			; ref 0BE856h via y
	cmpp	(01Bh),(018h)
	mv	a,010h
	jrnz	LOC_BD990
	mv	x,(018h)
	mv	y,(02Eh)
	mv	[x++],y
	inc	y
	mv	il,00Fh
LOC_BD8FE:
	mv	[x++],y
	dec	il
	jrnz	LOC_BD8FE
	mv	a,000h
	mv	[(02Eh)],a
	mv	(042h),006h
	mv	x,0BF000h
	mv	il,000h
	mv	a,000h
	call	SUB_BDA25
	mv	(020h),(086h)
	test	(024h),001h
	jrnz	LOC_BD92A
	mv	x,DB_BE851			; ref 0BE851h via x
	mv	y,000010h
	call	SUB_BDA20
LOC_BD92A:
	call	SUB_BDDC2
	call	SUB_BD9E2
	mv	y,(028h)
	dec	y
	inc	y
	jrz	LOC_BD93D
	mv	x,(031h)
	call	SUB_BDA20
LOC_BD93D:
	call	SUB_BDA11
	call	SUB_BDA83
	mv	x,[DB_BE859]			; ref 0BE859h via x
	pushu	x
	mv	y,[DB_BE856]			; ref 0BE856h via y
	add	x,y
	dec	x
	pushu	x
	mvp	[--u],(028h)
	mv	x,DB_BE908			; ref 0BE908h via x
	call	SUB_BDA5F
	dec	x
	call	SUB_BDA5F
	dec	x
	call	SUB_BDA5F
	mv	a,00Ah
LOC_BD967:
	call	SUB_BD9F0
	mv	u,(003h)
	mv	s,(000h)
	or	(09Ah),008h
	popu	a
	pre	032h
	mv	(bp_ram),a
	popu	x
LOC_BD976:
	mv	a,[x++]
	cmp	a,00Dh
	jrnz	LOC_BD976
	dec	x
	pushu	x
	rc
	retf
LOC_BD981:
	pushu	a
	mv	x,DB_BE8C5			; ref 0BE8C5h via x
	call	SUB_BDA65
	mv	a,004h
	call	SUB_BD9F0
	jr	LOC_BD9AD
LOC_BD990:
	call	SUB_BD9F0
	mv	a,(021h)
	or	a,(022h)
	or	a,(023h)
	jrz	LOC_BD9AD
	mv	x,DB_BE8BC			; ref 0BE8BCh via x
	ex	(021h),(023h)
	mvp	[--u],(021h)
	call	SUB_BDA5F
	mv	a,003h
	call	SUB_BD9F0
LOC_BD9AD:
	call	SUB_BDA11
	call	SUB_BDA16
	cmp	(020h),0FFh
	jrz	LOC_BD9C1
	mv	x,0BF000h
	mv	il,00Eh
	call	SUB_BDA0C
LOC_BD9C1:
	mv	a,005h
	jr	LOC_BD967
SUB_BD9C5:
	inc	y
	test	(042h),002h
	jrz	LOC_BD9E1
	mv	(01Eh),a
	pushu	x
	mv	x,(012h)
	mv	[x++],a
	mv	(012h),x
	cmpp	(00Fh),x
	jrnz	LOC_BD9E0
	call	SUB_BD9E2
	mvp	(012h),(00Ch)
LOC_BD9E0:
	popu	x
LOC_BD9E1:
	ret
SUB_BD9E2:
	pushu	y
	mv	x,(00Ch)
	mv	y,(012h)
	sub	y,x
	jrz	LOC_BD9EE
	call	SUB_BDA20
LOC_BD9EE:
	popu	y
	ret
SUB_BD9F0:
	mv	y,DB_BE861			; ref 0BE861h via y
	mv	i,ba
	mv	ba,00109h
LOC_BD9F9:
	mv	x,y
LOC_BD9FB:
	mv	a,[y++]
	ror	a
	jrnz	LOC_BD9FB
	dec	il
	jrnz	LOC_BD9F9
	mv	(086h),a
	sub	y,x
	dec	y
	mv	il,004h
SUB_BDA0C:
	callf	fcs_call
	ret
SUB_BDA11:
	mv	(086h),(020h)
	jr	LOC_BDA1C
SUB_BDA16:
	mv	(086h),(01Fh)
	mv	(01Fh),0FFh
LOC_BDA1C:
	mv	il,002h
	jr	SUB_BDA0C
SUB_BDA20:
	mv	il,004h
	mv	(086h),(020h)
SUB_BDA25:
	callf	fcs_call
	jrc	LOC_BD981
	ret
SUB_BDA2C:
	pushu	x
	pushu	y
	mv	a,007h
	test	(042h),002h
	jrz	LOC_BDA37
	mv	a,008h
LOC_BDA37:
	call	SUB_BD9F0
	mv	y,(015h)
	call	0BD9F7h
	mv	a,009h
	call	SUB_BD9F0
	popu	y
	popu	x
	ret
SUB_BDA47:
	mv	a,[x++]
SUB_BDA49:
	sub	a,030h
	cmp	a,00Ah
	jrc	LOC_BDA5D
	sub	a,011h
	cmp	a,040h
	jrnc	LOC_BDA78
	and	a,01Fh
	cmp	a,006h
	jrnc	LOC_BDA78
	add	a,00Ah
LOC_BDA5D:
	rc
	ret
SUB_BDA5F:
	call	SUB_BDA65
	call	SUB_BDA65
SUB_BDA65:
	popu	a
	pushu	a
	call	SUB_BDA6C
	popu	a
	swap	a
SUB_BDA6C:
	and	a,00Fh
	cmp	a,00Ah
	jrc	LOC_BDA74
	add	a,007h
LOC_BDA74:
	add	a,030h
	mv	[--x],a
LOC_BDA78:
	sc
	ret
SUB_BDA7A:
	mv	a,[x++]
	mv	[y++],a
	dec	il
	jrnz	SUB_BDA7A
	ret
SUB_BDA83:
	mv	il,000h
	mv	x,DB_BE84A			; ref 0BE84Ah via x
	callf	iocs_call
	jrc	LOC_BDAAC
	mv	a,000h
	mv	il,046h
	mv	y,0BF040h
	mv	a,020h
	mv	[y],a
	callf	iocs_call
	jrc	LOC_BDAAC
	mv	x,0BF000h
	mv	a,001h
	mv	il,00Bh
	call	SUB_BDA0C
LOC_BDAAC:
	ret
SUB_BDAAD:
	add	a,002h
SUB_BDAAF:
	mv	(037h),a
	mv	(057h),00Ah
	call	SUB_BDAC1
	mv	a,[x++]
	cmp	(037h),a
	jrnz	LOC_BDB2C
	and	(042h),0FBh
	ret
SUB_BDAC1:
	cmpp	(054h),s
	mv	a,013h
	jrnc	LOC_BDB2E
	cmp	(057h),000h
	jrnz	LOC_BDAD2
	call	SUB_BDB31
	jr	LOC_BDAF6
LOC_BDAD2:
	dec	(057h)
	call	SUB_BDAC1
	inc	(057h)
	call	SUB_BDAF7
	jrnc	LOC_BDAF6
	mv	ba,0DAD9h
	pushs	ba
	pushs	i
	mvp	[--u],(04Bh)
	dec	(057h)
	call	SUB_BDAC1
	inc	(057h)
	mvp	(04Eh),(04Bh)
	mvp	(04Bh),[u++]
	ret
LOC_BDAF6:
	ret
SUB_BDAF7:
	pushu	y
	mv	y,DB_BE6D9			; ref 0BE6D9h via y
	mv	a,(057h)
	add	y,a
	mv	a,[y]
	add	y,a
	mvw	(051h),[x]
LOC_BDB07:
	mv	ba,[y++]
	mv	i,[y++]
	cmp	a,000h
	jrz	LOC_BDB2A
	cmp	(051h),a
	jrnz	LOC_BDB07
	mv	a,b
	cmp	a,020h
	jrz	LOC_BDB27
	jrnc	LOC_BDB21
	cmp	(051h),(052h)
	jrz	LOC_BDB07
	jr	LOC_BDB27
LOC_BDB21:
	cmp	(052h),a
	jrnz	LOC_BDB07
	inc	x
LOC_BDB27:
	inc	x
	sc
LOC_BDB2A:
	popu	y
	ret
LOC_BDB2C:
	mv	a,00Bh
LOC_BDB2E:
	jp	LOC_BD990
SUB_BDB31:
	cmpp	(054h),s
	mv	a,013h
	jrnc	LOC_BDB2E
	mvp	(04Bh),(025h)
LOC_BDB3B:
	mv	a,[x]
	cmp	a,07Eh
	jrz	LOC_BDBB4
	sub	a,030h
	jrc	LOC_BDB6A
	jrz	LOC_BDBC8
	sub	a,00Ah
	jrnc	LOC_BDB8F
LOC_BDB4B:
	call	SUB_BDA47
	jrc	LOC_BDBD8
	cmp	a,00Ah
	jrnc	LOC_BDBD8
	pushu	x
	pushu	y
	mv	x,(04Bh)
	add	x,x
	mv	y,x
	add	x,x
	add	x,x
	add	x,y
	add	x,a
	mv	(04Bh),x
	popu	y
	popu	x
	jr	LOC_BDB4B
LOC_BDB6A:
	inc	x
	cmp	a,0F1h
	jrz	LOC_BDBC2
	cmp	a,0F8h
	jrz	LOC_BDBA3
	cmp	a,0FDh
	jrz	LOC_BDBBC
	cmp	a,0FBh
	jrz	LOC_BDB3B
	cmp	a,0F7h
	jrz	LOC_BDB94
	mv	(04Bh),y
	cmp	a,0FAh
	jrz	LOC_BDBDA
	mvp	(04Bh),(047h)
	cmp	a,0F5h
	jrz	LOC_BDBDA
	dec	x
LOC_BDB8F:
	call	SUB_BDBDB
	jr	LOC_BDBDA
LOC_BDB94:
	call	SUB_BE4CF
	jrc	LOC_BDB2C
	mv	(04Bh),ba
	mv	a,[x++]
	cmp	a,027h
	jrnz	LOC_BDB2C
	jr	LOC_BDBDA
LOC_BDBA3:
	mv	(057h),00Ah
	call	SUB_BDAC1
	mv	a,[x++]
	cmp	a,029h
	jrnz	LOC_BDB2C
	mv	(057h),000h
	jr	LOC_BDBDA
LOC_BDBB4:
	inc	x
	call	SUB_BDB31
	jp	LOC_BE5AA
LOC_BDBBC:
	call	SUB_BDB31
	jp	LOC_BE5CD
LOC_BDBC2:
	call	SUB_BDB31
	jp	LOC_BE5D9
LOC_BDBC8:
	call	SUB_BDA47
	jrc	LOC_BDBD5
	mv	il,003h
	dsll	(04Dh)
	or	(04Dh),a
	jr	LOC_BDBC8
LOC_BDBD5:
	ex	(04Bh),(04Dh)
LOC_BDBD8:
	dec	x
LOC_BDBDA:
	ret
SUB_BDBDB:
	mv	a,[x]
	test	(042h),006h
	jrz	LOC_BDC6F
	cmp	a,05Ch
	jrz	LOC_BDC08
	cmp	a,03Ah
	jrz	LOC_BDC15
	call	SUB_BDCC2
	jrz	LOC_BDB2C
	pushu	y
	pushu	x
	mv	x,(018h)
LOC_BDBF3:
	call	SUB_BDCE1
	jrc	LOC_BDC40
	cmpp	(01Bh),x
	jrz	LOC_BDC01
	mv	y,[--x]
	jr	LOC_BDBF3
LOC_BDC01:
	mv	a,014h
	mv	i,01D08h
	jr	LOC_BDB2E
LOC_BDC08:
	inc	x
	call	SUB_BDCC2
LOC_BDC0D:
	jrz	LOC_BDB2C
	pushu	y
	pushu	x
	mv	x,(01Bh)
	jr	LOC_BDC3B
LOC_BDC15:
	mv	(04Bh),000h
LOC_BDC18:
	mv	a,[x++]
	add	(04Bh),003h
	jrc	0BDC04h
	cmp	a,03Ah
	jrz	LOC_BDC18
	dec	x
	call	SUB_BDCC2
	jrz	LOC_BDC0D
	pushu	y
	pushu	x
	mv	x,(018h)
	mv	a,(04Bh)
	sub	a,006h
	sub	x,a
	cmpp	(01Bh),x
	jrz	LOC_BDC3B
	jrnc	0BDC04h
LOC_BDC3B:
	call	SUB_BDCE1
	jrnc	LOC_BDC01
LOC_BDC40:
	popu	x
	mvp	(04Bh),[--y]
	mv	a,[x]
	cmp	a,05Ch
	jrnz	LOC_BDC6D
	inc	x
	call	SUB_BDCC2
	jrz	LOC_BDC0D
	pushu	x
	mv	a,[--y]
	cmp	a,001h
	jrnz	0BDC04h
	mv	x,[y-006h]
	cmpp	(04Bh),x
	jrnz	0BDC04h
	mv	x,DB_BEB6F
	mv	[x],y
	call	SUB_BDCE1
	jrc	LOC_BDC40
	jr	LOC_BDC01
LOC_BDC6D:
	popu	y
	ret
LOC_BDC6F:
	cmp	a,05Ch
	jrz	0BDC80h
	cmp	a,03Ah
	jrnz	LOC_BDC82
LOC_BDC77:
	mv	a,[x++]
	cmp	a,03Ah
	jrz	LOC_BDC77
	dec	x
	mv	i,0046Ch
LOC_BDC82:
	call	SUB_BDCC2
	jrz	LOC_BDC0D
	mv	a,[x]
	cmp	a,05Ch
	jrz	0BDC80h
	ret
SUB_BDC8E:
	cmp	a,07Bh
	jrnc	LOC_BDCB8
	cmp	a,061h
	jrnc	LOC_BDCC1
	cmp	a,05Fh
	jrz	LOC_BDCC1
	cmp	a,05Bh
	jrnc	LOC_BDCB6
	cmp	a,03Fh
	jrnc	LOC_BDCC1
	cmp	a,03Ah
	jrnc	LOC_BDCB6
	cmp	a,030h
	jrnc	LOC_BDCC1
	cmp	a,02Eh
	jrz	LOC_BDCC1
	cmp	a,024h
	jrz	LOC_BDCC1
	cmp	a,023h
	jrz	LOC_BDCC1
LOC_BDCB6:
	sc
	ret
LOC_BDCB8:
	cmp	a,080h
	jrc	LOC_BDCC1
	cmp	a,0FDh
	jrnc	LOC_BDCB6
	rc
LOC_BDCC1:
	ret
SUB_BDCC2:
	mv	(03Ah),002h
	mv	(03Bh),x
	pushu	y
LOC_BDCC8:
	inc	(03Ah)
	jrz	LOC_BDDB2
	mv	a,[x++]
	call	SUB_BDC8E
	jrnc	LOC_BDCC8
	popu	y
	dec	x
	sub	(03Ah),003h
	ret
SUB_BDCDA:
	mvp	(03Bh),DB_BE834
	mv	x,(018h)
SUB_BDCE1:
	pushu	x
	mv	y,[x]
	mv	(039h),001h
LOC_BDCE7:
	mv	a,[--y]
	sub	a,003h
	jrnc	LOC_BDCFD
	cmp	a,0FEh
	jrc	LOC_BDD2D
	jrz	LOC_BDCF9
	dec	(039h)
	jrz	LOC_BDD2D
	jr	LOC_BDCE7
LOC_BDCF9:
	inc	(039h)
	jr	LOC_BDCE7
LOC_BDCFD:
	cmp	(03Ah),a
	jrnz	LOC_BDD27
	pushu	a
	mv	a,[y-001h]
	cmp	a,040h
	popu	a
	jrz	LOC_BDD0F
	cmp	(039h),001h
	jrnz	LOC_BDD27
LOC_BDD0F:
	mv	x,(03Bh)
	mv	il,(03Ah)
LOC_BDD13:
	mv	(038h),[--y]
	mv	a,[x++]
	cmp	(038h),a
	jrnz	LOC_BDD23
	dec	il
	jrnz	LOC_BDD13
	sc
	popu	x
	ret
LOC_BDD23:
	mv	ba,i
	dec	a
LOC_BDD27:
	add	a,003h
	sub	y,a
	jr	LOC_BDCE7
LOC_BDD2D:
	rc
	popu	x
	ret
SUB_BDD30:
	mv	x,(018h)
	mv	a,[(03Bh)]
	cmp	a,040h
	jrnz	LOC_BDD3B
	mv	x,(01Bh)
LOC_BDD3B:
	call	SUB_BDCE1
	mv	a,015h
	jrc	LOC_BDDBF
	mv	x,(03Bh)
	mv	il,(03Ah)
	mv	a,003h
	add	a,il
	mv	[y],a
LOC_BDD4C:
	mv	a,[x++]
	mv	[--y],a
	cmpp	(006h),y
	mv	a,00Ch
	jrnc	LOC_BDDBF
	dec	il
	jrnz	LOC_BDD4C
	mvp	[--y],(04Bh)
	mv	a,000h
	mv	[--y],a
	mv	(02Bh),y
	ret
SUB_BDD65:
	mv	x,(028h)
	cmpp	(009h),x
	jrz	LOC_BDDBD
	mv	[x++],a
	mv	(028h),x
	ret
LOC_BDD71:
	test	(042h),002h
	jrnz	LOC_BDDAF
	mv	a,[x]
	mv	il,000h
	cmp	a,05Bh
	jrz	LOC_BDD86
	mv	il,080h
	cmp	a,028h
	mv	a,00Bh
	jrnz	LOC_BDDBF
LOC_BDD86:
	mv	ba,i
	pushu	x
	pushu	y
	mv	x,(034h)
	sub	y,x
	mv	(04Eh),y
	mv	x,00007Eh
	sub	y,x
	jrnc	LOC_BDD9C
	or	a,(04Eh)
	jr	LOC_BDDA8
LOC_BDD9C:
	or	a,07Eh
	call	SUB_BDD65
	mv	a,(04Eh)
	call	SUB_BDD65
	mv	a,(04Fh)
LOC_BDDA8:
	call	SUB_BDD65
	popu	y
	popu	x
	mv	(034h),y
LOC_BDDAF:
	jp	LOC_BDEC0
LOC_BDDB2:
	mv	a,016h
	jr	LOC_BDDBF
LOC_BDDB6:
	sub	(015h),020h
	mv	a,01Ch
	jr	LOC_BDDBF
LOC_BDDBD:
	mv	a,00Dh
LOC_BDDBF:
	jp	LOC_BD990
SUB_BDDC2:
	mv	a,006h
	call	SUB_BD9F0
	mv	x,(043h)
SUB_BDDC9:
	pushu	y
	mv	y,(015h)
	callf	SUB_BE626
	jrc	LOC_BDDB6
	mv	[y+016h],(058h)
	mv	(058h),000h
	mv	[y+01Ah],x
	mvp	[y+017h],(006h)
	mvp	[y+01Dh],(021h)
	mvp	(021h),(025h)
	call	SUB_BDA2C
	mv	x,(015h)
	mv	il,00Bh
	mv	a,000h
	mv	y,0BF040h
	call	SUB_BDA25
	mv	x,[y+005h]
	mv	y,(006h)
	pushu	y
	pushu	x
	pushu	y
	add	y,x
	mv	a,020h
	add	y,a
	mv	a,00Ch
	cmpp	(02Bh),y
	jrc	LOC_BDDBF
	mv	(006h),y
	mv	x,(015h)
	mv	il,001h
	mv	a,001h
	call	SUB_BDA25
	mv	(01Fh),(086h)
	popu	x
	popu	y
	mv	il,003h
	mv	a,000h
	call	SUB_BDA25
	mv	a,01Ah
	mv	[x++],a
	call	SUB_BDA16
	popu	x
	popu	y
	inc	(023h)
	test	(042h),004h
	jrz	SUB_BDE84
	mv	a,[x++]
	cmp	a,05Ch
	mv	a,00Eh
	jrnz	LOC_BDF27
	mv	ba,[x]
	mv	i,0686Eh
	sub	ba,i
	jrnz	LOC_BDE51
	mv	ba,[x++]
	mv	a,[x++]
	cmp	a,05Ch
	mv	a,00Eh
	jrnz	LOC_BDF27
	or	(024h),001h
LOC_BDE51:
	mv	y,(025h)
	mv	(047h),y
	mv	(057h),00Ah
	call	SUB_BDAC1
	mv	y,(04Bh)
	mv	(034h),y
	mv	(047h),y
	mv	[DB_BE859],y			; ref 0BE859h via y
	and	(042h),0FBh
LOC_BDE68:
	mv	a,[x++]
	cmp	a,020h
	jrnc	LOC_BDE68
LOC_BDE6E:
	cmp	a,00Ah
	jrz	LOC_BDE7E
	cmp	a,00Dh
	jrnz	LOC_BDF05
	mv	a,[x++]
	cmp	a,00Ah
	jrz	LOC_BDE7E
	dec	x
LOC_BDE7E:
	mv	a,001h
	mv	il,003h
	dadl	(023h),a
SUB_BDE84:
	mv	a,[x]
	cmp	a,02Bh
	jpz	LOC_BE29C
	cmp	a,030h
	jrc	LOC_BDE93
	cmp	a,03Ch
	jrc	LOC_BDEC0
LOC_BDE93:
	call	SUB_BDCC2
	jrz	LOC_BDEC0
	mv	(04Bh),y
	mv	a,[x]
	cmp	a,028h
	jrnz	LOC_BDEB4
	mv	a,029h
	mv	il,004h
	mvl	(03Eh),(03Ah)
	inc	x
	or	(042h),004h
	call	SUB_BDAAF
	mv	il,004h
	mvl	(03Ah),(03Eh)
LOC_BDEB4:
	test	(042h),002h
	jrnz	LOC_BDEC0
	pushu	x
	pushu	y
	call	SUB_BDD30
	popu	y
	popu	x
LOC_BDEC0:
	test	(0AFh),008h
	mv	a,01Eh
	jrnz	LOC_BDF27
	mv	a,[x++]
	cmp	a,020h
	jrz	LOC_BDEC0
	jrc	LOC_BDE6E
	cmp	a,05Ch
	jpz	LOC_BDFA7
	cmp	a,027h
	jrz	LOC_BDF59
	cmp	a,028h
	jrz	LOC_BDF2A
	cmp	a,05Bh
	jrz	LOC_BDF40
	cmp	a,07Bh
	jrz	LOC_BDF4F
	cmp	a,03Ch
	jrz	LOC_BDF73
	cmp	a,02Ah
	jpz	LOC_BDD71
	cmp	a,03Bh
	jrz	LOC_BDE68
	call	SUB_BDA49
	jrc	0BDF25h
	swap	a
	mv	(04Bh),a
	call	SUB_BDA47
	jrc	0BDF25h
	or	a,(04Bh)
	call	SUB_BD9C5
	jr	LOC_BDEC0
LOC_BDF05:
	cmp	a,01Ah
	jrnz	0BDF25h
	cmp	(058h),000h
	jrnz	LOC_BDF22
	pushu	y
	mv	y,(015h)
	mv	x,[y+01Ah]
	mvp	(006h),[y+017h]
	mvp	(021h),[y+01Dh]
	mv	(058h),[y+016h]
	popu	y
	ret
LOC_BDF22:
	mv	a,025h
	mv	i,00B08h
LOC_BDF27:
	jp	LOC_BD990
LOC_BDF2A:
	mv	a,029h
	call	SUB_BDAAF
LOC_BDF2F:
	mv	a,(04Bh)
	call	SUB_BD9C5
	mv	a,(04Ch)
	call	SUB_BD9C5
	mv	a,(04Dh)
	call	SUB_BD9C5
	jr	LOC_BDEC0
LOC_BDF40:
	call	SUB_BDAAD
	mv	a,(04Bh)
	call	SUB_BD9C5
	mv	a,(04Ch)
	call	SUB_BD9C5
	jr	LOC_BDEC0
LOC_BDF4F:
	call	SUB_BDAAD
LOC_BDF52:
	mv	a,(04Bh)
	call	SUB_BD9C5
	jr	LOC_BDEC0
LOC_BDF59:
	call	SUB_BE4CF
	jrc	LOC_BDF6D
	pushu	ba
	call	SUB_BD9C5
	popu	ba
	mv	a,b
	cmp	a,000h
	jrz	LOC_BDF59
	call	SUB_BD9C5
	jr	LOC_BDF59
LOC_BDF6D:
	jrz	LOC_BDEC0
	mv	a,00Bh
	jr	LOC_BDF27
LOC_BDF73:
	call	SUB_BDAAD
	test	(042h),002h
	jrz	LOC_BDF52
	mv	a,01Ah
	pushu	x
	pushu	y
	mv	x,(04Bh)
	sub	y,x
	inc	y
	test	(01Eh),001h
	jrc	LOC_BDF90
	jrz	LOC_BDF27
	mv	(04Bh),y
	jr	LOC_BDF9A
LOC_BDF90:
	jrnz	LOC_BDF27
	mv	x,000000h
	sub	x,y
	mv	(04Bh),x
LOC_BDF9A:
	mv	a,01Bh
	mv	il,000h
	cmpw	(04Ch),i
	jrnz	LOC_BDF27
	popu	y
	popu	x
	jr	LOC_BDF52
LOC_BDFA7:
	mv	(04Bh),y
	mv	(03Ah),002h
	mv	a,[x++]
	pushu	x
	pushu	y
	cmp	a,07Bh
	jrz	LOC_BDFDE
	cmp	a,07Dh
	jrnz	LOC_BE036
	test	(042h),002h
	jrnz	LOC_BDFD6
	cmpp	(01Bh),(018h)
	mv	a,011h
	jrz	LOC_BDF27
	mvp	(03Bh),DB_BE82E
	call	SUB_BDD30
	mv	a,002h
	mv	[y],a
	mv	a,000h
	mv	[--y],a
	mv	(02Bh),y
LOC_BDFD6:
	mv	x,(018h)
	mv	y,[--x]
	mv	(018h),x
	jr	LOC_BE031
LOC_BDFDE:
	test	(042h),002h
	jrnz	LOC_BE00C
	mv	y,0BF22Dh
	cmpp	(018h),y
	mv	a,012h
	jrz	LOC_BDF27
	call	SUB_BDCDA
	mv	a,001h
	mv	[y],a
	mv	x,(018h)
	mv	[x+003h],y
	mv	a,000h
	mv	[--y],a
	mv	y,[x++]
	mv	(018h),x
	mvp	(03Bh),DB_BE831
	call	SUB_BDD30
	jr	LOC_BE031
LOC_BE00C:
	mv	x,(018h)
	mv	y,[x++]
	pushu	y
	mv	y,[x]
	mv	(018h),x
	popu	x
	sub	x,y
	jrc	LOC_BE01F
	call	SUB_BDCDA
	jr	LOC_BE023
LOC_BE01F:
	mv	x,(018h)
	mv	y,[--x]
LOC_BE023:
	mv	a,[--y]
	cmp	a,003h
	jrc	LOC_BE02D
	sub	y,a
	jr	LOC_BE023
LOC_BE02D:
	mv	x,(018h)
	mv	[x],y
LOC_BE031:
	popu	y
	popu	x
	jp	LOC_BDEC0
LOC_BE036:
	popu	y
	popu	x
	dec	x
	call	SUB_BDCC2
	jrz	0BE133h
	pushu	y
	pushu	x
	mv	y,DB_BE736			; ref 0BE736h via y
	call	SUB_BE498
	jrc	LOC_BE113
	mv	y,(02Eh)
	call	SUB_BE498
	jrnc	0BE12Ah
	mv	ba,[y++]
	mv	(04Bh),y
	popu	x
	mv	y,0BF100h
	mv	il,010h
	mv	a,[x++]
	cmp	a,028h
	jrnz	0BE133h
LOC_BE062:
	mv	[y++],x
LOC_BE064:
	call	SUB_BE4C2
	jrnc	LOC_BE064
	jrnz	0BE133h
	cmp	a,029h
	jrz	LOC_BE075
	dec	il
	jrnz	LOC_BE062
	jr	0BE12Dh
LOC_BE075:
	dec	x
	dec	il
	jrnz	LOC_BE062
	inc	x
	add	(015h),020h
	mv	a,00Fh
	jrz	LOC_BE135
	mv	y,(015h)
	mv	[y+016h],(058h)
	mv	(058h),000h
	mv	[y+01Ah],x
	mvp	[y+017h],(006h)
	mvp	[y+01Dh],(021h)
	mvp	(021h),(025h)
	mv	y,(015h)
	mv	x,DB_BE837			; ref 0BE837h via x
	mv	il,013h
	call	SUB_BDA7A
	mv	a,00Dh
	sub	y,a
	mv	x,(03Bh)
	mv	il,00Ch
	cmp	(03Ah),00Ch
	jrnc	LOC_BE0B5
	mv	il,(03Ah)
LOC_BE0B5:
	call	SUB_BDA7A
	call	SUB_BDA2C
	mv	y,(006h)
	mv	x,(04Bh)
LOC_BE0BF:
	mv	a,[x++]
	cmp	a,025h
	jrnz	LOC_BE0EC
	call	SUB_BDA47
	jrc	LOC_BE0E9
	pushu	x
	pushu	y
	mv	y,0BF100h
	add	y,a
	rol	a
	add	y,a
	mv	x,[y]
	popu	y
LOC_BE0D8:
	call	SUB_BE4C2
	jrc	LOC_BE0E6
	mv	[y++],a
	cmpp	(02Bh),y
	jrc	0BE127h
	jr	LOC_BE0D8
LOC_BE0E6:
	popu	x
	jr	LOC_BE0BF
LOC_BE0E9:
	mv	a,[x-001h]
LOC_BE0EC:
	mv	[y++],a
	cmpp	(02Bh),y
	jrc	0BE127h
	cmp	a,01Ah
	jrnz	LOC_BE0BF
	mv	a,020h
	add	y,a
	cmpp	(02Bh),y
	jrc	0BE127h
	mv	x,(006h)
	mv	(006h),y
	popu	y
	inc	(023h)
	call	SUB_BDE84
	sub	(015h),020h
	call	SUB_BDA2C
	jp	LOC_BDEC0
LOC_BE113:
	mv	a,[y+002h]
	mv	(04Ah),a
	popu	x
	popu	y
	cmp	a,004h
	jrc	LOC_BE150
	jrz	LOC_BE138
	cmp	a,005h
	jrz	LOC_BE1C7
	mv	a,01Fh
	mv	i,00C08h
	mv	i,01408h
	mv	i,02308h
	mv	i,02008h
	mv	i,00B08h
LOC_BE135:
	jp	LOC_BD990
LOC_BE138:
	mv	a,[x++]
	cmp	a,028h
	jrnz	0BE133h
	mv	a,029h
	call	SUB_BDAAF
	test	(042h),002h
	jrz	LOC_BE14D
	cmpp	(04Bh),(025h)
	jrz	0BE130h
LOC_BE14D:
	jp	LOC_BDEC0
LOC_BE150:
	mv	a,[x++]
	cmp	a,020h
	jrnz	0BE133h
LOC_BE156:
	mv	a,[x]
	cmp	a,030h
	jrc	LOC_BE160
	cmp	a,03Ch
	jrc	0BE133h
LOC_BE160:
	call	SUB_BDCC2
	jrz	0BE133h
	mv	a,[x]
	cmp	a,028h
	jrnz	LOC_BE182
	mv	a,029h
	mv	il,004h
	mvl	(03Eh),(03Ah)
	inc	x
	or	(042h),004h
	call	SUB_BDAAF
	mv	il,004h
	mvl	(03Ah),(03Eh)
	mvp	(047h),(04Bh)
LOC_BE182:
	mvp	(04Bh),(047h)
	test	(042h),002h
	jrnz	LOC_BE191
	pushu	x
	pushu	y
	call	SUB_BDD30
	popu	y
	popu	x
LOC_BE191:
	cmp	(04Ah),000h
	jrz	LOC_BE1B6
	mvp	(04Bh),000001h
	mv	a,[x]
	cmp	a,05Bh
	jrnz	LOC_BE1A9
	inc	x
	or	(042h),004h
	call	SUB_BDAAD
LOC_BE1A9:
	mv	a,(04Ah)
LOC_BE1AB:
	mv	il,003h
	adcl	(047h),(04Bh)
	dec	a
	jrnz	LOC_BE1AB
	jr	LOC_BE1BC
LOC_BE1B6:
	shl	(047h)
	shl	(048h)
	shl	(049h)
LOC_BE1BC:
	mv	a,[x++]
	cmp	a,02Ch
	jrz	LOC_BE156
	dec	x
	jp	LOC_BDEC0
LOC_BE1C7:
	mv	a,[x++]
	cmp	a,028h
	jrnz	0BE133h
	mv	(04Ah),000h
	mv	a,[x++]
	mv	il,000h
	cmp	a,04Dh
	jrz	LOC_BE205
	cmp	a,030h
	jrnz	LOC_BE1E1
	or	(04Ah),080h
	mv	a,[x++]
LOC_BE1E1:
	cmp	a,031h
	jrc	LOC_BE1EF
	cmp	a,03Ah
	jrnc	LOC_BE1EF
	and	a,00Fh
	or	(04Ah),a
	mv	a,[x++]
LOC_BE1EF:
	mv	il,010h
	cmp	a,075h
	jrz	LOC_BE205
	mv	il,020h
	cmp	a,058h
	jrz	LOC_BE205
	mv	il,040h
	cmp	a,078h
	jrz	LOC_BE205
	mv	a,021h
	jr	LOC_BE135
LOC_BE205:
	mv	ba,i
	or	(04Ah),a
	mv	a,[x++]
	cmp	a,02Ch
	jrnz	0BE133h
	or	(042h),004h
	mv	a,029h
	call	SUB_BDAAF
	mvp	(04Eh),(04Bh)
	test	(04Ah),070h
	jrnz	LOC_BE245
	mv	ba,(04Ch)
	inc	ba
	dec	ba
	jrnz	LOC_BE240
	mv	a,(04Bh)
	dec	a
	cmp	a,00Ch
	jrnc	LOC_BE240
	pushu	x
	mv	x,DB_BE7EB			; ref 0BE7EBh via x
	add	x,a
	rol	a
	add	x,a
	mvp	(04Bh),[x]
	popu	x
	jp	LOC_BDF2F
LOC_BE240:
	mv	a,022h
	jp	LOC_BD990
LOC_BE245:
	mvp	(04Bh),00000Ah
	test	(04Ah),010h
	jrnz	LOC_BE252
	mv	(04Bh),010h
LOC_BE252:
	mv	a,0FFh
	pushu	a
LOC_BE255:
	exp	(04Bh),(04Eh)
	call	SUB_BE55A
	mv	a,(051h)
	add	a,030h
	cmp	a,03Ah
	jrc	LOC_BE26C
	add	a,007h
	test	(04Ah),040h
	jrz	LOC_BE26C
	add	a,020h
LOC_BE26C:
	pushu	a
	test	(04Ah),00Fh
	jrz	LOC_BE274
	dec	(04Ah)
LOC_BE274:
	mv	a,(04Eh)
	or	a,(04Fh)
	or	a,(050h)
	jrnz	LOC_BE255
	mv	a,(04Ah)
	mv	il,020h
	test	a,080h
	jrz	LOC_BE286
	mv	il,030h
LOC_BE286:
	and	a,00Fh
	jrz	LOC_BE28F
LOC_BE28A:
	pushu	il
	dec	a
	jrnz	LOC_BE28A
LOC_BE28F:
	popu	a
	cmp	a,0FFh
	jrz	LOC_BE299
	call	SUB_BD9C5
	jr	LOC_BE28F
LOC_BE299:
	jp	LOC_BDEC0
LOC_BE29C:
	inc	x
	call	SUB_BE3C2
	cmp	a,080h
	jrnz	LOC_BE2B8
	add	(015h),020h
	mv	a,00Fh
	jrz	LOC_BE2DE
	call	SUB_BDDC9
	sub	(015h),020h
	call	SUB_BDA2C
	jp	LOC_BDE68
LOC_BE2B8:
	cmp	a,081h
	jrnz	LOC_BE2E0
	mv	y,DB_BEB6F
	mv	il,019h
LOC_BE2C2:
	call	SUB_BE4CF
	jrc	LOC_BE2D8
	dec	il
	jrz	LOC_BE2D8
	mv	[y++],a
	mv	a,b
	cmp	a,000h
	jrz	LOC_BE2C2
	mv	[y++],a
	dec	il
	jrnz	LOC_BE2C2
LOC_BE2D8:
	mv	a,000h
	mv	[y++],a
	mv	a,029h
LOC_BE2DE:
	jr	LOC_BE3BF
LOC_BE2E0:
	cmp	a,040h
	jrnz	LOC_BE365
	pushu	y
	call	SUB_BE48F
	call	SUB_BDCC2
	jrz	LOC_BE3A8
	pushu	x
	mv	y,(02Eh)
	call	SUB_BE498
	jrc	0BE3AEh
	mv	il,(03Ah)
	mv	x,(03Bh)
	mv	[y-001h],il
LOC_BE2FC:
	mv	a,[x++]
	mv	[y++],a
	cmpp	(031h),y
	jrc	0BE3ABh
	dec	il
	jrnz	LOC_BE2FC
	popu	x
	call	SUB_BE46E
	pushu	y
	mv	[y++],ba
	mv	il,001h
LOC_BE312:
	mv	a,[x]
	cmp	a,02Bh
	jrnz	LOC_BE325
	pushu	i
	pushu	x
	inc	x
	call	SUB_BE3C2
	popu	x
	popu	i
	cmp	a,041h
	jrz	LOC_BE352
LOC_BE325:
	mv	a,[x++]
	mv	[y++],a
	cmpp	(031h),y
	jrc	0BE3ABh
	inc	i
	cmp	a,020h
	jrnc	LOC_BE325
	cmp	a,01Ah
	jrz	0BE3BDh
	cmp	a,00Ah
	jrz	LOC_BE348
	cmp	a,00Dh
	jrnz	0BE3B1h
	mv	a,[x++]
	cmp	a,00Ah
	jrz	LOC_BE348
	dec	x
LOC_BE348:
	pushu	i
	mv	a,001h
	mv	il,003h
	dadl	(023h),a
	popu	i
	jr	LOC_BE312
LOC_BE352:
	mv	ba,0001Ah
	mv	[y++],ba
	cmpp	(031h),y
	jrz	0BE3ABh
	jrc	0BE3ABh
	popu	y
	mv	[y++],i
	popu	y
	jp	LOC_BDE68
LOC_BE365:
	test	a,020h
	jrz	LOC_BE381
	pushu	y
	inc	(058h)
	jrz	0BE3BAh
LOC_BE36E:
	call	SUB_BE40A
	jrc	LOC_BE37D
	call	SUB_BE3DB
	test	a,010h
	jrnz	LOC_BE36E
	popu	y
	jr	LOC_BE3A0
LOC_BE37D:
	popu	y
	jp	LOC_BDE68
LOC_BE381:
	test	a,010h
	jrz	LOC_BE39C
	pushu	y
	cmp	(058h),000h
	jrz	0BE3B4h
LOC_BE38B:
	call	SUB_BE44C
	call	SUB_BE3DB
	test	a,010h
	jrnz	LOC_BE38B
	popu	y
	jr	LOC_BE3A0
	db	03Dh,002h,068h,0DEh
LOC_BE39C:
	test	a,008h
	jrz	LOC_BE3A8
LOC_BE3A0:
	sub	(058h),001h
	jrc	0BE3B7h
	jp	LOC_BDE68
LOC_BE3A8:
	mv	a,024h
	mv	i,01808h
	mv	i,01508h
	mv	i,00B08h
	mv	i,02708h
	mv	i,02808h
	mv	i,02608h
	mv	i,01708h
LOC_BE3BF:
	jp	LOC_BD990
SUB_BE3C2:
	call	SUB_BE48F
	call	SUB_BDCC2
	jrz	LOC_BE3A8
	pushu	x
	pushu	y
	mv	y,DB_BE76F			; ref 0BE76Fh via y
	call	SUB_BE498
	jrnc	LOC_BE3A8
	mv	a,[y+002h]
	popu	y
	popu	x
	ret
SUB_BE3DB:
	mv	(04Bh),000h
LOC_BE3DE:
	call	SUB_BE46E
	mv	a,[x]
	cmp	a,02Bh
	jrnz	LOC_BE3DE
	inc	x
	call	SUB_BE3C2
	test	a,020h
	jrz	LOC_BE3F6
	inc	(04Bh)
	jrz	0BE3BAh
	jr	LOC_BE3DE
LOC_BE3F6:
	test	a,008h
	jrz	LOC_BE400
	sub	(04Bh),001h
	jrnc	LOC_BE3DE
	ret
LOC_BE400:
	test	a,010h
	jrz	LOC_BE3DE
	cmp	(04Bh),000h
	jrnz	LOC_BE3DE
	ret
SUB_BE40A:
	and	a,003h
	jrz	LOC_BE437
	cmp	a,002h
	jrz	LOC_BE424
	jrnc	LOC_BE435
	call	SUB_BE48F
	call	SUB_BDCC2
	jrz	LOC_BE3A8
	pushu	x
	mv	y,(02Eh)
	call	SUB_BE498
	popu	x
	ret
LOC_BE424:
	call	SUB_BE48F
	call	SUB_BDCC2
	jrz	LOC_BE3A8
	pushu	x
	mv	y,(02Eh)
	call	SUB_BE498
	popu	x
	jrc	LOC_BE44A
LOC_BE435:
	sc
	ret
LOC_BE437:
	mv	a,[x++]
	cmp	a,028h
	jrnz	0BE3B1h
	mv	a,029h
	or	(042h),004h
	call	SUB_BDAAF
	cmpp	(04Bh),(025h)
	jrnz	LOC_BE435
LOC_BE44A:
	rc
	ret
SUB_BE44C:
	and	a,003h
	jrz	LOC_BE45E
	cmp	a,003h
	jrz	LOC_BE46D
	call	SUB_BE48F
	call	SUB_BDCC2
	jrz	LOC_BE3A8
	jr	LOC_BE46D
LOC_BE45E:
	mv	a,[x++]
	cmp	a,028h
	jrnz	0BE3B1h
	call	SUB_BDAAF
	mv	a,[x++]
	cmp	a,029h
	jrnz	0BE3B1h
LOC_BE46D:
	ret
SUB_BE46E:
	mv	a,[x++]
	cmp	a,020h
	jrnc	SUB_BE46E
	cmp	a,01Ah
	jrz	0BE3BDh
	cmp	a,00Ah
	jrz	LOC_BE488
	cmp	a,00Dh
	jrnz	0BE3B1h
	mv	a,[x++]
	cmp	a,00Ah
	jrz	LOC_BE488
	dec	x
LOC_BE488:
	mv	a,001h
	mv	il,003h
	dadl	(023h),a
	ret
SUB_BE48F:
	mv	a,[x++]
	cmp	a,020h
	jrz	SUB_BE48F
	dec	x
	ret
SUB_BE498:
	mv	a,[y++]
	cmp	a,000h
	jrz	LOC_BE4C1
	cmp	(03Ah),a
	jrnz	LOC_BE4B9
	mv	x,(03Bh)
	mv	i,ba
LOC_BE4A6:
	mv	(038h),[y++]
	mv	a,[x++]
	sub	a,(038h)
	jrnz	LOC_BE4B5
	dec	il
	jrnz	LOC_BE4A6
	sc
	ret
LOC_BE4B5:
	mv	ba,i
	dec	a
LOC_BE4B9:
	add	y,a
	mv	ba,[y++]
	add	y,ba
	jr	SUB_BE498
LOC_BE4C1:
	ret
SUB_BE4C2:
	mv	ba,00000h
	mv	a,[x++]
	cmp	a,02Ch
	jrz	LOC_BE522
	cmp	a,029h
	jr	LOC_BE4D6
SUB_BE4CF:
	mv	ba,00000h
	mv	a,[x++]
	cmp	a,027h
LOC_BE4D6:
	jrz	LOC_BE522
	cmp	a,020h
	jrc	LOC_BE523
	cmp	a,05Eh
	jrnz	LOC_BE4EE
	mv	a,[x++]
	cmp	a,03Fh
	jrc	LOC_BE523
	cmp	a,060h
	jrnc	LOC_BE520
	xor	a,040h
	rc
	ret
LOC_BE4EE:
	cmp	a,05Ch
	jrnz	LOC_BE4FE
	mv	a,[x++]
	cmp	a,020h
	jrc	LOC_BE523
	cmp	a,07Fh
	jrnc	LOC_BE520
	rc
	ret
LOC_BE4FE:
	cmp	a,081h
	jrc	LOC_BE51E
	cmp	a,0A0h
	jrc	LOC_BE50E
	cmp	a,0E0h
	jrc	LOC_BE51E
	cmp	a,0FDh
	jrnc	LOC_BE520
LOC_BE50E:
	mv	b,a
	mv	a,[x++]
	cmp	a,040h
	jrc	LOC_BE523
	cmp	a,07Fh
	jrz	LOC_BE520
	cmp	a,0FDh
	jrnc	LOC_BE520
	ex	a,b
LOC_BE51E:
	rc
	ret
LOC_BE520:
	cmp	a,027h
LOC_BE522:
	sc
LOC_BE523:
	ret
	db	009h,003h,054h,04Bh,04Eh,006h,009h,003h,05Ch,04Bh,04Eh,006h,008h,018h,0CAh,051h
	db	04Eh,0CAh,04Eh,025h,009h,006h,054h,04Eh,04Eh,01Eh,005h,009h,003h
	db	'TNK|',000h
	db	01Bh,010h,0CAh,04Bh,04Eh,006h,004h,05Ah,0E5h,0CAh,04Bh,04Eh,006h,004h,05Ah,0E5h
	db	0CAh,04Bh,051h,006h
SUB_BE55A:
	mv	a,018h
	mvp	(051h),(025h)
	exp	(04Bh),(04Eh)
LOC_BE562:
	mv	il,006h
	adcl	(04Eh),(04Eh)
	mv	il,003h
	sbcl	(051h),(04Bh)
	jrc	LOC_BE572
	inc	(04Eh)
	jr	LOC_BE577
LOC_BE572:
	mv	il,003h
	adcl	(051h),(04Bh)
LOC_BE577:
	dec	a
	jrnz	LOC_BE562
	ret
	db	0C6h,04Fh,025h,01Ah,060h,080h,04Eh,060h,000h,018h,00Bh,09Fh,0F7h,04Bh,0F7h,04Ch
	db	0F7h,04Dh,07Ch,000h,01Bh,00Bh,006h,0C6h,04Fh,025h,01Ah,049h,080h,04Eh,060h,000h
	db	018h,00Bh,09Fh,0F5h,04Dh,0F5h,04Ch,0F5h,04Bh,07Ch,000h,01Bh,00Bh,006h
LOC_BE5AA:
	mvp	(04Eh),0FFFFFFh
	xor	(04Bh),(04Eh)
	xor	(04Ch),(04Fh)
	xor	(04Dh),(050h)
	ret
	db	'~KN~LO~MP'
	db	006h
	db	'vKNvLOvMP'
	db	006h
LOC_BE5CD:
	mvp	(04Eh),(04Bh)
	mvp	(04Bh),(025h)
	mv	il,003h
	sbcl	(04Bh),(04Eh)
	ret
LOC_BE5D9:
	mvp	(04Eh),(025h)
	cmpp	(04Bh),(04Eh)
	jrz	LOC_BE5E5
	mvp	(04Bh),(025h)
	ret
LOC_BE5E5:
	mvp	(04Bh),0FFFFFFh
	ret
	db	0C7h,04Bh,04Eh,01Bh,00Bh,013h,011h,0C7h,04Eh,04Bh,01Dh,012h,013h,018h,0C7h,04Eh
	db	04Bh,01Fh,019h,013h,01Fh,0C7h,04Bh,04Eh,01Dh,020h,013h,026h,0C7h,04Bh,04Eh,01Fh
	db	027h,013h,02Dh,0C7h,04Bh,025h,01Bh,02Eh,0C7h,04Eh,025h,01Bh,033h,013h,039h,0C7h
	db	04Bh,025h,019h,03Eh,0C7h,04Eh,025h,019h,043h,013h,041h
SUB_BE626:
	pushu	y
	mv	(046h),000h
LOC_BE62A:
	call	SUB_BE6B6
	jrz	LOC_BE62A
	dec	x
	mv	a,081h
	jrc	LOC_BE696
	mv	y,x
LOC_BE637:
	call	SUB_BE6B6
	jrnc	LOC_BE637
	xor	a,03Ah
	jrz	LOC_BE649
	mv	x,y
	mv	y,0BFC7Dh
	mv	(046h),001h
LOC_BE649:
	pushu	x
	mv	x,y
	mv	y,[u+003h]
	mv	il,006h
LOC_BE651:
	mv	a,[x++]
	mv	[y++],a
	xor	a,03Ah
	jrz	LOC_BE664
	dec	il
	jrnz	LOC_BE651
	mv	a,00Ah
	popu	x
	jr	LOC_BE696
LOC_BE662:
	mv	[y++],a
LOC_BE664:
	mv	ba,02020h
	dec	il
	jrnz	LOC_BE662
	popu	x
	mv	a,[x]
	call	SUB_BE6B8
	jrnc	LOC_BE67A
	cmp	a,02Eh
	jrz	LOC_BE67A
	mv	ba,03F20h
LOC_BE67A:
	mv	il,008h
	call	SUB_BE698
	cmp	a,02Eh
	jrnz	LOC_BE688
	inc	x
	or	(046h),002h
LOC_BE688:
	mv	a,02Eh
	mv	[y++],a
	mv	il,003h
	call	SUB_BE698
	mv	[y++],il
	mv	a,001h
	rc
LOC_BE696:
	popu	y
	retf
SUB_BE698:
	mv	a,[x]
	call	SUB_BE6B8
	xor	a,02Ah
	mv	a,03Fh
	jrz	LOC_BE6A8
	mv	a,b
	jrc	LOC_BE6A8
	mv	a,[x++]
LOC_BE6A8:
	mv	[y++],a
	dec	il
	jrnz	SUB_BE698
LOC_BE6AE:
	call	SUB_BE6B6
	jrnc	LOC_BE6AE
	dec	x
	ret
SUB_BE6B6:
	mv	a,[x++]
SUB_BE6B8:
	cmp	a,0FFh
	jrz	LOC_BE6D5
	cmp	a,022h
	jrz	LOC_BE6D7
	cmp	a,03Ch
	jrz	LOC_BE6D7
	cmp	a,03Eh
	jrz	LOC_BE6D7
	cmp	a,03Ah
	jrz	LOC_BE6D7
	cmp	a,02Eh
	jrz	LOC_BE6D7
	cmp	a,020h
	jrz	LOC_BE6D7
	ret
LOC_BE6D5:
	cmp	a,000h
LOC_BE6D7:
	sc
	ret
DB_BE6D9:
	db	000h,00Ah,016h,01Eh
	db	'&6>BFJN* 0'
	db	0E5h,02Fh,020h,04Ch,0E5h,025h,020h,053h,0E5h,000h,02Bh,020h,024h,0E5h,02Dh,020h
	db	02Ah,0E5h,000h,03Ch,03Ch,07Ch,0E5h,03Eh,03Eh,093h,0E5h,000h,03Ch,03Dh,0F9h,0E5h
	db	03Ch,07Ch,000h,0E6h,03Eh,03Dh,007h,0E6h,07Ch,03Eh,0F2h,0E5h,000h,021h,03Dh,0EBh
	db	0E5h,03Dh,03Dh,0DCh,0E5h,000h,026h,01Fh,0C3h,0E5h,000h,05Eh,01Fh,0AFh,0E5h,000h
	db	07Ch,01Fh,0B9h,0E5h,000h,026h,026h,01Ah,0E6h,000h,07Ch,07Ch,00Eh,0E6h,000h
DB_BE736:
	db	004h
	db	'BYTE'
	db	001h,000h,001h,004h
	db	'ENUM'
	db	001h,000h,001h,004h
	db	'WORD'
	db	001h,000h,002h,004h
	db	'PNTR'
	db	001h,000h,003h,004h
	db	'FLAG'
	db	001h,000h,000h,004h
	db	'TEST'
	db	001h,000h,004h,004h
	db	'STRF'
	db	001h,000h,005h,000h
DB_BE76F:
	db	007h
	db	'INCLUDE'
	db	001h,000h,080h,005h
	db	'ERROR'
	db	001h,000h,081h,008h
	db	'DEFMACRO'
	db	001h,000h,040h,008h
	db	'ENDMACRO'
	db	001h,000h,041h,002h,049h,046h,001h,000h,020h,005h
	db	'IFDEF'
	db	001h,000h,021h,006h
	db	'IFNDEF'
	db	001h,000h,022h,006h
	db	'ELSEIF'
	db	001h,000h,010h,009h
	db	'ELSEIFDEF'
	db	001h,000h,011h,00Ah
	db	'ELSEIFNDEF'
	db	001h,000h,012h,004h
	db	'ELSE'
	db	001h,000h,013h,005h
	db	'ENDIF'
	db	001h,000h,008h,000h
DB_BE7EB:
	db	'JanFebMarAprMayJunJulAugSepOctNovDec'
DB_BE80F:
	db	000h,0D8h,00Bh,000h,0F4h,00Bh,000h,0F8h,00Bh,000h,0F4h,00Bh,000h,0F3h,00Bh,000h
	db	0F2h,00Bh,000h,0F2h,00Bh,000h,0FFh,0FFh,000h,000h,000h,000h,000h,000h,000h
DB_BE82E:
	db	02Eh,042h,000h
DB_BE831:
	db	02Eh,043h,000h
DB_BE834:
	db	02Bh,02Bh,000h
DB_BE837:
	db	05Fh,0CFh,0B8h,0DBh
	db	'_:            ',000h
DB_BE84A:
	db	'CLOCK:',000h
DB_BE851:
	db	0FFh,000h,006h,001h,010h
DB_BE856:
	db	000h,000h,000h
DB_BE859:
	db	000h,000h,000h,0FFh,0FFh,0FFh,000h,00Fh
DB_BE861:
	db	'MASSE/1.2.0 (c) N.Masuichi 1997.4.10',00Dh,00Ah,000h
	db	'USAGE : MASSE [-Mx/-Rx] source [object]',00Dh,00Ah,000h
	db	' in 000000'
DB_BE8BC:
	db	000h
	db	'Error 00'
DB_BE8C5:
	db	' in fcs',000h
	db	02Eh,00Dh,00Ah,000h,020h,00Dh,00Ah,000h,01Eh
	db	'Pass 1 [',000h
	db	01Eh
	db	'Pass 2 [',000h
	db	05Dh,00Dh,00Ah,000h
	db	'Object:000000-000000[000000'
DB_BE908:
	db	05Dh,00Dh,00Ah,000h
	db	'Syntax error',000h
	db	'Memory exhausted',000h
	db	'Relocation table exhausted',000h
	db	'Location counter undefined',000h
	db	'Include nest over',000h
	db	'Struct brace not closed',000h
	db	027h,05Ch,07Dh,027h
	db	' used without '
	db	027h,05Ch,07Bh,027h,000h
	db	'Struct brace nest over',000h
	db	'Too complex expression',000h
	db	'Undefined identifier',000h
	db	'Duplicate identifier',000h
	db	'Too long idenitfier',000h
	db	'Unexpected EOF',000h
	db	'Macro table exhausted',000h
	db	'No object',000h
	db	'Branch direction false',000h
	db	'Branch too far',000h
	db	'Filename expected',000h
	db	'Illegal label path',000h
	db	'User break',000h
	db	'Sorry, internal error',000h
	db	027h
	db	'\TEST'
	db	027h
	db	' error',000h
	db	027h
	db	'\STRF'
	db	027h
	db	' format error',000h
	db	'Data out of range',000h
	db	'Macro parameter error',000h
	db	027h,02Bh,027h
	db	' command error',000h
	db	027h,02Bh,049h,046h,027h,02Dh,027h
	db	'+ENDIF'
	db	027h
	db	' not closed',000h
	db	027h,02Bh,049h,046h,027h,02Dh,027h
	db	'+ENDIF'
	db	027h
	db	' nest over',000h
	db	027h
	db	'+ELSE'
	db	027h
	db	' used without '
	db	027h,02Bh,049h,046h,027h,000h,027h
	db	'+ENDIF'
	db	027h
	db	' used without '
	db	027h,02Bh,049h,046h,027h,000h
