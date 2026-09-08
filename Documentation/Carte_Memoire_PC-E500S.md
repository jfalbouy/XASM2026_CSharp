# Carte mémoire du SHARP PC-E500S — constantes triées par adresse

Version du document : 08/09/2026

Ce document présente les **constantes système** de `Exemples/INCLUDE/pce500.inc` **triées par adresse croissante**, pour visualiser la continuité de la mémoire et retrouver rapidement *ce qui se trouve à une adresse donnée*. Il est **généré** depuis `pce500.inc` (lui-même généré depuis les tables du désassembleur `SC62015Disassembler`) : ne pas l'éditer à la main — régénérer par `python tools/gen_carte_memoire.py`.

> Les tables du bas (**codes de fonction FCS/IOCS**, **numéros de device**) ne sont **pas des adresses** : ce sont des valeurs à placer dans un registre (`IL`, `(cl)`). Elles sont listées à part, triées par valeur.

## Adresses mémoire (triées)

125 constantes d'adresse, de `0000CBH` à `0FFFE8H`.

### RAM interne du CPU (00h–0FFh) — vue aussi par PEEK/POKE 0–255

| Adresse | Nom | Description |
|---|---|---|
| `0000CBH` | `txtbas` | TEXT.BAS courant |
| `0000CEH` | `datbas` | DATA.BAS courant |
| `0000D1H` | `basptr` | POINTEUR (3 octets) vers la zone de travail de l'interpreteur BASIC. A NE PAS CONFONDRE avec baswrk = 0BFD0Eh, qui est la zone elle-meme : ce nom-la vient du listing de E. Kako (register.lst, 1990) et sert de verite terrain. Les crochets d'extension du BASIC sont en [(basptr)+090h] et [(basptr)+093h] |
| `0000D4H` | `bl` | registre BL / BX bas |
| `0000D5H` | `bh` | registre BH / BX haut |
| `0000D6H` | `cl` | registre CL / CX bas |
| `0000D7H` | `ch` | registre CH / CX haut |
| `0000D8H` | `dl` | registre DL / DX bas |
| `0000D9H` | `dh` | registre DH / DX haut |
| `0000DAH` | `si` | pointeur source (3 octets) |
| `0000DDH` | `di` | pointeur destination (3 octets) |
| `0000E6H` | `iocsw` | zone de travail IOCS : recopie du pointeur [0BFD17h] (3 octets) (manuel technique, IOCS Special Technique p85-86) |
| `0000EAH` | `brkmsk` | masque de la touche BREAK |
| `0000EBH` | `iisr` | Interrupt In-Service Register : le bit vaut 1 pendant l'execution de la routine d'interruption ; bits 0-6 : timer rapide, timer lent, clavier, touche ON, emission SIO, reception SIO, batterie faible, bit 7 = instruction IR (manuel technique p93) |
| `0000ECH` | `bp_ram` | base pointer RAM interne |
| `0000EDH` | `px` | pointeur auxiliaire PX |
| `0000EEH` | `py` | pointeur auxiliaire PY |
| `0000EFH` | `amc` | Address Modify Control : bit 7 AME autorise la modification d'adresse, bits 5-0 AM5-AM0 donnent la capacite de la carte RAM cote CE0 en code thermometre (000000 = 2 Ko, 000001 = 4, 000011 = 8, 000111 = 16, 001111 = 32, 011111 = 64, 111111 = 128 Ko). La derniere adresse de CE0 est toujours xFFFFh : c'est pourquoi une RAM plus petite est calee en HAUT de sa zone. Lecture/ecriture (manuel CPU p8-9) |
| `0000F0H` | `ko` | Key Output Buffer bas (KOL) : pilote les pins KO0-KO7, un bit par pin, 1 = niveau haut ; strobe clavier. Lecture/ecriture (manuel CPU p9) |
| `0000F1H` | `koh` | Key Output Buffer haut (KOH) : pilote les pins KO8-KO15. Lecture/ecriture (manuel CPU p9-10) |
| `0000F2H` | `ki` | Key Input Buffer (KI) : etat des pins KI0-KI7, 1 = niveau haut ; lecture du clavier. LECTURE SEULE (manuel CPU p10) |
| `0000F3H` | `eol` | E Port Output Buffer bas (EOL) : pilote les pins E0-E7, port d'E/S general. Lecture/ecriture (manuel CPU p10) |
| `0000F4H` | `eoh` | E Port Output Buffer haut (EOH) : pilote les pins E8-E15. Lecture/ecriture (manuel CPU p10) |
| `0000F5H` | `eil` | E Port Input Buffer bas (EIL) : etat des pins E0-E7. LECTURE SEULE (manuel CPU p11) |
| `0000F6H` | `eih` | E Port Input Buffer haut (EIH) : etat des pins E8-E15. LECTURE SEULE (manuel CPU p11) |
| `0000F7H` | `ucr` | UART Control Register : bit 7 BOE (break : force 0 sur TXD), bits 6-4 debit (0 arrete ET REINITIALISE l UART, 1 300, 2 600, 3 1200, 4 2400, 5 4800, 6 9600, 7 19200 bps), bits 3-2 parite (00 paire, 01 impaire, 1x aucune), bit 1 longueur (0 : 8 bits, 1 : 7), bit 0 stop (0 : 1 bit, 1 : 2). 068h = 9600 8N1. Lecture/ecriture (manuel CPU p11-12) |
| `0000F8H` | `usr` | UART Status Register : bit 5 RXR caractere recu, bit 4 TXE emetteur au repos, bit 3 TXR tampon d'emission libre, bit 2 FE erreur de trame, bit 1 OE surcharge, bit 0 PE erreur de parite. RXR et TXR alimentent les bits RXRI/TXRI de l ISR. L horloge de l UART vient de la CG principale : elle est ARRETEE en HALT et OFF, une reception ne peut donc pas reveiller la machine. LECTURE SEULE (manuel CPU p12) |
| `0000F9H` | `rxd` | UART Receive Buffer : le caractere recu ; le lire remet RXR a zero. LECTURE SEULE (manuel CPU p12-14) |
| `0000FAH` | `txd` | UART Transmit Buffer : le caractere a emettre ; peut etre ecrit pendant l'emission du precedent, TXR dit si le tampon est libre. ECRITURE SEULE (manuel CPU p14-15) |
| `0000FBH` | `imr` | Interrupt Mask Register : bit 7 IRM masque general, bit 6 EXM interruption EXTERNE (pin IRQ ; sur PC-E500 ce pin est cable au controleur de batterie, d'ou 'batterie faible' cote machine), bit 5 RXRM reception SIO, bit 4 TXRM emission SIO, bit 3 ONKM touche ON, bit 2 KEYM clavier, bit 1 STM timer secondes, bit 0 MTM timer millisecondes ; 0 interdit, 1 autorise. Une interruption empile l'IMR et met le bit 7 a 0. Lecture/ecriture (manuel CPU p15-16) |
| `0000FCH` | `isr` | Interrupt Status Register : memes bits 6-0 que l'IMR (bit 6 EXI = interruption EXTERNE), pas de bit 7. La demande met le bit a 1, ou il RESTE jusqu'a ce que le logiciel y ecrive 0. Le handler de la ROM lit (isr) ET (imr) puis saute au vecteur logiciel de 0BFCC6h+3n. Lecture/ecriture (manuel CPU p16, p37) |
| `0000FDH` | `scr` | System Control Register : bit 7 ISE autorise l'interruption externe (pin IRQ) a reveiller d'un HALT/OFF, bits 6-4 pilotent les pins CO/CI de la cassette (bas, haut, 2 kHz, 4 kHz, et autorisation de l'entree), bit 3 VDDC niveau VDD (sur SC62015B01, 1 arrete la sub-CG), bit 2 STS periode du timer secondes (0 : 0,5 s, 1 : 2 s), bit 1 MTS periode du timer millisecondes (0 : 4 ms, 1 : 16 ms), bit 0 DISC synchronisation de l'affichage. Lecture/ecriture (manuel CPU p17-19) |
| `0000FEH` | `lcc` | LCD Contrast Control : bits 7-3 contraste sur 32 crans, bit 2 KSD inhibe le strobe clavier (tous les KO au niveau bas), bit 1 STCL et bit 0 MTCL remettent a zero le timer secondes / millisecondes lors d'un TCL. Lecture/ecriture (manuel CPU p20) |
| `0000FFH` | `ssr` | System Status Register : bit 3 ONK touche ON enfoncee, bit 2 RSF (1 : on sort d'un HALT/OFF, 0 : le pin RESET a ete active), bit 1 CI entree cassette, bit 0 TEST entree de test. LECTURE SEULE (manuel CPU p20-21) |

### Registres d'E/S mappés en mémoire (afficheur LCD, etc.)

| Adresse | Nom | Description |
|---|---|---|
| `002000H` | `lcd_cmd_2000` | meme registre que lcd_cmd, vu en 002000h : les deux bases ne different que du bit 15 |
| `002002H` | `lcd_data_2000` | meme registre que lcd_data, vu en 002002h : les deux bases ne different que du bit 15 |
| `002004H` | `lcd1_cmd_2000` | meme registre que lcd1_cmd, vu en 002004h : les deux bases ne different que du bit 15 ; c'est la base que documente La Feuille du Sharp n.9, Voyage au coeur de l'ecran (A. Hansen), et celle qu'emploient S3EXT et ROUTINES.SHA |
| `002005H` | `lcd1_stat_2000` | meme registre que lcd1_stat, vu en 002005h : les deux bases ne different que du bit 15 |
| `002006H` | `lcd1_data_2000` | meme registre que lcd1_data, vu en 002006h : les deux bases ne different que du bit 15 |
| `002007H` | `lcd1_read_2000` | meme registre que lcd1_read, vu en 002007h : les deux bases ne different que du bit 15 |
| `002008H` | `lcd2_cmd_2000` | meme registre que lcd2_cmd, vu en 002008h : les deux bases ne different que du bit 15 |
| `002009H` | `lcd2_stat_2000` | meme registre que lcd2_stat, vu en 002009h : les deux bases ne different que du bit 15 |
| `00200AH` | `lcd2_data_2000` | meme registre que lcd2_data, vu en 00200Ah : les deux bases ne different que du bit 15 |
| `00200BH` | `lcd2_read_2000` | meme registre que lcd2_read, vu en 00200Bh : les deux bases ne different que du bit 15 |
| `00A000H` | `lcd_cmd` | LCD, commande des DEUX controleurs a la fois : rom83/rom53 y font l'initialisation et l'extinction (17 ecritures), vogue y ecrit sa commande avant de streamer vers lcd1_data et lcd2_data |
| `00A002H` | `lcd_data` | LCD, donnees vers les deux controleurs a la fois |
| `00A004H` | `lcd1_cmd` | HD61202 IC-6 (moitie gauche, 120 colonnes), commande : 03Eh/03Fh eteint-allume, 0C0h+adresse de depart, 0B8h+page (adresse X, 0-7), 040h+adresse Y (0-63) ; cf. La Feuille du Sharp n.9, Voyage au coeur de l'ecran (A. Hansen) |
| `00A005H` | `lcd1_stat` | HD61202 IC-6, lecture des statuts : bit 7 BUSY, bit 5 ON/OFF, bit 4 RESET |
| `00A006H` | `lcd1_data` | HD61202 IC-6, ecriture d'un octet dans la RAM d'affichage ; l'adresse s'incremente apres chaque acces |
| `00A007H` | `lcd1_read` | HD61202 IC-6, lecture d'un octet de la RAM d'affichage |
| `00A008H` | `lcd2_cmd` | HD61202 IC-5 (moitie droite, 120 colonnes), commande ; memes codes que lcd1_cmd |
| `00A009H` | `lcd2_stat` | HD61202 IC-5, lecture des statuts |
| `00A00AH` | `lcd2_data` | HD61202 IC-5, ecriture d'un octet dans la RAM d'affichage |
| `00A00BH` | `lcd2_read` | HD61202 IC-5, lecture d'un octet de la RAM d'affichage |

### Zone système haute (0BFCxxh–0BFFxxh) : chaîne des devices, vecteurs, pointeurs S1

| Adresse | Nom | Description |
|---|---|---|
| `0BFC09H` | `s3_top` | lead address du slot 2 = lecteur S3: (3 octets ; manuel technique, Parameter of memory block device) |
| `0BFC0CH` | `s3_cap` | capacite du slot 2 (S3:) en blocs de 2 Ko (2 octets ; manuel technique, Parameter of memory block device) |
| `0BFC0FH` | `s2_top` | lead address du slot 1 = lecteur S2:, 040000h sur PC-E500S (3 octets ; manuel technique, Parameter of memory block device) |
| `0BFC12H` | `s2_cap` | capacite du slot 1 (S2:) en blocs de 2 Ko (2 octets ; manuel technique, Parameter of memory block device) |
| `0BFC15H` | `s1_top` | top of S1 (nom et libelle de REGISTER.ASM) ; lead address du slot 0 = lecteur S1:, 080000h sur PC-E500S (3 octets ; manuel technique, Parameter of memory block device) |
| `0BFC18H` | `s1_cap` | capacite du slot 0 (S1:) en blocs de 2 Ko (2 octets ; manuel technique, Parameter of memory block device) |
| `0BFC27H` | `scrn_crsr_x` | X du curseur du peripherique stdo:/scrn: |
| `0BFC28H` | `scrn_crsr_y` | Y du curseur du peripherique stdo:/scrn: |
| `0BFC29H` | `ctrl_disp` | code de controle affiche au lieu d'etre execute (bit 6) |
| `0BFC2AH` | `linprn` | motif de points du trait et du remplissage de rectangle, 16 points (2 octets) ; employe par les commandes 04Eh line_draw et 04Fh box_fill du device 0. ATTENTION : le manuel se contredit sur ce nom - la liste des parametres (p42) ecrit linprn, la description des commandes (p38) ecrit linptn ; la liste, qui definit le champ, fait autorite |
| `0BFC2DH` | `keytbl_1b` | pointeur table conversion clavier, code 1 octet (3 o, table de 62 o) |
| `0BFC30H` | `keytbl_2b` | pointeur table conversion clavier, code 2 octets (3 o) |
| `0BFC33H` | `keytbl_1b_shift` | pointeur table conversion clavier SHIFT, code 1 octet (3 o) |
| `0BFC36H` | `keytbl_2b_shift` | pointeur table conversion clavier SHIFT, code 2 octets (3 o) |
| `0BFC39H` | `keytbl_1b_ctrl` | pointeur table conversion clavier CTRL, code 1 octet (3 o) |
| `0BFC3CH` | `keytbl_2b_ctrl` | pointeur table conversion clavier CTRL, code 2 octets (3 o) |
| `0BFC3FH` | `funckey_flag` | bit 2 = affichage des touches de fonction interdit |
| `0BFC41H` | `key_hook1` | hook de la routine de traitement clavier (3 o) |
| `0BFC45H` | `funckey_slot` | numero de slot portant le fichier FUNCKEY (0 = S1:) |
| `0BFC46H` | `funckey_name` | nom du fichier portant les touches de fonction (BFC46-BFC51) |
| `0BFC87H` | `font_00_1f` | adresse de la police des caracteres 00h-1Fh (3 o, 6 octets par caractere) |
| `0BFC8AH` | `font_80_9f` | adresse de la police des caracteres 80h-9Fh (3 o) |
| `0BFC8DH` | `font_e0_ff` | adresse de la police des caracteres E0h-FFh, 32 glyphes (3 o ; le resolveur 0F2418h borne par cmp a,0E0h) |
| `0BFC90H` | `font_20_7f` | adresse de la police des caracteres 20h-7Fh, l'ASCII (3 o) |
| `0BFC93H` | `font_a0_df` | adresse de la police des caracteres A0h-DFh, 64 glyphes (3 o ; et non A0h-CFh comme le dit le manuel) |
| `0BFC96H` | `dotsop` | operation sur le point deja affiche : 0 allume, 1 efface, 2 inverse |
| `0BFC9BH` | `lcd_crsr_x` | X du curseur ecran |
| `0BFC9CH` | `lcd_crsr_y` | Y du curseur ecran |
| `0BFC9DH` | `lcd_width` | nombre de colonnes affichables |
| `0BFC9EH` | `lcd_height` | nombre de lignes affichables |
| `0BFCA1H` | `lcd_mode` | mode d'affichage : bit 6 = video inverse |
| `0BFCA2H` | `d_link` | device link pointer / IOCSH |
| `0BFCBAH` | `repeat_wait` | delai avant repetition d'une touche (unite 16 ms) |
| `0BFCBBH` | `repeat_pitch` | intervalle entre deux repetitions (unite 16 ms) |
| `0BFCBCH` | `apo_time` | delai d'extinction automatique (2 o, bas puis haut, unite 0,5 s) |
| `0BFCBEH` | `softint` | bit 7 = break, bit 6 = batterie faible |
| `0BFCBFH` | `keyrep` | bit 7 = repetition active, bit 4 = clic touche |
| `0BFCC0H` | `keymtx_tbl` | adresse de la table code materiel -> code matrice clavier (3 o) |
| `0BFCC3H` | `key_hook2` | hook de la routine de traitement clavier (3 o) |
| `0BFCC6H` | `intv_ftimer` | vecteur interruption timer principal, ISR/IMR bit 0 MTM ; balayage du clavier, touche BREAK comprise (manuel technique, List of interrupt factor p91-92) |
| `0BFCC9H` | `intv_stimer` | vecteur interruption timer lent, ISR/IMR bit 1 STM ; clignotement du curseur (manuel technique, List of interrupt factor p91-92) |
| `0BFCCCH` | `keyvct` | vecteur interruption clavier, ISR/IMR bit 2 KEYM ; non employee par le systeme ; se declenche quand un port K10-K17 passe a 1, soit (kil) non nul (manuel technique, List of interrupt factor p91-92) |
| `0BFCCFH` | `intv_onkey` | vecteur interruption touche ON, ISR/IMR bit 3 ONKM ; non employee par le systeme (manuel technique, List of interrupt factor p91-92) |
| `0BFCD2H` | `intv_sio_tx` | vecteur interruption emission SIO, ISR/IMR bit 4 TXRM ; non employee par le systeme ; se declencherait a la fin de l'emission d'un octet (manuel technique, List of interrupt factor p91-92) |
| `0BFCD5H` | `intv_sio_rx` | vecteur interruption reception SIO, ISR/IMR bit 5 RXRM ; reception d'un octet SIO terminee (manuel technique, List of interrupt factor p91-92) |
| `0BFCD8H` | `intv_ext` | vecteur interruption externe, ISR/IMR bit 6 EXM ; BATTERIE FAIBLE : l'interruption exterieure est cablee au controleur de batterie de la machine (manuel technique, List of interrupt factor p91-92) |
| `0BFCDBH` | `intv_soft` | vecteur interruption logicielle : instruction IR, ISR/IMR bit 7 IRM ; non employee par le systeme ; declenchee par l'instruction IR (manuel technique, List of interrupt factor p91-92) |
| `0BFCDEH` | `s1_btm` | bottom of S1 (nom et libelle de REGISTER.ASM) ; le manuel dit "last address of slot 0 (S1:) + 1" et La Feuille du Sharp en fait le pointeur de la 1re zone de travail, la pile utilisateur U : trois lectures d'une meme frontiere, la fin de la zone de fichiers de S1: ou commencent les zones de travail |
| `0BFCE1H` | `swork` | pointeur de zone de travail : pile systeme S ; taille de la zone U = [0BFCE1h] - [0BFCDEh] |
| `0BFD0EH` | `baswrk` | BASIC work address -- la ZONE de travail, en memoire EXTERNE. Nom repris du listing de E. Kako (register.lst, 1990), ou il est declare baswrk: equ 0bfd0eh. A NE PAS CONFONDRE avec basptr = 0D1h, le POINTEUR en RAM interne : un mv x,(baswrk) serait tronque a 8 bits par l assembleur, sans le moindre avertissement |
| `0BFD17H` | `iocswrk` | pointeur de zone de travail : IOCS ; debut de la zone de travail IOCS ; elle s'etend jusqu'a [0BFD1Ah] et fait environ 246h octets ; ce pointeur est recopie en RAM interne (iocsw) (manuel technique, IOCS Special Technique p85-86) |
| `0BFD1AH` | `usrwrk` | machine language area ; fin de la zone de travail IOCS et debut de la zone langage machine de l'utilisateur (manuel technique, IOCS Special Technique p85-86) |
| `0BFD31H` | `sio_timer` | minuterie d'erreur SIO, 2 octets : n x 0,5 s ; 0FFFFh = sans limite (defaut) (manuel technique, Parameter Work du driver SIO p53) |
| `0BFD33H` | `sio_baud` | reglage de la liaison SIO : bits 6-4 = vitesse (001 300, 010 600, 011 1200, 100 2400, 101 4800, 110 9600 bauds ; 000 aucune), bits 3-2 = parite (00 paire, 01 impaire, 1x aucune), bit 1 = longueur (0 : 8 bits, 1 : 7), bit 0 = bits d'arret (0 : 1, 1 : 2) ; defaut 03Ch = 1200 bauds, sans parite, 8 bits, 1 stop. Apres modification, appeler la commande 043h du device 2 (manuel technique, Parameter Work du driver SIO p53) |
| `0BFD34H` | `sio_setup` | reglage du protocole SIO : bit 6 = emettre l'octet [0BFD61h] a l'ouverture, bit 4 = emettre [0BFD62h] a la fermeture, bit 2 = XON/XOFF en reception, bit 1 = XON/XOFF en emission ; defaut 021h (manuel technique, Parameter Work du driver SIO p53) |
| `0BFD35H` | `sio_rx_port_cond` | SIO receive port condition : ce qui CONDITIONNE la reception. bit 2 CS = 1 : ne prendre la donnee que si le signal CS est haut, l'ignorer sinon ; bit 1 CD = 1 : idem sur CD ; 0 = don't care. Defaut 002h. Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>) |
| `0BFD36H` | `sio_rx_port_ctrl` | SIO receive port control : ce que le Sharp FAIT de ses sorties quand le tampon de reception est plein. bit 6 ER = 0 : ER passe bas ; bit 5 RR = 0 : RR passe bas ; bit 4 RS = 0 : RS passe bas ; 1 = don't care. Defaut 0DFh. Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>) |
| `0BFD37H` | `sio_tx_port_cond` | SIO send port condition : ce qui CONDITIONNE l'emission. bit 2 CS = 1 : n'emettre que si CS est haut, attendre sinon ; bit 1 CD = 1 : idem sur CD ; 0 = don't care. Defaut 004h. ATTENTION, c'est le reglage qui explique les I/O ERROR en emission : sans RTS cote PC, le CS du Sharp reste bas et son XOFF ne part jamais. Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>) |
| `0BFD38H` | `sio_tx_port_ctrl` | SIO send port control : ce que le Sharp fait de ses sorties autour d'un bloc emis. bit 6 ER, bit 5 RR, bit 4 RS = 1 : le signal passe haut avant le transfert du bloc et bas apres ; 0 = don't care. Defaut 050h. Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>) |
| `0BFD39H` | `sio_tx_delay` | SIO send delay : attente avant ou apres un bloc emis, <000h-0FFh> x 2 ms. Defaut 001h (2 ms). Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>) |
| `0BFD3BH` | `sio_crlf` | SIO crlf : delimiteur externe converti en delimiteur interne (00Dh + 00Ah). bits 1-0 : 00 aucun, 01 = 00Dh, 10 = 00Ah, 11 = 00Dh + 00Ah. Defaut 001h. Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>) |
| `0BFD3CH` | `sio_eof` | SIO eof code : code de fin de fichier. Defaut 01Ah. Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>) |
| `0BFD40H` | `sio_open_wait` | SIO open close wait : attente de n x 0,5 ms juste apres l'ouverture et juste avant la fermeture du port. Defaut 004h (20 ms). Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>) |
| `0BFD41H` | `sio_open_port_ctrl` | SIO open port control : etat des sorties a l'ouverture du port. Defaut 041h. Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>) |
| `0BFD61H` | `sio_open_data` | octet emis a l'ouverture du port SIO, si le bit 6 de [0BFD34h] est arme (manuel technique, Parameter Work du driver SIO p53) |
| `0BFD62H` | `sio_close_data` | octet emis a la fermeture du port SIO, si le bit 4 de [0BFD34h] est arme (manuel technique, Parameter Work du driver SIO p53) |

