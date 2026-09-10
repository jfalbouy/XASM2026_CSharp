;=======================================================================
;	This  is  a sample program  for XASM  Ver 1.30
;=======================================================================
        org     0bcdefh
;
        local                   ;local block without name
          local                 ;local block without name
            nop
          endl
        endl
;
        scope_on
outer:  nop
        local
        mv      x,outer         ;be able to access to a label in outer block
        endl
;
        pre_on
        mv      (BP+0),0        ;( BP + 0 )       XASM 1.2x method
        xor     ($fd),$10       ;( $FD )
        pre_off
        mv      (0),0           ;( BP + 0 )
        xor     (#$fd),$10      ;( $FD )          Direct Prebyte
;
        pre_on
        mv      (0),0           ;pre is on
        pre_push                ;                 to save pre_on/off status
          pre_off
          mv      (0),0         ;pre is off
        pre_pop                 ;                 to restore pre_on/off
        mv      (0),0           ;pre is on
;
        addb    x,a
        addw    x,i             ;Undocumented commands about add/sub
        addp    x,y
;
;
        macro    begin          ;Macro definition
        local
continue:
        endm
;
        macro    endb
break:
        endl
        endm
;
        macro    check,param
        mv       a,[x++]
        cmp      a,param
        endm
;
;
        mv       il,10
        begin
          check   $1a
          jrz     break
          dec     il
          jrnz    continue
        endb
;
	macro	for,p1,p2,p3
	local
	mv	p1,p2
_l1:	cmp	p1,p3
	jrc	_l11
	jrnz	_l2
_l11:
	endm

	macro	next,p1
	inc	p1
	jr	_l1
_l2:
	endl
	endm
;
j:	equ	0		;use (0) as a loop counter
max:	equ	1		;use (1) as a loop maximum value
	mv	(max),10
	mv	il,0
	for (j), 1,(max)
	    mv    a,(j)
	    add   i,a
	next (j)
;
        end
