# Réponse aux rapports de bug — octet PRE et préfixe `rel`

**Rapports** : `RAPPORT-BUG-octet-pre.md` et `RAPPORT-BUG-rel-champ-adresse.md` (2026-09-16)
**Réponse du** : 2026-09-17
**Statut** : ✅ **les deux défauts sont confirmés et corrigés** — commit `9e76984` sur `main`,
CI GitHub verte, 302 tests verts.

Merci pour ces deux rapports. Leur précision a beaucoup aidé : la reproduction a été immédiate,
et les oracles qu'ils proposaient (le moteur C pour le PRE, le double assemblage pour `rel`) sont
devenus les tests de non-régression. Ci-dessous : ce qui a été confirmé, ce que l'enquête a trouvé
**en plus**, la correction, et ce que cela change pour `BASEXT-DRV`.

---

## 1. Octet PRE

### Confirmé

Les sept familles du §1 se reproduisent à l'octet près, avec les valeurs du rapport
(`mvp [y],(00BH)` → `EA 05 0B` au lieu de `30 EA 05 0B`, `jp (00BH)` → `02 0B 00` au lieu de
`30 10 0B`, etc.).

### Plus large que le rapport

Le test proposé au §5 a été construit, en l'élargissant : au lieu des 157 formes en `(n)` sous
`pre_on`, chaque forme est déclinée sur **tous les modes qui changent le PRE** — `(n)`, `(BP+n)`,
`(PX+n)`, `(PY+n)`, et pour deux opérandes `BP+PX` / `BP+PY` — sous `pre_on` **et** `pre_off`.
Soit **2520 cas**, dont 322 que le moteur C refuse. Résultat avant correction :
**224 divergences sous `pre_on`, 65 sous `pre_off`**, soit neuf défauts — les sept du rapport,
plus deux qu'il ne pouvait pas voir :

| # | Forme | Avant | Moteur C | Remarque |
|---|---|---|---|---|
| 1 | `mvp [r3],(n)` | `EA 05 0B` | `30 EA 05 0B` | rapport, famille 1 |
| 2 | `mvw [r3],(n)` | `E9 05 30 0B` | `30 E9 05 0B` | rapport, famille 2 |
| 3 | `mvp (m),[(n)]`, `mvp [(m)],(n)` | `F2 00 0C 0B` | `32 F2 00 0C 0B` | rapport, famille 3 |
| 4 | `mvw [(m)],(n)` | `F9 00 30 0C 30 0B` | `32 F9 00 0C 0B` | rapport, famille 4 |
| 5 | `mv (m),[(n)]` | `30 32 F0 00 0C 0B` | `32 F0 00 0C 0B` | rapport, famille 5 |
| 6 | `jp (n)` | `02 0B 00` | `30 10 0B` | rapport, famille 6 |
| 7 | `mvl (n),[lmn]`, `mvl [lmn],(n)` | `D3 30 0B …` | `30 D3 0B …` | rapport, famille 7 |
| 8 | `mv (BP+m),[(n)±d]` | `F0 80 04 03 00` | `F0 00 04 03` | **nouveau** : sous-octet `80h`, `22h` et déplacement codés en dur |
| 9 | `mv s,[(n)]`, `mv [(n)],s` | `9F …`, `BF …` | refus | **nouveau** : la famille `98`–`9E` / `B8`–`BE` s'arrête à U |

