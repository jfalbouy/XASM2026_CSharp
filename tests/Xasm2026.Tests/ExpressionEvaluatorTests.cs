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

    [Theory]
    [InlineData("0F0H|0FH", 0xFF)]
    [InlineData("0FFH&0F0H", 0xF0)]
    [InlineData("17%5", 2)]
    [InlineData("10%2", 0)]
    public void Bitwise_and_modulo_operators_are_supported(string expression, long expected)
    {
        Assert.Equal(expected, Eval(expression));
    }

    /// <summary>
    /// Precedence de oprlevel_set (init.c), du plus faible au plus fort :
    /// "|" 3 &lt; "&amp;" 4 &lt; "%" 5 &lt; "+ -" 6 &lt; "* /" 7.
    ///
    /// Le piege : le modulo lie **moins fort** que l'addition, contrairement au C. Ces cas
    /// echoueraient avec la precedence du C, ils verrouillent donc la regle historique.
    /// </summary>
    [Theory]
    [InlineData("1+2%3", 0)]        // (1+2)%3 = 0, et non 1+(2%3) = 3
    [InlineData("2*3%4", 2)]        // (2*3)%4 = 2
    [InlineData("1|2&3", 3)]        // & plus fort que | : 1|(2&3) = 1|2 = 3
    [InlineData("6&3+1", 4)]        // + plus fort que & : 6&(3+1) = 6&4 = 4
    [InlineData("(1+2)%3", 0)]
    [InlineData("1+(2%3)", 3)]      // parentheses explicites : l'autre lecture
    public void Operator_precedence_follows_oprlevel(string expression, long expected)
    {
        Assert.Equal(expected, Eval(expression));
    }

    /// <summary>
    /// L'evaluateur ne leve pas : il rend 0 et signale le fait via DividedByZero. C'est
    /// l'assembleur qui en fait l'erreur fatale (err 2), et seulement en passe d'emission,
    /// car en passe de resolution un diviseur symbolique vaut encore 0.
    /// </summary>
    [Theory]
    [InlineData("5/0")]
    [InlineData("5%0")]
    [InlineData("10/(3-3)")]
    public void Division_by_zero_is_reported_not_thrown(string expression)
    {
        var evaluator = new ExpressionEvaluator(NoSymbols);
        var value = evaluator.Evaluate(expression);

        Assert.Equal(0, value);
        Assert.True(evaluator.DividedByZero, "la division par zero doit etre signalee");
    }

    [Theory]
    [InlineData("10/2")]
    [InlineData("10%3")]
    [InlineData("0/5")]
    public void Sound_division_is_not_flagged(string expression)
    {
        var evaluator = new ExpressionEvaluator(NoSymbols);
        evaluator.Evaluate(expression);

        Assert.False(evaluator.DividedByZero);
    }
}
