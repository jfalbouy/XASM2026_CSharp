# Rapport de bug — octet PRE absent, déplacé ou doublé sur sept familles d'instructions

**Composant** : xasm2026-4 (assembleur SC62015), émission automatique de l'octet PRE (`pre_on`)
**Gravité** : **critique** — objet mal formé **en silence** (`No fatal error`). Selon le cas, le CPU
lit une autre instruction et **se désynchronise**, ou exécute la bonne instruction **en mode
`(BP+n)`** et écrit dans le cadre du BASIC au lieu de la RAM interne visée.
**Type** : divergence avec le moteur C de référence `xasm2026-1-2`, qui encode juste.
**Découvert le** : 2026-09-16 : `MVL` en dressant l'inventaire de
`RAPPORT-BUG-rel-champ-adresse.md`, puis les six autres familles en confrontant au moteur C
l'installateur de `C:\Claude\BASEXT-DRV` (sa boucle de relocation écrivait par
`mvp [y],(00BH)`).

> Ce rapport est destiné à être **corrigé dans xasm2026-4** ; rien n'a été modifié dans le dépôt.
> Il remplace `RAPPORT-BUG-mvl-pre.md` (même jour), dont il reprend le cas `MVL` (famille 7).

---

## 1. Résumé

Sous `pre_on`, une instruction dont un opérande de RAM interne est une adresse **directe** `(n)`
reçoit un octet PRE (`30h` pour un seul opérande interne, `32h` pour deux…), qui **précède
l'opcode**. Sur **157 formes** assemblées par les deux moteurs, **7 familles** diffèrent :

| # | Forme | xasm2026-4 | moteur C | Défaut |
|---|---|---|---|---|
| 1 | `mvp [r3],(n)` | `EA 05 0B` | `30 EA 05 0B` | PRE **absent** |
| 2 | `mvw [r3],(n)` | `E9 05 30 0B` | `30 E9 05 0B` | PRE **après** l'opcode |
| 3 | `mvp (m),[(n)]` / `mvp [(m)],(n)` | `F2 00 0C 0B` / `FA 00 0C 0B` | `32 F2 00 0C 0B` / `32 FA 00 0C 0B` | PRE **absent** |
| 4 | `mvw [(m)],(n)` | `F9 00 30 0C 30 0B` | `32 F9 00 0C 0B` | **deux** `30h` au milieu, au lieu d'un `32h` en tête |
| 5 | `mv (m),[(n)]` | `30 32 F0 00 0C 0B` | `32 F0 00 0C 0B` | **deux** PRE |
| 6 | `jp (n)` | `02 0B 00` | `30 10 0B` | **autre instruction** : `JP 000Bh` direct au lieu de `JP (n)` indirect |
| 7 | `mvl (n),[lmn]` / `mvl [lmn],(n)` | `D3 30 0B lmn` / `DB lmn 30 0B` | `30 D3 0B lmn` / `30 DB lmn 0B` | PRE **après** l'opcode ou l'adresse |

Les familles 1 et 2 valent pour **toutes** les formes d'index : `[y]`, `[y++]`, `[--y]`, `[y+2]`,
`[y-2]` (§3). Les formes `(BP+n)`, qui ne demandent pas de PRE, sont justes.

---

## 2. Reproduction

Chaque ligne s'assemble seule ; les octets attendus sont ceux du moteur C.

```asm
        org     0BF000H
        pre_on
        mvp     [y],(00BH)          ; 30 EA 05 0B
        mvw     [y],(00BH)          ; 30 E9 05 0B
        mvp     (00CH),[(00BH)]     ; 32 F2 00 0C 0B
        mvp     [(00CH)],(00BH)     ; 32 FA 00 0C 0B
        mvw     [(00CH)],(00BH)     ; 32 F9 00 0C 0B
        mv      (00CH),[(00BH)]     ; 32 F0 00 0C 0B
        jp      (00BH)              ; 30 10 0B
        mvl     (00BH),[v]          ; 30 D3 0B lmn
        mvl     [v],(00BH)          ; 30 DB lmn 0B
v:      db      0
        end
```

`xasm2026-4 PRE.ASM -O -L` : `No fatal error`, octets du §1.

### Ce que lit le CPU

- **Famille 1** (`EA 05 0B`) : sans PRE, le mode par défaut s'applique, **`(BP+0Bh)`**. La longueur
  est bonne, rien ne se désynchronise, mais la copie part **dans le cadre courant du BASIC**. C'est
  le cas le plus sournois : l'instruction « marche », ailleurs.
