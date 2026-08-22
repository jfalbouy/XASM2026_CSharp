# PLINKC — Pocket Link Cache Device Driver 1.62

Driver de périphérique installé en `0BF000h` (D. Mizobata, 1996-99, d'après PLINK de N. Kon).
Même famille que `REGISTER.ASM` : il détourne des vecteurs IOCS, gère un cache FAT/données et
dialogue avec la SIO.

| Fichier | Rôle |
| --- | --- |
| `PLINKC.asm` | source d'origine, dialecte **A62 / Kon** (fins de ligne CR) |
| `PLINKC.OBJ` | objet compilé d'époque (1554 o = en-tête IOCS 16 o + 1538 o) |
| `PLINKC-BF000.asm` | désassemblage de l'objet par `SC62015Disassembler` — se réassemble en un `PLINKC.OBJ` **identique octet pour octet** (table de relocation comprise, codée en `db`) |
| `plinkc.native.asm` | **port dans le dialecte XASM2026-4** (ce dossier) |
| `convert_a62.py` | le convertisseur qui produit `plinkc.native.asm` |

## Le dialecte A62 et son portage

`PLINKC.asm` n'a jamais été écrit pour XASM. Les constructions spécifiques d'A62 et leur
traitement :

| A62 | XASM2026-4 | Traitement |
| --- | --- | --- |
| `#DEFMACRO bsr` / `rel call %0` / `#ENDMACRO` | — | `bsr X` = `rel call X` → `call X` (macro dépliée) |
| préfixe `rel` (30×) | — | retiré, reporté en commentaire `;rel` (voir la limite plus bas) |
| `%` en position de terme | `%` | **compteur secondaire** (SUBORG) : la taille du cadre de travail |
| `%` entre deux valeurs | `%` | modulo — même désambiguïsation par la position que `*` (LC) |
| `suborg N` / `suborg *` | `suborg` | **directive native ajoutée** : positionne le compteur secondaire |
| `byte` / `word` / `pntr` | idem | **directives natives ajoutées** : champs de 1/2/3 octets à offsets successifs, sans émettre |
| blocs `{ }` + `continue` / `break` | idem | **construction native ajoutée** : boucles structurées |
| `pre $XX`, `$` hexa, `cmpw`, `sbcl`, `pmdf (n),%` | idem | déjà compris tels quels |

Les blocs `{ }` doivent être **équilibrés** : XASM2026-4 refuse une accolade non fermée. La
source A62 laissait le bloc d'attente SIO ouvert (l'assembleur de Kon le tolérait) ; le
convertisseur le referme juste après son unique `jrz continue`, où la boucle d'attente se
termine. La `}` n'émet aucun octet : l'objet est inchangé, la source devient bien formée.

`continue` vise le début du bloc englobant, `break` la sortie (juste après la `}`). Ce sont des
**cibles réservées à l'intérieur d'un bloc seulement** : hors d'un `{ }`, `continue`/`break`
restent de simples étiquettes, si bien que les sources qui en définissent (SAMPLE2, COMPILE.S)
ne sont pas affectées.

## Vérification

Le code produit par `plinkc.native.asm` est **identique octet pour octet** aux **1475 premiers
octets** de la section code de `PLINKC.OBJ` — c'est-à-dire tout le code machine, jusqu'à
`prgend`. Les adresses des tampons de travail (`sect_1`, `fcachep`, `dcache`, … déclarés sous
`suborg *`, 1340 o de RAM au total, de `0BF5C3h` à `0BFAFFh`) sont exactes : le code qui les
référence émet les bons octets, ce que prouve justement l'égalité des 1475 octets.

**Limite — la table de relocation.** `PLINKC.OBJ` se termine par 63 octets qui ne proviennent
d'aucune donnée de la source : c'est la **table de relocation** qu'A62 émet à partir des 30
`rel`, tout comme les `.DVF` de `ssfdc120`. XASM2026-4 n'a pas cette notion ; `plinkc.native.asm`
produit donc le code (1475 o) mais pas ces 63 octets. L'objet complet reste reproductible par le
désassemblage `PLINKC-BF000.asm`, qui code cette table en `db` explicite.

## Assemblage

```powershell
cd .\Exemples\PLINKC
..\..\bin\xasm2026-4.exe plinkc.native.asm -O plinkc.native.obj -L plinkc.native.lst
```

## Exécution sur matériel — `PLINKC-BF000.uu`

`PLINKC-BF000.uu` est l'auto-décodeur BASIC de l'objet **complet** (1554 o), **validé sur un
PC-E500S réel** : le driver s'installe en `S1:` sous le nom `PLINK   SYS`.

Il est produit depuis le désassemblage, avec le nom d'objet `PLINKC.SYS` :

```powershell
..\..\bin\xasm2026-4.exe PLINKC-BF000.asm -O PLINKC.SYS -B PLINKC-BF000.uu
```

Deux points appris en le portant sur le Sharp :

- **Il faut l'objet complet, pas le code seul.** Un `.uu` issu de `plinkc.native.asm`
  (`size 1491`, sans la table de relocation) s'installe mais **se corrompt à l'exécution** :
  l'installateur relit une table de relocation terminée par `$FF` pour corriger ses adresses
  absolues, et sans elle il applique des corrections erronées — le nom affiché devient
  « PaWNK » au lieu de « PLINK ». `PLINKC-BF000.uu` (`size 1554`) contient la table et
  fonctionne.

