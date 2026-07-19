# Description des fichiers sources XASM2026-4

Ce document presente le role de chaque fichier source utile du projet `xasm2026-4`.

Les fichiers generes par .NET dans les dossiers `bin` et `obj` ne sont pas documentes ici : ils sont regenerables par la compilation et ne font pas partie du code maintenu.

## Vue d'ensemble

`xasm2026-4` est le port C# natif de l'assembleur XASM pour le processeur Sharp PC-E500 / CPU-SC62015.

Le projet est organise en blocs fonctionnels :

- `src` : implementation C# native utilisee pour produire `xasm2026-4.exe`.
- `src/Assembly` : lecture du source assembleur, expansion des includes/macros, gestion des symboles et encodage des instructions.
- `src/Core` : structures de donnees communes produites par l'assemblage.
- `src/Expressions` : evaluation des expressions numeriques de l'assembleur.
- `src/Outputs` : generation des differents formats de sortie.
- `Reference/C` : source C historique conserve comme base de comparaison.
- `Reference/CSharpWrapper` : ancien wrapper C# autour du moteur historique.
- `tests/Xasm2026.Tests` : harnais xUnit de non-regression.

## Sources principales C#

### `src/Program.cs`

Point d'entree du programme.

Il lit la ligne de commande, affiche l'en-tete du programme, cree l'assembleur natif, lance l'assemblage et declenche la generation des fichiers demandes.

Il centralise aussi la gestion des erreurs fatales : lorsqu'une erreur intervient, il ecrit un rapport exploitable dans les fichiers `.err` et `.lst` si les options correspondantes sont activees.

### `src/CommandLineOptions.cs`

Modele et parseur des options de ligne de commande.

Ce fichier interprete les options historiques de XASM, notamment :

- `-O` pour le fichier objet ;
- `-L` pour le listing ;
- `-E` pour le rapport d'erreur ;
- `-B` pour le fichier BASIC uuencode ;
- `-I`, `-M`, `-P`, `-D`, `-X` pour les autres formats de sortie ;
- `-T` pour le type d'objet.

Il calcule egalement les noms de sortie par defaut a partir du nom du fichier source.

### `src/Usage.cs`

Affichage de l'aide courte.

Ce fichier contient le texte imprime lorsque l'utilisateur lance le programme sans argument ou avec l'option d'aide.

## Assemblage

### `src/Assembly/NativeAssembler.cs`

Coeur de l'assembleur.

Ce fichier assure la majorite du travail :

- lecture du fichier source principal ;
- traitement des fichiers `INCLUDE` ;
- expansion des macros ;
- gestion des directives d'assemblage ;
- gestion des symboles, etiquettes globales et etiquettes locales ;
- execution des deux passes d'assemblage ;
- encodage des instructions CPU-SC62015 ;
- generation des octets, lignes de listing, sections et dependances ;
- validation des prebytes et des operandes de memoire interne.

Les procedures `Emit...` encodent les familles d'instructions : mouvements, comparaisons, operations logiques, arithmetiques, sauts, pile, donnees et stockage.

Les procedures `Parse...`, `TryEmit...`, `Is...` et `Resolve...` sont des aides internes pour analyser les operandes, resoudre les symboles et choisir la bonne forme d'encodage.

`NativeAssembler` est une **classe `partial`** repartie sur plusieurs fichiers par
preoccupation. Ce decoupage a ete choisi precisement parce qu'il ne modifie aucun site
d'appel, ce qui est determinant quand la moindre regression se mesure a l'octet pres.
`NativeAssembler.cs` conserve la boucle des deux passes, l'aiguillage des directives et
opcodes, et les encodeurs `Emit...`.

### `src/Assembly/NativeAssembler.Preprocessor.cs`

Preprocesseur : lecture des sources et resolution des `INCLUDE` avec detection des cycles,
expansion des macros, `REPEAT`, `IRP` et `IRPC`, et traitement des conditionnelles.

Le corps d'une macro y est **re-developpe** plutot que recopie tel quel, ce qui permet les
conditionnelles internes, `EXITM`, les macros imbriquees et `REPEAT` dans un corps. Un
garde-fou rejette une macro qui s'appellerait elle-meme.

### `src/Assembly/NativeAssembler.Expressions.cs`

Evaluation des expressions dans le contexte de l'assemblage : appel de l'evaluateur avec la
table des symboles, la portee locale et le compteur de localisation, resolution des cibles de
sauts relatifs, et substitution des arguments `@0`..`@9` d'un `INCLUDE`.

