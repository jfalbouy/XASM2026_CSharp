using Xasm2026.Native.Core;

namespace Xasm2026.Native.Assembly;

// Preprocesseur : lecture des sources, resolution des INCLUDE (avec detection de cycle),
// expansion des macros et gestion des marqueurs de fin de fichier inclus.
// Extrait du noyau NativeAssembler ; comportement inchange.
internal sealed partial class NativeAssembler
{
    /// <summary>
    /// Action : lit le source principal et developpe les fichiers inclus.
    /// Donnees d'entree : parametres de la signature (string sourceFile) et etat courant necessaire.
    /// Donnees de sortie : collection calculee par la procedure.
    /// </summary>
    private List<SourceRef> ReadSourceWithIncludes(string sourceFile)
    {
        _dependencies.Clear();
        _includeStack.Clear();
        var baseDirectory = Path.GetDirectoryName(Path.GetFullPath(sourceFile)) ?? Environment.CurrentDirectory;
        return ReadSourceWithIncludes(sourceFile, baseDirectory, isTopLevel: true);
    }

    /// <summary>
    /// Action : lit le source principal et developpe les fichiers inclus.
    /// Donnees d'entree : parametres de la signature (string sourceFile, string baseDirectory, bool isTopLevel) et etat courant necessaire.
    /// Donnees de sortie : collection calculee par la procedure.
    /// </summary>
    private List<SourceRef> ReadSourceWithIncludes(string sourceFile, string baseDirectory, bool isTopLevel)
    {
        var path = Path.IsPathRooted(sourceFile) ? sourceFile : Path.Combine(baseDirectory, sourceFile);
        var fullPath = Path.GetFullPath(path);

        // Detection de cycle : un fichier deja en cours d'inclusion (directement ou via une
        // chaine) provoquerait une recursion infinie. On le signale explicitement.
        if (!_includeStack.Add(fullPath))
        {
            var chain = string.Join(" -> ", _includeStack.Append(fullPath).Select(Path.GetFileName));
            throw new InvalidOperationException($"inclusion cyclique detectee: {chain}");
        }

        try
        {
            var lines = new List<SourceRef>();
            var fileName = Path.GetFileName(path);

            // genop.c case 66 : a la fermeture d'un fichier inclus, le C compare la profondeur
            // des piles LOCAL et PRE_PUSH a celle observee au moment du INCLUDE (err 33 et 38).
            // On compte ici les directives propres au fichier ; un fichier imbrique equilibre
            // contribue zero, et s'il ne l'est pas il produit son propre avertissement.
            var localDepth = 0;
            var preDepth = 0;
            var fileLineCount = 0;
            string? lastLine = null;

            foreach (var rawLine in File.ReadAllLines(path))
            {
                fileLineCount++;
                lastLine = rawLine;
                var line = SourceLine.Parse(rawLine);
                switch (line.Mnemonic.ToUpperInvariant())
                {
                    case "LOCAL": localDepth++; break;
                    case "ENDL": localDepth--; break;
                    case "PRE_PUSH": preDepth++; break;
                    case "PRE_POP": preDepth--; break;
                }

                if (line.Mnemonic.Equals("INCLUDE", StringComparison.OrdinalIgnoreCase))
                {
                    var includeName = line.OperandText.Trim().Trim('\'', '"');
                    _dependencies.Add(includeName);
                    lines.Add(new SourceRef(rawLine, fileName, fileLineCount));
                    lines.AddRange(ReadSourceWithIncludes(includeName, Path.GetDirectoryName(path) ?? baseDirectory, isTopLevel: false));
                }
                else if (!isTopLevel && line.Mnemonic.Equals("END", StringComparison.OrdinalIgnoreCase))
                {
                    lines.Add(new SourceRef(IncludedEndMarker + rawLine, fileName, fileLineCount));
                }
                else
                {
                    lines.Add(new SourceRef(rawLine, fileName, fileLineCount));
                }
            }

            if (!isTopLevel)
            {
                // Le desequilibre n'est constate qu'a la fermeture du fichier : on rattache
                // l'avertissement a sa derniere ligne, comme le C dont current_file->lines
                // vaut alors le nombre de lignes lues.
                var lastColumn = lastLine is null ? 0 : ColumnOf(lastLine, SourceLine.Parse(lastLine));

                if (localDepth != 0)
                {
                    _warnings.Add(new AssemblyWarning(
                        fileName, fileLineCount, lastColumn, "Warning: LOCAL and ENDL not match in included file"));
                }

                if (preDepth != 0)
                {
                    _warnings.Add(new AssemblyWarning(
                        fileName, fileLineCount, lastColumn, "Warning: PRE_PUSH and PRE_POP not match"));
                }
            }

            return lines;
        }
        finally
        {
            _includeStack.Remove(fullPath);
        }
    }

