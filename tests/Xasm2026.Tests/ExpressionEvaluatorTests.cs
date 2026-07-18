using Xasm2026.Native.Expressions;
using Xunit;

namespace Xasm2026.Tests;

/// <summary>
/// Constantes numeriques et compteur de localisation, conformement a eval.c :
/// c'est le dernier caractere du jeton qui fixe la base, et "*" en position de terme
/// designe le compteur de localisation.
/// </summary>
public sealed class ExpressionEvaluatorTests
{
    private static readonly Dictionary<string, long> NoSymbols = new(StringComparer.OrdinalIgnoreCase);

    private static long Eval(string expression, long locationCounter = 0)
    {
        var evaluator = new ExpressionEvaluator(NoSymbols, locationCounter: locationCounter);
        var value = evaluator.Evaluate(expression);
        Assert.Empty(evaluator.Undefined);
        return value;
    }

    [Theory]
    // Binaire : suffixe B, dans les deux casses.
    [InlineData("10110101B", 0xB5)]
    [InlineData("10110101b", 0xB5)]
    [InlineData("0B", 0)]
    // Octal : suffixe O.
    [InlineData("377O", 0xFF)]
    [InlineData("377o", 0xFF)]
    // Decimal : suffixe D, et absence de suffixe.
    [InlineData("1234D", 1234)]
    [InlineData("1234d", 1234)]
    [InlineData("1234", 1234)]
    [InlineData("42", 42)]
    // Hexadecimal : suffixe H ou prefixe $.
    [InlineData("0FFH", 0xFF)]
    [InlineData("0ffh", 0xFF)]
    [InlineData("$AB", 0xAB)]
    [InlineData("$ab", 0xAB)]
    public void Number_bases_follow_the_trailing_suffix(string token, long expected)
    {
        Assert.Equal(expected, Eval(token));
    }

    [Theory]
    [InlineData("1010_1010B", 0xAA)]
    [InlineData("0F_FH", 0xFF)]
    [InlineData("1_000", 1000)]
    public void Underscore_is_a_visual_separator(string token, long expected)
    {
        Assert.Equal(expected, Eval(token));
    }

    /// <summary>
    /// Un chiffre superieur ou egal a la base invalide le jeton (err 23 de eval.c) : il n'est
    /// alors pas un nombre, donc il remonte comme symbole indefini.
    /// </summary>
    [Theory]
    [InlineData("2B")]     // 2 n'existe pas en base 2
    [InlineData("8O")]     // 8 n'existe pas en base 8
    [InlineData("1A9D")]   // A n'existe pas en base 10
    public void Digit_outside_the_radix_is_not_a_number(string token)
    {
        var evaluator = new ExpressionEvaluator(NoSymbols);
        evaluator.Evaluate(token);

        Assert.Contains(token, evaluator.Undefined);
    }

    /// <summary>
    /// Un jeton commencant par une lettre est un nom de symbole, jamais un nombre : c'est la
    /// raison pour laquelle l'hexadecimal exige un zero de tete (0FFH et non FFH).
    /// </summary>
    [Fact]
    public void Token_starting_with_a_letter_is_a_symbol_not_a_number()
    {
        var evaluator = new ExpressionEvaluator(NoSymbols);
        evaluator.Evaluate("FFH");

        Assert.Contains("FFH", evaluator.Undefined);
    }

    [Fact]
    public void Star_in_term_position_yields_the_location_counter()
    {
        Assert.Equal(0xE000, Eval("*", locationCounter: 0xE000));
    }

    [Fact]
    public void Location_counter_composes_with_arithmetic()
    {
        Assert.Equal(0xE002, Eval("*+2", locationCounter: 0xE000));
        Assert.Equal(0xDFFE, Eval("*-2", locationCounter: 0xE000));
        Assert.Equal(0x1000, Eval("*/2", locationCounter: 0x2000));
    }

    /// <summary>
    /// Le point delicat : "*" reste l'operateur de multiplication entre deux valeurs. Les deux
    /// emplois se distinguent par la position, exactement comme le drapeau set_x du C.
    /// </summary>
    [Theory]
    [InlineData("4*3", 12)]
    [InlineData("2*3*2", 12)]
    [InlineData("(2+2)*3", 12)]
    public void Star_between_values_remains_multiplication(string expression, long expected)
    {
        Assert.Equal(expected, Eval(expression, locationCounter: 0xE000));
    }

    /// <summary>
    /// Cas limite : compteur de localisation multiplie par une valeur. Le premier "*" est en
    /// position de terme, le second est l'operateur.
    /// </summary>
    [Fact]
    public void Location_counter_can_be_multiplied()
    {
        Assert.Equal(0x20, Eval("**2", locationCounter: 0x10));
    }
}
