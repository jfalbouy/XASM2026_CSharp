; SAMPLE7.ASM - Macros avancees
;
; Illustre le portage complet du systeme de macros en xasm2026-4 :
; portee anonyme par LOCAL nu, EXITM, macros imbriquees, REPEAT dans un corps.
; ATTENTION : ce fichier n'assemble PAS avec xasm2026-1.

        title   'SAMPLE7 - macros avancees'
        org     0E000H

; ---------------------------------------------------------------------------
; LOCAL sans etiquette ouvre une portee ANONYME, unique a chaque expansion.
; C'est ce qui rend utilisables les etiquettes dans un corps de macro : sans
; lui, une reference avant se resolvait vers l'expansion voisine et le binaire
; etait faux sans le moindre message.
; ---------------------------------------------------------------------------
        section BOUCLES

        macro   attendre,duree
        local
        mv      a,duree
boucle: dec     a
        jrnz    boucle          ; vise le "boucle" de CETTE expansion
        endl
        endm

        attendre 10H
        attendre 20H            ; meme etiquette, aucune collision

; ---------------------------------------------------------------------------
; EXITM interrompt l'expansion de la macro englobante. Il n'a de sens que
; parce que le corps est re-developpe : les conditionnelles y sont resolues
; au moment de l'expansion.
; ---------------------------------------------------------------------------
        section GARDE

        macro   entete,avec_marqueur
        db      0AAH
        ifeq    avec_marqueur
        exitm                   ; sortie anticipee
        endif
        db      0BBH
        endm

        entete  0               ; -> AA
        entete  1               ; -> AA BB

; ---------------------------------------------------------------------------
; Le corps d'une macro peut contenir un REPEAT et appeler d'autres macros.
; Le moteur C l'interdisait (err 44) ; seule la recursion reste rejetee.
; ---------------------------------------------------------------------------
        section IMBRIQUE

        macro   trois_fois,valeur
        repeat  3
        db      valeur
        endr
        endm

        macro   bloc
        db      011H
        trois_fois 022H         ; macro appelee depuis une macro
        db      033H
        endm

        bloc
; -> 11 22 22 22 33

        end