C'est ici que les symboles indefinis et les divisions par zero deviennent des erreurs fatales,
et uniquement en passe d'emission : en passe de resolution, une reference avant vaut encore
zero et le controle produirait un faux positif.

### `src/Assembly/NativeAssembler.Sections.cs`

Gestion des `STRUCT`, des sections declarees par `SECTION`, et recopie de l'etat interne vers
le resultat public de l'assemblage.

### `src/Assembly/SymbolTable.cs`

Table des symboles : valeurs, occurrences d'adresse, references croisees et regles de portee
locale (prefixe `portee!etiquette`, reference parente `..!`).

C'est la partie la plus subtile du portage, d'ou son extraction en type autonome, testable
independamment du reste de l'assembleur. Pendant de `hash.c` et de la pile `l_stack` du C.

### `src/Assembly/RegisterTable.cs`

Tables de correspondance des registres SC62015 vers leurs identifiants et opcodes. Sans etat,
donc importees par l'assembleur via `using static` : les sites d'appel restent non prefixes.

### `src/Assembly/SourceRef.cs`

Une ligne source accompagnee de son origine physique — fichier et numero de ligne — et des
expressions d'arguments d'`INCLUDE` en vigueur pour elle.

L'origine est portee **par la ligne elle-meme** et non par une liste parallele, parce que les
corps de macro et les blocs `REPEAT` sont copies puis rejoues, ce qui detruirait toute
correspondance positionnelle. C'est ce qui permet aux erreurs et avertissements de designer le
fichier reellement fautif, y compris a travers un `INCLUDE`.

### `src/Assembly/SourceLine.cs`

Analyse syntaxique d'une ligne assembleur.

Ce fichier decoupe une ligne brute en trois parties :

- etiquette eventuelle ;
- mnemonique ou directive ;
- texte des operandes.

Il supprime aussi les commentaires en respectant les chaines entre guillemets.

## Structures communes

### `src/Core/AssemblyResult.cs`

Conteneur du resultat complet d'un assemblage.

Il regroupe les octets generes, les lignes de listing, les symboles, les sections, les dependances et les informations globales comme l'adresse de depart, l'adresse de fin et le nombre de lignes source traitees.

### `src/Core/GeneratedByte.cs`

Structure legere representant un octet genere avec son adresse.

Elle permet de conserver la relation entre l'adresse assemblee et la valeur produite, ce qui est necessaire pour les formats Intel HEX, S-Record, listing et map.

### `src/Core/ListingLine.cs`

Structure representant une ligne de listing.

Elle associe une adresse, une liste d'octets emis et le texte source correspondant.

### `src/Core/AssemblyWarning.cs`

Avertissement non fatal : fichier, ligne, colonne et libelle historique repris de `mes.c`.
Porte aussi le formatage unique utilise par la console, le `.lst` et le `.err`, afin que les
trois destinations ne puissent pas diverger.

### `src/Core/SectionInfo.cs`

Structure de description d'une section.

Elle contient le nom de la section, son adresse de debut et son adresse de fin.

## Expressions

### `src/Expressions/ExpressionEvaluator.cs`

Evaluateur d'expressions numeriques.

Il interprete les constantes, symboles, expressions parenthesees, valeurs hexadecimales, constantes caracteres, additions, soustractions, multiplications, divisions et modulos.

Il tient compte du contexte d'etiquette locale pour retrouver les symboles definis dans la portee courante.

## Formats de sortie

### `src/Outputs/ObjectWriter.cs`

Generation des fichiers objet.

Il construit l'en-tete objet historique, ajoute les octets produits par l'assembleur et gere les variantes demandees par l'option `-T`, notamment les formats brut, hex texte et ZSH.

### `src/Outputs/BasicUuWriter.cs`

Generation des fichiers `.uu` de l'option `-B`.

Il ecrit un programme BASIC auto-decodeur puis encode les octets objet en lignes uuencode compatibles Sharp PC-E500.

Ce fichier reprend la logique attendue par le decodeur historique `UUSELFX`.

### `src/Outputs/ListingWriter.cs`

Generation du fichier `.lst`.

Il ecrit les options actives, les lignes assemblees, les adresses, les octets produits et, si demande, la liste des symboles.

### `src/Outputs/MapWriter.cs`

Generation du fichier `.map`.

Il ecrit les sections et les symboles connus avec leurs adresses.

### `src/Outputs/DependencyWriter.cs`

Generation du fichier `.d`.

Il produit une liste de dependances utilisable pour savoir quels fichiers source et includes ont participe a l'assemblage.

### `src/Outputs/IntelHexWriter.cs`

Generation du format Intel HEX.

Il regroupe les octets contigus en enregistrements, calcule les checksums et termine le fichier par l'enregistrement de fin standard.

