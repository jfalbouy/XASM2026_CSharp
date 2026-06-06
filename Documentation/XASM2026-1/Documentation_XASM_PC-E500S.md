# XASM pour Sharp PC-E500S

Guide francais de reference pour l assembleur XASM, le CPU ESR-L / SC62015 et le workflow machine language PC-E500S.

## Portee du document

Ce document rassemble la documentation originale de XASM 1.4, les apports de la version `xasm2026-1` et les elements techniques utiles des manuels Sharp PC-E500S. Il vise une utilisation pratique : ecrire, assembler, verifier et transferer du code machine pour PC-E500S.

| Element | Valeur |
|---|---|
| Outil documente | XASM 1.40 et adaptation `xasm2026-1` |
| Cible CPU | Sharp ESR-L / SC62015 |
| Machine principale | Sharp PC-E500 / PC-E500S |
| Sorties `xasm2026-1` | `.obj`, `.lst`, `.hex`, `.s19`, `.map`, `.d`, `.uu`, dump HxD `.txt` |
| Sources | `XASM - ENGLISH.DOC`, sources XASM, manuels ESR-L et PC-E500/PC-E500S |

## Sommaire

- Vue d ensemble
- Architecture du PC-E500S et du CPU ESR-L
- Syntaxe assembleur XASM
- Directives, macros et assemblage conditionnel
- Labels hierarchiques et organisation des sources
- Ligne de commande et formats de sortie
- Workflow complet avec `xasm2026-1`
- Reference rapide du jeu d instructions
- Erreurs, avertissements et diagnostic
- Annexes et sources consultees

# 1. Vue d ensemble

XASM est un assembleur croise absolu concu pour le developpement en langage machine sur les machines Sharp utilisant le CPU ESR-L, dont la famille PC-E500. Il produit du code positionne a une adresse precise par la directive `ORG`. Contrairement a un assembleur relocatable, il ne gere pas de phase d edition de liens : le programmeur choisit les adresses, les blocs, les fichiers inclus et les formats de sortie.

La version historique XASM 1.40 a ete ecrite en C a partir d une version Turbo Pascal et amelioree par un hachage des symboles. La version `xasm2026-1` conserve ce coeur tout en ajoutant des sorties modernes et quelques facilites de structuration utiles pour des projets plus grands.

| Famille | Role dans le projet |
|---|---|
| XASM 1.40 | Assembleur original : syntaxe, mnemonics ESR-L, directives historiques, labels locaux, macros. |
| `xasm2026-1` | Port maintenu localement : compilation GCC, sorties Intel HEX/S19/MAP/dependances/UU/HxD, directives supplementaires. |
| Manuels Sharp | Description du CPU, de la memoire interne/externe, des registres, de l IOCS et des usages machine language. |

## 1.1 Ce que XASM assemble

- Des instructions ESR-L / SC62015 ecrites avec les mnemonics du manuel CPU Sharp.
- Des directives de controle d assemblage : `ORG`, `END`, `EQU`, `DB`, `DW`, `INCLUDE`, `MACRO`, `IFDEF`, etc.
- Des labels globaux et locaux organises en blocs hierarchiques.
- Des expressions numeriques calculees sur 20 bits, adaptees a l espace d adressage de 1 Mo.
- Des fichiers sources multiples via `INCLUDE`, avec transmission d arguments `@0` a `@9`.

> Note : dans le contexte Sharp, on parle souvent de programme en langage machine. XASM n est pas un compilateur BASIC : c est un assembleur. Il traduit presque directement chaque instruction assembleur en octets machine, avec calcul des adresses et resolution des labels.

# 2. Architecture du PC-E500S et du CPU ESR-L

Le SC62015, aussi appele ESR-L, est un CPU CMOS 8 bits utilise par les pocket computers Sharp de la serie PC-E500. Le manuel CPU decrit un espace memoire externe continu de 1 Mo, des registres de tailles variees et une memoire interne separee de 256 octets dont 236 octets de RAM ordinaire.

