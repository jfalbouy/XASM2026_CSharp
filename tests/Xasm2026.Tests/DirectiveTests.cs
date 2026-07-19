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

    [Fact]
    public void Align_and_even_pad_up_to_the_boundary()
    {
        AssertBytes(
            "        DB  1,2,3\n" +
            "        ALIGN 4\n" +
            "        DB  0AAH\n" +
            "        EVEN\n" +
            "        DB  0BBH\n",
            0x01, 0x02, 0x03, 0x00, 0xAA, 0x00, 0xBB);
    }

    /// <summary>
    /// L'image etant contigue, l'alignement doit emettre le remplissage et pas seulement
    /// avancer le compteur, sinon l'objet et les adresses divergeraient.
    /// </summary>
    [Fact]
    public void Align_on_an_already_aligned_counter_emits_nothing()
    {
        AssertBytes("        DB  1,2,3,4\n        ALIGN 4\n        DB  0AAH\n",
            0x01, 0x02, 0x03, 0x04, 0xAA);
    }

    [Fact]
    public void Dz_appends_a_terminator()
    {
        AssertBytes("        DZ  'HI'\n", 0x48, 0x49, 0x00);
    }

    /// <summary>
    /// PHASE assemble a une adresse et execute a une autre : les etiquettes prennent
    /// l'adresse logique, mais les octets restent a leur place physique dans l'image.
    /// </summary>
    [Fact]
    public void Phase_relocates_labels_but_not_the_image()
    {
        var result = Assemble(
            "        DB  0AAH\n" +
            "        PHASE 0B0000H\n" +
            "ici:    NOP\n" +
            "        DP  ici\n" +          // 0B0000, adresse logique
            "        DEPHASE\n" +
            "        DP  *\n");            // retour au physique

        Assert.Equal(
            new[] { 0xAA, 0x00, 0x00, 0x00, 0x0B, 0x05, 0xE0, 0x00 },
            result.GeneratedBytes.Select(b => (int)b.Value).ToArray());

        // L'image reste contigue a partir de l'ORG physique.
        Assert.Equal(0xE000, result.GeneratedBytes[0].Address);
        Assert.Equal(0xE007, result.GeneratedBytes[^1].Address);
    }

    [Theory]
    [InlineData("        DB  LOW  0BE123H\n", 0x23)]
    [InlineData("        DB  MID  0BE123H\n", 0xE1)]
    [InlineData("        DB  HIGH 0BE123H\n", 0x0B)]
    [InlineData("        DB  0F0H^0FFH\n", 0x0F)]
    [InlineData("        DB  1<<4\n", 0x10)]
    [InlineData("        DB  80H>>3\n", 0x10)]
    [InlineData("        DB  ~0FFH&0FFH\n", 0x00)]
    public void New_operators_evaluate(string source, int expected)
    {
        AssertBytes(source, expected);
    }

    /// <summary>
    /// Les decalages lient moins fort que l'addition, comme en C : "1<<2+3" vaut "1<<5".
    /// Et "&lt;" ne doit pas etre confondu avec le debut de "&lt;&lt;".
    /// </summary>
    [Theory]
    [InlineData("        DB  1<<2+3\n", 0x20)]
    [InlineData("        DB  3<5\n", 0x01)]
    [InlineData("        DB  5<3\n", 0x00)]
    [InlineData("        DB  4=4\n", 0x01)]
    [InlineData("        DB  4<>4\n", 0x00)]
    [InlineData("        DB  5>=5\n", 0x01)]
    public void Comparison_and_shift_disambiguate(string source, int expected)
    {
        AssertBytes(source, expected);
    }

    /// <summary>
    /// ERROR interrompt l'assemblage avec son message ; ASSERT ne le fait que si la
    /// condition est fausse.
    /// </summary>
    [Fact]
    public void Error_and_assert_stop_the_assembly()
    {
        var error = Assert.Throws<InvalidOperationException>(
            () => Assemble("        ERROR 'table trop grande'\n"));
        Assert.Contains("table trop grande", error.Message, StringComparison.Ordinal);

        var assert = Assert.Throws<InvalidOperationException>(
            () => Assemble("taille: EQU 300\n        ASSERT taille<256,'depasse 256'\n"));
        Assert.Contains("depasse 256", assert.Message, StringComparison.Ordinal);

        // Assertion verifiee : aucun arret.
        var ok = Assemble("taille: EQU 100\n        ASSERT taille<256\n        DB 1\n");
        Assert.Single(ok.GeneratedBytes);
    }

    [Fact]
    public void Warning_directive_reports_without_being_fatal()
    {
        var result = Assemble("        WARNING 'code experimental'\n        DB 1\n");

        Assert.Single(result.GeneratedBytes);
        Assert.Contains(result.Warnings, w => w.Message.Contains("code experimental"));
    }

    /// <summary>
    /// Assemble un fragment place apres un ORG et compare les octets emis.
    /// </summary>
    /// <summary>
    /// NOLIST retire les lignes du listing sans rien changer au code emis : les octets et
    /// les adresses doivent rester identiques.
    /// </summary>
    [Fact]
    public void Nolist_hides_listing_lines_but_still_emits_code()
    {
        var result = Assemble(
            "        DB  1\n" +
            "        NOLIST\n" +
            "        DB  0FFH\n" +
            "        LIST\n" +
            "        DB  2\n");

        Assert.Equal(new[] { 0x01, 0xFF, 0x02 }, result.GeneratedBytes.Select(b => (int)b.Value).ToArray());
        Assert.DoesNotContain(result.ListingLines, l => l.SourceText.Contains("0FFH", StringComparison.Ordinal));
        Assert.Contains(result.ListingLines, l => l.SourceText.Contains("DB  2", StringComparison.Ordinal));
    }

    [Fact]
    public void Title_is_carried_to_the_result()
    {
        var result = Assemble("        TITLE 'Module de test'\n        DB 1\n");

        Assert.Equal("Module de test", result.Title);
    }

    /// <summary>
    /// La table des references croisees recense les **utilisations** d'un symbole, avec leur
    /// ligne physique — a ne pas confondre avec les occurrences de definition, qui servent a
    /// choisir la cible d'un saut relatif.
    /// </summary>
    [Fact]
    public void Cross_reference_records_symbol_uses_with_their_lines()
    {
        var result = Assemble(
            "base:   EQU 10H\n" +      // ligne 2 du fichier (ORG est en ligne 1)
            "        DB  base\n" +     // ligne 3
            "        DB  base+1\n" +   // ligne 4
            "        DB  base*2\n");   // ligne 5

        Assert.True(result.SymbolReferences.TryGetValue("base", out var places));
        Assert.Equal(new[] { "t.asm:3", "t.asm:4", "t.asm:5" }, places);
    }

    /// <summary>
    /// EXITM interrompt l'expansion de la macro englobante. Il n'a de sens que parce que le
    /// corps est desormais **re-developpe** : les conditionnelles y sont resolues au moment
    /// de l'expansion, et non plus reportees a la passe d'assemblage.
    /// </summary>
    [Fact]
    public void Exitm_stops_the_enclosing_macro()
    {
        AssertBytes(
            "        MACRO  garde,drapeau\n" +
            "        DB     0AAH\n" +
            "        IFEQ   drapeau\n" +
            "        EXITM\n" +
            "        ENDIF\n" +
            "        DB     0BBH\n" +
            "        ENDM\n" +
            "        garde  0\n" +      // sortie anticipee : AA seul
            "        garde  1\n",       // corps complet : AA BB
            0xAA, 0xAA, 0xBB);
    }

    /// <summary>
    /// EXITM traverse un REPEAT pour sortir de la macro, et non seulement de la boucle.
    /// </summary>
    [Fact]
    public void Exitm_unwinds_through_a_repeat()
    {
        AssertBytes(
            "        MACRO  m\n" +
            "        REPEAT 5\n" +
            "        DB     7\n" +
            "        EXITM\n" +
            "        ENDR\n" +
            "        DB     0FFH\n" +
            "        ENDM\n" +
            "        m\n",
            0x07);
    }

    /// <summary>
    /// L'expansion recursive debloque les macros imbriquees, que le C interdit (err 44),
    /// ainsi que REPEAT a l'interieur d'un corps de macro.
    /// </summary>
    [Fact]
    public void Macros_can_nest_and_contain_repeat()
    {
        AssertBytes(
            "        MACRO  interne\n        DB 022H\n        ENDM\n" +
            "        MACRO  externe\n        DB 011H\n        interne\n        DB 033H\n        ENDM\n" +
            "        externe\n",
            0x11, 0x22, 0x33);

        AssertBytes(
            "        MACRO  trois\n        REPEAT 3\n        DB 5\n        ENDR\n        ENDM\n" +
            "        trois\n",
            0x05, 0x05, 0x05);
    }

    /// <summary>
    /// Une macro qui s'appelle elle-meme doit etre rejetee, et non developper a l'infini.
    /// </summary>
    [Fact]
    public void Recursive_macro_is_rejected()
    {
        var ex = Assert.Throws<InvalidOperationException>(
            () => Assemble("        MACRO boucle\n        DB 1\n        boucle\n        ENDM\n        boucle\n"));

        Assert.Contains("recursion de macro", ex.Message, StringComparison.Ordinal);
    }

    [Fact]
    public void Exitm_outside_a_macro_is_an_error()
    {
        var ex = Assert.Throws<InvalidOperationException>(() => Assemble("        EXITM\n"));

        Assert.Contains("EXITM", ex.Message, StringComparison.Ordinal);
    }

    private static void AssertBytes(string body, params int[] expected)
    {
        var result = Assemble(body);
        Assert.Equal(expected, result.GeneratedBytes.Select(b => (int)b.Value).ToArray());
    }

    /// <summary>
    /// Assemble un fragment place apres un ORG dans un dossier temporaire.
    /// </summary>
    private static Xasm2026.Native.Core.AssemblyResult Assemble(string body)
    {
        var dir = Path.Combine(Path.GetTempPath(), "xasm_directives", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        var previous = Directory.GetCurrentDirectory();
        Directory.SetCurrentDirectory(dir);
        try
        {
            File.WriteAllText(Path.Combine(dir, "t.asm"), "        ORG 0E000H\n" + body + "        END\n");
            var options = CommandLineOptions.Parse(new[] { "t.asm" });
            return new NativeAssembler(options).Assemble();
        }
        finally
        {
            Directory.SetCurrentDirectory(previous);
            try { Directory.Delete(dir, recursive: true); } catch { /* best-effort */ }
        }
    }
}
