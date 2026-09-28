# Note sur la réponse au rapport « constante de plusieurs caractères » — §6

**Objet** : `REPONSE-RAPPORT-BUG-constante-plusieurs-caracteres.md`, §6 (« Sur le §7 (contournement) »)
**Date** : 2026-09-28
**Statut** : correction de la **documentation** seulement. Le correctif de l'assembleur est juste
et vérifié (voir §3 ci-dessous) : rien à changer dans le code.

---

## 1. Ce que dit le §6

> La réécriture 2026 de TMAP écrit `mv i,0422bh` avec le commentaire `"+B"`. [...] Elle peut
> maintenant redevenir `mv i,'+B'`, plus lisible, si vous le souhaitez.

## 2. Pourquoi c'est inexact

Les deux formes ne donnent **pas** les mêmes octets. Mesuré avec l'assembleur corrigé
(`bin\xasm2026-4.exe` et `dist\xasm2026-4.exe` du 2026-09-27, 20:31) :

```
0BE000 0B 42 2B          mv      i,'+B'
0BE003 0B 2B 42          mv      i,'B+'
0BE006 0B 2B 42          mv      i,0422bh
```

TMAP écrit ensuite `I` par `mv [x++],i`, **poids faible en tête** :

| Source | `I` | Octets écrits | Affichage |
|---|---|---|---|
| `mv i,'+B'` | `2B42h` | `42 2B` | **`B+90`** — celui de TORO en 1994 |
| `mv i,0422bh` | `422Bh` | `2B 42` | **`+B90`** — celui voulu, validé sur PockEmul |
| `mv i,'B+'` | `422Bh` | `2B 42` | `+B90` |

`0422bh` n'est donc **pas** l'écriture hexadécimale de `'+B'`, mais celle de **`'B+'`**. Revenir
à `'+B'` rendrait l'affichage de 1994, avec le signe après la lettre.

## 3. Ce qui reste juste dans la réponse

- La correction elle-même : `'+B'` → `0B 42 2B`, soit les octets de 1994. Vérifié.
- Le second paragraphe du §6 : seule la forme hexadécimale donne les mêmes octets avec le moteur C
  `xasm2026-1-2`. C'est la raison pour laquelle TMAP 2.00 la garde.
- TMAP 2.00, réassemblé avec l'assembleur corrigé, donne un objet **identique à l'octet près**
  (MD5 `83f82a928febcc068c003a5773a28fe7`).

## 4. Correction proposée du §6

> La réécriture 2026 de TMAP écrit `mv i,0422bh` avec le commentaire `"+B"`. Cela reste juste.
> Son équivalent littéral est **`mv i,'B+'`**, et non `'+B'` : le dernier caractère devient
> l'octet de poids faible, écrit en premier par `mv [x++],i`. `'+B'` donnerait l'affichage de
> 1994, `B+`.
>
> Attention en revanche si cette source doit aussi s'assembler avec le moteur C `xasm2026-1-2`
> [...] (inchangé).

## 5. Suggestion, facultative

Le piège tient à l'ordre des octets : une constante de plusieurs caractères se lit « à l'envers »
une fois écrite en mémoire par `mv [r3],r`. Une phrase à ce sujet dans la documentation de
l'évaluateur (README, section sur les constantes caractères) éviterait la même confusion à
d'autres.