- **Famille 7**, `e500dasm` sur `D3 30 D6 12 F0 0B` :

  ```
  0BF000 D3 30 D6 12 F0    mvl  (030h),[0F012D6h]
  0BF005 0B DB 12          mv   i,012DBh
  0BF008 F0 0B 30 D6       mv   (030h),[(cl)]
  ```

  l'opérande interne est lu dans l'octet `30h`, l'adresse est décalée, et les octets restants
  s'exécutent comme deux instructions parasites.
- **Famille 6** : `02 0B 00` est un `JP 000Bh` **direct** dans la page courante.

---

## 3. Portée — la mesure complète

Source : toutes les instructions du jeu SC62015 qui portent un opérande de RAM interne direct,
d'après `SC62015Disassembler/Data/OpcodeTable.json`. Arithmétique et logique `(m),n`, `(n),A`,
`A,(n)` ; `ADCL`/`SBCL`/`DADL`/`DSBL` ; `PMDF` ; `CMP`/`CMPW`/`CMPP` `(m),(n)` et
`(m),r` ; `INC`/`DEC`/`ROR`/`ROL`/`SHR`/`SHL`/`DSLL`/`DSRL (n)` ; `MV r,(n)`, `MV (n),r`,
`MV r,[(n)]`, `MV [(n)],r` pour les huit registres ; `MV`/`MVW`/`MVP (m),imm` ; `MV`/`MVW`/`MVP`/
`MVL`/`MVLD`/`EX`/`EXW`/`EXP`/`EXL (m),(n)` ; `MV`/`MVW`/`MVP`/`MVL` avec `[lmn]`, `[y]`, `[y++]`,
`[--y]`, `[y+2]`, `[y-2]`, `[(n)]`, `[(n)+2]` dans les deux sens ; `JP (n)`. Soit **157 lignes**,
assemblées sous `pre_on` par les deux moteurs, comparées ligne à ligne.

Tout le reste est **identique**. Dans le détail :

| Forme | xasm2026-4 | moteur C | |
|---|---|---|---|
| `mv [y],(00BH)` | `30 E8 05 0B` | `30 E8 05 0B` | = |
| `mvw [y],(00BH)` | `E9 05 30 0B` | `30 E9 05 0B` | ⛔ 2 |
| `mvw [y++],(00BH)` | `E9 25 30 0B` | `30 E9 25 0B` | ⛔ 2 |
| `mvw [--y],(00BH)` | `E9 35 30 0B` | `30 E9 35 0B` | ⛔ 2 |
| `mvw [y+2],(00BH)` | `E9 85 30 0B 02` | `30 E9 85 0B 02` | ⛔ 2 |
| `mvw [y-2],(00BH)` | `E9 C5 30 0B 02` | `30 E9 C5 0B 02` | ⛔ 2 |
| `mvp [y],(00BH)` | `EA 05 0B` | `30 EA 05 0B` | ⛔ 1 |
| `mvp [y++],(00BH)` | `EA 25 0B` | `30 EA 25 0B` | ⛔ 1 |
| `mvp [--y],(00BH)` | `EA 35 0B` | `30 EA 35 0B` | ⛔ 1 |
| `mvp [y+2],(00BH)` | `EA 85 0B 02` | `30 EA 85 0B 02` | ⛔ 1 |
| `mvp [y-2],(00BH)` | `EA C5 0B 02` | `30 EA C5 0B 02` | ⛔ 1 |
| `mvl [y++],(00BH)` | `30 EB 25 0B` | `30 EB 25 0B` | = |
| `mv`/`mvw`/`mvp (00BH),[y]` (et index) | `30 E0/E1/E2 …` | idem | = |
| `mv [(00CH)],(00BH)` | `32 F8 00 0C 0B` | idem | = |
| `mvw (00CH),[(00BH)]` | `32 F1 00 0C 0B` | idem | = |
| `mvw [(00CH)],(00BH)` | `F9 00 30 0C 30 0B` | `32 F9 00 0C 0B` | ⛔ 4 |
| `mvw [(00CH)+2],(00BH)` | `F9 80 30 0C 30 0B 02` | `32 F9 80 0C 0B 02` | ⛔ 4 |
| `mvp (00CH),[(00BH)]` | `F2 00 0C 0B` | `32 F2 00 0C 0B` | ⛔ 3 |
| `mvp [(00CH)],(00BH)` | `FA 00 0C 0B` | `32 FA 00 0C 0B` | ⛔ 3 |
| `mvp (00CH),[(00BH)+2]` | `F2 80 0C 0B 02` | `32 F2 80 0C 0B 02` | ⛔ 3 |
| `mvp [(00CH)+2],(00BH)` | `FA 80 0C 0B 02` | `32 FA 80 0C 0B 02` | ⛔ 3 |
| `mv (00CH),[(00BH)]` | `30 32 F0 00 0C 0B` | `32 F0 00 0C 0B` | ⛔ 5 |
| `mv (00CH),[(00BH)+2]` | `30 32 F0 80 0C 0B 02` | `32 F0 80 0C 0B 02` | ⛔ 5 |
| `mvl (00CH),[(00BH)]`, `mvl [(00CH)],(00BH)` | `32 F3 …`, `32 FB …` | idem | = |
| `mv`/`mvw`/`mvp (00BH),[v]` et `[v],(00BH)` | `30 D0…D2`, `30 D8…DA` | idem | = |
| `mvl (00BH),[v]` | `D3 30 0B lmn` | `30 D3 0B lmn` | ⛔ 7 |
| `mvl [v],(00BH)` | `DB lmn 30 0B` | `30 DB lmn 0B` | ⛔ 7 |
| `mvl` sous `(BP+n)`, `[x++]`, `[--x]`, `[x+3]`, `(m),(n)`, `mvld` | — | idem | = |
| `jp (00BH)` | `02 0B 00` | `30 10 0B` | ⛔ 6 |
| `mv [y],(BP+3)`, `mvp [y],(BP+3)`, `mvp (BP+3),[y]` | `E8 05 03`, `EA 05 03`, `E2 05 03` | idem | = |

