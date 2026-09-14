# TUTORIEL — exemples des fonctionnalités de XASM2026-4

Ce dossier rassemble des **fichiers d'illustration** de ce qui fait l'originalité de XASM2026-4 :
expressions, directives, symboles locaux, macros, structures, préprocesseur A62, adressage de la
mémoire interne et prébits. Ils complètent
le [README principal](../../README.md) en montrant chaque construction **à l'œuvre** — et
surtout l'octet qu'elle produit.

> **La plupart ne sont PAS des programmes exécutables sur le Sharp.** Ils émettent des données pour
> *démontrer l'assembleur*, pas pour tourner : les exécuter (`CALL`) planterait la machine
> (des données seraient exécutées comme du code). C'est pourquoi ils **n'ont pas de `.uu`** — le
> `.uu` sert à déployer un programme réel sur le PC-E500S, ce qui n'a pas de sens pour eux. Pour
> ces exemples : le **`.asm`** (source commentée), le **`.lst`** (listing : *adresse → octets →
> source*, c'est là qu'on lit le résultat de chaque construction) et le **`.obj`** (octets assemblés).
>
> **Exceptions : `08_relocation_detaillee.asm` et `09_memoire_interne_prebits.asm` SONT exécutables
> et testables sur le Sharp** (ils ont donc un `.uu`). Ces deux mécanismes — la relocation et
> l'octet PRE (« prébit ») de la mémoire interne — étant les plus délicats du CPU, on les comprend
> beaucoup mieux en les voyant à l'œuvre : chaque programme produit un résultat visible à l'écran.
> Les deux sont **validés sur émulateur** : `08` → « RELOC. REUSSIE » ; `09` → affiche `A` (avec
> prébit, `(40h)`) puis `Z` (sans prébit, `(BP+40h)=50h`), prouvant que le prébit change l'octet lu.

## Les exemples

| Fichier | Ce qu'il illustre | À voir dans le README principal |
| --- | --- | --- |
| `01_expressions.asm` | radix par caractère de fin (`B`/`O`/`D`/`H`), opérateurs (`+ - * / % & | ^ ~ << >>`), comparaisons (`= <> < > <= >=`), compteur de localisation `*`, `LOW`/`MID`/`HIGH` | *Syntaxe assembleur → Constantes / Expressions* |
| `02_directives_donnees.asm` | `EQU` vs `SET` (redéfinissable), `DB`/`DM`/`DW`/`DP`/`DS`/`DZ`, `ALIGN`/`EVEN` (le bourrage est **émis**), `TITLE` | *Directives* |
| `03_symboles_locaux.asm` | portées `LOCAL`/`ENDL`, un même nom dans deux portées, référence au parent `..!`, portée **anonyme** (labels de macro uniques) | *Portées, macros, structures* |
| `04_macros.asm` | `MACRO` à paramètres, `EXITM` (sortie anticipée), `IRP` (liste) et `IRPC` (caractères). **Piège montré** : un paramètre à une lettre entre en collision (substitution textuelle) | *Portées, macros, structures* |
| `05_repeat_conditions.asm` | `REPEAT`/`ENDR` + compteur `SET` **génératif**, conditionnelles `IFEQ`/`IFNE`/`IFGT`/`IFLT` (+ `ELSE`), `ASSERT` | *Répétition, conditionnelles* |
| `06_structures.asm` | `STRUCT`/`ENDS` (champs = offsets, nom = taille), zone de travail A62 `SUBORG` + `BYTE`/`WORD`/`PNTR` + `%`, blocs `{ }` | *Structures, blocs A62* |
| `07_preprocesseur_a62.asm` | le **préprocesseur A62** : `rel` (génère la table de relocation), `#defmacro`/`%0..%9` (dont `bsr`), `#if`/`#else`/`#endif` | *Préprocesseur A62 : `rel`, `#defmacro`, `#if`* |
| `08_relocation_detaillee.asm` | **la relocation, démontrée et TESTABLE** : copie un code à une autre adresse, applique la table `rel`, sabote l'original, exécute la copie → affiche « RELOC. REUSSIE ». Décode la table octet par octet et donne la correction. **A un `.uu`.** | *Préprocesseur A62 → la relocation* |
| `09_memoire_interne_prebits.asm` | **mémoire interne `(n)` et octet PRE, démontrés et TESTABLES** : avec `BP=10h`, lit le **même** `(40h)` **avec** prébit (→ absolu `40h`, `'A'`) et **sans** prébit (→ `(BP+40h)=50h`, `'Z'`) et affiche les deux. Prouve à l'écran que le prébit change l'octet lu. Le `.lst` montre le `30h` présent/absent. **A un `.uu`.** | *Syntaxe assembleur → mémoire interne / prébits* |

## Comment lire un exemple

Ouvrez le `.asm` (la source expliquée), puis le `.lst` en regard : chaque ligne y montre
l'**adresse**, les **octets émis** et la **source**. On vérifie ainsi de visu que, par exemple,
`db 1010B` produit bien `0Ah`, ou que `#if version == 1` écarte le bon bloc.

## Réassembler

```powershell
cd .\Exemples\TUTORIEL
..\..\bin\xasm2026-4.exe 01_expressions.asm -O -L
```

*(les exemples exécutables `08` et `09`, ainsi que `06`/`07` (zone de travail), s'assemblent en
`0BF000h` ; les autres à `0E000h`. Voyez l'en-tête de chaque fichier pour la commande exacte —
`08` et `09` ajoutent `-B` pour produire le `.uu` de déploiement, certains `-S` pour les symboles.)*
