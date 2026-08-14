# SC62015 — Référence complète du jeu d'instructions

> Extrait et organisé depuis `README - PC-E500 Instruction Table.md` et croisé avec `xasm2026.md` / sources XASM.
>
> **Révision du 2026-08-06** — confronté à deux sources qui n'avaient pas servi à l'établir :
> `ESR-L_CPU_tech_manual.pdf` (le manuel du processeur **par Sharp**, table de commandes pp. 73-88,
> récapitulatif 16×16 en dernière page) et `Data/OpcodeTable.json` du désassembleur, dont les
> 25 listings XASM de référence vérifient chaque instruction. Les **240 opcodes concordent**, sans
> un écart de mnémonique ni de longueur. Cinq points ont été corrigés, marqués ⛔ ou ⚠️ dans le texte.
>
> ⚠️ Le manuel de Sharp fait autorité sur ce document : il donne les post-octets **en binaire,
> position par position** — ce qui dit quels bits sont *spécifiés* — et le nombre de cycles par mode
> d'adressage. Voir `Docs/Synthese/Jeu-d-instructions.md`.
>
> **Conventions :**
> - `(n)` : mémoire **interne** (adresse directe, ou modifiée par un octet PRE)
> - `[lmn]` : mémoire **externe** directe (adresse 20 bits)
> - `[r3]` : mémoire externe indirecte via registre (r3 ∈ {X,Y,U,S})
> - `[(n)]` : mémoire externe indirecte via pointeur en mémoire interne
> - `n,m,l,k` : octets immédiat 8 bits ; `mn`=16 bits ; `lmn`=20/24 bits (LSB en premier)
> - `○` flag affecté · `-` flag inchangé · `C Z` = Carry / Zero

---

## 1. Encodage des registres

| Groupe | Registre | Code (3 bits) | Taille |
|:-------|:---------|:-------------|:-------|
| r₁     | A        | 0 (000)      | 8 bit  |
| r₁     | IL       | 1 (001)      | 8 bit  |
| r₂     | BA       | 2 (010)      | 16 bit |
| r₂     | I        | 3 (011)      | 16 bit |
| r₃/r₄  | X        | 4 (100)      | 24 bit |
| r₃/r₄  | Y        | 5 (101)      | 24 bit |
| r₃/r₄  | U        | 6 (110)      | 24 bit |
| r₃     | S        | 7 (111)      | 24 bit |

> r₄ = {X, Y, U} uniquement (S exclu). r₃ = {X, Y, U, S}.

---

## 2. Octets PRE — préfixe de mémoire interne

Certaines instructions à **deux opérandes mémoire interne** nécessitent un octet `PRE` avant l'opcode quand le mode d'adressage n'est pas `(n)` direct simple.

**L'octet PRE est inséré juste avant l'octet d'opcode.**

| 1er opérande \ 2e opérande | `(n)` | `(BP+n)` | `(PY+n)` | `(BP+PY)` |
|:--------------------------|:------|:---------|:---------|:----------|
| **(n)**                   | `32H` | `30H`    | `33H`    | `31H`     |
| **(BP+n)**                | `22H` | —        | `23H`    | `21H`     |
| **(PX+n)**                | `36H` | `34H`    | `37H`    | `35H`     |
| **(BP+PX)**               | `26H` | `24H`    | `27H`    | `25H`     |

> - Rangée = mode du **1er** opérande (ex : destination dans `MV (m),(n)`)
> - Colonne = mode du **2e** opérande (ex : source dans `MV (m),(n)`)
> - **Sans PRE = les deux opérandes sont en `(BP+n)`** — c'est la case « — » du tableau, le mode par
>   défaut du CPU. Voir l'encadré ci-dessous.
> - En assembleur XASM : `PRE 30H` / `PRE_ON` / `PRE_OFF` / `PRE_PUSH` / `PRE_POP`

> ⛔ **Corrigé le 2026-08-06.** Ce document affirmait « sans PRE = les deux opérandes sont en
> adressage direct `(n)` → PRE implicite `32H` (non écrit) ». C'est **l'inverse** : l'absence
> d'octet PRE signifie `(BP+n)` × `(BP+n)`, et `32H` — qui vaut `(n)` × `(n)` — est bel et bien
> émis quand on le veut. Deux sources indépendantes :
>
> 1. **`sample2.lst`**, listing d'assemblage XASM du dépôt : `mv (BP+0),0` sous `pre_on` et
>    `mv (0),0` sous `pre_off` produisent **tous deux `CC 00 00`**, sans octet PRE. Les deux
>    écritures désignent le même mode, celui qui n'a pas de préfixe.
> 2. **La table PRE de Sharp** (`ESR-L_CPU_tech_manual.pdf`, p. 87, « PRE-BYTE — Internal Memory
>    Addressing Mode Setting Byte ») laisse **vide** la case `(bp±n)` × `(bp±n)`, tandis que `32H`
>    y figure à la case `(N)` × `(n)`. Une case vide = pas d'octet à émettre.
>
> Ce n'est pas une subtilité d'écriture : c'est la différence entre lire `mv (0ECh),050h` et
> `mv (bp+0ECh),050h`. Un programme dont BP n'est pas nul ne *peut pas* écrire dans BP sans PRE.
>
> ✅ **Et la règle du PRE à opérande unique est spécifiée**, ce qui explique la domination de `30H`
> dans les objets réels. Note du manuel Sharp sous la même table : « *When the number of operands
> for the internal memory is only one, the assembler generates PRE-BYTE shown in the column marked
> with `*` above regardless of whether the operand is the first or second one.* » La colonne marquée
> est `(bp±n)` — donc **`30H` pour un opérande mémoire unique**, quelle que soit sa position. Un
> auteur qui veut autre chose l'écrit à la main : `PLINKC.asm` dit `pre $32` avant chacune de ces
> instructions.

**Registres spéciaux de mémoire interne utilisés dans les modes PRE :**

| Symbole | Adresse | Rôle                      |
|:--------|:--------|:--------------------------|
| BP      | ECH     | Base Pointer              |
| PX      | EDH     | Pointeur X interne        |
| PY      | EEH     | Pointeur Y interne        |

---

## 3. Carte mémoire interne (IMEM)

| Nom  | Adresse | Description                                 |
|:-----|:--------|:--------------------------------------------|
| BP   | ECH     | RAM Base Pointer                            |
| PX   | EDH     | RAM PX Pointer                              |
| PY   | EEH     | RAM PY Pointer                              |
| AMC  | EFH     | ADR Modify Control (AME bit7, AM5–AM0 bits 6–1) |
| KOL  | F0H     | Key Output Buffer **L** (KO0–KO7) ⚠️            |
| KOH  | F1H     | Key Output Buffer **H** (KO8–KO15) ⚠️           |
| KIL  | F2H     | Key Input Buffer (KI0–KI7)                  |
| EOL  | F3H     | E Port Output **L** (E0–E7) ⚠️                 |
| EOH  | F4H     | E Port Output **H** (E8–E15) ⚠️                |
| EIL  | F5H     | E Port Input **L** (E0–E7) ⚠️                  |
| EIH  | F6H     | E Port Input **H** (E8–E15) ⚠️                 |
| UCR  | F7H     | UART Control Register                       |
| USR  | F8H     | UART Status Register                        |
| RXD  | F9H     | UART Receive Buffer                         |
| TXD  | FAH     | UART Transmit Buffer                        |
| IMR  | FBH     | Interrupt Mask Register                     |
| ISR  | FCH     | Interrupt Status Register                   |
| SCR  | FDH     | System Control Register                     |
| LCC  | FEH     | LCD Contrast Control                        |
| SSR  | FFH     | System Status Register                      |

