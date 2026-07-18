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