| Caracteristique | Description pratique |
|---|---|
| CPU | ESR-L / SC62015, coeur 8 bits oriente pocket computer. |
| Espace externe | 1 Mo adressable. Les pointeurs `X`, `Y`, `U` et `S` sont sur 20 bits. |
| Programme | `PC` 16 bits + registre de page `PS` 4 bits, soit des pages de 64 Ko. |
| Memoire interne | 256 octets separes : `00h` a `EBh` RAM ordinaire, `ECh` a `FFh` registres/pointeurs/ports. |
| Peripheriques integres | UART, ports clavier, ports E, controle LCD, interruptions, horloges. |

## 2.1 Registres principaux

| Registre | Taille | Usage |
|---|---:|---|
| `A` | 8 bits | Accumulateur principal pour arithmetique, logique et transferts octet. |
| `B` | 8 bits | Registre auxiliaire ; combine avec `A` pour former `BA`. |
| `BA` | 16 bits | Registre compose `B:A`, utile pour transferts et calculs 16 bits. |
| `I` | 16 bits | Compteur ; de nombreuses instructions de boucle le decrementent jusqu a zero. |
| `IH` / `IL` | 8 bits chacun | Parties haute et basse du registre `I`. |
| `X`, `Y` | 20 bits | Pointeurs de l espace memoire externe de 1 Mo. |
| `U` | 20 bits | Pile utilisateur, egalement utilisable comme pointeur. |
| `S` | 20 bits | Pile systeme pour appels, retours, interruptions ; utilisable comme pointeur avec prudence. |
| `PC` | 16 bits | Compteur programme dans la page courante. |
| `PS` | 4 bits | Segment/page de programme. |

## 2.2 Memoire interne `00h`-`FFh`

La memoire interne est un espace distinct de la memoire externe. Les modes d adressage internes utilisent `BP`, `PX` et `PY` et des offsets courts. Les octets `ECh` a `FFh` ne sont pas de la RAM ordinaire : ils correspondent a des pointeurs et registres de controle.

| Adresse | Nom | Role |
|---|---|---|
| `00h`-`EBh` | RAM interne | 236 octets ordinaires, souvent utilises comme variables rapides ou registres logiques systeme. |
| `ECh` | `BP` | RAM Base Pointer pour adressage relatif interne. |
| `EDh` | `PX` | Pointeur RAM PX. |
| `EEh` | `PY` | Pointeur RAM PY. |
| `EFh` | `AMC` | Address Modify Control pour cartes RAM. |
| `F0h`-`F2h` | `KOL`/`KOH`/`KI` | Sorties et entree clavier. |
| `F3h`-`F6h` | `EOL`/`EOH`/`EIL`/`EIH` | Ports E. |
| `F7h`-`FAh` | UART | Controle, statut, reception, transmission serie. |
| `FBh`-`FCh` | `IMR`/`ISR` | Masque et statut d interruptions. |
| `FDh`-`FFh` | `SCR`/`LCC`/`SSR` | Controle systeme, contraste LCD, statut systeme. |

> Attention : les adresses internes entre `ECh` et `FFh` pilotent le materiel. Une instruction qui les modifie peut changer le clavier, l UART, les interruptions ou l etat systeme. Toujours isoler ce type de code et restaurer les registres critiques si necessaire.

## 2.3 Espace externe, pages et vecteurs

L espace externe de 1 Mo est adresse par les pointeurs 20 bits. Les programmes, eux, s executent via `PC` 16 bits et `PS` 4 bits : les appels et sauts proches restent dans une page de 64 Ko, tandis que les formes far manipulent aussi le segment.

| Zone | Description |
|---|---|
| `00000h`-`03FFFh` | Zone SH-26 mentionnee dans le manuel CPU, acces plus lent lie au driver LCD historique. |
| `04000h`-`07FFFh` | Zone nouveau driver mentionnee dans le manuel CPU. |
| `FFFFAh`-`FFFFCh` | Vecteur d interruption : 3 octets charges lors d une interruption. |
| `FFFFDh`-`FFFFFh` | Vecteur de reset : 3 octets charges au redemarrage. |

