# PLINKC — version A62 d'origine, assemblée directement

Ce dossier contient la source **A62 (dialecte Kon)** de PLINKC assemblée **telle quelle** par
XASM2026-4, qui reproduit désormais le compilateur A62 : préfixe `rel` + **génération** de la
table de relocation, macros `#defmacro`/`#endmacro` (`%0..%9`) et conditionnelles
`#if`/`#else`/`#endif`.

| Fichier | Rôle |
| --- | --- |
| `plinkc.a62.asm` | la source **A62 d'origine** (`../PLINKC.asm`), à deux ajustements minimes près (voir plus bas) |
| `plinkc.a62.obj` | l'objet produit — **byte-identique à `../PLINKC.OBJ`** (1554 o, code + table de relocation) |
| `plinkc.a62.lst` | le listing |

## Ce que ça démontre — et la différence avec les autres versions du dossier parent

| Version (dossier `../`) | Nature | Table de relocation |
| --- | --- | --- |
| `PLINKC.asm` | source A62 d'origine (fins de ligne CR) | **générée** par A62 (préfixes `rel`) |
| `PLINKC-BF000.asm` | désassemblage de l'objet | **codée en dur** (`db` explicite) |
| `plinkc.native.asm` | portage dialecte XASM2026-4 | **absente** (les `rel` étaient devenus des commentaires) |
| **`A62/plinkc.a62.asm`** | **la source A62 assemblée directement** | **générée** par XASM2026-4, comme A62 |

C'est « aller plus loin que `PLINKC-BF000.asm` » : la table n'est plus recopiée en dur, elle est
**recalculée** à partir des `rel`, exactement comme le compilateur d'origine. Les 60 sites de
relocation (dont **tous les `call` proches** via la macro `bsr` = `rel call`) sont collectés à
l'assemblage et encodés au format Kon (deltas, bit `080h` = largeur 3, `07Eh` = delta long,
`0FFh` = fin).

## Les deux seuls ajustements vs `../PLINKC.asm`

La source est celle d'origine, à ceci près :

1. **Fins de ligne CR → LF** (la source d'origine est en retours-chariot Mac seuls).
2. **Une accolade `}` ajoutée** pour fermer la boucle d'attente SIO, juste après son unique
   `jrz continue`. La source A62 laissait ce bloc **ouvert** — l'assembleur de Kon le tolérait,
   XASM2026-4 exige l'équilibre des blocs `{ }`. C'est le seul point où A62 était plus permissif ;
   l'ajout n'émet aucun octet (l'objet reste byte-identique).

Aucune autre modification : les `rel`, le `#defmacro bsr`, les `suborg`/`byte`/`word`/`pntr`, les
blocs `{ }`, les `pre $XX`, `%`… sont assemblés tels quels.

## Réassembler

```powershell
cd .\Exemples\PLINKC\A62
..\..\..\bin\xasm2026-4.exe plinkc.a62.asm -O plinkc.a62.obj -L plinkc.a62.lst
```
