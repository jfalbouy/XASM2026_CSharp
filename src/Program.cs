using Xasm2026.Native.Assembly;
using Xasm2026.Native.Outputs;

namespace Xasm2026.Native;

internal static class Program
{
    /// <summary>
    /// Action : pilote l'execution en ligne de commande, lance l'assemblage puis retourne le code de fin.
    /// Donnees d'entree : parametres de la signature (string[] args) et etat courant necessaire.
    /// Donnees de sortie : valeur int calculee par la procedure.
    /// </summary>
    public static int Main(string[] args)
    {
        Usage.WriteTitle();

        if (args.Length == 0)
        {
            Usage.Write();
            return 1;
        }

        var options = CommandLineOptions.Parse(args);
        if (options.ShowHelp)
        {
            Usage.Write();
            return 1;
        }

        if (options.SourceFile is null)
        {
            Console.Error.WriteLine("XASM2026-4: fichier source manquant.");
            Usage.Write();
            return 1;
        }

        try
        {
            var assembler = new NativeAssembler(options);
            var result = assembler.Assemble();
            WriteOutputs(options, result);
            ReportWarnings(options, result);
            if (options.CountLinesEnabled)
            {
                Console.WriteLine($"    {result.SourceLineCount} line(s)");
            }

            Console.WriteLine("  No fatal error.  " +
                $"Code: {result.StartAddress:X6}h - {result.EndAddress - 1:X6}h " +
                $"[ {result.GeneratedBytes.Count,8} byte(s)]");
            WriteSectionReport(options, result);
            return 0;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"XASM2026-4: {ex.Message}");
            WriteFailureOutputs(options, ex);
            return 1;
        }
    }

    /// <summary>
    /// Action : genere tous les fichiers demandes par les options de compilation.
    /// Donnees d'entree : parametres de la signature (CommandLineOptions options, Core.AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private static void WriteOutputs(CommandLineOptions options, Core.AssemblyResult result)
    {
        if (options.ListingEnabled)
        {
            ListingWriter.Write(options.ListingFile, options, result);
        }

        if (options.ErrorReportEnabled)
        {
            var errorReport = Path.ChangeExtension(options.ListingFile, ".err");
            File.WriteAllText(errorReport, "No fatal error." + Environment.NewLine);
        }

        if (options.ObjectEnabled)
        {
            ObjectWriter.Write(options.ObjectFile, result, options.ObjectType);
        }

        if (options.IntelHexEnabled)
        {
            IntelHexWriter.Write(options.IntelHexFile, result.GeneratedBytes);
        }

        if (options.SRecordEnabled)
        {
            SRecordWriter.Write(options.SRecordFile, result.GeneratedBytes);
        }

        if (options.HxdEnabled)
        {
            var bytes = options.ObjectEnabled
                ? ObjectWriter.BuildObjectBytes(result, options.ObjectType)
                : result.GeneratedBytes.Select(x => x.Value).ToArray();
            HxdDumpWriter.Write(options.HxdFile, bytes);
        }

        if (options.BasicUuEnabled)
        {
            if (options.ObjectEnabled && File.Exists(options.ObjectFile))
            {
                BasicUuWriter.Write(options.BasicUuFile, options.ObjectFile, File.ReadAllBytes(options.ObjectFile));
            }
            else
            {
                BasicUuWriter.Write(options.BasicUuFile, options.ObjectFile, ObjectWriter.BuildObjectBytes(result, options.ObjectType));
            }
        }

        if (options.MapEnabled)
        {
            MapWriter.Write(options.MapFile, options, result);
        }

        if (options.DependencyEnabled)
        {
            DependencyWriter.Write(options.DependencyFile, options, result);
        }
    }

    /// <summary>
    /// Action : affiche les avertissements non fatals et les annexe au listing et au rapport .err.
    /// Donnees d'entree : parametres de la signature (CommandLineOptions options, Core.AssemblyResult result).
    /// Donnees de sortie : aucune valeur retournee ; effets sur la console et les fichiers de sortie.
    ///
    /// Fidelite a mes.c (err_handle) : les avertissements sont muets sans -W et ne rendent
    /// jamais l'assemblage fatal. Le format de ligne reprend "fichier\tligne\ttexte", avec
    /// "col N" insere sous -V.
    ///
    /// L'insertion dans le listing n'est pas faite ici : ListingWriter les intercale a la
    /// ligne fautive, comme le C. Cette procedure ne traite que la console et le .err.
    /// </summary>
    private static void ReportWarnings(CommandLineOptions options, Core.AssemblyResult result)
    {
        if (!options.WarningEnabled || result.Warnings.Count == 0)
        {
            return;
        }

        var lines = result.Warnings
            .Select(w => w.Format(options.VerboseErrorsEnabled))
            .ToList();

        foreach (var line in lines)
        {
            Console.WriteLine($"                 \r{line}");
        }

        if (options.ErrorReportEnabled)
        {
            File.AppendAllText(
                Path.ChangeExtension(options.ListingFile, ".err"),
                string.Join(Environment.NewLine, lines) + Environment.NewLine);
        }
    }

    /// <summary>
    /// Action : ecrit les rapports d'erreur lorsqu'une erreur fatale interrompt l'assemblage.
    /// Donnees d'entree : parametres de la signature (CommandLineOptions options, Exception exception) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private static void WriteFailureOutputs(CommandLineOptions options, Exception exception)
    {
        var report = BuildFailureReport(options, exception);
        if (options.ErrorReportEnabled)
        {
            var errorReport = Path.ChangeExtension(options.ListingFile, ".err");
            File.WriteAllText(errorReport, report);
        }

        if (options.ListingEnabled)
        {
            File.WriteAllText(options.ListingFile, report);
        }
    }

    /// <summary>
    /// Action : compose le texte detaille d'un rapport d'erreur exploitable dans les fichiers .lst et .err.
    /// Donnees d'entree : parametres de la signature (CommandLineOptions options, Exception exception) et etat courant necessaire.
    /// Donnees de sortie : valeur string calculee par la procedure.
    /// </summary>
    private static string BuildFailureReport(CommandLineOptions options, Exception exception)
    {
        var message = exception.Message;
        var lines = new List<string>
        {
            "; XASM2026-4 error report",
            $"; Source: {options.SourceFile}",
            "; Status: Fatal error",
            string.Empty,
            $"XASM2026-4: {message}",
        };

        if (TryParseErrorLine(message, out var lineNumber, out var originFile, out var detail, out var sourceText))
        {
            // Le fichier fautif peut etre un INCLUDE : c'est lui qu'on nomme et qu'on relit,
            // pas le source principal.
            var faultyFile = string.IsNullOrEmpty(originFile) ? options.SourceFile : originFile;

            lines.Add(string.Empty);
            lines.Add($"{faultyFile}\t{lineNumber}\t{detail}");
            if (!string.IsNullOrWhiteSpace(sourceText))
            {
                lines.Add($"    {sourceText.Trim()}");
            }

            var physicalLine = TryReadSourceLine(faultyFile, lineNumber);
            if (!string.IsNullOrWhiteSpace(physicalLine) &&
                !string.Equals(physicalLine.Trim(), sourceText.Trim(), StringComparison.Ordinal))
            {
                lines.Add($"    file line: {physicalLine.Trim()}");
            }
        }

        lines.Add(string.Empty);
        lines.Add("Fatal error occured.");
        lines.Add("Assemble aborted.");
        return string.Join(Environment.NewLine, lines) + Environment.NewLine;
    }

    /// <summary>
    /// Action : extrait le fichier, le numero de ligne, le libelle et le texte source depuis un message d'erreur normalise.
    /// Donnees d'entree : parametres de la signature (string message, out int lineNumber, out string originFile, out string detail, out string sourceText) et etat courant necessaire.
    /// Donnees de sortie : booleen indiquant si le traitement a reussi ou si la condition est verifiee.
    ///
    /// Deux formes sont acceptees : "ligne N: ..." quand l'erreur vient du source principal,
    /// et "ligne N (fichier): ..." quand elle vient d'un fichier inclus.
    /// </summary>
    private static bool TryParseErrorLine(
        string message, out int lineNumber, out string originFile, out string detail, out string sourceText)
    {
        lineNumber = 0;
        originFile = string.Empty;
        detail = message;
        sourceText = string.Empty;
        const string prefix = "ligne ";
        if (!message.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        var colon = message.IndexOf(':', prefix.Length);
        if (colon < 0)
        {
            return false;
        }

        var locator = message[prefix.Length..colon].Trim();
        var open = locator.IndexOf('(');
        if (open >= 0 && locator.EndsWith(')'))
        {
            originFile = locator[(open + 1)..^1].Trim();
            locator = locator[..open].Trim();
        }

        if (!int.TryParse(locator, out lineNumber))
        {
            return false;
        }

        var rest = message[(colon + 1)..].Trim();
        var separator = rest.LastIndexOf(" | ", StringComparison.Ordinal);
        if (separator >= 0)
        {
            detail = rest[..separator].Trim();
            sourceText = rest[(separator + 3)..].Trim();
        }
        else
        {
            detail = rest;
        }

        return true;
    }

    /// <summary>
    /// Action : relit une ligne physique du fichier source pour enrichir le diagnostic.
    /// Donnees d'entree : parametres de la signature (string? sourceFile, int lineNumber) et etat courant necessaire.
    /// Donnees de sortie : valeur string calculee par la procedure.
    /// </summary>
    private static string TryReadSourceLine(string? sourceFile, int lineNumber)
    {
        if (string.IsNullOrWhiteSpace(sourceFile) || lineNumber <= 0 || !File.Exists(sourceFile))
        {
            return string.Empty;
        }

        try
        {
            return File.ReadLines(sourceFile).Skip(lineNumber - 1).FirstOrDefault() ?? string.Empty;
        }
        catch
        {
            return string.Empty;
        }
    }

    /// <summary>
    /// Action : affiche le resume des sections assemblees lorsque l'option correspondante est active.
    /// Donnees d'entree : parametres de la signature (CommandLineOptions options, Core.AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private static void WriteSectionReport(CommandLineOptions options, Core.AssemblyResult result)
    {
        if (!options.SizeReportEnabled)
        {
            return;
        }

        Console.WriteLine();
        Console.WriteLine(" - Sections -");
        foreach (var section in result.Sections)
        {
            Console.WriteLine($" {section.Name,-16} {section.Start:X6}h - {section.End - 1:X6}h [ {section.End - section.Start} byte(s)]");
        }
    }
}