## 2.4 IOCS et appels systeme

Le PC-E500 fournit un IOCS, c est a dire une couche logicielle systeme pour utiliser les peripheriques, les fichiers, l affichage, le clavier, la memoire et l alimentation. Le manuel technique recommande de privilegier ce niveau lorsque la compatibilite compte, et de reserver l acces direct au materiel aux traitements qui exigent une vitesse maximale.

| Niveau | Usage |
|---|---|
| Niveau 2 | Systeme de fichiers et peripheriques vus comme fichiers ; proche de ce qu expose BASIC. |
| Niveau 1 | Commandes de drivers IOCS : affichage, clavier, memoire, peripheriques. |
| Niveau 0 | Acces direct au materiel ; rapide mais moins portable et plus fragile. |

# 3. Syntaxe assembleur XASM

Un fichier source XASM contient une instruction ou directive par ligne et doit se terminer par `END`. La forme generale est : label optionnel suivi de deux-points, instruction optionnelle, operandes separes par des virgules, puis commentaire commencant par un point-virgule.

```asm
LABEL:  INSTRUCTION  OPERANDE1,OPERANDE2   ; commentaire
        INSTRUCTION  OPERANDE
        ; ligne de commentaire
        END
```

| Element | Regle |
|---|---|
| Label | Lettres, chiffres et underscore ; ne commence pas par un chiffre ; 16 caracteres maximum. |
| Casse | Les labels et mnemonics sont traites sans distinction majuscule/minuscule. |
| Separateurs | Espaces et tabulations separent instruction et operandes. |
| Commentaire | Commence par `;` et continue jusqu a la fin de ligne. |
| Fin de fichier | `END` est obligatoire, y compris dans les fichiers inclus. |

## 3.1 Nombres et constantes

Les expressions sont converties en entiers de 20 bits. Selon la directive, seuls les octets bas necessaires sont emis. Le suffixe indique la base ; sans suffixe, le nombre est decimal.

| Notation | Base | Exemple |
|---|---|---|
| `B` ou `b` | Binaire | `0100_1100b` |
| `O` ou `o` | Octal | `377o` |
| `D` ou `d` | Decimal | `1234d` |
| `H` ou `h` | Hexadecimal | `0E000h` |
| `$` en tete | Hexadecimal | `$4C` |
| `_` | Separateur visuel | `1000_0000b` |

## 3.2 Caracteres et chaines

Une constante caractere entre apostrophes vaut le code du dernier caractere. Dans `DB`, `DM`, `DW` et `DP`, une chaine entre apostrophes est developpee caractere par caractere. Pour coder une apostrophe, on l ecrit deux fois.

```asm
DB 'A'              ; emet 41h
DB 'I don''t know'  ; l apostrophe est doublee dans la source
DW 'AB'             ; emet les codes des caracteres selon la directive
```

## 3.3 Operateurs

| Priorite croissante | Operateurs | Sens |
|---:|---|---|
| 1 | `|` | OR binaire |
| 2 | `&` | AND binaire |
| 3 | `%` | Modulo |
| 4 | `+` `-` | Addition, soustraction |
| 5 | `*` `/` | Multiplication, division |
| Max | `+` `-` unaire | Signe unaire en debut d expression ou apres operateur |

## 3.4 Compteur de position

Le symbole `*` represente le compteur de position, c est a dire l adresse courante d assemblage. Il peut etre utilise dans les expressions, par exemple pour calculer une taille ou remplir jusqu a une adresse.

```asm
        ORG 0BF000h
DEBUT:  NOP
TAILLE: EQU *-DEBUT
        DS  0BF100h-*,0
```

# 4. Directives, macros et assemblage conditionnel