> ⚠️ **Corrigé le 2026-08-06 — les mentions `H`/`L` étaient inversées** pour `KOL`/`KOH`,
> `EOL`/`EOH` et `EIL`/`EIH`. L'erreur vient de `README - PC-E500 Instruction Table.md`, qui est
> incohérent avec lui-même (il nomme `EOL 0xF3` puis le décrit « Buffer H »). **Le rang de bits
> tranche** : `E0-E7` et `KO0-KO7` sont les bits **bas**, donc `EOL` et `KOL`. C'est ce que suit
> `Data/InternalRAMNames.json`.
>
> Les 34 entrées de ce carnet correspondent une à une à ce tableau, à deux conventions de nommage
> près : le désassembleur écrit `ko` (`F0h`) et `ki` (`F2h`) plutôt que `KOL`/`KIL`, pour suivre la
> section EQU du listing de référence `register`.

---

## 4. Table complète des instructions

### 4.1 Divers / Système

| Mnémonique XASM | Opcode | Octets | Cycles | C Z | Opération |
|:----------------|:-------|:-------|:-------|:----|:----------|
| `NOP`           | `00`   | 1 | 1 | `- -` | Pas d'opération |
| `RETI`          | `01`   | 1 | 7 | restaurés | Retour d'interruption ; dépile IMR, F, PC, PS |
| `RET`           | `06`   | 1 | 4 | `- -` | Retour de sous-programme (pile système S) |
| `RETF`          | `07`   | 1 | 5 | `- -` | Retour far ; dépile PS + PC |
| `SC`            | `97`   | 1 | 1 | `○ -` | Carry ← 1 |
| `RC`            | `9F`   | 1 | 1 | `○ -` | Carry ← 0 |
| `TCP` *(=TCL)*  | `CE`   | 1 | 1 | `- -` | Timer Clear / raz diviseur *(mném. doc : TCL)* |
| `HALT`          | `DE`   | 1 | — | `- -` | Arrêt horloge système (jusqu'à IRQ) |
| `OFF`           | `DF`   | 1 | — | `- -` | Mise hors tension (horloges système et sub) |
| `WAIT`          | `EF`   | 1 | 1+I | `- -` | Boucle d'attente I fois (I = registre I) |
| `SWAP A`        | `EE`   | 1 | 3 | `- ○` | Échange nibbles de A (bits 0–3 ↔ 4–7) — *Carry inchangé* ⚠️ |
| `IR`            | `FE`   | 1 | — | `- -` | Interruption logicielle |
| `RESET`         | `FF`   | 1 | — | `- -` | Reset logiciel |

---

### 4.2 Sauts inconditionnels

| Mnémonique | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:-----------|:-------------------|:-------|:-------|:----|:----------|
| `JP (n)`   | `10` `n`           | 2 | 6 | `- -` | PC ← [(n)..(n+2)] |
| `JP r3`    | `11` `0r`          | 2 | 4 | `- -` | PC ← r3 (r3 = X/Y/U/S) |
| `JP mn`    | `02` `n` `m`       | 3 | 4 | `- -` | PC ← mn (même page) |
| `JPF lmn`  | `03` `n` `m` `l`   | 4 | 5 | `- -` | PC ← lmn, far jump (PS ← 1) |
| `JR +n`    | `12` `n`           | 2 | 3 | `- -` | PC ← PC+2+n (relatif avant) |
| `JR -n`    | `13` `n`           | 2 | 3 | `- -` | PC ← PC+2−n (relatif arrière) |

---

### 4.3 Sauts conditionnels absolus

| Mnémonique | Opcode + opérandes | Octets | Cycles | C Z | Condition |
|:-----------|:-------------------|:-------|:-------|:----|:----------|
| `JPZ mn`   | `14` `n` `m`       | 3 | 4/3 | `- -` | Saut si Z=1 |
| `JPNZ mn`  | `15` `n` `m`       | 3 | 4/3 | `- -` | Saut si Z=0 |
| `JPC mn`   | `16` `n` `m`       | 3 | 4/3 | `- -` | Saut si C=1 |
| `JPNC mn`  | `17` `n` `m`       | 3 | 4/3 | `- -` | Saut si C=0 |

---

### 4.4 Sauts relatifs conditionnels

| Mnémonique | Opcode + opérandes | Octets | Cycles | C Z | Condition |
|:-----------|:-------------------|:-------|:-------|:----|:----------|
| `JRZ +n`   | `18` `n`           | 2 | 3/2 | `- -` | Si Z=1 : PC ← PC+2+n |
| `JRZ -n`   | `19` `n`           | 2 | 3/2 | `- -` | Si Z=1 : PC ← PC+2−n |
| `JRNZ +n`  | `1A` `n`           | 2 | 3/2 | `- -` | Si Z=0 : PC ← PC+2+n |
| `JRNZ -n`  | `1B` `n`           | 2 | 3/2 | `- -` | Si Z=0 : PC ← PC+2−n |
| `JRC +n`   | `1C` `n`           | 2 | 3/2 | `- -` | Si C=1 : PC ← PC+2+n |
| `JRC -n`   | `1D` `n`           | 2 | 3/2 | `- -` | Si C=1 : PC ← PC+2−n |
| `JRNC +n`  | `1E` `n`           | 2 | 3/2 | `- -` | Si C=0 : PC ← PC+2+n |
| `JRNC -n`  | `1F` `n`           | 2 | 3/2 | `- -` | Si C=0 : PC ← PC+2−n |

> En XASM : `JRZ label` génère automatiquement le sens (+ ou −) selon la position du label.

---

### 4.5 Appel / Retour de sous-programme

| Mnémonique  | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:------------|:-------------------|:-------|:-------|:----|:----------|
| `CALL mn`   | `04` `n` `m`       | 3 | 6 | `- -` | S←S−2, [S]←PC+3, PC←mn |
| `CALLF lmn` | `05` `n` `m` `l`   | 4 | 8 | `- -` | S←S−3, [S]←PC+4, PS←1, PC←lmn |

---

### 4.6 Pile utilisateur (PUSHU / POPU)

| Mnémonique    | Opcode | Octets | Cycles | C Z | Opération |
|:--------------|:-------|:-------|:-------|:----|:----------|
| `PUSHU A`     | `28`   | 1 | 3     | `- -` | U←U−1, [U]←A |
| `PUSHU IL`    | `29`   | 1 | 3     | `- -` | U←U−1, [U]←IL |
| `PUSHU BA`    | `2A`   | 1 | 4     | `- -` | U←U−2, [U]←BA |
| `PUSHU I`     | `2B`   | 1 | 4     | `- -` | U←U−2, [U]←I |
| `PUSHU X`     | `2C`   | 1 | 5     | `- -` | U←U−3, [U]←X |
| `PUSHU Y`     | `2D`   | 1 | 5     | `- -` | U←U−3, [U]←Y |
| `PUSHU F`     | `2E`   | 1 | 3     | `- -` | U←U−1, [U]←F |
| `PUSHU IMR`   | `2F`   | 1 | 3     | `- -` | U←U−1, [U]←IMR, IMR₇←0 |
| `POPU A`      | `38`   | 1 | 2     | `- -` | A←[U], U←U+1 |
| `POPU IL`     | `39`   | 1 | 3     | `- -` | IL←[U], IH←0, U←U+1 |
| `POPU BA`     | `3A`   | 1 | 3     | `- -` | BA←[U], U←U+2 |
| `POPU I`      | `3B`   | 1 | 3     | `- -` | I←[U], U←U+2 |
| `POPU X`      | `3C`   | 1 | 4     | `- -` | X←[U], U←U+3 |
| `POPU Y`      | `3D`   | 1 | 4     | `- -` | Y←[U], U←U+3 |
| `POPU F`      | `3E`   | 1 | 2     | restaurés | F←[U], U←U+1 |
| `POPU IMR`    | `3F`   | 1 | 2     | `- -` | IMR←[U], U←U+1 |

### 4.7 Pile système (PUSHS / POPS)

| Mnémonique  | Opcode | Octets | Cycles | C Z | Opération |
|:------------|:-------|:-------|:-------|:----|:----------|
| `PUSHS F`   | `4F`   | 1 | 3 | `- -` | S←S−1, [S]←F |
| `POPS F`    | `5F`   | 1 | 2 | restaurés | F←[S], S←S+1 |

---

### 4.8 MV — Chargement registre depuis immédiat

Opcode de base : `0r` où `r` = code registre (voir §1).

| Mnémonique    | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:--------------|:-------------------|:-------|:-------|:----|:----------|
| `MV A,n`      | `08` `n`           | 2 | 2 | `- -` | A←n |
| `MV IL,n`     | `09` `n`           | 2 | 3 | `- -` | IL←n, IH←0 |
| `MV BA,mn`    | `0A` `n` `m`       | 3 | 3 | `- -` | BA←mn |
| `MV I,mn`     | `0B` `n` `m`       | 3 | 3 | `- -` | I←mn |
| `MV X,lmn`    | `0C` `n` `m` `l`   | 4 | 4 | `- -` | X←lmn |
| `MV Y,lmn`    | `0D` `n` `m` `l`   | 4 | 4 | `- -` | Y←lmn |
| `MV U,lmn`    | `0E` `n` `m` `l`   | 4 | 4 | `- -` | U←lmn |
| `MV S,lmn`    | `0F` `n` `m` `l`   | 4 | 4 | `- -` | S←lmn |

---

### 4.9 MV — Chargement registre depuis mémoire interne `(n)`

Opcode de base : `8r` où `r` = code registre.

| Mnémonique    | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:--------------|:-------------------|:-------|:-------|:----|:----------|
| `MV A,(n)`    | `80` `n`           | 2 | 3  | `- -` | A←(n) |
| `MV IL,(n)`   | `81` `n`           | 2 | 4  | `- -` | IL←(n), IH←0 |
| `MV BA,(n)`   | `82` `n`           | 2 | 4  | `- -` | BA←(n)(n+1) |
| `MV I,(n)`    | `83` `n`           | 2 | 4  | `- -` | I←(n)(n+1) |
| `MV X,(n)`    | `84` `n`           | 2 | 5  | `- -` | X←(n)(n+1)(n+2) |
| `MV Y,(n)`    | `85` `n`           | 2 | 5  | `- -` | Y←(n)(n+1)(n+2) |
| `MV U,(n)`    | `86` `n`           | 2 | 5  | `- -` | U←(n)(n+1)(n+2) |
| `MV S,(n)`    | `87` `n`           | 2 | 5  | `- -` | S←(n)(n+1)(n+2) |

> **Note PRE :** si l'adresse interne utilise un mode PRE (BP+n, PX+n…), insérer l'octet PRE **avant** l'opcode. Ex : `PRE 30H` + `80` + `n`.

---

### 4.10 MV — Chargement registre depuis mémoire externe directe `[lmn]`

Opcode de base : `8r+8` (= `88`..`8F`).

| Mnémonique       | Opcode + opérandes         | Octets | Cycles | C Z | Opération |
|:-----------------|:---------------------------|:-------|:-------|:----|:----------|
| `MV A,[lmn]`     | `88` `n` `m` `l`           | 4 | 6  | `- -` | A←[lmn] |
| `MV IL,[lmn]`    | `89` `n` `m` `l`           | 4 | 6  | `- -` | IL←[lmn], IH←0 |
| `MV BA,[lmn]`    | `8A` `n` `m` `l`           | 4 | 7  | `- -` | BA←[lmn..+1] |
| `MV I,[lmn]`     | `8B` `n` `m` `l`           | 4 | 7  | `- -` | I←[lmn..+1] |
| `MV X,[lmn]`     | `8C` `n` `m` `l`           | 4 | 8  | `- -` | X←[lmn..+2] |
| `MV Y,[lmn]`     | `8D` `n` `m` `l`           | 4 | 8  | `- -` | Y←[lmn..+2] |
| `MV U,[lmn]`     | `8E` `n` `m` `l`           | 4 | 8  | `- -` | U←[lmn..+2] |
| `MV S,[lmn]`     | `8F` `n` `m` `l`           | 4 | 8  | `- -` | S←[lmn..+2] |

---

### 4.11 MV — Chargement registre depuis mémoire externe indirecte via registre

Opcode de base : `9r` + octet de mode registre.

**Byte de mode r3 (2e octet) :**

| Mode         | 2e octet | Description |
|:-------------|:---------|:------------|
| `[r3]`       | `0r3`    | Indirect simple |
| `[r3++]`     | `2r3`    | Post-incrément |
| `[--r3]`     | `3r3`    | Pré-décrément |
| `[r3+n]`     | `8r3` `n` | Offset positif |
| `[r3-n]`     | `Cr3` `n` | Offset négatif |

Où `r3` est le code du registre (X=4, Y=5, U=6, S=7).

| Mnémonique          | Opcode + opérandes        | Octets | Cycles | C Z | Opération |
|:--------------------|:--------------------------|:-------|:-------|:----|:----------|
| `MV A,[r3]`         | `90` `0r3`                | 2 | 4  | `- -` | A←[r3] |
| `MV IL,[r3]`        | `91` `0r3`                | 2 | 5  | `- -` | IL←[r3], IH←0 |
| `MV BA,[r3]`        | `92` `0r3`                | 2 | 5  | `- -` | BA←[r3..+1] |
| `MV I,[r3]`         | `93` `0r3`                | 2 | 5  | `- -` | I←[r3..+1] |
| `MV X,[r3]`         | `94` `0r3`                | 2 | 6  | `- -` | X←[r3..+2] |
| `MV Y,[r3]`         | `95` `0r3`                | 2 | 6  | `- -` | Y←[r3..+2] |
| `MV U,[r3]`         | `96` `0r3`                | 2 | 6  | `- -` | U←[r3..+2] |
| `MV A,[r3++]`       | `90` `2r3`                | 2 | 4  | `- -` | A←[r3], r3←r3+1 |
| `MV IL,[r3++]`      | `91` `2r3`                | 2 | 5  | `- -` | IL←[r3], r3←r3+1 |
| `MV BA,[r3++]`      | `92` `2r3`                | 2 | 5  | `- -` | BA←[r3..+1], r3←r3+2 |
| `MV I,[r3++]`       | `93` `2r3`                | 2 | 5  | `- -` | I←[r3..+1], r3←r3+2 |
| `MV X,[r3++]`       | `94` `2r3`                | 2 | 7  | `- -` | X←[r3..+2], r3←r3+3 |
| `MV Y,[r3++]`       | `95` `2r3`                | 2 | 7  | `- -` | Y←[r3..+2], r3←r3+3 |
| `MV U,[r3++]`       | `96` `2r3`                | 2 | 7  | `- -` | U←[r3..+2], r3←r3+3 |
| `MV A,[--r3]`       | `90` `3r3`                | 2 | 5  | `- -` | r3←r3−1, A←[r3] |
| `MV IL,[--r3]`      | `91` `3r3`                | 2 | 6  | `- -` | r3←r3−1, IL←[r3] |
| `MV BA,[--r3]`      | `92` `3r3`                | 2 | 6  | `- -` | r3←r3−2, BA←[r3..+1] |
| `MV X,[--r3]`       | `94` `3r3`                | 2 | 8  | `- -` | r3←r3−3, X←[r3..+2] |
| `MV A,[r3+n]`       | `90` `8r3` `n`            | 3 | 6  | `- -` | A←[r3+n] |
| `MV IL,[r3+n]`      | `91` `8r3` `n`            | 3 | 7  | `- -` | IL←[r3+n] |
| `MV BA,[r3+n]`      | `92` `8r3` `n`            | 3 | 7  | `- -` | BA←[r3+n..+1] |
| `MV X,[r3+n]`       | `94` `8r3` `n`            | 3 | 8  | `- -` | X←[r3+n..+2] |
| `MV A,[r3-n]`       | `90` `Cr3` `n`            | 3 | 6  | `- -` | A←[r3−n] |
| `MV X,[r3-n]`       | `94` `Cr3` `n`            | 3 | 8  | `- -` | X←[r3−n..+2] |

---

### 4.12 MV — Chargement registre depuis mémoire indirecte `[(n)]`

Opcode : `9r+8` (= `98`..`9F`).

| Mnémonique          | Opcode + opérandes         | Octets | Cycles | C Z | Opération |
|:--------------------|:---------------------------|:-------|:-------|:----|:----------|
| `MV A,[(n)]`        | `98` `00` `n`              | 3 | 9  | `- -` | A←[[( n)]] |
| `MV IL,[(n)]`       | `99` `00` `n`              | 3 | 10 | `- -` | IL←[[(n)]] |
| `MV BA,[(n)]`       | `9A` `00` `n`              | 3 | 10 | `- -` | BA←[[(n)]..+1] |
| `MV I,[(n)]`        | `9B` `00` `n`              | 3 | 10 | `- -` | I←[[(n)]..+1] |
| `MV X,[(n)]`        | `9C` `00` `n`              | 3 | 11 | `- -` | X←[[(n)]..+2] |
| `MV Y,[(n)]`        | `9D` `00` `n`              | 3 | 11 | `- -` | Y←[[(n)]..+2] |
| `MV U,[(n)]`        | `9E` `00` `n`              | 3 | 11 | `- -` | U←[[(n)]..+2] |
| `MV A,[(m)+n]`      | `98` `80` `m` `n`          | 4 | 11 | `- -` | A←[[(m)]+n] |
| `MV X,[(m)+n]`      | `9C` `80` `m` `n`          | 4 | 13 | `- -` | X←[[(m)]+n..+2] |
| `MV A,[(m)-n]`      | `98` `C0` `m` `n`          | 4 | 11 | `- -` | A←[[(m)]−n] |

---

### 4.13 MV — Écriture registre vers mémoire interne `(n)`

Opcode de base : `Ar` où `r` = code registre.

| Mnémonique    | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:--------------|:-------------------|:-------|:-------|:----|:----------|
| `MV (n),A`    | `A0` `n`           | 2 | 3  | `- -` | (n)←A |
| `MV (n),IL`   | `A1` `n`           | 2 | 3  | `- -` | (n)←IL |
| `MV (n),BA`   | `A2` `n`           | 2 | 4  | `- -` | (n)(n+1)←BA |
| `MV (n),I`    | `A3` `n`           | 2 | 4  | `- -` | (n)(n+1)←I |
| `MV (n),X`    | `A4` `n`           | 2 | 5  | `- -` | (n)(n+1)(n+2)←X |
| `MV (n),Y`    | `A5` `n`           | 2 | 5  | `- -` | (n)(n+1)(n+2)←Y |
| `MV (n),U`    | `A6` `n`           | 2 | 5  | `- -` | (n)(n+1)(n+2)←U |
| `MV (n),S`    | `A7` `n`           | 2 | 5  | `- -` | (n)(n+1)(n+2)←S |

---

### 4.14 MV — Écriture registre vers mémoire externe directe `[lmn]`

Opcode de base : `Ar+8` (= `A8`..`AF`).

| Mnémonique       | Opcode + opérandes       | Octets | Cycles | C Z | Opération |
|:-----------------|:-------------------------|:-------|:-------|:----|:----------|
| `MV [lmn],A`     | `A8` `n` `m` `l`         | 4 | 5  | `- -` | [lmn]←A |
| `MV [lmn],IL`    | `A9` `n` `m` `l`         | 4 | 5  | `- -` | [lmn]←IL |
| `MV [lmn],BA`    | `AA` `n` `m` `l`         | 4 | 6  | `- -` | [lmn..+1]←BA |
| `MV [lmn],I`     | `AB` `n` `m` `l`         | 4 | 6  | `- -` | [lmn..+1]←I |
| `MV [lmn],X`     | `AC` `n` `m` `l`         | 4 | 7  | `- -` | [lmn..+2]←X |
| `MV [lmn],Y`     | `AD` `n` `m` `l`         | 4 | 7  | `- -` | [lmn..+2]←Y |
| `MV [lmn],U`     | `AE` `n` `m` `l`         | 4 | 7  | `- -` | [lmn..+2]←U |
| `MV [lmn],S`     | `AF` `n` `m` `l`         | 4 | 7  | `- -` | [lmn..+2]←S |

---

### 4.15 MV — Écriture registre vers mémoire externe indirecte via registre

Opcode de base : `Br` + octet de mode (même encodage que §4.11).

| Mnémonique          | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:--------------------|:-------------------|:-------|:-------|:----|:----------|
| `MV [r3],A`         | `B0` `0r3`         | 2 | 4  | `- -` | [r3]←A |
| `MV [r3],IL`        | `B1` `0r3`         | 2 | 4  | `- -` | [r3]←IL |
| `MV [r3],BA`        | `B2` `0r3`         | 2 | 5  | `- -` | [r3..+1]←BA |
| `MV [r3],I`         | `B3` `0r3`         | 2 | 5  | `- -` | [r3..+1]←I |
| `MV [r3],X`         | `B4` `0r3`         | 2 | 6  | `- -` | [r3..+2]←X |
| `MV [r3],Y`         | `B5` `0r3`         | 2 | 6  | `- -` | [r3..+2]←Y |
| `MV [r3],U`         | `B6` `0r3`         | 2 | 6  | `- -` | [r3..+2]←U |
| `MV [r3++],A`       | `B0` `2r3`         | 2 | 4  | `- -` | [r3]←A, r3←r3+1 |
| `MV [r3++],BA`      | `B2` `2r3`         | 2 | 5  | `- -` | [r3..+1]←BA, r3←r3+2 |
| `MV [r3++],X`       | `B4` `2r3`         | 2 | 7  | `- -` | [r3..+2]←X, r3←r3+3 |
| `MV [--r3],A`       | `B0` `3r3`         | 2 | 5  | `- -` | r3←r3−1, [r3]←A |
| `MV [--r3],BA`      | `B2` `3r3`         | 2 | 6  | `- -` | r3←r3−2, [r3..+1]←BA |
| `MV [--r3],X`       | `B4` `3r3`         | 2 | 8  | `- -` | r3←r3−3, [r3..+2]←X |
| `MV [r3+n],A`       | `B0` `8r3` `n`     | 3 | 6  | `- -` | [r3+n]←A |
| `MV [r3+n],BA`      | `B2` `8r3` `n`     | 3 | 7  | `- -` | [r3+n..+1]←BA |
| `MV [r3+n],X`       | `B4` `8r3` `n`     | 3 | 8  | `- -` | [r3+n..+2]←X |
| `MV [r3-n],A`       | `B0` `Cr3` `n`     | 3 | 6  | `- -` | [r3−n]←A |

---

### 4.16 MV — Écriture registre vers mémoire via pointeur `[(n)]`

| Mnémonique         | Opcode + opérandes    | Octets | Cycles | C Z | Opération |
|:-------------------|:----------------------|:-------|:-------|:----|:----------|
| `MV [(n)],A`       | `B8` `00` `n`         | 3 | 9  | `- -` | [[(n)]]←A |
| `MV [(n)],IL`      | `B9` `00` `n`         | 3 | 9  | `- -` | [[(n)]]←IL |
| `MV [(n)],BA`      | `BA` `00` `n`         | 3 | 10 | `- -` | [[(n)]..+1]←BA |
| `MV [(n)],I`       | `BB` `00` `n`         | 3 | 10 | `- -` | [[(n)]..+1]←I |
| `MV [(n)],X`       | `BC` `00` `n`         | 3 | 11 | `- -` | [[(n)]..+2]←X |
| `MV [(n)],Y`       | `BD` `00` `n`         | 3 | 11 | `- -` | [[(n)]..+2]←Y |
| `MV [(n)],U`       | `BE` `00` `n`         | 3 | 11 | `- -` | [[(n)]..+2]←U |

---

### 4.17 MV — Transferts mémoire–mémoire interne

| Mnémonique        | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:------------------|:-------------------|:-------|:-------|:----|:----------|
| `MV (m),(n)`      | `C8` `m` `n`       | 3 | 6  | `- -` | (m)←(n) |
| `MV (m),n`        | `CC` `m` `n`       | 3 | 3  | `- -` | (m)←n (immédiat) |
| `MVW (m),(n)`     | `C9` `m` `n`       | 3 | 8  | `- -` | (m..m+1)←(n..n+1) |
| `MVW (l),mn`      | `CD` `l` `n` `m`   | 4 | 4  | `- -` | (l..l+1)←mn (immédiat 16 bits) |
| `MVP (m),(n)`     | `CA` `m` `n`       | 3 | 10 | `- -` | (m..m+2)←(n..n+2) |
| `MVP (k),lmn`     | `DC` `k` `n` `m` `l` | 5 | 5 | `- -` | (k..k+2)←lmn (immédiat 24 bits) |
| `MVL (m),(n)`     | `CB` `m` `n`       | 3 | 5+2×I | `- -` | Boucle I fois : (m++)←(n++) |
| `MVLD (m),(n)`    | `CF` `m` `n`       | 3 | 5+2×I | `- -` | Boucle I fois : (m--)←(n--) |

> **Note PRE :** quand l'un des opérandes utilise un mode BP/PX, insérer l'octet PRE correspondant (§2) avant l'opcode.

---

### 4.18 MV — Transferts mémoire externe ↔ mémoire interne

| Mnémonique           | Opcode + opérandes              | Octets | Cycles | C Z | Opération |
|:---------------------|:--------------------------------|:-------|:-------|:----|:----------|
| `MV (k),[lmn]`       | `D0` `k` `n` `m` `l`           | 5 | 7      | `- -` | (k)←[lmn] |
| `MVW (k),[lmn]`      | `D1` `k` `n` `m` `l`           | 5 | 8      | `- -` | (k..k+1)←[lmn..+1] |
| `MVP (k),[lmn]`      | `D2` `k` `n` `m` `l`           | 5 | 9      | `- -` | (k..k+2)←[lmn..+2] |
| `MVL (k),[lmn]`      | `D3` `k` `n` `m` `l`           | 5 | 6+2×I  | `- -` | Boucle I : (k++)←[lmn++] |
| `MV (n),[r3]`        | `E0` `0r3` `n`                  | 3 | 6      | `- -` | (n)←[r3] |
| `MVW (n),[r3]`       | `E1` `0r3` `n`                  | 3 | 7      | `- -` | (n..n+1)←[r3..+1] |
| `MVP (n),[r3]`       | `E2` `0r3` `n`                  | 3 | 8      | `- -` | (n..n+2)←[r3..+2] |
| `MVL (n),[r3++]`     | `E3` `2r3` `n`                  | 3 | 7+2×I  | `- -` | Boucle I : (n++)←[r3++] |
| `MVL (n),[--r3]`     | `E3` `3r3` `n`                  | 3 | 7+2×I  | `- -` | Boucle I : (n++)←[--r3] |
| `MVL (m),[r3+n]`     | `56` `8r3`/`Cr3` `m` `n`        | 4 | 5+2×I  | `- -` | Boucle I : (m++)←[r3±n++] |
| `MV [r3],(n)`        | `E8` `0r3` `n`                  | 3 | 6      | `- -` | [r3]←(n) |
| `MVW [r3],(n)`       | `E9` `0r3` `n`                  | 3 | 7      | `- -` | [r3..+1]←(n..n+1) |
| `MVP [r3],(n)`       | `EA` `0r3` `n`                  | 3 | 8      | `- -` | [r3..+2]←(n..n+2) |
| `MVL [r3++],(n)`     | `EB` `2r3` `n`                  | 3 | 5+2×I  | `- -` | Boucle I : [r3++]←(n++) |
| `MVL [--r3],(n)`     | `EB` `3r3` `n`                  | 3 | 7+2×I  | `- -` | Boucle I : [--r3]←(n++) |
| `MVL [r3+m],(n)`     | `5E` `8r3`/`Cr3` `n` `m`        | 4 | 5+2×I  | `- -` | Boucle I : [r3±m++]←(n++) |
| `MV (m),[(n)]`       | `F0` `00` `m` `n`               | 4 | 11     | `- -` | (m)←[[(n)]] |
| `MVW (m),[(n)]`      | `F1` `00` `m` `n`               | 4 | 12     | `- -` | (m..m+1)←[[(n)]..+1] |
| `MVP (m),[(n)]`      | `F2` `00` `m` `n`               | 4 | 13     | `- -` | (m..m+2)←[[(n)]..+2] |
| `MVL (m),[(n)]`      | `F3` `00` `m` `n`               | 4 | 10+2×I | `- -` | Boucle I : (m++)←[[(n)]++] |
| `MV [(m)],(n)`       | `F8` `00` `m` `n`               | 4 | 11     | `- -` | [[(m)]]←(n) |
| `MVW [(m)],(n)`      | `F9` `00` `m` `n`               | 4 | 12     | `- -` | [[(m)]..+1]←(n..n+1) |
| `MVP [(m)],(n)`      | `FA` `00` `m` `n`               | 4 | 13     | `- -` | [[(m)]..+2]←(n..n+2) |
| `MVL [(m)],(n)`      | `FB` `00` `m` `n`               | 4 | 10+2×I | `- -` | Boucle I : [[(m)]++]←(n++) |
| `MV (k),[lmn]`→`MVP`| `F0` `80`/`C0` `l` `m` `n`      | 5 | 13     | `- -` | [[(l)]±m]←(n) (mémoire externe indirecte indexée) |
| `MVP (n),[lmn]`      | `DC` `n` `m` `l` `k`            | — | —      | `- -` | *(variante externe→interne 24 bits)* |

---

### 4.19 MV — Transferts registre–registre

| Mnémonique       | Opcode + opérandes     | Octets | Cycles | C Z | Opération |
|:-----------------|:-----------------------|:-------|:-------|:----|:----------|
| `MV A,B`         | `74`                   | 1 | 1  | `- -` | A←B |
| `MV B,A`         | `75`                   | 1 | 1  | `- -` | B←A |
| `MV r2,r2'`      | `FD` `0r 0r'`          | 2 | 2  | `- -` | r2←r2' (BA↔I) |
| `MV r3,r3'`      | `FD` `0r 0r'`          | 2 | 2  | `- -` | r3←r3' (X/Y/U/S) |

---

### 4.20 EX — Échange de données

| Mnémonique        | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:------------------|:-------------------|:-------|:-------|:----|:----------|
| `EX (m),(n)`      | `C0` `m` `n`       | 3 | 7      | `- -` | (m) ↔ (n) |
| `EXW (m),(n)`     | `C1` `m` `n`       | 3 | 10     | `- -` | (m..m+1) ↔ (n..n+1) |
| `EXP (m),(n)`     | `C2` `m` `n`       | 3 | 13     | `- -` | (m..m+2) ↔ (n..n+2) |
| `EXL (m),(n)`     | `C3` `m` `n`       | 3 | 5+3×I  | `- -` | Boucle I : (m++) ↔ (n++) |
| `EX A,B`          | `DD`               | 1 | 3      | `- -` | A ↔ B |
| `EX r2,r2'`       | `ED` `0r 0r'`      | 2 | 4      | `- -` | r2 ↔ r2' |
| `EX r3,r3'`       | `ED` `0r 0r'`      | 2 | 4      | `- -` | r3 ↔ r3' |

---

### 4.21 ADD / SUB — Addition et soustraction

| Mnémonique       | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:-----------------|:-------------------|:-------|:-------|:----|:----------|
| `ADD A,n`        | `40` `n`           | 2 | 3  | `○ ○` | A←A+n |
| `ADD (m),n`      | `41` `m` `n`       | 3 | 4  | `○ ○` | (m)←(m)+n |
| `ADD A,(n)`      | `42` `n`           | 2 | 4  | `○ ○` | A←A+(n) |
| `ADD (n),A`      | `43` `n`           | 2 | 4  | `○ ○` | (n)←(n)+A |
| `ADD r2,r'`      | `44` `rr'`         | 2 | 5  | `○ ○` | r2←r2+r' (r' : r1 ou r2) |
| `ADD r3,r'`      | `45` `rr'`         | 2 | 7  | `○ ○` | r3←r3+r' (r' : r1, r2, r3) |
| `ADD r1,r1'`     | `46` `rr'`         | 2 | 3  | `○ ○` | r1←r1+r1' |
| `SUB A,n`        | `48` `n`           | 2 | 3  | `○ ○` | A←A−n |
| `SUB (m),n`      | `49` `m` `n`       | 3 | 4  | `○ ○` | (m)←(m)−n |
| `SUB A,(n)`      | `4A` `n`           | 2 | 4  | `○ ○` | A←A−(n) |
| `SUB (n),A`      | `4B` `n`           | 2 | 4  | `○ ○` | (n)←(n)−A |
| `SUB r2,r'`      | `4C` `rr'`         | 2 | 5  | `○ ○` | r2←r2−r' |
| `SUB r3,r'`      | `4D` `rr'`         | 2 | 7  | `○ ○` | r3←r3−r' |
| `SUB r1,r1'`     | `4E` `rr'`         | 2 | 3  | `○ ○` | r1←r1−r1' |

