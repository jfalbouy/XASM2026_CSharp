namespace Xasm2026.Native;

internal sealed class CommandLineOptions
{
    public string? SourceFile { get; private set; }
    public string ObjectFile { get; private set; } = "a.obj";
    public string ListingFile { get; private set; } = "a.lst";
    public string IntelHexFile { get; private set; } = "a.hex";
    public string SRecordFile { get; private set; } = "a.s19";
    public string MapFile { get; private set; } = "a.map";
    public string DependencyFile { get; private set; } = "a.d";
    public string BasicUuFile { get; private set; } = "a.uu";
    public string HxdFile { get; private set; } = "a.txt";
    public char ObjectType { get; private set; }
    public bool ObjectEnabled { get; private set; }
    public bool ListingEnabled { get; private set; }
    public bool ErrorReportEnabled { get; private set; }
    public bool SymbolListEnabled { get; private set; }
    public bool CountLinesEnabled { get; private set; }
    public bool WarningEnabled { get; private set; }
    public bool HashDisabled { get; private set; }
    public bool IntelHexEnabled { get; private set; }
    public bool SRecordEnabled { get; private set; }
    public bool MapEnabled { get; private set; }
    public bool DependencyEnabled { get; private set; }
    public bool BasicUuEnabled { get; private set; }
    public bool HxdEnabled { get; private set; }
    public bool VerboseErrorsEnabled { get; private set; }
    public bool SizeReportEnabled { get; private set; }
    public bool ShowHelp { get; private set; }

    /// <summary>
    /// Action : analyse les arguments de la ligne de commande et construit les options internes.
    /// Donnees d'entree : parametres de la signature (string[] args) et etat courant necessaire.
    /// Donnees de sortie : valeur de type CommandLineOptions produite par la procedure.
    /// </summary>
    public static CommandLineOptions Parse(string[] args)
    {
        var options = new CommandLineOptions();
        options.SourceFile = NormalizeSourceName(args[0]);
        options.ApplyDefaultOutputNames();

        for (var i = 1; i < args.Length; i++)
        {
            var arg = args[i];
            if (!arg.StartsWith('-') || arg.Length < 2)
            {
                continue;
            }

            switch (char.ToUpperInvariant(arg[1]))
            {
                case '?':
                    options.ShowHelp = true;
                    break;
                case 'L':
                    options.ListingEnabled = true;
                    options.ListingFile = ReadOptionValue(args, ref i, options.ListingFile);
                    break;
                case 'E':
                    options.ErrorReportEnabled = true;
                    break;
                case 'O':
                    options.ObjectEnabled = true;
                    options.ObjectFile = ReadOptionValue(args, ref i, options.ObjectFile);
                    break;
                case 'S':
                    options.SymbolListEnabled = true;
                    break;
                case 'T':
                    options.ObjectType = ReadObjectType(args, ref i);
                    break;
                case 'C':
                    options.CountLinesEnabled = true;
                    break;
                case 'W':
                    options.WarningEnabled = true;
                    break;
                case 'H':
                    options.HashDisabled = true;
                    break;
                case 'I':
                    options.IntelHexEnabled = true;
                    options.IntelHexFile = ReadOptionValue(args, ref i, options.IntelHexFile);
                    break;
                case 'M':
                    options.SRecordEnabled = true;
                    options.SRecordFile = ReadOptionValue(args, ref i, options.SRecordFile);
                    break;
                case 'P':
                    options.MapEnabled = true;
                    options.MapFile = ReadOptionValue(args, ref i, options.MapFile);
                    break;
                case 'D':
                    options.DependencyEnabled = true;
                    options.DependencyFile = ReadOptionValue(args, ref i, options.DependencyFile);
                    break;
                case 'B':
                    options.BasicUuEnabled = true;
                    options.BasicUuFile = ReadOptionValue(args, ref i, options.BasicUuFile);
                    break;
                case 'X':
                    options.HxdEnabled = true;
                    options.HxdFile = ReadOptionValue(args, ref i, options.HxdFile);
                    break;
                case 'V':
                    options.VerboseErrorsEnabled = true;
                    break;
                case 'R':
                    options.SizeReportEnabled = true;
                    break;
            }
        }

        return options;
    }

    /// <summary>
    /// Action : derive les noms de fichiers de sortie a partir du fichier source.
    /// Donnees d'entree : aucune donnee directe ; utilise l'etat courant de l'objet ou de l'application.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void ApplyDefaultOutputNames()
    {
        if (SourceFile is null)
        {
            return;
        }

        ObjectFile = Path.ChangeExtension(SourceFile, ".obj");
        ListingFile = Path.ChangeExtension(SourceFile, ".lst");
        IntelHexFile = Path.ChangeExtension(SourceFile, ".hex");
        SRecordFile = Path.ChangeExtension(SourceFile, ".s19");
        MapFile = Path.ChangeExtension(SourceFile, ".map");
        DependencyFile = Path.ChangeExtension(SourceFile, ".d");
        BasicUuFile = Path.ChangeExtension(SourceFile, ".uu");
        HxdFile = Path.ChangeExtension(SourceFile, ".txt");
    }

    /// <summary>
    /// Action : ajoute l'extension .asm lorsque le fichier source est fourni sans extension.
    /// Donnees d'entree : parametres de la signature (string source) et etat courant necessaire.
    /// Donnees de sortie : valeur string calculee par la procedure.
    /// </summary>
    private static string NormalizeSourceName(string source)
    {
        return Path.HasExtension(source) ? source : source + ".asm";
    }

    /// <summary>
    /// Action : lit une valeur d'option fournie collee a l'option ou dans l'argument suivant.
    /// Donnees d'entree : parametres de la signature (string[] args, ref int index, string currentValue) et etat courant necessaire.
    /// Donnees de sortie : valeur string calculee par la procedure.
    /// </summary>
    private static string ReadOptionValue(string[] args, ref int index, string currentValue)
    {
        var arg = args[index];
        if (arg.Length > 2)
        {
            return arg[2..];
        }

        if (index + 1 < args.Length && !args[index + 1].StartsWith('-'))
        {
            index++;
            return args[index];
        }

        return currentValue;
    }

    /// <summary>
    /// Action : lit le type d'objet demande par l'option -T.
    /// Donnees d'entree : parametres de la signature (string[] args, ref int index) et etat courant necessaire.
    /// Donnees de sortie : valeur char calculee par la procedure.
    /// </summary>
    private static char ReadObjectType(string[] args, ref int index)
    {
        var arg = args[index];
        if (arg.Length > 2)
        {
            return char.ToUpperInvariant(arg[2]);
        }

        if (index + 1 < args.Length)
        {
            index++;
            return char.ToUpperInvariant(args[index][0]);
        }

        return '\0';
    }
}