| Directive | Forme | Effet |
|---|---|---|
| `ORG` | `ORG expr` | Fixe l adresse de debut ou avance le compteur de position. |
| `END` | `END` | Termine le source ou le fichier inclus. |
| `EQU` | `LABEL: EQU expr` | Affecte une valeur symbolique a un label. |
| `DB` / `DM` | `DB expr[,expr]*` | Emet des octets. |
| `DW` | `DW expr[,expr]*` | Emet des mots 16 bits, octet bas puis haut. |
| `DP` | `DP expr[,expr]*` | Emet des pointeurs/adresses sur 3 octets. |
| `DS` | `DS taille[,valeur]` | Reserve et remplit une zone. |
| `PRE` | `PRE expr` | Emet manuellement un prebyte. |
| `PRE_ON` / `PRE_OFF` | `PRE_ON` / `PRE_OFF` | Active ou desactive la generation automatique de prebyte. |
| `INCLUDE` | `INCLUDE fichier[,arg]*` | Assemble un autre fichier et lui passe des arguments. |
| `MACRO` / `ENDM` | `MACRO nom[,arg]* ... ENDM` | Definit une macro. |
| `DEF` / `UNDEF` | `DEF nom` / `UNDEF nom` | Definit ou retire un symbole conditionnel. |
| `IFDEF` / `IFNDEF` | `IFDEF nom ... ELSE ... ENDIF` | Assemble selon la presence d un symbole. |

> Prebytes : le CPU ESR-L a besoin de prebytes pour certains acces a la RAM interne. XASM peut les generer automatiquement avec `PRE_ON`, mais le mode par defaut historique est `PRE_OFF`. Le mode manuel `PRE` reste disponible pour les sources qui veulent controler exactement les octets emis.

## 4.1 Directives ajoutees dans `xasm2026-1`

| Directive | Forme | Usage |
|---|---|---|
| `REPEAT` / `ENDR` | `REPEAT n ... ENDR` | Repete un bloc a l assemblage. |
| `IFEQ` | `IFEQ expr` | Assemble si l expression vaut zero. |
| `IFNE` | `IFNE expr` | Assemble si l expression est non nulle. |
| `IFGT` | `IFGT expr` | Assemble si l expression est strictement positive. |
| `IFLT` | `IFLT expr` | Assemble si l expression est strictement negative. |
| `STRUCT` / `ENDS` | `NOM: STRUCT ... ENDS` | Cree automatiquement `NOM_SIZE` selon les offsets declares. |
| `SECTION` | `SECTION nom` | Marque une zone pour le rapport `-R` et la MAP. |

```asm
        SECTION INIT
        REPEAT 4
        NOP
        ENDR

VERSION: EQU 2
        IFEQ VERSION-2
        DB 056h
        ENDIF

POINT:  STRUCT
POINT_X:EQU 0
POINT_Y:EQU 1
        ENDS        ; POINT_SIZE vaut 2
```

## 4.2 `INCLUDE` avec arguments

`INCLUDE` permet de creer des fragments parametrables. Les arguments passes apres le nom du fichier sont visibles dans le fichier inclus sous la forme `@0` a `@9`. Le premier argument est `@0`.

```asm
        INCLUDE runtime.s,0B9800h,VOGUE
; dans runtime.s : @0 et @1 sont utilisables comme operandes
```

## 4.3 Macros

Les macros de XASM sont volontairement simples : elles enregistrent les lignes entre `MACRO` et `ENDM`, puis les reinserent lors de l assemblage. Elles sont tres utiles pour les boucles idiomatiques et les structures de controle legeres.

```asm
        MACRO check,param
        MV    A,[X++]
        CMP   A,param
        ENDM

        check $1A
```

# 5. Labels hierarchiques et organisation des sources

Une originalite de XASM est la gestion de labels hierarchiques avec `LOCAL` et `ENDL`. Un bloc local joue un role proche d un sous-repertoire : il permet de reutiliser des noms courts dans des zones differentes sans collision globale.

