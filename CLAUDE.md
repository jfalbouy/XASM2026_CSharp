# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

XASM2026-4 is a standalone C# (.NET 8) port of the XASM2026 cross-assembler for the
**SHARP PC-E500S** pocket computer's **SC62015** CPU. It replaces the original C engine
(preserved in `Reference/C/`) with native C#, while reproducing the historical command-line
interface, directives, and output formats **byte-for-byte**. The overriding constraint of
this project is bit-exact non-regression against the reference assembler `xasm2026-1`.

Documentation and code comments are in French; keep that convention when editing.

## Build & run

```powershell
# Build (produces src/bin/Release/net8.0/xasm2026-4.exe)
dotnet build .\src\Xasm2026.Native.csproj -c Release

# Assemble an example. Run from the source file's own directory so INCLUDEs resolve.
cd .\Exemples\VOGUE
..\..\bin\xasm2026-4.exe VOGUE.S -O vogue.obj -L vogue.lst -B vogue.uu
```

`bin/xasm2026-4.exe` (and `.dll`) is a hand-copied convenience build; the canonical output
of a build is under `src/bin/Release/net8.0/`. After a meaningful change, rebuild and copy
the fresh binary to `bin/` if you rely on it.

VS Code tasks (`.vscode/tasks.json`) wrap the common flows: `build xasm2026-4`,
`assembler VOGUE`, `assembler REGISTER`, and `coverage_all toutes options`.

## Command-line interface

First positional argument is the source file (`.asm` appended if no extension). Every output
type is opt-in via a flag; each flag can take an explicit filename or default to the source
basename with a new extension. Flags are parsed in `src/CommandLineOptions.cs`:

`-O` object, `-L` listing, `-I` Intel HEX, `-M` S-record (`.s19`), `-P` map, `-D` dependency,
`-B` BASIC uuencode (`.uu`, self-decodable), `-X` HxD-style text dump, `-T<type>` object type
(e.g. `-TZ`), `-E` error report (`.err`), `-S` symbol list, `-C` line count, `-W` warnings
(see below), `-H` disable hash, `-V` verbose errors, `-R` section size report, `-?` help.

### Warnings (`-W`)

The C reference (`mes.c`, `err_handle`) defines six non-fatal warnings among its error codes.
Four are ported, because the port has the state needed to detect them — the ORG/DS ones are
raised in `NativeAssembler`, the include-scope ones in `NativeAssembler.Preprocessor.cs`:

| Code | Message | Trigger |
| --- | --- | --- |
| 28 | `Warning: Location counter already set` | `ORG` after the origin was already fixed |
| 32 | `Warning: No effective code` | `DS 0` — reserves nothing |
| 33 | `Warning: LOCAL and ENDL not match in included file` | unbalanced `LOCAL`/`ENDL` in an INCLUDE |
| 38 | `Warning: PRE_PUSH and PRE_POP not match` | unbalanced `PRE_PUSH`/`PRE_POP` in an INCLUDE |

Codes 29 (`Used PRE while auto-prebyte is active`) and 34 (`INCLUDE argument isn't defined yet`)
are **not** ported: they need the `PRE` data directive and INCLUDE arguments respectively,
neither of which the port implements. Add them alongside those features, not before.

Semantics follow the C: warnings never make the assembly fatal (exit code stays 0) and are
**silent unless `-W`** — which is why they cannot affect the goldens, none of which were
produced with `-W`. Output goes to the console as `file<TAB>line<TAB>text`, and is appended to
the `.lst` and `.err` when those are enabled. Two deviations remain: the C interleaves each
warning at the offending listing line (we group them at the end of the listing), and the C adds
`col N` under `-V` (we track no parse column and print none rather than a fake value).

### Source positions

Every source line carries its physical origin through the whole pipeline via
`src/Assembly/SourceRef.cs` (`Text`, `File`, `Line`). The origin travels **on the line itself**
rather than in a parallel list, because MACRO bodies and REPEAT blocks are copied and replayed,
which destroys any positional correspondence. Consequences:

- Errors and warnings name the **real file** — an INCLUDE reports its own name and line, as
  `ligne N (file.asm): …`; the plain `ligne N: …` form is kept when the fault is in the main
  source, so the historical shape is preserved in the common case.
- Lines produced by a macro expansion are attributed to the **call site**, not the macro body:
  that is the line the user has to fix, and it matches the C, whose `current_file->lines` is the
  line being read when the macro is replayed.
- `Program.TryParseErrorLine` parses both forms and re-reads the faulty line from the file that
  actually contains it.

## Non-regression testing (the core workflow)

There is an xUnit harness in `tests/Xasm2026.Tests/` — run it with:

```powershell
dotnet test tests\Xasm2026.Tests\Xasm2026.Tests.csproj -c Release
```

`GoldenAssemblyTests` re-assembles SAMPLE5 / VOGUE / REGISTER / TMAP2020 in a temp dir
(calling `Program.Main` in-process — the main project exposes internals via
`InternalsVisibleTo("Xasm2026.Tests")`) and asserts that **all eight** outputs (`.obj`,
`.hex`, `.s19`, `.txt`, `.lst`, `.map`, `.d`, `.uu`) are **byte-identical** to the committed
goldens in `Exemples/`.

