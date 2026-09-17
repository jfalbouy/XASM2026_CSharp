using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Xasm2026.Native;
using Xasm2026.Native.Assembly;
using Xunit;

namespace Xasm2026.Tests;

/// <summary>
/// La table de relocation A62 produite par le prefixe 'rel' doit designer exactement les
/// octets ou l'adresse a ete ecrite, avec leur largeur. Aucun source d'epoque ne couvre ces
/// formes : l'oracle est la MESURE. La meme source est assemblee a deux origines dont l'ecart
/// (0BF000h - 0A1234h = 1DDCCh) change chaque octet d'un champ d'adresse sans retenue
/// ambigue ; les octets qui different sont les champs relogeables, et la table emise,
/// decodee independamment de l'encodeur, doit en etre la liste. Voir
/// RAPPORT-BUG-rel-champ-adresse.md.
/// </summary>
[Collection("assembler")]
public sealed class RelocationSitesTests
{
    // Les 27 formes du jeu SC62015 qui portent une adresse absolue mn ou lmn, plus DP et DW.
    private static readonly string[] AddressForms =
    [
        "jp cible", "call cible", "jpz cible", "jpnz cible", "jpc cible", "jpnc cible",
        "jpf cible", "callf cible",
        "mv x,v", "mv a,[v]", "mv [v],a",
        "mv (0D6H),[v]", "mvw (0D6H),[v]", "mvp (0D6H),[v]", "mvl (0D6H),[v]", "mvp (0D6H),v",
        "cmp [v],012H", "test [v],012H", "xor [v],012H", "and [v],012H", "or [v],012H",
        "mv [v],(0D6H)", "mvw [v],(0D6H)", "mvp [v],(0D6H)", "mvl [v],(0D6H)",
        "dp v", "dw v",
    ];

    [Fact]
    public void Rel_table_designates_the_bytes_that_move_with_the_origin()
    {
        RunInTempDir(() =>
        {
            var atA = Assemble(Source("0BF000H", withRel: true));
            var atB = Assemble(Source("0A1234H", withRel: true));
            var codeLength = Assemble(Source("0BF000H", withRel: false)).Count;
            Assert.Equal(atA.Count, atB.Count);

            // Champs mesures : suites d'octets consecutifs qui changent avec l'origine. Les
            // 'nop' intercales garantissent que deux champs voisins ne se touchent jamais.
            var measured = new List<(int Offset, int Width)>();
            for (var i = 0; i < codeLength; i++)
            {
                if (atA[i] == atB[i])
                {
                    continue;
                }

                var start = i;
                while (i < codeLength && atA[i] != atB[i])
                {
                    i++;
                }

                measured.Add((start, i - start));
            }

            Assert.Equal(AddressForms.Length, measured.Count);
            Assert.Equal(measured, DecodeKonTable(atA.Skip(codeLength).ToArray()));
            // La table ne depend pas de l'origine.
            Assert.Equal(atA.Skip(codeLength), atB.Skip(codeLength));
        });
    }

    /// <summary>
    /// 'rel' n'a de sens que devant une instruction portant exactement une adresse absolue.
    /// Accepte devant "mv a,05H", il produisait un ecart negatif encode FFh, le terminateur.
    /// </summary>
    [Theory]
    [InlineData("rel mv a,05H")]
    [InlineData("rel nop")]
    [InlineData("rel jr suite")]
    [InlineData("rel jp (00BH)")]
    [InlineData("rel db 1")]
    [InlineData("rel dw 1,2")]
    public void Rel_without_exactly_one_absolute_address_is_an_error(string line)
    {
        RunInTempDir(() =>
        {
            File.WriteAllText("r.asm", $"\torg 0BF000H\n\t{line}\nsuite:\tnop\n\tend\n");
            var options = CommandLineOptions.Parse(new[] { "r.asm" });
            var ex = Assert.Throws<InvalidOperationException>(() => new NativeAssembler(options).Assemble());
            Assert.Contains("rel :", ex.Message, StringComparison.Ordinal);
        });
    }

    private static string Source(string origin, bool withRel)
    {
        var body = string.Concat(AddressForms.Select(f => $"\t{(withRel ? "rel " : "")}{f}\n\tnop\n"));
        return $"\torg {origin}\n\tpre_on\n{body}cible:\tretf\nv:\tdb 0\n\tend\n";
    }

    private static List<byte> Assemble(string source)
    {
        File.WriteAllText("rel.asm", source);
        var options = CommandLineOptions.Parse(new[] { "rel.asm" });
        return new NativeAssembler(options).Assemble().GeneratedBytes.Select(b => b.Value).ToList();
    }

    /// <summary>
    /// Decode une table Kon : ecart depuis le site precedent (le premier depuis l'origine),
    /// bit 80h = largeur 3 (absent = 2), 7Eh = ecart long sur 2 octets LE, FFh = fin.
    /// Ecrit a part de l'encodeur de l'assembleur, pour ne pas s'auto-valider.
    /// </summary>
    private static List<(int Offset, int Width)> DecodeKonTable(byte[] table)
    {
        var sites = new List<(int Offset, int Width)>();
        var position = 0;
        var offset = 0;
        while (true)
        {
            var entry = table[position++];
            if (entry == 0xFF)
            {
                break;
            }

            var gap = entry & 0x7F;
            if (gap == 0x7E)
            {
                gap = table[position] | (table[position + 1] << 8);
                position += 2;
            }

            offset += gap;
            sites.Add((offset, (entry & 0x80) != 0 ? 3 : 2));
        }

        Assert.Equal(table.Length, position);
        return sites;
    }

    private static void RunInTempDir(Action body)
    {
        var dir = Path.Combine(Path.GetTempPath(), "xasm_rel", Guid.NewGuid().ToString("N"));
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
