; SAMPLE5.ASM - Test des nouvelles fonctionnalites XASM modernes
;
        ORG     0E000H

; ── Test SECTION ─────────────────────────────────────────────
        SECTION INIT

; ── Test REPEAT / ENDR ───────────────────────────────────────
; Genere 4 NOP consecutifs
        REPEAT  4
        NOP
        ENDR

; ── Test IFEQ / IFNE / IFGT / IFLT ──────────────────────────
VERSION:        EQU     2

        IFEQ    VERSION-2
        DB      056H            ; code specifique V2
        ENDIF

        IFNE    VERSION-1
        DB      0FFH            ; pas la version 1
        ENDIF

        IFGT    VERSION-1
        DB      001H            ; version > 1
        ENDIF

        IFLT    VERSION-5
        DB      002H            ; version < 5
        ENDIF

; ── Test STRUCT / ENDS ───────────────────────────────────────
POINT:          STRUCT
POINT_X:        EQU     0
POINT_Y:        EQU     1
                ENDS

; POINT_SIZE est automatiquement defini = 2

; ── Test SECTION MAIN ────────────────────────────────────────
        SECTION MAIN

MAIN:
        MV      A,0             ; initialisation
        MV      IL,POINT_X      ; utiliser champ de structure
        MV      I,POINT_SIZE    ; utiliser taille de structure

; Boucle avec REPEAT : copier 8 octets
        REPEAT  8
        MV      A,[X++]
        ENDR

        END