| Notation | Signification |
|---|---|
| `label` | Label du bloc courant. |
| `bloc!label` | Label situe dans un bloc enfant. |
| `..!label` | Label situe dans le bloc parent. |
| `...!label` | Remonte de deux niveaux. |
| `!bloc!label` | Reference absolue depuis la racine. |
| `.[.]*!bloc!label` | Reference relative vers un autre bloc. |

```asm
MAIN:   LOCAL
loop:   NOP
        JRNZ loop
SUB:    LOCAL
        JPF  ..!loop
        ENDL
        ENDL
```

> `SCOPE_ON` : avec `SCOPE_ON`, la portee des labels ressemble davantage a celle du langage C. Les labels des blocs englobants deviennent visibles depuis les blocs internes. C est confortable, mais la recherche de symboles peut etre plus large et donc moins stricte.

# 6. Ligne de commande et formats de sortie

XASM ne produit aucun fichier si aucune sortie n est demandee. Pour un travail reel, on combine generalement `-O` pour l objet, `-L` pour le listing, et selon le besoin `-B`, `-I`, `-M`, `-P`, `-D` ou `-X`.

| Option | Sortie | Description |
|---|---|---|
| `-O[fichier]` | `.obj` | Objet principal. Sans `-T`, binaire avec en-tete XASM 16 octets. |
| `-L[fichier]` | `.lst` | Listing assemble avec adresses, octets et messages. |
| `-E` | listing erreurs | Supprime la partie objet du listing ; utile pour un fichier de diagnostic. |
| `-S` | symboles | Ajoute les symboles a la fin du listing. |
| `-T[type]` | format objet | `Z`, `F`, `B`, `H` ou binaire avec en-tete par defaut. |
| `-C` | console | Affiche le compteur de lignes pendant l assemblage. |
| `-W` | console/listing | Affiche les warnings. |
| `-H` | interne | Desactive le hachage des symboles. |
| `-I[fichier]` | `.hex` | Intel HEX adresse, checksum, fin `:00000001FF`. |
| `-M[fichier]` | `.s19` | Motorola S-Record S1/S9. |
| `-P[fichier]` | `.map` | Sections et symboles. |
| `-D[fichier]` | `.d` | Dependances type make. |
| `-B[fichier]` | `.uu` | BASIC auto-decodable pour PC-E500S. |
| `-X[fichier]` | `.txt` | Dump texte facon HxD, base sur le `.obj` si `-O` est present. |
| `-V` | console | Ajoute une indication de colonne aux erreurs. |
| `-R` | console | Rapport de taille par `SECTION`. |

## 6.1 Formats `-T` historiques

| Type | Format |
|---|---|
| `Z` | Format texte ZSH pour PC-E500. |
| `F` | Format FTX. |
| `B` | Binaire brut : taille 3 octets + adresse de debut 3 octets + corps. |
| `H` | Representation hexadecimale ASCII du format binaire. |
| absent/autre | Objet avec en-tete XASM 16 octets utilisable comme fichier machine language. |

## 6.2 En-tete objet par defaut

Le format par defaut ajoute un en-tete de 16 octets devant le code. Dans les tests VOGUE, le fichier objet commence par :

```text
FF 00 06 01 10 61 38 00 00 98 0B FF FF FF 00 0F
```

Les octets suivants contiennent le programme assemble. Le dump `-X` permet de verifier cet ensemble exactement comme dans HxD.

## 6.3 Commandes de reference

```powershell
# Compilation de xasm2026-1
gcc -std=c99 -Wall -Wextra -Wno-pointer-sign -Wno-sign-compare -o xasm2026-1.exe eval.c genop.c hash.c init.c mes.c misc.c modern.c mvopr.c opr.c var.c xasm.c

# Assemblage complet de VOGUE
..\..\xasm2026-1.exe VOGUE.S -O VOGUE.obj -L VOGUE.lst -I VOGUE.hex -M VOGUE.s19 -P VOGUE.map -D VOGUE.d -B VOGUE.uu -X VOGUE.txt -R -W
```

# 7. Workflow complet avec `xasm2026-1`

