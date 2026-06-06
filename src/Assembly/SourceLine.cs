namespace Xasm2026.Native.Assembly;

internal sealed class SourceLine
{
    /// <summary>
    /// Action : cree une representation analysee d'une ligne assembleur.
    /// Donnees d'entree : parametres de la signature (string? label, string mnemonic, string operandText) et etat courant necessaire.
    /// Donnees de sortie : instance initialisee.
    /// </summary>
    private SourceLine(string? label, string mnemonic, string operandText)
    {
        Label = label;
        Mnemonic = mnemonic;
        OperandText = operandText;
    }

    public string? Label { get; }
    public string Mnemonic { get; }
    public string OperandText { get; }
    public bool IsEmpty => Label is null && string.IsNullOrWhiteSpace(Mnemonic);

    /// <summary>
    /// Action : decoupe une ligne source en etiquette, mnemonique et operandes.
    /// Donnees d'entree : parametres de la signature (string rawLine) et etat courant necessaire.
    /// Donnees de sortie : valeur de type SourceLine produite par la procedure.
    /// </summary>
    public static SourceLine Parse(string rawLine)
    {
        var clean = StripComment(rawLine).TrimEnd('\u001A').Trim();
        if (string.IsNullOrWhiteSpace(clean))
        {
            return new SourceLine(null, string.Empty, string.Empty);
        }

        string? label = null;
        var working = clean;
        var colon = FindColonOutsideQuote(working);
        if (colon >= 0 && !char.IsWhiteSpace(working[0]))
        {
            label = working[..colon].Trim();
            working = working[(colon + 1)..].TrimStart();
        }

        if (string.IsNullOrWhiteSpace(working))
        {
            return new SourceLine(label, string.Empty, string.Empty);
        }

        var firstSpace = FindFirstSpace(working);
        if (firstSpace < 0)
        {
            return new SourceLine(label, working.Trim(), string.Empty);
        }

        var mnemonic = working[..firstSpace].Trim();
        var operandText = working[firstSpace..].Trim();
        return new SourceLine(label, mnemonic, operandText);
    }

    /// <summary>
    /// Action : trouve la premiere separation hors contexte particulier.
    /// Donnees d'entree : parametres de la signature (string value) et etat courant necessaire.
    /// Donnees de sortie : valeur int calculee par la procedure.
    /// </summary>
    private static int FindFirstSpace(string value)
    {
        for (var i = 0; i < value.Length; i++)
        {
            if (char.IsWhiteSpace(value[i]))
            {
                return i;
            }
        }

        return -1;
    }

    /// <summary>
    /// Action : trouve un deux-points d'etiquette en ignorant les chaines.
    /// Donnees d'entree : parametres de la signature (string value) et etat courant necessaire.
    /// Donnees de sortie : valeur int calculee par la procedure.
    /// </summary>
    private static int FindColonOutsideQuote(string value)
    {
        var quoted = false;
        for (var i = 0; i < value.Length; i++)
        {
            if (value[i] == '\'')
            {
                quoted = !quoted;
            }
            else if (value[i] == ':' && !quoted)
            {
                return i;
            }
        }

        return -1;
    }

    /// <summary>
    /// Action : supprime la partie commentaire d'une ligne source.
    /// Donnees d'entree : parametres de la signature (string value) et etat courant necessaire.
    /// Donnees de sortie : valeur string calculee par la procedure.
    /// </summary>
    private static string StripComment(string value)
    {
        var quoted = false;
        for (var i = 0; i < value.Length; i++)
        {
            if (value[i] == '\'')
            {
                quoted = !quoted;
            }
            else if (value[i] == ';' && !quoted)
            {
                return value[..i];
            }
        }

        return value;
    }
}