---

### 4.22 ADC / SBC — Addition/soustraction avec Carry

| Mnémonique       | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:-----------------|:-------------------|:-------|:-------|:----|:----------|
| `ADC A,n`        | `50` `n`           | 2 | 3  | `○ ○` | A←A+n+C |
| `ADC (m),n`      | `51` `m` `n`       | 3 | 4  | `○ ○` | (m)←(m)+n+C |
| `ADC A,(n)`      | `52` `n`           | 2 | 4  | `○ ○` | A←A+(n)+C |
| `ADC (n),A`      | `53` `n`           | 2 | 4  | `○ ○` | (n)←(n)+A+C |
| `SBC A,n`        | `58` `n`           | 2 | 3  | `○ ○` | A←A−n−C |
| `SBC (m),n`      | `59` `m` `n`       | 3 | 4  | `○ ○` | (m)←(m)−n−C |
| `SBC A,(n)`      | `5A` `n`           | 2 | 4  | `○ ○` | A←A−(n)−C |
| `SBC (n),A`      | `5B` `n`           | 2 | 4  | `○ ○` | (n)←(n)−A−C |

---

### 4.23 ADCL / SBCL — Add/Sub avec Carry multi-octets

| Mnémonique        | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:------------------|:-------------------|:-------|:-------|:----|:----------|
| `ADCL (m),(n)`    | `54` `m` `n`       | 3 | 5+2×I  | `○ ○` | Boucle I : (m)←(m)+(n)+C, C propage |
| `ADCL (n),A`      | `55` `n`           | 2 | 4+I    | `○ ○` | Boucle I : (n)←(n)+A+C, C propage |
| `SBCL (m),(n)`    | `5C` `m` `n`       | 3 | 5+2×I  | `○ ○` | Boucle I : (m)←(m)−(n)−C |
| `SBCL (n),A`      | `5D` `n`           | 2 | 4+I    | `○ ○` | Boucle I : (n)←(n)−A−C |