1. Placer le source principal et ses fichiers inclus dans un dossier de projet.
2. Definir l adresse de chargement avec `ORG` et, si utile, separer les zones par `SECTION`.
3. Assembler une premiere fois avec `-L -W -V` pour obtenir les diagnostics lisibles.
4. Ajouter `-P` et `-D` pour verifier les symboles, sections et inclusions.
5. Produire le format cible : `.obj` pour chargement binaire, `.uu` pour decodeur BASIC, `.hex`/`.s19` pour outils externes.
6. Verifier le `.obj` avec `-X` et comparer les premieres lignes si une reference HxD existe.
7. Tester sur emulateur ou machine reelle, en surveillant les adresses systeme et les appels IOCS.

> Conseil de projet : conserver les sorties `.lst`, `.map` et `.d` avec les sources. Le listing donne les octets reels, la MAP aide a inspecter les labels, et le fichier de dependances montre immediatement quels `INCLUDE` ont ete pris en compte.

# 8. Reference rapide du jeu d instructions

XASM reconnait les mnemonics ESR-L suivants. Cette liste provient de la table de hachage de `xasm2026-1` et represente donc exactement les mots reserves assembleur acceptes par cette version.

| Famille | Mnemonics |
|---|---|
| Transferts | `MV`, `MVW`, `MVP`, `MVL`, `MVLD`, `PMDF` |
| Echanges | `EX`, `EXW`, `EXP`, `EXL`, `SWAP` |
| Arithmetique | `ADD`, `SUB`, `ADC`, `SBC`, `ADCL`, `SBCL`, `DADL`, `DSBL`, `INC`, `DEC`, `ADDB`, `ADDW`, `ADDP`, `SUBB`, `SUBW`, `SUBP` |
| Logique / test | `AND`, `OR`, `XOR`, `CMP`, `TEST`, `CMPW`, `CMPP` |
| Decalages/rotations | `ROR`, `ROL`, `SHR`, `SHL`, `DSRL`, `DSLL` |
| Sauts | `JP`, `JPF`, `JPZ`, `JPNZ`, `JPC`, `JPNC`, `JR`, `JRZ`, `JRNZ`, `JRC`, `JRNC` |
| Appels/retours | `CALL`, `CALLF`, `RET`, `RETF`, `RETI` |
| Piles | `PUSHS`, `PUSHU`, `POPS`, `POPU` |
| Controle CPU | `WAIT`, `NOP`, `TCP`/`TCL` selon documentation, `HALT`, `OFF`, `IR`, `RESET`, `SC`, `RC` |

## 8.1 Modes d adressage a retenir

| Mode | Exemple | Commentaire |
|---|---|---|
| Immediat | `MV A,34h` | Valeur dans l instruction. |
| Memoire interne directe | `MV A,(23h)` | Acces a l espace interne `00h`-`FFh`. |
| `BP` + offset | `MV A,(BP+10h)` | Adresse interne relative a `BP`. |
| `BP` + `PX`/`PY` | `MV A,(BP+PX)` | Adresse interne calculee. |
| Externe directe | `MV A,[89AB3h]` | Adresse externe 20 bits. |
| Externe par registre | `MV A,[X]` | Adresse pointee par `X`/`Y`/`U`/`S`. |
| Post-increment | `MV A,[X++]` | Transfert puis increment du pointeur. |
| Pre-decrement | `MV A,[--X]` | Decrement puis transfert. |
| Registre + offset | `MV A,[X+23h]` | Adresse externe pointeur + offset. |
| Indirect interne | `MV A,[(7Bh)]` | Adresse externe lue dans trois octets internes. |

> Branches relatives : XASM choisit automatiquement la forme adaptee pour certains branchements relatifs selon l operand et le compteur de position. Si la cible est trop loin, l erreur `Branch too far` indique qu il faut changer de strategie, par exemple utiliser un saut long/far.

# 9. Erreurs, avertissements et diagnostic