The presentation formats (`.lst`, `.map`, `.d`, `.uu`) embed the source and output filenames,
so they only reproduce if you replay the **exact historical invocation**: all-lowercase names
(`sample5.asm` → `sample5.lst`, …) plus `-S` (symbol table appended to the listing). The
lowercase source name only resolves to the real file (`SAMPLE5.ASM`) on a case-insensitive
filesystem — one more reason CI runs on windows-latest. The single non-deterministic field in
any output is the `' Submitted dd/mm/yyyy` line of the `.uu`, which the harness normalizes
before comparing. `BehaviorTests` covers the guard rails
(undefined-symbol detection, cyclic-include detection). `.github/workflows/ci.yml` runs build
+ test on push/PR (windows-latest, to avoid CRLF drift in the text formats).

Correctness beyond that is still verified by comparing generated output files against the
reference assembler, byte for byte. The priority examples live in
`Exemples/` — `SAMPLES/SAMPLE5.ASM`, `VOGUE/VOGUE.S`, `REGISTER/REGISTER.ASM`,
`TMAP/TMAP2020.asm` — with committed reference outputs (`.obj`, `.lst`, `.hex`, `.s19`,
`.map`, `.d`, `.uu`, `.txt`) beside them.

`tools/compare_with_xasm2026_1_1.ps1` runs both the reference and the candidate over a batch
of examples and diffs `.obj` and `.uu` (with `.uu` decode verification). Its paths are derived
from the script's own location, so it works in any checkout; examples listed but absent (the
TRDOS/UUCODE ones) are skipped with a warning. The reference exe (`xasm2026-1`) is **not** in
this repo — pass `-ReferenceXasm <path>` or set `XASM_REFERENCE_EXE`, otherwise the script
stops with an explicit message.

`tests/coverage_all.asm` (+ `coverage_all_include.asm`) exercises every directive/opcode form
and is the target of the "all options" VS Code task and launch config.

When changing the assembler, always re-run the affected example(s) and confirm the primary
machine outputs (`.hex`, `.s19`, `.obj`) stay identical to the committed references before
worrying about presentation formats. Presentation/packaging formats (`.lst`, `.map`, `.d`,
`.txt`, `.uu`) have their own exact-match expectations documented in `PORTAGE.md`.

## Architecture

Flow: `Program.Main` → `CommandLineOptions.Parse` → `NativeAssembler.Assemble` →
`Program.WriteOutputs` dispatches to each writer in `src/Outputs/`.

- **`NativeAssembler`** — the heart of the project, one `partial class` split across
  `src/Assembly/NativeAssembler*.cs` by concern: the core loop + directive/opcode dispatch and
  the `Emit*` encoders in `NativeAssembler.cs`; register/opcode lookup tables in
  `.Registers.cs`; INCLUDE resolution + macro expansion in `.Preprocessor.cs`; expression
  evaluation, relative-target resolution and symbol-name handling in `.Expressions.cs`; STRUCT,
  sections and result-copying in `.Sections.cs`. It runs a **two-pass** assemble
  (`RunPass(emit: false)` resolves symbols/addresses, then `RunPass(emit: true)` emits bytes).
  The many `Emit*` methods (`EmitMove`, `EmitMovePointer`, `EmitArithmetic`, `EmitRelativeJump`,
  …) each encode one instruction family. `_emitPass` gates emit-pass-only checks (an undefined
  symbol is only an error once addresses are final).
- **`src/Assembly/SourceLine.cs`** — parses one raw line into label / mnemonic / operand text.
- **`src/Expressions/ExpressionEvaluator.cs`** — numeric expression evaluation (`+ - * /`, etc.)
  over the symbol table.
- **`src/Core/`** — plain data carriers: `AssemblyResult` (generated bytes, symbols, sections,
  listing lines), `GeneratedByte`, `ListingLine`, `SectionInfo`.
- **`src/Outputs/`** — one writer per format: `ObjectWriter`, `ListingWriter`, `IntelHexWriter`,
  `SRecordWriter`, `MapWriter`, `DependencyWriter`, `BasicUuWriter`, `HxdDumpWriter`. `BasicUuWriter`
  reproduces `uuselfx.c` behavior (45-byte trailing buffer, historical checksum, final `size` line).

### Mapping to the original C sources

The port follows `Reference/C/` module by module; `PORTAGE.md` maps them: `xasm.c` (main loop),
`eval.c` (expressions), `opr.c`/`mvopr.c`/`genop.c` (operands & opcode encoding), `misc.c`
(listing & object emission), `modern.c` (2026 outputs/directives), `hash.c` (symbols/macros).
When an encoding is unclear or a byte diff appears, the C reference is the authority.

`PORTAGE.md` also holds a detailed dated journal of what has been ported and verified — read it
to understand current coverage and known-good vs. not-yet-ported instruction forms.

## Directives supported

`ORG`, `END`, `EQU`, `SECTION`, `STRUCT`/`ENDS`, `REPEAT`/`ENDR`, `IFEQ`/`IFNE`/`IFGT`/`IFLT`
(and other conditionals), `MACRO`, `INCLUDE`, `DB`/`DM`/`DW`/`DP`/`DS`. An INCLUDE'd file's
internal `END` must **not** terminate the whole assembly — this is an intentional, previously-fixed
behavior; preserve it.
