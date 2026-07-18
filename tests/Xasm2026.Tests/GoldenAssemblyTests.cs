using System.IO;
using System.Text.RegularExpressions;
using Xasm2026.Native;
using Xunit;

namespace Xasm2026.Tests;

// Les tests changent le repertoire courant et pilotent l'entree Program.Main
// (etat global console/CWD) : on desactive la parallelisation pour les serialiser.
[CollectionDefinition("assembler", DisableParallelization = true)]
public sealed class AssemblerCollection { }

/// <summary>
/// Non-regression octet-a-octet : reassemble chaque exemple de reference et compare
/// les huit sorties (obj/hex/s19/txt + lst/map/d/uu) aux golden files commits dans Exemples/.
///
/// Les formats de presentation (.lst/.map/.d/.uu) embarquent le nom du fichier source et
/// celui des sorties : ils ne sont reproductibles que si l'on rejoue **l'invocation
/// historique exacte** ayant produit les goldens, a savoir des noms entierement en
/// minuscules (`sample5.asm` -> `sample5.lst`, ...) et l'option `-S` (table des symboles
/// annexee au listing). Les noms minuscules ne resolvent le fichier source reel
/// (`SAMPLE5.ASM`) que sur un systeme insensible a la casse : c'est l'une des raisons
/// pour lesquelles la CI tourne sur windows-latest.
/// </summary>
[Collection("assembler")]
public sealed class GoldenAssemblyTests
{
    // Toutes les sorties sont desormais comparees octet a octet.
    private static readonly string[] AllExtensions =
        { "obj", "hex", "s19", "txt", "lst", "map", "d", "uu" };

    // Le writer BASIC uuencode date la ligne de soumission avec le jour courant :
    // seul champ non deterministe de l'ensemble des sorties, on le neutralise.
    private static readonly Regex UuSubmittedDate =
        new(@"' Submitted \d{2}/\d{2}/\d{4}", RegexOptions.Compiled);

    public static IEnumerable<object[]> Cases()
    {
        yield return new object[] { "SAMPLES", "sample5.asm", "sample5" };
        yield return new object[] { "VOGUE", "vogue.s", "vogue" };
        yield return new object[] { "REGISTER", "register.asm", "register" };
        yield return new object[] { "TMAP", "tmap2020.asm", "tmap2020" };
    }

    [Theory]
    [MemberData(nameof(Cases))]
    public void Reassembling_example_matches_golden_outputs(
        string exampleDir, string sourceFile, string stem)
    {
        var work = CopyExampleToTemp(exampleDir);
        try
        {
            var exit = RunAssembler(work, sourceFile, stem);
            Assert.Equal(0, exit);

            foreach (var ext in AllExtensions)
            {
                var golden = Path.Combine(TestPaths.ExamplesDir, exampleDir, $"{stem}.{ext}");
                var produced = Path.Combine(work, $"{stem}.{ext}");
                Assert.True(File.Exists(golden), $"Golden manquant : {golden}");
                Assert.True(File.Exists(produced), $"Sortie non produite : {produced}");

                if (ext == "uu")
                {
                    AssertUuEqual(golden, produced);
                }
                else
                {
                    AssertBytesEqual(golden, produced, ext);
                }
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
                "-O", $"{stem}.obj",
                "-L", $"{stem}.lst",
                "-I", $"{stem}.hex",
                "-M", $"{stem}.s19",
                "-P", $"{stem}.map",
                "-D", $"{stem}.d",
                "-B", $"{stem}.uu",
                "-X", $"{stem}.txt",
                "-S",
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

        // On assemble sous les memes noms que les goldens : on retire les copies de sorties
        // pour que le test echoue si un format n'est pas reellement regenere.
        foreach (var file in Directory.GetFiles(work))
        {
            var ext = Path.GetExtension(file).TrimStart('.');
            if (AllExtensions.Contains(ext, StringComparer.OrdinalIgnoreCase))
            {
                File.Delete(file);
            }
        }

        return work;
    }

    /// <summary>
    /// Compare deux sorties BASIC uuencode apres neutralisation de la date de soumission.
    /// </summary>
    private static void AssertUuEqual(string golden, string produced)
    {
        var expected = UuSubmittedDate.Replace(File.ReadAllText(golden), "' Submitted <DATE>");
        var actual = UuSubmittedDate.Replace(File.ReadAllText(produced), "' Submitted <DATE>");
        Assert.Equal(expected, actual);
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
