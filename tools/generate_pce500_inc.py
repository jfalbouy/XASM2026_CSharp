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

# ---------------------------------------------------------------------------
# Les deux bornes du moteur C historique (xasm2026-1-2), mesurees le 2026-09-11
# ---------------------------------------------------------------------------
# src/genop.c lit ses lignes par fgets(asmtext, 255, ...) : une ligne de 254
# caracteres ou plus n'est pas refusee, elle est COUPEE EN DEUX, et la suite
# devient une ligne a part entiere -- d'ou un "Label format error" signale sur la
# ligne suivante. Et ses labels sont bornes a 16 caracteres.
#
# Tant que l'include depassait ces bornes, le controle croise entre les deux
# assembleurs demandait une copie expurgee du carnet : une verification qui
# porte sur autre chose que le fichier livre ne vaut pas grand-chose. On respecte
# donc les deux bornes ici, une fois pour toutes.
LARGEUR_MAX = 16      # longueur maximale d'un label, borne du moteur C
LIGNE_MAX = 250       # marge sous les 253 caracteres que fgets(255) tolere

# Abreviations appliquees SEULEMENT a un nom qui depasse encore LARGEUR_MAX apres
# le prefixe de device. Un nom qui tient est laisse tel quel : mieux vaut la
# lisibilite quand elle est gratuite.
ABREV = {
    "table": "tbl", "buffer": "buf", "matrix": "mtx", "block": "blk",
    "create": "cre", "transfer": "xfer", "format": "fmt", "read": "rd",
    "write": "wr", "sector": "sect", "verify": "vfy",
}

def raccourcir(name):
    """Ramene un nom sous LARGEUR_MAX par la table ci-dessus, ou echoue en le disant."""
    if len(name) <= LARGEUR_MAX:
        return name
    court = "_".join(ABREV.get(m, m) for m in name.split("_"))
    if len(court) > LARGEUR_MAX:
        sys.exit(f"generate_pce500_inc: '{name}' fait {len(name)} caracteres et "
                 f"'{court}' en fait encore {len(court)} : le moteur C en refuse "
                 f"plus de {LARGEUR_MAX}. Ajouter une abreviation a ABREV.")
    return court

lines = []
used = {}             # nom emis -> nom complet d'origine : unicite globale des EQU
skipped = []          # (nom, adresse) ignores pour cause de doublon, listes en fin de fichier
def emit(s=""): lines.append(s)

def define(name, addr, desc, width, hexw, complet=None):
    """Emet un EQU si le nom est neuf ; sinon l'ignore et le consigne (pas de doublon).

    `complet` est le nom documente ailleurs (carnet, CLAUDE.md) quand il differe de
    celui qu'on emet : il ouvre alors le commentaire, pour que rien ne se perde.
    """
    complet = complet or name
    name = raccourcir(name)
    if name in used:
        # ⛔ Un raccourcissement ne doit JAMAIS faire disparaitre une constante en
        # silence : si deux noms complets differents se rejoignent, c'est un defaut
        # de la table ABREV, pas un doublon des carnets.
        if used[name] != complet:
            sys.exit(f"generate_pce500_inc: '{complet}' et '{used[name]}' se "
                     f"raccourcissent tous deux en '{name}'. Corriger ABREV.")
        skipped.append((complet, addr))
        return
    used[name] = complet
    line = f"{name+':':<{width+1}} equ {addr:<{hexw}}"
    if desc or name != complet:
        # le nom complet ouvre le commentaire : rien n'est perdu, et un grep sur
        # l'ancien nom retrouve la constante
        line += " ; " + (f"{complet} - {desc}" if name != complet and desc
                         else complet if name != complet else desc)
    line = line.rstrip()
    if len(line) > LIGNE_MAX:
        line = line[:LIGNE_MAX - 4].rstrip() + " ..."
    emit(line)

def block(items, addrkey, namekey):
    width = max((len(raccourcir(x[namekey])) for x in items), default=8)
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
emit("; Prefixe dN_ = le NUMERO du device, celui-la meme qu'il faut poser dans (cl) :")
emit("; un code de fonction >= 41h ne veut rien dire sans lui (043h vaut key_read sur le")
emit("; clavier et printer_check sur l'imprimante). Le nom complet d'origine ouvre le")
emit("; commentaire, de sorte qu'un grep sur display_guide_line retrouve d0_guide_line.")
for dev in fcs["iocs_devices"]:
    emit(f"; device {dev['device']} : {dev['name']} ({dev['drives']})")
    for fn in dev.get("functions", []):
        if fn["name"] in ("unused", "non_documente"):
            continue
        define(f"d{dev['device']}_{fn['name']}", hx(fn["il"]), fn["desc"][:80], 16, 5,
               complet=f"{dev['name']}_{fn['name']}")
    emit("")

if skipped:
    emit("; --- Doublons de nom dans les tables source, ignores pour rester univoque ------")
    for n, a in skipped:
        emit(f";   {n}  (aussi a {a})")
    emit("")

# Le moteur C historique exige un END dans CHAQUE fichier inclus (« EOF comes before
# END ») ; xasm2026-4 l'accepte sans broncher, et ni l'un ni l'autre n'arrete pour
# autant l'assemblage du fichier appelant.
emit("; --- Fin du carnet ------------------------------------------------------------")
emit("; END est exige par le moteur C dans chaque fichier inclus ; xasm2026-4 l'admet.")
emit("\tend")

# --------------------------------------------------------------------------------
# Controle de ce qu'on vient d'ecrire : les deux bornes du moteur C, sur le fichier
# LIVRE. Un generateur qui promet une contrainte doit la verifier, pas l'esperer.
# --------------------------------------------------------------------------------
trop_long = [l for l in lines if len(l) > LIGNE_MAX + 3]
trop_large = [m.group(1) for l in lines
              if (m := re.match(r"^([A-Za-z_][A-Za-z_0-9]*):", l)) and len(m.group(1)) > LARGEUR_MAX]
if trop_long or trop_large:
    sys.exit("generate_pce500_inc: le fichier produit viole les bornes du moteur C"
             + (f" | {len(trop_long)} ligne(s) de plus de {LIGNE_MAX + 3} caracteres" if trop_long else "")
             + (f" | label(s) de plus de {LARGEUR_MAX} caracteres : {', '.join(trop_large)}" if trop_large else ""))

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
renommes = sorted(n for n, c in used.items() if n != c)
larg = max(len(x) for x in used)
print(f"ecrit : {OUT}  ({len(lines)} lignes, {len(used)} equ, label le plus long "
      f"{larg} car., {len(renommes)} nom(s) differents du nom documente)")
