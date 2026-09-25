# Rapport de bug — `cmp a,(n)` accepté à tort et mal encodé (opcode 0x62)

**Composant** : xasm2026-4 (assembleur SC62015)
**Gravité** : **critique** — l'assembleur produit **silencieusement** un objet mal formé
qui **désynchronise l'exécution** sur la vraie machine (plantage).
**Type** : régression de non-régression (le moteur C de référence, lui, **refuse** cette forme).
**Découvert le** : 2026-09-15, en portant la fonction `INSTR` d'une extension BASIC
(`STREXT.ASM`, aujourd'hui `C:\Claude\BASEXT\src\STREXT.ASM`).

> ✅ **Corrigé le 2026-09-15.** `EmitCompare` refuse `A,(n)` ; le codeur logique refuse
> `test A,(n)` et `test (m),(n)` (`src/Assembly/NativeAssembler.cs`). Test négatif :
> `BehaviorTests.cs` (5 formes : `cmp a,(005H)`, `cmp a,(BP+5)`, `cmp a,(0)`,
> `test a,(BP+1)`, `test a,(16)`). Vérifié : suite complète 293/293 ; `dist\xasm2026-4.exe`
> rend `Undefined instruction` sur les lignes 4 et 6 de la reproduction ; les formes
> valides restent intactes (`60 5A`, `63 05`, `30 63 05`, `67 01`, `64 5A`,
> `42/4A/52/5A/77/7F/6F 01`, `61 01 5A`, `62 45 23 01 5A`).

---

## 1. Résumé

`xasm2026-4` **accepte** la forme `cmp a,(n)` (comparer l'accumulateur `A` à un
emplacement de **RAM interne**), y compris `cmp a,(BP+n)` et `cmp a,(nnH)`, alors que
**cette instruction n'existe pas** dans le jeu SC62015. Il l'encode sur l'opcode **`0x62`**,
qui est en réalité `CMP [lmn],n` — une instruction **de 5 octets** (mémoire externe 20 bits
comparée à un immédiat). L'assembleur n'émet que **2 octets** (`62 nn`). L'objet est donc
tronqué : le CPU, à l'exécution, lit `0x62` comme une instruction de **5 octets**, avale les
**3 octets suivants** comme adresse + **1** comme immédiat, et part en désynchronisation.

Le moteur C historique (`xasm2026-1-2`) **refuse** la même source avec `Undefined instruction`.

---

## 2. Reproduction minimale

```asm
        org     0BF000H
        pre_on
        cmp     a,05AH          ; ligne 3 : cmp a,imm      -> OK
        cmp     a,(BP+5)        ; ligne 4 : cmp a,(n)      -> FAUTIF
        cmp     (BP+5),a        ; ligne 5 : cmp (n),a      -> OK
        cmp     a,(005H)        ; ligne 6 : cmp a,(n) direct -> FAUTIF
        end
```

```
xasm2026-4 cmptest.asm -O -L
```

### Sortie de `xasm2026-4` (listing) — **BUG**
```
0BF000 60 5A             cmp     a,05AH          ; correct (0x60 = CMP A,n)
0BF002 62 05             cmp     a,(BP+5)         ; <-- 0x62 emis, 2 octets seulement
0BF004 63 05             cmp     (BP+5),a         ; correct (0x63 = CMP (n),A)
0BF006 30 62 05          cmp     a,(005H)         ; <-- PRE 30 + 0x62, meme bug
```
`  No fatal error.` — l'assembleur **ne signale rien**.

### Sortie du moteur C de référence `xasm2026-1-2` sur la même source — **correct**
```
cmpref.asm   4   Undefined instruction
cmpref.asm   6   Undefined instruction
 Fatal error occured.
```
Les lignes 4 et 6 (`cmp a,(BP+5)` et `cmp a,(005H)`) sont **rejetées** ; les lignes 3 et 5
(formes valides) passent. **C'est le comportement attendu.**

---

## 3. Pourquoi c'est faux — analyse à l'octet

L'opcode `0x62` est `CMP [lmn],n` (longueur **5** : opcode + adresse 20 bits sur 3 octets +
immédiat 1 octet), d'après `OpcodeTable.json` du désassembleur (concordant avec le manuel
Sharp) :

```
0x60  CMP  A,n       len 2
0x61  CMP  (m),n     len 3
0x62  CMP  [lmn],n   len 5      <-- ce que xasm emet pour "cmp a,(n)"
0x63  CMP  (n),A     len 2
0xB7  CMP  (m),(n)   len 3
```

