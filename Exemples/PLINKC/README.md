# PLINKC — Pocket Link Cache Device Driver 1.62

Driver de périphérique installé en `0BF000h` (D. Mizobata, 1996-99, d'après PLINK de N. Kon).
Même famille que `REGISTER.ASM` : il détourne des vecteurs IOCS, gère un cache FAT/données et
dialogue avec la SIO.

| Fichier | Rôle |
| --- | --- |
| `PLINKC.asm` | source d'origine, dialecte **A62 / Kon** (fins de ligne CR) |
| `PLINKC.OBJ` | objet compilé d'époque (1554 o = en-tête IOCS 16 o + 1538 o) |
| `PLINKC-BF000.asm` | désassemblage de l'objet par `SC62015Disassembler` — se réassemble en un `PLINKC.OBJ` **identique octet pour octet** (table de relocation comprise, codée en `db`) |
| `plinkc.native.asm` | **port dans le dialecte XASM2026-4** (ce dossier) |
| `convert_a62.py` | le convertisseur qui produit `plinkc.native.asm` |

## Le dialecte A62 et son portage

`PLINKC.asm` n'a jamais été écrit pour XASM. Les constructions spécifiques d'A62 et leur
traitement :

| A62 | XASM2026-4 | Traitement |
| --- | --- | --- |
| `#DEFMACRO bsr` / `rel call %0` / `#ENDMACRO` | — | `bsr X` = `rel call X` → `call X` (macro dépliée) |
| préfixe `rel` (30×) | — | retiré, reporté en commentaire `;rel` (voir la limite plus bas) |
| `%` en position de terme | `%` | **compteur secondaire** (SUBORG) : la taille du cadre de travail |
| `%` entre deux valeurs | `%` | modulo — même désambiguïsation par la position que `*` (LC) |
| `suborg N` / `suborg *` | `suborg` | **directive native ajoutée** : positionne le compteur secondaire |
| `byte` / `word` / `pntr` | idem | **directives natives ajoutées** : champs de 1/2/3 octets à offsets successifs, sans émettre |
| blocs `{ }` + `continue` / `break` | idem | **construction native ajoutée** : boucles structurées |
| `pre $XX`, `$` hexa, `cmpw`, `sbcl`, `pmdf (n),%` | idem | déjà compris tels quels |

Les blocs `{ }` doivent être **équilibrés** : XASM2026-4 refuse une accolade non fermée. La
source A62 laissait le bloc d'attente SIO ouvert (l'assembleur de Kon le tolérait) ; le
convertisseur le referme juste après son unique `jrz continue`, où la boucle d'attente se
termine. La `}` n'émet aucun octet : l'objet est inchangé, la source devient bien formée.

`continue` vise le début du bloc englobant, `break` la sortie (juste après la `}`). Ce sont des
**cibles réservées à l'intérieur d'un bloc seulement** : hors d'un `{ }`, `continue`/`break`
restent de simples étiquettes, si bien que les sources qui en définissent (SAMPLE2, COMPILE.S)
ne sont pas affectées.

## Vérification

Le code produit par `plinkc.native.asm` est **identique octet pour octet** aux **1475 premiers
octets** de la section code de `PLINKC.OBJ` — c'est-à-dire tout le code machine, jusqu'à
`prgend`. Les adresses des tampons de travail (`sect_1`, `fcachep`, `dcache`, … déclarés sous
`suborg *`, 1340 o de RAM au total, de `0BF5C3h` à `0BFAFFh`) sont exactes : le code qui les
référence émet les bons octets, ce que prouve justement l'égalité des 1475 octets.

**Limite — la table de relocation.** `PLINKC.OBJ` se termine par 63 octets qui ne proviennent
d'aucune donnée de la source : c'est la **table de relocation** qu'A62 émet à partir des 30
`rel`, tout comme les `.DVF` de `ssfdc120`. XASM2026-4 n'a pas cette notion ; `plinkc.native.asm`
produit donc le code (1475 o) mais pas ces 63 octets. L'objet complet reste reproductible par le
désassemblage `PLINKC-BF000.asm`, qui code cette table en `db` explicite.

## Assemblage

```powershell
cd .\Exemples\PLINKC
..\..\bin\xasm2026-4.exe plinkc.native.asm -O plinkc.native.obj -L plinkc.native.lst
```
