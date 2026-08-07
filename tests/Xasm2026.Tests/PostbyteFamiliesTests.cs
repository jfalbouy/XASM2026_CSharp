using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using Xasm2026.Native;
using Xasm2026.Native.Assembly;
using Xunit;

namespace Xasm2026.Tests;

/// <summary>
/// Jeu d'essai systematique des familles a post-octet (MV/MVW/MVP/MVL, indirection par
/// pointeur registre et memoire). Les octets attendus proviennent du moteur de reference
/// xasm2026-1-2, verifies contre la table de commandes du manuel ESR-L de Sharp (pp. 73-88)
/// et redecodes sans ecart par le desassembleur.
///
/// Chaque cas assemble une instruction isolee et compare l'objet emis, octet pour octet.
/// La note l'a etabli : le fichier entier assemble donne exactement la concatenation des
/// resultats ligne a ligne, donc aucune dependance au contexte — chaque ligne se teste seule.
/// Voir tests/postbyte_families.README.md.
/// </summary>
[Collection("assembler")]
public sealed class PostbyteFamiliesTests
{
    /// <summary>
    /// Lit postbyte_families.expected.txt : "instruction &lt;TAB&gt; octets" pour les formes
    /// valides, et "instruction &lt;TAB&gt; (refus attendu)" pour les deux formes que Sharp ne
    /// definit pas (MVL sur [r3] sans post-incrementation).
    /// </summary>
    public static IEnumerable<object[]> Cases()
    {
        var path = Path.Combine(TestPaths.TestsDir, "postbyte_families.expected.txt");
        foreach (var raw in File.ReadAllLines(path))
        {
            if (raw.Length == 0 || raw.StartsWith('#') || !raw.Contains('\t'))
            {
                continue;
            }

            var parts = raw.Split('\t', 2);
            yield return new object[] { parts[0].Trim(), parts[1].Trim() };
        }
    }

    [Theory]
    [MemberData(nameof(Cases))]
    public void Encodings_match_the_reference(string instruction, string expected)
    {
        RunInTempDir(() =>
        {
            File.WriteAllText("one.asm", $"\torg 0BE000h\n\t{instruction}\n\tend\n");
            var options = CommandLineOptions.Parse(new[] { "one.asm" });

            if (expected == "(refus attendu)")
            {
                // Forme non definie par Sharp : l'assemblage doit echouer, comme le moteur
                // de reference qui repond "Undefined instruction".
                Assert.NotNull(Record.Exception(() => new NativeAssembler(options).Assemble()));
                return;
            }

            var result = new NativeAssembler(options).Assemble();
            var got = string.Join(
                ' ',
                result.GeneratedBytes.Select(b => ((int)b.Value & 0xFF).ToString("x2", CultureInfo.InvariantCulture)));
            Assert.Equal(expected, got);
        });
    }

    private static void RunInTempDir(Action body)
    {
        var dir = Path.Combine(Path.GetTempPath(), "xasm_postbyte", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        var previous = Directory.GetCurrentDirectory();
        Directory.SetCurrentDirectory(dir);
        try
        {
            body();
        }
        finally
        {
            Directory.SetCurrentDirectory(previous);
            try { Directory.Delete(dir, recursive: true); } catch { /* best-effort */ }
        }
    }
}
