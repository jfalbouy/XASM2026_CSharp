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
- 2026-07-18 : les formats de presentation entrent dans la non-regression octet a octet. L'invocation historique ayant produit les goldens a ete reconstituee : noms de source et de sorties entierement en minuscules (`sample5.asm` -> `sample5.lst`, ...) et option `-S` (table des symboles annexee au listing). Sous cette invocation, `SAMPLE5`, `VOGUE`, `REGISTER` et `TMAP2020` produisent des `.lst`, `.map`, `.d` et `.uu` strictement identiques aux references (32 sorties sur 32, en comptant `.obj/.hex/.s19/.txt`). Les ecarts observes auparavant venaient uniquement de la casse du nom de fichier embarque et de l'absence de `-S`. Le harnais `GoldenAssemblyTests` compare desormais les huit formats, en neutralisant le seul champ non deterministe : la ligne `' Submitted jj/mm/aaaa` du `.uu`. Les goldens de presentation encore issus de `Publish XASM2026-3 final project` (produits sans `-S` par un build qui n'echoait pas les lignes vides du source) ont ete remplaces par les sorties de reference alignees sur DOSBox le 2026-06-04.
- 2026-07-18 : l'option `-W` devient effective. Elle etait jusqu'ici analysee dans `CommandLineOptions` puis jamais lue. Quatre des six avertissements non fatals de `mes.c` (`err_handle`) sont portes, avec leur libelle historique : 28 `Location counter already set` (ORG apres origine deja fixee, `genop.c` case 64), 32 `No effective code` (`DS 0`, case 73), 33 `LOCAL and ENDL not match in included file` et 38 `PRE_PUSH and PRE_POP not match` (deseequilibre constate a la fermeture d'un fichier inclus, case 66). Les codes 29 (`Used PRE while auto-prebyte is active`) et 34 (`INCLUDE argument isn't defined yet`) ne sont pas portes : ils supposent respectivement la directive de donnees `PRE` et les arguments de `INCLUDE`, absents du port ; a ajouter avec ces fonctionnalites. Semantique conforme au C : un avertissement ne rend jamais l'assemblage fatal et reste muet sans `-W`, ce qui garantit l'absence d'effet sur les goldens (aucun n'a ete produit avec `-W`). Rendu console `fichier<TAB>ligne<TAB>texte`, annexe au `.lst` et au `.err` quand ils sont demandes. Divergences assumees, toutes liees a l'absence de correspondance avec les lignes physiques : le C intercale l'avertissement a la ligne fautive du listing (on les regroupe en fin), le C ajoute `col N` sous `-V` (on n'instrumente pas la colonne et on prefere ne rien afficher), et les numeros rapportes pour le source principal sont ceux des lignes developpees. Verifie : aucun avertissement parasite sur `SAMPLE5`, `VOGUE`, `REGISTER`, `TMAP2020` et `coverage_all`, et non-regression octet a octet inchangee (9 tests verts).
- 2026-07-18 : numeros de ligne physiques (amelioration (c)), banniere `title` et correction de `-?`. (1) Chaque ligne source porte desormais son origine via le nouveau type `src/Assembly/SourceRef.cs` (`Text`, `File`, `Line`). L'origine est attachee a la ligne elle-meme et non a une liste parallele, parce que les corps de MACRO et les blocs REPEAT sont copies puis rejoues, ce qui detruirait toute correspondance positionnelle ; c'est le pendant de `file_typ.name` / `file_typ.lines` du C. Les erreurs et avertissements designent maintenant le fichier reel : une faute dans un INCLUDE est rapportee `ligne N (fichier.asm): ...`, la forme historique `ligne N: ...` etant conservee quand la faute est dans le source principal. Les lignes issues d'une expansion de macro sont rattachees au **site d'appel**, comme dans le C ou `current_file->lines` vaut la ligne en cours de lecture au moment du rejeu. `Program.TryParseErrorLine` accepte les deux formes et relit la ligne fautive dans le fichier qui la contient reellement. Les deux divergences restantes sur les warnings sont l'intercalage dans le listing (on les regroupe en fin) et l'absence de `col N` sous `-V`. (2) Ajout de `Usage.WriteTitle`, pendant de `title()` de `mes.c`, avec la constante `Usage.Version` (pendant du `#define VERSION` de `xasm.h`) : la banniere reprend l'encadrement et les credits historiques et ajoute la mention du portage 2026. (3) Correction de `-?` : `CommandLineOptions.Parse` prenait `args[0]` pour le fichier source sans condition et n'analysait les options qu'a partir de l'indice 1, si bien qu'une option placee en premier n'etait jamais vue (`xasm -?` cherchait un fichier `-?.asm`). Le premier argument n'est desormais traite comme source que s'il ne commence pas par `-`. `-?` est aussi ajoute a la liste des options affichees. Verifie : 13 tests verts, non-regression octet a octet inchangee.
- 2026-07-18 : suppression des chemins machine `C:\Codex\...`. `tools/build_documentation.py` deduit desormais sa racine de l'emplacement du script (`Path(__file__).parent.parent`) ; ses deux ressources externes absentes du depot (table d'instructions PC-E500, `XASM140 - Information`) restent referencees par defaut mais sont surchargeables via les variables d'environnement `XASM_INSTRUCTION_TABLE` et `XASM140_INFO_TXT`, `XASM_FINAL_ROOT` couvrant la racine de publication. `tools/compare_with_xasm2026_1_1.ps1` deduit `OutDir` et `CandidateXasm` de `$PSScriptRoot`, accepte l'exe de reference via `-ReferenceXasm` ou `XASM_REFERENCE_EXE` et echoue avec un message explicite s'il manque, la liste d'exemples etant devenue relative et tolerante aux entrees absentes (TRDOS et UUCODE ne font pas partie de ce checkout). `src/Properties/launchSettings.json` utilise des `workingDirectory` relatifs au dossier du projet, les profils de lancement Visual Studio etant jusqu'ici inutilisables hors de `C:\Codex`. Les documents `Documentation/*.md` ont perdu leurs chemins machine au profit de chemins relatifs a la racine du projet. Enfin, les deux `.docx` portaient un nom en 2026-4 pour un contenu entierement en 2026-3 : leur regeneration etant impossible ici (python-docx absent et sources externes manquantes), leurs parties XML ont ete reecrites en place, ce qui est sur car aucune des occurrences visees n'etait fractionnee entre plusieurs runs XML (verifie au prealable) et la mise en forme est integralement preservee. Verifie : archives ZIP integres, `[Content_Types].xml` en tete, 0 occurrence residuelle de `2026-3` ou de `Codex`.
- 2026-07-18 : les avertissements sont desormais intercales dans le listing a la ligne fautive, comme le fait `err_handle` dans le C, au lieu d'etre regroupes en fin de fichier. L'appariement se fait par l'origine physique : `ListingLine` porte maintenant les champs `File` et `Line`, et `ListingWriter` emet apres chaque ligne les avertissements dont l'origine correspond, en preservant leur ordre lorsque plusieurs visent la meme ligne (cas de 33 et 38 sur la derniere ligne d'un fichier inclus). Les avertissements sans ligne de listing correspondante sont vides en fin de fichier plutot que perdus. L'option `-V` retrouve sa colonne : `AssemblyWarning.Column` designe le debut 1-base de l'operande fautif, ou du mnemonique a defaut. Ce n'est volontairement pas le `pp` du C, qui est la position courante de l'analyseur au moment de l'erreur ; c'est une approximation stable et verifiable, documentee comme telle. Le formatage est centralise dans `AssemblyWarning.Format`, pendant du `errtext` unique de `err_handle`, pour que console, `.lst` et `.err` ne puissent pas diverger. Sans `-W` le listing ne porte aucune trace d'avertissement, ce qui garantit l'invariance des sorties de reference. Verifie : intercalage et colonnes controles sur un cas couvrant les quatre avertissements, 15 tests verts.
- 2026-07-18 : extraction de vrais types depuis le noyau. `src/Assembly/SymbolTable.cs` porte desormais les valeurs de symboles, les occurrences d'adresse et les regles de portee locale (prefixe `scope!label`, reference parente `..!`), qui etaient jusqu'ici quatre champs et cinq methodes disperses dans le partial `NativeAssembler` ; c'est le pendant de `hash.c` et de la pile `l_stack` du C. Cette partie etant la plus subtile du port, elle gagne une suite de tests unitaires dediee (`SymbolTableTests`, 18 cas) qui couvre le prefixage, l'imbrication et le devidage des portees, la resolution de `..!`, l'ordre des candidats de resolution et l'insensibilite a la casse. `src/Assembly/RegisterTable.cs` regroupe les tables registre/opcode SC62015, qui sont sans etat : le noyau les importe via `using static`, donc aucun des 36 appels n'a ete modifie. Le dispatch directive/opcode reste volontairement un `switch` de 96 cas et n'est **pas** converti en table : C# compile deja un switch sur chaine en saut indexe par hachage, une table n'apporterait ni vitesse ni lisibilite, et reecrire les 96 branches est precisement le type de changement que la contrainte d'exactitude octet a octet rend couteux a valider. Verifie : 33 tests verts, non-regression octet a octet inchangee sur les 4 exemples et les 8 formats.
- 2026-07-18 : portage des bases numeriques et du compteur de localisation dans l'evaluateur d'expressions, conformement a `eval.c`. (1) C'est desormais le **dernier caractere** du jeton qui fixe la base : `B`=2, `O`=8, `D`=10, `H`=16 ; sans suffixe reconnu la base est 10 et ce caractere est un chiffre a part entiere. Les suffixes sont acceptes dans les deux casses, le souligne `_` est un separateur visuel ignore (`1010_1010B`, `0F_FH`, `1_000`), et un chiffre superieur ou egal a la base invalide le jeton (err 23 du C), qui remonte alors comme symbole indefini plutot que d'etre silencieusement mal converti. Un nombre doit commencer par un chiffre ou par `$`, ce qui preserve la distinction avec les noms de symboles et explique l'exigence du zero de tete en hexadecimal (`0FFH` et non `FFH`). L'ancien `IsHexToken`, devenu mort, est supprime. (2) L'operande `*` rend le compteur de localisation. Les deux emplois de `*` se distinguent par la position dans l'analyse, ce qui est l'equivalent exact du drapeau `set_x` du C : en position de terme il vaut le compteur, entre deux valeurs il reste l'operateur de multiplication ; `**2` vaut donc « compteur x 2 ». Le compteur est transmis a chaque evaluation, pendant de la globale `lc` du C lue au moment de l'evaluation, si bien qu'il avance au fil des octets emis a l'interieur d'une meme directive. Verifie : octets generes `B5 FF D2 FF AB AA 2A` pour les six notations et le defaut, `dp *` rendant successivement `00E000` puis `00E003`, `db 4*3` valant toujours `0C` ; 59 tests verts dont 26 nouveaux, non-regression octet a octet inchangee.
