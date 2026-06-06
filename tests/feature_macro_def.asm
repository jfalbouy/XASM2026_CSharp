        ORG     0200H
        MACRO   TWICE,value
        DB      value
        DB      @1
        ENDM
        DEF     ENABLED
        IFDEF   ENABLED
        TWICE   12H
        ELSE
        DB      0
        ENDIF
        IFNDEF  MISSING
        DB      34H
        ENDIF
        UNDEF   ENABLED
        IFDEF   ENABLED
        DB      0FFH
        ENDIF
        END
