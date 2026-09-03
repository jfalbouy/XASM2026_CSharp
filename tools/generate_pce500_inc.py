#!/usr/bin/env python3
# Genere Exemples/INCLUDE/pce500.inc a partir des tables du desassembleur SC62015Disassembler
# (Data/InternalRAMNames.json, SystemAddresses.json, FCSFunctions.json). Ces tables sont la
# source autoritative, alignee sur le listing de reference ; regenerer l'include depuis elles
# garantit la coherence entre le desassembleur et l'assembleur.
#
#   python tools/generate_pce500_inc.py [chemin_du_dossier_Data]
import json, re, sys, datetime, pathlib

DATA = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path(r"C:/Claude/SC62015Disassembler/Data")
OUT = pathlib.Path(__file__).resolve().parent.parent / "Exemples" / "INCLUDE" / "pce500.inc"

def hx(s):
    """0xCB -> 0CBH ; 0xBFC15 -> 0BFC15H (chiffre de tete obligatoire, sinon c'est un symbole)."""
    h = s[2:].upper() if s.lower().startswith("0x") else s.upper()
    if h[0] not in "0123456789":
        h = "0" + h
    return h + "H"

def load(fn):
    return json.load(open(DATA / fn, encoding="utf-8"))

lines = []
used = set()          # noms deja definis : garantit l'unicite globale des EQU
skipped = []          # (nom, adresse) ignores pour cause de doublon, listes en fin de fichier
def emit(s=""): lines.append(s)

def define(name, addr, desc, width, hexw):
    """Emet un EQU si le nom est neuf ; sinon l'ignore et le consigne (pas de doublon)."""
    if name in used:
        skipped.append((name, addr))
        return
    used.add(name)
    line = f"{name+':':<{width+1}} equ {addr:<{hexw}}"
    if desc:
        line += f" ; {desc}"
    emit(line.rstrip())

def block(items, addrkey, namekey):
    width = max((len(x[namekey]) for x in items), default=8)
    hexw = max((len(hx(x[addrkey])) for x in items), default=8)
    for x in items:
        define(x[namekey], hx(x[addrkey]), x.get("desc", "").strip(), width, hexw)

iram = load("InternalRAMNames.json")["names"]
sysa = load("SystemAddresses.json")["addresses"]
fcs = load("FCSFunctions.json")

# Un meme nom pour deux adresses rend l'une des deux INNOMMABLE dans une source, et
# ce fichier etait l'endroit ou elle disparaissait -- en silence.
#
# C'est arrive, et cela a coute une dizaine d'essais sur machine le 2026-09-03 :
# "baswrk" designait 0D1h (le POINTEUR, en RAM interne) et 0BFD0Eh (la ZONE, en
# memoire externe, nom repris du listing de E. Kako). Ce filtre ecartait l'interne
# sans rien dire ; "mv x,(baswrk)" assemblait donc la version systeme, que XASM
# TRONQUAIT a 8 bits pour un acces interne -- 0BFD0Eh devenait 0Eh, toujours sans
# avertissement. Une extension BASIC installait ses crochets a la mauvaise adresse.
#
# On REFUSE desormais. Une collision est un defaut des carnets, a corriger la-bas :
# SC62015Disassembler/Tests/CarnetNameCollisionTests.cs la verrouille depuis.
collisions = sorted({x["name"] for x in iram} & {x["name"] for x in sysa})
if collisions:
    sys.exit("generate_pce500_inc: collision de noms entre les carnets -- l une des "
             "deux adresses serait innommable dans une source : "
             + ", ".join(collisions)
             + " | Corriger Data/InternalRAMNames.json ou Data/SystemAddresses.json.")

emit("; ============================================================================")
emit("; pce500.inc - constantes systeme du SHARP PC-E500S / SC62015")
emit("; ============================================================================")
emit(";")
emit("; GENERE automatiquement par tools/generate_pce500_inc.py a partir des tables")
emit("; du desassembleur SC62015Disassembler (Data/*.json), source autoritative alignee")
emit("; sur le listing de reference. NE PAS EDITER A LA MAIN : regenerer depuis les tables.")
emit(f"; Genere le {datetime.date.today().isoformat()}.")
emit(";")
emit("; Usage :   include pce500.inc")
emit(";")
emit("; Adresses en hexa avec chiffre de tete (0BFC15H) : XASM exige qu'un nombre commence")
emit("; par un chiffre ou $. Les noms sont ceux qu'emet le desassembleur, d'ou la coherence")
emit("; entre une source ecrite ici et un desassemblage relu la-bas.")
emit("")
emit("; --- Registres et zones de la RAM interne (00h-0FFh) ---------------------------")
block(iram, "addr", "name")
emit("")
emit("; --- Adresses systeme et vecteurs (20 bits) -----------------------------------")
block(sysa, "addr", "name")
emit("")
emit("; --- Codes de fonction FCS (IL) -----------------------------------------------")
emit("; (les points d'entree fcs_call=0FFFE4H et iocs_call=0FFFE8H figurent ci-dessus)")
for x in fcs["fcs"]:
    define("fcs_" + x["name"], hx(x["il"]), x["desc"][:90], 24, 5)
emit("")
emit("; --- Codes de fonction IOCS communs (IL) --------------------------------------")
for x in fcs["iocs"]:
    define("iocs_" + x["name"], hx(x["il"]), x["desc"][:90], 24, 5)
emit("")
emit("; --- Numeros de device IOCS (a placer dans (cl) = 0D6h) ------------------------")
for dev in fcs["iocs_devices"]:
    define("dev_" + dev["name"], hx(hex(dev["device"])), f"device {dev['device']} ({dev['drives']})", 16, 5)
emit("")
emit("; --- Codes de fonction IOCS par device (IL >= 41h) ----------------------------")
for dev in fcs["iocs_devices"]:
    emit(f"; device {dev['device']} : {dev['name']} ({dev['drives']})")
    for fn in dev.get("functions", []):
        if fn["name"] in ("unused", "non_documente"):
            continue
        define(f"{dev['name']}_{fn['name']}", hx(fn["il"]), fn["desc"][:80], 28, 5)
    emit("")

if skipped:
    emit("; --- Doublons de nom dans les tables source, ignores pour rester univoque ------")
    for n, a in skipped:
        emit(f";   {n}  (aussi a {a})")
    emit("")

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"ecrit : {OUT}  ({len(lines)} lignes)")
