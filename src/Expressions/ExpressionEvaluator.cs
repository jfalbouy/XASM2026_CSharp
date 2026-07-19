namespace Xasm2026.Native.Expressions;

internal sealed class ExpressionEvaluator
{
    private readonly IReadOnlyDictionary<string, long> _symbols;
    private readonly string? _localScope;
    private readonly IReadOnlySet<string>? _reservedZero;
    private readonly long _locationCounter;

    /// <summary>
    /// Action : prepare un evaluateur d'expressions avec table des symboles et contexte local.
    /// Donnees d'entree : parametres de la signature (IReadOnlyDictionary<string, long> symbols, string? localScope = null,
    ///   IReadOnlySet<string>? reservedZero = null, long locationCounter = 0) et etat courant necessaire.
    /// Donnees de sortie : instance initialisee.
    /// reservedZero : identifiants reserves (mnemoniques de registres) qui valent 0 dans une
    ///   expression d'adressage et ne doivent pas etre signales comme symboles indefinis.
    /// locationCounter : valeur du compteur de localisation, rendue par l'operande "*".
    ///   Pendant de la variable globale lc du C, lue au moment de l'evaluation.
    /// </summary>
    public ExpressionEvaluator(
        IReadOnlyDictionary<string, long> symbols,
        string? localScope = null,
        IReadOnlySet<string>? reservedZero = null,
        long locationCounter = 0)
    {
        _symbols = symbols;
        _localScope = localScope;
        _reservedZero = reservedZero;
        _locationCounter = locationCounter;
    }

    /// <summary>
    /// Action : evalue une expression numerique assembleur.
    /// Donnees d'entree : parametres de la signature (string expression) et etat courant necessaire.
    /// Donnees de sortie : valeur long calculee par la procedure.
    /// </summary>
    public long Evaluate(string expression)
    {
        var parser = new Parser(expression, _symbols, _localScope, _reservedZero, _locationCounter);
        var value = Regular(parser.ParseExpression());
        Undefined = parser.Undefined;
        Referenced = parser.Referenced;
        DividedByZero = parser.DividedByZero;
        return value;
    }

    /// <summary>
    /// Noms rencontres lors de la derniere evaluation qui ne sont ni des symboles connus
    /// ni des constantes numeriques valides. Vide lorsque l'expression est entierement resolue.
    /// </summary>
    public IReadOnlyCollection<string> Undefined { get; private set; } = Array.Empty<string>();

    /// <summary>
    /// Symboles effectivement resolus lors de la derniere evaluation. Alimente la table des
    /// references croisees ; sans cela, seules les **definitions** seraient connues.
    /// </summary>
    public IReadOnlyCollection<string> Referenced { get; private set; } = Array.Empty<string>();

    /// <summary>
    /// Vrai si la derniere evaluation a rencontre une division ou un modulo par zero.
    /// Pendant de l'err 2 de mes.c : c'est l'appelant qui decide d'en faire une erreur
    /// fatale, car un diviseur symbolique vaut encore 0 en passe de resolution.
    /// </summary>
    public bool DividedByZero { get; private set; }

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
        private readonly long _locationCounter;
        private readonly List<string> _undefined = new();
        private readonly List<string> _referenced = new();
        private int _position;

        /// <summary>
        /// Jetons non resolus (ni symbole connu, ni nombre valide) collectes durant l'analyse.
        /// </summary>
        public IReadOnlyCollection<string> Undefined => _undefined;

        /// <summary>Symboles resolus au cours de l'analyse.</summary>
        public IReadOnlyCollection<string> Referenced => _referenced;

        /// <summary>
        /// Vrai si une division ou un modulo par zero a ete rencontre pendant l'analyse.
        /// </summary>
        public bool DividedByZero { get; private set; }

        /// <summary>
        /// Action : initialise le parseur recursif d'expression.
        /// Donnees d'entree : parametres de la signature (string text, IReadOnlyDictionary<string, long> symbols, string? localScope) et etat courant necessaire.
        /// Donnees de sortie : instance initialisee.
        /// </summary>
        public Parser(
            string text,
            IReadOnlyDictionary<string, long> symbols,
            string? localScope,
            IReadOnlySet<string>? reservedZero,
            long locationCounter)
        {
            _text = text;
            _symbols = symbols;
            _localScope = localScope;
            _reservedZero = reservedZero;
            _locationCounter = locationCounter;
        }

        /// <summary>
        /// Action : analyse les additions, soustractions et operations de plus haut niveau.
        /// Donnees d'entree : aucune donnee directe ; utilise l'etat courant de l'objet ou de l'application.
        /// Donnees de sortie : valeur long calculee par la procedure.
        /// </summary>
        public long ParseExpression() => ParseComparison();