---

### 4.24 DADL / DSBL — Arithmétique BCD

| Mnémonique        | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:------------------|:-------------------|:-------|:-------|:----|:----------|
| `DADL (m),(n)`    | `C4` `m` `n`       | 3 | 5+2×I  | `○ ○` | BCD add avec carry multi-octets (adresses décroissantes) |
| `DADL (n),A`      | `C5` `n`           | 2 | 4+I    | `○ ○` | BCD add (n)←(n)+A+C |
| `DSBL (m),(n)`    | `D4` `m` `n`       | 3 | 5+2×I  | `○ ○` | BCD sub avec borrow multi-octets |
| `DSBL (n),A`      | `D5` `n`           | 2 | 4+I    | `○ ○` | BCD sub (n)←(n)−A−C |

---

### 4.25 PMDF — Modification BCD condensée

| Mnémonique        | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:------------------|:-------------------|:-------|:-------|:----|:----------|
| `PMDF (m),n`      | `47` `m` `n`       | 3 | 4  | `- -` | (m)←(m)+n (BCD packed) |
| `PMDF (n),A`      | `57` `n`           | 2 | 4  | `- -` | (n)←(n)+A (BCD packed) |

---

### 4.26 AND / OR / XOR — Logique

| Mnémonique       | Opcode + opérandes    | Octets | Cycles | C Z | Opération |
|:-----------------|:----------------------|:-------|:-------|:----|:----------|
| `AND A,n`        | `70` `n`              | 2 | 3  | `- ○` | A←A & n |
| `AND (m),n`      | `71` `m` `n`          | 3 | 4  | `- ○` | (m)←(m) & n |
| `AND [lmn],n`    | `72` `n` `m` `l` `n2` | 5 | 7  | `- ○` | [lmn]←[lmn] & n |
| `AND (n),A`      | `73` `n`              | 2 | 4  | `- ○` | (n)←(n) & A |
| `AND A,(n)`      | `77` `n`              | 2 | 4  | `- ○` | A←A & (n) |
| `AND (m),(n)`    | `76` `m` `n`          | 3 | 6  | `- ○` | (m)←(m) & (n) |
| `OR A,n`         | `78` `n`              | 2 | 3  | `- ○` | A←A \| n |
| `OR (m),n`       | `79` `m` `n`          | 3 | 4  | `- ○` | (m)←(m) \| n |
| `OR [lmn],n`     | `7A` `n` `m` `l` `n2` | 5 | 7  | `- ○` | [lmn]←[lmn] \| n |
| `OR (n),A`       | `7B` `n`              | 2 | 4  | `- ○` | (n)←(n) \| A |
| `OR A,(n)`       | `7F` `n`              | 2 | 4  | `- ○` | A←A \| (n) |
| `OR (m),(n)`     | `7E` `m` `n`          | 3 | 6  | `- ○` | (m)←(m) \| (n) |
| `XOR A,n`        | `68` `n`              | 2 | 3  | `- ○` | A←A ^ n |
| `XOR (m),n`      | `69` `m` `n`          | 3 | 4  | `- ○` | (m)←(m) ^ n |
| `XOR [lmn],n`    | `6A` `n` `m` `l` `n2` | 5 | 7  | `- ○` | [lmn]←[lmn] ^ n |
| `XOR (n),A`      | `6B` `n`              | 2 | 4  | `- ○` | (n)←(n) ^ A |
| `XOR A,(n)`      | `6F` `n`              | 2 | 4  | `- ○` | A←A ^ (n) |
| `XOR (m),(n)`    | `6E` `m` `n`          | 3 | 6  | `- ○` | (m)←(m) ^ (n) |

