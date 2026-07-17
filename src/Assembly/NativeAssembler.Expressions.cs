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
        var evaluator = new ExpressionEvaluator(_symbols, _currentLocalScope, ReservedRegisters);
        var value = evaluator.Evaluate(NormalizeScopedExpression(expression));

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
        operand = NormalizeScopedExpression(operand);
        if (IsSimpleSymbolName(operand))
        {
            foreach (var symbolName in RelativeSymbolCandidates(operand))
            {
                if (!_symbolOccurrences.TryGetValue(symbolName, out var occurrences))
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

    /// <summary>
    /// Action : remplace les references locales par leur nom complet contextualise.
    /// Donnees d'entree : parametres de la signature (string expression) et etat courant necessaire.
    /// Donnees de sortie : valeur string calculee par la procedure.
    /// </summary>
    private string NormalizeScopedExpression(string expression)
    {
        const string parentPrefix = "..!";
        if (!expression.Contains(parentPrefix, StringComparison.Ordinal))
        {
            return expression;
        }

        var parentScope = _localScopeStack.Count > 0 ? _localScopeStack.Peek() : null;
        var result = new System.Text.StringBuilder(expression.Length);
        var index = 0;
        while (index < expression.Length)
        {
            var parentIndex = expression.IndexOf(parentPrefix, index, StringComparison.Ordinal);
            if (parentIndex < 0)
            {
                result.Append(expression, index, expression.Length - index);
                break;
            }

            result.Append(expression, index, parentIndex - index);
            var tokenStart = parentIndex + parentPrefix.Length;
            var tokenEnd = tokenStart;
            while (tokenEnd < expression.Length)
            {
                var c = expression[tokenEnd];
                if (!(char.IsLetterOrDigit(c) || c is '_' or '!'))
                {
                    break;
                }

                tokenEnd++;
            }

            var token = expression[tokenStart..tokenEnd];
            if (parentScope is null)
            {
                result.Append(token);
            }
            else if (token.Contains('!'))
            {
                var tokenHead = token[..token.IndexOf('!')];
                var parentTailSeparator = parentScope.LastIndexOf('!');
                var parentTail = parentTailSeparator >= 0 ? parentScope[(parentTailSeparator + 1)..] : parentScope;
                if (parentTail.Equals(tokenHead, StringComparison.OrdinalIgnoreCase))
                {
                    if (parentTailSeparator >= 0)
                    {
                        result.Append(parentScope, 0, parentTailSeparator + 1);
                    }

                    result.Append(token);
                }
                else
                {
                    result.Append(parentScope).Append('!').Append(token);
                }
            }
            else
            {
                result.Append(parentScope).Append('!').Append(token);
            }

            index = tokenEnd;
        }

        return result.ToString();
    }

    /// <summary>
    /// Action : fournit les noms possibles pour une reference relative ou locale.
    /// Donnees d'entree : parametres de la signature (string operand) et etat courant necessaire.
    /// Donnees de sortie : collection calculee par la procedure.
    /// </summary>
    private IEnumerable<string> RelativeSymbolCandidates(string operand)
    {
        if (_currentLocalScope is not null)
        {
            yield return $"{_currentLocalScope}!{operand}";
        }

        yield return operand;
    }

    /// <summary>
    /// Action : enregistre l'adresse d'utilisation d'un symbole.
    /// Donnees d'entree : parametres de la signature (string symbolName, long address) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void AddSymbolOccurrence(string symbolName, long address)
    {
        if (!_symbolOccurrences.TryGetValue(symbolName, out var occurrences))
        {
            occurrences = [];
            _symbolOccurrences[symbolName] = occurrences;
        }

        occurrences.Add(address);
    }

    /// <summary>
    /// Action : calcule le nom complet a utiliser lors de la definition d'un symbole.
    /// Donnees d'entree : parametres de la signature (string label, bool forceGlobal) et etat courant necessaire.
    /// Donnees de sortie : valeur string calculee par la procedure.
    /// </summary>
    private string SymbolNameForDefinition(string label, bool forceGlobal)
    {
        if (forceGlobal || _currentLocalScope is null || label.Contains('!') || label.StartsWith('.'))
        {
            return label;
        }

        return $"{_currentLocalScope}!{label}";
    }

    /// <summary>
    /// Action : verifie qu'une chaine est un nom de symbole simple.
    /// Donnees d'entree : parametres de la signature (string value) et etat courant necessaire.
    /// Donnees de sortie : booleen indiquant si le traitement a reussi ou si la condition est verifiee.
    /// </summary>
    private static bool IsSimpleSymbolName(string value)
    {
        if (string.IsNullOrWhiteSpace(value) || value[0] is '!' or '.' or '$' or '\'' or '"' or '[' or '(')
        {
            return false;
        }

        return value.All(c => char.IsLetterOrDigit(c) || c == '_');
    }
}