### Pourquoi le corpus ne l'a pas vu

Les sources du corpus écrivent ces formes avec `(BP+n)`, sans PRE (`BASEXT`, par exemple).
✅ Vérifié : `C:\Claude\BASEXT\src\BASEXT.ASM` (2709 octets, validé sur machine), assemblé par les
deux moteurs, donne des objets **identiques à l'octet**.

---

## 4. Cause — ce qui est lu, et ce qui ne l'est pas

`InternalRamOffset` (`src/Assembly/NativeAssembler.cs`, l. 2645-2657) **émet l'octet PRE comme
effet de bord** (`EmitPrebyte(preId, 0, emit, result)`) avant de rendre la valeur de `n`. Toute
branche qui l'appelle **après** avoir émis l'opcode place donc le PRE au milieu de l'instruction.
Des commentaires de la même source montrent que la règle est connue et déjà corrigée ailleurs
(l. 1390, 1478, 1492, 1506 : « le prebyte precede l'opcode »).

**Lu dans la source, et conforme aux octets observés :**

| Famille | Branche | Ordre d'émission |
|---|---|---|
| 2 `mvw [r3],(n)` | l. 1437-1458 | `Emit(0xE9)`, suffixe, puis `InternalRamOffset(right)` → `E9 05 30 0B` |
| 4 `mvw [(m)],(n)` | l. 1415-1431 | `Emit(0xF9)`, sous-octet, `InternalRamOffset(base)`, `InternalRamOffset(right)` → `F9 00 30 0C 30 0B` : deux PRE simples au lieu d'un PRE combiné `32h` |
| 7 `mvl (n),[lmn]` | l. 1621-1625 (`EmitMoveLong`) | `Emit(0xD3)`, puis `InternalRamOffset(left)` |
| 7 `mvl [lmn],(n)` | l. 1640-1644 | `Emit(0xDB)`, `Emit24`, puis `InternalRamOffset(right)` |

**Non localisé** (constaté sur les octets seulement) : famille 1 (`EA`, PRE perdu), famille 3
(`F2`/`FA`, PRE perdu), famille 5 (`F0`, un `30h` de trop devant le `32h`), famille 6 (`jp (n)`
pris pour un saut direct).

---

## 5. Comportement attendu et tests

Les octets du moteur C (§3), qui suivent la règle générale : **un seul octet PRE, en tête**, qui
combine les modes des deux opérandes internes quand il y en a deux.

**Test proposé** : la source du §3 (157 lignes) assemblée par xasm2026-4, comparée **ligne à
ligne** à la sortie du moteur C `Reference/C/xasm2026-1-2.exe`. Elle couvrirait les sept familles
et empêcherait qu'un correctif en casse une voisine. C'est le moteur C qui a trouvé les familles
1 à 6, alors que les tests de reproduction du corpus passaient tous.

⚠️ Après correction, le champ d'adresse des formes `mvl` à `[lmn]` **change de place** : voir
`RAPPORT-BUG-rel-champ-adresse.md` §7.

---

## 6. Contournement en attendant

Écrire ces transferts en `(BP+n)`, ou octet par octet (`mv a,(n)` / `mv [y],a`, justes), et
confronter l'objet au moteur C. `C:\Claude\BASEXT-DRV\outils\construire.py` fait cette
confrontation à chaque construction.
