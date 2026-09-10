;=======================================================================
;	This  is  a sample program  for XASM
;=======================================================================
        org     0bcdefh
;
l1:     pushs   imr 
        wait
        mv      x,l4
        mvw     [l3!label1!test1+2],($14) 
l2:     mvp     (10),(10)
l3:     local
l2:     nop
label1: local
        add     x,y
test2:  sub     a,1
test1:  cmp     a,0
        endl
l5:     jpf     l2
        mv      a,(-1)*(-1)
        jpf     label1
        endl
l8:     equ     $abcd
        jp      l8
l4:     callf   l1
l5:     local
ll1:    db      'abcdefg',13,10
ll2:    local
lll1:   dw      '0123456789',13,10
        endl
        endl
;
        end