**Il n'existe aucun `CMP A,(n)`.** Le CPU décode donc `62 05 ...` comme les 5 premiers octets
d'un `CMP [lmn],n`. Exemple réel qui plantait, désassemblé par `e500dasm` :

```
0BF2D5 62 05 1C 04 18   cmp [041C05h],018h     ; 5 octets : avale le "jrc" qui suivait
0BF2FB 62 06 1A 0E 7C   cmp [0E1A06h],07Ch     ; idem
0BF300 01               reti                    ; <-- octet orphelin decode en RETI -> retour MENU
```

Le `1C 04` avalé était un `jrc` ; l'exécution saute n'importe où, tombe sur un `01` (RETI) et
la machine **revient au MENU principal**. Symptôme mesuré sur émulateur PockEmul (PC-E500S).

Avec le correctif `cmp (n),a` (opcode `0x63`, 2 octets), le même code se **resynchronise** :
```
0BF2D5 63 05            cmp (005h),a
0BF2D7 1C 3E            jrc LOC_BF317          ; le jrc n'est plus avale
0BF2F7 63 06            cmp (006h),a
0BF2FD 1B 0E            jrnz LOC_BF2F1         ; la boucle reboucle correctement
```

---

## 4. Cause probable

Les familles arithmétiques/logiques ont **toutes** une forme `A,(n)` sauf **CMP** (et **TEST**) :

| Famille | `A,(n)` | opcode |
|---|---|---|
| ADD | oui | 0x42 |
| SUB | oui | 0x4A |
| ADC | oui | 0x52 |
| SBC | oui | 0x5A |
| AND | oui | 0x77 |
| OR  | oui | 0x7F |
| XOR | oui | 0x6F |
| **CMP** | **NON** | — |
| **TEST** | **NON** | — |

Le codeur d'opérandes de `CMP` semble, faute de trouver un `A,(n)`, **retomber** sur le
gabarit `[lmn],n` (0x62) — au lieu de refuser la forme. La présence d'un `A,(n)` valide pour
ADD/SUB/… masque le problème pour ces familles ; il n'apparaît que sur CMP (et TEST).

---

## 5. Portée — un second cas, silencieux

`TEST A,(n)` n'existe pas non plus. `xasm2026-4` encode `test a,(BP+1)` en **`6B 01`**, soit
l'opcode `0x6B` = **`XOR (n),A`** (2 octets). Ici pas de désynchronisation (bonne longueur),
mais **mauvaise opération** — et pire, `XOR (n),A` **écrit** en mémoire alors que `TEST` ne
doit rien modifier. À vérifier et corriger dans le même geste que CMP.

Les formes `A,(n)` **valides** (ADD/SUB/ADC/SBC/AND/OR/XOR) sont, elles, correctement encodées
(`42/4A/52/5A/77/7F/6F 01`) — **ne pas y toucher**.

---

## 6. Comportement attendu

`cmp a,(n)`, `cmp a,(BP+n)`, `cmp a,(nnH)` (et `test a,(n)` sous toutes ses formes) doivent
être **rejetés** avec l'erreur `Undefined instruction`, exactement comme le moteur C de
référence — plutôt que d'émettre un opcode faux.

Le programmeur doit employer la forme réellement existante `cmp (n),a` (opcode 0x63), en
tenant compte de l'**inversion des opérandes** : `cmp (n),a` calcule `(n) - A` (donc retenue
et « inférieur/supérieur » inversés par rapport à un hypothétique `cmp a,(n)` ; l'égalité,
elle, est identique).

---

## 7. Piste de correction

Dans la table/logique d'encodage des opérandes de `CMP` (et `TEST`) : ne pas autoriser
`A,(n)` à retomber sur le gabarit `[lmn],n` (0x62 / 0x66). Si aucun opcode `A,(n)` n'existe
pour la famille, **émettre `Undefined instruction`**. Un test de non-régression dédié
(assembler `cmp a,(0)` et attendre un refus) verrouillerait le point.

> Remarque : `ListingReproductionTests` et `ReassemblyTests` ne l'ont pas attrapé car aucun
> programme du corpus n'emploie `cmp a,(n)` (le corpus a été écrit avec le moteur C, qui la
> refuse). Un test négatif — « ces formes doivent échouer » — est donc le bon garde-fou,
> dans l'esprit des « 2 formes que l'assembleur doit refuser » déjà présentes dans
> `tests/postbyte_families`.