        /// <summary>
        /// Action : analyse les comparaisons, niveau de precedence le plus faible.
        /// Donnees de sortie : 1 si la comparaison est vraie, 0 sinon.
        ///
        /// Ces operateurs n'existent pas dans le C historique (oprlevel_set s'arrete a "|") :
        /// ils sont ajoutes sous le niveau le plus faible, de sorte que "a+1 = b*2" se lise
        /// comme prevu sans parentheses. Le resultat 1/0 se combine avec IFEQ / IFNE.
        /// </summary>
        private long ParseComparison()
        {
            var value = ParseOr();
            while (true)
            {
                SkipSpaces();

                // Les formes a deux caracteres sont testees en premier, et "<" / ">" ne sont
                // acceptes que s'ils ne sont pas le debut d'un decalage "<<" / ">>".
                if (TryRead("<=")) { value = value <= ParseOr() ? 1 : 0; }
                else if (TryRead(">=")) { value = value >= ParseOr() ? 1 : 0; }
                else if (TryRead("<>")) { value = value != ParseOr() ? 1 : 0; }
                else if (TryRead("==")) { value = value == ParseOr() ? 1 : 0; }
                else if (Peek(0) == '<' && Peek(1) != '<') { _position++; value = value < ParseOr() ? 1 : 0; }
                else if (Peek(0) == '>' && Peek(1) != '>') { _position++; value = value > ParseOr() ? 1 : 0; }
                else if (Peek(0) == '=') { _position++; value = value == ParseOr() ? 1 : 0; }
                else { return value; }
            }
        }

        /// <summary>
        /// Action : analyse le OU binaire, niveau de precedence le plus faible.
        /// </summary>
        private long ParseOr()
        {
            var value = ParseXor();
            while (true)
            {
                SkipSpaces();
                if (TryRead('|'))
                {
                    value |= ParseXor();
                }
                else
                {
                    return value;
                }
            }
        }

        /// <summary>
        /// Action : analyse le OU exclusif, entre le OU et le ET comme en C.
        /// </summary>
        private long ParseXor()
        {
            var value = ParseAnd();
            while (true)
            {
                SkipSpaces();
                if (TryRead('^'))
                {
                    value ^= ParseAnd();
                }
                else
                {
                    return value;
                }
            }
        }

        /// <summary>
        /// Action : analyse le ET binaire.
        /// </summary>
        private long ParseAnd()
        {
            var value = ParseModulo();
            while (true)
            {
                SkipSpaces();
                if (TryRead('&'))
                {
                    value &= ParseModulo();
                }
                else
                {
                    return value;
                }
            }
        }

        /// <summary>
        /// Action : analyse le modulo.
        ///
        /// Attention : dans ce langage le modulo lie **moins fort** que l'addition
        /// (niveau 5 contre 6 dans oprlevel_set de init.c), contrairement au C ou il a la
        /// precedence de la multiplication. "1+2%3" vaut donc (1+2)%3, et non 1+(2%3).
        /// </summary>
        private long ParseModulo()
        {
            var value = ParseShift();
            while (true)
            {
                SkipSpaces();
                if (TryRead('%'))
                {
                    var divisor = ParseShift();
                    if (divisor == 0)
                    {
                        DividedByZero = true;
                        value = 0;
                    }
                    else
                    {
                        value -= value / divisor * divisor;
                    }
                }
                else
                {
                    return value;
                }
            }
        }

        /// <summary>
        /// Action : analyse les decalages binaires.
        ///
        /// Places entre le modulo et l'addition, ils lient donc moins fort que "+" : comme en
        /// C, "1 << 2+3" vaut "1 << 5".
        /// </summary>
        private long ParseShift()
        {
            var value = ParseAdditive();
            while (true)
            {
                SkipSpaces();
                if (TryRead("<<"))
                {
                    value <<= (int)ParseAdditive();
                }
                else if (TryRead(">>"))
                {
                    value >>= (int)ParseAdditive();
                }
                else
                {
                    return value;
                }
            }
        }

        /// <summary>
        /// Action : analyse les additions et soustractions.
        /// </summary>
        private long ParseAdditive()
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
                    if (divisor == 0)
                    {
                        DividedByZero = true;
                        value = 0;
                    }
                    else
                    {
                        value /= divisor;
                    }
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

            // Complement binaire. Le repliage sur 20 bits est fait par Regular en fin
            // d'evaluation : "~0" vaut donc 0FFFFFh.
            if (TryRead('~'))
            {
                return ~ParseTerm();
            }

