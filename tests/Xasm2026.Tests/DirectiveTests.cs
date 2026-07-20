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

    /// <summary>
    /// Une etiquette posee sur un appel de macro doit designer le premier octet emis par
    /// l'expansion. Elle etait silencieusement perdue : l'expansion ayant lieu au
    /// preprocesseur, l'etiquette de la ligne d'appel disparaissait avec elle, alors que le
    /// C la definit avant meme de chercher le mnemonique.
    ///
    /// Defaut trouve en reecrivant REGISTER.ASM, ou "waitky:" etiquette un balayage clavier
    /// devenu un appel de macro.
    /// </summary>
    [Fact]
    public void Label_on_a_macro_call_is_kept()
    {
        AssertBytes(
            "        MACRO  deuxoctets\n" +
            "        DB     11H\n" +
            "        DB     22H\n" +
            "        ENDM\n" +
            "cible:  deuxoctets\n" +
            "        DP     cible\n",
            0x11, 0x22, 0x00, 0xE0, 0x00);
    }

    /// <summary>
    /// Un symbole dont le nom commence par les lettres d'un registre de base ne doit pas
    /// etre confondu avec la forme d'adressage correspondante.
    ///
    /// "(bp_p)" etait pris pour une forme relative a BP, ce qui supprimait le prebyte
    /// automatique : trois octets emis au lieu de quatre, donc un code faux, et sans le
    /// moindre message. Defaut trouve en nommant une constante "bp_p" dans REGISTER2.ASM.
    /// </summary>
    [Fact]
    public void Symbol_starting_like_a_base_register_is_not_an_indexed_form()
    {
        // Les trois ecritures designent la meme adresse et doivent produire les memes octets.
        AssertBytes("        PRE_ON\n        MV  (0ECH),0H\n", 0x30, 0xCC, 0xEC, 0x00);
        AssertBytes("port:   EQU 0ECH\n        PRE_ON\n        MV  (port),0H\n",
            0x30, 0xCC, 0xEC, 0x00);
        AssertBytes("bp_p:   EQU 0ECH\n        PRE_ON\n        MV  (bp_p),0H\n",
            0x30, 0xCC, 0xEC, 0x00);

        // La vraie forme relative a BP reste reconnue, et sans prebyte.
        // Encodage confirme contre l'assembleur de reference xasm2026-1-2.
        AssertBytes("        PRE_ON\n        MV  (BP+1),0H\n", 0xCC, 0x01, 0x00);
    }

    /// <summary>
    /// Le prebyte precede l'opcode. Sur les formes MVW (n),[...] il se retrouvait derriere
    /// lui, car InternalRamOffset emet le prebyte au moment de son appel et cet appel avait
    /// lieu apres l'emission de l'opcode. Les octets etaient les bons, dans le mauvais ordre.
    ///
    /// Defaut trouve en assemblant ISHD.ASM et ISHE.ASM, deux programmes que les quatre
    /// exemples de reference n'avaient jamais mis en defaut. Encodages confirmes contre
    /// l'assembleur de reference xasm2026-1-2.
    /// </summary>
    [Fact]
    public void Prebyte_precedes_the_opcode_on_mvw_from_memory()
    {
        // MVW (n),[adresse absolue] : prebyte, opcode, offset interne, adresse 24 bits.
        AssertBytesAt(0xBC000,
            "cible:  EQU 0BD3A6H\n        PRE_ON\n        MVW (0),[cible]\n",
            0x30, 0xD1, 0x00, 0xA6, 0xD3, 0x0B);

        // MVW (n),[y++] : prebyte, opcode, suffixe d'indexation, offset interne.
        AssertBytesAt(0xBC000,
            "        PRE_ON\n        MVW (0),[y++]\n",
            0x30, 0xE1, 0x25, 0x00);
    }

    /// <summary>
    /// Encodages ramenes de l'assembleur de reference, sur des formes que les quatre
    /// exemples historiques n'exercaient pas. Chacun correspond a un defaut trouve en
    /// assemblant ISHD, ISHE, PLINK, tycom et PANO.
    /// </summary>
    [Theory]
    // Echange entre registres d'adresse : prefixe 0EDh puis les deux identifiants.
    [InlineData("        EX  X,U\n", new[] { 0xED, 0x46 })]
    [InlineData("        EX  BA,I\n", new[] { 0xED, 0x23 })]
    // MV (bp+n),[adresse] : pas de prebyte, l'operande gauche etant relatif a BP.
    [InlineData("w:      EQU 0BFC9DH\n        PRE_ON\n        MV (bp+7),[w]\n",
        new[] { 0xD0, 0x07, 0x9D, 0xFC, 0x0B })]
    // Indirection par pointeur en RAM interne : le prebyte de la base precede l'opcode.
    [InlineData("        PRE_ON\n        MV A,[(20H)+1]\n", new[] { 0x30, 0x98, 0x80, 0x20, 0x01 })]
    [InlineData("        PRE_ON\n        MV A,[(px+3)+1]\n", new[] { 0x34, 0x98, 0x80, 0x03, 0x01 })]
    [InlineData("        PRE_ON\n        MV A,[(bp+3)+1]\n", new[] { 0x98, 0x80, 0x03, 0x01 })]
    // MVW (n),(n) : le prebyte se deduit des deux operandes et precede l'opcode.
    [InlineData("        PRE_ON\n        MVW (bp+2),(0D4H)\n", new[] { 0x22, 0xC9, 0x02, 0xD4 })]
    [InlineData("        PRE_ON\n        MVW (10H),(20H)\n", new[] { 0x32, 0xC9, 0x10, 0x20 })]
    // CMP [adresse],immediat : l'opcode est 62h, les deux chiffres avaient ete transposes.
    [InlineData("a1:     EQU 0BF76CH\n        PRE_ON\n        CMP [a1],0\n",
        new[] { 0x62, 0x6C, 0xF7, 0x0B, 0x00 })]
    // Saut vers l'adresse contenue dans un registre. Seul "jp x" etait reconnu : les trois
    // autres formes tombaient dans le saut absolu et sautaient en silence vers l'adresse 0.
    [InlineData("        JP X\n", new[] { 0x11, 0x04 })]
    [InlineData("        JP Y\n", new[] { 0x11, 0x05 })]
    [InlineData("        JP U\n", new[] { 0x11, 0x06 })]
    [InlineData("        JP S\n", new[] { 0x11, 0x07 })]
    // Un symbole reste un saut absolu : la forme registre ne doit pas capturer les etiquettes.
    [InlineData("cible:  EQU 0BE000H\n        JP cible\n", new[] { 0x02, 0x00, 0xE0 })]
    public void Encodings_confirmed_against_the_reference_assembler(string source, int[] expected)
    {
        AssertBytesAt(0xBE000, source, expected);
    }

    private static void AssertBytesAt(long origine, string body, params int[] expected)
    {
        var result = Assemble(body, origine);
        Assert.Equal(expected, result.GeneratedBytes.Select(b => (int)b.Value).ToArray());
    }

    private static void AssertBytes(string body, params int[] expected)
    {
        var result = Assemble(body);
        Assert.Equal(expected, result.GeneratedBytes.Select(b => (int)b.Value).ToArray());
    }

    /// <summary>
    /// Assemble un fragment place apres un ORG dans un dossier temporaire.
    /// </summary>
    private static Xasm2026.Native.Core.AssemblyResult Assemble(string body) => Assemble(body, 0xE000);

    private static Xasm2026.Native.Core.AssemblyResult Assemble(string body, long origine)
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
