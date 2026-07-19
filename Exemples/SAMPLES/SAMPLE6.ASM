; SAMPLE6.ASM - Symboles redefinissables et generation de donnees
;
; Illustre les directives ajoutees en xasm2026-4 : SET, IRP, IRPC.
; ATTENTION : ce fichier n'assemble PAS avec xasm2026-1, ces directives
; n'existant pas dans le moteur C historique.

        title   'SAMPLE6 - generation de donnees'
        org     0E000H

; ---------------------------------------------------------------------------
; SET rend REPEAT reellement generatif : sans symbole redefinissable, aucun
; compteur ne peut progresser d'une iteration a l'autre.
; ---------------------------------------------------------------------------
        section COMPTEUR

n:      set     0
        repeat  8
        db      n
n:      set     n+1
        endr
; -> 00 01 02 03 04 05 06 07

; Une table de carres, calculee a l'assemblage.
carre:  set     0
        repeat  6
        db      carre*carre
carre:  set     carre+1
        endr
; -> 00 01 04 09 10 19   (0,1,4,9,16,25 en hexadecimal)

; ---------------------------------------------------------------------------
; IRP rejoue le bloc une fois par valeur de la liste.
; ---------------------------------------------------------------------------
        section LISTE

        irp     v,0AAH,0BBH,0CCH
        db      v
        endr
; -> AA BB CC

; IRPC parcourt les caracteres d'une chaine : chacun est injecte comme
; litteral, si bien que DB emet son code ASCII.
        irpc    c,PCE500
        db      c
        endr
; -> 50 43 45 35 30 30

; ---------------------------------------------------------------------------
; REPEAT, IRP et IRPC partagent le terminateur ENDR et s'imbriquent.
; ---------------------------------------------------------------------------
        section IMBRIQUE

        irp     base,10H,20H
        repeat  3
        db      base
        endr
        endr
; -> 10 10 10 20 20 20

        end