            // eval.c : case '*' avec set_x == FALSE. En position de terme, "*" designe le
            // compteur de localisation ; entre deux valeurs, c'est ParseProduct qui l'a deja
            // consomme comme operateur de multiplication. Les deux emplois ne peuvent donc
            // pas etre confondus.
            if (TryRead('*'))
            {
                return _locationCounter;
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

            // Extraction d'octets, calquee sur xlow / xmid / xhigh de misc.c : une adresse
            // 20 bits se decompose en trois octets, exactement comme l'emet DP.
            switch (token.ToUpperInvariant())
            {
                case "LOW": return ParseTerm() % 256;
                case "MID": return ParseTerm() / 256 % 256;
                case "HIGH": return ParseTerm() / 65536 % 256;
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
                _referenced.Add($"{_localScope}!{token}");
                return localValue;
            }

            if (_symbols.TryGetValue(token, out var qualifiedValue))
            {
                _referenced.Add(token);
                return qualifiedValue;
            }

            if (!_symbols.ContainsKey(token) && token.Contains('!'))
            {
                token = token[(token.LastIndexOf('!') + 1)..];
            }
            if (_symbols.TryGetValue(token, out var symbolValue))
            {
                _referenced.Add(token);
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
                if (char.IsWhiteSpace(c) || c is '+' or '-' or '*' or '/' or '%' or '&' or '|'
                    or '^' or '~' or '<' or '>' or '=' or ',' or ')')
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
        /// Donnees de sortie : booleen de reussite et valeur convertie.
        ///
        /// Regle reprise telle quelle de eval.c : un nombre commence obligatoirement par un
        /// chiffre ou par "$" (sinon c'est un nom de symbole), et c'est le **dernier
        /// caractere** qui fixe la base : B=2, O=8, D=10, H=16. Sans suffixe reconnu, la base
        /// est 10 et ce dernier caractere est un chiffre a part entiere. Le souligne "_" est
        /// un separateur visuel ignore. Un chiffre superieur ou egal a la base est refuse
        /// (err 23 du C) : le jeton n'est alors pas un nombre valide.
        /// </summary>
        private static bool TryParseNumber(string token, out long value)
        {
            value = 0;
            token = token.Trim();
            if (token.Length == 0)
            {
                return false;
            }

            // "$FF00" est la notation hexadecimale prefixee : eval.c la reecrit en "0FF00H".
            if (token[0] == '$')
            {
                return TryParseDigits(token[1..], 16, out value);
            }

            if (!char.IsAsciiDigit(token[0]))
            {
                return false;
            }

            var radix = char.ToUpperInvariant(token[^1]) switch
            {
                'B' => 2,
                'O' => 8,
                'D' => 10,
                'H' => 16,
                _ => 0,
            };

            // Pas de suffixe : base 10, et le dernier caractere fait partie des chiffres.
            return radix == 0
                ? TryParseDigits(token, 10, out value)
                : TryParseDigits(token[..^1], radix, out value);
        }

        /// <summary>
        /// Action : accumule les chiffres d'un jeton dans la base donnee.
        /// Donnees d'entree : chiffres sans suffixe, base attendue.
        /// Donnees de sortie : booleen de reussite et valeur accumulee.
        /// </summary>
        private static bool TryParseDigits(string digits, int radix, out long value)
        {
            value = 0;
            var seen = false;
            foreach (var c in digits)
            {
                if (c == '_')
                {
                    continue;
                }

                int digit;
                if (char.IsAsciiDigit(c))
                {
                    digit = c - '0';
                }
                else if (c is >= 'A' and <= 'F')
                {
                    digit = c - 'A' + 10;
                }
                else if (c is >= 'a' and <= 'f')
                {
                    digit = c - 'a' + 10;
                }
                else
                {
                    return false;
                }

                if (digit >= radix)
                {
                    return false;
                }

                value = value * radix + digit;
                seen = true;
            }

            return seen;
        }


        /// <summary>
        /// Action : consomme un caractere attendu si present.
        /// Donnees d'entree : parametres de la signature (char expected) et etat courant necessaire.
        /// Donnees de sortie : booleen indiquant si le traitement a reussi ou si la condition est verifiee.
        /// </summary>
        /// <summary>
        /// Action : lit le caractere a la position courante decalee, sans consommer.
        /// Donnees de sortie : le caractere, ou '\0' au-dela de la fin.
        /// </summary>
        private char Peek(int offset)
        {
            var index = _position + offset;
            return index < _text.Length ? _text[index] : '\0';
        }

        /// <summary>
        /// Action : consomme un operateur de plusieurs caracteres s'il est present.
        /// </summary>
        private bool TryRead(string expected)
        {
            if (_position + expected.Length > _text.Length)
            {
                return false;
            }

            for (var i = 0; i < expected.Length; i++)
            {
                if (_text[_position + i] != expected[i])
                {
                    return false;
                }
            }

            _position += expected.Length;
            return true;
        }

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