S'y ajoutent deux effets de bord des familles 1 et 4 : `mvp [r3],(PY+n)` était accepté alors que
le moteur C le refuse (le PRE n'était jamais calculé, donc jamais contrôlé), et
`mvw [(m)],(PY+n)` était refusé à tort, sous `pre_on` comme sous `pre_off` : le PRE de `(PY+n)`
seul est illégal, alors que le PRE combiné des deux opérandes est légal (`33 F9 00 0C 03`).

### Cause

Celle du §4 du rapport, qui vaut aussi pour les familles qu'il n'avait pas localisées :
`InternalRamOffset` **émet le PRE en effet de bord**.

- **appelé après l'opcode** → PRE au milieu (familles 2, 7) ;
- **remplacé par un simple `Eval`** → PRE perdu (familles 1 et 3 : `EA`, `F2`, `FA`) ;
- **appelé deux fois** → deux PRE simples au lieu d'un combiné (famille 4) ;
- **la branche générique de `MV (n),…` émettait déjà le PRE de `(m)`** avant que la sous-branche
  `[(n)]` émette le PRE combiné → PRE doublé (famille 5) ;
- **`jp (n)`** n'avait pas de cas : l'opérande était évalué comme une expression parenthésée, d'où
  un saut direct (famille 6).

### Correction

- `mvp [r3],(n)`, `mvw [r3],(n)`, `mvl (n),[lmn]` et `mvl [lmn],(n)` : l'opérande interne est
  résolu (PRE émis) **avant** l'opcode ;
- toute la famille `F0`–`F3` / `F8`–`FB` passe par un encodeur unique,
  `EmitMemoryPointerTransfer`, qui calcule **un** PRE à partir des deux opérandes et l'émet en tête.
  Chaque mnémonique avait sa propre copie de ce code, et quatre sur huit étaient fausses ; elles
  sont remplacées par cet encodeur ;
- `jp (n)` → `[PRE] 10 n` ;
- `mv s,[(n)]` et `mv [(n)],s` → `Undefined instruction`.

**Après correction : 0 divergence sur 2520.**

### Test

`PrebyteFamiliesTests` compare les 2520 cas à `tests/prebyte_families.expected.txt`, produit par
le moteur C via `tools/gen_prebyte_families.py` (régénérable). Détail et tableau complet :
`tests/prebyte_families.README.md`.

---

## 2. Préfixe `rel`

### Confirmé

L'inventaire du §2 se reproduit : **14 formes sur 29** produisaient une entrée fausse
(`JPZ`/`JPNZ`/`JPC`/`JPNC`, `CMP`/`TEST`/`XOR`/`AND`/`OR [lmn],n`, `MV`/`MVW`/`MVP`/`MVL [lmn],(n)`,
`DW`), et le défaut annexe du §5 aussi : `rel mv a,05H` / `rel jr` / `rel nop` donnaient la table
`FF 82 81 FF`, lue comme vide.

### Correction

Celle que proposait le §7 :

- la position du champ n'est plus **déduite** de la fin de l'instruction : elle est **relevée au
  moment où l'encodeur émet l'adresse** (`NoteAddressField`, appelé par `Emit24` pour les adresses
  `lmn`, par `EmitAbsoluteJump` pour les sauts et appels, par `EmitData` pour `DW` et `DP`), avec
  sa largeur — 2 pour `mn`, 3 pour `lmn` ;
- une ligne `rel` doit porter **exactement une** adresse absolue, sinon erreur d'assemblage :
  `rel mv a,05H`, `rel jr`, `rel nop`, `rel jp (n)`, `rel db`, `rel dw a,b` sont refusés ;
- par sécurité, `EncodeRelocTable` refuse aussi un écart négatif, qui s'encoderait en `0FFh`.

Comme le rapport l'anticipait au §7, relever la position plutôt que la calculer rend les deux
corrections indépendantes : le champ de `mvl (n),[lmn]`, déplacé d'un octet par la correction du
PRE, est désigné juste sans aucun traitement particulier.

Précision sur la portée : seules les **adresses** sont relogeables, conformément à l'inventaire du
rapport. Un immédiat de 16 bits (`mv ba,…`, `mvw (n),…`) n'est pas une adresse, et `rel` devant lui
est refusé plutôt que de produire une entrée douteuse.

### Test

`RelocationSitesTests` applique l'oracle du §6 : les 27 formes plus `DP` et `DW`, séparées par des
`nop`, sont assemblées à `0BF000h` et `0A1234h`. La table émise, **décodée indépendamment de
l'encodeur**, doit égaler la liste des octets qui changent. Six cas négatifs couvrent les refus.
Les nouveaux tests échouent tous sur l'ancien code.

### Validation sur BASEXT

L'essai du §3 a été refait dans les mêmes conditions : `BASEXT.ASM`, les 14 entrées de répartition
réécrites en `dp routine+0400000H` (code identique, vérifié), `rel` devant les 144 lignes dont
l'instruction contient un champ mesuré.

| | Avant (rapport) | Après |
|---|---|---|
| table émise | 147 octets, 144 entrées | 147 octets, 144 entrées |
| entrées fausses | 12, décalées d'un octet | **0** — table identique aux champs de `reloc.py` |
| objet relogé vers une 3ᵉ origine | 48 octets faux | **0 octet faux** |

---

## 3. Non-régression

- Goldens (SAMPLE5, VOGUE, REGISTER, TMAP2020 : 32 comparaisons), `postbyte_families`,
  reproduction de `PLINKC.OBJ`, exemples TUTORIEL 01 à 10 : **inchangés** ;
- exemples comparés au moteur C par `tools/compare_with_xasm2026_1_1.ps1` : code machine
  **identique** ;
- `BASEXT.ASM` (2709 octets) : **identique** avec les deux moteurs ;
- seule sortie modifiée : `tests/coverage_all.debug.*` (même taille, 889 octets). Ces fichiers
  avaient figé les octets faux de **9 instructions** des familles corrigées ; chacune a été
  vérifiée identique au moteur C avant régénération.

`bin/xasm2026-4.exe` — celui qu'utilise `reloc.py` par défaut — et `dist/` ont été régénérés.

---

## 4. Ce que cela change pour `BASEXT-DRV`

**Rien à régénérer.** Vérifié sur une copie, sans rien modifier dans le dépôt :

- `BASEXTDR.OBJ` (4536 octets) : **identique** avec l'assembleur corrigé, et identique à celui du
  moteur C (`ASSERT` neutralisés, comme le fait `construire.py`) ;
- `reloc.inc` : `reloc.py`, relancé avec l'assembleur corrigé, régénère **la même table**
  (155 champs), vérifiée à trois origines.

Le pilote était protégé des deux défauts par construction : sa table est mesurée par `reloc.py`
et non produite par `rel`, et `construire.py` confronte l'objet au moteur C.

Deux remarques, sans urgence :

- la docstring de `outils/reloc.py` explique qu'on ne se sert pas de `rel` parce que XASM suppose
  le champ en fin d'instruction. **Ce n'est plus vrai**. La mesure par `reloc.py` reste toutefois
  le meilleur choix pour ce projet : elle n'exige aucun marquage à la main et vérifie la table à
  trois origines. Il suffit d'actualiser la justification ;
- la confrontation au moteur C dans `construire.py` reste utile. `PrebyteFamiliesTests` couvre
  désormais les encodages PRE côté assembleur, mais un contrôle de bout en bout sur l'objet réel
  reste la meilleure garantie.

---

## 5. Pour vérifier

```powershell
cd C:\Claude\xasm2026-4
dotnet test .\tests\Xasm2026.Tests\Xasm2026.Tests.csproj -c Release --filter "PrebyteFamiliesTests|RelocationSitesTests"
python .\tools\gen_prebyte_families.py     # régénère les octets attendus depuis le moteur C
```

Journal détaillé : `PORTAGE.md`, entrée du 2026-09-17.
