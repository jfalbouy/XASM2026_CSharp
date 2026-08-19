# Modèle d'installation d'un pilote résident — SHARP PC-E500S

Analyse comparée de trois pilotes du corpus qui installent un **driver résident en RAM** :
`REGISTER`, `PLINKC` et `SSFDC`. Objectif : dégager l'ossature commune, les trois modèles
d'installation, la logique de construction, et la faisabilité d'une **désinstallation**. Ce
document est la référence de conception ; le *template* réutilisable et la routine de
désinstallation en découlent (livrables séparés).

Les références de ligne renvoient aux sources de `Exemples/` : `REGISTER/REGISTER.ASM`,
`PLINKC/PLINKC.asm`, `ssfdc120/ssfdc.asm`.

---

## 1. L'ossature invariante d'un pilote résident

Quelle que soit la méthode d'installation, tout pilote résident du PC-E500S est le même objet
en quatre parties, chargé comme un **bloc mémoire** que le système d'exploitation reconnaît :

```
┌─ En-tête de bloc mémoire ───  $fb + 'NOM     SYS' + attributs + date + taille + pointeurs
├─ En-tête IOCS (maillon) ────  [lien suivant] + n°/attribut device + point d'entrée + 'X:Y:…'
├─ Corps du pilote ──────────  les fonctions : init, read/write secteur, hooks…
└─ Table de relocation ──────  liste des adresses absolues à corriger au chargement
```

### 1.1 L'en-tête de bloc mémoire

Format commun (PLINKC `btop:` l.275-282 ; SSFDC `memoryBlockHeading:` l.78-88) :

