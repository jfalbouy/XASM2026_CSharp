; example.asm - montre l'usage de pce500.inc dans un nouveau projet.
; Assemble tel quel :  ..\..\bin\xasm2026-4.exe example.asm -O example.obj

        include pce500.inc          ; toutes les constantes systeme d'un coup

        org     0BF000H

; --- appel FCS : ouvrir un fichier ------------------------------------------
        mv      il,fcs_open_file    ; code de fonction FCS
        callf   fcs_call            ; point d'entree FCS (0FFFE4H)

; --- appel IOCS : afficher un caractere via le device ecran -----------------
        mv      (cl),dev_display    ; (0D6h) <- numero de device 0
        mv      il,display_char_out_at
        callf   iocs_call           ; point d'entree IOCS (0FFFE8H)

; --- registres internes et carte memoire ------------------------------------
        pushu   imr                 ; IMR comme registre
        mv      (imr),0A0H          ; ... et comme adresse RAM interne (0FBh)
        mv      x,[s1_top]          ; carte memoire : haut de S1: (0BFC15H)
        mv      y,[baswrk]          ; zone de travail BASIC (0BFD0EH)
        test    (ssr),8             ; System Status Register (0FFh)

        end
