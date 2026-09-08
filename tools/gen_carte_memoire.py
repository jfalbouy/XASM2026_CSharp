#!/usr/bin/env python3
# Genere Carte_Memoire_PC-E500S.md a partir de pce500.inc :
#  - les constantes d'ADRESSE (RAM interne + systeme/vecteurs) triees par adresse
#    (une seule table, pour visualiser la continuite memoire) ;
#  - les constantes de CODE (fonctions FCS/IOCS, numeros de device) en tables
#    separees, triees par valeur, clairement etiquetees "pas des adresses".
import re, datetime

INC = r"C:\Claude\xasm2026-4\Exemples\INCLUDE\pce500.inc"
OUT = r"C:\Claude\xasm2026-4\Documentation\Carte_Memoire_PC-E500S.md"

# section courante -> categorie
SECTIONS = {
    "Registres et zones de la RAM interne": ("adr", "RAM interne (00h-0FFh)"),
    "Adresses systeme et vecteurs":        ("adr", "Adresses systeme / vecteurs (20 bits)"),
    "Codes de fonction FCS":               ("fcs", "Codes de fonction FCS (dans IL)"),
    "Codes de fonction IOCS communs":      ("iocs", "Codes de fonction IOCS communs (dans IL)"),
    "Numeros de device IOCS":              ("dev", "Numeros de device IOCS (dans (cl)=0D6h)"),
    "Codes de fonction IOCS par device":   ("iocsdev", "Codes de fonction IOCS par device (IL >= 41h)"),
    "Doublons de nom":                     ("dup", "Doublons"),
}

entries = {"adr": [], "fcs": [], "iocs": [], "dev": [], "iocsdev": [], "dup": []}
cat = None
for line in open(INC, encoding="latin-1"):
    m = re.match(r"^;\s*---\s*(.+?)\s*-+", line)
    if m:
        cat = None
        for key, (c, _) in SECTIONS.items():
            if line.find(key) >= 0:
                cat = c
        continue
    m = re.match(r"^\s*([A-Za-z_][\w]*)\s*:?\s*equ\s+([0-9A-Fa-f]+)[Hh]?\b\s*(?:;\s*(.*))?$", line)
    if m and cat and cat != "dup":
        name, val, comment = m.group(1), int(m.group(2), 16), (m.group(3) or "").strip()
        entries[cat].append((val, name, comment))

def table(rows, addr=True):
    out = []
    col = "Adresse" if addr else "Valeur"
    out.append(f"| {col} | Nom | Description |")
    out.append("|---|---|---|")
    for val, name, comment in rows:
        v = f"`0{val:05X}H`" if addr else f"`{val:02X}h`" + (f" ({val})" if val < 256 else "")
        c = comment.replace("|", "\\|")
        out.append(f"| {v} | `{name}` | {c} |")
    return "\n".join(out)

adr = sorted(entries["adr"])
# marquer les frontieres de region pour la lisibilite
today = datetime.date.today().strftime("%d/%m/%Y")
doc = []
doc.append("# Carte mémoire du SHARP PC-E500S — constantes triées par adresse\n")
doc.append(f"Version du document : {today}\n")
doc.append(
    "Ce document présente les **constantes système** de `Exemples/INCLUDE/pce500.inc` "
    "**triées par adresse croissante**, pour visualiser la continuité de la mémoire et "
    "retrouver rapidement *ce qui se trouve à une adresse donnée*. Il est **généré** depuis "
    "`pce500.inc` (lui-même généré depuis les tables du désassembleur `SC62015Disassembler`) : "
    "ne pas l'éditer à la main — régénérer par `python tools/gen_carte_memoire.py`.\n")
doc.append(
    "> Les tables du bas (**codes de fonction FCS/IOCS**, **numéros de device**) ne sont **pas "
    "des adresses** : ce sont des valeurs à placer dans un registre (`IL`, `(cl)`). Elles sont "
    "listées à part, triées par valeur.\n")

# --- table des adresses, avec en-tetes de region ---
doc.append("## Adresses mémoire (triées)\n")
doc.append(f"{len(adr)} constantes d'adresse, de `0{adr[0][0]:05X}H` à `0{adr[-1][0]:05X}H`.\n")

def region_of(v):
    if v <= 0xFF:      return "RAM interne du CPU (00h–0FFh) — vue aussi par PEEK/POKE 0–255"
    if v < 0x0B0000:   return "Registres d'E/S mappés en mémoire (afficheur LCD, etc.)"
    if v < 0x0BF000:   return "Zone 0Bxxxxh"
    if v < 0x0BFC00:   return "Zone de travail BASIC / système (0BFxxxh)"
    if v < 0x0C0000:   return "Zone système haute (0BFCxxh–0BFFxxh) : chaîne des devices, vecteurs, pointeurs S1"
    if v < 0x0F0000:   return "Cartouches / ROM basse"
    return "ROM système (0Fxxxxh) : points d'entrée FCS/IOCS"

cur = None
buf = []
for val, name, comment in adr:
    r = region_of(val)
    if r != cur:
        if buf:
            doc.append(table(buf, addr=True) + "\n")
            buf = []
        cur = r
        doc.append(f"### {r}\n")
    buf.append((val, name, comment))
if buf:
    doc.append(table(buf, addr=True) + "\n")

# --- tables des codes (pas des adresses) ---
doc.append("## Codes de fonction et numéros (ne sont pas des adresses)\n")
for c, title in [("fcs","Codes de fonction FCS (dans IL)"),
                 ("iocs","Codes de fonction IOCS communs (dans IL)"),
                 ("dev","Numéros de device IOCS (dans (cl) = 0D6h)"),
                 ("iocsdev","Codes de fonction IOCS par device (IL >= 41h)")]:
    rows = sorted(entries[c])
    if rows:
        doc.append(f"### {title}\n")
        doc.append(table(rows, addr=False) + "\n")

open(OUT, "w", encoding="utf-8", newline="\r\n").write("\n".join(doc))
n = sum(len(v) for v in entries.values())
print(f"ecrit {OUT}  ({n} constantes : {len(adr)} adresses + {n-len(adr)} codes)")
