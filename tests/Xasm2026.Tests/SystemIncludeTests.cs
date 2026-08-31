using System.IO;
using System.Linq;
using Xasm2026.Native;
using Xasm2026.Native.Assembly;
using Xasm2026.Native.Outputs;
using Xunit;

namespace Xasm2026.Tests;

/// <summary>
/// Verifie que l'include de constantes systeme Exemples/INCLUDE/pce500.inc s'assemble et que
/// ses symboles se resolvent aux bonnes valeurs. example.asm sert a la fois de documentation
/// d'usage et de cible de test. Les octets attendus ont ete controles a la main :
///   fcs_open_file=01h, fcs_call=0FFFE4h, cl=0D6h, dev_display=0, display_char_out_at=41h,
///   iocs_call=0FFFE8h, pushu imr, imr=0FBh, s1_top=0BFC15h, baswrk=0BFD0Eh, ssr=0FFh.
/// </summary>
[Collection("assembler")]
public sealed class SystemIncludeTests
{
    [Fact]
    public void Example_using_pce500_inc_assembles_to_the_expected_bytes()
    {
        var dir = Path.Combine(TestPaths.ExamplesDir, "INCLUDE");
        var previous = Directory.GetCurrentDirectory();
        Directory.SetCurrentDirectory(dir);
        try
        {
            var options = CommandLineOptions.Parse(new[] { "example.asm" });
            var result = new NativeAssembler(options).Assemble();
            var got = result.GeneratedBytes.Select(b => (int)b.Value & 0xFF).ToArray();

            Assert.Equal(
                new[]
                {
                    0x09, 0x01,                   // mv il,fcs_open_file
                    0x05, 0xE4, 0xFF, 0x0F,       // callf fcs_call
                    0xCC, 0xD6, 0x00,             // mv (cl),dev_display
                    0x09, 0x41,                   // mv il,display_char_out_at
                    0x05, 0xE8, 0xFF, 0x0F,       // callf iocs_call
                    0x2F,                         // pushu imr
                    0xCC, 0xFB, 0xA0,             // mv (imr),0A0h
                    0x8C, 0x15, 0xFC, 0x0B,       // mv x,[s1_top]
                    0x8D, 0x0E, 0xFD, 0x0B,       // mv y,[baswrk]
                    0x65, 0xFF, 0x08,             // test (ssr),8
                },
                got);
        }
        finally
        {
            Directory.SetCurrentDirectory(previous);
        }
    }

    /// <summary>
    /// -K : le listing ne conserve d'un fichier INCLUDE que les constantes EQU effectivement
    /// utilisees. Une constante inutilisee (txtbas) disparait, une utilisee (s1_top) reste, et
    /// la source principale est intacte. Sans -K, tout l'include est present : c'est ce qui
    /// garantit que l'option est purement additive et que les goldens restent identiques.
    /// </summary>
    [Fact]
    public void Dash_K_keeps_only_used_include_constants_in_the_listing()
    {
        var dir = Path.Combine(TestPaths.ExamplesDir, "INCLUDE");
        var previous = Directory.GetCurrentDirectory();
        Directory.SetCurrentDirectory(dir);
        var lst = Path.Combine(Path.GetTempPath(), $"example_K_{System.Guid.NewGuid():N}.lst");
        try
        {
            // Sans -K : txtbas (inutilisee) est bien presente.
            var full = CommandLineOptions.Parse(new[] { "example.asm" });
            var resultFull = new NativeAssembler(full).Assemble();
            ListingWriter.Write(lst, full, resultFull);
            Assert.Contains("txtbas:", File.ReadAllText(lst));

            // Avec -K : txtbas disparait, s1_top (utilisee) reste, la source principale est la.
            var trimmed = CommandLineOptions.Parse(new[] { "example.asm", "-K" });
            var resultTrimmed = new NativeAssembler(trimmed).Assemble();
            ListingWriter.Write(lst, trimmed, resultTrimmed);
            var text = File.ReadAllText(lst);
            Assert.DoesNotContain("txtbas:", text);
            Assert.Contains("s1_top:", text);
            Assert.Contains("montre l'usage de pce500.inc", text);
        }
        finally
        {
            if (File.Exists(lst)) File.Delete(lst);
            Directory.SetCurrentDirectory(previous);
        }
    }
}
