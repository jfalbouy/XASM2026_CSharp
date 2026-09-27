# Rapport de bug — constante de plusieurs caractères réduite à son dernier caractère

> ✅ **Corrigé le 2026-09-27.** L'accumulation est rétablie (comportement de 1994), l'apostrophe
> doublée est un caractère comme un autre, et au-delà de trois caractères c'est une erreur. Les
> témoins TMAP2020/TMAP2021 sont régénérés ; l'écart d'un octet avec le moteur C est **assumé et
> documenté**. Détail : `REPONSE-RAPPORT-BUG-constante-plusieurs-caracteres.md` et `PORTAGE.md`.

**Composant** : xasm2026-4 (assembleur SC62015), évaluateur d'expressions
**Gravité** : **moyenne** — l'assembleur produit **silencieusement** une valeur fausse ; pas de
désynchronisation du code (la longueur des instructions est juste), mais une donnée erronée.
**Type** : fidélité à XASM 1.40, **mais écart avec l'assembleur de TORO (1994)** et avec
l'intention évidente des sources d'époque.
**Découvert le** : 2026-09-27, en réécrivant TMAP (`C:\Claude\TMAP\Sources\2026\tmap.asm`),
à partir d'un relevé pris sur PockEmul : la note `+B90` s'imprimait `B`, un octet nul, puis `90`.

---

## 1. Résumé

Dans un opérande **immédiat**, une constante entre apostrophes de **plus d'un caractère** ne
garde que son **dernier** caractère : `mv i,'+B'` est assemblé `0B 42 00` (`I = 0042h`), alors que
l'objet de TMAP 1.05 de TORO (1994) contient `0B 42 2B` (`I = 2B42h`). Le premier caractère est
perdu, **sans diagnostic**.

`db`/`dw 'AB'` ne sont **pas** concernés (chaîne émise octet par octet).

---

## 2. Reproduction minimale

```asm
        org     0BE000H
        mv      i,'+B'          ; attendu 0B 42 2B
        mv      ba,'AB'         ; attendu 0A 42 41
        mv      x,'ABC'         ; attendu 0C 43 42 41
        dw      'AB'            ; 41 42 : correct
        mv      a,'A'           ; 08 41 : correct
        mv      i,'+B'+0        ; attendu 0B 42 2B
        end
```

```
xasm2026-4 carmulti.asm -L
```

### Sortie de xasm2026-4 — **BUG**
```
0BE000 0B 42 00          mv      i,'+B'
0BE003 0A 42 00          mv      ba,'AB'
0BE006 41 42             dw      'AB'
0BE008 0C 43 00 00       mv      x,'ABC'
0BE00C 08 41             mv      a,'A'
0BE00E 0B 42 00          mv      i,'+B'+0
```
`No fatal error.`

---

## 3. Ce que produisaient les sources d'époque

`C:\Claude\TMAP\Sources\Origine\TMAP.ASM` (TORO, 1994) et son objet d'époque `TMAP.obj` :

| Source (1994) | Objet d'époque | Offset dans `TMAP.obj` | xasm2026-4 |
|---|---|---|---|
| `MV BA,'[ '` | `0A 20 5B` | `0CBh` | `0A 20 00` |
| `MV BA,' ]'` | `0A 5D 20` | `0DAh` | `0A 5D 00` |
| `MV BA,'  '` | `0A 20 20` | `0DFh` | `0A 20 00` |
| `MV I,'+B'` | `0B 42 2B` | `36Bh` | `0B 42 00` |

La règle de l'assembleur de 1994 se lit sur ces octets : **chaque caractère décale la valeur d'un
octet vers la gauche**, le dernier caractère devient l'octet de poids faible :

```
value = (value << 8) | caractere
'+B'  -> 2B42h -> emis 42 2B (poids faible en tete)
```

C'est aussi ce qu'attend le code : `mv [x++],ba` écrit A (poids faible) puis B. Pour obtenir
`" ["`, TORO a écrit `'[ '`.

⚠️ **Les réécritures TMAP2020/TMAP2021 contournent déjà ce défaut**. Elles ont remplacé les trois
`MV BA,'..'` par `mv a,05Bh / mv b,a / mv a,020h`, mais ont **gardé** `MV I,'+B'`, qui est
donc faux dans `Exemples/TMAP/TMAP2020.obj` et `TMAP2021.obj`. Sur la machine, `TMAP 1.05`
réassemblé affiche `B` suivi d'un octet nul au lieu de `B+` (constaté sur la réécriture de 2026).

