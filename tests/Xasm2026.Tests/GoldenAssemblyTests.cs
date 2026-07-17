using System.IO;
using Xasm2026.Native;
using Xunit;

namespace Xasm2026.Tests;

// Les tests changent le repertoire courant et pilotent l'entree Program.Main
// (etat global console/CWD) : on desactive la parallelisation pour les serialiser.
[CollectionDefinition("assembler", DisableParallelization = true)]
public sealed class AssemblerCollection { }

/// <summary>
/// Non-regression octet-a-octet : reassemble chaque exemple de reference et compare
/// les sorties machine (obj/hex/s19/txt) aux golden files commits dans Exemples/.
/// Ces formats sont independants du nom de fichier de sortie, donc reproductibles.
/// </summary>
[Collection("assembler")]
public sealed class GoldenAssemblyTests
{
    // Formats machine deterministes et independants du nom de sortie : compares octet a octet.
    private static readonly string[] MachineExtensions = { "obj", "hex", "s19", "txt" };

    // Formats de presentation : ils embarquent le nom de fichier de sortie et ont
    // derive dans le depot ; on verifie seulement qu'ils sont produits et non vides.
    private static readonly string[] PresentationExtensions = { "lst", "map", "d", "uu" };

    public static IEnumerable<object[]> Cases()
    {
        yield return new object[] { "SAMPLES", "SAMPLE5.ASM", "sample5" };
        yield return new object[] { "VOGUE", "VOGUE.S", "vogue" };
        yield return new object[] { "REGISTER", "REGISTER.ASM", "register" };
        yield return new object[] { "TMAP", "TMAP2020.asm", "tmap2020" };
    }

    [Theory]
    [MemberData(nameof(Cases))]
    public void Reassembling_example_matches_golden_machine_outputs(
        string exampleDir, string sourceFile, string goldStem)
    {
        var work = CopyExampleToTemp(exampleDir);
        try
        {
            var stem = Path.GetFileNameWithoutExtension(sourceFile);
            var exit = RunAssembler(work, sourceFile, stem);
            Assert.Equal(0, exit);

            foreach (var ext in MachineExtensions)
            {
                var golden = Path.Combine(TestPaths.ExamplesDir, exampleDir, $"{goldStem}.{ext}");
                var produced = Path.Combine(work, $"{stem}.out.{ext}");
                Assert.True(File.Exists(golden), $"Golden manquant : {golden}");
                Assert.True(File.Exists(produced), $"Sortie non produite : {produced}");
                AssertBytesEqual(golden, produced, ext);
            }

            foreach (var ext in PresentationExtensions)
            {
                var produced = Path.Combine(work, $"{stem}.out.{ext}");
                Assert.True(File.Exists(produced), $"Sortie non produite : {produced}");
                Assert.True(new FileInfo(produced).Length > 0, $"Sortie vide : {produced}");
            }
        }
        finally
        {
            TryDelete(work);
        }
    }

    private static int RunAssembler(string work, string sourceFile, string stem)
    {
        var previous = Directory.GetCurrentDirectory();
        Directory.SetCurrentDirectory(work);
        try
        {
            return Program.Main(new[]
            {
                sourceFile,
                "-O", $"{stem}.out.obj",
                "-L", $"{stem}.out.lst",
                "-I", $"{stem}.out.hex",
                "-M", $"{stem}.out.s19",
                "-P", $"{stem}.out.map",
                "-D", $"{stem}.out.d",
                "-B", $"{stem}.out.uu",
                "-X", $"{stem}.out.txt",
            });
        }
        finally
        {
            Directory.SetCurrentDirectory(previous);
        }
    }

    private static string CopyExampleToTemp(string exampleDir)
    {
        var source = Path.Combine(TestPaths.ExamplesDir, exampleDir);
        var work = Path.Combine(Path.GetTempPath(), "xasm_tests", $"{exampleDir}_{Guid.NewGuid():N}");
        Directory.CreateDirectory(work);
        foreach (var file in Directory.GetFiles(source))
        {
            File.Copy(file, Path.Combine(work, Path.GetFileName(file)), overwrite: true);
        }

        return work;
    }

    private static void AssertBytesEqual(string golden, string produced, string ext)
    {
        var expected = File.ReadAllBytes(golden);
        var actual = File.ReadAllBytes(produced);
        Assert.True(
            expected.Length == actual.Length,
            $".{ext} : taille {actual.Length} attendue {expected.Length}");

        for (var i = 0; i < expected.Length; i++)
        {
            if (expected[i] != actual[i])
            {
                Assert.Fail(
                    $".{ext} : premier ecart offset {i} (0x{i:X}) " +
                    $"golden=0x{expected[i]:X2} produit=0x{actual[i]:X2}");
            }
        }
    }

    private static void TryDelete(string path)
    {
        try { Directory.Delete(path, recursive: true); }
        catch { /* nettoyage best-effort */ }
    }
}