### Cartouches / ROM basse

| Adresse | Nom | Description |
|---|---|---|
| `0E01C2H` | `drv_off` | extinction (simuler OFF) : releve sur rom83, aucune table de l'image ne le designe |

### ROM système (0Fxxxxh) : points d'entrée FCS/IOCS

| Adresse | Nom | Description |
|---|---|---|
| `0FFFD8H` | `secure_work_call` | reservation de zone de travail : POKE en 0BFE03h l'ADRESSE DU POINTEUR de la zone ; reservation d'une zone de travail : [0BFE03h] = adresse du pointeur a deplacer (3 octets), [0BFE06h] = taille voulue (3 octets), puis CALL ; provoque un petit reset sans dommage (manuel technique, IOCS Special Technique p85-86) |
| `0FFFDCH` | `iocs_call3` | appel IOCS a trois registres seulement : POKE &BFE00,cl,ch,il puis CALL &FFFDC (manuel technique p31 ; exemple donne : POKE &HBFE00,8,0,&H41 = device 8 systeme, lecteur 0, commande 41h, qui eteint la machine). ATTENTION : la ROM emploie aussi 0BFE00h comme octet de drapeaux prive pour BASIC, TEXT, DELETE et RENUM (48 acces, bits 0 a 7 ; dans RENUM les bits 5-4 numerotent une des trois passes de balayage) : la zone est un brouillon, pas une variable persistante |
| `0FFFE4H` | `fcs_call` | FCS call entry |
| `0FFFE8H` | `iocs_call` | IOCS call entry |