---

## 4. Origine : un comportement hérité de XASM 1.40

Le défaut n'est **pas** une régression du portage C# : les trois moteurs font la même chose.

| Moteur | Fichier | Code |
|---|---|---|
| XASM 1.40 (original) | `XASM Origine/02- xasm/EVAL.C`, l. 118 | `x = txt[txt_p-1];` |
| xasm2026-1-2 (C) | `Reference/C/eval.c`, l. 115 | `x = txt[txt_p-1];` |
| **xasm2026-4 (C#)** | **`src/Expressions/ExpressionEvaluator.cs`, `ParseCharacter()`** | **`value = _text[_position];`** |

La boucle **écrase** la valeur à chaque caractère au lieu de l'accumuler. TMAP 1.05 (1994) est
**antérieur** à XASM 1.40 (1996) : l'assembleur de TORO accumulait, et la 1.40 a perdu ce
comportement. XASM 1.40 lui-même était donc déjà fautif sur ces sources.

---

## 5. Correction proposée

Dans `ParseCharacter()` (`src/Expressions/ExpressionEvaluator.cs`), accumuler au lieu d'écraser :

```csharp
long value = 0;
while (_position < _text.Length && _text[_position] != '\'')
{
    value = (value << 8) | _text[_position];   // etait : value = _text[_position];
    _position++;
}
```

Deux points à trancher par le responsable :

1. **L'apostrophe doublée à l'intérieur d'une constante longue.** Le code actuel ne la reconnaît
   qu'en tête (`''''` → `27h`). Avec l'accumulation, `'A'''` devrait valoir `4127h` ; à traiter
   dans la boucle si l'on veut être complet (XASM 1.40 la traite dans la boucle, cf. `EVAL.C`).
2. **Au-delà de 3 caractères** : la valeur dépasse 20 bits. Refuser (erreur) ou avertir me
   semble préférable à une troncature muette.

### Compatibilité — mesurée sur tout `C:\Claude`

Recherche des constantes de 2 ou 3 caractères dans un opérande immédiat (hors `db`/`dm`/`dz`/`dw`) :

| Source | Forme | Effet de la correction |
|---|---|---|
| `TMAP2020.asm`, `TMAP2021.asm`, TMAP 1994 | `MV I,'+B'` | `42 00` → `42 2B` : **retour aux octets de 1994** |
| TMAP 1994 | `MV BA,'[ '`, `' ]'`, `'  '` | retour aux octets de 1994 |
| `trdos033/init.asm` l. 45, 64, 79 | `cmp a,'""'` | **inchangé** : `2222h` sur un opérande 8 bits donne `22h`, puisque l'assembleur tronque sans rien dire (`cmp a,2222h` → `60 22`, mesuré) |

Aucune autre occurrence dans le corpus.

### Ce que la correction fait bouger dans les tests

- `GoldenAssemblyTests` : les témoins `Exemples/TMAP/TMAP2020.*` changent (**un octet** : `00` → `2B`
  en `0BE36Bh`, instruction `MV I,'+B'` en `0BE369h`, identique dans `TMAP2021`), et les sorties qui en dépendent : `.obj`, `.hex`, `.s19`, `.txt`, `.uu`). C'est
  **voulu** : le nouvel octet est celui de 1994. Les témoins sont à régénérer.
- `tools/compare_with_xasm2026_1_1.ps1` : TMAP2020 divergera de xasm2026-1-2, qui garde le
  comportement 1.40. L'écart est à documenter comme volontaire.
- À ajouter à `BehaviorTests.cs` : les six lignes du §2, avec les octets attendus.

---

## 6. Défaut voisin, signalé au passage

Une valeur immédiate trop grande pour son opérande est **tronquée sans avertissement** :
`mv a,1234h` → `08 34`, `mv ba,12345h` → `0A 45 23`, `cmp a,2222h` → `60 22`. C'est ce qui rend la
correction du §5 sans effet sur `cmp a,'""'`. Un avertissement (`-W`) serait utile, mais il
signalerait aussi ce cas de TRDOS : à décider séparément.

---

## 7. Contournement en attendant

Écrire la valeur en hexadécimal, en commentant les caractères :

```asm
        mv      i,0422bh        ;"+B" : poids faible ecrit en premier
```

C'est ce que fait `C:\Claude\TMAP\Sources\2026\tmap.asm`. Vérifié sur PockEmul le 2026-09-27 :
la note s'affiche `+B90 +B93`.
