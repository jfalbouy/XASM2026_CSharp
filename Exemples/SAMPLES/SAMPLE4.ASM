;=======================================================================
;	This  is  a sample program  for XASM  Ver 1.40
;=======================================================================
;
   def    ZAURUS
   def    LOW
   undef  LOW
;
   ifdef ZAURUS
       mv    a,0
       ifndef LOW
          mv    il,1
       else
          mv    il,2
       endif
       nop
    else
       mv    a,1
       ifdef LOW
           mv    il,2
       endif
       nop
    endif
    nop
;
    end
