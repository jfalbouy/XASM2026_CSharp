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
