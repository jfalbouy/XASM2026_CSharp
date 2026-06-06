using Xasm2026.Native.Core;

namespace Xasm2026.Native.Outputs;

internal static class DependencyWriter
{
    /// <summary>
    /// Action : ecrit les dependances de compilation au format makefile simple.
    /// Donnees d'entree : parametres de la signature (string path, CommandLineOptions options, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    public static void Write(string path, CommandLineOptions options, AssemblyResult result)
    {
        if (options.SourceFile is null)
        {
            return;
        }

        var dependencies = string.Join(" ", result.Dependencies);
        var suffix = string.IsNullOrWhiteSpace(dependencies) ? string.Empty : " " + dependencies;
        File.WriteAllText(path, $"{options.ObjectFile}: {options.SourceFile}{suffix}{Environment.NewLine}");
    }
}
