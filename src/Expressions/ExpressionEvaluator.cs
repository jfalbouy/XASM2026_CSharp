namespace Xasm2026.Native.Expressions;

internal sealed class ExpressionEvaluator
{
    private readonly IReadOnlyDictionary<string, long> _symbols;
    private readonly string? _localScope;
    private readonly IReadOnlySet<string>? _reservedZero;

    /// <summary>
    /// Action : prepare un evaluateur d'expressions avec table des symboles et contexte local.
    /// Donnees d'entree : parametres de la signature (IReadOnlyDictionary<string, long> symbols, string? localScope = null,
    ///   IReadOnlySet<string>? reservedZero = null) et etat courant necessaire.
    /// Donnees de sortie : instance initialisee.
    /// reservedZero : identifiants reserves (mnemoniques de registres) qui valent 0 dans une
    ///   expression d'adressage et ne doivent pas etre signales comme symboles indefinis.
    /// </summary>
    public ExpressionEvaluator(
        IReadOnlyDictionary<string, long> symbols,
        string? localScope = null,
        IReadOnlySet<string>? reservedZero = null)
    {
        _symbols = symbols;
        _localScope = localScope;
        _reservedZero = reservedZero;
    }

    /// <summary>
    /// Action : evalue une expression numerique assembleur.
    /// Donnees d'entree : parametres de la signature (string expression) et etat courant necessaire.
    /// Donnees de sortie : valeur long calculee par la procedure.
    /// </summary>
    public long Evaluate(string expression)
    {
        var parser = new Parser(expression, _symbols, _localScope, _reservedZero);
        var value = Regular(parser.ParseExpression());
        Undefined = parser.Undefined;
        return value;
    }

    /// <summary>
    /// Noms rencontres lors de la derniere evaluation qui ne sont ni des symboles connus
    /// ni des constantes numeriques valides. Vide lorsque l'expression est entierement resolue.
    /// </summary>
    public IReadOnlyCollection<string> Undefined { get; private set; } = Array.Empty<string>();

    /// <summary>
    /// Action : borne une valeur au format entier 24 bits utilise par l'assembleur.
    /// Donnees d'entree : parametres de la signature (long value) et etat courant necessaire.
    /// Donnees de sortie : valeur long calculee par la procedure.
    /// </summary>
    private static long Regular(long value)
    {
        return value < 0 ? 1_048_575L + (value + 1) : value;
    }

    private sealed class Parser
    {
        private readonly string _text;
        private readonly IReadOnlyDictionary<string, long> _symbols;
        private readonly string? _localScope;
        private readonly IReadOnlySet<string>? _reservedZero;
        private readonly List<string> _undefined = new();
        private int _position;

        /// <summary>
        /// Jetons non resolus (ni symbole connu, ni nombre valide) collectes durant l'analyse.
        /// </summary>
        public IReadOnlyCollection<string> Undefined => _undefined;

        /// <summary>
        /// Action : initialise le parseur recursif d'expression.
        /// Donnees d'entree : parametres de la signature (string text, IReadOnlyDictionary<string, long> symbols, string? localScope) et etat courant necessaire.
        /// Donnees de sortie : instance initialisee.
        /// </summary>
        public Parser(
            string text,
            IReadOnlyDictionary<string, long> symbols,
            string? localScope,
            IReadOnlySet<string>? reservedZero)
        {
            _text = text;
            _symbols = symbols;
            _localScope = localScope;
            _reservedZero = reservedZero;
        }

        /// <summary>
        /// Action : analyse les additions, soustractions et operations de plus haut niveau.
        /// Donnees d'entree : aucune donnee directe ; utilise l'etat courant de l'objet ou de l'application.
        /// Donnees de sortie : valeur long calculee par la procedure.
        /// </summary>
        public long ParseExpression()
        {
            var value = ParseProduct();
            while (true)
            {
                SkipSpaces();
                if (TryRead('+'))
                {
                    value += ParseProduct();
                }
                else if (TryRead('-'))
                {
                    value -= ParseProduct();
                }
                else
                {
                    return value;
                }
            }
        }

        /// <summary>
        /// Action : analyse les multiplications, divisions et modulo.
        /// Donnees d'entree : aucune donnee directe ; utilise l'etat courant de l'objet ou de l'application.
        /// Donnees de sortie : valeur long calculee par la procedure.
        /// </summary>
        private long ParseProduct()
        {
            var value = ParseTerm();
            while (true)
            {
                SkipSpaces();
                if (TryRead('*'))
                {
                    value *= ParseTerm();
                }
                else if (TryRead('/'))
                {
                    var divisor = ParseTerm();
                    value = divisor == 0 ? 0 : value / divisor;
                }
                else
                {
                    return value;
                }
            }
        }

