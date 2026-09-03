; ============================================================================
; pce500.inc - constantes systeme du SHARP PC-E500S / SC62015
; ============================================================================
;
; GENERE automatiquement par tools/generate_pce500_inc.py a partir des tables
; du desassembleur SC62015Disassembler (Data/*.json), source autoritative alignee
; sur le listing de reference. NE PAS EDITER A LA MAIN : regenerer depuis les tables.
; Genere le 2026-09-03.
;
; Usage :   include pce500.inc
;
; Adresses en hexa avec chiffre de tete (0BFC15H) : XASM exige qu'un nombre commence
; par un chiffre ou $. Les noms sont ceux qu'emet le desassembleur, d'ou la coherence
; entre une source ecrite ici et un desassemblage relu la-bas.

; --- Registres et zones de la RAM interne (00h-0FFh) ---------------------------
txtbas: equ 0CBH ; TEXT.BAS courant
datbas: equ 0CEH ; DATA.BAS courant
basptr: equ 0D1H ; POINTEUR (3 octets) vers la zone de travail de l'interpreteur BASIC. A NE PAS CONFONDRE avec baswrk = 0BFD0Eh, qui est la zone elle-meme : ce nom-la vient du listing de E. Kako (register.lst, 1990) et sert de verite terrain. Les crochets d'extension du BASIC sont en [(basptr)+090h] et [(basptr)+093h]
bl:     equ 0D4H ; registre BL / BX bas
bh:     equ 0D5H ; registre BH / BX haut
cl:     equ 0D6H ; registre CL / CX bas
ch:     equ 0D7H ; registre CH / CX haut
dl:     equ 0D8H ; registre DL / DX bas
dh:     equ 0D9H ; registre DH / DX haut
si:     equ 0DAH ; pointeur source (3 octets)
di:     equ 0DDH ; pointeur destination (3 octets)
iocsw:  equ 0E6H ; zone de travail IOCS : recopie du pointeur [0BFD17h] (3 octets) (manuel technique, IOCS Special Technique p85-86)
brkmsk: equ 0EAH ; masque de la touche BREAK
iisr:   equ 0EBH ; Interrupt In-Service Register : le bit vaut 1 pendant l'execution de la routine d'interruption ; bits 0-6 : timer rapide, timer lent, clavier, touche ON, emission SIO, reception SIO, batterie faible, bit 7 = instruction IR (manuel technique p93)
bp_ram: equ 0ECH ; base pointer RAM interne
px:     equ 0EDH ; pointeur auxiliaire PX
py:     equ 0EEH ; pointeur auxiliaire PY
amc:    equ 0EFH ; Address Modify Control : bit 7 AME autorise la modification d'adresse, bits 5-0 AM5-AM0 donnent la capacite de la carte RAM cote CE0 en code thermometre (000000 = 2 Ko, 000001 = 4, 000011 = 8, 000111 = 16, 001111 = 32, 011111 = 64, 111111 = 128 Ko). La derniere adresse de CE0 est toujours xFFFFh : c'est pourquoi une RAM plus petite est calee en HAUT de sa zone. Lecture/ecriture (manuel CPU p8-9)
ko:     equ 0F0H ; Key Output Buffer bas (KOL) : pilote les pins KO0-KO7, un bit par pin, 1 = niveau haut ; strobe clavier. Lecture/ecriture (manuel CPU p9)
koh:    equ 0F1H ; Key Output Buffer haut (KOH) : pilote les pins KO8-KO15. Lecture/ecriture (manuel CPU p9-10)
ki:     equ 0F2H ; Key Input Buffer (KI) : etat des pins KI0-KI7, 1 = niveau haut ; lecture du clavier. LECTURE SEULE (manuel CPU p10)
eol:    equ 0F3H ; E Port Output Buffer bas (EOL) : pilote les pins E0-E7, port d'E/S general. Lecture/ecriture (manuel CPU p10)
eoh:    equ 0F4H ; E Port Output Buffer haut (EOH) : pilote les pins E8-E15. Lecture/ecriture (manuel CPU p10)
eil:    equ 0F5H ; E Port Input Buffer bas (EIL) : etat des pins E0-E7. LECTURE SEULE (manuel CPU p11)
eih:    equ 0F6H ; E Port Input Buffer haut (EIH) : etat des pins E8-E15. LECTURE SEULE (manuel CPU p11)
ucr:    equ 0F7H ; UART Control Register : bit 7 BOE (break : force 0 sur TXD), bits 6-4 debit (0 arrete ET REINITIALISE l UART, 1 300, 2 600, 3 1200, 4 2400, 5 4800, 6 9600, 7 19200 bps), bits 3-2 parite (00 paire, 01 impaire, 1x aucune), bit 1 longueur (0 : 8 bits, 1 : 7), bit 0 stop (0 : 1 bit, 1 : 2). 068h = 9600 8N1. Lecture/ecriture (manuel CPU p11-12)
usr:    equ 0F8H ; UART Status Register : bit 5 RXR caractere recu, bit 4 TXE emetteur au repos, bit 3 TXR tampon d'emission libre, bit 2 FE erreur de trame, bit 1 OE surcharge, bit 0 PE erreur de parite. RXR et TXR alimentent les bits RXRI/TXRI de l ISR. L horloge de l UART vient de la CG principale : elle est ARRETEE en HALT et OFF, une reception ne peut donc pas reveiller la machine. LECTURE SEULE (manuel CPU p12)
rxd:    equ 0F9H ; UART Receive Buffer : le caractere recu ; le lire remet RXR a zero. LECTURE SEULE (manuel CPU p12-14)
txd:    equ 0FAH ; UART Transmit Buffer : le caractere a emettre ; peut etre ecrit pendant l'emission du precedent, TXR dit si le tampon est libre. ECRITURE SEULE (manuel CPU p14-15)
imr:    equ 0FBH ; Interrupt Mask Register : bit 7 IRM masque general, bit 6 EXM interruption EXTERNE (pin IRQ ; sur PC-E500 ce pin est cable au controleur de batterie, d'ou 'batterie faible' cote machine), bit 5 RXRM reception SIO, bit 4 TXRM emission SIO, bit 3 ONKM touche ON, bit 2 KEYM clavier, bit 1 STM timer secondes, bit 0 MTM timer millisecondes ; 0 interdit, 1 autorise. Une interruption empile l'IMR et met le bit 7 a 0. Lecture/ecriture (manuel CPU p15-16)
isr:    equ 0FCH ; Interrupt Status Register : memes bits 6-0 que l'IMR (bit 6 EXI = interruption EXTERNE), pas de bit 7. La demande met le bit a 1, ou il RESTE jusqu'a ce que le logiciel y ecrive 0. Le handler de la ROM lit (isr) ET (imr) puis saute au vecteur logiciel de 0BFCC6h+3n. Lecture/ecriture (manuel CPU p16, p37)
scr:    equ 0FDH ; System Control Register : bit 7 ISE autorise l'interruption externe (pin IRQ) a reveiller d'un HALT/OFF, bits 6-4 pilotent les pins CO/CI de la cassette (bas, haut, 2 kHz, 4 kHz, et autorisation de l'entree), bit 3 VDDC niveau VDD (sur SC62015B01, 1 arrete la sub-CG), bit 2 STS periode du timer secondes (0 : 0,5 s, 1 : 2 s), bit 1 MTS periode du timer millisecondes (0 : 4 ms, 1 : 16 ms), bit 0 DISC synchronisation de l'affichage. Lecture/ecriture (manuel CPU p17-19)
lcc:    equ 0FEH ; LCD Contrast Control : bits 7-3 contraste sur 32 crans, bit 2 KSD inhibe le strobe clavier (tous les KO au niveau bas), bit 1 STCL et bit 0 MTCL remettent a zero le timer secondes / millisecondes lors d'un TCL. Lecture/ecriture (manuel CPU p20)
ssr:    equ 0FFH ; System Status Register : bit 3 ONK touche ON enfoncee, bit 2 RSF (1 : on sort d'un HALT/OFF, 0 : le pin RESET a ete active), bit 1 CI entree cassette, bit 0 TEST entree de test. LECTURE SEULE (manuel CPU p20-21)

; --- Adresses systeme et vecteurs (20 bits) -----------------------------------
lcd_cmd_2000:       equ 02000H  ; meme registre que lcd_cmd, vu en 002000h : les deux bases ne different que du bit 15
lcd_data_2000:      equ 02002H  ; meme registre que lcd_data, vu en 002002h : les deux bases ne different que du bit 15
lcd1_cmd_2000:      equ 02004H  ; meme registre que lcd1_cmd, vu en 002004h : les deux bases ne different que du bit 15 ; c'est la base que documente La Feuille du Sharp n.9, Voyage au coeur de l'ecran (A. Hansen), et celle qu'emploient S3EXT et ROUTINES.SHA
lcd1_stat_2000:     equ 02005H  ; meme registre que lcd1_stat, vu en 002005h : les deux bases ne different que du bit 15
lcd1_data_2000:     equ 02006H  ; meme registre que lcd1_data, vu en 002006h : les deux bases ne different que du bit 15
lcd1_read_2000:     equ 02007H  ; meme registre que lcd1_read, vu en 002007h : les deux bases ne different que du bit 15
lcd2_cmd_2000:      equ 02008H  ; meme registre que lcd2_cmd, vu en 002008h : les deux bases ne different que du bit 15
lcd2_stat_2000:     equ 02009H  ; meme registre que lcd2_stat, vu en 002009h : les deux bases ne different que du bit 15
lcd2_data_2000:     equ 0200AH  ; meme registre que lcd2_data, vu en 00200Ah : les deux bases ne different que du bit 15
lcd2_read_2000:     equ 0200BH  ; meme registre que lcd2_read, vu en 00200Bh : les deux bases ne different que du bit 15
lcd_cmd:            equ 0A000H  ; LCD, commande des DEUX controleurs a la fois : rom83/rom53 y font l'initialisation et l'extinction (17 ecritures), vogue y ecrit sa commande avant de streamer vers lcd1_data et lcd2_data
lcd_data:           equ 0A002H  ; LCD, donnees vers les deux controleurs a la fois
lcd1_cmd:           equ 0A004H  ; HD61202 IC-6 (moitie gauche, 120 colonnes), commande : 03Eh/03Fh eteint-allume, 0C0h+adresse de depart, 0B8h+page (adresse X, 0-7), 040h+adresse Y (0-63) ; cf. La Feuille du Sharp n.9, Voyage au coeur de l'ecran (A. Hansen)
lcd1_stat:          equ 0A005H  ; HD61202 IC-6, lecture des statuts : bit 7 BUSY, bit 5 ON/OFF, bit 4 RESET
lcd1_data:          equ 0A006H  ; HD61202 IC-6, ecriture d'un octet dans la RAM d'affichage ; l'adresse s'incremente apres chaque acces
lcd1_read:          equ 0A007H  ; HD61202 IC-6, lecture d'un octet de la RAM d'affichage
lcd2_cmd:           equ 0A008H  ; HD61202 IC-5 (moitie droite, 120 colonnes), commande ; memes codes que lcd1_cmd
lcd2_stat:          equ 0A009H  ; HD61202 IC-5, lecture des statuts
lcd2_data:          equ 0A00AH  ; HD61202 IC-5, ecriture d'un octet dans la RAM d'affichage
lcd2_read:          equ 0A00BH  ; HD61202 IC-5, lecture d'un octet de la RAM d'affichage
s3_top:             equ 0BFC09H ; lead address du slot 2 = lecteur S3: (3 octets ; manuel technique, Parameter of memory block device)
s3_cap:             equ 0BFC0CH ; capacite du slot 2 (S3:) en blocs de 2 Ko (2 octets ; manuel technique, Parameter of memory block device)
s2_top:             equ 0BFC0FH ; lead address du slot 1 = lecteur S2:, 040000h sur PC-E500S (3 octets ; manuel technique, Parameter of memory block device)
s2_cap:             equ 0BFC12H ; capacite du slot 1 (S2:) en blocs de 2 Ko (2 octets ; manuel technique, Parameter of memory block device)
s1_top:             equ 0BFC15H ; top of S1 (nom et libelle de REGISTER.ASM) ; lead address du slot 0 = lecteur S1:, 080000h sur PC-E500S (3 octets ; manuel technique, Parameter of memory block device)
s1_cap:             equ 0BFC18H ; capacite du slot 0 (S1:) en blocs de 2 Ko (2 octets ; manuel technique, Parameter of memory block device)
scrn_crsr_x:        equ 0BFC27H ; X du curseur du peripherique stdo:/scrn:
scrn_crsr_y:        equ 0BFC28H ; Y du curseur du peripherique stdo:/scrn:
ctrl_disp:          equ 0BFC29H ; code de controle affiche au lieu d'etre execute (bit 6)
linprn:             equ 0BFC2AH ; motif de points du trait et du remplissage de rectangle, 16 points (2 octets) ; employe par les commandes 04Eh line_draw et 04Fh box_fill du device 0. ATTENTION : le manuel se contredit sur ce nom - la liste des parametres (p42) ecrit linprn, la description des commandes (p38) ecrit linptn ; la liste, qui definit le champ, fait autorite
keytbl_1b:          equ 0BFC2DH ; pointeur table conversion clavier, code 1 octet (3 o, table de 62 o)
keytbl_2b:          equ 0BFC30H ; pointeur table conversion clavier, code 2 octets (3 o)
keytbl_1b_shift:    equ 0BFC33H ; pointeur table conversion clavier SHIFT, code 1 octet (3 o)
keytbl_2b_shift:    equ 0BFC36H ; pointeur table conversion clavier SHIFT, code 2 octets (3 o)
keytbl_1b_ctrl:     equ 0BFC39H ; pointeur table conversion clavier CTRL, code 1 octet (3 o)
keytbl_2b_ctrl:     equ 0BFC3CH ; pointeur table conversion clavier CTRL, code 2 octets (3 o)
funckey_flag:       equ 0BFC3FH ; bit 2 = affichage des touches de fonction interdit
key_hook1:          equ 0BFC41H ; hook de la routine de traitement clavier (3 o)
funckey_slot:       equ 0BFC45H ; numero de slot portant le fichier FUNCKEY (0 = S1:)
funckey_name:       equ 0BFC46H ; nom du fichier portant les touches de fonction (BFC46-BFC51)
font_00_1f:         equ 0BFC87H ; adresse de la police des caracteres 00h-1Fh (3 o, 6 octets par caractere)
font_80_9f:         equ 0BFC8AH ; adresse de la police des caracteres 80h-9Fh (3 o)
font_e0_ff:         equ 0BFC8DH ; adresse de la police des caracteres E0h-FFh, 32 glyphes (3 o ; le resolveur 0F2418h borne par cmp a,0E0h)
font_20_7f:         equ 0BFC90H ; adresse de la police des caracteres 20h-7Fh, l'ASCII (3 o)
font_a0_df:         equ 0BFC93H ; adresse de la police des caracteres A0h-DFh, 64 glyphes (3 o ; et non A0h-CFh comme le dit le manuel)
dotsop:             equ 0BFC96H ; operation sur le point deja affiche : 0 allume, 1 efface, 2 inverse
lcd_crsr_x:         equ 0BFC9BH ; X du curseur ecran
lcd_crsr_y:         equ 0BFC9CH ; Y du curseur ecran
lcd_width:          equ 0BFC9DH ; nombre de colonnes affichables
lcd_height:         equ 0BFC9EH ; nombre de lignes affichables
lcd_mode:           equ 0BFCA1H ; mode d'affichage : bit 6 = video inverse
d_link:             equ 0BFCA2H ; device link pointer / IOCSH
repeat_wait:        equ 0BFCBAH ; delai avant repetition d'une touche (unite 16 ms)
repeat_pitch:       equ 0BFCBBH ; intervalle entre deux repetitions (unite 16 ms)
apo_time:           equ 0BFCBCH ; delai d'extinction automatique (2 o, bas puis haut, unite 0,5 s)
softint:            equ 0BFCBEH ; bit 7 = break, bit 6 = batterie faible
keyrep:             equ 0BFCBFH ; bit 7 = repetition active, bit 4 = clic touche
keymtx_tbl:         equ 0BFCC0H ; adresse de la table code materiel -> code matrice clavier (3 o)
key_hook2:          equ 0BFCC3H ; hook de la routine de traitement clavier (3 o)
intv_ftimer:        equ 0BFCC6H ; vecteur interruption timer principal, ISR/IMR bit 0 MTM ; balayage du clavier, touche BREAK comprise (manuel technique, List of interrupt factor p91-92)
intv_stimer:        equ 0BFCC9H ; vecteur interruption timer lent, ISR/IMR bit 1 STM ; clignotement du curseur (manuel technique, List of interrupt factor p91-92)
keyvct:             equ 0BFCCCH ; vecteur interruption clavier, ISR/IMR bit 2 KEYM ; non employee par le systeme ; se declenche quand un port K10-K17 passe a 1, soit (kil) non nul (manuel technique, List of interrupt factor p91-92)
intv_onkey:         equ 0BFCCFH ; vecteur interruption touche ON, ISR/IMR bit 3 ONKM ; non employee par le systeme (manuel technique, List of interrupt factor p91-92)
intv_sio_tx:        equ 0BFCD2H ; vecteur interruption emission SIO, ISR/IMR bit 4 TXRM ; non employee par le systeme ; se declencherait a la fin de l'emission d'un octet (manuel technique, List of interrupt factor p91-92)
intv_sio_rx:        equ 0BFCD5H ; vecteur interruption reception SIO, ISR/IMR bit 5 RXRM ; reception d'un octet SIO terminee (manuel technique, List of interrupt factor p91-92)
intv_ext:           equ 0BFCD8H ; vecteur interruption externe, ISR/IMR bit 6 EXM ; BATTERIE FAIBLE : l'interruption exterieure est cablee au controleur de batterie de la machine (manuel technique, List of interrupt factor p91-92)
intv_soft:          equ 0BFCDBH ; vecteur interruption logicielle : instruction IR, ISR/IMR bit 7 IRM ; non employee par le systeme ; declenchee par l'instruction IR (manuel technique, List of interrupt factor p91-92)
s1_btm:             equ 0BFCDEH ; bottom of S1 (nom et libelle de REGISTER.ASM) ; le manuel dit "last address of slot 0 (S1:) + 1" et La Feuille du Sharp en fait le pointeur de la 1re zone de travail, la pile utilisateur U : trois lectures d'une meme frontiere, la fin de la zone de fichiers de S1: ou commencent les zones de travail
swork:              equ 0BFCE1H ; pointeur de zone de travail : pile systeme S ; taille de la zone U = [0BFCE1h] - [0BFCDEh]
baswrk:             equ 0BFD0EH ; BASIC work address -- la ZONE de travail, en memoire EXTERNE. Nom repris du listing de E. Kako (register.lst, 1990), ou il est declare baswrk: equ 0bfd0eh. A NE PAS CONFONDRE avec basptr = 0D1h, le POINTEUR en RAM interne : un mv x,(baswrk) serait tronque a 8 bits par l assembleur, sans le moindre avertissement
iocswrk:            equ 0BFD17H ; pointeur de zone de travail : IOCS ; debut de la zone de travail IOCS ; elle s'etend jusqu'a [0BFD1Ah] et fait environ 246h octets ; ce pointeur est recopie en RAM interne (iocsw) (manuel technique, IOCS Special Technique p85-86)
usrwrk:             equ 0BFD1AH ; machine language area ; fin de la zone de travail IOCS et debut de la zone langage machine de l'utilisateur (manuel technique, IOCS Special Technique p85-86)
sio_timer:          equ 0BFD31H ; minuterie d'erreur SIO, 2 octets : n x 0,5 s ; 0FFFFh = sans limite (defaut) (manuel technique, Parameter Work du driver SIO p53)
sio_baud:           equ 0BFD33H ; reglage de la liaison SIO : bits 6-4 = vitesse (001 300, 010 600, 011 1200, 100 2400, 101 4800, 110 9600 bauds ; 000 aucune), bits 3-2 = parite (00 paire, 01 impaire, 1x aucune), bit 1 = longueur (0 : 8 bits, 1 : 7), bit 0 = bits d'arret (0 : 1, 1 : 2) ; defaut 03Ch = 1200 bauds, sans parite, 8 bits, 1 stop. Apres modification, appeler la commande 043h du device 2 (manuel technique, Parameter Work du driver SIO p53)
sio_setup:          equ 0BFD34H ; reglage du protocole SIO : bit 6 = emettre l'octet [0BFD61h] a l'ouverture, bit 4 = emettre [0BFD62h] a la fermeture, bit 2 = XON/XOFF en reception, bit 1 = XON/XOFF en emission ; defaut 021h (manuel technique, Parameter Work du driver SIO p53)
sio_rx_port_cond:   equ 0BFD35H ; SIO receive port condition : ce qui CONDITIONNE la reception. bit 2 CS = 1 : ne prendre la donnee que si le signal CS est haut, l'ignorer sinon ; bit 1 CD = 1 : idem sur CD ; 0 = don't care. Defaut 002h. Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>)
sio_rx_port_ctrl:   equ 0BFD36H ; SIO receive port control : ce que le Sharp FAIT de ses sorties quand le tampon de reception est plein. bit 6 ER = 0 : ER passe bas ; bit 5 RR = 0 : RR passe bas ; bit 4 RS = 0 : RS passe bas ; 1 = don't care. Defaut 0DFh. Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>)
sio_tx_port_cond:   equ 0BFD37H ; SIO send port condition : ce qui CONDITIONNE l'emission. bit 2 CS = 1 : n'emettre que si CS est haut, attendre sinon ; bit 1 CD = 1 : idem sur CD ; 0 = don't care. Defaut 004h. ATTENTION, c'est le reglage qui explique les I/O ERROR en emission : sans RTS cote PC, le CS du Sharp reste bas et son XOFF ne part jamais. Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>)
sio_tx_port_ctrl:   equ 0BFD38H ; SIO send port control : ce que le Sharp fait de ses sorties autour d'un bloc emis. bit 6 ER, bit 5 RR, bit 4 RS = 1 : le signal passe haut avant le transfert du bloc et bas apres ; 0 = don't care. Defaut 050h. Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>)
sio_tx_delay:       equ 0BFD39H ; SIO send delay : attente avant ou apres un bloc emis, <000h-0FFh> x 2 ms. Defaut 001h (2 ms). Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>)
sio_crlf:           equ 0BFD3BH ; SIO crlf : delimiteur externe converti en delimiteur interne (00Dh + 00Ah). bits 1-0 : 00 aucun, 01 = 00Dh, 10 = 00Ah, 11 = 00Dh + 00Ah. Defaut 001h. Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>)
sio_eof:            equ 0BFD3CH ; SIO eof code : code de fin de fichier. Defaut 01Ah. Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>)
sio_open_wait:      equ 0BFD40H ; SIO open close wait : attente de n x 0,5 ms juste apres l'ouverture et juste avant la fermeture du port. Defaut 004h (20 ms). Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>)
sio_open_port_ctrl: equ 0BFD41H ; SIO open port control : etat des sorties a l'ouverture du port. Defaut 041h. Technical Reference Manual PC-E500 p54 (releve du projet << Sharp transfert serial >>)
sio_open_data:      equ 0BFD61H ; octet emis a l'ouverture du port SIO, si le bit 6 de [0BFD34h] est arme (manuel technique, Parameter Work du driver SIO p53)
sio_close_data:     equ 0BFD62H ; octet emis a la fermeture du port SIO, si le bit 4 de [0BFD34h] est arme (manuel technique, Parameter Work du driver SIO p53)
drv_off:            equ 0E01C2H ; extinction (simuler OFF) : releve sur rom83, aucune table de l'image ne le designe
secure_work_call:   equ 0FFFD8H ; reservation de zone de travail : POKE en 0BFE03h l'ADRESSE DU POINTEUR de la zone ; reservation d'une zone de travail : [0BFE03h] = adresse du pointeur a deplacer (3 octets), [0BFE06h] = taille voulue (3 octets), puis CALL ; provoque un petit reset sans dommage (manuel technique, IOCS Special Technique p85-86)
iocs_call3:         equ 0FFFDCH ; appel IOCS a trois registres seulement : POKE &BFE00,cl,ch,il puis CALL &FFFDC (manuel technique p31 ; exemple donne : POKE &HBFE00,8,0,&H41 = device 8 systeme, lecteur 0, commande 41h, qui eteint la machine). ATTENTION : la ROM emploie aussi 0BFE00h comme octet de drapeaux prive pour BASIC, TEXT, DELETE et RENUM (48 acces, bits 0 a 7 ; dans RENUM les bits 5-4 numerotent une des trois passes de balayage) : la zone est un brouillon, pas une variable persistante
fcs_call:           equ 0FFFE4H ; FCS call entry
iocs_call:          equ 0FFFE8H ; IOCS call entry

; --- Codes de fonction FCS (IL) -----------------------------------------------
; (les points d'entree fcs_call=0FFFE4H et iocs_call=0FFFE8H figurent ci-dessus)
fcs_create_file:          equ 00H   ; creation d'un fichier, ouvert en lecture-ecriture (X = nom de fichier, termine par 000h, a
fcs_open_file:            equ 01H   ; ouverture d'un fichier existant (X = nom de fichier, termine par 000h, a = 1 lecture, 2 ec
fcs_close_file:           equ 02H   ; fermeture d'un fichier ((cl) = handle) : le repertoire et la FAT sont reecrits, le handle
fcs_read_block:           equ 03H   ; lecture d'un bloc ((cl) = handle, X = destination, Y = nombre d'octets, a bit 0 = 0 la fin
fcs_write_block:          equ 04H   ; ecriture d'un bloc ((cl) = handle, X = source, Y = nombre d'octets ; retour X = adresse su
fcs_read_byte:            equ 05H   ; lecture d'un octet ((cl) = handle, a bit 0 = 0 la fin de fichier est le code 01Ah, 1 c'est
fcs_write_byte:           equ 06H   ; ecriture d'un octet ((cl) = handle, a = donnee ; retour b = nombre d'octets ecrits)
fcs_verify_file:          equ 07H   ; verification d'un fichier : relit n octets et les compare a la memoire ((cl) = handle, X =
fcs_read_byte_nd:         equ 08H   ; lecture non destructive d'un octet : le pointeur ne bouge pas ((cl) = handle, a bit 0 = co
fcs_seek:                 equ 09H   ; deplacement du pointeur de fichier ((cl) = handle, (si) = deplacement sur 3 octets, a = 0
fcs_file_info:            equ 0AH   ; informations d'un fichier ouvert ((cl) = handle). a = 0 : retour a = attribut d'ouverture,
fcs_set_dir:              equ 0BH   ; lecture ou ecriture des informations de repertoire d'un fichier (a = 0 lire, 1 ecrire ; X
fcs_find_file:            equ 0CH   ; recherche du nom de fichier correspondant, jokers admis ((bx) = numero de repertoire de de
fcs_rename_file:          equ 0DH   ; renommage d'un fichier (X = ancien nom, Y = nouveau nom, tous deux termines par 000h)
fcs_delete_file:          equ 0EH   ; suppression d'un fichier (X = nom de fichier, termine par 000h)
fcs_free_space:           equ 0FH   ; capacite libre d'un lecteur (a = 0, X = nom de lecteur ; retour (si) = capacite libre sur
fcs_init_fcs:             equ 10H   ; initialisation du file control system (a = 000h zone de travail seule, 001h libere tous le

; --- Codes de fonction IOCS communs (IL) --------------------------------------
iocs_find_drive:          equ 00H   ; recherche du device et du lecteur d'apres le nom de lecteur (X = adresse du nom ; retour (
iocs_header_addr:         equ 01H   ; adresse du header d'apres le numero de device ((cl) = device ; retour X = adresse du heade
iocs_header_next:         equ 02H   ; adresse du header suivant ((cl) = device, X = header de depart ; retour X = header trouve)
iocs_drive_name:          equ 03H   ; nom de lecteur d'apres device et lecteur ((cl) = device, (ch) = lecteur, X = zone de 6 oct
iocs_format_drive:        equ 04H   ; formatage du device designe par le nom de lecteur (X = nom de lecteur suivi de la chaine d
iocs_init_all:            equ 05H   ; initialisation de tous les devices installes (a = niveau : 0 all reset, 1 reset, 2 off, 3
iocs_char_open:           equ 08H   ; ouverture du peripherique caractere (X = nom de fichier sur 12 octets, a = mode 1 lecture,
iocs_char_close:          equ 09H   ; fermeture du peripherique caractere ((cl) et (ch) seuls)
iocs_read_block:          equ 0AH   ; lecture d'un bloc (X = destination, Y = nombre d'octets ; retour X = adresse suivante, Y =
iocs_write_block:         equ 0BH   ; ecriture d'un bloc (X = source, Y = nombre d'octets ; retour X = adresse suivante, Y = oct
iocs_read_byte:           equ 0CH   ; lecture d'un octet (retour a = donnee)
iocs_write_byte:          equ 0DH   ; ecriture d'un octet (a = donnee)
iocs_read_byte_nd:        equ 0EH   ; lecture non destructive d'un octet : la donnee est rendue sans avancer le pointeur (retour
iocs_media_check:         equ 10H   ; verification du media
iocs_media_param:         equ 11H   ; adresse du bloc de parametres du media (retour X = adresse du bloc, qui decrit la geometri
iocs_read_sector:         equ 12H   ; lecture de secteurs ((bx) = premier secteur, (dx) = nombre de secteurs, X = destination ;
iocs_write_sector:        equ 13H   ; ecriture de secteurs ((bx) = premier secteur, (dx) = nombre de secteurs, X = source ; reto
iocs_write_verify_sector: equ 14H   ; ecriture puis verification de secteurs ((bx) = premier secteur, (dx) = nombre de secteurs,
iocs_verify_sector:       equ 15H   ; verification de secteurs ((bx) = premier secteur, (dx) = nombre de secteurs, X = donnees a
iocs_status_read:         equ 16H   ; lecture de l'etat d'un lecteur (retour ba bit 0 = 1 lecteur protege en ecriture ; le manue
iocs_sector_addr:         equ 17H   ; adresse d'un secteur ((bx) = numero de secteur ; retour X = adresse du secteur, (cx) = tai
iocs_create_file:         equ 20H   ; creation d'un fichier (peripherique special ; memes registres que la fonction FCS 000h, av
iocs_open_file:           equ 21H   ; ouverture d'un fichier (peripherique special ; memes registres que la fonction FCS 001h, a
iocs_close_file:          equ 22H   ; fermeture d'un fichier (peripherique special ; memes registres que la fonction FCS 002h, a
iocs_verify_file:         equ 27H   ; verification d'un fichier (peripherique special ; memes registres que la fonction FCS 007h
iocs_seek:                equ 29H   ; deplacement du pointeur de fichier (peripherique special ; memes registres que la fonction
iocs_file_info:           equ 2AH   ; lecture des informations d'un fichier (peripherique special ; memes registres que la fonct
iocs_set_dir:             equ 2BH   ; changement des informations de repertoire (peripherique special ; memes registres que la f
iocs_find_file:           equ 2CH   ; recherche du nom de fichier correspondant (peripherique special ; memes registres que la f
iocs_rename_file:         equ 2DH   ; renommage d'un fichier (peripherique special ; memes registres que la fonction FCS 00Dh, a
iocs_delete_file:         equ 2EH   ; suppression d'un fichier (peripherique special ; memes registres que la fonction FCS 00Eh,
iocs_free_space:          equ 2FH   ; lecture de la capacite libre du lecteur (peripherique special ; memes registres que la fon
iocs_format:              equ 3FH   ; formatage du media, commun a tous les devices
iocs_init_device:         equ 40H   ; initialisation du device (A = niveau : 0 all reset, 1 reset, 2 off, 3 on)

; --- Numeros de device IOCS (a placer dans (cl) = 0D6h) ------------------------
dev_display:      equ 0H    ; device 0 (STDO:/SCRN:)
dev_key:          equ 1H    ; device 1 (STDI:/KYBD:)
dev_sio:          equ 2H    ; device 2 (COM:)
dev_printer:      equ 3H    ; device 3 (STDL:/PRN:)
dev_tape:         equ 4H    ; device 4 (CAS:)
dev_memfile:      equ 5H    ; device 5 (E:/F:/G:)
dev_memcard:      equ 6H    ; device 6 (S1:/S2:/S3:)
dev_fdd:          equ 7H    ; device 7 (X:/Y:)
dev_system:       equ 8H    ; device 8 (SYSTM:)
dev_function:     equ 9H    ; device 9 ()

; --- Codes de fonction IOCS par device (IL >= 41h) ----------------------------
; device 0 : display (STDO:/SCRN:)
display_char_out_at:          equ 41H   ; affichage d'un caractere a une position quelconque ((bl) = X, (bh) = Y, a = cara
display_chars_out_at:         equ 42H   ; affichage d'une chaine a une position quelconque ((bl) = X, (bh) = Y, X = adress
display_set_cursor:           equ 44H   ; positionnement du curseur, sans changer sa forme ((bl) = X, (bh) = Y ; cy=1 si h
display_cursor_type:          equ 45H   ; forme du curseur (a : bit 5 = curseur affiche, bit 3 = clignotement, bits 2-0 =
display_symbol_disp:          equ 46H   ; allumage ou extinction des symboles de l'ecran (a = motif, un bit a 1 allume ; (
display_scroll_up:            equ 47H   ; defilement vers le haut de n lignes ((bx) = 00000h, a = nombre de lignes)
display_scroll_down:          equ 48H   ; defilement vers le bas de n lignes ((bx) = 00000h, a = nombre de lignes)
display_clear_line:           equ 49H   ; effacement d'une ligne ((bh) = ordonnee de la ligne)
display_dot8_write:           equ 4AH   ; affichage d'un motif de 8 points, en colonne vers le bas (X, Y = coin superieur,
display_dot8_read:            equ 4BH   ; lecture d'un motif de 8 points, en colonne vers le bas (X, Y = coin superieur ;
display_dot_write:            equ 4CH   ; affichage d'un point (X = abscisse, Y = ordonnee, a = 0 allumer, 1 eteindre, 2 i
display_dot_read:             equ 4DH   ; lecture d'un point (X = abscisse, Y = ordonnee ; retour a = 1 si le point est al
display_line_draw:            equ 4EH   ; trace d'une ligne (X,Y = point de depart, (bx),(dx) = point d'arrivee ; le mode
display_box_fill:             equ 4FH   ; remplissage d'un rectangle defini par les deux bouts d'une diagonale (X,Y et (bx
display_disp_state:           equ 50H   ; allumage ou extinction de l'affichage (a = 0 eteint, 1 allume)
display_clear_disp:           equ 51H   ; effacement complet de l'affichage ((cx) = 0000h)
display_clear_from:           equ 52H   ; effacement a partir d'une position (a = nombre de caracteres, (bl) = X, (bh) = Y
display_insert_line:          equ 54H   ; insertion de n lignes ((bh) = Y de depart, a = nombre de lignes)
display_pattern_read:         equ 55H   ; lecture du motif de points d'une ligne vers la memoire externe ((bh) = ordonnee,
display_pattern_write:        equ 56H   ; ecriture du motif de points d'une ligne depuis la memoire externe ((bh) = ordonn
display_disp_no_clip:         equ 57H   ; affichage d'un caractere SANS tenir compte de la fenetre d'affichage ((bl) = X,
display_guide_line:           equ 58H   ; affichage de chaines encadrees d'un guide ((bl) = X, (bh) = Y, a = nombre de cha

; device 1 : key (STDI:/KYBD:)
key_conv_table_set:           equ 3FH   ; installe les SIX pointeurs de tables de conversion code matriciel -> code caract
key_init_driver:              equ 40H   ; initialisation du driver clavier (a = niveau : 0 all reset, 1 reset, 2 off, 3 on
key_matrix_read:              equ 41H   ; lecture du code matrice dans le tampon de balayage (retour a : bit 7 = 1 touche
key_matrix_read_nd:           equ 42H   ; lecture non destructive du code matrice : meme rendu que 041h, sans consommer la
key_key_read:                 equ 43H   ; lecture d'une touche, apres traitement des touches SHIFT et CTRL (a bit 7 = 0 re
key_key_buffer_set:           equ 44H   ; ecriture de donnees dans le tampon clavier (X = adresse des donnees, a = nombre
key_buffer_clear:             equ 45H   ; vidage du tampon de balayage et du tampon clavier
key_fkey_display:             equ 46H   ; affichage ou effacement des libelles de touches de fonction (retour cy=1 si l'ec

; device 2 : sio (COM:)
sio_byte_out:                 equ 41H   ; sortie directe d'un octet
sio_byte_in:                  equ 42H   ; entree directe d'un octet
sio_set_hardware:             equ 43H   ; reglage du materiel et du format d'apres la zone de travail IOCS
sio_rs_high:                  equ 44H   ; port RS force a l'etat haut
sio_rs_low:                   equ 45H   ; port RS force a l'etat bas
sio_rr_high:                  equ 46H   ; port RR force a l'etat haut
sio_rr_low:                   equ 47H   ; port RR force a l'etat bas
sio_er_high:                  equ 48H   ; port ER force a l'etat haut
sio_er_low:                   equ 49H   ; port ER force a l'etat bas
sio_read_cs:                  equ 4AH   ; lecture du port CS (retour cy=0 etat bas, cy=1 etat haut)
sio_read_cd:                  equ 4BH   ; lecture du port CD (retour cy=0 etat bas, cy=1 etat haut)

; device 3 : printer (STDL:/PRN:)
printer_print_out:            equ 41H   ; envoi d'un octet a l'imprimante (a = donnee ; cy=1 en erreur)
printer_print_pos:            equ 42H   ; position courante de la tete d'impression (retour a = position)
printer_printer_check:        equ 43H   ; test de l'imprimante (retour cy=0 : a = type d'imprimante, i = nombre maximal de

; device 4 : tape (CAS:)
tape_data_write:              equ 41H   ; ecriture d'un bloc de donnees sur la bande (X = adresse, Y = taille ; retour X e
tape_data_read:               equ 42H   ; lecture d'un bloc de donnees depuis la bande (X = adresse, Y = taille ; retour X
tape_data_verify:             equ 43H   ; lecture et comparaison d'un bloc de donnees (X = adresse, Y = taille ; retour X
tape_header_write:            equ 44H   ; ecriture du bloc d'en-tete sur la bande (X = adresse du bloc d'en-tete)
tape_header_read:             equ 45H   ; lecture du bloc d'en-tete depuis la bande (X = adresse du bloc d'en-tete)

; device 5 : memfile (E:/F:/G:)

; device 6 : memcard (S1:/S2:/S3:)
memcard_search_phys:          equ 41H   ; adresse physique d'un bloc d'apres son nom ((ch) = slot 0/1/2, X = nom du bloc ;
memcard_block_resize:         equ 42H   ; changement de taille d'un bloc ((ch) = slot, a = numero de pointeur de zone libr
memcard_block_transfer:       equ 43H   ; transfert d'un bloc (X = source, Y = destination, (si) = taille ; retour X et Y
memcard_block_rename:         equ 44H   ; renommage d'un bloc ((ch) = slot, X = ancien nom, Y = nouveau nom ; erreur a = 0
memcard_block_create:         equ 45H   ; creation d'un bloc memoire ((ch) = slot, X = nom ; retour Y = adresse du bloc cr
memcard_block_delete:         equ 46H   ; suppression d'un bloc memoire ((ch) = slot, X = nom ; erreur a = 002h bloc intro
memcard_condense:             equ 47H   ; compactage de l'espace libre des blocs memoire ((ch) = slot)
memcard_block_create_top:     equ 48H   ; creation d'un bloc memoire EN TETE des blocs, propre au PC-E500 ((ch) = slot, X

; device 7 : fdd (X:/Y:)

; device 8 : system (SYSTM:)
system_power_off:             equ 41H   ; extinction : arret du CPU, retour par la touche ON
system_secure_work:           equ 42H   ; redimensionnement d'une zone de travail systeme (X = l'un des 21 pointeurs de 0B
system_basic_exec:            equ 43H   ; execution d'une chaine en code intermediaire BASIC (X = adresse ; a bit0 pas a p
system_code_addr:             equ 45H   ; adresse de traitement d'une instruction d'apres son code intermediaire (a = code

; device 9 : function ()
function_num_ne:              equ 41H   ; comparaison numerique Y<>X (X = (bp)-(bp+14), Y = (bp+15)-(bp+29)); (ch)=1 : add
function_num_lt:              equ 42H   ; comparaison numerique Y<X; (ch)=1 : soustraction (matrice); (ch)=2 : regression
function_num_gt:              equ 43H   ; comparaison numerique Y>X; (ch)=1 : multiplication (matrice)
function_num_eq:              equ 44H   ; comparaison numerique Y=X; (ch)=1 : division (matrice)
function_num_le:              equ 45H   ; comparaison numerique Y<=X; (ch)=1 : inverse (matrice)
function_num_ge:              equ 46H   ; comparaison numerique Y>=X; (ch)=1 : addition d'un scalaire (matrice)
function_add:                 equ 47H   ; addition Y+X -> X (X = (bp)-(bp+14), Y = (bp+15)-(bp+29)); (ch)=1 : soustraction
function_sub:                 equ 48H   ; soustraction Y-X -> X; (ch)=1 : multiplication par un scalaire (matrice)
function_mul:                 equ 49H   ; multiplication Y*X -> X; (ch)=1 : multiplication par X-1 scalaire (matrice)
function_div:                 equ 4AH   ; division Y/X -> X; (ch)=1 : remplacer X par Y (matrice)
function_pow:                 equ 4BH   ; puissance Y^X -> X; (ch)=1 : matrice transposee (matrice)
function_exp:                 equ 4CH   ; exponentielle e^X -> X; (ch)=1 : determinant (resultat dans X) (matrice)
function_sin:                 equ 4DH   ; sinus sinX -> X; (ch)=1 : changement de signe (matrice)
function_cos:                 equ 4EH   ; cosinus cosX -> X; (ch)=1 : carre (matrice)
function_tan:                 equ 4FH   ; tangente tanX -> X; (ch)=1 : ranger X dans M (matrice)
function_asin:                equ 50H   ; arc sinus sin-1X -> X; (ch)=1 : rappeler M dans X (matrice)
function_acos:                equ 51H   ; arc cosinus cos-1X -> X; (ch)=1 : ajouter M et X (matrice)
function_atan:                equ 52H   ; arc tangente tan-1X -> X; (ch)=1 : ranger X dans MA-MZ (matrice)
function_deg:                 equ 53H   ; conversion en degres X->DEG->X; (ch)=1 : rappeler MA-MZ dans X (matrice)
function_dms:                 equ 54H   ; conversion en degres-minutes-secondes X->DMS->X; (ch)=1 : systeme d'equations (m
function_abs:                 equ 55H   ; valeur absolue |X| -> X; (ch)=1 : reste d'un systeme d'equations (matrice)
function_int:                 equ 56H   ; partie entiere intX -> X
function_sgn:                 equ 57H   ; signe sgnX -> X
function_rnd:                 equ 58H   ; arrondi rndX -> X
function_sqr:                 equ 59H   ; racine carree sqrt(X) -> X
function_log:                 equ 5AH   ; logarithme decimal logX -> X
function_ln:                  equ 5BH   ; logarithme neperien lnX -> X
function_str_ne:              equ 70H   ; comparaison de chaines Y<>X
function_str_lt:              equ 71H   ; comparaison de chaines Y<X
function_str_gt:              equ 72H   ; comparaison de chaines Y>X
function_str_eq:              equ 73H   ; comparaison de chaines Y=X
function_str_le:              equ 74H   ; comparaison de chaines Y<=X
function_str_ge:              equ 75H   ; comparaison de chaines Y>=X
function_asc:                 equ 76H   ; ASC : code du 1er caractere d'une chaine
function_chr_s:               equ 77H   ; CHR$ : caractere de code donne
function_str_s:               equ 78H   ; STR$ : nombre converti en chaine
function_val:                 equ 79H   ; VAL : chaine convertie en nombre
function_dec2bin:             equ 7EH   ; conversion decimal -> binaire
function_bin2dec:             equ 7FH   ; conversion binaire -> decimal

; --- Doublons de nom dans les tables source, ignores pour rester univoque ------
;   iocs_read_block  (aussi a 23H)
;   iocs_write_block  (aussi a 24H)
;   iocs_read_byte  (aussi a 25H)
;   iocs_write_byte  (aussi a 26H)
;   iocs_read_byte_nd  (aussi a 28H)
;   system_code_addr  (aussi a 46H)