---

### 4.27 TEST / CMP — Comparaison et test de bits

| Mnémonique       | Opcode + opérandes    | Octets | Cycles | C Z | Opération |
|:-----------------|:----------------------|:-------|:-------|:----|:----------|
| `TEST A,n`       | `64` `n`              | 2 | 3  | `- ○` | A & n (positionne Z) |
| `TEST (m),n`     | `65` `m` `n`          | 3 | 4  | `- ○` | (m) & n |
| `TEST [lmn],n`   | `66` `n` `m` `l` `n2` | 5 | 6  | `- ○` | [lmn] & n |
| `TEST (n),A`     | `67` `n`              | 2 | 4  | `- ○` | (n) & A |
| `CMP A,n`        | `60` `n`              | 2 | 3  | `○ ○` | A − n |
| `CMP (m),n`      | `61` `m` `n`          | 3 | 4  | `○ ○` | (m) − n |
| `CMP [lmn],n`    | `62` `n` `m` `l` `n2` | 5 | 6  | `○ ○` | [lmn] − n |
| `CMP (n),A`      | `63` `n`              | 2 | 4  | `○ ○` | (n) − A |
| `CMP (m),(n)`    | `B7` `m` `n`          | 3 | 6  | `○ ○` | (m) − (n) |
| `CMPW (m),(n)`   | `C6` `m` `n`          | 3 | 8  | `○ ○` | (m..m+1) − (n..n+1) |
| `CMPW (m),r2`    | `D6` `0r` `m`         | 3 | 7  | `○ ○` | (m..m+1) − r2 |
| `CMPP (m),(n)`   | `C7` `m` `n`          | 3 | 10 | `○ ○` | (m..m+2) − (n..n+2) |
| `CMPP (m),r3`    | `D7` `0r` `m`         | 3 | 9  | `○ ○` | (m..m+2) − r3 |

