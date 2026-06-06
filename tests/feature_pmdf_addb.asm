        ORG     0100H
        PMDF    (0ECH),6
        PMDF    (BP+2),A
        PUSHS   IMR
        PUSHU   IMR
        ADDB    A,IL
        ADDW    BA,I
        ADDP    X,Y
        SUBB    A,IL
        SUBW    BA,I
        SUBP    X,Y
        END
