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
python tools\generate_pce500_inc.py            # tables prises dans C:\Claude\SC62015Disassembler\Data
python tools\generate_pce500_inc.py <dossier_Data>   # ou un autre emplacement
```

Le générateur donne la priorité à l'adresse **système** sur la RAM interne en cas de nom
identique (`baswrk` = `0BFD0EH`, la version qu'emploient REGISTER et PLINKC), et déduplique les
quelques noms répétés dans les tables source — ceux-ci sont listés en fin de fichier, jamais
émis en double.

## Note sur `imr`, `px`, `py`

Ces trois noms désignent à la fois un registre CPU et une adresse de RAM interne. La définition
`EQU` cohabite sans heurt avec l'usage registre : `pushu imr` reste l'empilement du registre IMR,
tandis que `mv (imr),0A0H` emploie l'adresse `0FBh`. Vérifié à l'assemblage (`example.asm`).