## Codes de fonction et numéros (ne sont pas des adresses)

### Codes de fonction FCS (dans IL)

| Valeur | Nom | Description |
|---|---|---|
| `00h` (0) | `fcs_create_file` | creation d'un fichier, ouvert en lecture-ecriture (X = nom de fichier, termine par 000h, a |
| `01h` (1) | `fcs_open_file` | ouverture d'un fichier existant (X = nom de fichier, termine par 000h, a = 1 lecture, 2 ec |
| `02h` (2) | `fcs_close_file` | fermeture d'un fichier ((cl) = handle) : le repertoire et la FAT sont reecrits, le handle |
| `03h` (3) | `fcs_read_block` | lecture d'un bloc ((cl) = handle, X = destination, Y = nombre d'octets, a bit 0 = 0 la fin |
| `04h` (4) | `fcs_write_block` | ecriture d'un bloc ((cl) = handle, X = source, Y = nombre d'octets ; retour X = adresse su |
| `05h` (5) | `fcs_read_byte` | lecture d'un octet ((cl) = handle, a bit 0 = 0 la fin de fichier est le code 01Ah, 1 c'est |
| `06h` (6) | `fcs_write_byte` | ecriture d'un octet ((cl) = handle, a = donnee ; retour b = nombre d'octets ecrits) |
| `07h` (7) | `fcs_verify_file` | verification d'un fichier : relit n octets et les compare a la memoire ((cl) = handle, X = |
| `08h` (8) | `fcs_read_byte_nd` | lecture non destructive d'un octet : le pointeur ne bouge pas ((cl) = handle, a bit 0 = co |
| `09h` (9) | `fcs_seek` | deplacement du pointeur de fichier ((cl) = handle, (si) = deplacement sur 3 octets, a = 0 |
| `0Ah` (10) | `fcs_file_info` | informations d'un fichier ouvert ((cl) = handle). a = 0 : retour a = attribut d'ouverture, |
| `0Bh` (11) | `fcs_set_dir` | lecture ou ecriture des informations de repertoire d'un fichier (a = 0 lire, 1 ecrire ; X |
| `0Ch` (12) | `fcs_find_file` | recherche du nom de fichier correspondant, jokers admis ((bx) = numero de repertoire de de |
| `0Dh` (13) | `fcs_rename_file` | renommage d'un fichier (X = ancien nom, Y = nouveau nom, tous deux termines par 000h) |
| `0Eh` (14) | `fcs_delete_file` | suppression d'un fichier (X = nom de fichier, termine par 000h) |
| `0Fh` (15) | `fcs_free_space` | capacite libre d'un lecteur (a = 0, X = nom de lecteur ; retour (si) = capacite libre sur |
| `10h` (16) | `fcs_init_fcs` | initialisation du file control system (a = 000h zone de travail seule, 001h libere tous le |

### Codes de fonction IOCS communs (dans IL)

| Valeur | Nom | Description |
|---|---|---|
| `00h` (0) | `iocs_find_drive` | recherche du device et du lecteur d'apres le nom de lecteur (X = adresse du nom ; retour ( |
| `01h` (1) | `iocs_header_addr` | adresse du header d'apres le numero de device ((cl) = device ; retour X = adresse du heade |
| `02h` (2) | `iocs_header_next` | adresse du header suivant ((cl) = device, X = header de depart ; retour X = header trouve) |
| `03h` (3) | `iocs_drive_name` | nom de lecteur d'apres device et lecteur ((cl) = device, (ch) = lecteur, X = zone de 6 oct |
| `04h` (4) | `iocs_format_drive` | formatage du device designe par le nom de lecteur (X = nom de lecteur suivi de la chaine d |
| `05h` (5) | `iocs_init_all` | initialisation de tous les devices installes (a = niveau : 0 all reset, 1 reset, 2 off, 3 |
| `08h` (8) | `iocs_char_open` | ouverture du peripherique caractere (X = nom de fichier sur 12 octets, a = mode 1 lecture, |
| `09h` (9) | `iocs_char_close` | fermeture du peripherique caractere ((cl) et (ch) seuls) |
| `0Ah` (10) | `iocs_read_block` | lecture d'un bloc (X = destination, Y = nombre d'octets ; retour X = adresse suivante, Y = |
| `0Bh` (11) | `iocs_write_block` | ecriture d'un bloc (X = source, Y = nombre d'octets ; retour X = adresse suivante, Y = oct |
| `0Ch` (12) | `iocs_read_byte` | lecture d'un octet (retour a = donnee) |
| `0Dh` (13) | `iocs_write_byte` | ecriture d'un octet (a = donnee) |
| `0Eh` (14) | `iocs_read_byte_nd` | lecture non destructive d'un octet : la donnee est rendue sans avancer le pointeur (retour |
| `10h` (16) | `iocs_media_check` | verification du media |
| `11h` (17) | `iocs_media_param` | adresse du bloc de parametres du media (retour X = adresse du bloc, qui decrit la geometri |
| `12h` (18) | `iocs_read_sector` | lecture de secteurs ((bx) = premier secteur, (dx) = nombre de secteurs, X = destination ; |
| `13h` (19) | `iocs_write_sector` | ecriture de secteurs ((bx) = premier secteur, (dx) = nombre de secteurs, X = source ; reto |
| `14h` (20) | `iocs_write_verify_sector` | ecriture puis verification de secteurs ((bx) = premier secteur, (dx) = nombre de secteurs, |
| `15h` (21) | `iocs_verify_sector` | verification de secteurs ((bx) = premier secteur, (dx) = nombre de secteurs, X = donnees a |
| `16h` (22) | `iocs_status_read` | lecture de l'etat d'un lecteur (retour ba bit 0 = 1 lecteur protege en ecriture ; le manue |
| `17h` (23) | `iocs_sector_addr` | adresse d'un secteur ((bx) = numero de secteur ; retour X = adresse du secteur, (cx) = tai |
| `20h` (32) | `iocs_create_file` | creation d'un fichier (peripherique special ; memes registres que la fonction FCS 000h, av |
| `21h` (33) | `iocs_open_file` | ouverture d'un fichier (peripherique special ; memes registres que la fonction FCS 001h, a |
| `22h` (34) | `iocs_close_file` | fermeture d'un fichier (peripherique special ; memes registres que la fonction FCS 002h, a |
| `27h` (39) | `iocs_verify_file` | verification d'un fichier (peripherique special ; memes registres que la fonction FCS 007h |
| `29h` (41) | `iocs_seek` | deplacement du pointeur de fichier (peripherique special ; memes registres que la fonction |
| `2Ah` (42) | `iocs_file_info` | lecture des informations d'un fichier (peripherique special ; memes registres que la fonct |
| `2Bh` (43) | `iocs_set_dir` | changement des informations de repertoire (peripherique special ; memes registres que la f |
| `2Ch` (44) | `iocs_find_file` | recherche du nom de fichier correspondant (peripherique special ; memes registres que la f |
| `2Dh` (45) | `iocs_rename_file` | renommage d'un fichier (peripherique special ; memes registres que la fonction FCS 00Dh, a |
| `2Eh` (46) | `iocs_delete_file` | suppression d'un fichier (peripherique special ; memes registres que la fonction FCS 00Eh, |
| `2Fh` (47) | `iocs_free_space` | lecture de la capacite libre du lecteur (peripherique special ; memes registres que la fon |
| `3Fh` (63) | `iocs_format` | formatage du media, commun a tous les devices |
| `40h` (64) | `iocs_init_device` | initialisation du device (A = niveau : 0 all reset, 1 reset, 2 off, 3 on) |

### Numéros de device IOCS (dans (cl) = 0D6h)

| Valeur | Nom | Description |
|---|---|---|
| `00h` (0) | `dev_display` | device 0 (STDO:/SCRN:) |
| `01h` (1) | `dev_key` | device 1 (STDI:/KYBD:) |
| `02h` (2) | `dev_sio` | device 2 (COM:) |
| `03h` (3) | `dev_printer` | device 3 (STDL:/PRN:) |
| `04h` (4) | `dev_tape` | device 4 (CAS:) |
| `05h` (5) | `dev_memfile` | device 5 (E:/F:/G:) |
| `06h` (6) | `dev_memcard` | device 6 (S1:/S2:/S3:) |
| `07h` (7) | `dev_fdd` | device 7 (X:/Y:) |
| `08h` (8) | `dev_system` | device 8 (SYSTM:) |
| `09h` (9) | `dev_function` | device 9 () |

### Codes de fonction IOCS par device (IL >= 41h)

| Valeur | Nom | Description |
|---|---|---|
| `3Fh` (63) | `key_conv_table_set` | installe les SIX pointeurs de tables de conversion code matriciel -> code caract |
| `40h` (64) | `key_init_driver` | initialisation du driver clavier (a = niveau : 0 all reset, 1 reset, 2 off, 3 on |
| `41h` (65) | `display_char_out_at` | affichage d'un caractere a une position quelconque ((bl) = X, (bh) = Y, a = cara |
| `41h` (65) | `function_num_ne` | comparaison numerique Y<>X (X = (bp)-(bp+14), Y = (bp+15)-(bp+29)); (ch)=1 : add |
| `41h` (65) | `key_matrix_read` | lecture du code matrice dans le tampon de balayage (retour a : bit 7 = 1 touche |
| `41h` (65) | `memcard_search_phys` | adresse physique d'un bloc d'apres son nom ((ch) = slot 0/1/2, X = nom du bloc ; |
| `41h` (65) | `printer_print_out` | envoi d'un octet a l'imprimante (a = donnee ; cy=1 en erreur) |
| `41h` (65) | `sio_byte_out` | sortie directe d'un octet |
| `41h` (65) | `system_power_off` | extinction : arret du CPU, retour par la touche ON |
| `41h` (65) | `tape_data_write` | ecriture d'un bloc de donnees sur la bande (X = adresse, Y = taille ; retour X e |
| `42h` (66) | `display_chars_out_at` | affichage d'une chaine a une position quelconque ((bl) = X, (bh) = Y, X = adress |
| `42h` (66) | `function_num_lt` | comparaison numerique Y<X; (ch)=1 : soustraction (matrice); (ch)=2 : regression |
| `42h` (66) | `key_matrix_read_nd` | lecture non destructive du code matrice : meme rendu que 041h, sans consommer la |
| `42h` (66) | `memcard_block_resize` | changement de taille d'un bloc ((ch) = slot, a = numero de pointeur de zone libr |
| `42h` (66) | `printer_print_pos` | position courante de la tete d'impression (retour a = position) |
| `42h` (66) | `sio_byte_in` | entree directe d'un octet |
| `42h` (66) | `system_secure_work` | redimensionnement d'une zone de travail systeme (X = l'un des 21 pointeurs de 0B |
| `42h` (66) | `tape_data_read` | lecture d'un bloc de donnees depuis la bande (X = adresse, Y = taille ; retour X |
| `43h` (67) | `function_num_gt` | comparaison numerique Y>X; (ch)=1 : multiplication (matrice) |
| `43h` (67) | `key_key_read` | lecture d'une touche, apres traitement des touches SHIFT et CTRL (a bit 7 = 0 re |
| `43h` (67) | `memcard_block_transfer` | transfert d'un bloc (X = source, Y = destination, (si) = taille ; retour X et Y |
| `43h` (67) | `printer_printer_check` | test de l'imprimante (retour cy=0 : a = type d'imprimante, i = nombre maximal de |
| `43h` (67) | `sio_set_hardware` | reglage du materiel et du format d'apres la zone de travail IOCS |
| `43h` (67) | `system_basic_exec` | execution d'une chaine en code intermediaire BASIC (X = adresse ; a bit0 pas a p |
| `43h` (67) | `tape_data_verify` | lecture et comparaison d'un bloc de donnees (X = adresse, Y = taille ; retour X |
| `44h` (68) | `display_set_cursor` | positionnement du curseur, sans changer sa forme ((bl) = X, (bh) = Y ; cy=1 si h |
| `44h` (68) | `function_num_eq` | comparaison numerique Y=X; (ch)=1 : division (matrice) |
| `44h` (68) | `key_key_buffer_set` | ecriture de donnees dans le tampon clavier (X = adresse des donnees, a = nombre |
| `44h` (68) | `memcard_block_rename` | renommage d'un bloc ((ch) = slot, X = ancien nom, Y = nouveau nom ; erreur a = 0 |
| `44h` (68) | `sio_rs_high` | port RS force a l'etat haut |
| `44h` (68) | `tape_header_write` | ecriture du bloc d'en-tete sur la bande (X = adresse du bloc d'en-tete) |
| `45h` (69) | `display_cursor_type` | forme du curseur (a : bit 5 = curseur affiche, bit 3 = clignotement, bits 2-0 = |
| `45h` (69) | `function_num_le` | comparaison numerique Y<=X; (ch)=1 : inverse (matrice) |
| `45h` (69) | `key_buffer_clear` | vidage du tampon de balayage et du tampon clavier |
| `45h` (69) | `memcard_block_create` | creation d'un bloc memoire ((ch) = slot, X = nom ; retour Y = adresse du bloc cr |
| `45h` (69) | `sio_rs_low` | port RS force a l'etat bas |
| `45h` (69) | `system_code_addr` | adresse de traitement d'une instruction d'apres son code intermediaire (a = code |
| `45h` (69) | `tape_header_read` | lecture du bloc d'en-tete depuis la bande (X = adresse du bloc d'en-tete) |
| `46h` (70) | `display_symbol_disp` | allumage ou extinction des symboles de l'ecran (a = motif, un bit a 1 allume ; ( |
| `46h` (70) | `function_num_ge` | comparaison numerique Y>=X; (ch)=1 : addition d'un scalaire (matrice) |
| `46h` (70) | `key_fkey_display` | affichage ou effacement des libelles de touches de fonction (retour cy=1 si l'ec |
| `46h` (70) | `memcard_block_delete` | suppression d'un bloc memoire ((ch) = slot, X = nom ; erreur a = 002h bloc intro |
| `46h` (70) | `sio_rr_high` | port RR force a l'etat haut |
| `47h` (71) | `display_scroll_up` | defilement vers le haut de n lignes ((bx) = 00000h, a = nombre de lignes) |
| `47h` (71) | `function_add` | addition Y+X -> X (X = (bp)-(bp+14), Y = (bp+15)-(bp+29)); (ch)=1 : soustraction |
| `47h` (71) | `memcard_condense` | compactage de l'espace libre des blocs memoire ((ch) = slot) |
| `47h` (71) | `sio_rr_low` | port RR force a l'etat bas |
| `48h` (72) | `display_scroll_down` | defilement vers le bas de n lignes ((bx) = 00000h, a = nombre de lignes) |
| `48h` (72) | `function_sub` | soustraction Y-X -> X; (ch)=1 : multiplication par un scalaire (matrice) |
| `48h` (72) | `memcard_block_create_top` | creation d'un bloc memoire EN TETE des blocs, propre au PC-E500 ((ch) = slot, X |
| `48h` (72) | `sio_er_high` | port ER force a l'etat haut |
| `49h` (73) | `display_clear_line` | effacement d'une ligne ((bh) = ordonnee de la ligne) |
| `49h` (73) | `function_mul` | multiplication Y*X -> X; (ch)=1 : multiplication par X-1 scalaire (matrice) |
| `49h` (73) | `sio_er_low` | port ER force a l'etat bas |
| `4Ah` (74) | `display_dot8_write` | affichage d'un motif de 8 points, en colonne vers le bas (X, Y = coin superieur, |
| `4Ah` (74) | `function_div` | division Y/X -> X; (ch)=1 : remplacer X par Y (matrice) |
| `4Ah` (74) | `sio_read_cs` | lecture du port CS (retour cy=0 etat bas, cy=1 etat haut) |
| `4Bh` (75) | `display_dot8_read` | lecture d'un motif de 8 points, en colonne vers le bas (X, Y = coin superieur ; |
| `4Bh` (75) | `function_pow` | puissance Y^X -> X; (ch)=1 : matrice transposee (matrice) |
| `4Bh` (75) | `sio_read_cd` | lecture du port CD (retour cy=0 etat bas, cy=1 etat haut) |
| `4Ch` (76) | `display_dot_write` | affichage d'un point (X = abscisse, Y = ordonnee, a = 0 allumer, 1 eteindre, 2 i |
| `4Ch` (76) | `function_exp` | exponentielle e^X -> X; (ch)=1 : determinant (resultat dans X) (matrice) |
| `4Dh` (77) | `display_dot_read` | lecture d'un point (X = abscisse, Y = ordonnee ; retour a = 1 si le point est al |
| `4Dh` (77) | `function_sin` | sinus sinX -> X; (ch)=1 : changement de signe (matrice) |
| `4Eh` (78) | `display_line_draw` | trace d'une ligne (X,Y = point de depart, (bx),(dx) = point d'arrivee ; le mode |
| `4Eh` (78) | `function_cos` | cosinus cosX -> X; (ch)=1 : carre (matrice) |
| `4Fh` (79) | `display_box_fill` | remplissage d'un rectangle defini par les deux bouts d'une diagonale (X,Y et (bx |
| `4Fh` (79) | `function_tan` | tangente tanX -> X; (ch)=1 : ranger X dans M (matrice) |
| `50h` (80) | `display_disp_state` | allumage ou extinction de l'affichage (a = 0 eteint, 1 allume) |
| `50h` (80) | `function_asin` | arc sinus sin-1X -> X; (ch)=1 : rappeler M dans X (matrice) |
| `51h` (81) | `display_clear_disp` | effacement complet de l'affichage ((cx) = 0000h) |
| `51h` (81) | `function_acos` | arc cosinus cos-1X -> X; (ch)=1 : ajouter M et X (matrice) |
| `52h` (82) | `display_clear_from` | effacement a partir d'une position (a = nombre de caracteres, (bl) = X, (bh) = Y |
| `52h` (82) | `function_atan` | arc tangente tan-1X -> X; (ch)=1 : ranger X dans MA-MZ (matrice) |
| `53h` (83) | `function_deg` | conversion en degres X->DEG->X; (ch)=1 : rappeler MA-MZ dans X (matrice) |
| `54h` (84) | `display_insert_line` | insertion de n lignes ((bh) = Y de depart, a = nombre de lignes) |
| `54h` (84) | `function_dms` | conversion en degres-minutes-secondes X->DMS->X; (ch)=1 : systeme d'equations (m |
| `55h` (85) | `display_pattern_read` | lecture du motif de points d'une ligne vers la memoire externe ((bh) = ordonnee, |
| `55h` (85) | `function_abs` | valeur absolue \|X\| -> X; (ch)=1 : reste d'un systeme d'equations (matrice) |
| `56h` (86) | `display_pattern_write` | ecriture du motif de points d'une ligne depuis la memoire externe ((bh) = ordonn |
| `56h` (86) | `function_int` | partie entiere intX -> X |
| `57h` (87) | `display_disp_no_clip` | affichage d'un caractere SANS tenir compte de la fenetre d'affichage ((bl) = X, |
| `57h` (87) | `function_sgn` | signe sgnX -> X |
| `58h` (88) | `display_guide_line` | affichage de chaines encadrees d'un guide ((bl) = X, (bh) = Y, a = nombre de cha |
| `58h` (88) | `function_rnd` | arrondi rndX -> X |
| `59h` (89) | `function_sqr` | racine carree sqrt(X) -> X |
| `5Ah` (90) | `function_log` | logarithme decimal logX -> X |
| `5Bh` (91) | `function_ln` | logarithme neperien lnX -> X |
| `70h` (112) | `function_str_ne` | comparaison de chaines Y<>X |
| `71h` (113) | `function_str_lt` | comparaison de chaines Y<X |
| `72h` (114) | `function_str_gt` | comparaison de chaines Y>X |
| `73h` (115) | `function_str_eq` | comparaison de chaines Y=X |
| `74h` (116) | `function_str_le` | comparaison de chaines Y<=X |
| `75h` (117) | `function_str_ge` | comparaison de chaines Y>=X |
| `76h` (118) | `function_asc` | ASC : code du 1er caractere d'une chaine |
| `77h` (119) | `function_chr_s` | CHR$ : caractere de code donne |
| `78h` (120) | `function_str_s` | STR$ : nombre converti en chaine |
| `79h` (121) | `function_val` | VAL : chaine convertie en nombre |
| `7Eh` (126) | `function_dec2bin` | conversion decimal -> binaire |
| `7Fh` (127) | `function_bin2dec` | conversion binaire -> decimal |
