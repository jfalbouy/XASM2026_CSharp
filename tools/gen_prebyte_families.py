#!/usr/bin/env python3
"""Genere tests/prebyte_families.expected.txt a partir du moteur C de reference.

Chaque instruction portant un operande de RAM interne est assemblee SEULE par
Reference/C/xasm2026-1-2.exe, sous pre_on puis sous pre_off, et les octets de
code sont releves dans l'objet (en-tete de 16 octets saute). Une forme que le
moteur C refuse est notee "(refus attendu)".

Les operandes internes varient sur les modes qui changent l'octet PRE :
adresse directe (n), BP+n, PX+n, PY+n, et BP+PX / BP+PY pour les formes a deux
operandes. C'est ce qui permet de verifier l'octet PRE lui-meme, sa place (en
tete) et son unicite -- cf. RAPPORT-BUG-octet-pre.md.

Usage : python tools/gen_prebyte_families.py [--reference chemin.exe]
"""
import argparse
import concurrent.futures
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_REFERENCE = ROOT / "Reference" / "C" / "xasm2026-1-2.exe"
OUTPUT = ROOT / "tests" / "prebyte_families.expected.txt"

# Un seul operande interne.
SINGLE = ["(00BH)", "(BP+3)", "(PX+3)", "(PY+3)"]
# Deux operandes internes : le premier et le second n'admettent pas les memes modes.
FIRST = ["(00CH)", "(BP+4)", "(PX+4)", "(BP+PX)"]
SECOND = ["(00BH)", "(BP+3)", "(PY+3)", "(BP+PY)"]

REGISTERS = ["a", "il", "ba", "i", "x", "y", "u", "s"]
INDEXES = ["[y]", "[y++]", "[--y]", "[y+2]", "[y-2]"]
EXTERNAL = "[0BF800H]"


def single_templates():
    """Formes a un operande interne ; I est remplace par chaque mode de SINGLE."""
    for op in ["add", "sub", "adc", "sbc", "and", "or", "xor"]:
        yield f"{op} I,012H"
        yield f"{op} I,a"
        yield f"{op} a,I"
    yield "cmp I,012H"
    yield "cmp I,a"
    yield "test I,012H"
    yield "test I,a"
    for op in ["adcl", "sbcl", "dadl", "dsbl"]:
        yield f"{op} I,a"
    yield "pmdf I,012H"
    yield "pmdf I,a"
    yield "cmpw I,ba"
    yield "cmpw I,i"
    yield "cmpp I,x"
    yield "cmpp I,y"
    for op in ["inc", "dec", "ror", "rol", "shr", "shl", "dsll", "dsrl"]:
        yield f"{op} I"
    for reg in REGISTERS:
        yield f"mv {reg},I"
        yield f"mv I,{reg}"
        yield f"mv {reg},[I]"
        yield f"mv [I],{reg}"
        yield f"mv {reg},[I+2]"
        yield f"mv [I+2],{reg}"
    yield "mv I,012H"
    yield "mvw I,01234H"
    yield "mvp I,012345H"
    for op in ["mv", "mvw", "mvp", "mvl"]:
        yield f"{op} I,{EXTERNAL}"
        yield f"{op} {EXTERNAL},I"
        for index in INDEXES:
            yield f"{op} I,{index}"
            yield f"{op} {index},I"
    yield "jp I"


def double_templates():
    """Formes a deux operandes internes ; M prend FIRST, N prend SECOND."""
    for op in ["mv", "mvw", "mvp", "mvl", "mvld", "ex", "exw", "exp", "exl",
               "cmp", "cmpw", "cmpp", "and", "or", "xor",
               "adcl", "sbcl", "dadl", "dsbl"]:
        yield f"{op} M,N"
    for op in ["mv", "mvw", "mvp", "mvl"]:
        for suffix in ["", "+2", "-2"]:
            yield f"{op} M,[N{suffix}]"
            yield f"{op} [M{suffix}],N"


def instructions():
    for template in single_templates():
        for operand in SINGLE:
            yield _replace_marker(template, "I", operand)
    for template in double_templates():
        for first in FIRST:
            for second in SECOND:
                yield _replace_marker(_replace_marker(template, "M", first), "N", second)


def _replace_marker(template, marker, operand):
    """Remplace le marqueur dans les operandes seulement (jamais dans le mnemonique)."""
    mnemonic, _, operands = template.partition(" ")
    parts = []
    for part in operands.split(","):
        if part == marker:
            parts.append(operand)
        elif part.startswith("[" + marker):
            parts.append("[" + operand + part[1 + len(marker):])
        else:
            parts.append(part)
    return f"{mnemonic} {','.join(parts)}"


def assemble(reference, mode, instruction):
    with tempfile.TemporaryDirectory(prefix="xasm_pre_") as work:
        source = pathlib.Path(work) / "T.ASM"
        source.write_text(
            f"\torg\t0BF000H\n\t{mode}\n\t{instruction}\n\tend\n", encoding="ascii")
        run = subprocess.run([str(reference), "T.ASM", "-O"], cwd=work,
                             capture_output=True, text=True)
        obj = pathlib.Path(work) / "T.obj"
        if run.returncode != 0 or not obj.exists():
            return "(refus attendu)"
        code = obj.read_bytes()[16:]
        return " ".join(f"{b:02x}" for b in code)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--reference", default=str(DEFAULT_REFERENCE))
    args = parser.parse_args()
    reference = pathlib.Path(args.reference)

    cases = []
    seen = set()
    for mode in ["pre_on", "pre_off"]:
        for instruction in instructions():
            if (mode, instruction) not in seen:
                seen.add((mode, instruction))
                cases.append((mode, instruction))

    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        results = list(pool.map(lambda c: assemble(reference, *c), cases))

    lines = [
        "# Octets attendus pour les formes a operande de RAM interne (octet PRE).",
        "# Genere par tools/gen_prebyte_families.py avec le moteur C xasm2026-1-2 :",
        "# chaque instruction assemblee seule, a 0BF000h, sous le mode indique.",
        "# Format : mode <TAB> instruction <TAB> octets | (refus attendu)",
        "",
    ]
    lines += [f"{mode}\t{instruction}\t{expected}"
              for (mode, instruction), expected in zip(cases, results)]
    OUTPUT.write_text("\n".join(lines) + "\n", encoding="ascii", newline="\n")
    refused = sum(1 for r in results if r == "(refus attendu)")
    print(f"{len(cases)} cas ecrits dans {OUTPUT} ({refused} refus attendus)")


if __name__ == "__main__":
    main()