| Champ | Taille | Rôle |
|---|---|---|
| signature | 1 | `$fb` — marque un bloc de périphérique |
| nom | 11 | `'NOM     SYS'` (8 + 3, complété d'espaces) |
| attributs | 1 | ex. `$25` / `00100101B` |
| date / heure | 4 | `dw 0,0` |
| taille du bloc | 3 | `dp` — nombre d'octets |
| … | | pointeurs : crédit, programme de contrôle, **table de relocation** (`dp relTbl` chez SSFDC l.88) |

### 1.2 L'en-tête IOCS et la chaîne des devices

Le cœur du système : les périphériques forment une **liste simplement chaînée**, dont la racine
est le pointeur global **`0BFCA2h`** — que les trois sources nomment `d_link` (REGISTER l.17) ou
`iroot` (PLINKC l.46). Chaque en-tête IOCS commence par le pointeur vers le suivant ; `$FF`/-1
marque la fin.

Format (PLINKC `ihead:` l.286-290) :

| Champ | Taille | Rôle |
|---|---|---|
| lien suivant | 3 | `dp 0` — rempli à l'installation |
| n° de device | 1 | ex. variable (PLINKC) ou fixe |
| attribut | 1 | ex. `$83` |
| point d'entrée | 3 | `dp init` — **relogeable** |
| noms | n | `'L:',0` (PLINKC) ou `'S:SA:SB:…',0` (SSFDC) |

**Installer un pilote = insérer son en-tête IOCS en tête de cette chaîne** (prepend) : on
sauvegarde l'ancienne tête dans le champ « lien suivant » du nouvel en-tête, puis on écrit
`[iroot] ← nouvel en-tête`.

---

## 2. Trois modèles d'installation

| | REGISTER | PLINKC | SSFDC |
|---|---|---|---|
| **Modèle** | installateur actif (`CALL`) | installateur actif (`CALL`) | **bloc passif** posé par l'OS (`.DVF`) |
| **Nom device** | `REGISTERSYS` (l.309) | `PLINK   SYS` (l.275) | `SSFDC   SYS` (l.80) |
| **Relocation** | `modify_table` en ligne (l.113-127) + assertions (2026) | table d'octets lue par l'installateur, terminée par `$FF` (l.177-200) | `dp relTbl` référencée dans l'en-tête (l.88), relocalisée par l'OS |
| **N° de device** | fixe (#11, l.91-98) | 1ᵉʳ libre ≥ 10 | attribué par l'OS |
| **Chaînage** | prepend manuel sur `d_link` (l.105-110) | prepend manuel sur `iroot` (l.206-208) | fait par l'OS |
| **Vecteurs détournés** | — | SIO `sio_rcv_vct`, sauvé dans `vct_rsv` (l.338-341) | — |
| **Fixup BASIC** | — | `linkbas` (BTEXT$/BDATA$), `bomb:reset` (l.219-254) | — |

- **REGISTER et PLINKC sont des installateurs actifs** : on les charge à une adresse fixe et on
  les lance par `CALL &addr`. Le code d'entrée fait tout le travail (§3), puis rend la main.
- **SSFDC est un pilote passif** : le fichier `.DVF` est simplement un bloc mémoire. C'est le
  **gestionnaire de périphériques de l'OS** qui le lit, le relocalise via `relTbl` et le chaîne ;
  la fonction `init` de l'en-tête IOCS est appelée par l'OS. Il n'y a **pas** de code
  d'installation propre (ssfdc.asm ne contient que des `equ`/macros avant `block_top`).

Les deux approches produisent le même résultat résident ; elles diffèrent par *qui* exécute
l'installation.

---

## 3. La logique de construction, en 8 étapes

Séquence d'un installateur actif (REGISTER, PLINKC). SSFDC délègue 1-8 à l'OS et se contente de
**déclarer** les mêmes structures.

1. **Unicité** — le device existe-t-il déjà ? (PLINKC cherche « L: » via `icall` ; REGISTER
   cherche le device #11 dans la chaîne, l.91-98.) Sinon → message et sortie.
2. **Mémoire** — `s1_btm − haut_de_S1 ≥ taille_du_bloc` ? (REGISTER l.80-86.) Sinon → « not
   enough memory ».
3. **N° de device** — fixe, ou balayage du premier libre.
4. **Allocation** — créer le bloc (décalage de la zone de fichiers S1, ou appel IOCS `memd`).
5. **Copie** — recopier le corps depuis l'adresse d'assemblage vers son emplacement RAM final.
6. **Relocation** — ajouter `(adresse_finale − adresse_assemblée)` à chaque pointeur absolu
   listé dans la table (§4).
7. **Chaînage** — sauvegarder l'ancienne tête `[iroot]`, la placer dans le lien du nouvel
   en-tête, puis `[iroot] ← nouvel en-tête` (PLINKC l.88-89 puis l.206-208).
8. **Détournement de vecteurs** — détourner ce qui doit l'être (SIO, timer…) **en conservant
   l'original** (PLINKC `vct_rsv` l.338-341), puis afficher « Installed » et rendre la main.

---

## 4. Le point délicat : la relocation

C'est la **seule vraie fragilité** de la construction. Le corps est assemblé à une adresse fixe
mais copié à une adresse variable ; **toute adresse absolue interne** (un `mv x,label`, un
`dp label`) doit être corrigée du décalage. Une adresse oubliée dans la table s'installe sans
erreur puis **plante à l'exécution** — c'est exactement ce qu'on a observé sur PLINKC privé de
sa table (le nom du driver affiché « PaWNK » au lieu de « PLINK »).

Trois mécanismes, une même idée :

- **REGISTER** — `modify_table` (l.913) est une liste d'adresses de sites à corriger, terminée
  par -1 ; l'installateur (l.113-127) lit chaque site, calcule le décalage et réécrit l'adresse.
- **PLINKC** — la table est un **flux d'octets terminé par `$FF`**, lu par une boucle
  d'installateur (l.177-200) qui décode chaque entrée (largeur 1 ou 2 octets) et applique la
  correction via `mvp`/`sbcl`/`mvp`.
- **SSFDC** — `dp relTbl` est **référencée dans l'en-tête** ; c'est l'OS qui parcourt la table.

**La bonne pratique, apportée par REGISTER2 (2026) : une assertion d'assemblage** qui vérifie
que chaque site d'adresse absolue est bien inscrit dans la table. Un site oublié devient une
**erreur d'assemblage**, plus un plantage silencieux à l'exécution. C'est la clé d'un modèle
réutilisable sûr (§6).

> Rappel de portage : XASM ne **génère pas** de table de relocation (le préfixe A62 `rel` est
> traité comme un commentaire). Les tables ci-dessus sont donc écrites explicitement dans la
> source — `modify_table` chez REGISTER, ou reprises telles quelles dans le désassemblage pour
> PLINKC/SSFDC. Un template devra donc fournir sa propre discipline de table (§6).

---

## 5. La désinstallation — possible, sous condition

Aucun des trois ne l'implémente. Elle est pourtant **techniquement faisable**, et surtout
**l'état nécessaire est déjà sauvegardé** :

- PLINKC conserve l'ancienne tête de chaîne (`ihead` l.89) **et** le vecteur SIO original
  (`vct_rsv` l.339) — et sait déjà le restaurer (l.373-374).
- REGISTER conserve `header` / `iocs_eleven` (l.100, 106).

### Procédure

1. **Parcourir** la chaîne depuis `iroot` pour retrouver *son* en-tête (par le nom device) **et
   son prédécesseur**.
2. **Délier** : `prédécesseur.lien_suivant ← soi.lien_suivant` (retrait du maillon).
3. **Restaurer** les vecteurs détournés depuis les copies sauvegardées.
4. **Libérer** le bloc mémoire (le rendre à l'OS).

### La condition — le problème classique du TSR

Le retrait n'est propre que si **rien n'a été installé après vous** sur les mêmes ressources. Si
un pilote ultérieur s'est chaîné derrière vous, ou a re-détourné « votre » vecteur, vous délier
casserait ses liens. Une désinstallation sûre doit donc, **avant d'agir, vérifier qu'elle est au
sommet de la pile de hooks** — que le vecteur détourné pointe encore vers elle, et qu'aucun
maillon plus récent ne dépend d'elle — et **refuser** proprement sinon (message « impossible de
désinstaller : un autre pilote a été chargé ensuite »).

C'est quelques lignes de code, adossées à un état que ces pilotes conservent déjà. L'architecture
le permet ; ces programmes ne l'ont simplement jamais écrit.

---

## 6. Perspective : vers un modèle réutilisable

L'ossature (§1) et la séquence (§3) sont assez régulières pour un **template paramétré**, qui
réduirait un nouveau pilote à l'écriture de ses seules **fonctions**. Il fournirait :

- des **macros d'en-tête** (`MEMBLOCK`, `IOCSHDR`) générant les deux en-têtes sans erreur de champ ;
- une **discipline de relocation sûre** : une macro `RELPTR` qui émet le pointeur *et* l'inscrit
  dans la table, plus l'**ASSERT de complétude** — la généralisation de REGISTER2 ;
- un **squelette d'installateur** couvrant les 8 étapes, où l'auteur ne remplit que l'unicité, les
  vecteurs à détourner et le corps ;
- une **routine de désinstallation** standard (§5), avec la vérification « suis-je au sommet des
  hooks ? » ;
- deux **variantes** : *actif* (à la REGISTER/PLINKC) et *passif* (à la SSFDC, bloc `.DVF`).

C'est l'esprit de `Exemples/INCLUDE/pce500.inc` — mutualiser ce qui est invariant — appliqué
cette fois à la **structure** d'un pilote, et non plus aux seules constantes.

**Réalisé** : `Exemples/DRIVER_TEMPLATE/` fournit ce squelette — les deux en-têtes, l'installateur
en 8 étapes (généralisé depuis REGISTER2, sans le hook clavier), et la discipline de relocation
`reldp`/`relref` avec l'assertion de complétude qui rend un oubli détectable **à l'assemblage**
(là où REGISTER2 ne le voyait qu'à l'exécution). La routine de désinstallation (§5) reste à
ajouter.
