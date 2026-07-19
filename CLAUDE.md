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

All six non-fatal warnings of the C reference (`mes.c`, `err_handle`) are ported. The
ORG/DS/PRE ones are raised in `NativeAssembler`, the include-scope ones in
`NativeAssembler.Preprocessor.cs`:

| Code | Message | Trigger |
| --- | --- | --- |
| 28 | `Warning: Location counter already set` | `ORG` after the origin was already fixed |
| 29 | `Warning: Used PRE while auto-prebyte is active` | `PRE` while `PRE_ON` is in effect |
| 32 | `Warning: No effective code` | `DS 0` — reserves nothing |
| 33 | `Warning: LOCAL and ENDL not match in included file` | unbalanced `LOCAL`/`ENDL` in an INCLUDE |
| 34 | `Warning: INCLUDE argument isn't defined yet` | unresolvable INCLUDE argument |
| 38 | `Warning: PRE_PUSH and PRE_POP not match` | unbalanced `PRE_PUSH`/`PRE_POP` in an INCLUDE |

Code 34 is implemented but rarely observable, and that is architectural rather than a bug:
the preprocessor evaluates every `EQU` before the passes, so a symbol defined *later* in the
source is already known — the C's order-dependent notion of "not defined *yet*" largely
evaporates. And when the symbol is defined nowhere, using it through `@n` raises a fatal
undefined-symbol error first, which is more useful. The warning therefore only surfaces when
the offending argument is never used inside the included file. Don't "fix" this by weakening
the fatal check.

Semantics follow the C: warnings never make the assembly fatal (exit code stays 0) and are
**silent unless `-W`** — which is why they cannot affect the goldens, none of which were
produced with `-W`. The rendering is `file<TAB>line<TAB>text`, or `file<TAB>line<TAB>col
N<TAB>text` under `-V` (`AssemblyWarning.Format` — one formatter for all three destinations,
mirroring the single `errtext` of `err_handle`). Warnings go to the console, to the `.err`, and
are **interleaved into the `.lst` right after the offending line**, which `ListingWriter` does
by matching `AssemblyWarning`'s origin against `ListingLine`'s — hence the `File`/`Line` fields
on `ListingLine`. Anything left unmatched is flushed at the end so it can never be silently
dropped.

The reported column is the 1-based start of the offending operand (or of the mnemonic when
there is no operand). It is deliberately *not* the C's `pp`, which is the parser's current
position at the time of the error: this is a stable, verifiable approximation, not a
reproduction.

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
  the `Emit*` encoders in `NativeAssembler.cs`; INCLUDE resolution + macro expansion in
  `.Preprocessor.cs`; expression evaluation and relative-target resolution in `.Expressions.cs`;
  STRUCT, sections and result-copying in `.Sections.cs`. It runs a **two-pass** assemble
  (`RunPass(emit: false)` resolves symbols/addresses, then `RunPass(emit: true)` emits bytes).
  The many `Emit*` methods (`EmitMove`, `EmitMovePointer`, `EmitArithmetic`, `EmitRelativeJump`,
  …) each encode one instruction family. `_emitPass` gates emit-pass-only checks (an undefined
  symbol is only an error once addresses are final).
- **`src/Assembly/SymbolTable.cs`** — symbol values, address occurrences, and the local-scope
  rules (`scope!label` prefixing, `..!` parent references). The subtlest part of the port, so it
  is a standalone type with its own unit tests (`SymbolTableTests`) rather than assembler state.
  Counterpart of `hash.c` plus the C's `l_stack`.
- **`src/Assembly/RegisterTable.cs`** — stateless SC62015 register/opcode lookup tables.
  Imported by the assembler with `using static`, so call sites stay unqualified.
- **`src/Assembly/SourceRef.cs`** — a source line plus its physical origin and the INCLUDE
  argument expressions in scope for it (see *Source positions* above).
- **`src/Assembly/SourceLine.cs`** — parses one raw line into label / mnemonic / operand text.
- **`src/Expressions/ExpressionEvaluator.cs`** — numeric expression evaluation (`+ - * /`,
  parentheses) over the symbol table. Two rules come straight from `eval.c` and are easy to
  break: the **trailing character sets the radix** (`B`=2, `O`=8, `D`=10, `H`=16, none=10, `_`
  ignored, and a number must start with a digit or `$`), and **`*` in term position is the
  location counter** while `*` between two values stays multiplication — the port distinguishes
  them by parser position, which is the equivalent of the C's `set_x` flag. The location counter
  is passed in per evaluation, mirroring the C reading its global `lc` at eval time.
  Division/modulo by zero is **not** thrown by the evaluator: it returns 0 and raises the
  `DividedByZero` flag, and `NativeAssembler.Eval` turns that into the C's fatal err 2 —
  but only on the emit pass, because a symbolic divisor is still 0 while addresses are
  being resolved. The undefined-symbol check runs first, so an unknown divisor is
  reported as the missing symbol rather than as a division by zero.
