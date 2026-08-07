# Tests de non-régression

Ce dossier regroupe le harnais automatisé et les fichiers de couverture du port C#
`xasm2026-4`, dont la contrainte fondatrice est la reproduction **octet à octet** des sorties
de la référence `xasm2026-1`.

## Contenu

| Chemin | Rôle |
|---|---|
| `Xasm2026.Tests/` | Harnais xUnit exécuté par `dotnet test` et par la CI. |
| `coverage_all.asm` | Source exerçant chaque directive et forme d'opcode portée. |
| `coverage_all_include.asm` | Fichier inclus par le précédent. |
| `postbyte_families.asm` | Couverture systématique des familles à post-octet (104 instructions) — voir `postbyte_families.README.md`. |
| `postbyte_families.expected.txt` | Octets attendus pour le fichier ci-dessus, produits par le moteur de référence. |
| `_compare_with_xasm2026_1_1/` | Sorties du script de comparaison. Régénérable, ignoré par git. |

## Exécution

```powershell
dotnet test .\tests\Xasm2026.Tests\Xasm2026.Tests.csproj -c Release
```

## Ce que couvre le harnais

| Suite | Objet |
|---|---|
| `GoldenAssemblyTests` | Réassemble `SAMPLE5`, `VOGUE`, `REGISTER` et `TMAP2020`, puis compare les **huit** sorties (`.obj`, `.hex`, `.s19`, `.txt`, `.lst`, `.map`, `.d`, `.uu`) octet à octet aux fichiers de référence — 32 comparaisons exactes. |
| `BehaviorTests` | Garde-fous : symbole indéfini, inclusion cyclique, division par zéro, étiquette dupliquée, avertissements, positions source. |
| `ExpressionEvaluatorTests` | Bases numériques, compteur de localisation, précédence des opérateurs. |
| `SymbolTableTests` | Règles de portée locale : préfixage, imbrication, référence parente `..!`. |
| `DirectiveTests` | Directives ajoutées en 2026-4 : `SET`, `IRP`/`IRPC`, `ALIGN`, `DZ`, `PHASE`, `EXITM`… |
| `SampleAssemblyTests` | Octets produits par les exemples `SAMPLE6` à `SAMPLE9`. |
| `PostbyteFamiliesTests` | Les 104 formes à post-octet de `postbyte_families.expected.txt`, plus les 2 formes que Sharp ne définit pas (refus attendu) — 106 cas pilotés par les données. |

> ✅ **`postbyte_families` est branché sur `dotnet test`** (`PostbyteFamiliesTests`). Il a révélé
> sept défauts d'encodage des familles à post-octet, tous corrigés le 2026-08-07 : les **20
> divergences sur 104** sont retombées à **zéro**, et les deux formes invalides (`MVL` sur `[r3]`
> sans post-incrémentation) sont désormais rejetées. Le détail — les sept défauts, leur méthode
> et leur correctif — est dans `postbyte_families.README.md`.

### Point à connaître avant de toucher au harnais

Les formats de présentation (`.lst`, `.map`, `.d`, `.uu`) embarquent le nom du fichier source
et celui des sorties. Ils ne sont donc reproductibles qu'en rejouant **l'invocation historique
exacte** : noms entièrement en minuscules (`sample5.asm` → `sample5.lst`) et option `-S`. Les
noms en minuscules ne résolvent le fichier réel (`SAMPLE5.ASM`) que sur un système de fichiers
insensible à la casse, ce qui explique que la CI tourne sur `windows-latest`.

Le seul champ non déterministe de l'ensemble des sorties est la ligne
`' Submitted jj/mm/aaaa` du `.uu`, que le harnais neutralise avant comparaison.

## Comparaison directe avec le moteur C

Au-delà des fichiers de référence, qui sont des instantanés figés, les deux assembleurs
peuvent être confrontés l'un à l'autre :

```powershell
.\tools\compare_with_xasm2026_1_1.ps1 -ReferenceXasm .\Reference\C\xasm2026-1-2.exe -IncludeVogue
```

Chaque source est assemblée dans son propre dossier de travail, purgé au préalable de toute
sortie, de sorte qu'un fichier absent signifie réellement « non produit par ce run ». La
colonne `MissingOutputs` du rapport le signale explicitement.

Dernier résultat (2026-07-19) : **code machine identique sur les huit sources**. Le `.uu`
diffère par une ligne finale `size` et le bourrage du dernier bloc, choix délibéré de
reproduire `uuselfx.c` documenté dans `PORTAGE.md` ; les deux fichiers décodent vers le même
objet.
