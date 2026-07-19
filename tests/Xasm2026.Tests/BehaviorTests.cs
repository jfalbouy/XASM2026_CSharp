using System.IO;
using Xasm2026.Native;
using Xasm2026.Native.Assembly;
using Xunit;

namespace Xasm2026.Tests;

/// <summary>
/// Tests de comportement des garde-fous ajoutes : detection des symboles indefinis (a)
/// et des inclusions cycliques (b). Chaque test ecrit une source minimale dans un dossier
/// temporaire, positionne le repertoire courant, puis assemble.
/// </summary>
[Collection("assembler")]
public sealed class BehaviorTests
{
    [Fact]
    public void Undefined_symbol_raises_error_in_emit_pass()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "bad.asm"),
                "        ORG 100H\n" +
                "        DB  UNDEFINED_LABEL\n" +
                "        END\n");

            var options = CommandLineOptions.Parse(new[] { "bad.asm" });
            var assembler = new NativeAssembler(options);

            var ex = Assert.Throws<InvalidOperationException>(() => assembler.Assemble());
            Assert.Contains("indefini", ex.Message, StringComparison.OrdinalIgnoreCase);
            Assert.Contains("UNDEFINED_LABEL", ex.Message, StringComparison.OrdinalIgnoreCase);
        });
    }

    [Fact]
    public void Defined_symbol_still_assembles()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "ok.asm"),
                "value:  EQU 42H\n" +
                "        ORG 100H\n" +
                "        DB  value\n" +
                "        END\n");

            var options = CommandLineOptions.Parse(new[] { "ok.asm" });
            var result = new NativeAssembler(options).Assemble();

            Assert.Single(result.GeneratedBytes);
            Assert.Equal(0x42, result.GeneratedBytes[0].Value);
        });
    }

    [Fact]
    public void Cyclic_include_raises_error()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "a.asm"), "        INCLUDE 'b.asm'\n        END\n");
            File.WriteAllText(Path.Combine(dir, "b.asm"), "        INCLUDE 'a.asm'\n        END\n");

            var options = CommandLineOptions.Parse(new[] { "a.asm" });
            var assembler = new NativeAssembler(options);

            var ex = Assert.Throws<InvalidOperationException>(() => assembler.Assemble());
            Assert.Contains("cyclique", ex.Message, StringComparison.OrdinalIgnoreCase);
        });
    }

    /// <summary>
    /// Les quatre avertissements portes depuis mes.c sont detectes, avec leur libelle
    /// historique, et n'empechent pas l'assemblage d'aboutir.
    /// </summary>
    [Fact]
    public void Warnings_are_detected_without_being_fatal()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "inc.asm"),
                "        LOCAL\n" +      // jamais referme par ENDL   -> warning 33
                "        PRE_PUSH\n" +   // jamais referme par PRE_POP -> warning 38
                "        DB  11H\n" +
                "        END\n");
            File.WriteAllText(Path.Combine(dir, "warn.asm"),
                "        ORG 0E000H\n" +
                "        INCLUDE 'inc.asm'\n" +
                "        DS  0\n" +      // reserve zero octet          -> warning 32
                "        ORG 0E100H\n" + // origine deja fixee          -> warning 28
                "        DB  22H\n" +
                "        END\n");

            var options = CommandLineOptions.Parse(new[] { "warn.asm" });
            var result = new NativeAssembler(options).Assemble();

            // L'assemblage aboutit : un avertissement n'est pas une erreur fatale.
            Assert.Equal(2, result.GeneratedBytes.Count);

            var messages = result.Warnings.Select(w => w.Message).ToList();
            Assert.Contains("Warning: LOCAL and ENDL not match in included file", messages);
            Assert.Contains("Warning: PRE_PUSH and PRE_POP not match", messages);
            Assert.Contains("Warning: No effective code", messages);
            Assert.Contains("Warning: Location counter already set", messages);

            // Les avertissements du fichier inclus lui sont rattaches, pas au source principal.
            Assert.All(
                result.Warnings.Where(w => w.Message.Contains("included file") || w.Message.Contains("PRE_PUSH")),
                w => Assert.Equal("inc.asm", w.File));
        });
    }

    /// <summary>
    /// Une source saine ne produit aucun avertissement : garde-fou contre les faux positifs,
    /// qui rendraient l'option -W inexploitable.
    /// </summary>
    [Fact]
    public void Clean_source_produces_no_warning()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "clean.asm"),
                "        ORG 0E000H\n" +
                "        DS  2\n" +
                "        DB  33H\n" +
                "        END\n");

            var options = CommandLineOptions.Parse(new[] { "clean.asm" });
            var result = new NativeAssembler(options).Assemble();

            Assert.Empty(result.Warnings);
        });
    }

    /// <summary>
    /// Une erreur situee dans un fichier inclus est rapportee avec le nom de ce fichier et
    /// son numero de ligne **physique**, et non la position dans le source developpe.
    /// </summary>
    [Fact]
    public void Error_in_included_file_reports_physical_file_and_line()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "lib.asm"),
                "; commentaire\n" +
                "        DB  01H\n" +
                "        DB  UNDEFINED_IN_INCLUDE\n" +   // ligne 3 de lib.asm
                "        END\n");
            File.WriteAllText(Path.Combine(dir, "main.asm"),
                "        ORG 0E000H\n" +
                "        INCLUDE 'lib.asm'\n" +
                "        END\n");

            var options = CommandLineOptions.Parse(new[] { "main.asm" });
            var ex = Assert.Throws<InvalidOperationException>(() => new NativeAssembler(options).Assemble());

            Assert.Contains("ligne 3 (lib.asm)", ex.Message, StringComparison.Ordinal);
        });
    }

    /// <summary>
    /// Une erreur provenant du corps d'une macro est rattachee au site d'appel : c'est la
    /// ligne que l'utilisateur doit corriger.
    /// </summary>
    [Fact]
    public void Error_from_macro_body_reports_call_site()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "mac.asm"),
                "        ORG 0E000H\n" +
                "        MACRO  bad,v\n" +
                "        DB     v\n" +
                "        DB     MISSING_SYM\n" +
                "        ENDM\n" +
                "        DB     01H\n" +
                "        bad    02H\n" +   // ligne 7 : site d'appel
                "        END\n");

            var options = CommandLineOptions.Parse(new[] { "mac.asm" });
            var ex = Assert.Throws<InvalidOperationException>(() => new NativeAssembler(options).Assemble());

            Assert.Contains("ligne 7", ex.Message, StringComparison.Ordinal);
        });
    }

    /// <summary>
    /// Les avertissements sont eux aussi situes sur la ligne physique : ici DS 0 et le second
    /// ORG sont en lignes 3 et 4 du source, alors qu'ils occupent les lignes 7 et 8 du source
    /// developpe (l'INCLUDE ayant insere quatre lignes).
    /// </summary>
    [Fact]
    public void Warnings_report_physical_line_numbers()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "inc.asm"),
                "        DB  11H\n" +
                "        DB  12H\n" +
                "        DB  13H\n" +
                "        END\n");
            File.WriteAllText(Path.Combine(dir, "w.asm"),
                "        ORG 0E000H\n" +
                "        INCLUDE 'inc.asm'\n" +
                "        DS  0\n" +       // ligne 3
                "        ORG 0E100H\n" +  // ligne 4
                "        DB  22H\n" +
                "        END\n");

            var options = CommandLineOptions.Parse(new[] { "w.asm" });
            var result = new NativeAssembler(options).Assemble();

            var noCode = Assert.Single(result.Warnings, w => w.Message.Contains("No effective code"));
            Assert.Equal("w.asm", noCode.File);
            Assert.Equal(3, noCode.Line);

            var orgSet = Assert.Single(result.Warnings, w => w.Message.Contains("Location counter already set"));
            Assert.Equal("w.asm", orgSet.File);
            Assert.Equal(4, orgSet.Line);
        });
    }

    /// <summary>
    /// Une option placee avant le nom du source est prise en compte : "xasm -?" affichait
    /// autrefois une erreur de fichier introuvable, le premier argument etant pris pour un source.
    /// </summary>
    [Fact]
    public void Leading_help_option_is_recognized()
    {
        var options = CommandLineOptions.Parse(new[] { "-?" });

        Assert.True(options.ShowHelp);
        Assert.Null(options.SourceFile);
    }

    /// <summary>
    /// Sous -W, chaque avertissement est intercale immediatement apres la ligne de listing
    /// fautive (comportement de err_handle) ; sans -W, le listing n'en porte aucune trace,
    /// ce qui garantit l'invariance des sorties de reference.
    /// </summary>
    [Fact]
    public void Listing_interleaves_warnings_only_under_W()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "l.asm"),
                "        ORG 0E000H\n" +
                "        DS  0\n" +      // ligne 2 : warning 32
                "        DB  22H\n" +
                "        END\n");

            Assert.Equal(0, Program.Main(new[] { "l.asm", "-O", "l.obj", "-L", "with.lst", "-W" }));
            Assert.Equal(0, Program.Main(new[] { "l.asm", "-O", "l.obj", "-L", "without.lst" }));

            var with = File.ReadAllLines(Path.Combine(dir, "with.lst"));
            var without = File.ReadAllText(Path.Combine(dir, "without.lst"));

            var offending = Array.FindIndex(with, l => l.Contains("DS  0", StringComparison.Ordinal));
            Assert.True(offending >= 0, "ligne fautive absente du listing");
            Assert.Contains("Warning: No effective code", with[offending + 1], StringComparison.Ordinal);

            Assert.DoesNotContain("Warning", without, StringComparison.Ordinal);
        });
    }

    /// <summary>
    /// La colonne rapportee sous -V designe le debut de l'operande fautif.
    /// </summary>
    [Fact]
    public void Warning_column_points_at_the_operand()
    {
        RunInTempDir(dir =>
        {
            //        123456789012345 -> l'operande "0" est en colonne 13
            File.WriteAllText(Path.Combine(dir, "col.asm"),
                "        ORG 0E000H\n" +
                "        DS  0\n" +
                "        DB  22H\n" +
                "        END\n");

            var options = CommandLineOptions.Parse(new[] { "col.asm" });
            var result = new NativeAssembler(options).Assemble();

            var warning = Assert.Single(result.Warnings);
            Assert.Equal(13, warning.Column);
            Assert.Equal("col.asm\t2\tcol 13\tWarning: No effective code", warning.Format(verbose: true));
            Assert.Equal("col.asm\t2\tWarning: No effective code", warning.Format(verbose: false));
        });
    }

    /// <summary>
    /// Les arguments d'INCLUDE sont referencables par @0..@9 dans le fichier inclus,
    /// et se combinent normalement dans une expression.
    /// </summary>
    [Fact]
    public void Include_arguments_are_referenced_by_at_digit()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "sub.asm"),
                "        DB  @0\n" +
                "        DB  @1\n" +
                "        DB  @0+@1\n" +
                "        END\n");
            File.WriteAllText(Path.Combine(dir, "main.asm"),
                "base:   EQU 10H\n" +
                "        ORG 0E000H\n" +
                "        INCLUDE 'sub.asm',base,3\n" +
                "        END\n");

            var options = CommandLineOptions.Parse(new[] { "main.asm" });
            var result = new NativeAssembler(options).Assemble();

            Assert.Equal(
                new[] { 0x10, 0x03, 0x13 },
                result.GeneratedBytes.Select(b => (int)b.Value).ToArray());
        });
    }

    /// <summary>
    /// Une reference @n au-dela des arguments recus est une erreur explicite (err 31 du C),
    /// situee dans le fichier inclus fautif.
    /// </summary>
    [Fact]
    public void Argument_beyond_the_supplied_count_is_an_error()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "sub.asm"), "        DB  @3\n        END\n");
            File.WriteAllText(Path.Combine(dir, "main.asm"),
                "        ORG 0E000H\n        INCLUDE 'sub.asm',1\n        END\n");

            var options = CommandLineOptions.Parse(new[] { "main.asm" });
            var ex = Assert.Throws<InvalidOperationException>(() => new NativeAssembler(options).Assemble());

            Assert.Contains("Bad argument number", ex.Message, StringComparison.Ordinal);
            Assert.Contains("sub.asm", ex.Message, StringComparison.Ordinal);
        });
    }

    /// <summary>
    /// La directive PRE emet un seul octet, et refuse une valeur hors des plages de
    /// prebytes legaux (21h-27h et 30h-37h, err 1 du C).
    /// </summary>
    [Fact]
    public void Pre_directive_emits_one_byte_and_validates_its_range()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "ok.asm"),
                "        ORG 0E000H\n        PRE 21H\n        PRE 37H\n        END\n");
            var okOptions = CommandLineOptions.Parse(new[] { "ok.asm" });
            var result = new NativeAssembler(okOptions).Assemble();
            Assert.Equal(new[] { 0x21, 0x37 }, result.GeneratedBytes.Select(b => (int)b.Value).ToArray());

            File.WriteAllText(Path.Combine(dir, "bad.asm"),
                "        ORG 0E000H\n        PRE 99H\n        END\n");
            var badOptions = CommandLineOptions.Parse(new[] { "bad.asm" });
            var ex = Assert.Throws<InvalidOperationException>(() => new NativeAssembler(badOptions).Assemble());
            Assert.Contains("Prebyte error", ex.Message, StringComparison.Ordinal);
        });
    }

    /// <summary>
    /// PRE employe alors que le prebyte automatique est actif declenche l'avertissement 29,
    /// que le portage de la directive rend enfin atteignable.
    /// </summary>
    [Fact]
    public void Pre_while_auto_prebyte_is_active_warns()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "p.asm"),
                "        ORG 0E000H\n" +
                "        PRE_ON\n" +
                "        PRE 21H\n" +
                "        END\n");

            var options = CommandLineOptions.Parse(new[] { "p.asm" });
            var result = new NativeAssembler(options).Assemble();

            Assert.Contains(
                result.Warnings,
                w => w.Message == "Warning: Used PRE while auto-prebyte is active");
        });
    }

    /// <summary>
    /// Avertissement 34 : un argument d'INCLUDE non resoluble. Il n'est observable que si
    /// l'argument n'est jamais utilise dans le fichier inclus ; sinon son emploi via @n
    /// provoque d'abord une erreur fatale de symbole indefini, plus utile.
    /// </summary>
    [Fact]
    public void Unresolvable_include_argument_warns_when_never_used()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "sub.asm"), "        DB  55H\n        END\n");
            File.WriteAllText(Path.Combine(dir, "main.asm"),
                "        ORG 0E000H\n        INCLUDE 'sub.asm',JAMAIS_DEFINI\n        END\n");

            var options = CommandLineOptions.Parse(new[] { "main.asm" });
            var result = new NativeAssembler(options).Assemble();

            Assert.Contains(
                result.Warnings,
                w => w.Message == "Warning: INCLUDE argument isn't defined yet");
        });
    }

    /// <summary>
    /// Une division ou un modulo par zero est une erreur fatale (err 2 de mes.c), et non
    /// un 0 silencieux : sans cela le binaire serait faux sans que rien ne le signale.
    /// </summary>
    [Theory]
    [InlineData("        DB  10/0\n")]
    [InlineData("        DB  10%0\n")]
    [InlineData("zero:   EQU 0\n        DB  10/zero\n")]
    public void Division_by_zero_is_fatal(string faulty)
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "d.asm"),
                "        ORG 0E000H\n" + faulty + "        END\n");

            var options = CommandLineOptions.Parse(new[] { "d.asm" });
            var ex = Assert.Throws<InvalidOperationException>(() => new NativeAssembler(options).Assemble());

            Assert.Contains("Division by zero", ex.Message, StringComparison.Ordinal);
        });
    }

    /// <summary>
    /// Le controle ne doit pas se declencher en passe de resolution : ici le diviseur est un
    /// label defini **plus loin**, donc encore inconnu (valeur 0) pendant la premiere passe.
    /// Un controle trop precoce rejetterait ce source pourtant valide.
    /// </summary>
    [Fact]
    public void Forward_reference_as_divisor_does_not_false_positive()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "f.asm"),
                "        ORG 0E000H\n" +
                "        DB  20H/taille\n" +   // taille n'est connu qu'apres
                "taille: EQU 4\n" +
                "        END\n");

            var options = CommandLineOptions.Parse(new[] { "f.asm" });
            var result = new NativeAssembler(options).Assemble();

            Assert.Equal(0x08, result.GeneratedBytes.Single().Value);
        });
    }

    /// <summary>
    /// Un diviseur symbolique jamais defini doit etre signale comme symbole indefini, et non
    /// comme division par zero : le vrai defaut est le symbole manquant.
    /// </summary>
    [Fact]
    public void Undefined_divisor_reports_the_symbol_not_the_division()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "u.asm"),
                "        ORG 0E000H\n        DB  10/INCONNU\n        END\n");

            var options = CommandLineOptions.Parse(new[] { "u.asm" });
            var ex = Assert.Throws<InvalidOperationException>(() => new NativeAssembler(options).Assemble());

            Assert.Contains("symbole indefini", ex.Message, StringComparison.Ordinal);
            Assert.DoesNotContain("Division by zero", ex.Message, StringComparison.Ordinal);
        });
    }

    /// <summary>
    /// Un LOCAL sans etiquette ouvre une portee anonyme au nom genere (genop.c case 66,
    /// pendant de no_name_lbl). C'est ce qui rend uniques les etiquettes du corps d'une
    /// macro expansee plusieurs fois.
    ///
    /// Regression : sans ce mecanisme, une **reference avant** vers une etiquette du corps
    /// resolvait vers l'expansion voisine, et les deux sauts se retrouvaient croises — un
    /// binaire faux emis silencieusement.
    /// </summary>
    [Fact]
    public void Bare_local_makes_macro_labels_unique_per_expansion()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "m.asm"),
                "        ORG 0E000H\n" +
                "        MACRO  saut_avant\n" +
                "        LOCAL\n" +
                "        JP     fin\n" +
                "        NOP\n" +
                "fin:    NOP\n" +
                "        ENDL\n" +
                "        ENDM\n" +
                "        saut_avant\n" +
                "        saut_avant\n" +
                "        END\n");

            var options = CommandLineOptions.Parse(new[] { "m.asm" });
            var result = new NativeAssembler(options).Assemble();

            // Chaque expansion saute vers SON propre "fin" : 00E004 puis 00E009.
            Assert.Equal(
                new[] { 0x02, 0x04, 0xE0, 0x00, 0x00, 0x02, 0x09, 0xE0, 0x00, 0x00 },
                result.GeneratedBytes.Select(b => (int)b.Value).ToArray());
        });
    }

    /// <summary>
    /// Les portees anonymes s'imbriquent : une reference depuis la portee externe ne doit pas
    /// etre captee par l'etiquette de meme nom definie dans la portee interne.
    /// </summary>
    [Fact]
    public void Anonymous_scopes_nest()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "n.asm"),
                "        ORG 0E000H\n" +
                "        LOCAL\n" +
                "        JP     cible\n" +
                "        LOCAL\n" +
                "cible:  NOP\n" +          // portee interne, en 00E003
                "        ENDL\n" +
                "cible:  NOP\n" +          // portee externe, en 00E004
                "        ENDL\n" +
                "        END\n");

            var options = CommandLineOptions.Parse(new[] { "n.asm" });
            var result = new NativeAssembler(options).Assemble();

            Assert.Equal(
                new[] { 0x02, 0x04, 0xE0, 0x00, 0x00 },
                result.GeneratedBytes.Select(b => (int)b.Value).ToArray());
        });
    }

    /// <summary>
    /// Les noms de portee anonyme doivent etre identiques entre les deux passes, sinon les
    /// adresses divergeraient. Le compteur repart donc a zero a chaque passe, comme
    /// no_name_lbl dans le C. Deux assemblages successifs doivent aussi coincider.
    /// </summary>
    [Fact]
    public void Anonymous_scope_numbering_is_stable_across_passes_and_runs()
    {
        RunInTempDir(dir =>
        {
            File.WriteAllText(Path.Combine(dir, "s.asm"),
                "        ORG 0E000H\n" +
                "        MACRO  bloc\n" +
                "        LOCAL\n" +
                "cible:  NOP\n" +
                "        JP     cible\n" +
                "        ENDL\n" +
                "        ENDM\n" +
                "        bloc\n        bloc\n        bloc\n" +
                "        END\n");

            var options = CommandLineOptions.Parse(new[] { "s.asm" });
            var first = new NativeAssembler(options).Assemble()
                .GeneratedBytes.Select(b => b.Value).ToArray();
            var second = new NativeAssembler(CommandLineOptions.Parse(new[] { "s.asm" })).Assemble()
                .GeneratedBytes.Select(b => b.Value).ToArray();

            Assert.Equal(first, second);

            // Chaque bloc fait 4 octets (NOP + JP) et saute sur sa propre etiquette.
            Assert.Equal(
                new[] { 0x00, 0x02, 0x00, 0xE0, 0x00, 0x02, 0x04, 0xE0, 0x00, 0x02, 0x08, 0xE0 },
                first.Select(b => (int)b).ToArray());
        });
    }

    private static void RunInTempDir(Action<string> body)
    {
        var dir = Path.Combine(Path.GetTempPath(), "xasm_behavior", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        var previous = Directory.GetCurrentDirectory();
        Directory.SetCurrentDirectory(dir);
        try
        {
            body(dir);
        }
        finally
        {
            Directory.SetCurrentDirectory(previous);
            try { Directory.Delete(dir, recursive: true); } catch { /* best-effort */ }
        }
    }
}