- **`src/Core/`** — plain data carriers: `AssemblyResult` (generated bytes, symbols, sections,
  listing lines, warnings), `GeneratedByte`, `ListingLine`, `SectionInfo`, `AssemblyWarning`.

The directive/opcode dispatch is a ~96-case `switch` on the mnemonic, deliberately **not**
turned into a lookup table. C# already compiles a string switch to a hash-based jump, so a
table would buy no speed and no clarity, while rewriting all 96 arms is exactly the kind of
change this project's byte-exactness constraint makes expensive to trust. The genuinely
table-shaped data — register and opcode encodings — is what `RegisterTable` holds.
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

Historical set: `ORG`, `END`, `EQU`, `SECTION`, `STRUCT`/`ENDS`, `REPEAT`/`ENDR`,
`IFEQ`/`IFNE`/`IFGT`/`IFLT` (and other conditionals), `MACRO`, `INCLUDE`,
`DB`/`DM`/`DW`/`DP`/`DS`, `PRE`. An INCLUDE'd file's internal `END` must **not** terminate the
whole assembly — this is an intentional, previously-fixed behavior; preserve it.

Added beyond the C reference — all purely additive, so a source that doesn't use them emits
identical bytes and the goldens are unaffected by construction:

| Directive | Note |
| --- | --- |
| `SET` / `=` | Redefinable symbol. Evaluated **in source order** by the preprocessor, which is what lets a counter advance across `REPEAT` iterations |
| `IRP` / `IRPC` | Repeat over a value list / over characters. Share `ENDR` with `REPEAT`, hence the depth-counting `CollectBlock` — before it, `REPEAT` itself could not nest |
| `ALIGN` / `EVEN` | **Emits** the padding; the image is contiguous, so merely bumping the counter would desynchronise object and addresses |
| `DZ` | String plus NUL. Escape sequences in `DM` are deliberately *not* added: they would silently reinterpret backslashes in existing sources |
| `ASSERT` / `ERROR` / `WARNING` | `ASSERT` is checked on the emit pass only — a forward reference is still 0 during resolution and would fail spuriously |
| `TITLE` / `LIST` / `NOLIST` / `PAGE` | Listing layout only; `NOLIST` never changes emitted bytes |
| `PHASE` / `DEPHASE` | Labels take the logical address while bytes stay at their physical place, via `_phaseOffset` subtracted in `Emit` |

**Duplicate labels** are rejected (the C's err 13, `xasm.c`). The check runs on the
**resolution pass only** — mirroring the C's `if (pass_sw == 1)` — because the emit pass
legitimately redefines every label. It is scope-aware, so the same name in two `LOCAL`
blocks is fine; what it catches is a labelled MACRO expanded twice without `LOCAL`, which
used to emit wrong addresses in silence. `EQU` is exempt because the preprocessor
pre-evaluates it before the passes, and `SET` is redefinable by design.

New expression operators (`^ ~ << >> = <> < > <= >=`, and `LOW`/`MID`/`HIGH`) are documented
in the evaluator section below.

`LOCAL` opens a local scope. **Without a label it opens an *anonymous* scope** whose name is
generated as `n%05X` from a per-pass counter (`genop.c` case 66, the C's `no_name_lbl`), and
registered as an ordinary symbol at the current LC. This is what makes labels inside a MACRO
body unique across expansions — each expansion enters its own scope. The counter **must** be
reset at the start of every pass, otherwise the two passes would mint different scope names
and addresses would diverge. Note the C never raises its err 20 ("No label before LOCAL"):
a bare `LOCAL` is legitimate, and this was a porting omission, not a missing feature — before
the fix, a forward reference inside a twice-expanded macro silently bound to the neighbouring
expansion.

`INCLUDE file[,arg0,…,arg9]` passes arguments, referenced as `@0`…`@9` inside the included
file. Because includes are flattened *before* any pass, the symbol table is not yet populated
when they are read, so `SourceRef.Args` carries the argument **expressions as text** and the
substitution happens at evaluation time (`SubstituteArguments`, parenthesized to preserve
precedence). A parent file's own `@n` are substituted into the arguments before they are handed
down, so nested `@n` still resolve against the right scope.

`PRE value` emits a single explicit prebyte (`genop.c` case 70 uses the data-directive family
with `offset = 1`). The value must be a legal prebyte — `21h`–`27h` or `30h`–`37h` — otherwise
it is a fatal error, and using `PRE` while `PRE_ON` is in effect raises warning 29.
