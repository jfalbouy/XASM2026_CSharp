using System.IO;
using Xasm2026.Native;
using Xasm2026.Native.Assembly;
using Xunit;

namespace Xasm2026.Tests;

/// <summary>
/// Les exemples SAMPLE6 a SAMPLE9 illustrent les fonctionnalites ajoutees en 2026-4.
/// Ils ne font **pas** partie des goldens : ces directives n'existant pas dans le moteur C,
/// ils ne s'assemblent pas avec xasm2026-1 et ne peuvent donc pas etre compares a lui.
/// On verrouille ici les octets qu'ils produisent, ce qui protege les nouvelles
/// fonctionnalites d'une regression.
/// </summary>
[Collection("assembler")]
public sealed class SampleAssemblyTests
{
    [Theory]
    [InlineData("SAMPLE6.ASM", 29)]
    [InlineData("SAMPLE7.ASM", 20)]
    [InlineData("SAMPLE8.ASM", 31)]
    [InlineData("SAMPLE9.ASM", 29)]
    public void Feature_samples_assemble_to_a_stable_size(string sourceFile, int expectedBytes)
    {
        var result = AssembleSample(sourceFile);

        Assert.Equal(expectedBytes, result.GeneratedBytes.Count);
    }

    /// <summary>
    /// SAMPLE6 : compteur SET dans un REPEAT, table de carres, IRP, IRPC, imbrication.
    /// </summary>
    [Fact]
    public void Sample6_generates_the_expected_tables()
    {
        var bytes = AssembleSample("SAMPLE6.ASM").GeneratedBytes.Select(b => (int)b.Value).ToArray();

        Assert.Equal(new[] { 0, 1, 2, 3, 4, 5, 6, 7 }, bytes[..8]);                   // compteur SET
        Assert.Equal(new[] { 0x00, 0x01, 0x04, 0x09, 0x10, 0x19 }, bytes[8..14]);     // carres
        Assert.Equal(new[] { 0xAA, 0xBB, 0xCC }, bytes[14..17]);                      // IRP
        Assert.Equal(new[] { 0x50, 0x43, 0x45, 0x35, 0x30, 0x30 }, bytes[17..23]);    // IRPC "PCE500"
        Assert.Equal(new[] { 0x10, 0x10, 0x10, 0x20, 0x20, 0x20 }, bytes[23..]);      // IRP + REPEAT
    }

    /// <summary>
    /// SAMPLE7 : les deux expansions de la macro sautent chacune sur leur propre etiquette,
    /// grace a la portee anonyme ouverte par un LOCAL nu. Les deux sauts relatifs doivent
    /// donc porter le meme deplacement.
    /// </summary>
    [Fact]
    public void Sample7_macro_labels_do_not_collide()
    {
        var bytes = AssembleSample("SAMPLE7.ASM").GeneratedBytes.Select(b => (int)b.Value).ToArray();

        // Deux boucles identiques : MV A,n / DEC A / JRNZ -4, puis EXITM et imbrication.
        Assert.Equal(bytes[2..6], bytes[8..12]);

        // Section GARDE : "entete 0" sort avant le second octet, "entete 1" le produit.
        Assert.Equal(new[] { 0xAA, 0xAA, 0xBB }, bytes[12..15]);

        // Section IMBRIQUE : macro appelee depuis une macro, avec REPEAT interne.
        Assert.Equal(new[] { 0x11, 0x22, 0x22, 0x22, 0x33 }, bytes[15..]);
    }

    /// <summary>
    /// SAMPLE9 : PHASE donne a l'etiquette son adresse d'execution tout en laissant les
    /// octets a leur place physique dans l'image.
    /// </summary>
    [Fact]
    public void Sample9_phase_relocates_labels_only()
    {
        var result = AssembleSample("SAMPLE9.ASM");
        var bytes = result.GeneratedBytes.Select(b => (int)b.Value).ToArray();

        // Decoupage : 7 octets d'alignement, 8 pour 'PC-E500S', 3 pour DZ 'OK',
        // 2 prebytes, 1 NOP, puis les 3 octets de "dp routine".
        // routine vaut 0B0000h, emis en petit-boutiste.
        Assert.Equal(new[] { 0x00, 0x00, 0x0B }, bytes[21..24]);

        // L'image reste contigue depuis l'ORG physique.
        Assert.Equal(0xE000, result.GeneratedBytes[0].Address);
        Assert.Equal(0xE01C, result.GeneratedBytes[^1].Address);

        // La directive WARNING remonte bien un avertissement non fatal.
        Assert.Contains(result.Warnings, w => w.Message.Contains("experimental"));
    }

    private static Xasm2026.Native.Core.AssemblyResult AssembleSample(string sourceFile)
    {
        var samples = Path.Combine(TestPaths.ExamplesDir, "SAMPLES");
        var work = Path.Combine(Path.GetTempPath(), "xasm_samples", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(work);
        File.Copy(Path.Combine(samples, sourceFile), Path.Combine(work, sourceFile));

        var previous = Directory.GetCurrentDirectory();
        Directory.SetCurrentDirectory(work);
        try
        {
            var options = CommandLineOptions.Parse(new[] { sourceFile });
            return new NativeAssembler(options).Assemble();
        }
        finally
        {
            Directory.SetCurrentDirectory(previous);
            try { Directory.Delete(work, recursive: true); } catch { /* best-effort */ }
        }
    }
}
