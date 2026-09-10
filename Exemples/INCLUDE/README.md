# `pce500.inc` — constantes système du SHARP PC-E500S / SC62015

Fichier d'inclusion prêt à l'emploi pour démarrer un nouveau projet. Une seule ligne suffit :

```asm
        include pce500.inc
```

Il définit **276 constantes** (`EQU`) réparties en sections :

| Section | Contenu | Exemples |
| --- | --- | --- |
| Registres RAM interne (00h–0FFh) | pseudo-registres et zones de travail | `bl`, `cl`, `imr`, `ssr`, `ucr`, `bp_ram`, `si`, `di` |
| Adresses système et vecteurs (20 bits) | carte mémoire, vecteurs, curseur | `s1_top`, `s1_btm`, `baswrk`, `fcs_call`, `iocs_call`, `keyv` |
| Codes de fonction FCS | numéro à mettre dans `IL` | `fcs_open_file`, `fcs_read`, `fcs_close_file` |
| Codes de fonction IOCS communs | idem, fonctions partagées | `iocs_find_drive`, `iocs_memory_directory` |
| Numéros de device IOCS | à placer dans `(cl)` = `0D6h` | `dev_display`, `dev_key`, `dev_sio`, `dev_memcard` |
| Codes de fonction IOCS par device | commandes ≥ 41h, préfixées par le device | `display_char_out_at`, `key_getkey`, `sio_send_byte` |

Voir `example.asm` pour un usage typique (appel FCS, appel IOCS, accès aux registres).

## Cohérence avec le désassembleur

Les noms et adresses **ne sont pas saisis à la main** : le fichier est **généré** à partir des
tables du désassembleur `SC62015Disassembler` (`Data/InternalRAMNames.json`,
`SystemAddresses.json`, `FCSFunctions.json`), la source autoritative alignée sur le listing de
référence. Écrire une source avec ces noms puis la désassembler là-bas redonne donc les **mêmes
étiquettes** — les deux outils parlent le même vocabulaire.

Pour régénérer après une évolution des tables :

```powershell
python tools\generate_pce500_inc.py                  # tables du desassembleur (emplacement par defaut)
python tools\generate_pce500_inc.py <dossier_Data>   # ou un dossier Data explicite
```

Le générateur donne la priorité à l'adresse **système** sur la RAM interne en cas de nom
identique (`baswrk` = `0BFD0EH`, la version qu'emploient REGISTER et PLINKC), et déduplique les
quelques noms répétés dans les tables source — ceux-ci sont listés en fin de fichier, jamais
émis en double.

## Note sur `imr`, `px`, `py`

Ces trois noms désignent à la fois un registre CPU et une adresse de RAM interne. La définition
`EQU` cohabite sans heurt avec l'usage registre : `pushu imr` reste l'empilement du registre IMR,
tandis que `mv (imr),0A0H` emploie l'adresse `0FBh`. Vérifié à l'assemblage (`example.asm`).

## Un listing court avec `-K`

Inclure `pce500.inc` insère ses 276 constantes dans le `.lst`, ce qui le noie. L'option **`-K`**
(à combiner avec `-L`) n'y conserve, **des fichiers inclus**, que les constantes réellement
**utilisées** par le programme :

```powershell
..\..\bin\xasm2026-4.exe example.asm -O example.obj -L example.lst -K
```

Sur `example.asm`, le listing passe de **357 à 36 lignes** : la source principale reste
intégrale (commentaires, code, `end`) et l'include se réduit aux ~10 constantes employées, avec
leur commentaire. Tout ce qui n'émet pas d'octet et n'est pas une constante utilisée (constantes
inutiles, en-têtes de section, lignes vides) est masqué. C'est un **filtre de listing pur** :
l'objet et les autres sorties sont identiques avec ou sans `-K`, et les goldens (produits sans
`-K`) restent inchangés.

## Vue triée par adresse

Pour visualiser la **continuité de la mémoire** et retrouver *ce qui se trouve à une adresse
donnée*, le document `Documentation/Carte_Memoire_PC-E500S.md` liste ces mêmes constantes
**triées par adresse croissante** (RAM interne, registres d'E/S, zone système, points d'entrée
ROM), avec les codes de fonction FCS/IOCS et numéros de device en tables séparées. Il est généré
depuis `pce500.inc` par `tools/gen_carte_memoire.py`.
