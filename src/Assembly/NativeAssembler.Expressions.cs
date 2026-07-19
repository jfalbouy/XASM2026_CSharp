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
        // Le compteur de localisation est transmis a chaque evaluation : c'est la valeur
        // rendue par l'operande "*", pendant de la globale lc du C lue au moment de l'eval.
        var evaluator = new ExpressionEvaluator(
            _symbols.Values, _symbols.CurrentScope, ReservedRegisters, _locationCounter);
        var prepared = SubstituteArguments(expression, _currentOrigin?.Args);
        var value = evaluator.Evaluate(_symbols.NormalizeScopedExpression(prepared));

        // En passe d'emission, un symbole encore non resolu ne peut plus l'etre : c'est une erreur,
        // sinon la reference serait silencieusement assemblee a 0 (binaire faux non signale).
        // Ce controle passe avant celui de la division par zero : quand un diviseur est un
        // symbole inconnu, le vrai defaut est le symbole, pas la division.
        if (strict && _emitPass && evaluator.Undefined.Count > 0)
        {
            throw new InvalidOperationException(
                $"symbole indefini: {string.Join(", ", evaluator.Undefined)}");
        }

        // err 2 de mes.c. Comme pour les symboles, le controle n'a lieu qu'en passe
        // d'emission : en passe de resolution un diviseur symbolique vaut encore 0, et
        // signaler la sur cette base produirait un faux positif sur un source valide.
        if (strict && _emitPass && evaluator.DividedByZero)
        {
            throw new InvalidOperationException($"Division by zero: {expression.Trim()}");
        }

        // Table des references croisees : on n'enregistre qu'en passe d'emission, sans quoi
        // chaque utilisation serait comptee deux fois.
        if (_emitPass && _currentOrigin is not null)
        {
            foreach (var name in evaluator.Referenced)
            {
                _symbols.AddReference(name, _currentOrigin.File, _currentOrigin.Line);
            }
        }

        return value;
    }

    /// <summary>
    /// Action : evalue et borne un deplacement signe sur un octet.
    /// Donnees d'entree : parametres de la signature (string expression) et etat courant necessaire.
    /// Donnees de sortie : valeur int calculee par la procedure.
    /// </summary>
    /// <summary>
    /// Action : remplace les references @0..@9 par l'expression de l'argument correspondant.
    /// Donnees d'entree : expression source, arguments de l'INCLUDE du fichier courant.
    /// Donnees de sortie : expression ou chaque @n est remplace par "(expression)".
    ///
    /// eval.c traite '@' avec set_x == FALSE : @ suivi d'un chiffre unique rend
    /// current_file->arg[n], et une reference hors plage donne l'err 31. Ici la substitution
    /// est textuelle et parenthesee, ce qui preserve la precedence de l'expression injectee.
    /// </summary>
    private static string SubstituteArguments(string expression, IReadOnlyList<string>? args)
    {
        if (expression.IndexOf('@') < 0)
        {
            return expression;
        }

        var result = new System.Text.StringBuilder(expression.Length);
        for (var i = 0; i < expression.Length; i++)
        {
            if (expression[i] != '@' || i + 1 >= expression.Length || !char.IsAsciiDigit(expression[i + 1]))
            {
                result.Append(expression[i]);
                continue;
            }

            var index = expression[i + 1] - '0';
            if (args is null || index >= args.Count)
            {
                throw new InvalidOperationException(
                    $"Bad argument number: @{index} (le fichier a recu {args?.Count ?? 0} argument(s))");
            }

            result.Append('(').Append(args[index]).Append(')');
            i++;
        }

        return result.ToString();
    }

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
