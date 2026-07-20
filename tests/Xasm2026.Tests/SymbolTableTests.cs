using System.IO;
using Xasm2026.Native;
using Xasm2026.Native.Assembly;
using Xunit;

namespace Xasm2026.Tests;

/// <summary>
/// Regles de nommage a portee locale, testables directement depuis que la table des
/// symboles est un type autonome. C'est la partie la plus subtile du port : un label
/// defini dans un bloc LOCAL est prefixe par la portee, et "..!" designe la portee parente.
/// </summary>
public sealed class SymbolTableTests
{
    [Fact]
    public void Label_defined_outside_any_scope_keeps_its_name()
    {
        var symbols = new SymbolTable();

        Assert.Equal("main", symbols.NameForDefinition("main", forceGlobal: false));
    }

    [Fact]
    public void Label_defined_inside_a_scope_is_prefixed()
    {
        var symbols = new SymbolTable();
        symbols.EnterScope("outer");

        Assert.Equal("outer!loop", symbols.NameForDefinition("loop", forceGlobal: false));
    }

    [Theory]
    [InlineData("already!qualified")]   // deja qualifie
    [InlineData(".dotted")]             // prefixe point : reserve
    public void Qualified_or_dotted_labels_are_left_alone(string label)
    {
        var symbols = new SymbolTable();
        symbols.EnterScope("outer");

        Assert.Equal(label, symbols.NameForDefinition(label, forceGlobal: false));
    }

    [Fact]
    public void Force_global_bypasses_the_current_scope()
    {
        var symbols = new SymbolTable();
        symbols.EnterScope("outer");

        Assert.Equal("loop", symbols.NameForDefinition("loop", forceGlobal: true));
    }

    [Fact]
    public void Scopes_nest_and_unwind()
    {
        var symbols = new SymbolTable();
        symbols.EnterScope("outer");
        symbols.EnterScope("outer!inner");
        Assert.Equal("outer!inner", symbols.CurrentScope);

        symbols.ExitScope();
        Assert.Equal("outer", symbols.CurrentScope);

        symbols.ExitScope();
        Assert.Null(symbols.CurrentScope);

        // Une fermeture surnumeraire ne doit pas lever : elle laisse simplement la portee nulle.
        symbols.ExitScope();
        Assert.Null(symbols.CurrentScope);
    }

    [Fact]
    public void Parent_reference_resolves_against_the_enclosing_scope()
    {
        var symbols = new SymbolTable();
        symbols.EnterScope("outer");
        symbols.EnterScope("outer!inner");

        // Depuis "outer!inner", "..!retry" designe "outer!retry".
        Assert.Equal("outer!retry", symbols.NormalizeScopedExpression("..!retry"));
    }

    [Fact]
    public void Parent_reference_without_enclosing_scope_drops_the_prefix()
    {
        var symbols = new SymbolTable();

        Assert.Equal("retry", symbols.NormalizeScopedExpression("..!retry"));
    }

    [Fact]
    public void Expression_without_parent_reference_is_returned_unchanged()
    {
        var symbols = new SymbolTable();
        symbols.EnterScope("outer");

        Assert.Equal("base + 2 * 3", symbols.NormalizeScopedExpression("base + 2 * 3"));
    }

    [Fact]
    public void Relative_candidates_try_the_scoped_name_first()
    {
        var symbols = new SymbolTable();
        symbols.EnterScope("outer");

        Assert.Equal(new[] { "outer!loop", "loop" }, symbols.RelativeCandidates("loop"));
    }

    [Fact]
    public void Occurrences_accumulate_per_symbol()
    {
        var symbols = new SymbolTable();
        symbols.AddOccurrence("loop", 0x100);
        symbols.AddOccurrence("loop", 0x180);

        Assert.True(symbols.TryGetOccurrences("loop", out var occurrences));
        Assert.Equal(new long[] { 0x100, 0x180 }, occurrences);

        symbols.ClearOccurrences();
        Assert.False(symbols.TryGetOccurrences("loop", out _));
    }

    [Theory]
    [InlineData("loop", true)]
    [InlineData("loop_2", true)]
    [InlineData("!local", false)]
    [InlineData("$1234", false)]
    [InlineData("(bp+1)", false)]
    [InlineData("a+b", false)]
    public void Simple_symbol_names_are_recognized(string value, bool expected)
    {
        Assert.Equal(expected, SymbolTable.IsSimpleSymbolName(value));
    }

    /// <summary>
    /// Un EQU defini dans un bloc LOCAL appartient a la portee, et ne doit **pas** fuiter
    /// sous son nom nu dans l'espace global.
    ///
    /// Le preprocesseur enregistrait l'etiquette brute alors que la passe d'assemblage
    /// enregistrait le nom porte : le symbole existait deux fois. Deux portees definissant
    /// le meme nom s'ecrasaient alors mutuellement dans l'espace global, et une reference
    /// faite hors de toute portee obtenait une valeur au lieu d'une erreur.
    ///
    /// Constate sur VOGUE, ou trois symboles (`midi_term`, `off`, `on`) apparaissaient en
    /// trop par rapport a l'assembleur de reference.
    /// </summary>
    [Fact]
    public void Equ_inside_a_local_block_does_not_leak_its_bare_name()
    {
        var dir = Path.Combine(Path.GetTempPath(), "xasm_scope", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        var previous = Directory.GetCurrentDirectory();
        Directory.SetCurrentDirectory(dir);
        try
        {
            File.WriteAllText(Path.Combine(dir, "s.asm"),
                "        ORG 0E000H\n" +
                "bloc:   LOCAL\n" +
                "port:   EQU 0F4H\n" +
                "        DB  port\n" +      // resolu dans la portee
                "        ENDL\n" +
                "        END\n");

            var options = CommandLineOptions.Parse(new[] { "s.asm" });
            var result = new NativeAssembler(options).Assemble();

            // La valeur reste correctement resolue a l'interieur du bloc.
            Assert.Equal(0xF4, result.GeneratedBytes.Single().Value);

            // Le symbole n'existe que sous son nom porte.
            Assert.Contains("bloc!port", result.Symbols.Keys);
            Assert.DoesNotContain("port", result.Symbols.Keys);
        }
        finally
        {
            Directory.SetCurrentDirectory(previous);
            try { Directory.Delete(dir, recursive: true); } catch { /* best-effort */ }
        }
    }

    [Fact]
    public void Values_are_case_insensitive_like_the_assembler()
    {
        var symbols = new SymbolTable();
        symbols["Loop"] = 0x42;

        Assert.True(symbols.TryGetValue("LOOP", out var value));
        Assert.Equal(0x42, value);
    }
}