---

### 4.28 INC / DEC — Incrément / Décrément

| Mnémonique   | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:-------------|:-------------------|:-------|:-------|:----|:----------|
| `INC r`      | `6C` `0r`          | 2 | 3  | `- ○` | r←r+1 (r1, r2 ou r3) |
| `INC (n)`    | `6D` `n`           | 2 | 3  | `- ○` | (n)←(n)+1 |
| `DEC r`      | `7C` `0r`          | 2 | 3  | `- ○` | r←r−1 |
| `DEC (n)`    | `7D` `n`           | 2 | 3  | `- ○` | (n)←(n)−1 |

---

### 4.29 ROR / ROL — Rotation

| Mnémonique   | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:-------------|:-------------------|:-------|:-------|:----|:----------|
| `ROR A`      | `E4`               | 1 | 2  | `○ ○` | Rotation droite de A via C |
| `ROR (n)`    | `E5` `n`           | 2 | 3  | `○ ○` | Rotation droite de (n) via C |
| `ROL A`      | `E6`               | 1 | 2  | `○ ○` | Rotation gauche de A via C |
| `ROL (n)`    | `E7` `n`           | 2 | 3  | `○ ○` | Rotation gauche de (n) via C |

---

### 4.30 SHR / SHL — Décalage

| Mnémonique   | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:-------------|:-------------------|:-------|:-------|:----|:----------|
| `SHR A`      | `F4`               | 1 | 2  | `○ ○` | Décalage droit de A via C (C←A₀, A₇←C) |
| `SHR (n)`    | `F5` `n`           | 2 | 3  | `○ ○` | Décalage droit de (n) |
| `SHL A`      | `F6`               | 1 | 2  | `○ ○` | Décalage gauche de A via C (C←A₇, A₀←C) |
| `SHL (n)`    | `F7` `n`           | 2 | 3  | `○ ○` | Décalage gauche de (n) |

