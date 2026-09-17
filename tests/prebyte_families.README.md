# `prebyte_families` — l'octet PRE

Jeu d'essai systématique de l'**octet PRE** (« prébit ») : l'octet placé **avant l'opcode** qui
fixe le mode d'adressage des opérandes de RAM interne. Sous `pre_on`, `(n)` est une adresse
absolue et reçoit un PRE ; `(BP+n)` est le mode par défaut du CPU et n'en reçoit pas. Une erreur
ici donne un objet plausible mais faux : PRE absent (l'instruction lit en `(BP+n)`, ailleurs),
PRE après l'opcode (le CPU se désynchronise), ou deux PRE au lieu d'un.

| Fichier | Rôle |
|---|---|
| `prebyte_families.expected.txt` | `mode <TAB> instruction <TAB> octets` — ou `(refus attendu)` |
| `../tools/gen_prebyte_families.py` | le générateur, qui interroge le moteur C |
| `Xasm2026.Tests/PrebyteFamiliesTests.cs` | la comparaison, branchée sur `dotnet test` |

## Ce qui est couvert

Toutes les instructions qui portent un opérande de RAM interne direct (d'après
`SC62015Disassembler/Data/OpcodeTable.json`) : arithmétique et logique `(m),n`, `(n),A`, `A,(n)` ;
`ADCL`/`SBCL`/`DADL`/`DSBL` ; `PMDF` ; `CMP`/`CMPW`/`CMPP` ; `INC`…`DSRL (n)` ; `MV r,(n)`,
`MV (n),r`, `MV r,[(n)]`, `MV [(n)],r` pour les huit registres ; `MV`/`MVW`/`MVP (m),imm` ;
`MV`…`EXL (m),(n)` ; `MV`/`MVW`/`MVP`/`MVL` avec `[lmn]`, `[y]`, `[y++]`, `[--y]`, `[y±2]`,
`[(n)]`, `[(n)±2]` dans les deux sens ; `JP (n)`.

Chaque forme est déclinée sur les modes qui changent le PRE — `(n)`, `(BP+n)`, `(PX+n)`,
`(PY+n)`, et pour les formes à deux opérandes internes les combinaisons de `(n)`, `BP+n`, `PX+n`,
`BP+PX` (premier) et `(n)`, `BP+n`, `PY+n`, `BP+PY` (second) — puis assemblée sous `pre_on` **et**
`pre_off`. Soit **2520 cas**, dont 322 que le moteur C refuse.

## D'où viennent les octets attendus

Du moteur C de référence `Reference/C/xasm2026-1-2.exe`, qui encode ces formes juste (vérifié
contre le manuel Sharp et le désassembleur). Chaque instruction est assemblée **seule**, à
`0BF000h` ; les octets de code sont lus dans l'objet, en-tête de 16 octets sauté. Une forme que le
moteur C refuse (`Undefined instruction`, `Prebyte error`) doit être refusée aussi.

Régénérer (après avoir ajouté des formes au générateur) :

```powershell
python .\tools\gen_prebyte_families.py
dotnet test .\tests\Xasm2026.Tests\Xasm2026.Tests.csproj -c Release --filter PrebyteFamiliesTests
```

## Ce que ce jeu a révélé *(corrigé le 2026-09-17)*

**224 divergences sous `pre_on`, 65 sous `pre_off`**, sur neuf défauts — plus larges que les sept
familles de `RAPPORT-BUG-octet-pre.md`, qui ne testait que `(n)` sous `pre_on` :

| Forme | Avant | Moteur C |
|---|---|---|
| `mvp [y],(00BH)` (et tous les index) | `EA 05 0B` | `30 EA 05 0B` — PRE absent |
| `mvw [y],(00BH)` (et tous les index) | `E9 05 30 0B` | `30 E9 05 0B` — PRE après l'opcode |
| `mvp (00CH),[(00BH)]`, `mvp [(00CH)],(00BH)` | `F2 00 0C 0B` | `32 F2 00 0C 0B` — PRE absent |
| `mvw [(00CH)],(00BH)` | `F9 00 30 0C 30 0B` | `32 F9 00 0C 0B` — deux PRE simples au milieu |
| `mv (00CH),[(00BH)]` | `30 32 F0 00 0C 0B` | `32 F0 00 0C 0B` — PRE doublé |
| `mv (BP+4),[(BP+3)]` | `F0 80 04 03 00` | `F0 00 04 03` — sous-octet et déplacement parasites |
| `mvl (00BH),[lmn]`, `mvl [lmn],(00BH)` | `D3 30 0B …`, `DB … 30 0B` | `30 D3 0B …`, `30 DB … 0B` |
| `jp (00BH)` | `02 0B 00` (saut direct) | `30 10 0B` (saut indirect) |
| `mv s,[(n)]`, `mv [(n)],s` | `9F …`, `BF …` | refusé : la famille `98`–`9E` s'arrête à U |
| `mvw [(m)],(PY+n)`, sous `pre_off` | refusé | `F9 00 0C 03` — le PRE combiné est légal |

La cause commune : `InternalRamOffset` **émet le PRE en effet de bord**. Toute branche qui
l'appelait après l'opcode le plaçait au milieu de l'instruction ; celles qui lisaient l'opérande
par un simple `Eval` le perdaient ; et deux appels successifs donnaient deux PRE simples au lieu
d'un PRE combiné. La famille `F0`–`FB` passe désormais par un encodeur unique,
`EmitMemoryPointerTransfer`, qui calcule le PRE des deux opérandes et l'émet en tête.

Les goldens, `postbyte_families`, `PLINKC.OBJ` et `BASEXT` (2709 octets, identique au moteur C)
sont inchangés : le corpus écrivait ces formes en `(BP+n)`, sans PRE.