### `src/Outputs/SRecordWriter.cs`

Generation du format Motorola S-Record.

Il regroupe les octets contigus en lignes S-Record et calcule les checksums associes.

### `src/Outputs/HxdDumpWriter.cs`

Generation du dump hexadecimal texte.

Il affiche les octets sous forme hexadecimale avec une colonne ASCII lisible lorsque les caracteres sont imprimables.

## Wrapper C# de reference

### `Reference/CSharpWrapper/src/Program.cs`

Ancien lanceur C# autour du moteur historique.

Il conserve une trace de la logique de transition entre `xasm2026-2` et le port natif `xasm2026-4`.

Ce fichier n'est plus le coeur du projet final, mais il reste utile pour comprendre le chemin de portage.

## Sources C historiques

Les fichiers de `Reference/C` sont conserves comme reference d'origine. Ils ne sont pas modifies dans le port C# natif, mais servent a verifier le comportement historique de XASM.

### `Reference/C/xasm.c`

Programme principal historique en C.

Il pilote la lecture de la ligne de commande, l'assemblage et la production des sorties dans la version d'origine.

### `Reference/C/xasm.h`

Definitions communes de la version C.

Il regroupe les constantes, types, variables globales et declarations partagees.

### `Reference/C/protos.h`

Declarations de fonctions de la version C.

Il sert d'interface entre les differents modules C historiques.

### `Reference/C/init.c`

Initialisation des tables et de l'etat global de l'assembleur historique.

### `Reference/C/eval.c`

Evaluation des expressions dans la version C.

Il correspond fonctionnellement au fichier C# `ExpressionEvaluator.cs`.

### `Reference/C/opr.c`

Analyse et encodage d'une partie des operandes et instructions.

### `Reference/C/mvopr.c`

Traitement historique des instructions de mouvement.

Ce fichier est particulierement utile pour comparer les encodages `MV`, `MVP`, `MVW` et `MVL`.

### `Reference/C/genop.c`

Generation des opcodes dans la version C.

### `Reference/C/hash.c`

Gestion de tables de recherche et de symboles dans la version historique.

### `Reference/C/mes.c`

Messages, diagnostics et textes d'erreur de la version C.

### `Reference/C/misc.c`

Fonctions utilitaires diverses de la version C.

### `Reference/C/modern.c`

Adaptations modernes necessaires pour compiler ou executer la base C historique dans un environnement plus recent.

### `Reference/C/var.c`

Variables globales et donnees partagees de la version C.

## Fichiers de projet et de developpement

### `src/Xasm2026.Native.csproj`

Projet .NET principal.

Il definit la cible de compilation du port C# natif.

### `xasm2026-4.sln`

Solution Visual Studio classique.

Elle permet d'ouvrir et compiler le projet dans Visual Studio 2022.

### `xasm2026-4.slnx`

Solution Visual Studio au format moderne.

Elle peut etre utilisee avec Visual Studio Insiders lorsque ce format est active.

### `.vscode/tasks.json`

Taches de compilation et d'execution pour Visual Studio Code.

### `.vscode/launch.json`

Configurations de lancement et de debogage.

### `.vscode/settings.json`

Parametres locaux de l'espace de travail Visual Studio Code.

## Harnais de tests

### `tests/Xasm2026.Tests/GoldenAssemblyTests.cs`

Reassemble les quatre exemples de reference et compare les huit sorties octet a octet aux
fichiers commites, soit 32 comparaisons exactes. C'est le garde-fou central du projet.

### `tests/Xasm2026.Tests/BehaviorTests.cs`

Comportements attendus des garde-fous : symbole indefini, inclusion cyclique, division par
zero, etiquette dupliquee, avertissements, et position source des erreurs.

### `tests/Xasm2026.Tests/ExpressionEvaluatorTests.cs`

Bases numeriques, compteur de localisation et precedence des operateurs, y compris les deux
precedences contre-intuitives heritees du C.

### `tests/Xasm2026.Tests/SymbolTableTests.cs`

Regles de portee locale : prefixage, imbrication et devidage des portees, resolution de `..!`.

### `tests/Xasm2026.Tests/DirectiveTests.cs`

Directives ajoutees en 2026-4, verifiees sur les octets reellement emis.

### `tests/Xasm2026.Tests/SampleAssemblyTests.cs`

Octets produits par les exemples `SAMPLE6` a `SAMPLE9`, qui illustrent ces memes directives.

### `tests/Xasm2026.Tests/TestPaths.cs`

Localise la racine du depot a partir de l'emplacement de l'assembly de test, sans dependre du
repertoire courant.
