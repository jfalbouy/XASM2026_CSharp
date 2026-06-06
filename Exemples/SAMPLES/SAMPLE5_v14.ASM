; ============================================================
; SAMPLE5_v14.ASM - Test fonctionnalites XASM 1.4
; Compatible XASM v1.4 original
; PC-E500S / SC62015
; ============================================================

        ORG     0E000H

; ── Constantes EQU ───────────────────────────────────────
VERSION:        EQU     2
VRAM_BASE:      EQU     0E0000H
IOCS_ENTRY:     EQU     00000AH
POINT_X:        EQU     0
POINT_Y:        EQU     1
POINT_SIZE:     EQU     2

; ── Definition macro (syntaxe XASM 1.4 : MACRO macroname) ─
        MACRO   DELAY
        NOP
        NOP
        ENDM

; ── Test DEF / IFDEF / IFNDEF / ENDIF ────────────────────
        DEF     VER2

        IFDEF   VER2
        DB      056H            ; code specifique V2
        ENDIF

        IFNDEF  VER1
        DB      0FFH            ; pas la version 1
        ENDIF

; ── Programme principal ──────────────────────────────────
MAIN:
        MV      A,0             ; initialisation
        MV      IL,POINT_X      ; champ X
        MV      I,POINT_SIZE    ; taille structure

; ── Test LOCAL / ENDL ────────────────────────────────────
        LOCAL
LOOP_LABEL:
        MV      A,[X++]
        DEC     I
        JRZ     LOOP_END
        JR      LOOP_LABEL
LOOP_END:
        ENDL

; ── 4 NOP ────────────────────────────────────────────────
        NOP
        NOP
        NOP
        NOP

; ── Copie 4 octets ───────────────────────────────────────
        MV      A,[X++]
        MV      A,[X++]
        MV      A,[X++]
        MV      A,[X++]

; ── Appel macro ──────────────────────────────────────────
        DELAY

        END
