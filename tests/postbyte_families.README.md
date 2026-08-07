# `postbyte_families` — les familles à post-octet

Jeu d'essai systématique des familles d'instructions qui portent un **post-octet** ou un
**sous-octet** d'indirection. Ce sont celles où se jouent l'ordre des champs et le choix du
sous-octet — donc celles où une erreur produit des octets plausibles mais faux.

| Fichier | Rôle |
|---|---|
| `postbyte_families.asm` | 104 instructions, une par ligne : `mnémonique × mode d'indirection` |
| `postbyte_families.expected.txt` | les octets attendus, une ligne par instruction |

## Ce qui est couvert

```
E0-E3 / E8-EB    (n) <-> [r3]     avec [r3] [r3++] [--r3] [r3+n] [r3-n]
F0-F3 / F8-FB    (n) <-> [(n)]    avec [(n)] [(n)+n] [(n)-n]
56 / 5E          MVL à offset de pointeur
90-96 / B0-B6    registre <-> [r3]
98-9E / B8-BE    registre <-> [(n)]
```

## D'où viennent les octets attendus

Trois sources indépendantes, qui concordent :

1. le **moteur C de référence** `xasm2026-1-2`, qui a produit ces octets ;
2. la **table de commandes du manuel du constructeur** — SHARP, *ESR-L INSTRUCTION MANUAL*,
   pp. 73-88 — qui donne les post-octets **en binaire, position par position** ;
3. le désassembleur `SC62015Disassembler`, qui **redécode les 104 sorties en un texte source
   identique**, sans un écart.

Deux règles en découlent, et elles suffisent à expliquer chaque ligne du fichier :

- **L'emplacement RAM interne précède toujours l'offset du pointeur.** Sharp l'écrit ainsi :
  `(N) <- [x±n]` donne `11100000, 1s000-r-, N n`, et `[X±N] <- (n)` donne
  `11101001, 1s000-R-, n N`. C'est l'emplacement d'abord dans les deux sens.
- **Un mode sans offset a un sous-octet nul et aucun octet de déplacement.** `[(n)]` s'encode
  `00000000`, pas `10000000` suivi d'un zéro. Les bits que le manuel écrit à `0` sont
  *spécifiés*, pas indifférents.

## Exécution

Le jeu est branché sur `dotnet test` (`PostbyteFamiliesTests`) : chaque ligne de
`postbyte_families.expected.txt` est assemblée isolément et comparée octet pour octet, et les
deux formes invalides doivent lever une erreur.

```powershell
dotnet test .\tests\Xasm2026.Tests\Xasm2026.Tests.csproj -c Release --filter PostbyteFamiliesTests
```

**État au 2026-08-07 : 0 divergence sur 104**, les 356 octets attendus reproduits, et les deux
formes invalides rejetées. Les sept défauts décrits ci-dessous ont tous été corrigés ce jour-là ;
la section est conservée comme journal de ce qui était cassé et pourquoi.

## Les sept défauts que ce jeu a révélés *(corrigés le 2026-08-07)*

Tous étaient dans `src/Assembly/NativeAssembler.cs`. La correction s'appuie sur deux helpers
partagés, `PointerSubByte` et `HasPointerOffset`, qui encodent la règle Sharp du sous-octet
(`00` sans offset et alors aucun octet de déplacement, `80` pour `+`, `C0` pour `−`).

### D6 — le signe est perdu sur `[(m)-n]` *(le plus grave : code faux, en silence)*

`EmitMoveLong`, deux sites : `Emit(0x80)` est codé en dur.

```
mvl (022h),[(033h)+044h]   ->  f3 80 22 33 44
mvl (022h),[(033h)-044h]   ->  f3 80 22 33 44      <- octets identiques
```

`EmitMoveWord` fait déjà juste au même endroit :
`offsetExpression.TrimStart().StartsWith('-') ? 0xC0 : 0x80`.

### D1 — ordre des champs inversé sur `E1`/`E9` (MVW)

`EmitMoveWord`, sites `0xE1` et `0xE9` : `Emit(opcode); EmitSuffix(suffix); Emit(interne)` —
donc post-octet, offset du pointeur, puis l'emplacement. **Le bon motif existe déjà dans
`EmitMove`** (E0/E8) et dans `EmitMovePointer` (E2/EA) :

```csharp
Emit(0xE0, emit, result);
if (suffix.Length > 1 && (suffix[0] is >= 0x80 and <= 0x87 or >= 0xC0 and <= 0xC7))
{
    Emit(suffix[0], emit, result);                              // post-octet
    Emit(InternalRamOffset(left, emit, result), emit, result);  // emplacement RAM interne
    for (var i = 1; i < suffix.Length; i++) { … }               // puis l'offset du pointeur
}
```

Seul `EmitMoveWord` ne l'a pas — d'où une alternance selon le **bit 0 de l'opcode**, signature
d'une erreur d'indexation.

### D2 — `MVL` à offset doit être `56`/`5E`, pas `E3`/`EB`

`EmitMoveLong`, sites `0xE3` et `0xEB`. Sharp réserve `E3`/`EB` à la forme `[r3++]` ; la forme à
offset a ses propres opcodes.

```
mvl [y+011h],(022h)    attendu  5e 85 22 11    obtenu  eb 85 11 22
```

### D3 — `MVL` accepte `[r3]` sans post-incrémentation

Mêmes sites. `mvl (022h),[y]` n'existe pas : `E3` est `MVL (n),[r3++]`. Le moteur de référence
rejette (`Undefined instruction`) ; le port émet le post-octet `05`, un encodage indéfini.

### D4 — `[(n)]` sans offset émis comme une forme à offset

Sites émettant `0x80` suivi d'un déplacement nul, là où le sous-octet `00` suffit — dans
`EmitMove` (F0/F8), `EmitMovePointer` (F2), `EmitMoveWord` (F9), `EmitMoveLong` (F3/FB) :

```
mv (022h),[(033h)]     attendu  f0 00 22 33    obtenu  f0 80 22 33 00     <- un octet de trop
```

C'est l'essentiel des 9 octets d'écart sur le fichier entier.

### D5 — `MVW (m),[(n)]` part dans la mauvaise famille

`EmitMoveWord` : la branche générique `right.StartsWith('[')` est testée **avant** la branche
`right.StartsWith("[(")`, donc `[(033h)]` tombe dans l'indirection *registre* (`E1`) au lieu de
l'indirection *mémoire* (`F1`). Les autres méthodes testent dans le bon ordre.

### D7 — octet PRE parasite

`EmitMoveLong`, branche `[(m)±n] <- (n)` : `Emit(0x22)` avant `0xFB`, sans justification.

## Branchement sur le harnais

Fait : `PostbyteFamiliesTests` lit `postbyte_families.expected.txt`, assemble chaque ligne dans un
dossier temporaire et compare l'objet émis, octet pour octet ; les deux formes invalides doivent
lever une erreur. 106 cas au total (104 encodages + 2 refus), tous verts. La CI les exécute avec
le reste de la suite.
