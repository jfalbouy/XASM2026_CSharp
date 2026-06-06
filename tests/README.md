# Tests de non-regression

Ce dossier est reserve aux comparaisons entre :

- la reference `xasm2026-1` ;
- le port C# natif `xasm2026-3`.

## Principe

Pour chaque exemple, generer les sorties avec la reference, puis avec le port C#, et comparer :

```text
obj, lst, hex, s19, map, d, uu, txt
```

## Exemples prioritaires

```text
SAMPLES/SAMPLE5.ASM
VOGUE/VOGUE.S
REGISTER/REGISTER.ASM
TMAP/TMAP2020.asm
```

## Etat actuel

Le port C# natif ne produit pas encore l'assemblage complet. Les tests deviendront actifs lorsque les passes d'assemblage seront branchees.
