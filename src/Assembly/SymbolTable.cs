namespace Xasm2026.Native.Assembly;

/// <summary>
/// Action : table des symboles de l'assemblage, avec leurs valeurs, leurs occurrences
/// d'adresse et la gestion de la portee locale (LOCAL / ENDL).
/// Donnees d'entree : definitions et references rencontrees pendant les deux passes.
/// Donnees de sortie : valeurs resolues, candidats de resolution et noms contextualises.
///
/// Extrait du noyau NativeAssembler : les regles de nommage a portee locale (prefixe
/// "scope!label", reference parente "..!") sont la partie la plus subtile du port et
/// gagnent a etre isolees et testables independamment du reste de l'assembleur.
/// Pendant de hash.c (table des symboles) et de la pile l_stack du C.
/// </summary>
internal sealed class SymbolTable
{
    private readonly Dictionary<string, long> _values = new(StringComparer.OrdinalIgnoreCase);
    private readonly Dictionary<string, List<long>> _occurrences = new(StringComparer.OrdinalIgnoreCase);
    private readonly Stack<string?> _scopeStack = new();

    /// <summary>Portee locale courante, ou null hors de tout bloc LOCAL.</summary>
    public string? CurrentScope { get; private set; }

    /// <summary>Vue en lecture seule des valeurs, destinee a l'evaluateur d'expressions.</summary>
    public IReadOnlyDictionary<string, long> Values => _values;

    public long this[string name]
    {
        get => _values[name];
        set => _values[name] = value;
    }

    public bool TryGetValue(string name, out long value) => _values.TryGetValue(name, out value);

    public bool Contains(string name) => _values.ContainsKey(name);

    /// <summary>
    /// Action : reinitialise l'etat de portee entre deux passes, sans perdre les valeurs.
    /// </summary>
    public void ResetScopes()
    {
        CurrentScope = null;
        _scopeStack.Clear();
    }

    public void ClearOccurrences() => _occurrences.Clear();

    /// <summary>
    /// Action : ouvre une portee locale, en empilant la precedente.
    /// </summary>
    public void EnterScope(string scope)
    {
        _scopeStack.Push(CurrentScope);
        CurrentScope = scope;
    }

    /// <summary>
    /// Action : referme la portee locale courante et restaure la precedente.
    /// </summary>
    public void ExitScope()
    {
        CurrentScope = _scopeStack.Count > 0 ? _scopeStack.Pop() : null;
    }

    /// <summary>
    /// Action : enregistre l'adresse d'utilisation d'un symbole.
    /// </summary>
    public void AddOccurrence(string symbolName, long address)
    {
        if (!_occurrences.TryGetValue(symbolName, out var occurrences))
        {
            occurrences = [];
            _occurrences[symbolName] = occurrences;
        }

        occurrences.Add(address);
    }

    public bool TryGetOccurrences(string symbolName, out List<long> occurrences) =>
        _occurrences.TryGetValue(symbolName, out occurrences!);

    /// <summary>
    /// Action : calcule le nom complet a utiliser lors de la definition d'un symbole.
    /// Donnees de sortie : le label prefixe par la portee courante, ou tel quel s'il est
    /// deja qualifie, global force, ou hors de toute portee.
    /// </summary>
    public string NameForDefinition(string label, bool forceGlobal)
    {
        if (forceGlobal || CurrentScope is null || label.Contains('!') || label.StartsWith('.'))
        {
            return label;
        }

        return $"{CurrentScope}!{label}";
    }

    /// <summary>
    /// Action : fournit, dans l'ordre de priorite, les noms possibles pour une reference.
    /// </summary>
    public IEnumerable<string> RelativeCandidates(string operand)
    {
        if (CurrentScope is not null)
        {
            yield return $"{CurrentScope}!{operand}";
        }

        yield return operand;
    }

    /// <summary>
    /// Action : remplace les references parentes "..!" par leur nom complet contextualise.
    /// Donnees d'entree : expression source telle qu'ecrite.
    /// Donnees de sortie : expression ou chaque "..!token" est resolu contre la portee parente.
    /// </summary>
    public string NormalizeScopedExpression(string expression)
    {
        const string parentPrefix = "..!";
        if (!expression.Contains(parentPrefix, StringComparison.Ordinal))
        {
            return expression;
        }

        var parentScope = _scopeStack.Count > 0 ? _scopeStack.Peek() : null;
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
    /// Action : verifie qu'une chaine est un nom de symbole simple, sans operateur ni prefixe.
    /// </summary>
    public static bool IsSimpleSymbolName(string value)
    {
        if (string.IsNullOrWhiteSpace(value) || value[0] is '!' or '.' or '$' or '\'' or '"' or '[' or '(')
        {
            return false;
        }

        return value.All(c => char.IsLetterOrDigit(c) || c == '_');
    }
}
