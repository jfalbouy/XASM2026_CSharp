using Xasm2026.Native.Core;

namespace Xasm2026.Native.Outputs;

internal static class MapWriter
{
    /// <summary>
    /// Action : ecrit la cartographie des symboles et sections.
    /// Donnees d'entree : parametres de la signature (string path, CommandLineOptions options, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    public static void Write(string path, CommandLineOptions options, AssemblyResult result)
    {
        using var writer = new StreamWriter(path, false);
        writer.WriteLine($"; XASM MAP file - {options.SourceFile}");
        writer.WriteLine($"; Code: {result.StartAddress:X6}h - {result.EndAddress - 1:X6}h [{result.GeneratedBytes.Count} bytes]");
        writer.WriteLine();
        writer.WriteLine("; Sections:");
        foreach (var section in result.Sections)
        {
            writer.WriteLine($";   {section.Name,-16} {section.Start:X6}h  {section.End - 1:X6}h  {section.End - section.Start}");
        }

        writer.WriteLine();
        writer.WriteLine("; Symbols:");
        foreach (var symbol in result.Symbols.OrderBy(x => x.Key, StringComparer.OrdinalIgnoreCase))
        {
            writer.WriteLine($"{symbol.Value:X6}h  {symbol.Key}");
        }
    }
}
