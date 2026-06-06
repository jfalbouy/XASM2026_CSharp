# Portage C# natif

## Reference

Les sources C a respecter sont conservees dans `Reference/C`.

```text
xasm.c      boucle principale, passes, options, fichiers
var.c       etat global
init.c      tables de caracteres et hash initial
hash.c      symboles, mnemonics, macros
eval.c      evaluation d'expressions
opr.c       parsing d'operandes
mvopr.c     encodage MV/EX
genop.c     directives et dispatch opcodes
misc.c      helpers, listing, emission objet
modern.c    sorties 2026 et directives ajoutees
mes.c       messages, erreurs, usage
```

## Cibles C#

```text
Core/        modeles simples et etat d'assemblage
Parsing/     lecture source, tokens, operandes
Symbols/     labels, hash, scopes, macros
Expressions/ evaluation numerique
Instructions/dispatch opcodes et encodage
Directives/  ORG, EQU, INCLUDE, MACRO, IFDEF, REPEAT, STRUCT, SECTION
Outputs/     objets, listing, Intel HEX, S19, MAP, D, UU, HxD
```

## Regles de non-regression

Les sorties suivantes doivent etre comparees avec `xasm2026-1` :

```text
.obj
.lst
.hex
.s19
.map
.d
.uu
.txt
```

Les exemples prioritaires sont :

```text
Exemples/SAMPLES/SAMPLE5.ASM
Exemples/VOGUE/VOGUE.S
Exemples/REGISTER/REGISTER.ASM
Exemples/TMAP/TMAP2020.asm
```

## Journal

- 2026-06-03 : creation de `xasm2026-3`.
- 2026-06-03 : copie de la documentation, des exemples et des sources C de reference.
- 2026-06-03 : creation du projet C# natif.
- 2026-06-03 : port initial du parsing des options, Intel HEX, S-Record et dump HxD.
- 2026-06-03 : premier moteur assembleur C# autonome : `ORG`, `END`, `EQU`, `SECTION`, `STRUCT/ENDS`, `REPEAT/ENDR`, `IFEQ/IFNE/IFGT/IFLT`, `DB/DM/DW/DP/DS`, `NOP` et formes `MV` utilisees par `SAMPLE5`.
- 2026-06-03 : verification `SAMPLE5` : sorties `.hex` et `.s19` identiques a la reference.
- 2026-06-03 : port du generateur BASIC uuencode auto-decodable `-B`; verification de creation de `SAMPLE5.native.uu`.
- 2026-06-03 : branchement de `-L`, `-S`, `-C`, `-E`, lecture `INCLUDE` et dependances enrichies.
- 2026-06-03 : verification complete `SAMPLE5` avec `-O -L -E -S -C -TZ -I -M -P -D -B -X -R -W -V -H`; tous les fichiers attendus sont generes, `.hex` et `.s19` restent identiques a la reference.
- 2026-06-03 : test `VOGUE.S`; les includes et directives simples passent, blocage attendu sur `JP`, premier opcode SC62015 complet non encore porte.
- 2026-06-03 : amelioration du message d'erreur console; la commande `bin\xasm2026-3.exe vogue.s -O vogue.obh -L vogue.lst -B vogue.uu` indique maintenant `ligne 120: start: jp main`.
- 2026-06-03 : port partiel supplementaire pour `VOGUE.S` : sauts/appels `JP/JPF/JP*/CALL/CALLF/JR*`, `PUSHU/POPU/PUSHS/POPS`, `RET/RETF`, operations immediates sur `A`, `INC/DEC`, et premieres formes `MV/MVP/MVW`. Le test avance maintenant jusqu'a `sub x,y`.
- 2026-06-03 : reprise du port `VOGUE.S` : formes `ADD/SUB` internes, `MV/MVW/MVP/MVL` indexees, registres `IL/BA/I/X/Y/U/S`, rotations/decalages, `ADCL/SBCL`, `EX/EXW/EXP/EXL`, `SWAP`, labels locaux imbriques et references parent `..!`.
- 2026-06-03 : correction de la lecture des fichiers inclus : les `END` internes ne terminent plus l'assemblage global.
- 2026-06-03 : verification complete `SAMPLE5.ASM` avec toutes les options de sortie : OK, code `00E000h - 00E01Dh` et fichiers generes.
- 2026-06-03 : finalisation des encodages SC62015 utilises par `VOGUE.S` : piles `PUSHS/POPS`, `JP X`, lectures/ecritures internes hautes, acces `PX`, formes `MV/MVP` indexees et comparaison `CMP (bp+...),A`.
- 2026-06-03 : verification complete `VOGUE.S` avec `-O -L -E -S -C -TZ -I -M -P -D -B -X -R -W -V -H` : OK sans erreur fatale, fichiers generes. Le code produit couvre `0B9800h - 0BD060h`, soit 14433 octets, identique a la reference historique. La carte des symboles ne presente plus aucun ecart d'adresse avec `xasm2026-1`.
- 2026-06-03 : alignement octet a octet de `VOGUE.S` : corrections des formes `ADD/SUB A,(...)`, `AND/OR/XOR A,(...)`, `MV [(bp+...)+n],(...)`, `MVP (...),[adresse]` et evaluation des expressions avec `*` et `/`. Les sorties `VOGUE.hex`, `VOGUE.s19`, `SAMPLE5.hex` et `SAMPLE5.s19` sont identiques aux references.
- 2026-06-03 : correction du format `.lst` C# : le listing n'est plus un dump texte du binaire, il reprend une presentation assembleur ligne par ligne avec adresse, octets generes, commentaires, labels, directives et instructions. Verification `SAMPLE5.ASM` et `VOGUE.S` OK, sans regression sur `.hex` et `.s19`.
- 2026-06-03 : correction de l'entete BASIC `.uu` : les lignes 290 a 410 utilisent maintenant un seul marqueur `%` apres l'apostrophe, conformement au format attendu. Verification OK sur `SAMPLE5.check.uu` et `vogue.check.uu`.
- 2026-06-03 : dernier check croise `xasm2026-2` / `xasm2026-3` avec toutes les options sur `SAMPLE5.ASM` et `VOGUE.S`. Les sorties machine `.hex` et `.s19` sont identiques pour les deux programmes. Les differences restantes concernent les formats de presentation ou d'emballage (`.lst`, `.map`, `.d`, `.txt`, `.uu`) et le type objet `-TZ`, que `xasm2026-3` emet au format texte ZSH.
- 2026-06-04 : alignement final avec les sorties DOSBox `C:\sharp\xasm140-0\Exemples\VOGUE`. `vogue.obj`, `vogue.lst` et `vogue.uu` produits par `xasm2026-3` sont maintenant strictement identiques aux references. Le generateur `.uu` reproduit le comportement de `uuselfx.c` : tampon de 45 octets conserve sur le dernier bloc, checksum historique et ligne finale `size`. Le listing utilise le decoupage historique de 6 octets par ligne, conserve les `end` des fichiers inclus, et reprend le resume final `Code: ...`.
