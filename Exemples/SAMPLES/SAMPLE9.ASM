; SAMPLE9.ASM - Placement, donnees et diagnostics
;
; Illustre ALIGN/EVEN, DZ, PRE, les diagnostics ASSERT/WARNING et
; l'assemblage deplace PHASE/DEPHASE, ajoutes en xasm2026-4.
; ATTENTION : ce fichier n'assemble PAS avec xasm2026-1.
;
; Les avertissements ne sont visibles qu'avec l'option -W.

        title   'SAMPLE9 - placement et diagnostics'
        org     0E000H

; ---------------------------------------------------------------------------
; Alignement. L'image produite etant contigue, ALIGN EMET le remplissage au
; lieu de seulement avancer le compteur : sans cela l'objet et les adresses
; divergeraient.
; ---------------------------------------------------------------------------
        section ALIGNEMENT

        db      1,2,3
        align   4               ; 1 octet de remplissage -> 00
        db      0AAH
        even                    ; 1 octet de remplissage -> 00
        db      0BBH

; ---------------------------------------------------------------------------
; Chaines. DZ ajoute le terminateur nul, DM ne l'ajoute pas.
; ---------------------------------------------------------------------------
        section CHAINES

        dm      'PC-E500S'      ; sans terminateur
        dz      'OK'            ; -> 4F 4B 00

; ---------------------------------------------------------------------------
; Prebyte explicite. La valeur doit etre un prebyte legal : 21h-27h ou
; 30h-37h, sinon l'assemblage s'arrete.
; ---------------------------------------------------------------------------
        section PREBYTE

        pre     21H
        pre     37H

; ---------------------------------------------------------------------------
; Diagnostics declenches par le source. ASSERT n'est evalue qu'en passe
; d'emission : en passe de resolution une reference avant vaut encore zero
; et l'assertion echouerait a tort.
; ---------------------------------------------------------------------------
        section DIAGNOSTIC

taille: equ     100
        assert  taille<256,'la table depasse un octet'
        assert  taille                          ; simplement non nulle
        warning 'exemple de code experimental'   ; visible avec -W

; ---------------------------------------------------------------------------
; Assemblage deplace. Le code ci-dessous est assemble comme s'il s'executait
; en 0B0000h, alors que ses octets restent a leur place dans l'image. C'est
; le cas d'un bloc recopie en RAM systeme avant d'etre execute, courant sur
; PC-E500S.
; ---------------------------------------------------------------------------
        section DEPLACE

        phase   0B0000H
routine:
        nop
        dp      routine         ; -> 00 00 0B, l'adresse d'EXECUTION
        dephase
        dp      *               ; -> l'adresse physique, de nouveau

; ---------------------------------------------------------------------------
; Mise en page du listing. NOLIST retire des lignes du listing sans jamais
; changer les octets emis.
; ---------------------------------------------------------------------------
        section LISTING

        nolist
        db      0EEH            ; emis, mais absent du listing
        list
        db      0FFH

        end
