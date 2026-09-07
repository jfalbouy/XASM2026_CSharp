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
    private List<SourceRef> ReadSourceWithIncludes(
        string sourceFile,
        string baseDirectory,
        bool isTopLevel,
        IReadOnlyList<string>? args = null)
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
                    // genop.c case 76 : INCLUDE fichier[,arg0,...,arg9]. Les expressions
                    // d'arguments sont transmises telles quelles, apres substitution des
                    // arguments du fichier courant pour qu'un @n imbrique reste correct.
                    var includeParts = SplitOperands(line.OperandText);
                    var includeName = includeParts[0].Trim().Trim('\'', '"');
                    var includeArgs = includeParts
                        .Skip(1)
                        .Select(x => SubstituteArguments(x.Trim(), args))
                        .ToArray();
                    _dependencies.Add(includeName);
                    lines.Add(new SourceRef(rawLine, fileName, fileLineCount, args));
                    lines.AddRange(ReadSourceWithIncludes(
                        includeName,
                        Path.GetDirectoryName(path) ?? baseDirectory,
                        isTopLevel: false,
                        includeArgs));
                }
                else if (!isTopLevel && line.Mnemonic.Equals("END", StringComparison.OrdinalIgnoreCase))
                {
                    lines.Add(new SourceRef(IncludedEndMarker + rawLine, fileName, fileLineCount, args));
                }
                else
                {
                    lines.Add(new SourceRef(rawLine, fileName, fileLineCount, args));
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
        _macrosInExpansion.Clear();
        _macroDepth = 0;
        _exitMacroRequested = false;

        // Le preprocesseur ouvre et referme des portees LOCAL : il part donc d'un etat
        // propre, comme le fait chaque passe.
        _anonymousScopeCounter = 0;
        _symbols.ResetScopes();
        ExpandSourceBlock(sourceLines, 0, sourceLines.Count, _expandedLines, expandMacroDefinitions: true);
        RewriteStructuredBlocks(_expandedLines);
    }

    /// <summary>
    /// Action : transforme les blocs structures { } et leurs cibles continue/break en
    /// etiquettes synthetiques, sur la liste deja aplatie.
    /// Donnees d'entree : la liste des lignes developpees (modifiee sur place).
    /// Donnees de sortie : aucune ; { et } deviennent des etiquettes, continue/break des
    /// references vers, respectivement, le debut et la fin du bloc englobant le plus proche.
    ///
    /// Un bloc s'ecrit :
    ///     {
    ///         ...            ; continue  -> reboucle au debut du bloc
    ///         jrnz continue
    ///         jrz  break     ; break     -> sort juste apres la }
    ///     }
    /// continue et break ne sont PAS des etiquettes : ce sont des cibles reservees, resolues
    /// par la structure du bloc. La substitution n'a lieu qu'a l'interieur d'un bloc, si bien
    /// qu'une source qui definit une vraie etiquette "continue:" ou "break:" hors de tout bloc
    /// (SAMPLE2, COMPILE.S) n'est pas affectee — et aucune source du corpus n'emploie { }, donc
    /// cette reecriture est un no-op sur tous les goldens. Purement additif.
    ///
    /// La transformation a lieu une seule fois sur la liste aplatie, avant les deux passes :
    /// les etiquettes synthetiques sont donc identiques d'une passe a l'autre, sans compteur
    /// a reinitialiser. Elles recoivent leur adresse comme une etiquette ordinaire, et les
    /// sauts relatifs vers elles passent par la resolution habituelle.
    /// </summary>
    private static void RewriteStructuredBlocks(List<SourceRef> lines)
    {
        // Rien a faire si aucune accolade ouvrante isolee : evite tout parcours inutile sur
        // les sources qui n'emploient pas la construction (c'est-a-dire tout le corpus).
        if (!lines.Any(l => CodePart(l.Text).Trim() == "{"))
        {
            return;
        }

        var blocs = new Stack<(string Top, string End)>();
        var compteur = 0;
        for (var i = 0; i < lines.Count; i++)
        {
            var origine = lines[i];
            var code = CodePart(origine.Text).Trim();
            if (code == "{")
            {
                compteur++;
                var top = $"_blk{compteur:D5}_t";
                var end = $"_blk{compteur:D5}_e";
                blocs.Push((top, end));
                lines[i] = origine with { Text = top + ":" };
            }
            else if (code == "}")
            {
                if (blocs.Count == 0)
                {
                    throw new InvalidOperationException(
                        $"'}}' sans '{{' correspondant, {Origine(origine)}");
                }

                var (_, end) = blocs.Pop();
                lines[i] = origine with { Text = end + ":" };
            }
            else if (blocs.Count > 0)
            {
                var (top, end) = blocs.Peek();
                var remplace = SubstituteBlockTargets(origine.Text, top, end);
                if (!ReferenceEquals(remplace, origine.Text))
                {
                    lines[i] = origine with { Text = remplace };
                }
            }
        }

        // Ouverture et fermeture doivent s'equilibrer : un bloc reste ouvert signale une
        // '}' manquante. On le refuse plutot que de laisser le bloc engloutir la suite du
        // fichier (et rendre continue/break ambigus au-dela de sa portee voulue).
        if (blocs.Count > 0)
        {
            var restant = blocs.Peek();
            throw new InvalidOperationException(
                $"bloc '{{' non ferme (manque '}}') pour {restant.Top}");
        }
    }

    /// <summary>Origine lisible d'une ligne, pour les messages d'erreur.</summary>
    private static string Origine(SourceRef ligne) =>
        $"ligne {ligne.Line} ({ligne.File})";

    /// <summary>
    /// Action : remplace, dans la portion code d'une ligne, les mots continue/break par les
    /// etiquettes de debut et de fin du bloc englobant. Ne touche ni la portion commentaire
    /// ni les autres identificateurs.
    /// </summary>
    private static string SubstituteBlockTargets(string text, string top, string end)
    {
        var coupe = CommentIndex(text);
        var code = coupe < 0 ? text : text[..coupe];
        var commentaire = coupe < 0 ? string.Empty : text[coupe..];
        var nouveau = System.Text.RegularExpressions.Regex.Replace(
            code,
            @"\bcontinue\b",
            top);
        nouveau = System.Text.RegularExpressions.Regex.Replace(
            nouveau,
            @"\bbreak\b",
            end);
        return ReferenceEquals(nouveau, code) || nouveau == code ? text : nouveau + commentaire;
    }

    /// <summary>Renvoie la portion de la ligne situee avant tout commentaire ';'.</summary>
    private static string CodePart(string text)
    {
        var i = CommentIndex(text);
        return i < 0 ? text : text[..i];
    }

    /// <summary>
    /// Position du ';' de commentaire, ou -1. Un ';' entre apostrophes (chaine) est ignore,
    /// pour ne pas confondre un caractere de donnee avec un debut de commentaire.
    /// </summary>
    private static int CommentIndex(string text)
    {
        var quoted = false;
        for (var i = 0; i < text.Length; i++)
        {
            if (text[i] == '\'')
            {
                quoted = !quoted;
            }
            else if (text[i] == ';' && !quoted)
            {
                return i;
            }
        }

        return -1;
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

            // Une demande d'EXITM remonte a travers les blocs imbriques (REPEAT, IRP,
            // conditionnelles) jusqu'a la macro qui l'englobe.
            if (_exitMacroRequested)
            {
                return;
            }

            var origin = sourceLines[i];
            _currentOrigin = origin;
            var line = SourceLine.Parse(StripInternalMarker(origin.Text));
            var mnemonic = line.Mnemonic.ToUpperInvariant();

            // SET est evalue ici comme EQU, mais **dans l'ordre du source** : c'est ce
            // qui permet a un compteur de progresser d'une iteration de REPEAT a la
            // suivante, le bloc etant re-developpe a chaque tour.
            // Le preprocesseur suit lui aussi les portees LOCAL. Sans cela, un EQU defini
            // dans un bloc etait enregistre sous son **nom nu** alors que la passe
            // d'assemblage l'enregistre sous son nom porte : le symbole existait deux fois,
            // et la version nue fuyait dans l'espace global. Deux portees definissant le
            // meme nom s'y ecrasaient mutuellement, et une reference faite hors de toute
            // portee obtenait une valeur au lieu d'une erreur.
            if (active && mnemonic == "LOCAL")
            {
                var portee = line.Label ?? $"n{++_anonymousScopeCounter:X5}";
                _symbols.EnterScope(_symbols.NameForDefinition(portee, forceGlobal: false));
            }
            else if (active && mnemonic == "ENDL")
            {
                _symbols.ExitScope();
            }

            if (active && line.Label is not null && mnemonic is "EQU" or "SET" or "=")
            {
                _symbols[_symbols.NameForDefinition(line.Label, forceGlobal: false)] =
                    Eval(line.OperandText);
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
                // Ces directives ne comparent pas deux valeurs : enter_numeric_if (modern.c)
                // lit un unique operande et le teste contre zero. "IFEQ x,0" s'assemble donc
                // sans erreur en ignorant le ",0" en silence, et produit un binaire faux mais
                // valide — piege rencontre en portant les sources A62 du pilote SmartMedia, ou
                // "IFEQ media_type,0" decalait le code de 21 octets. Le comportement reste
                // celui du C ; on se contente d'avertir, et seulement si le bloc englobant est
                // actif, pour ne pas signaler du code que l'on est justement en train d'ecarter.
                if (active && SplitOperands(line.OperandText).Length > 1)
                {
                    _warnings.Add(new AssemblyWarning(
                        origin.File,
                        origin.Line,
                        ColumnOf(origin.Text, line),
                        $"Warning: {mnemonic} tests one value against zero, extra operand ignored"));
                }

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

            if (mnemonic == "#IF")
            {
                // Conditionnelle A62 (Kon) : '#if symbole' (vrai si != 0), '#if a == b',
                // '#if a != b'. Evaluee au preprocesseur, ou les EQU/SET deja rencontres sont
                // connus (les drapeaux de configuration sont poses en tete de source).
                conditions.Push(active);
                active = active && EvaluateA62Condition(line.OperandText);
                continue;
            }

            if (mnemonic is "ELSE" or "#ELSE")
            {
                if (conditions.TryPeek(out var parent))
                {
                    active = parent && !active;
                }
                continue;
            }

            if (mnemonic is "ENDIF" or "#ENDIF")
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

            if (mnemonic == "EXITM")
            {
                if (_macroDepth == 0)
                {
                    throw new InvalidOperationException("EXITM hors d'une macro");
                }

                _exitMacroRequested = true;
                return;
            }

            if (mnemonic == "REPEAT")
            {
                var count = (int)Eval(line.OperandText);
                var block = CollectBlock(sourceLines, ref i, end, RepeatOpeners, "ENDR");
                for (var repeat = 0; repeat < count && !_exitMacroRequested; repeat++)
                {
                    ExpandSourceBlock(block, 0, block.Count, output, expandMacroDefinitions: false);
                }

                continue;
            }

            // IRP nom,v1,v2,... : rejoue le bloc une fois par valeur, en substituant le nom.
            // IRPC nom,chaine   : idem, une fois par caractere de la chaine.
            if (mnemonic is "IRP" or "IRPC")
            {
                var header = SplitOperands(line.OperandText);
                if (header.Length < 2)
                {
                    throw new InvalidOperationException(
                        $"{mnemonic} attend un nom puis au moins une valeur: {origin.Text.Trim()}");
                }

                var parameter = new[] { header[0].Trim() };
                var values = mnemonic == "IRP"
                    ? header.Skip(1).Select(x => x.Trim()).ToArray()
                    // Chaque caractere est injecte comme litteral entre apostrophes, afin que
                    // "DB c" emette bien son code ASCII et non une reference a un symbole.
                    : header[1].Trim().Trim('\'', '"').Select(c => $"'{c}'").ToArray();

                var block = CollectBlock(sourceLines, ref i, end, RepeatOpeners, "ENDR");
                foreach (var value in values)
                {
                    if (_exitMacroRequested)
                    {
                        break;
                    }

                    var substituted = block
                        .Select(l => l with { Text = ExpandMacroLine(l.Text, parameter, new[] { value }) })
                        .ToList();
                    ExpandSourceBlock(substituted, 0, substituted.Count, output, expandMacroDefinitions: false);
                }

                continue;
            }

            if (mnemonic == "#DEFMACRO")
            {
                // Macro A62 : le nom suit '#DEFMACRO', le corps utilise %0..%9, '#ENDMACRO' ferme.
                var nameA62 = line.OperandText.Trim();
                if (nameA62.Length == 0)
                {
                    throw new InvalidOperationException($"#DEFMACRO sans nom: {origin.Text.Trim()}");
                }

                var bodyA62 = CollectBlock(sourceLines, ref i, end, DefMacroOpeners, "#ENDMACRO");
                if (expandMacroDefinitions)
                {
                    _macros[nameA62] = new MacroDefinition(nameA62, A62MacroParameters, bodyA62);
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

                var body = CollectBlock(sourceLines, ref i, end, MacroOpeners, "ENDM");
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
                // Recursion interdite : sans ce garde-fou, une macro qui s'appelle elle-meme
                // developperait a l'infini. Le C l'evite en interdisant toute macro dans une
                // macro (err 44) ; on est plus permissif, en n'interdisant que le cycle.
                if (!_macrosInExpansion.Add(macro.Name))
                {
                    throw new InvalidOperationException(
                        $"recursion de macro detectee: {macro.Name}");
                }

                // Une etiquette posee sur l'appel doit designer le premier octet emis par
                // l'expansion. Elle est donc reportee sur une ligne propre, placee avant le
                // corps : le C la definit avant meme de chercher le mnemonique (xasm.c),
                // alors qu'ici l'expansion a lieu au preprocesseur, ou elle serait perdue.
                if (line.Label is not null)
                {
                    output.Add(origin with { Text = line.Label + ":" });
                }

                var args = SplitOperands(line.OperandText).Select(x => x.Trim()).ToArray();

                // Les lignes issues d'une macro sont rattachees au **site d'appel** et non
                // au corps de la definition : c'est la ligne que l'utilisateur doit corriger,
                // et c'est aussi ce que suit le C, dont current_file->lines vaut la ligne
                // en cours de lecture au moment ou la macro est rejouee.
                var expanded = macro.Body
                    .Select(l => origin with { Text = ExpandMacroLine(l.Text, macro.Arguments, args) })
                    .ToList();

                // Le corps est **re-developpe** au lieu d'etre recopie tel quel : les
                // conditionnelles, REPEAT, IRP et les appels de macro imbriques y sont donc
                // resolus, et EXITM peut interrompre l'expansion.
                _macroDepth++;
                ExpandSourceBlock(expanded, 0, expanded.Count, output, expandMacroDefinitions: false);
                _macroDepth--;
                _macrosInExpansion.Remove(macro.Name);

                // EXITM ne remonte pas au-dela de la macro qu'il interrompt.
                _exitMacroRequested = false;
                continue;
            }

            output.Add(sourceLines[i]);
        }
    }

    // Constructions qui ouvrent un bloc ferme par ENDR : leur imbrication doit etre comptee
    // pour que le ENDR ramasse soit bien celui du bloc courant.
    private static readonly IReadOnlySet<string> RepeatOpeners =
        new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "REPEAT", "IRP", "IRPC" };

    private static readonly IReadOnlySet<string> MacroOpeners =
        new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "MACRO" };

    // Macro du dialecte A62 (Kon) : '#DEFMACRO nom' ... '#ENDMACRO', corps a parametres
    // positionnels %0..%9. On la ramene au meme mecanisme que MACRO, avec ces noms de parametres.
    private static readonly IReadOnlySet<string> DefMacroOpeners =
        new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "#DEFMACRO" };

    private static readonly string[] A62MacroParameters =
        ["%0", "%1", "%2", "%3", "%4", "%5", "%6", "%7", "%8", "%9"];

    /// <summary>
    /// Action : collecte les lignes d'un bloc jusqu'a son terminateur, en tenant compte de
    /// l'imbrication.
    /// Donnees d'entree : lignes source, index de la ligne d'ouverture (avance en sortie),
    /// borne du bloc englobant, mnemoniques ouvrants et mnemonique fermant.
    /// Donnees de sortie : contenu du bloc, terminateur exclu.
    ///
    /// Le comptage de profondeur permet d'imbriquer REPEAT, IRP et IRPC, qui partagent tous
    /// le meme terminateur ENDR. Sans lui, le premier ENDR rencontre fermerait le bloc
    /// exterieur et le source serait developpe de travers.
    /// </summary>
    private static List<SourceRef> CollectBlock(
        IReadOnlyList<SourceRef> sourceLines,
        ref int index,
        int end,
        IReadOnlySet<string> openers,
        string closer)
    {
        var block = new List<SourceRef>();
        var depth = 1;
        index++;
        while (index < end)
        {
            var mnemonic = SourceLine.Parse(StripInternalMarker(sourceLines[index].Text)).Mnemonic;
            if (openers.Contains(mnemonic))
            {
                depth++;
            }
            else if (mnemonic.Equals(closer, StringComparison.OrdinalIgnoreCase))
            {
                depth--;
                if (depth == 0)
                {
                    break;
                }
            }

            block.Add(sourceLines[index]);
            index++;
        }

        return block;
    }

    /// <summary>
    /// Action : evalue une condition A62 de '#if' : 'a == b', 'a != b', ou 'symbole' (vrai si
    /// != 0). Les operandes sont evaluees avec les symboles connus a ce point du preprocesseur.
    /// </summary>
    private bool EvaluateA62Condition(string condition)
    {
        condition = condition.Trim();
        var eq = condition.IndexOf("==", StringComparison.Ordinal);
        if (eq >= 0)
        {
            return Eval(condition[..eq]) == Eval(condition[(eq + 2)..]);
        }

        var ne = condition.IndexOf("!=", StringComparison.Ordinal);
        if (ne >= 0)
        {
            return Eval(condition[..ne]) != Eval(condition[(ne + 2)..]);
        }

        return Eval(condition) != 0;
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
