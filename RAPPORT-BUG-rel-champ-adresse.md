# Rapport de bug — `rel` situe mal le champ d'adresse : table de relocation fausse

> ✅ **Corrigé le 2026-09-17.** Le champ est relevé au moment où l'adresse est émise, et `rel` sans
> adresse absolue unique est refusé. `RelocationSitesTests` applique l'oracle du §6 aux 27 formes
> + `DP`/`DW`. Sur BASEXT (144 sites), la table émise égale celle de `reloc.py` et reloge l'objet
> sans un octet faux. Détail : `PORTAGE.md`.

**Composant** : xasm2026-4 (assembleur SC62015), préprocesseur A62, préfixe `rel`
**Gravité** : **critique** — la table de relocation est **fausse en silence** (`No fatal error`).
Un pilote relogé avec elle s'installe, puis **corrompt ses propres instructions** : opcode
écrasé, adresse relogée d'un octet à côté.
**Type** : heuristique de position incomplète ; aucun test ne couvre les formes en cause.
**Découvert le** : 2026-09-16, en préparant `C:\Claude\BASEXT-DRV` (BASEXT résident sous forme
de pilote), par confrontation avec une table mesurée par double assemblage.

> Ce rapport est destiné à être **corrigé dans xasm2026-4** ; rien n'a été modifié dans le
> dépôt. Le défaut voisin sur `MVL` et l'octet PRE fait l'objet d'un rapport à part :
> `RAPPORT-BUG-octet-pre.md`.

---

## 1. Résumé

Pour une ligne `rel <instruction>`, `NativeAssembler.cs` enregistre le site de relocation ainsi
(l. 720-728) :

```csharp
if (relLine && emit)
{
    var width = mnemonic is "CALL" or "JP" ? 2 : 3;
    _relocSites.Add((result.GeneratedBytes.Count - width, width));
}
```

Deux suppositions, toutes deux fausses en général :

1. **le champ d'adresse occupe les derniers octets** de l'instruction ;
2. **seuls `CALL` et `JP` ont un champ de 2 octets.**

Sur les **27 formes** du jeu SC62015 qui portent une adresse absolue (plus `DP` et `DW`),
**14 produisent une entrée fausse**. S'y ajoute un troisième défaut : `rel` devant une
instruction **sans** adresse est accepté, et peut produire un écart négatif encodé `0FFh`,
c'est-à-dire **le terminateur** de la table (§5).

Le moteur C `xasm2026-1-2` n'a pas de `rel` : il n'y a pas de référence à laquelle comparer. La
référence, ici, est la **mesure** : assembler la même source à deux origines et relever les
octets qui changent (§6).

---

## 2. Reproduction — l'inventaire complet

Les formes viennent de `SC62015Disassembler/Data/OpcodeTable.json` : tous les opcodes dont un
opérande est `mn` ou `lmn`.

```asm
        org     0BF000H
        pre_on
        rel jp      cible
        rel call    cible
        rel jpz     cible
        rel jpnz    cible
        rel jpc     cible
        rel jpnc    cible
        rel jpf     cible
        rel callf   cible
        rel mv      x,v
        rel mv      a,[v]
        rel mv      [v],a
        rel mv      (0D6H),[v]
        rel mvw     (0D6H),[v]
        rel mvp     (0D6H),[v]
        rel mvl     (0D6H),[v]
        rel mvp     (0D6H),v
        rel cmp     [v],012H
        rel test    [v],012H
        rel xor     [v],012H
        rel and     [v],012H
        rel or      [v],012H
        rel mv      [v],(0D6H)
        rel mvw     [v],(0D6H)
        rel mvp     [v],(0D6H)
        rel mvl     [v],(0D6H)
        rel dp      v
        rel dw      v
cible:  retf
v:      db      0
fin:
        end
```

```
xasm2026-4 RELFORM.ASM -O -L
```

