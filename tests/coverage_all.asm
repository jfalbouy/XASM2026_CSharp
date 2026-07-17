; Large parser/output coverage file for xasm2026-4
; It intentionally covers many instructions, addressing modes and directives.

        org     $BE000
        section CODE
        include coverage_all_include.asm

base0:  equ     $00
base1:  equ     $01
base2:  equ     $02
base3:  equ     $03
base4:  equ     $04
base5:  equ     $05
base6:  equ     $06
base7:  equ     $07
ptr0:   equ     $20
ptr1:   equ     $24
ext0:   equ     $0BE900
ext1:   equ     $0BEA00

        struct  work
w_a:    ds      1
w_b:    ds      2
w_p:    ds      3
        ends

        macro   emit_marker,value
        db      value
        endm

        macro   alu_pair,left,right
        add     left,right
        sub     left,right
        and     left,right
        or      left,right
        xor     left,right
        cmp     left,right
        endm

        macro   begin_loop
        local
loop_top:
        endm

        macro   end_loop
        jr      loop_top
        endl
        endm

        pre_off
        nop
        pre_on
        pre_push
        pre_off
        mv      (base0),$11
        pre_pop
        mv      (base1),$22

        ifdef   INCLUDE_FLAG
        db      $AA
        else
        db      $55
        endif

        ifndef  NEVER_DEFINED
        db      $BB
        endif

        ifeq    1-1
        db      $CC
        endif

        ifne    2-1
        db      $DD
        endif

        ifgt    3-2
        db      $EE
        endif

        iflt    2-3
        db      $99
        endif

        repeat  4
        db      $5A
        endr

data_block:
        db      'A','B','C',0
        dm      'HELLO',13,10
        dw      $1234,ext0-base0
        dp      ext0,ext1
        ds      3
        emit_marker $7E

