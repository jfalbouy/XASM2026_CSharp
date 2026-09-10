from pathlib import Path
import re

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.style import WD_STYLE_TYPE
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


# Le document source est le voisin de ce script (dossier Documentation/XASM2026-1/) :
# on le deduit de l'emplacement du script, sans chemin machine.
DOC_DIR = Path(__file__).resolve().parent.parent
SRC = DOC_DIR / "Documentation_XASM_PC-E500S.md"
OUT = DOC_DIR / "Documentation_XASM_PC-E500S.docx"

BLUE = RGBColor(0x2E, 0x74, 0xB5)
DARK = RGBColor(0x1F, 0x4D, 0x78)
MUTED = RGBColor(0x55, 0x55, 0x55)
FILL = "E8EEF5"
LIGHT = "F4F6F9"


def shade(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def border(cell, color="D0D7DE", size="4"):
    tc_pr = cell._tc.get_or_add_tcPr()
    borders = tc_pr.first_child_found_in("w:tcBorders")
    if borders is None:
        borders = OxmlElement("w:tcBorders")
        tc_pr.append(borders)
    for edge in ("top", "left", "bottom", "right"):
        element = borders.find(qn(f"w:{edge}"))
        if element is None:
            element = OxmlElement(f"w:{edge}")
            borders.append(element)
        element.set(qn("w:val"), "single")
        element.set(qn("w:sz"), size)
        element.set(qn("w:space"), "0")
        element.set(qn("w:color"), color)


def set_widths(table, widths):
    table.alignment = WD_TABLE_ALIGNMENT.LEFT
    table.autofit = False
    for row in table.rows:
        for idx, width in enumerate(widths[: len(row.cells)]):
            cell = row.cells[idx]
            cell.width = Inches(width)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            tc_pr = cell._tc.get_or_add_tcPr()
            tc_w = tc_pr.find(qn("w:tcW"))
            if tc_w is None:
                tc_w = OxmlElement("w:tcW")
                tc_pr.append(tc_w)
            tc_w.set(qn("w:w"), str(int(width * 1440)))
            tc_w.set(qn("w:type"), "dxa")


def keep_next(paragraph):
    p_pr = paragraph._p.get_or_add_pPr()
    if p_pr.find(qn("w:keepNext")) is None:
        p_pr.append(OxmlElement("w:keepNext"))


def setup_styles(doc):
    sec = doc.sections[0]
    sec.page_width = Inches(8.5)
    sec.page_height = Inches(11)
    sec.top_margin = Inches(1)
    sec.bottom_margin = Inches(1)
    sec.left_margin = Inches(1)
    sec.right_margin = Inches(1)
    sec.header_distance = Inches(0.492)
    sec.footer_distance = Inches(0.492)

    styles = doc.styles
    normal = styles["Normal"]
    normal.font.name = "Calibri"
    normal.font.size = Pt(11)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.25

    style_specs = [
        ("Title", 24, RGBColor(0x0B, 0x25, 0x45), 0, 8),
        ("Subtitle", 12, MUTED, 0, 12),
        ("Heading 1", 16, BLUE, 18, 10),
        ("Heading 2", 13, BLUE, 14, 7),
        ("Heading 3", 12, DARK, 10, 5),
    ]
    for name, size, color, before, after in style_specs:
        style = styles[name]
        style.font.name = "Calibri"
        style.font.size = Pt(size)
        style.font.color.rgb = color
        if name != "Subtitle":
            style.font.bold = True
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
        style.paragraph_format.line_spacing = 1.15

    code = styles.add_style("CodeBlock", WD_STYLE_TYPE.PARAGRAPH)
    code.font.name = "Consolas"
    code.font.size = Pt(8.5)
    code.paragraph_format.left_indent = Inches(0.18)
    code.paragraph_format.space_after = Pt(0)
    code.paragraph_format.line_spacing = 1.0

    quote = styles.add_style("NoteBox", WD_STYLE_TYPE.PARAGRAPH)
    quote.font.name = "Calibri"
    quote.font.size = Pt(10)
    quote.font.color.rgb = RGBColor(0x0B, 0x25, 0x45)
    quote.paragraph_format.left_indent = Inches(0.18)
    quote.paragraph_format.right_indent = Inches(0.18)
    quote.paragraph_format.space_before = Pt(4)
    quote.paragraph_format.space_after = Pt(8)
    quote.paragraph_format.line_spacing = 1.18


def add_text_with_code(paragraph, text):
    parts = re.split(r"(`[^`]+`)", text)
    for part in parts:
        if not part:
            continue
        run = paragraph.add_run(part[1:-1] if part.startswith("`") and part.endswith("`") else part)
        if part.startswith("`") and part.endswith("`"):
            run.font.name = "Consolas"
            run.font.size = Pt(9.5)
            run.font.color.rgb = DARK


def add_markdown_table(doc, lines):
    rows = []
    for line in lines:
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        rows.append(cells)
    headers = rows[0]
    data = rows[2:]
    table = doc.add_table(rows=1, cols=len(headers))
    table.style = "Table Grid"
    for i, h in enumerate(headers):
        table.rows[0].cells[i].text = h
        shade(table.rows[0].cells[i], FILL)
    for row in data:
        cells = table.add_row().cells
        for i, value in enumerate(row[: len(headers)]):
            cells[i].text = value
    for row in table.rows:
        for cell in row.cells:
            border(cell)
            for p in cell.paragraphs:
                p.paragraph_format.space_after = Pt(2)
                for run in p.runs:
                    run.font.name = "Calibri"
                    run.font.size = Pt(9.2)
    widths = [6.5 / len(headers)] * len(headers)
    if len(headers) == 2:
        widths = [1.65, 4.85]
    elif len(headers) == 3:
        widths = [1.45, 1.65, 3.4]
    set_widths(table, widths)


def add_note_table(doc, text):
    table = doc.add_table(rows=1, cols=1)
    table.style = "Table Grid"
    cell = table.cell(0, 0)
    shade(cell, LIGHT)
    border(cell, "B8C7D9", "6")
    p = cell.paragraphs[0]
    add_text_with_code(p, text)


def build():
    doc = Document()
    setup_styles(doc)
    sec = doc.sections[0]
    header = sec.header.paragraphs[0]
    header.text = "XASM 2026-1 - Documentation PC-E500S"
    header.style = doc.styles["Normal"]
    for run in header.runs:
        run.font.size = Pt(9)
        run.font.color.rgb = MUTED
    footer = sec.footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    footer.add_run("Documentation XASM / PC-E500S")

    lines = SRC.read_text(encoding="utf-8").splitlines()
    i = 0
    in_code = False
    first_title = True
    while i < len(lines):
        line = lines[i]
        if line.startswith("```"):
            in_code = not in_code
            i += 1
            continue
        if in_code:
            p = doc.add_paragraph(style="CodeBlock")
            p.add_run(line)
            i += 1
            continue
        if not line.strip():
            i += 1
            continue
        if line.startswith("|"):
            table_lines = []
            while i < len(lines) and lines[i].startswith("|"):
                table_lines.append(lines[i])
                i += 1
            add_markdown_table(doc, table_lines)
            continue
        if line.startswith("> "):
            add_note_table(doc, line[2:])
            i += 1
            continue
        if line.startswith("# "):
            text = line[2:].strip()
            if first_title:
                p = doc.add_paragraph(style="Title")
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                p.add_run(text)
                first_title = False
            else:
                p = doc.add_heading(text, level=1)
                keep_next(p)
            i += 1
            continue
        if line.startswith("## "):
            p = doc.add_heading(line[3:].strip(), level=2)
            keep_next(p)
            i += 1
            continue
        if line.startswith("### "):
            p = doc.add_heading(line[4:].strip(), level=3)
            keep_next(p)
            i += 1
            continue
        if line.startswith("- "):
            p = doc.add_paragraph(style="List Bullet")
            add_text_with_code(p, line[2:].strip())
            i += 1
            continue
        if re.match(r"^\d+\. ", line):
            p = doc.add_paragraph(style="List Number")
            add_text_with_code(p, re.sub(r"^\d+\. ", "", line).strip())
            i += 1
            continue
        if first_title is False and doc.paragraphs and doc.paragraphs[-1].style.name == "Title":
            p = doc.add_paragraph(style="Subtitle")
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            add_text_with_code(p, line.strip())
            i += 1
            continue
        p = doc.add_paragraph()
        add_text_with_code(p, line.strip())
        i += 1

    for p in doc.paragraphs:
        if p.style.name.startswith("Heading"):
            keep_next(p)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc.save(OUT)
    print(OUT)


if __name__ == "__main__":
    build()
