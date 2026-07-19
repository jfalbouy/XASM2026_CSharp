using Xasm2026.Native.Core;

namespace Xasm2026.Native.Outputs;

internal static class ListingWriter
{
    private const int BytesPerListingLine = 6;
    private const int ByteColumnWidth = 18;

    /// <summary>
    /// Action : ecrit le fichier listing avec options, symboles et lignes assemblees.
    /// Donnees d'entree : parametres de la signature (string path, CommandLineOptions options, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    public static void Write(string path, CommandLineOptions options, AssemblyResult result)
    {
        using var writer = new StreamWriter(path, false);

        // Titre pose par la directive TITLE. Absent par defaut, donc sans effet sur les
        // listings de reference.
        if (!string.IsNullOrEmpty(result.Title))
        {
            writer.WriteLine(result.Title);
            writer.WriteLine();
        }

        // Les avertissements sont intercales a la ligne fautive, comme le fait err_handle
        // dans le C. Sans -W ils sont totalement absents du listing, ce qui garantit
        // l'invariance des sorties de reference.
        var pending = options.WarningEnabled
            ? result.Warnings.ToList()
            : new List<AssemblyWarning>();

        if (result.ListingLines.Count > 0)
        {
            foreach (var line in result.ListingLines)
            {
                WriteListingLine(writer, line);

                // Ordre d'emission preserve : plusieurs avertissements peuvent viser la
                // meme ligne (33 et 38 sur la derniere ligne d'un fichier inclus).
                var matched = pending
                    .Where(w => w.Line == line.Line &&
                                string.Equals(w.File, line.File, StringComparison.OrdinalIgnoreCase))
                    .ToList();
                foreach (var warning in matched)
                {
                    writer.WriteLine(warning.Format(options.VerboseErrorsEnabled));
                    pending.Remove(warning);
                }
            }
        }

        // Avertissements sans ligne de listing correspondante : on ne les perd pas.
        foreach (var warning in pending)
        {
            writer.WriteLine(warning.Format(options.VerboseErrorsEnabled));
        }

        if (options.SymbolListEnabled)
        {
            writer.WriteLine();
            writer.WriteLine(" - Symbols -");
            writer.WriteLine();
            foreach (var symbol in result.Symbols.OrderBy(x => x.Key, StringComparer.OrdinalIgnoreCase))
            {
                writer.WriteLine($"{symbol.Value:X6}h  {symbol.Key}");
            }
        }

        if (options.CrossReferenceEnabled && result.SymbolReferences.Count > 0)
        {
            writer.WriteLine();
            writer.WriteLine(" - Cross reference -");
            writer.WriteLine();
            foreach (var entry in result.SymbolReferences.OrderBy(x => x.Key, StringComparer.OrdinalIgnoreCase))
            {
                var value = result.Symbols.TryGetValue(entry.Key, out var v) ? $"{v:X6}h" : "      ";
                writer.WriteLine($"{value}  {entry.Key}");
                foreach (var place in entry.Value)
                {
                    writer.WriteLine($"          {place}");
                }
            }
        }

        writer.WriteLine();
        writer.WriteLine("  No fatal error.  " +
            $"Code: {result.StartAddress:X6}h - {result.EndAddress - 1:X6}h " +
            $"[ {result.GeneratedBytes.Count,8} byte(s)]");
    }

    /// <summary>
    /// Action : formate une ligne du listing avec adresse, octets et source.
    /// Donnees d'entree : parametres de la signature (StreamWriter writer, ListingLine line) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private static void WriteListingLine(StreamWriter writer, ListingLine line)
    {
        var source = line.SourceText;
        if (line.Bytes.Count == 0)
        {
            writer.WriteLine($"{line.Address:X6}                   \t{source}");
            return;
        }

        for (var index = 0; index < line.Bytes.Count; index += BytesPerListingLine)
        {
            var count = Math.Min(BytesPerListingLine, line.Bytes.Count - index);
            var bytesText = string.Join(' ', line.Bytes.Skip(index).Take(count).Select(x => x.ToString("X2")));
            if (index == 0)
            {
                writer.WriteLine($"{line.Address + index:X6} {bytesText,-ByteColumnWidth}\t{source}");
            }
            else
            {
                writer.WriteLine($"{line.Address + index:X6} {bytesText,-ByteColumnWidth}\t");
            }
        }
    }
}
