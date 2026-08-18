# UUENC2 / UUDEC2 — uuencode/uudecode acceptant les guillemets

Variantes corrigées de `uuencode`/`uudecode` (E. Kako, 1990, pour TY-DOS / PC-E500),
qui acceptent l'argument **entre guillemets complets** — `CALL &BE000 "F:FICHIER.OBJ"` —
là où l'original échouait sur le guillemet **fermant**.

| Fichier | Rôle |
| --- | --- |
| `UUENC2.ASM` / `UUDEC2.ASM` | sources corrigées (dialecte A62) |
| `UUENC2.OBJ` (1772 o) / `UUDEC2.OBJ` (1680 o) | objets, chargés en `0BE000h` |
| `UUENC2.LST` / `UUDEC2.LST` | listings |
| `UUENC2.uu` / `UUDEC2.uu` | auto-décodeurs BASIC (noms Sharp `UUENC2  .OBJ` / `UUDEC2  .OBJ`) |

Noms en **8.3** : distincts des `UUENCODE`/`UUDECODE` d'origine, qu'ils ne remplacent donc pas.

## Le défaut corrigé

La routine `arg:` (analyse de l'argument) traitait les deux guillemets de façon asymétrique :
le **guillemet ouvrant** était sauté (traité comme une espace de tête), mais le **guillemet
fermant** `"` (22h) n'était pas reconnu comme terminateur dans les boucles de lecture du drive
(`arg2`), du nom (`arg3`) et de l'extension (`arg6`). Sur `"F:FICHIER.OBJ"`, le `"` fermant
était donc consommé comme 4ᵉ caractère d'extension, dépassait la limite de 3 et déclenchait
`argerr`.

C'est pourquoi `CALL &BE000 "F:UUENCODE.OBJ` (sans guillemet final) fonctionnait, mais
`CALL &BE000 "F:UUENCODE.OBJ"` (guillemets complets) échouait.

## Le correctif

Trois insertions par programme, deux instructions chacune — traiter `"` (22h) comme un
terminateur là où l'espace l'est déjà :

```asm
        cmp     a,'"'           ; 60 22
        jrz     arg4z           ; (ou arg5z / arg7 selon la boucle)
```

Rien d'autre n'est touché : l'objet ne grandit que de 12 octets (3 × 4), et le comportement
est identique à l'original hormis l'acceptation du guillemet fermant. Le guillemet **en fin
d'argument** ferme proprement le nom, et un `"…OBJ" -s` reste parsé (le `"` se comporte comme
l'espace qui précédait l'option `-s`).

## Charger et tester sur le Sharp

```
LOAD "UUENC2.uu"    ' décode et écrit UUENC2  .OBJ
```

Puis charger `UUENC2.OBJ` en `0BE000h` et l'appeler avec les guillemets complets :

```
CALL &BE000 "F:FICHIER.OBJ"
```

L'original reste dans `../UUENCODE/` pour comparaison.
