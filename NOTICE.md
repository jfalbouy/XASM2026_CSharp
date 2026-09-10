# NOTICE — droits d'auteur, licences et crédits

Ce dépôt réunit **plusieurs œuvres distinctes**, sous des régimes de droits
différents. Ce fichier en dresse l'inventaire. **Lisez-le avant toute
redistribution.** En cas de doute, la règle la plus restrictive s'applique :
**usage non commercial uniquement**.

---

## 1. Le portage C# (œuvre originale de ce dépôt)

**XASM 2026-4** — portage C# / .NET 8 de l'assembleur croisé, écrit par
**Jean-François Albouy** (2026).

- Périmètre : `src/`, `tests/`, `tools/`, le fichier solution, et la
  documentation rédigée pour ce portage (`README.md`, `PORTAGE.md`, `CLAUDE.md`,
  `Documentation/` hors documents d'origine cités plus bas).
- Licence : **PolyForm Noncommercial License 1.0.0** (voir [`LICENSE`](LICENSE)).
- Ce portage est une **œuvre dérivée** de XASM (voir §2). Le choix d'une licence
  **non commerciale** est délibéré : il respecte la condition « no commercial
  use » de l'œuvre amont.

---

## 2. XASM — l'assembleur d'origine (amont)

Le moteur historique dont ce projet est le portage.

- **XASM Version 1.4**, *The Absolute Cross Assembler for ESR-L CPU*.
- Auteurs / titulaires des droits : **Narihito (Narihiro) Kon** et **Eiji Kako**.
  - Conception initiale par N. Kon (Turbo-Pascal puis C) ; issue à l'origine de
    « Pockecom Library #2 » (éditeur Kougaku-sha). Portage et améliorations C
    (algorithme de hachage, etc.) par E. Kako.
- Termes d'origine (§9 « The Copyrights » de la documentation, reproduite
  telle quelle dans [`Sources originales/`](Sources%20originales/)) :

  > This program is a free software. Eiji Kako and Narihiro Kon holds the
  > copyrights. You may freely copy and redistribute with the conditions, which
  > are **"no commercial use"** and **"no altering"**.

- Permission de lignage (documentation ENGLISH.DOC) :

  > I was permitted improving and rewriting the source codes and the documents
  > by the author Narihito Kon.

  C'est cette permission explicite d'« improving and rewriting » qui fonde la
  légitimité d'un portage dérivé. La distribution originale est incluse
  **inaltérée** dans [`Sources originales/`](Sources%20originales/) (sources C,
  `XASM.EXE`, documentation, `SAMPLE1-4.ASM`) afin de respecter la condition
  « no altering » sur l'œuvre d'origine elle-même : l'original n'est pas modifié,
  il est fourni tel quel à côté du portage.
- Site historique : <http://www.na.rim.or.jp/~kako>
- Copies de référence conservées : sources C dans [`Reference/C/`](Reference/C/) ;
  documentation dans `Documentation/XASM - ENGLISH.DOC`, `Documentation/XASM.DOC`.

---

## 3. Programmes d'exemple tiers (dossier `Exemples/`)

Ces programmes sont fournis à titre **pédagogique et de test de non-régression**.
Chacun reste sous les droits de son auteur ; ils ne sont **pas** couverts par la
licence du §1. La plupart sont des *freeware* à usage non commercial.

| Dossier | Programme | Auteur / droits | Note |
|---|---|---|---|
| `Exemples/PLINKC/` | Pocket Link Cache (PLINKC) v1.62 | Copyright (c) 1996,1997,1999 **Daisuke Mizobata** | basé sur PLINK.SYS v1.04, (c) 1990,93,94 **N. Kon** |
| `Exemples/REGISTER/` | REGISTER | (c) 1990,1992 **E. Kako** (JM2WGN) | |
| `Exemples/ssfdc120/` | SSFDC | (c) 1997,1999 **Kenji Takamatsu** | |
| `Exemples/MASSE/` | MASSE v1.2.0 | (c) 1994-1997 **N. Masuichi** | contient une adresse e-mail d'époque de l'auteur |
| `Exemples/VOGUE/` (+ `VOGUE/OLD/`) | Vogue (compilateur) | (c) 1991/1992 **Narihito Kon** | `OLD/` = versions antérieures des sources |
| `Exemples/TMAP/` | Tmap v1.05 | (C) 1994 **TORO** | |
| `Exemples/PANO122/` | Éditeur de texte PANORAMA v1.22 | **Daisuke Mizobata** | documentation d'origine en japonais |
| `Exemples/PLINK104/` | Pocket Link System Driver v1.04 | Copyright (c) 1990,93,94 **N. Kon** | version d'origine dont dérive PLINKC |
| `Exemples/ISH/` | ish encoder / decoder (pour TY-DOS) | port pour PC-E500 par **E. Kako** (JM2WGN) | d'après la version MS-DOS d'origine, (c) 1986-1990 **M. Ishizuka** |
| `Exemples/TYDOS/` | TY-DOS (système) | composants d'origine (`*.SYS`, `TYDOS.DOC/.MAN`, 1989-1992) : **T. Yamaguchi** | ports/reconstructions `tycom.asm`, `tydos.asm` (2019) et manuels `.docx`/`.xlsx` : **J.-F. Albouy** |
| `Exemples/trdos033/` | TRDOS v2.0 (2022) | **J.-F. Albouy** | d'après « DOS for PC-E500S » v0.33, (c) 1990,1992 **T. Kobayashi** ; manuels `.docx`/`.xlsx` : J.-F. Albouy |
| `Exemples/SAMPLES/` | SAMPLE1-4 | **Kako / Kon** (distribution XASM) | exemples officiels XASM |

> Les fichiers `SAMPLE5.*`, les exemples du dossier `TUTORIEL/`, `DRIVER_TEMPLATE/`,
> les variantes `*.native.*` / `*2026-4*` et les portages A62 (`PLINKC/A62/`,
> `REGISTER2/3`, `PLINK2`) qui portent des adaptations sont l'œuvre de
> **J.-F. Albouy** (2026), dérivés des programmes ci-dessus et soumis aux mêmes
> conditions non commerciales que leurs originaux respectifs.
>
> Les fichiers de sortie (`*.lst`, `*.obj`, `*.uu`, `*.hex`, `*.s19`, `*.map`,
> `*.txt`) présents dans ces dossiers sont des **produits d'assemblage régénérables**,
> conservés à titre de référence ; ils n'ajoutent aucun droit d'auteur nouveau.

---

## 4. Attribution demandée

En cas de redistribution, conserver ce fichier et créditer :

- **N. Kon** et **E. Kako** pour XASM ;
- l'auteur de chaque programme d'exemple redistribué (§3) : **D. Mizobata**
  (PLINKC, PANORAMA), **E. Kako** (REGISTER, ish), **K. Takamatsu** (SSFDC),
  **N. Masuichi** (MASSE), **N. Kon** (Vogue, PLINK), **TORO** (Tmap),
  **M. Ishizuka** (ish, version MS-DOS d'origine), **T. Yamaguchi** (TY-DOS),
  **T. Kobayashi** (DOS PC-E500S dont dérive TRDOS) ;
- **J.-F. Albouy** pour le portage C# 2026-4 et ses travaux dérivés (TRDOS,
  ports TY-DOS, exemples et documentation).

---

## 5. Absence de garantie

L'ensemble est fourni « en l'état », sans garantie d'aucune sorte. Voir la
clause *No Liability* de [`LICENSE`](LICENSE). Les œuvres tierces du §2 et §3
sont fournies sous les garanties (ou l'absence de garantie) de leurs auteurs
respectifs.
