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