    /// <summary>
    /// Action : developpe les macros et prepare les lignes source internes.
    /// Donnees d'entree : parametres de la signature (IReadOnlyList<SourceRef> sourceLines) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void ExpandSource(IReadOnlyList<SourceRef> sourceLines)
    {
        _macros.Clear();
        _definedSymbols.Clear();
        ExpandSourceBlock(sourceLines, 0, sourceLines.Count, _expandedLines, expandMacroDefinitions: true);
    }

    /// <summary>
    /// Action : traite un bloc source en detectant definitions et appels de macros.
    /// Donnees d'entree : parametres de la signature (IReadOnlyList<SourceRef> sourceLines, int start, int end, List<SourceRef> output, bool expandMacroDefinitions) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void ExpandSourceBlock(
        IReadOnlyList<SourceRef> sourceLines,
        int start,
        int end,
        List<SourceRef> output,
        bool expandMacroDefinitions)
    {
        var conditions = new Stack<bool>();
        var active = true;
        for (var i = 0; i < sourceLines.Count; i++)
        {
            if (i < start || i >= end)
            {
                continue;
            }

            var origin = sourceLines[i];
            var line = SourceLine.Parse(StripInternalMarker(origin.Text));
            var mnemonic = line.Mnemonic.ToUpperInvariant();

            if (active && line.Label is not null && mnemonic == "EQU")
            {
                _symbols[line.Label] = Eval(line.OperandText);
            }

            if (mnemonic is "IFDEF" or "IFNDEF")
            {
                conditions.Push(active);
                var defined = _definedSymbols.Contains(line.OperandText.Trim());
                active = active && (mnemonic == "IFDEF" ? defined : !defined);
                continue;
            }

            if (mnemonic is "IFEQ" or "IFNE" or "IFGT" or "IFLT")
            {
                conditions.Push(active);
                var value = Eval(line.OperandText);
                active = active && mnemonic switch
                {
                    "IFEQ" => value == 0,
                    "IFNE" => value != 0,
                    "IFGT" => value > 0,
                    _ => value < 0,
                };
                continue;
            }

            if (mnemonic == "ELSE")
            {
                if (conditions.TryPeek(out var parent))
                {
                    active = parent && !active;
                }
                continue;
            }

            if (mnemonic == "ENDIF")
            {
                if (conditions.TryPop(out var previous))
                {
                    active = previous;
                }
                continue;
            }

            if (!active)
            {
                continue;
            }

            if (mnemonic == "DEF")
            {
                _definedSymbols.Add(line.OperandText.Trim());
                output.Add(sourceLines[i]);
                continue;
            }

            if (mnemonic == "UNDEF")
            {
                _definedSymbols.Remove(line.OperandText.Trim());
                output.Add(sourceLines[i]);
                continue;
            }

            if (mnemonic == "REPEAT")
            {
            var count = (int)Eval(line.OperandText);
            var block = new List<SourceRef>();
            i++;
                while (i < end)
            {
                var blockLine = SourceLine.Parse(StripInternalMarker(sourceLines[i].Text));
                if (blockLine.Mnemonic.Equals("ENDR", StringComparison.OrdinalIgnoreCase))
                {
                    break;
                }

                block.Add(sourceLines[i]);
                i++;
            }

            for (var repeat = 0; repeat < count; repeat++)
            {
                    ExpandSourceBlock(block, 0, block.Count, output, expandMacroDefinitions: false);
                }
                continue;
            }

            if (mnemonic == "MACRO")
            {
                var header = SplitOperands(line.OperandText);
                if (header.Length == 0)
                {
                    throw new InvalidOperationException($"MACRO sans nom: {origin.Text.Trim()}");
                }

                var body = new List<SourceRef>();
                i++;
                while (i < end)
                {
                    var blockLine = SourceLine.Parse(StripInternalMarker(sourceLines[i].Text));
                    if (blockLine.Mnemonic.Equals("ENDM", StringComparison.OrdinalIgnoreCase))
                    {
                        break;
                    }

                    body.Add(sourceLines[i]);
                    i++;
                }

                if (expandMacroDefinitions)
                {
                    _macros[header[0].Trim()] = new MacroDefinition(
                        header[0].Trim(),
                        header.Skip(1).Select(x => x.Trim()).ToArray(),
                        body);
                }
                continue;
            }

            if (_macros.TryGetValue(mnemonic, out var macro))
            {
                var args = SplitOperands(line.OperandText).Select(x => x.Trim()).ToArray();
                foreach (var macroLine in macro.Body)
                {
                    // Les lignes issues d'une macro sont rattachees au **site d'appel** et non
                    // au corps de la definition : c'est la ligne que l'utilisateur doit corriger,
                    // et c'est aussi ce que suit le C, dont current_file->lines vaut la ligne
                    // en cours de lecture au moment ou la macro est rejouee.
                    output.Add(origin with
                    {
                        Text = ExpandMacroLine(macroLine.Text, macro.Arguments, args),
                    });
                }
                continue;
            }

            output.Add(sourceLines[i]);
        }
    }

    /// <summary>
    /// Action : remplace les arguments formels dans une ligne de macro.
    /// Donnees d'entree : parametres de la signature (string line, string[] names, string[] values) et etat courant necessaire.
    /// Donnees de sortie : valeur string calculee par la procedure.
    /// </summary>
    private static string ExpandMacroLine(string line, string[] names, string[] values)
    {
        var expanded = line;
        for (var i = 0; i < values.Length; i++)
        {
            expanded = expanded.Replace($"@{i + 1}", values[i], StringComparison.OrdinalIgnoreCase);
        }

        for (var i = 0; i < names.Length && i < values.Length; i++)
        {
            if (!string.IsNullOrWhiteSpace(names[i]))
            {
                expanded = expanded.Replace(names[i], values[i], StringComparison.OrdinalIgnoreCase);
            }
        }

        return expanded;
    }

    /// <summary>
    /// Action : remplace un identifiant sans toucher les fragments d'autres noms.
    /// Donnees d'entree : parametres de la signature (string source, string name, string value) et etat courant necessaire.
    /// Donnees de sortie : valeur string calculee par la procedure.
    /// </summary>
    private static string ReplaceIdentifier(string source, string name, string value)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            return source;
        }

        var result = new System.Text.StringBuilder(source.Length);
        var index = 0;
        while (index < source.Length)
        {
            var found = source.IndexOf(name, index, StringComparison.OrdinalIgnoreCase);
            if (found < 0)
            {
                result.Append(source, index, source.Length - index);
                break;
            }

            var beforeOk = found == 0 || !IsIdentifierChar(source[found - 1]);
            var after = found + name.Length;
            var afterOk = after >= source.Length || !IsIdentifierChar(source[after]);
            result.Append(source, index, found - index);
            result.Append(beforeOk && afterOk ? value : source.Substring(found, name.Length));
            index = after;
        }

        return result.ToString();
    }

    /// <summary>
    /// Action : indique si un caractere appartient a un identifiant assembleur.
    /// Donnees d'entree : parametres de la signature (char c) et etat courant necessaire.
    /// Donnees de sortie : booleen indiquant si le traitement a reussi ou si la condition est verifiee.
    /// </summary>
    private static bool IsIdentifierChar(char c)
    {
        return char.IsLetterOrDigit(c) || c is '_' or '!';
    }

    /// <summary>
    /// Action : detecte le marqueur interne de fin d'include.
    /// Donnees d'entree : parametres de la signature (string line) et etat courant necessaire.
    /// Donnees de sortie : booleen indiquant si le traitement a reussi ou si la condition est verifiee.
    /// </summary>
    private static bool IsIncludedEnd(string line)
    {
        return line.Length > 0 && line[0] == IncludedEndMarker;
    }

    /// <summary>
    /// Action : retire les marqueurs internes ajoutes pendant le pretraitement.
    /// Donnees d'entree : parametres de la signature (string line) et etat courant necessaire.
    /// Donnees de sortie : valeur string calculee par la procedure.
    /// </summary>
    private static string StripInternalMarker(string line)
    {
        return IsIncludedEnd(line) ? line[1..] : line;
    }
}