- **Le nom de fichier du `.uu` doit tenir sur 8 caractères** (complétés par des espaces), suivi
  de l'extension. Il est dérivé du nom d'objet `-O` : d'où `-O PLINKC.SYS`, qui donne
  `FNAME$="PLINKC  .SYS"`. Un nom d'objet plus long (`PLINKC-BF000.obj`) serait tronqué à
  `PLINKC-B`.

Note : au premier `CALL &BF000`, l'installateur peut déclencher son propre `reset` volontaire
(étiquette `bomb`, quand `linkbas` ne retrouve pas les pointeurs `BTEXT$`/`BDATA$` de BASIC).
C'est le comportement du driver d'origine — l'enregistrement IOCS a lieu avant, donc le driver
reste installé après le reset.

## PLINK2 — portage sur le modèle REGISTER3 (`PLINK2.asm`)

`PLINK2.asm` reprend PLINKC sur le **modèle du template de pilotes** (comme `REGISTER3` vis-à-vis
de `REGISTER2`) :

| Aspect | PLINKC (origine) | PLINK2 |
| --- | --- | --- |
| Installation | insertion + décalage + recalage BASIC (`linkbas`, `reset`/bomb possible) | **ajout-en-fin** : placé après les blocs, sans décalage → **pas de `linkbas`, pas de bomb** |
| Désinstallation | aucune | **`CALL &BF000 "-u"`** (déliage de la chaîne + `SET`/`KILL`) |
| Nom | `PLINK   SYS` / device `L:` | `PLINK2  SYS` / device `PL2:`, **définis une seule fois** (macros) |
| Relocation | table de deltas d'origine | **la même table, réutilisée verbatim** (un seul octet ajusté : `PL2:` fait +2 vs `L:`) |

**Le corps du pilote et la zone de travail sont repris byte-pour-byte de `plinkc.native.asm`** (le
`.asm` est généré par `build_plink2.py`). Points clés vérifiés à l'assemblage :

- le corps est byte-cohérent (offsets = natif +2 après `dvname`, `dvname` inchangé) ;
- la table de relocation d'origine (60 sites, dont **tous les `call` à cible absolue** — les
  marqueurs `;rel` du natif étaient incomplets) tombe exactement sur les bons champs d'adresse
  dans la nouvelle disposition ;
- `pre_off` sépare l'installateur (adressage RAM absolu, `pre_on`) du corps (qui a ses propres
  `pre` explicites) — sans quoi les prébytes se doubleraient.

Le pilote ne détourne la SIO que le temps de chaque appel (`jump00`), donc au repos il ne tient
aucun vecteur → la désinstallation se limite au déliage.

**Statut : validé sur émulateur, tous les cas** (`PLINK2.uu`, nom Sharp `PLINK2.SYS`, 1743 o).
`CALL &BF000` installe (`PLINK2.SYS` en fin de S1:, protégé) ; `CALL &BF000 "-u"` désinstalle
(« Uninstalled. » + `SET`/`KILL`) ; relancer à vide donne « PL2: not installed. » et réinstaller
« Error: already exist. » — **tous avec un retour BASIC propre**. La relocation à 60 sites,
réutilisée verbatim, tient.

Deux corrections du **retour à BASIC** ont été nécessaires (mêmes causes que pour UUENCODE) :

- **Terminateurs de l'argument.** Le scan ne reconnaissait que `0` et `CR` ; pour une chaîne
  *complète* (`"-u"`, guillemets fermés), BASIC termine par `1Ah` ou `0FFh` — le scan dépassait
  et rempilait un pointeur de ligne faux → « Syntax error ». Ajout des quatre terminateurs de
  `argskp` d'UUENCODE (`0`, `CR`, `1Ah`, `0FFh`).
- **Carry de retour.** Un `CALL` qui rend la main **carry armé** (`sc`) provoque une « Syntax
  error » BASIC. Les chemins d'erreur (`already exist`, `not installed`) rendent désormais la
  main **carry clair** (`rc`), comme les chemins succès.

Le figement a été localisé par une version instrumentée (`build_plink2.py` avec
`PLINK2_DEBUG=1` : un chiffre imprimé au début de chaque étape) — l'écran affichait `123456`,
révélant deux appels IOCS aux conventions incertaines, écartés :

- **la recherche dynamique de numéro de device** (`iocs il=1`) risquait une boucle infinie → le
  numéro est **codé en dur** (10) dans l'en-tête ;
- **l'initialisation des paramètres** (`iocs il=4`, reprise de PLINKC) figeait au premier accès
  device → écartée (REGISTER3 ne la fait pas ; le device est chaîné et le pilote s'initialise à
  la première commande).

*Réserve honnête :* le transfert cache réel (SIO) exige un câble PLINK relié à un PC, donc
intestable sur émulateur ; la validation porte sur **install + bloc/​device en place +
désinstall propre**. Si l'usage réel révélait un besoin d'init des paramètres, il faudrait
retrouver la bonne convention de `iocs il=4`.