        /// <summary>
        /// Action : analyse un terme numerique, symbole, caractere, expression parenthesee ou unaire.
        /// Donnees d'entree : aucune donnee directe ; utilise l'etat courant de l'objet ou de l'application.
        /// Donnees de sortie : valeur long calculee par la procedure.
        /// </summary>
        private long ParseTerm()
        {
            SkipSpaces();
            if (TryRead('('))
            {
                var value = ParseExpression();
                SkipSpaces();
                _ = TryRead(')');
                return value;
            }

            if (TryRead('-'))
            {
                return -ParseTerm();
            }

            if (_position >= _text.Length)
            {
                return 0;
            }

            if (_text[_position] == '\'')
            {
                return ParseCharacter();
            }

            var token = ReadToken();
            if (string.IsNullOrWhiteSpace(token))
            {
                return 0;
            }

            var isGlobal = token.StartsWith('!');
            token = token.TrimStart('!');
            while (token.StartsWith('.'))
            {
                token = token[1..];
            }

            token = token.TrimStart('!');
            if (!isGlobal && _localScope is not null && !token.Contains('!') && _symbols.TryGetValue($"{_localScope}!{token}", out var localValue))
            {
                return localValue;
            }

            if (_symbols.TryGetValue(token, out var qualifiedValue))
            {
                return qualifiedValue;
            }

            if (!_symbols.ContainsKey(token) && token.Contains('!'))
            {
                token = token[(token.LastIndexOf('!') + 1)..];
            }
            if (_symbols.TryGetValue(token, out var symbolValue))
            {
                return symbolValue;
            }

            if (TryParseNumber(token, out var number))
            {
                return number;
            }

            // Mnemonique de registre servant de base d'adressage : vaut 0 dans l'expression
            // (sa contribution est encodee dans l'opcode), ce n'est pas un symbole indefini.
            if (_reservedZero is not null && _reservedZero.Contains(token))
            {
                return 0;
            }

            // Ni symbole connu, ni constante numerique : reference non resolue.
            if (!string.IsNullOrEmpty(token))
            {
                _undefined.Add(token);
            }

            return 0;
        }

        /// <summary>
        /// Action : lit une constante caractere assembleur.
        /// Donnees d'entree : aucune donnee directe ; utilise l'etat courant de l'objet ou de l'application.
        /// Donnees de sortie : valeur long calculee par la procedure.
        /// </summary>
        private long ParseCharacter()
        {
            _position++;
            if (_position < _text.Length - 1 && _text[_position] == '\'' && _text[_position + 1] == '\'')
            {
                _position += 2;
                return '\'';
            }

            long value = 0;
            while (_position < _text.Length && _text[_position] != '\'')
            {
                value = _text[_position];
                _position++;
            }

            if (_position < _text.Length && _text[_position] == '\'')
            {
                _position++;
            }

            return value;
        }

        /// <summary>
        /// Action : lit le prochain jeton lexical de l'expression.
        /// Donnees d'entree : aucune donnee directe ; utilise l'etat courant de l'objet ou de l'application.
        /// Donnees de sortie : valeur string calculee par la procedure.
        /// </summary>
        private string ReadToken()
        {
            var start = _position;
            while (_position < _text.Length)
            {
                var c = _text[_position];
                if (char.IsWhiteSpace(c) || c is '+' or '-' or '*' or '/' or ',' or ')')
                {
                    break;
                }

                _position++;
            }

            return _text[start.._position].Trim();
        }

        /// <summary>
        /// Action : convertit un jeton numerique en valeur entiere.
        /// Donnees d'entree : parametres de la signature (string token) et etat courant necessaire.
        /// Donnees de sortie : valeur long calculee par la procedure.
        /// </summary>
        private static bool TryParseNumber(string token, out long value)
        {
            value = 0;
            token = token.Trim();
            if (token.Length == 0)
            {
                return false;
            }

            if (token[0] == '$')
            {
                var hex = token[1..];
                if (hex.Length > 0 && IsHexToken(hex))
                {
                    value = Convert.ToInt64(hex, 16);
                    return true;
                }

                return false;
            }

            if (token.Length > 1 &&
                (token[^1] is 'H' or 'h') &&
                IsHexToken(token[..^1]))
            {
                value = Convert.ToInt64(token[..^1], 16);
                return true;
            }

            return long.TryParse(token, out value);
        }

        /// <summary>
        /// Action : detecte un jeton hexadecimal implicite.
        /// Donnees d'entree : parametres de la signature (string token) et etat courant necessaire.
        /// Donnees de sortie : booleen indiquant si le traitement a reussi ou si la condition est verifiee.
        /// </summary>
        private static bool IsHexToken(string token)
        {
            return token.Length > 0 && token.All(c =>
                c is >= '0' and <= '9' ||
                c is >= 'a' and <= 'f' ||
                c is >= 'A' and <= 'F');
        }

        /// <summary>
        /// Action : consomme un caractere attendu si present.
        /// Donnees d'entree : parametres de la signature (char expected) et etat courant necessaire.
        /// Donnees de sortie : booleen indiquant si le traitement a reussi ou si la condition est verifiee.
        /// </summary>
        private bool TryRead(char expected)
        {
            if (_position < _text.Length && _text[_position] == expected)
            {
                _position++;
                return true;
            }

            return false;
        }

        /// <summary>
        /// Action : avance au-dela des espaces.
        /// Donnees d'entree : aucune donnee directe ; utilise l'etat courant de l'objet ou de l'application.
        /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
        /// </summary>
        private void SkipSpaces()
        {
            while (_position < _text.Length && char.IsWhiteSpace(_text[_position]))
            {
                _position++;
            }
        }
    }
}
