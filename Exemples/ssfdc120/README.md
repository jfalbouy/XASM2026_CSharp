# SmartMedia Driver 1.20 — portage du dialecte A62

Pilote de peripherique SmartMedia (ex-SSFDC) pour PC-E500S, (c) 1997,1999 Kenji Takamatsu.
Sources d'origine : `xasm2026-1-2/examples/ssfdc120/SRC`.

Ces fichiers **n'ont jamais ete ecrits pour XASM**. Le README du paquet le dit
explicitement — « ソースファイルは A62 でアセンブルできます » (les sources s'assemblent
avec A62) — et la ligne de construction d'epoque etait `A62 SSFDC2.ASM SSFDC2.DVF`.
L'assembleur de reference `xasm2026-1-2` les refuse au meme titre que nous
(`Label format error` sur le premier `#include`).

`convert_a62.py` fait la traduction. Les sources ici presents en sont le resultat ;
les commentaires japonais Shift-JIS ont ete rendus en UTF-8.

## Correspondances appliquees

| A62 | XASM2026-4 | Occurrences |
| --- | --- | --- |
| `preon` | `PRE_ON` | 1 |
| `#include f` | `include f` | 3 |
| `#defmacro n` … `#endmacro` | `macro n` … `endm` | 8 |
| `#if a == b` | `IFEQ (a)-(b)` | 9 (avec `!=` → `IFNE`) |
| `#else` / `#endif` | `ELSE` / `ENDIF` | 2 / 9 |
| `#00100000` (immediat binaire) | `00100000B` | 15 |
| prefixe de ligne `rel` | retire, reporte en commentaire `;rel` | 117 |

Le piege est la conditionnelle. `IFEQ` de XASM **ne compare pas deux operandes** :
`enter_numeric_if` (`modern.c`) lit un unique operande et le teste contre zero. Ecrire
`IFEQ media_type,0` assemble sans erreur mais **ignore silencieusement le `,0`** — d'ou
la soustraction parenthesee. Une premiere conversion naive a produit un code decale de
21 octets, faux mais parfaitement assemblable.

Le prefixe `rel` marquait les operandes a relocaliser au chargement ; A62 en tirait une
table emise a l'etiquette `relTbl:`, en fin de source. XASM n'a pas d'equivalent, donc
`relTbl:` reste vide.

## Verification

Les binaires d'epoque `.DVF` sont conserves ici comme references. Le code que nous
produisons leur est **identique octet pour octet** :

| Variante | media_type | notre `.obj` | `.DVF` | verdict |
| --- | --- | --- | --- | --- |
| `ssfdc2` | 0 (2 Mo) | 1430 o | 1532 o | code identique, 102 o de table absente |
| `ssfdc4` | 1 (4/8 Mo) | 1659 o | 1777 o | code identique, 118 o de table absente |
| `ssfdc16` | 2 (16 Mo) | 1680 o | 1798 o | code identique, 118 o de table absente |

Seuls diffèrent le champ de longueur de l'en-tete et la queue du fichier. Cette queue
est la table de relocalisation : elle mesure exactement **une entree par ligne `rel`
assemblee, plus un octet de fin** (101 lignes → 102 o ; 117 lignes → 118 o). Les `.DVF`
ne sont donc pas reproductibles tels quels sans reimplementer cette table, mais le code
machine, lui, l'est integralement.

## Assemblage

```powershell
cd .\Exemples\ssfdc120
..\..\bin\xasm2026-4.exe ssfdc2.asm -O ssfdc2.obj -L ssfdc2.lst
```

`ssfdc.asm` est le corps commun : il n'est pas autonome et doit etre atteint par l'une
des trois enveloppes, qui definissent `media_type` et `ssect`. `ssfdc_s.asm` est le
programme auxiliaire de `ssfdcutl.bas` (355 o).
