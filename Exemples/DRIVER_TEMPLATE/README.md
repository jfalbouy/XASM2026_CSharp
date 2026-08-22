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
3. **Le désinstallateur** (lancé par `CALL &BE000 "-u"`) : retire le pilote de la chaîne des
   devices puis affiche les commandes BASIC de libération (voir ci-dessous).
4. **Les noms définis une seule fois** — macros `drvbase`/`drvext` (fichier) et `drvdev`
   (device), voir ci-dessous.
5. **La discipline de relocation** — l'apport principal (voir plus bas).

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

## La désinstallation

`CALL &BE000 "-u"` (l'argument **doit être entre guillemets** — syntaxe BASIC, comme UUENCODE)
parcourt la chaîne des devices (`0BFCA2h`), retrouve le pilote par son nom de device, et le
**délie** de la chaîne. Deux points de conception :

- **Retour à BASIC.** `CALL` empile le pointeur de ligne sur la pile U ; il faut le **restituer
  avancé** au-delà de l'argument (`popu` à l'entrée, `pushu` du pointeur avancé à la sortie),
  sinon BASIC affiche « Syntax error » au retour. Le squelette le fait ; le solde de la pile U
  est de +1 à chaque `retf`. Deux détails **indispensables**, validés sur matériel (PLINK2,
  REGISTER3) : le scan doit reconnaître les **quatre** terminateurs de BASIC (`0`, `CR`, `1Ah`,
  `0FFh` — ceux d'`argskp` d'UUENCODE), sinon une chaîne *complète* `"-u"` (terminée `1Ah`/`0FFh`)
  fait déborder le scan → « Syntax error » ; et **tous** les chemins de l'installateur rendent la
  main **carry clair** (`rc`), un `CALL` qui rend la main carry armé (`sc`) provoquant lui aussi
  une « Syntax error ». *(Le `sc` du stub `iocs_entry` est autre chose : c'est la réponse du
  pilote résident à une commande non gérée, à conserver.)*
- **Libération de la mémoire.** Le bloc n'est **pas** libéré par le code. Le flag *Protected* du
  système de fichiers (que `KILL` contrôle) n'est pas le bit device testé par les pilotes, et
  l'effacer ne suffit pas (vérifié). Le désinstallateur affiche donc les deux commandes BASIC à
  taper, la ROM se chargeant de la mise à jour du répertoire et du recompactage :

  ```
  SET  "S1:DRIVER.SYS"," "   (ôter la protection)
  KILL "S1:DRIVER.SYS"       (libérer la mémoire)
  ```

- **Vecteurs détournés.** Le stub de ce template ne détourne aucun vecteur : sa désinstallation
  se limite au déliage. **Un vrai pilote résident détourne en général un vecteur** (clavier,
  SIO, timer…) ; il doit alors le **restaurer** dans `un_found`, *avant* le déliage, avec le
  contrôle « sommet de la pile de hooks » (le vecteur pointe-t-il encore vers *votre* handler ?
  sinon un autre pilote a hooké après vous, et le retrait casserait sa chaîne). Le point
  d'insertion est balisé en commentaire ; le modèle complet est `REGISTER3.ASM` (`un_found`).

## Les noms définis une seule fois

Le nom apparaît en plusieurs endroits (en-tête de bloc, messages `SET`/`KILL`, recherche dans la
chaîne). Pour le définir **une seule fois** :

- **Nom de fichier** — `drvbase` (base, ≤ 8 car.) et `drvext` (extension, 3 car.). Deux macros
  le formatent : `name83` pour l'en-tête de bloc (**8 caractères complétés d'espaces, sans
  point**, via `ds 8-(*-_n83),' '`) et `namedot` pour les messages (`base.ext`).
- **Nom de device** — `drvdev` (ex. `'DRV:'`), utilisé par l'en-tête, les messages et la
  recherche de désinstallation.

Pour renommer le pilote, il suffit de changer `drvbase`/`drvext` et `drvdev`.

## Adapter le template

Trois points à personnaliser :

1. **Noms** : `drvbase`/`drvext` (nom de fichier) et `drvdev` (nom de device) en tête du
   fichier ; ainsi que le `number` (n° de device). Les formats 8.3, `base.ext` et la recherche
   en découlent automatiquement.
2. **Corps** : remplacer le stub à partir de `iocs_entry` par vos fonctions. **Chaque adresse
   absolue interne** (un `mv x,table`, un `dp routine`…) doit être émise par `reldp` et son site
   inscrit par `relref` — sinon l'assertion vous arrêtera. Si le corps détourne un vecteur
   système, restaurez-le dans `un_found` (voir *La désinstallation*).
3. Rien d'autre : l'installateur, le désinstallateur et la relocation sont génériques.

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
  et l'en-tête sont bons. Le mécanisme install/désinstall et les macros de nom ont été validés
  de bout en bout sur `REGISTER3` (un vrai pilote qui détourne le clavier) avant d'être portés
  ici. Un pilote réel (corps complet) reste à valider pour son propre code.
- **Piège à connaître — `PRE_ON` est indispensable.** Sans lui, les accès à la RAM interne
  (`mv (n),x`, `cmpp (n),y`…) visent `(BP+n)` au lieu de l'absolu `(n)` : l'installateur lit sa
  mémoire de travail au mauvais endroit et échoue au contrôle mémoire (« not enough memory »).
  Il est placé juste après l'`org` ; ne le retirez pas.
- L'installateur est **dérivé de REGISTER2** (validé sur PC-E500S réel), avec un modèle
  d'installation simplifié (ajout en fin, sans recalage BASIC) et une boucle de relocation
  réécrite (comptage explicite).
- La **désinstallation** (`CALL &BE000 "-u"`) est fournie : déliage de la chaîne des devices +
  affichage des commandes `SET`/`KILL`. Pour un pilote qui détourne un vecteur, la restauration
  (avec contrôle « sommet de la pile de hooks ») est à compléter dans `un_found` — modèle complet
  dans `REGISTER3.ASM`. Voir aussi la section 5 du document de conception.
