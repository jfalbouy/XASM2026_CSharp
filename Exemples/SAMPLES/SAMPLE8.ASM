; SAMPLE8.ASM - Expressions, bases numeriques et operateurs
;
; Illustre l'evaluateur de xasm2026-4 : bases numeriques, compteur de
; localisation, operateurs binaires et de comparaison, extraction d'octets.
; ATTENTION : ce fichier n'assemble PAS avec xasm2026-1 ; seuls les
; operateurs + - * / % & | y existent.

        title   'SAMPLE8 - expressions'
        org     0E000H

; ---------------------------------------------------------------------------
; Bases numeriques : c'est le DERNIER caractere du jeton qui fixe la base.
; Le souligne est un separateur visuel ignore. Un nombre commence toujours
; par un chiffre, d'ou le zero de tete en hexadecimal.
; ---------------------------------------------------------------------------
        section BASES

        db      10110101b       ; binaire      -> B5
        db      377o            ; octal        -> FF
        db      1234d           ; decimal      -> D2 (octet bas de 1234)
        db      42              ; decimal nu   -> 2A
        db      0ffh            ; hexadecimal  -> FF
        db      $ab             ; hexadecimal  -> AB
        db      1010_1010b      ; souligne     -> AA

; ---------------------------------------------------------------------------
; Extraction d'octets d'une adresse 20 bits, calquee sur xlow/xmid/xhigh.
; ---------------------------------------------------------------------------
        section OCTETS

cible:  equ     0BE123H
        db      low  cible      ; -> 23
        db      mid  cible      ; -> E1
        db      high cible      ; -> 0B

; ---------------------------------------------------------------------------
; Operateurs binaires et decalages.
; ---------------------------------------------------------------------------
        section BINAIRE

        db      0F0H|0FH        ; OU           -> FF
        db      0FFH&0F0H       ; ET           -> F0
        db      0F0H^0FFH       ; OU exclusif  -> 0F
        db      ~0FFH&0FFH      ; complement   -> 00
        db      1<<4            ; decalage     -> 10
        db      80H>>3          ; decalage     -> 10
        db      17%5            ; modulo       -> 02

; Deux precedences contre-intuitives, toutes deux voulues et heritees du C :
        db      1+2%3           ; (1+2)%3      -> 00   le modulo lie moins fort que +
        db      1<<2+3          ; 1<<5         -> 20   le decalage aussi

; ---------------------------------------------------------------------------
; Comparaisons : rendent 1 ou 0, combinables avec l'assemblage conditionnel.
; ---------------------------------------------------------------------------
        section COMPARE

        db      3<5             ; -> 01
        db      5<3             ; -> 00
        db      4=4             ; -> 01
        db      4<>4            ; -> 00
        db      5>=5            ; -> 01

; ---------------------------------------------------------------------------
; Le compteur de localisation "*" en position de terme. Entre deux valeurs,
; "*" reste la multiplication : les deux emplois ne se confondent pas.
; ---------------------------------------------------------------------------
        section COMPTEUR

debut:  dp      *               ; adresse de cette ligne
        dp      *+3             ; adresse decalee
        db      4*3             ; multiplication -> 0C

        end
