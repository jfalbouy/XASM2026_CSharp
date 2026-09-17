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
/// Jeu d'essai systematique de l'octet PRE : toutes les instructions a operande de RAM
/// interne, sous pre_on et pre_off, avec les modes d'adressage qui changent le PRE
/// ((n), BP+n, PX+n, PY+n, BP+PX, BP+PY). Les octets attendus proviennent du moteur C
/// xasm2026-1-2 (tools/gen_prebyte_families.py) ; une forme qu'il refuse doit l'etre aussi.
///
/// Un cas par mode plutot qu'un cas par ligne : 2520 lignes feraient autant de tests, et
/// le message d'echec liste de toute facon chaque divergence. Voir RAPPORT-BUG-octet-pre.md
/// et tests/prebyte_families.README.md.
/// </summary>
[Collection("assembler")]
public sealed class PrebyteFamiliesTests
{
    private const string Refused = "(refus attendu)";

    [Theory]
    [InlineData("pre_on")]
    [InlineData("pre_off")]
    public void Encodings_match_the_reference_engine(string mode)
    {
        var path = Path.Combine(TestPaths.TestsDir, "prebyte_families.expected.txt");
        var cases = File.ReadAllLines(path)
            .Where(l => l.Length > 0 && !l.StartsWith('#'))
            .Select(l => l.Split('\t'))
            .Where(p => p[0] == mode)
            .ToList();
        Assert.NotEmpty(cases);

        var divergences = new List<string>();
        RunInTempDir(() =>
        {
            foreach (var parts in cases)
            {
                var instruction = parts[1];
                var expected = parts[2];
                File.WriteAllText("one.asm", $"\torg 0BF000h\n\t{mode}\n\t{instruction}\n\tend\n");
                var options = CommandLineOptions.Parse(new[] { "one.asm" });

                string got;
                try
                {
                    var result = new NativeAssembler(options).Assemble();
                    got = string.Join(' ', result.GeneratedBytes.Select(
                        b => ((int)b.Value & 0xFF).ToString("x2", CultureInfo.InvariantCulture)));
                }
                catch (Exception)
                {
                    got = Refused;
                }

                if (got != expected)
                {
                    divergences.Add($"{instruction,-28} attendu {expected,-22} obtenu {got}");
                }
            }
        });

        Assert.True(divergences.Count == 0,
            $"{divergences.Count} divergence(s) sur {cases.Count} ({mode}) :\n" + string.Join('\n', divergences));
    }

    private static void RunInTempDir(Action body)
    {
        var dir = Path.Combine(Path.GetTempPath(), "xasm_prebyte", Guid.NewGuid().ToString("N"));
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
