# Convertit PLINKC.asm (dialecte A62 / Kon) vers le dialecte XASM2026-4.
# Les constructions specifiques a A62 :
#   - #DEFMACRO bsr / rel call %0 / #ENDMACRO : la macro bsr = "rel call <arg>".
#     rel ne produit rien dans cet objet (verifie : le desassemblage se reassemble
#     exact sans table de relocation), donc bsr X se reduit a call X. On supprime la
#     definition de macro et on remplace chaque appel.
#   - prefixe 'rel' devant une instruction : retire, reporte en commentaire ;rel.
#   - '%' seul = compteur de localisation -> '*'. '%0' = argument de macro (n'existe
#     plus une fois bsr deplie).
#   - suborg / byte / word / pntr et les blocs { } continue/break : directives natives
#     de XASM2026-4, conservees telles quelles.
#   - hex '$xx', 'pre $xx', 'pmdf (n),*', 'sbcl', 'cmpw' : deja compris tels quels.
import re, sys, pathlib

src = pathlib.Path(sys.argv[1])
dst = pathlib.Path(sys.argv[2])

raw = src.read_bytes().replace(b"\r\n", b"\n").replace(b"\r", b"\n").decode("latin-1")
out = []
stats = {"rel retire": 0, "bsr -> call": 0, "% -> *": 0, "macro bsr supprimee": 0}

lines = raw.split("\n")
i = 0
while i < len(lines):
    l = lines[i]
    # Supprimer le bloc #DEFMACRO bsr ... #ENDMACRO
    if re.match(r"^\s*#DEFMACRO\b", l, re.I):
        while i < len(lines) and not re.match(r"^\s*#ENDMACRO\b", lines[i], re.I):
            i += 1
        i += 1  # sauter #ENDMACRO
        stats["macro bsr supprimee"] += 1
        continue

    code, sep, comment = l.partition(";")

    # Separer une eventuelle etiquette de tete (label:) : rel et bsr peuvent la suivre.
    ml = re.match(r"^(\s*\w+:\s*)(.*)$", code)
    label, reste = (ml.group(1), ml.group(2)) if ml else ("", code)

    # prefixe 'rel' (indentation preservee)
    m = re.match(r"^(\s*)rel\s+(.*)$", reste)
    if m:
        reste = m.group(1) + m.group(2)
        comment = (comment + " " if comment else "") + "rel"
        sep = ";"
        stats["rel retire"] += 1

    # bsr X -> call X
    m = re.match(r"^(\s*)bsr(\s+)(\S+)(.*)$", reste)
    if m:
        reste = f"{m.group(1)}call{m.group(2)}{m.group(3)}{m.group(4)}"
        stats["bsr -> call"] += 1

    code = label + reste

    # '%' reste inchange : en position de terme c'est le compteur secondaire (SUBORG),
    # entre deux valeurs c'est le modulo — meme convention que le dialecte A62, desormais
    # comprise nativement par l'evaluateur.

    out.append(code + (sep + comment if sep else ""))

    # Le bloc { } ouvert a la boucle d'attente SIO n'est jamais referme dans la source A62
    # d'origine (l'assembleur de Kon le tolere). XASM2026-4 exige des blocs equilibres : on
    # ferme le bloc juste apres son unique 'jrz continue', ou la boucle d'attente se termine.
    # La '}' n'emet aucun octet, l'objet est donc inchange, et la source devient bien formee.
    if "jrz\tcontinue" in l or re.search(r"\bjrz\s+continue\b", l):
        out.append("\t}")
        stats["bloc { } ferme"] = stats.get("bloc { } ferme", 0) + 1

    i += 1

dst.write_bytes("\n".join(out).encode("latin-1"))
for k, v in stats.items():
    print(f"  {v:4}  {k}")