Les messages XASM sont souvent tres directs. Le plus efficace est de relancer avec `-L -W -V` afin de disposer du listing, des warnings et de la colonne approximative.

| Message | Cause probable | Action |
|---|---|---|
| `Prebyte error` | Prebyte impossible ou incoherent. | Verifier `PRE`/`PRE_ON` et l adressage RAM interne. |
| `Division by zero` | Expression avec division par zero. | Corriger `EQU` ou operand. |
| `Undefined instruction` | Mnemonic inconnu ou combinaison operand/instruction invalide. | Verifier syntaxe, parentheses et mode d adressage. |
| `Bad internal RAM addressing` | Adressage interne mal forme. | Controler `(BP+n)`, `(BP+PX)`, offsets et parentheses. |
| `Bad external MEMORY addressing` | Adressage externe mal forme. | Controler crochets, pointeurs `X`/`Y`/`U`/`S`, adresse 20 bits. |
| `Branch too far` | Saut relatif hors portee. | Utiliser un saut plus long ou reorganiser le code. |
| `Duplicate label` | Label deja defini dans le meme bloc. | Renommer ou utiliser `LOCAL`/`ENDL`. |
| `LOCAL not closed` | `ENDL` manquant. | Verifier l imbrication des blocs. |
| `EOF comes before END` | `END` absent. | Ajouter `END` au source ou a l include. |
| `Location counter wandered` | `ORG` ou expression non stabilisee. | Eviter `ORG` multiples, remplacer par `DS` quand possible. |
| `IFDEF not closed` | `ENDIF` manquant. | Verifier les blocs conditionnels. |

## 9.1 Points d attention historiques

- XASM ne detecte pas proprement les `INCLUDE` recursifs ; ils peuvent finir par provoquer une erreur de fichiers ouverts.
- Le deux-points apres un label est obligatoire, meme devant `EQU`.
- Repositionner `ORG` plusieurs fois peut rendre le code incoherent ; utiliser `DS` pour remplir un espace quand c est possible.
- Des parentheses inutiles peuvent transformer un operand valide en adressage invalide.
- Les `EQU` en reference avant definition peuvent ajouter une passe et ralentir l assemblage ; definir les constantes tot est preferable.
- Dans `DW` et `DP`, les constantes caracteres sont developpees caractere par caractere.

# 10. Annexes et sources consultees

## 10.1 Exemple minimal

```asm
        ORG 0E000h
START:  MV  A,0
        NOP
        END
```

## 10.2 Exemple avec fichier objet, UU et dump HxD

```powershell
xasm2026-1.exe PROGRAM.ASM -O PROGRAM.obj -L PROGRAM.lst -B PROGRAM.uu -X PROGRAM.txt -W -V
```

## 10.3 Sources consultees

- `<archive>\xasm140\XASM - ENGLISH.DOC`
- `<archive>\xasm140\README.txt`
- `<archive>\xasm140\Samples`
- `<archive>\xasm2026-1\xasm2026.md`
- `<archive>\xasm2026-1\*.c` et `*.h`
- `<archive>\Manuels - Sharp PC-E500S\ESR-L_CPU_tech_manual.pdf`
- `<archive>\Manuels - Sharp PC-E500S\pce500_tech_manual.pdf`
- `<archive>\Manuels - Sharp PC-E500S\TechnicalReferenceManualPC-E500.pdf`
- `<archive>\Manuels - Sharp PC-E500S\PC-E500 manual_EN.pdf`
- `<archive>\Manuels - Sharp PC-E500S\PC-E500S-DE.pdf`

## 10.4 Pistes d enrichissement pour une version encyclopedique

- Ajouter une annexe opcode exhaustive, instruction par instruction, a partir du manuel ESR-L Command Table.
- Ajouter des captures ou schemas issus des manuels si l objectif devient une monographie complete.
- Documenter les appels IOCS utiles dans VOGUE et TMAP2020 avec leurs registres d entree/sortie.
- Ajouter une section pas a pas sur le transfert reel vers PC-E500S, selon le cable ou l interface utilisee.
