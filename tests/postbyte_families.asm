; postbyte_families.asm --- couverture systematique des familles a post-octet
;
; Chaque ligne exerce une combinaison (mnemonique x mode d'indirection) des familles
; qui portent un post-octet ou un sous-octet :
;     E0-E3 / E8-EB   (n) <-> [r3], avec [r3] [r3++] [--r3] [r3+n] [r3-n]
;     F0-F3 / F8-FB   (n) <-> [(n)], avec [(n)] [(n)+n] [(n)-n]
;     56 / 5E         MVL a offset de pointeur
;     90-96 / B0-B6   registre <-> [r3]
;     98-9E / B8-BE   registre <-> [(n)]
;
; Ces familles sont celles ou l'ordre des champs et le choix du sous-octet se jouent :
; l'emplacement RAM interne precede TOUJOURS l'offset du pointeur, et un mode sans
; offset s'ecrit avec un sous-octet nul, sans octet de deplacement.
; Reference : SHARP, ESR-L INSTRUCTION MANUAL, pp. 73-88 (table de commandes).
;
; Les octets attendus sont dans postbyte_families.expected.txt, produits par le moteur
; de reference xasm2026-1-2. Voir postbyte_families.README.md.

	org	0BE000h

	mv	(022h),[y]
	mv	[y],(022h)
	mv	(022h),[y++]
	mv	[y++],(022h)
	mv	(022h),[--y]
	mv	[--y],(022h)
	mv	(022h),[y+011h]
	mv	[y+011h],(022h)
	mv	(022h),[y-011h]
	mv	[y-011h],(022h)
	mvw	(022h),[y]
	mvw	[y],(022h)
	mvw	(022h),[y++]
	mvw	[y++],(022h)
	mvw	(022h),[--y]
	mvw	[--y],(022h)
	mvw	(022h),[y+011h]
	mvw	[y+011h],(022h)
	mvw	(022h),[y-011h]
	mvw	[y-011h],(022h)
	mvp	(022h),[y]
	mvp	[y],(022h)
	mvp	(022h),[y++]
	mvp	[y++],(022h)
	mvp	(022h),[--y]
	mvp	[--y],(022h)
	mvp	(022h),[y+011h]
	mvp	[y+011h],(022h)
	mvp	(022h),[y-011h]
	mvp	[y-011h],(022h)
	mvl	(022h),[y++]
	mvl	[y++],(022h)
	mvl	(022h),[--y]
	mvl	[--y],(022h)
	mvl	(022h),[y+011h]
	mvl	[y+011h],(022h)
	mvl	(022h),[y-011h]
	mvl	[y-011h],(022h)
	mv	(022h),[(033h)]
	mv	[(033h)],(022h)
	mv	(022h),[(033h)+044h]
	mv	[(033h)+044h],(022h)
	mv	(022h),[(033h)-044h]
	mv	[(033h)-044h],(022h)
	mvw	(022h),[(033h)]
	mvw	[(033h)],(022h)
	mvw	(022h),[(033h)+044h]
	mvw	[(033h)+044h],(022h)
	mvw	(022h),[(033h)-044h]
	mvw	[(033h)-044h],(022h)
	mvp	(022h),[(033h)]
	mvp	[(033h)],(022h)
	mvp	(022h),[(033h)+044h]
	mvp	[(033h)+044h],(022h)
	mvp	(022h),[(033h)-044h]
	mvp	[(033h)-044h],(022h)
	mvl	(022h),[(033h)]
	mvl	[(033h)],(022h)
	mvl	(022h),[(033h)+044h]
	mvl	[(033h)+044h],(022h)
	mvl	(022h),[(033h)-044h]
	mvl	[(033h)-044h],(022h)
	mv	a,[y]
	mv	[y],a
	mv	a,[y++]
	mv	[y++],a
	mv	a,[--y]
	mv	[--y],a
	mv	a,[y+011h]
	mv	[y+011h],a
	mv	a,[y-011h]
	mv	[y-011h],a
	mv	a,[(033h)]
	mv	[(033h)],a
	mv	a,[(033h)+044h]
	mv	[(033h)+044h],a
	mv	ba,[y]
	mv	[y],ba
	mv	ba,[y++]
	mv	[y++],ba
	mv	ba,[--y]
	mv	[--y],ba
	mv	ba,[y+011h]
	mv	[y+011h],ba
	mv	ba,[y-011h]
	mv	[y-011h],ba
	mv	ba,[(033h)]
	mv	[(033h)],ba
	mv	ba,[(033h)+044h]
	mv	[(033h)+044h],ba
	mv	x,[y]
	mv	[y],x
	mv	x,[y++]
	mv	[y++],x
	mv	x,[--y]
	mv	[--y],x
	mv	x,[y+011h]
	mv	[y+011h],x
	mv	x,[y-011h]
	mv	[y-011h],x
	mv	x,[(033h)]
	mv	[(033h)],x
	mv	x,[(033h)+044h]
	mv	[(033h)+044h],x

	end