---

### 4.31 DSRL / DSLL — Décalage logique décimal multi-octets

| Mnémonique   | Opcode + opérandes | Octets | Cycles | C Z | Opération |
|:-------------|:-------------------|:-------|:-------|:----|:----------|
| `DSRL (n)`   | `FC` `n`           | 2 | 4+I  | `- ○` | Décalage droit logique décimal (I octets, adresses croissantes) |
| `DSLL (n)`   | `EC` `n`           | 2 | 4+I  | `- ○` | Décalage gauche logique décimal (I octets, adresses décroissantes) |

---

## 5. Table récapitulative des opcodes (ordre numérique)

| Opcode | Mnémonique           | Opcode | Mnémonique           | Opcode | Mnémonique           | Opcode | Mnémonique           |
|:-------|:---------------------|:-------|:---------------------|:-------|:---------------------|:-------|:---------------------|
| `00`   | NOP                  | `40`   | ADD A,n              | `80`   | MV A,(n)             | `C0`   | EX (m),(n)           |
| `01`   | RETI                 | `41`   | ADD (m),n            | `81`   | MV IL,(n)            | `C1`   | EXW (m),(n)          |
| `02`   | JP mn                | `42`   | ADD A,(n)            | `82`   | MV BA,(n)            | `C2`   | EXP (m),(n)          |
| `03`   | JPF lmn              | `43`   | ADD (n),A            | `83`   | MV I,(n)             | `C3`   | EXL (m),(n)          |
| `04`   | CALL mn              | `44`   | ADD r2,r'            | `84`   | MV X,(n)             | `C4`   | DADL (m),(n)         |
| `05`   | CALLF lmn            | `45`   | ADD r3,r'            | `85`   | MV Y,(n)             | `C5`   | DADL (n),A           |
| `06`   | RET                  | `46`   | ADD r1,r1'           | `86`   | MV U,(n)             | `C6`   | CMPW (m),(n)         |
| `07`   | RETF                 | `47`   | PMDF (m),n           | `87`   | MV S,(n)             | `C7`   | CMPP (m),(n)         |
| `08`   | MV A,n               | `48`   | SUB A,n              | `88`   | MV A,[lmn]           | `C8`   | MV (m),(n)           |
| `09`   | MV IL,n              | `49`   | SUB (m),n            | `89`   | MV IL,[lmn]          | `C9`   | MVW (m),(n)          |
| `0A`   | MV BA,mn             | `4A`   | SUB A,(n)            | `8A`   | MV BA,[lmn]          | `CA`   | MVP (m),(n)          |
| `0B`   | MV I,mn              | `4B`   | SUB (n),A            | `8B`   | MV I,[lmn]           | `CB`   | MVL (m),(n)          |
| `0C`   | MV X,lmn             | `4C`   | SUB r2,r'            | `8C`   | MV X,[lmn]           | `CC`   | MV (m),n             |
| `0D`   | MV Y,lmn             | `4D`   | SUB r3,r'            | `8D`   | MV Y,[lmn]           | `CD`   | MVW (l),mn           |
| `0E`   | MV U,lmn             | `4E`   | SUB r1,r1'           | `8E`   | MV U,[lmn]           | `CE`   | TCP (TCL)            |
| `0F`   | MV S,lmn             | `4F`   | PUSHS F              | `8F`   | MV S,[lmn]           | `CF`   | MVLD (m),(n)         |
| `10`   | JP (n)               | `50`   | ADC A,n              | `90`   | MV A,[r3]            | `D0`   | MV (k),[lmn]         |
| `11`   | JP r3                | `51`   | ADC (m),n            | `91`   | MV IL,[r3]           | `D1`   | MVW (k),[lmn]        |
| `12`   | JR +n                | `52`   | ADC A,(n)            | `92`   | MV BA,[r3]           | `D2`   | MVP (k),[lmn]        |
| `13`   | JR -n                | `53`   | ADC (n),A            | `93`   | MV I,[r3]            | `D3`   | MVL (k),[lmn]        |
| `14`   | JPZ mn               | `54`   | ADCL (m),(n)         | `94`   | MV X,[r3]            | `D4`   | DSBL (m),(n)         |
| `15`   | JPNZ mn              | `55`   | ADCL (n),A           | `95`   | MV Y,[r3]            | `D5`   | DSBL (n),A           |
| `16`   | JPC mn               | `56`   | MVL (m),[r3±n]       | `96`   | MV U,[r3]            | `D6`   | CMPW (m),r2          |
| `17`   | JPNC mn              | `57`   | PMDF (n),A           | `97`   | SC                   | `D7`   | CMPP (m),r3          |
| `18`   | JRZ +n               | `58`   | SBC A,n              | `98`   | MV A,[(n)]           | `D8`   | MV [lmn],(n)         |
| `19`   | JRZ -n               | `59`   | SBC (m),n            | `99`   | MV IL,[(n)]          | `D9`   | MVW [lmn],(n)        |
| `1A`   | JRNZ +n              | `5A`   | SBC A,(n)            | `9A`   | MV BA,[(n)]          | `DA`   | MVP [lmn],(n)        |
| `1B`   | JRNZ -n              | `5B`   | SBC (n),A            | `9B`   | MV I,[(n)]           | `DB`   | MVL [lmn],(n)†       |
| `1C`   | JRC +n               | `5C`   | SBCL (m),(n)         | `9C`   | MV X,[(n)]           | `DC`   | MVP (k),lmn          |
| `1D`   | JRC -n               | `5D`   | SBCL (n),A           | `9D`   | MV Y,[(n)]           | `DD`   | EX A,B               |
| `1E`   | JRNC +n              | `5E`   | MVL [r3±m],(n)       | `9E`   | MV U,[(n)]           | `DE`   | HALT                 |
| `1F`   | JRNC -n              | `5F`   | POPS F               | `9F`   | RC                   | `DF`   | OFF                  |
| `20`–`37` | **Octets PRE** *(voir §2)* | `60` | CMP A,n    | `A0`   | MV (n),A             | `E0`   | MV (n),[r3]          |
| `38`   | POPU A               | `61`   | CMP (m),n            | `A1`   | MV (n),IL            | `E1`   | MVW (n),[r3]         |
| `39`   | POPU IL              | `62`   | CMP [lmn],n          | `A2`   | MV (n),BA            | `E2`   | MVP (n),[r3]         |
| `3A`   | POPU BA              | `63`   | CMP (n),A            | `A3`   | MV (n),I             | `E3`   | MVL (n),[r3±]        |
| `3B`   | POPU I               | `64`   | TEST A,n             | `A4`   | MV (n),X             | `E4`   | ROR A                |
| `3C`   | POPU X               | `65`   | TEST (m),n           | `A5`   | MV (n),Y             | `E5`   | ROR (n)              |
| `3D`   | POPU Y               | `66`   | TEST [lmn],n         | `A6`   | MV (n),U             | `E6`   | ROL A                |
| `3E`   | POPU F               | `67`   | TEST (n),A           | `A7`   | MV (n),S             | `E7`   | ROL (n)              |
| `3F`   | POPU IMR             | `68`   | XOR A,n              | `A8`   | MV [lmn],A           | `E8`   | MV [r3],(n)          |
| `28`   | PUSHU A              | `69`   | XOR (m),n            | `A9`   | MV [lmn],IL          | `E9`   | MVW [r3],(n)         |
| `29`   | PUSHU IL             | `6A`   | XOR [lmn],n          | `AA`   | MV [lmn],BA          | `EA`   | MVP [r3],(n)         |
| `2A`   | PUSHU BA             | `6B`   | XOR (n),A            | `AB`   | MV [lmn],I           | `EB`   | MVL [r3±],(n)        |
| `2B`   | PUSHU I              | `6C`   | INC r                | `AC`   | MV [lmn],X           | `EC`   | DSLL (n)             |
| `2C`   | PUSHU X              | `6D`   | INC (n)              | `AD`   | MV [lmn],Y           | `ED`   | EX r2,r2' / r3,r3'   |
| `2D`   | PUSHU Y              | `6E`   | XOR (m),(n)          | `AE`   | MV [lmn],U           | `EE`   | SWAP A               |
| `2E`   | PUSHU F              | `6F`   | XOR A,(n)            | `AF`   | MV [lmn],S           | `EF`   | WAIT                 |
| `2F`   | PUSHU IMR            | `70`   | AND A,n              | `B0`   | MV [r3],A            | `F0`   | MV (m),[(n)]         |
| —      |                      | `71`   | AND (m),n            | `B1`   | MV [r3],IL           | `F1`   | MVW (m),[(n)]        |
| —      |                      | `72`   | AND [lmn],n          | `B2`   | MV [r3],BA           | `F2`   | MVP (m),[(n)]        |
| —      |                      | `73`   | AND (n),A            | `B3`   | MV [r3],I            | `F3`   | MVL (m),[(n)]        |
| —      |                      | `74`   | MV A,B               | `B4`   | MV [r3],X            | `F4`   | SHR A                |
| —      |                      | `75`   | MV B,A               | `B5`   | MV [r3],Y            | `F5`   | SHR (n)              |
| —      |                      | `76`   | AND (m),(n)          | `B6`   | MV [r3],U            | `F6`   | SHL A                |
| —      |                      | `77`   | AND A,(n)            | `B7`   | CMP (m),(n)          | `F7`   | SHL (n)              |
| —      |                      | `78`   | OR A,n               | `B8`   | MV [(n)],A           | `F8`   | MV [(m)],(n)         |
| —      |                      | `79`   | OR (m),n             | `B9`   | MV [(n)],IL          | `F9`   | MVW [(m)],(n)        |
| —      |                      | `7A`   | OR [lmn],n           | `BA`   | MV [(n)],BA          | `FA`   | MVP [(m)],(n)        |
| —      |                      | `7B`   | OR (n),A             | `BB`   | MV [(n)],I           | `FB`   | MVL [(m)],(n)        |
| —      |                      | `7C`   | DEC r                | `BC`   | MV [(n)],X           | `FC`   | DSRL (n)             |
| —      |                      | `7D`   | DEC (n)              | `BD`   | MV [(n)],Y           | `FD`   | MV r,r&#39; (reg–reg)   |
| —      |                      | `7E`   | OR (m),(n)           | `BE`   | MV [(n)],U           | `FE`   | IR                   |
| —      |                      | `7F`   | OR A,(n)             | `BF`   | *(réservé)*          | `FF`   | RESET                |

