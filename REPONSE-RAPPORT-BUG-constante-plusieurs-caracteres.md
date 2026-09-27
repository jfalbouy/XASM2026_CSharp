# Réponse au rapport de bug — constante de plusieurs caractères

**Rapport** : `RAPPORT-BUG-constante-plusieurs-caracteres.md` (2026-09-27)
**Réponse du** : 2026-09-27
**Statut** : ✅ **confirmé et corrigé**, avec un **écart volontaire assumé** vis-à-vis du moteur C.

Merci pour ce rapport : le diagnostic, la lecture des trois moteurs et surtout la **mesure sur
l'objet d'époque** rendaient la décision possible sans rien deviner.

---

## 1. Vérifications

Tout ce qu'annonce le rapport se reproduit :

| Vérification | Résultat |
|---|---|
| Les six lignes du §2 | reproduites à l'octet près (`mv i,'+B'` → `0B 42 00`) |
| Le moteur C `xasm2026-1-2` sur la même source | **mêmes octets** que le port : ce n'est pas une régression du portage |
| `TMAP.obj` (TORO, 1994) aux offsets `0CBh`, `0DAh`, `0DFh`, `36Bh` | `0A 20 5B`, `0A 5D 20`, `0A 20 20`, `0B 42 2B` — l'accumulation est bien le comportement de 1994 |
| `eval.c` des deux moteurs C | `x = txt[txt_p-1]` écrase, et traite l'apostrophe doublée **dans** la boucle |
| Corpus | `MV I,'+B'` dans TMAP2020/TMAP2021, `cmp a,'""'` dans trdos033, `MV BA,'..'` dans le TMAP de 1994 : rien d'autre |

---

## 2. Décisions

Le point n'était pas technique : accumuler fait **diverger le port du moteur C**, ce qui touche à
la contrainte fondatrice du projet. Quatre choix ont été tranchés par le responsable :

| Question | Décision |
|---|---|
| Accumuler ? | **Oui, par défaut** : les octets de 1994 l'emportent sur la fidélité à XASM 1.40, qui était déjà fautif sur ces sources |
| Apostrophe doublée dans une constante longue | **Accumulée** comme un caractère : `'A'''` = `4127h` |
| Plus de 3 caractères (> 20 bits) | **Erreur fatale**, pas de troncature muette |
| §6, immédiat trop grand tronqué en silence | **Laissé en l'état** : un avertissement toucherait aussi des sources d'époque comme TRDOS. À traiter séparément |

---

## 3. Correction

`ParseCharacter()` (`src/Expressions/ExpressionEvaluator.cs`) accumule : `value = (value << 8) | c`.
L'apostrophe doublée est traitée **dans** la boucle, comme le fait XASM 1.40. Au-delà de trois
caractères, le drapeau `CharacterTooLong` est levé ; `NativeAssembler.Eval` en fait une erreur
fatale — sur **les deux passes**, la valeur ne dépendant d'aucun symbole, contrairement à la
division par zéro.

Résultat sur les lignes du §2 :

```
0BE000 0B 42 2B   mv  i,'+B'        <- 1994 : 0B 42 2B
0BE003 0A 42 41   mv  ba,'AB'
0BE006 0C 43 42 41 mv x,'ABC'
0BE00A 41 42      dw  'AB'          <- inchangé
0BE00C 08 41      mv  a,'A'         <- inchangé
0BE00E 0B 42 2B   mv  i,'+B'+0
0BE011 0B 27 41   mv  i,'A'''       <- 4127h
0BE014 08 27      mv  a,''''        <- inchangé
```

`mv x,'ABCD'` donne désormais : `ligne 2: Character constant too long (3 caracteres au plus)`.

Les chaînes de `DB`/`DM`/`DW` **ne passent pas par l'évaluateur** : elles restent émises caractère
par caractère, sans changement.

---

## 4. Ce qui bouge, et l'écart assumé

- **Témoins TMAP régénérés** : `TMAP2020` (8 sorties) et `TMAP2021` (3 sorties), **un seul octet**
  de code chacun (`00` → `2B` à l'offset `37Bh`), plus les sommes de contrôle `.hex`/`.s19`/`.uu`
  qui en découlent. `.map` et `.d` sont inchangés. Chaque témoin a été régénéré avec son
  **invocation historique** — minuscules et `-S` pour TMAP2020, majuscules pour TMAP2021 — et la
  date de soumission d'origine des `.uu` a été conservée, pour que le diff se limite au fait
  nouveau.
- **Écart avec le moteur C** : `TMAP2020.obj` diffère désormais de `xasm2026-1-2` d'**un octet
  exactement**, mesuré. C'est le **premier écart volontaire** du port. Il est documenté dans
  `CLAUDE.md`, `tests/README.md` et le journal `PORTAGE.md` : tout **autre** écart reste un
  défaut.
- **Non-régression** : les goldens SAMPLE5, VOGUE, REGISTER, `postbyte_families`,
  `prebyte_families` (2520 cas), `PLINKC.OBJ`, TUTORIEL et `coverage_all` sont inchangés.
  **314 tests verts**.

---

## 5. Tests ajoutés

Comme le suggérait le §5 :

- `BehaviorTests.Multi_character_constants_accumulate` : les six lignes du §2, plus `'A'''`,
  `''''`, `db 'AB'` et `dw 'AB'` — 9 cas, avec les octets attendus ;
- `BehaviorTests.Character_constant_longer_than_three_is_an_error` : 3 cas de refus.

---

## 6. Sur le §7 (contournement)

La réécriture 2026 de TMAP écrit `mv i,0422bh` avec le commentaire `"+B"`. Cela reste
juste : l'écriture hexadécimale ne change pas de sens. Elle peut maintenant redevenir
`mv i,'+B'`, plus lisible, si vous le souhaitez.

Attention en revanche si cette source doit aussi s'assembler avec le moteur C `xasm2026-1-2` :
lui garde le comportement de XASM 1.40, et rendrait `0B 42 00`. La forme hexadécimale est la seule
qui donne les mêmes octets avec les deux moteurs.
