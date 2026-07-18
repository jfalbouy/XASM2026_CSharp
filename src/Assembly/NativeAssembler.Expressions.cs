using Xasm2026.Native.Expressions;

namespace Xasm2026.Native.Assembly;

// Evaluation d'expressions, resolution des cibles relatives et gestion des noms
// de symboles (portee locale, occurrences). Extrait du noyau NativeAssembler.
internal sealed partial class NativeAssembler
{
    /// <summary>
    /// Action : evalue une expression assembleur avec les symboles connus.
    /// Donnees d'entree : parametres de la signature (string expression) et etat courant necessaire.
    /// Donnees de sortie : valeur long calculee par la procedure.
    /// </summary>
    // Mnemoniques de registres SC62015 : reserves, valent 0 dans une expression d'adressage.
    // Ils ne doivent jamais etre traites comme des symboles indefinis.
    private static readonly IReadOnlySet<string> ReservedRegisters =
        new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "A", "B", "BA", "I", "IL", "IMR", "F",
            "X", "Y", "U", "S", "BP", "PX", "PY",
        };

    private long Eval(string expression, bool strict = true)
    {
        var evaluator = new ExpressionEvaluator(_symbols.Values, _symbols.CurrentScope, ReservedRegisters);
        var value = evaluator.Evaluate(_symbols.NormalizeScopedExpression(expression));

        // En passe d'emission, un symbole encore non resolu ne peut plus l'etre : c'est une erreur,
        // sinon la reference serait silencieusement assemblee a 0 (binaire faux non signale).
        if (strict && _emitPass && evaluator.Undefined.Count > 0)
        {
            throw new InvalidOperationException(
                $"symbole indefini: {string.Join(", ", evaluator.Undefined)}");
        }

        return value;
    }

    /// <summary>
    /// Action : evalue et borne un deplacement signe sur un octet.
    /// Donnees d'entree : parametres de la signature (string expression) et etat courant necessaire.
    /// Donnees de sortie : valeur int calculee par la procedure.
    /// </summary>
    private int EvalDisplacement(string expression)
    {
        var value = Eval(expression);
        if (value > 0x7FFFF)
        {
            value -= 0x100000;
        }

        return Math.Abs((int)value);
    }

    /// <summary>
    /// Action : resout la cible d'un saut relatif, y compris les etiquettes locales.
    /// Donnees d'entree : parametres de la signature (string operand) et etat courant necessaire.
    /// Donnees de sortie : valeur long calculee par la procedure.
    /// </summary>
    private long ResolveRelativeTarget(string operand)
    {
        operand = _symbols.NormalizeScopedExpression(operand);
        if (SymbolTable.IsSimpleSymbolName(operand))
        {
            foreach (var symbolName in _symbols.RelativeCandidates(operand))
            {
                if (!_symbols.TryGetOccurrences(symbolName, out var occurrences))
                {
                    continue;
                }

                var reachable = occurrences
                    .Select(address => new { Address = address, Delta = address - _locationCounter - 2 })
                    .Where(x => x.Delta is >= 0 and <= 255 || x.Delta < 0 && x.Delta >= -255)
                    .OrderBy(x => Math.Abs(x.Delta))
                    .FirstOrDefault();
                if (reachable is not null)
                {
                    return reachable.Address;
                }
            }
        }

        return Eval(operand);
    }





}
