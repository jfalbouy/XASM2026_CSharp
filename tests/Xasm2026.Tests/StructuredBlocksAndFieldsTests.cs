using System;
using System.IO;
using System.Linq;
using Xasm2026.Native;
using Xasm2026.Native.Assembly;
using Xunit;

namespace Xasm2026.Tests;

/// <summary>
/// Deux fonctionnalites ajoutees pour porter les drivers du dialecte A62 (PLINKC) :
///   - les blocs structures { } avec les cibles reservees continue (debut du bloc) et
///     break (juste apres la fin) ;
///   - le couple SUBORG / byte-word-pntr, qui nomme des champs a offsets successifs dans
///     un compteur secondaire, plus l'operande "%" qui rend ce compteur.
/// Purement additives : aucune source du corpus ne les emploie, les goldens sont donc
/// inchanges par construction.
/// </summary>
[Collection("assembler")]
public sealed class StructuredBlocksAndFieldsTests
{
    private static int[] Assemble(string source)
    {
        return RunInTempDir(() =>
        {
            File.WriteAllText("t.asm", source);
            var options = CommandLineOptions.Parse(new[] { "t.asm" });
            var result = new NativeAssembler(options).Assemble();
            return result.GeneratedBytes.Select(b => (int)b.Value & 0xFF).ToArray();
        });
    }

    [Fact]
    public void Block_continue_loops_to_the_top_and_break_exits()
    {
        // continue reboucle au debut du bloc ; break sort juste apres la }. On compare a la
        // meme boucle ecrite avec des etiquettes explicites : les octets doivent coincider.
        var withBlock = Assemble(
            "\torg 0BF000h\n\tmv il,5\n\t{\n\tdec il\n\tjrnz continue\n\tjr break\n\t}\n\tret\n\tend\n");
        var withLabels = Assemble(
            "\torg 0BF000h\n\tmv il,5\nt:\n\tdec il\n\tjrnz t\n\tjr e\ne:\n\tret\n\tend\n");

        Assert.Equal(withLabels, withBlock);
    }

    [Fact]
    public void Nested_blocks_target_the_innermost_one()
    {
        var nested = Assemble(
            "\torg 0BF000h\n\t{\n\tmv i,4\n\t{\n\tdec i\n\tjrnz continue\n\t}\n\tdec il\n\tjrnz continue\n\t}\n\tret\n\tend\n");
        var labelled = Assemble(
            "\torg 0BF000h\nt1:\n\tmv i,4\nt2:\n\tdec i\n\tjrnz t2\n\tdec il\n\tjrnz t1\n\tret\n\tend\n");

        Assert.Equal(labelled, nested);
    }

    [Fact]
    public void A_real_label_named_break_outside_any_block_still_works()
    {
        // Hors d'un bloc, continue/break restent de simples etiquettes (SAMPLE2, COMPILE.S
        // en definissent). La substitution ne joue qu'a l'interieur d'un { }.
        var ex = Record.Exception(() => Assemble(
            "\torg 0BF000h\n\tjr break\nbreak:\n\tret\n\tend\n"));
        Assert.Null(ex);
    }

    [Fact]
    public void An_unbalanced_block_is_rejected()
    {
        Assert.NotNull(Record.Exception(() => Assemble(
            "\torg 0BF000h\n\t{\n\tret\n\tend\n")));
        Assert.NotNull(Record.Exception(() => Assemble(
            "\torg 0BF000h\n\t}\n\tret\n\tend\n")));
    }

    [Fact]
    public void Suborg_fields_take_successive_offsets_and_percent_is_the_frame_size()
    {
        // suborg 0 puis 2 octets + 2 mots + 4 octets + 3 pointeurs : offsets 0,1,2,4,6,7,8,9,
        // 10,13,16 ; le compteur secondaire vaut alors 19, rendu par "%".
        var bytes = Assemble(
            "\torg 0BF000h\n\tsuborg 0\n" +
            "\tbyte i_work1,i_work2\n\tword sect_num,sect_num2\n\tbyte flag,rxd,i_work3,subko\n" +
            "\tpntr cachep,vct_rsv,before\n" +
            "\tdb i_work1,i_work2,sect_num,sect_num2,flag,rxd,i_work3,subko,cachep,vct_rsv,before,%\n\tend\n");

        Assert.Equal(new[] { 0, 1, 2, 4, 6, 7, 8, 9, 10, 13, 16, 19 }, bytes);
    }

    [Fact]
    public void Suborg_star_bases_the_frame_on_the_location_counter_and_arrays_advance_by_size()
    {
        // suborg * -> compteur secondaire = LC courant (ici BF004 apres 4 octets de code).
        // Les tableaux avancent de element * taille. On lit les trois pointeurs 3 octets.
        var bytes = Assemble(
            "\torg 0BF000h\nhere:\tdb 0,0,0,0\n\tsuborg *\n" +
            "\tbyte a1[130],a2[130]\n\tword n\n\tdp a1,a2,n\n\tend\n");

        var ptr = new Func<int, int>(i => bytes[4 + i * 3] | bytes[5 + i * 3] << 8 | bytes[6 + i * 3] << 16);
        Assert.Equal(0xBF004, ptr(0)); // a1 au debut du cadre
        Assert.Equal(0xBF086, ptr(1)); // a1 + 130
        Assert.Equal(0xBF108, ptr(2)); // a2 + 130
    }

    private static T RunInTempDir<T>(Func<T> body)
    {
        var dir = Path.Combine(Path.GetTempPath(), "xasm_struct", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        var previous = Directory.GetCurrentDirectory();
        Directory.SetCurrentDirectory(dir);
        try
        {
            return body();
        }
        finally
        {
            Directory.SetCurrentDirectory(previous);
            try { Directory.Delete(dir, recursive: true); } catch { /* best-effort */ }
        }
    }
}