> ⛔ **Corrigé le 2026-08-06.** Ce document portait ici : « `DA` et `DB` : certaines sources les
> attribuent à des variantes MVW/MVL — à confirmer sur silicium », et la ligne `DA` de la table
> ci-dessus disait `MVW [r3],(n)`, ce qui contredisait sa propre ligne `D9`. **Aucun silicium n'est
> nécessaire**, et deux sources concordent :
>
> 1. **La table 16×16 de Sharp** (dernière page du manuel du CPU) donne `DA` = `MVP [lmn],(n)` et
>    `DB` = `MVL [lmn],(n)`, cinq octets — exactement la suite de `D8` `MV` et `D9` `MVW`.
> 2. **Le corpus les exerce et les reconstruit.** Le désassembleur en décode huit occurrences dans
>    les programmes réels — `DA D5 FC 0B 00` → `mvp [intv_sio_rx],(000h)` dans `MAPPE`,
>    `DA 07 E0 0B 00` → `mvp [LOC_BE007],(000h)` dans `MEMCHECK` — et ces programmes se
>    **réassemblent octet pour octet** par XASM. Une longueur ou un mnémonique faux ne survivrait
>    pas à l'aller-retour.

---

## 6. Correspondances XASM ↔ documentation CPU

| Mném. XASM    | Mném. doc CPU | Opcode | Remarque |
|:--------------|:--------------|:-------|:---------|
| `TCP`         | `TCL`         | `CE`   | Alias dans l'assembleur XASM (INIT.C `add_hash("TCP",56)`) |
| `ADDB`        | *(non documenté)* | —  | Instruction étendue XASM (registre word, undocumented) |
| `ADDW`        | *(non documenté)* | —  | Idem |
| `ADDP`        | *(non documenté)* | —  | Idem |
| `SUBB`        | *(non documenté)* | —  | Idem |
| `SUBW`        | *(non documenté)* | —  | Idem |
| `SUBP`        | *(non documenté)* | —  | Idem |
| `SC`          | `SC`          | `97`   | 1 octet, pas d'opérande — la table vue d'ensemble note "SC (n)" par erreur typographique |
| `RC`          | `RC`          | `9F`   | 1 octet, pas d'opérande |

---

## 7. Notes de codification XASM 2026

D'après `xasm2026.md`, les points suivants sont confirmés :

- **Toutes les mnémoniques XASM 1.40 sont conservées** (ORG, EQU, LOCAL, ENDL, DB/DM/DW/DP/DS, INCLUDE, MACRO/ENDM, DEF/UNDEF, IFDEF/IFNDEF, SCOPE_ON/OFF, PRE_ON/OFF/PUSH/POP).
- **Nouvelles directives 2026** (n'ajoutent aucune instruction CPU) : `REPEAT/ENDR`, `IFEQ/IFNE/IFGT/IFLT`, `STRUCT/ENDS`, `SECTION`.
- La directive `PRE` en source = insertion manuelle d'un octet de préfixe ; `PRE_ON/OFF` active/désactive la génération automatique.
- Les labels hiérarchiques XASM (`LOCAL/ENDL`) n'ont aucun impact sur les opcodes générés.
- Le format objet par défaut inclut un **en-tête XASM de 16 octets** avant le code machine.
