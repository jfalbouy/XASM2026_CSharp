# DRIVER_TEMPLATE — squelette de pilote résident PC-E500(S)

Point de départ pour un nouveau **pilote de périphérique résident**, généralisé à partir de
`REGISTER2` (validé sur matériel). Il fournit l'échafaudage — en-têtes, installateur, discipline
de relocation — pour qu'un nouveau pilote se réduise à l'écriture de ses **fonctions**.

Voir `Documentation/Modele_Pilotes_Resident_PC-E500S.md` pour l'architecture d'ensemble
(les trois modèles d'installation, l'ossature invariante, la faisabilité d'une désinstallation).

| Fichier | Rôle |
| --- | --- |
| `driver_template.asm` | le squelette, assemblable tel quel (pilote minimal : un stub qui renvoie « commande non gérée ») |
| `driver_template.obj` / `.lst` | l'objet et le listing produits |
| `driver_template.uu` | auto-décodeur BASIC pour l'émulateur (nom Sharp `DRVTMP  .OBJ`) |

## Ce que fournit le template

1. **Les deux en-têtes** — bloc mémoire (`$fb` + nom `8.3` + attributs + tailles) et en-tête
   IOCS (lien de chaîne + n° device + point d'entrée + noms), prêts à paramétrer.
2. **L'installateur** (lancé par `CALL &BE000`) : bannière → compactage S1 → recherche de
   doublon et de la **fin** de la chaîne des blocs → contrôle mémoire → chaînage en tête de la
   liste des devices (`0BFCA2h`) → **relocation** → **copie en fin de chaîne** + terminateur.

   Modèle **ajout-en-fin** : le pilote est placé *après* les blocs existants, sans les décaler.
   Aucun fichier BASIC ne bouge, donc **aucun recalage des pointeurs `BTEXT$`/`BDATA$`** — ce
   qui supprime le risque de corruption de BASIC de l'insertion-avec-décalage à la REGISTER. En
   cas d'échec (doublon, mémoire), l'installateur affiche un message et rend la main (carry)
   sans rien toucher.
3. **La discipline de relocation** — l'apport principal (voir ci-dessous).

## La discipline de relocation

Un pilote est copié à une adresse variable ; **toute adresse absolue interne doit être corrigée**
à l'installation. Un pointeur oublié s'installe puis plante à l'exécution (c'est le « PaWNK » de
PLINKC privé de sa table). REGISTER2 documentait ce piège mais ne le détectait pas.

Ici, deux macros et une assertion le rendent **détectable à l'assemblage** :

```asm
        reldp   cible      ; dans le pilote : émet un pointeur relogeable ET le compte
        relref  site       ; dans la table  : déclare le site (adresse du pointeur) ET le compte
        ...
        assert  _nrel = _ntbl,'table de relocation incomplete'
```

Chaque `reldp` incrémente `_nrel`, chaque `relref` incrémente `_ntbl` ; l'assertion échoue si
l'un est oublié. Vérifié : retirer le `relref` du gabarit provoque bien
`table de relocation incomplete` à l'assemblage, là où le pilote se serait sinon installé puis
planté.

La table est préfixée du **nombre d'entrées** (`dw _nrel`), que la boucle de l'installateur lit
pour savoir combien de sites corriger. Chaque site contient un pointeur de 3 octets ; l'installateur
le relit, calcule `pointeur − block_top + destination`, et le réécrit avant la copie.

## Adapter le template

Trois points à personnaliser :

1. **En-tête** : le nom (`'DRIVER  SYS'`, exactement 8 + 3 caractères), le `number` (n° de
   device) et la chaîne de noms (`'DRV:'`).
2. **Corps** : remplacer le stub à partir de `iocs_entry` par vos fonctions. **Chaque adresse
   absolue interne** (un `mv x,table`, un `dp routine`…) doit être émise par `reldp` et son site
   inscrit par `relref` — sinon l'assertion vous arrêtera.
3. Rien d'autre : l'installateur et la relocation sont génériques.

Les constantes système sont définies en tête du fichier ; on peut les remplacer par
`include ../INCLUDE/pce500.inc`.

## Assembler

```powershell
cd .\Exemples\DRIVER_TEMPLATE
..\..\bin\xasm2026-4.exe driver_template.asm -O driver_template.obj -L driver_template.lst -B driver.uu
```

## À savoir

- **Validé sur émulateur** : le pilote minimal s'installe et apparaît dans le listing sous
  `DRIVER  .SYS` (protégé), son nom affiché correctement — preuve que le chaînage, la relocation
  et l'en-tête sont bons. Un pilote réel (corps complet) reste à valider pour son propre code.
- **Piège à connaître — `PRE_ON` est indispensable.** Sans lui, les accès à la RAM interne
  (`mv (n),x`, `cmpp (n),y`…) visent `(BP+n)` au lieu de l'absolu `(n)` : l'installateur lit sa
  mémoire de travail au mauvais endroit et échoue au contrôle mémoire (« not enough memory »).
  Il est placé juste après l'`org` ; ne le retirez pas.
- L'installateur est **dérivé de REGISTER2** (validé sur PC-E500S réel), avec un modèle
  d'installation simplifié (ajout en fin, sans recalage BASIC) et une boucle de relocation
  réécrite (comptage explicite).
- La partie *désinstallation* n'est pas encore fournie (livrable suivant) : elle est possible —
  l'état nécessaire (ancienne tête de chaîne, vecteurs détournés) est déjà conservé — sous la
  condition d'être au sommet de la pile de hooks. Voir la section 5 du document de conception.
