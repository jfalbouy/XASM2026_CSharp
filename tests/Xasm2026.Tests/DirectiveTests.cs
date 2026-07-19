using System.IO;
using Xasm2026.Native;
using Xasm2026.Native.Assembly;
using Xunit;

namespace Xasm2026.Tests;

/// <summary>
/// Directives ajoutees au-dela du jeu historique de XASM : symboles redefinissables,
/// repetition sur liste et sur chaine. Chaque test compare les octets reellement emis.
/// </summary>
[Collection("assembler")]
public sealed class DirectiveTests
{
    /// <summary>
    /// SET definit un symbole redefinissable. C'est ce qui rend REPEAT reellement generatif :
    /// sans lui, aucun compteur ne peut progresser d'une iteration a l'autre.
    /// </summary>
    [Fact]
    public void Set_is_redefinable_and_drives_a_repeat_counter()
    {
        AssertBytes(
            "n:      SET 0\n" +
            "        REPEAT 5\n" +
            "        DB  n\n" +
            "n:      SET n+1\n" +
            "        ENDR\n" +
            "        DB  0FFH\n" +
            "n:      SET 100\n" +
            "        DB  n\n",
            0x00, 0x01, 0x02, 0x03, 0x04, 0xFF, 0x64);
    }

    /// <summary>
    /// La forme "=" est un synonyme de SET.
    /// </summary>
    [Fact]
    public void Equals_sign_is_a_synonym_of_set()
    {
        AssertBytes("k:      = 7\n        DB  k\n", 0x07);
    }

    /// <summary>
    /// IRP rejoue le bloc une fois par valeur de la liste.
    /// </summary>
    [Fact]
    public void Irp_repeats_the_block_once_per_value()
    {
        AssertBytes(
            "        IRP  v,10H,20H,30H\n" +
            "        DB   v\n" +
            "        ENDR\n",
            0x10, 0x20, 0x30);
    }

    /// <summary>
    /// IRPC rejoue le bloc une fois par caractere. Chaque caractere est injecte comme
    /// litteral, si bien que "DB c" emet son code ASCII.
    /// </summary>
    [Fact]
    public void Irpc_repeats_the_block_once_per_character()
    {
        AssertBytes(
            "        IRPC c,ABC\n" +
            "        DB   c\n" +
            "        ENDR\n",
            0x41, 0x42, 0x43);
    }

    /// <summary>
    /// REPEAT, IRP et IRPC partagent le terminateur ENDR : leur imbrication n'est correcte
    /// que si la collecte de bloc compte la profondeur. Sans cela, le premier ENDR fermerait
    /// le bloc exterieur et le source serait developpe de travers.
    /// </summary>
    [Fact]
    public void Repeat_and_irp_nest()
    {
        AssertBytes(
            "        IRP  v,1,2\n" +
            "        REPEAT 2\n" +
            "        DB   v\n" +
            "        ENDR\n" +
            "        ENDR\n",
            0x01, 0x01, 0x02, 0x02);
    }

    /// <summary>
    /// Le mnemonique de l'opcode 0CEh est enregistre "TCP" dans la table de hachage du C
    /// (init.c) alors que le commentaire a l'encodage dit TCL (genop.c case 56). Les deux
    /// graphies sont acceptees pour rester compatible dans les deux sens.
    /// </summary>
    [Theory]
    [InlineData("        TCL\n")]
    [InlineData("        TCP\n")]
    public void Both_spellings_of_the_0CE_opcode_are_accepted(string source)
    {
        AssertBytes(source, 0xCE);
    }

    /// <summary>
    /// Assemble un fragment place apres un ORG et compare les octets emis.
    /// </summary>
    private static void AssertBytes(string body, params int[] expected)
    {
        var dir = Path.Combine(Path.GetTempPath(), "xasm_directives", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        var previous = Directory.GetCurrentDirectory();
        Directory.SetCurrentDirectory(dir);
        try
        {
            File.WriteAllText(Path.Combine(dir, "t.asm"), "        ORG 0E000H\n" + body + "        END\n");
            var options = CommandLineOptions.Parse(new[] { "t.asm" });
            var result = new NativeAssembler(options).Assemble();

            Assert.Equal(expected, result.GeneratedBytes.Select(b => (int)b.Value).ToArray());
        }
        finally
        {
            Directory.SetCurrentDirectory(previous);
            try { Directory.Delete(dir, recursive: true); } catch { /* best-effort */ }
        }
    }
}
