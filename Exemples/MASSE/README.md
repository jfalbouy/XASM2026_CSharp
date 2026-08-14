# MASSE — *tiny Macro ASSEmbler* 1.2.0

Assembleur macro deux passes pour la famille Sharp PC-E500, écrit par **N. Masuichi**
(10 avril 1997). Il s'installe et s'exécute **sur la machine** : il lit un source texte et
produit un objet au format `SAVEM`. Chargé en `0BD800h`.

| Fichier | Rôle |
| --- | --- |
| `MASSE.X` | l'exécutable d'époque (objet IOCS, 4991 o = en-tête 16 o + 4975 o de code) |
| `MASSE-BD800.asm` | **désassemblage réassemblable** de `MASSE.X`, produit par `e500dasm` |
| `masse.uu` | auto-décodeur BASIC pour charger `MASSE.X` sur le Sharp (`MASSE   .X`) |
| `MASSE.S` | source d'origine, dans le **dialecte propre de MASSE** — voir plus bas |
| `MASSE.DOC` | documentation d'origine de l'auteur |

## Pourquoi le désassemblage, et pas le source

`MASSE.S` est écrit dans le **langage de MASSE lui-même** (l'assembleur est auto-hébergé) :
origine `\0BD800`, macros `+DEFMACRO`/`+ENDMACRO`, constantes en `nom(valeur)`, pointeurs
`\PNTR`, labels locaux hiérarchiques, échappements `^M^J`… C'est un dialecte entièrement
distinct de celui qu'assemble `xasm2026-4` (lignée A62 / Kon). Le porter serait une traduction
de langage complète, sans intérêt ici.

En revanche, l'**exécutable** `MASSE.X` se prête au **round-trip** : désassemblé en source
propre par `e500dasm` puis réassemblé par `xasm2026-4`, il redonne un objet **identique octet
pour octet** (4991 o). C'est la même cohérence d'inverses que pour les autres drivers du
corpus (voir `tools/roundtrip_coherence.ps1`), et c'est ce qui permet d'intégrer MASSE sans
convertir son source.

## Reproduire

```powershell
cd .\Exemples\MASSE
# réassembler le désassemblage : l'objet obtenu est identique à MASSE.X
..\..\bin\xasm2026-4.exe MASSE-BD800.asm -O MASSE.X -B masse.uu
```

`MASSE.S` et `MASSE.DOC` sont conservés comme **références** ; ils ne sont pas assemblés par
`xasm2026-4`.
