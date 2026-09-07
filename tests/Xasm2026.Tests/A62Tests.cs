using System.IO;
using System.Linq;
using Xasm2026.Native;
using Xasm2026.Native.Assembly;
using Xasm2026.Native.Outputs;
using Xunit;

namespace Xasm2026.Tests;

/// <summary>
/// Reproduction du preprocesseur A62 (dialecte Kon) : prefixe `rel` + generation de la table de
/// relocation, macros `#defmacro`/`#endmacro` (parametres `%0..%9`), conditionnelles
/// `#if`/`#else`/`#endif`. Le test de bout en bout assemble la source A62 d'origine de PLINKC et
/// verifie l'egalite octet-a-octet avec l'objet historique `PLINKC.OBJ`.
/// </summary>
[Collection("assembler")]
public sealed class A62Tests
{
    [Fact]
    public void DefMacro_expands_with_positional_parameters_and_feeds_rel()
    {
        // #defmacro bsr / rel call %0 / #endmacro : 'bsr 1234h' -> 'rel call 1234h'.
        // Emet 04 34 12 (call proche) puis la table 01 FF (site @ offset 1, largeur 2, delta 1).
        var bytes = AssembleToBytes(
            "#defmacro bsr\n" +
            "        rel call %0\n" +
            "#endmacro\n" +
            "        ORG 0BF000H\n" +
            "        bsr 1234H\n" +
            "        END\n");
        Assert.Equal(new[] { 0x04, 0x34, 0x12, 0x01, 0xFF }, bytes);
    }

    [Fact]
    public void Sharp_if_selects_blocks_on_equality_and_truthiness()
    {
        // media_type=2 : '#if ==0' faux -> #else (22) ; '#if sym' vrai (AA) ; '#if !=0' vrai (33).
        var bytes = AssembleToBytes(
            "media_type: SET 2\n" +
            "exchange:   SET 1\n" +
            "        ORG 0\n" +
            "#if media_type == 0\n" +
            "        DB 011H\n" +
            "#else\n" +
            "        DB 022H\n" +
            "#endif\n" +
            "#if exchange\n" +
            "        DB 0AAH\n" +
            "#endif\n" +
            "#if media_type != 0\n" +
            "        DB 033H\n" +
            "#endif\n" +
            "        END\n");
        Assert.Equal(new[] { 0x22, 0xAA, 0x33 }, bytes);
    }

    [Fact]
    public void Original_A62_PLINKC_source_reassembles_byte_identical_to_PLINKC_OBJ()
    {
        var dir = Path.Combine(TestPaths.ExamplesDir, "PLINKC", "A62");
        var previous = Directory.GetCurrentDirectory();
        Directory.SetCurrentDirectory(dir);
        try
        {
            var options = CommandLineOptions.Parse(new[] { "plinkc.a62.asm" });
            var result = new NativeAssembler(options).Assemble();
            var got = ObjectWriter.BuildObjectBytes(result, options.ObjectType);
            var expected = File.ReadAllBytes(Path.Combine(TestPaths.ExamplesDir, "PLINKC", "PLINKC.OBJ"));
            Assert.Equal(expected, got);
        }
        finally
        {
            Directory.SetCurrentDirectory(previous);
        }
    }

    private static int[] AssembleToBytes(string source)
    {
        var dir = Path.Combine(Path.GetTempPath(), "xasm_a62", System.Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        var previous = Directory.GetCurrentDirectory();
        Directory.SetCurrentDirectory(dir);
        try
        {
            File.WriteAllText(Path.Combine(dir, "a62.asm"), source);
            var options = CommandLineOptions.Parse(new[] { "a62.asm" });
            return new NativeAssembler(options).Assemble()
                .GeneratedBytes.Select(b => (int)b.Value & 0xFF).ToArray();
        }
        finally
        {
            Directory.SetCurrentDirectory(previous);
            Directory.Delete(dir, recursive: true);
        }
    }
}
