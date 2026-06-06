; Included by coverage_all.asm
inc_const:       equ     $34
inc_byte:        db      $12,$34,$56,$78
inc_word:        dw      $1234
inc_ptr:         dp      $0BE123

        macro   inc_pair,left,right
        add     left,right
        sub     left,right
        endm

        def     INCLUDE_FLAG
        end