start:
        mv      a,$01
        mv      il,$02
        mv      ba,$1234
        mv      i,$5678
        mv      x,ext0
        mv      y,ext1
        mv      u,$0BEE00
        mv      s,$0BEF00
        mv      a,b
        mv      b,a
        ex      a,b
        swap    a

        mv      a,(base0)
        mv      il,(base1)
        mv      ba,(base2)
        mv      i,(base3)
        mv      x,(base4)
        mv      y,(base5)
        mv      u,(base6)
        mv      s,(base7)

        mv      (base0),a
        mv      (base1),il
        mv      (base2),ba
        mv      (base3),i
        mv      (base4),x
        mv      (base5),y
        mv      (base6),u
        mv      (base7),s

        mv      a,[ext0]
        mv      il,[ext0]
        mv      ba,[ext0]
        mv      i,[ext0]
        mv      x,[ext0]
        mv      y,[ext0]
        mv      u,[ext0]
        mv      s,[ext0]

        mv      [ext1],a
        mv      [ext1],il
        mv      [ext1],ba
        mv      [ext1],i
        mv      [ext1],x
        mv      [ext1],y
        mv      [ext1],u
        mv      [ext1],s

        mv      a,[x]
        mv      il,[y]
        mv      ba,[u]
        mv      i,[s]
        mv      x,[x++]
        mv      y,[y++]
        mv      u,[--u]
        mv      s,[--s]
        mv      a,[x+1]
        mv      il,[y-2]
        mv      ba,[u+3]
        mv      i,[s-4]

        mv      [x],a
        mv      [y],il
        mv      [u],ba
        mv      [s],i
        mv      [x++],x
        mv      [y++],y
        mv      [--u],u
        mv      [--s],s
        mv      [x+5],a
        mv      [y-6],il
        mv      [u+7],ba
        mv      [s-8],i

        mv      a,[(ptr0)]
        mv      il,[(ptr0)+1]
        mv      ba,[(ptr0)-2]
        mv      [(ptr1)],a
        mv      [(ptr1)+3],il
        mv      [(ptr1)-4],ba

        mv      (16),(17)
        mv      (16),$44
        mv      (17),[ext0]
        mv      (18),[x]
        mv      (18),[y++]
        mv      (18),[u-1]
        mv      (18),[(ptr0)]
        mv      (18),[(ptr0)+2]
        mv      [ext1],(16)
        mv      [x],(16)
        mv      [y++],(17)
        mv      [u-3],(18)
        mv      [(ptr1)],(16)
        mv      [(ptr1)+4],(17)

        mvw     (16),(17)
        mvw     (16),$1234
        mvw     (16),[ext0]
        mvw     (16),[x]
        mvw     (16),[(ptr0)]
        mvw     [ext1],(16)
        mvw     [x],(16)
        mvw     [(ptr1)],(16)

        mvp     (16),(17)
        mvp     (16),ext0
        mvp     (16),[ext0]
        mvp     (16),[x]
        mvp     (16),[(ptr0)]
        mvp     [ext1],(16)
        mvp     [x],(16)
        mvp     [(ptr1)],(16)

        mvl     (16),(17)
        mvl     (16),[ext0]
        mvl     (16),[x+1]
        mvl     (16),[(ptr0)+1]
        mvl     [ext1],(16)
        mvl     [x+1],(16)
        mvl     [(ptr1)+1],(16)
        mvld    (16),(17)

        ex      (16),(17)
        exw     (16),(17)
        exp     (16),(17)
        exl     (16),(17)

        add     a,$10
        add     a,(16)
        add     (16),$11
        add     (16),a
        add     a,il
        add     ba,i
        add     x,y
        addb    a,il
        addw    ba,i
        addp    x,y
        adc     a,$12
        adc     (16),$13
        adc     (16),a
        adcl    (16),(17)
        adcl    (16),a
        dadl    (16),(17)
        dadl    (16),a
        pmdf    (16),$14
        pmdf    (16),a

        sub     a,$20
        sub     a,(16)
        sub     (16),$21
        sub     (16),a
        sub     a,il
        sub     ba,i
        sub     x,y
        subb    a,il
        subw    ba,i
        subp    x,y
        sbc     a,$22
        sbc     (16),$23
        sbc     (16),a
        sbcl    (16),(17)
        sbcl    (16),a
        dsbl    (16),(17)
        dsbl    (16),a

        and     a,$30
        and     a,(16)
        and     (16),$31
        and     (16),a
        and     (16),(17)
        and     [ext0],$32
        or      a,$33
        or      a,(16)
        or      (16),$34
        or      (16),a
        or      (16),(17)
        or      [ext0],$35
        xor     a,$36
        xor     a,(16)
        xor     (16),$37
        xor     (16),a
        xor     (16),(17)
        xor     [ext0],$38
        test    a,$39
        test    (16),$3A
        test    (16),a
        test    [ext0],$3B

        cmp     a,$40
        cmp     a,(16)
        cmp     (16),a
        cmp     (16),(17)
        cmp     [ext0],$41
        cmpw    (16),(17)
        cmpw    (16),ba
        cmpp    (16),(17)
        cmpp    (16),x

        inc     a
        inc     il
        inc     ba
        inc     i
        inc     x
        inc     y
        inc     u
        inc     s
        inc     (16)
        dec     a
        dec     il
        dec     ba
        dec     i
        dec     x
        dec     y
        dec     u
        dec     s
        dec     (16)

        ror     a
        ror     (16)
        rol     a
        rol     (16)
        shr     a
        shr     (16)
        shl     a
        shl     (16)
        dsrl    (16)
        dsll    (16)

        pushu   a
        pushu   il
        pushu   ba
        pushu   i
        pushu   x
        pushu   y
        pushu   f
        pushu   imr
        popu    imr
        popu    f
        popu    y
        popu    x
        popu    i
        popu    ba
        popu    il
        popu    a
        pushs   f
        pops    f

        sc
        rc
        tcl
        halt
        off
        wait
        ir

        call    sub_near
        callf   sub_far
        jpz     branch_a
branch_a:
        jpnz    branch_b
branch_b:
        jpc     branch_c
branch_c:
        jpnc    branch_d
branch_d:
        jr      branch_e
branch_e:
        jrz     branch_f
branch_f:
        jrnz    branch_g
branch_g:
        jrc     branch_h
branch_h:
        jrnc    branch_i
branch_i:
        jp      branch_j
branch_j:
        jp      x

        begin_loop
        db      $01
        end_loop

sub_near:
        ret

sub_far:
        retf

irq_return:
        reti

        section DATA
more_data:
        inc_pair a,il
        alu_pair (16),$12
        undef   INCLUDE_FLAG
        ifndef  INCLUDE_FLAG
        db      $24
        endif

        pre_on
        mv      (bp+1),a
        mv      (px+2),a
        mv      (bp+px),a
        mv      (#$40),a
        mv      a,(bp+1)
        mv      a,(px+2)
        mv      a,(bp+px)
        mv      a,(#$40)
        mv      (bp+1),(py+2)
        mvw     (px+2),(bp+3)
        mvp     (bp+px),(bp+py)
        mvl     (bp+1),(py+2)

        reset
        end

