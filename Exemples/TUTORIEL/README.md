# TUTORIEL — exemples des fonctionnalités de XASM2026-4

Ce dossier rassemble des **fichiers d'illustration** de ce qui fait l'originalité de XASM2026-4 :
expressions, directives, symboles locaux, macros, structures, préprocesseur A62. Ils complètent
le [README principal](../../README.md) en montrant chaque construction **à l'œuvre** — et
surtout l'octet qu'elle produit.

> **La plupart ne sont PAS des programmes exécutables sur le Sharp.** Ils émettent des données pour
> *démontrer l'assembleur*, pas pour tourner : les exécuter (`CALL`) planterait la machine
> (des données seraient exécutées comme du code). C'est pourquoi ils **n'ont pas de `.uu`** — le
> `.uu` sert à déployer un programme réel sur le PC-E500S, ce qui n'a pas de sens pour eux. Pour
> ces exemples : le **`.asm`** (source commentée), le **`.lst`** (listing : *adresse → octets →
> source*, c'est là qu'on lit le résultat de chaque construction) et le **`.obj`** (octets assemblés).
>
> **Exception : `08_relocation_detaillee.asm` EST exécutable et testable sur le Sharp** (il a donc
> un `.uu`), et il est **validé sur émulateur** : `CALL &BF000` affiche « RELOC. REUSSIE ». La
> relocation étant délicate, on la comprend beaucoup mieux en la voyant fonctionner : ce programme
> relocalise réellement un bout de code et affiche le résultat.

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

## Comment lire un exemple

Ouvrez le `.asm` (la source expliquée), puis le `.lst` en regard : chaque ligne y montre
l'**adresse**, les **octets émis** et la **source**. On vérifie ainsi de visu que, par exemple,
`db 1010B` produit bien `0Ah`, ou que `#if version == 1` écarte le bon bloc.

## Réassembler

```powershell
cd .\Exemples\TUTORIEL
..\..\bin\xasm2026-4.exe 01_expressions.asm -O -L
```

*(à part `06` et `07` en `0BF000h`/travail, tous s'assemblent à `0E000h` ; voyez l'en-tête de
chaque fichier pour la commande exacte, certains ajoutant `-S` pour lister les symboles.)*