`No fatal error.` Table décodée (offsets depuis le début de l'instruction), comparée au champ
réel mesuré :

| Instruction | Octets | Champ réel (offset, largeur) | Entrée `rel` | |
|---|---|---|---|---|
| `jp cible` | `02 7A F0` | +1, 2 | +1, 2 | juste |
| `call cible` | `04 7A F0` | +1, 2 | +1, 2 | juste |
| `jpz cible` | `14 7A F0` | +1, 2 | **+0, 3** | ⛔ **FAUX** |
| `jpnz cible` | `15 7A F0` | +1, 2 | **+0, 3** | ⛔ **FAUX** |
| `jpc cible` | `16 7A F0` | +1, 2 | **+0, 3** | ⛔ **FAUX** |
| `jpnc cible` | `17 7A F0` | +1, 2 | **+0, 3** | ⛔ **FAUX** |
| `jpf cible` | `03 7A F0 0B` | +1, 3 | +1, 3 | juste |
| `callf cible` | `05 7A F0 0B` | +1, 3 | +1, 3 | juste |
| `mv x,v` | `0C 7B F0 0B` | +1, 3 | +1, 3 | juste |
| `mv a,[v]` | `88 7B F0 0B` | +1, 3 | +1, 3 | juste |
| `mv [v],a` | `A8 7B F0 0B` | +1, 3 | +1, 3 | juste |
| `mv (0D6H),[v]` | `30 D0 D6 7B F0 0B` | +3, 3 | +3, 3 | juste |
| `mvw (0D6H),[v]` | `30 D1 D6 7B F0 0B` | +3, 3 | +3, 3 | juste |
| `mvp (0D6H),[v]` | `30 D2 D6 7B F0 0B` | +3, 3 | +3, 3 | juste |
| `mvl (0D6H),[v]` | `D3 30 D6 7B F0 0B` ⚠️ | +3, 3 | +3, 3 | juste (mais voir `RAPPORT-BUG-octet-pre.md`) |
| `mvp (0D6H),v` | `30 DC D6 7B F0 0B` | +3, 3 | +3, 3 | juste |
| `cmp [v],012H` | `62 7B F0 0B 12` | +1, 3 | **+2, 3** | ⛔ **FAUX** |
| `test [v],012H` | `66 7B F0 0B 12` | +1, 3 | **+2, 3** | ⛔ **FAUX** |
| `xor [v],012H` | `6A 7B F0 0B 12` | +1, 3 | **+2, 3** | ⛔ **FAUX** |
| `and [v],012H` | `72 7B F0 0B 12` | +1, 3 | **+2, 3** | ⛔ **FAUX** |
| `or [v],012H` | `7A 7B F0 0B 12` | +1, 3 | **+2, 3** | ⛔ **FAUX** |
| `mv [v],(0D6H)` | `30 D8 7B F0 0B D6` | +2, 3 | **+3, 3** | ⛔ **FAUX** |
| `mvw [v],(0D6H)` | `30 D9 7B F0 0B D6` | +2, 3 | **+3, 3** | ⛔ **FAUX** |
| `mvp [v],(0D6H)` | `30 DA 7B F0 0B D6` | +2, 3 | **+3, 3** | ⛔ **FAUX** |
| `mvl [v],(0D6H)` | `DB 7B F0 0B 30 D6` ⚠️ | +1, 3 | **+3, 3** | ⛔ **FAUX** |
| `dp v` | `7B F0 0B` | +0, 3 | +0, 3 | juste |
| `dw v` | `7B F0` | +0, 2 | **−1, 3** | ⛔ **FAUX** (déborde sur l'octet précédent) |

**Les trois familles fautives** :

| Famille | Opcodes | Défaut |
|---|---|---|
| sauts conditionnels proches `JPZ`/`JPNZ`/`JPC`/`JPNC mn` | `14h`–`17h` | largeur 3 au lieu de 2 : l'entrée commence **sur l'opcode** |
| adresse **suivie d'un octet** : `CMP`/`TEST`/`XOR`/`AND`/`OR [lmn],n` ; `MV`/`MVW`/`MVP`/`MVL [lmn],(n)` | `62h` `66h` `6Ah` `72h` `7Ah` ; `D8h`–`DBh` | l'entrée est décalée d'un octet vers la fin |
| donnée `DW` | — | largeur 3 au lieu de 2, commence un octet trop tôt |

---

## 3. Ce que la relocation en fait

L'installateur de PLINKC (et tout installateur au format Kon) ajoute l'écart de chargement aux
octets désignés. Sur une entrée fausse :

- **`jpnz cible`** relogé de `+0, 3` : l'opcode `15h` reçoit l'octet bas de l'écart. Le CPU
  exécute **une autre instruction**, et la suite se désynchronise ;
- **`cmp [v],012H`** relogé de `+2, 3` : l'octet bas de l'adresse reste faux, l'immédiat `12h`
  est modifié ; l'instruction garde sa longueur mais compare une autre case à une autre valeur ;
- **`mv [v],(0D6H)`** relogé de `+3, 3` : l'adresse est à moitié relogée et l'adresse de RAM
  interne `D6h` change — **écriture à une adresse arbitraire**.

Rien ne le signale, ni à l'assemblage, ni à l'installation.

### Mesure sur un programme réel

`C:\Claude\BASEXT\src\BASEXT.ASM` (14 mots-clés BASIC, 2709 octets, validé sur machine) a été
recopié avec `rel` devant ses **144** sites relogeables : 130 instructions, plus les 14 entrées
de sa table de répartition réécrites en `rel dp routine+0400000h` (code **identique à l'octet**
à `BASEXT.OBJ`). Résultat :

- table émise : 147 octets, 144 entrées, dont **12 décalées d'un octet**, toutes sur
  `mv [!sv_bp0],(bp_ram)`, `mv [!sv_bp1],(bp_ram)`, `mvp [!sv_a],(BP+n)` (`30 D8 B9 F6 0B EC`) ;
- objet relogé à une autre origine avec cette table : **48 octets faux**.

---

## 4. Pourquoi PLINKC n'a rien montré

`Exemples/PLINKC/A62/plinkc.a62.asm` (30 `rel` et 30 `bsr` = `rel call`) n'emploie que des formes
où l'adresse est **en fin** d'instruction, sur 3 octets, ou des `call` : `rel mv x,rcv`,
`rel mv [getmpb+1],x`, `rel mv ba,[sect_number]`, `rel mvw (sect_num),[sect_number]`,
`rel dp devmain`, `bsr`. L'heuristique y tombe juste à chaque fois ; l'objet est donc identique à
`PLINKC.OBJ`, et le test de reproduction passe **sans** couvrir les formes fautives.

---

## 5. Défaut annexe — `rel` devant une instruction sans adresse

```asm
        org     0BF000H
        rel mv      a,05H
        rel jr      ici
ici:    rel nop
        end
```

`No fatal error.` Objet : `08 05 12 00 00` puis la table **`FF 82 81 FF`**. Le premier site vaut
`2 − 3 = −1` ; l'écart `−1` est encodé `(byte)(−1 | 080h)` = **`0FFh`**, le **terminateur**. Tout
lecteur Kon s'arrête là : la table paraît vide, et les deux entrées qui suivent sont lues comme
du code ou des données.

**Attendu** : une erreur d'assemblage, `rel` n'ayant de sens que devant une instruction qui porte
**exactement une** adresse absolue (`mn` ou `lmn`), ou devant `DP`/`DW`.

---

## 6. Comportement attendu, et l'oracle de test

**Attendu** : l'entrée désigne **les octets où l'encodeur a écrit l'adresse**, avec **leur
largeur** : 2 pour `mn` (`JP`, `CALL`, `JPZ`, `JPNZ`, `JPC`, `JPNC`, `DW`), 3 pour `lmn` (`JPF`,
`CALLF`, `MV r,lmn`, toutes les formes `[lmn]`, `MVP (k),lmn`, `DP`). Refus sinon (§5).

**Oracle** : il n'y a pas de source d'époque pour ces formes, mais la vérité se **mesure** sans
rien supposer. Assembler la même source à deux origines A et B (écart dont chaque octet est non
nul et sans retenue possible sur l'octet médian, par exemple `0BF000h` et `0A1234h`) : chaque
champ relogeable est exactement la suite d'octets qui change, et sa valeur change de B − A.
L'outil `C:\Claude\BASEXT-DRV\outils\reloc.py` le fait (fonctions `classer`, `encoder_kon`,
`decoder_kon`), et vérifie la table en relogeant l'objet A vers une troisième origine C.

Un test de non-régression naturel :

1. assembler la source du §2 à `0BF000h` et à `0A1234h` ;
2. dériver les sites des octets qui changent ;
3. exiger que la table `rel` émise, décodée, soit **égale** à cette liste.

Il couvrirait d'un coup les 27 formes, et toute forme ajoutée plus tard. Le §5 appelle en plus un
test négatif (« `rel mv a,05H` doit être refusé »), dans l'esprit des tests négatifs de
`RAPPORT-BUG-cmp-a-parentheses.md`.

---

## 7. Piste de correction

Ne pas **déduire** la position du champ de la fin de l'instruction : la **relever** au moment où
l'encodeur émet les octets d'adresse. Les chemins d'émission de `mn` (2 octets) et de `lmn`
(3 octets) sont peu nombreux ; y noter l'index courant de `GeneratedBytes` et la largeur quand la
ligne porte `rel`, puis :

- aucune adresse notée → erreur « `rel` sans adresse absolue » ;
- plus d'une → erreur (aucune instruction SC62015 n'en porte deux) ;
- `DP` → 3, `DW` → 2, `DB` → erreur.

⚠️ La correction de `RAPPORT-BUG-octet-pre.md` **déplace** le champ de `mvl (n),[lmn]` et
`mvl [lmn],(n)` sous PRE : relever la position à l'émission, et non la calculer, rend les deux
corrections indépendantes.

---

## 8. Sources

- `src/Assembly/NativeAssembler.cs` : l. 259-267 (lecture du préfixe), 720-728 (heuristique),
  3035-3083 (`AppendRelocTable`, `EncodeRelocTable`).
- `Documentation/Documentation_XASM2026-4_PC-E500S.md` §6.1.2 (le format Kon).
- `SC62015Disassembler/Data/OpcodeTable.json` (inventaire des formes `mn`/`lmn`).
- `C:\Claude\BASEXT-DRV\CONCEPTION.md` §3.4 et `outils/reloc.py` (mesures du 2026-09-16).
