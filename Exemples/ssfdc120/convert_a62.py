# Convertit les sources SmartMedia 1.20 du dialecte A62 vers celui de XASM2026-4.
# Le README du paquet indique "A62 でアセンブルできます" : ces fichiers n'ont jamais
# ete ecrits pour XASM, d'ou les directives a prefixe '#' que les deux moteurs refusent.
import re, sys, pathlib, collections

SRC = pathlib.Path(sys.argv[1])
DST = pathlib.Path(sys.argv[2])
DST.mkdir(parents=True, exist_ok=True)

stats = collections.Counter()


def conv_conditionnelle(expr):
    """#if a == b -> IFEQ (a)-(b) ; #if a != b -> IFNE (a)-(b) ; #if a -> IFNE a

    IFEQ/IFNE de XASM ne comparent pas deux operandes : enter_numeric_if (modern.c)
    lit un unique operande et le teste contre zero. Un second operande separe par une
    virgule serait ignore en silence, d'ou la soustraction parenthesee.
    """
    m = re.match(r"^(.+?)\s*==\s*(.+)$", expr)
    if m:
        return f"IFEQ\t({m.group(1).strip()})-({m.group(2).strip()})"
    m = re.match(r"^(.+?)\s*!=\s*(.+)$", expr)
    if m:
        return f"IFNE\t({m.group(1).strip()})-({m.group(2).strip()})"
    # Forme booleenne : vrai si non nul.
    return f"IFNE\t{expr.strip()}"


def conv_ligne(ligne):
    code, sep, comm = ligne.partition(";")

    # Prefixe 'rel' d'A62 : marque un operande a relocaliser au chargement. XASM n'a
    # pas d'equivalent ; on le retire du code et on le conserve en fin de commentaire
    # pour que l'information reste presente et reperable.
    marque = ""
    m = re.match(r"^rel(\s+)(.*)$", code)
    if m:
        code = "\t\t" + m.group(2)
        marque = " ;rel"
        stats["prefixe rel deplace en commentaire"] += 1

    # Immediat binaire d'A62 : #00100000 -> 00100000B
    def bin_imm(m):
        stats["immediat binaire #nnnnnnnn -> nnnnnnnnB"] += 1
        return m.group(1) + "B"

    code = re.sub(r"#([01]{8})\b", bin_imm, code)

    # Directives a prefixe '#'
    m = re.match(r"^(\s*)#(\w+)\s*(.*?)\s*$", code)
    if m:
        blanc, mot, reste = m.group(1), m.group(2).lower(), m.group(3)
        if mot == "include":
            code, stats["#include -> include"] = f"\t\tinclude\t{reste}", stats["#include -> include"] + 1
        elif mot == "defmacro":
            code, stats["#defmacro -> macro"] = f"\t\tmacro\t{reste}", stats["#defmacro -> macro"] + 1
        elif mot == "endmacro":
            code, stats["#endmacro -> endm"] = "\t\tendm", stats["#endmacro -> endm"] + 1
        elif mot == "if":
            code, stats["#if -> IFEQ/IFNE"] = "\t\t" + conv_conditionnelle(reste), stats["#if -> IFEQ/IFNE"] + 1
        elif mot == "else":
            code, stats["#else -> ELSE"] = "\t\tELSE", stats["#else -> ELSE"] + 1
        elif mot == "endif":
            code, stats["#endif -> ENDIF"] = "\t\tENDIF", stats["#endif -> ENDIF"] + 1
        else:
            raise SystemExit(f"directive a prefixe non traitee : #{mot}")

    # preon -> PRE_ON
    if re.match(r"^\s*preon\s*$", code, re.I):
        code, stats["preon -> PRE_ON"] = "\t\tPRE_ON", stats["preon -> PRE_ON"] + 1

    return code + (sep + comm if sep else "") + marque


for f in sorted(SRC.glob("*.ASM")):
    # Les commentaires sont en japonais Shift-JIS (cp932) ; on les rend en UTF-8.
    lignes = f.read_bytes().decode("cp932").split("\r\n")
    out = [conv_ligne(l) for l in lignes]
    cible = DST / f.name.lower()
    cible.write_bytes("\r\n".join(out).encode("utf-8"))
    print(f"  {f.name:14} -> {cible.name}")

print()
for k, v in sorted(stats.items()):
    print(f"  {v:4}  {k}")
