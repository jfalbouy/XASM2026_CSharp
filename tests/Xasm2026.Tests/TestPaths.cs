using System.IO;

namespace Xasm2026.Tests;

/// <summary>
/// Localise la racine du depot et les dossiers d'exemples a partir de l'emplacement
/// de l'assembly de test, sans dependre du repertoire courant.
/// </summary>
internal static class TestPaths
{
    private static string? _repoRoot;

    public static string RepoRoot => _repoRoot ??= FindRepoRoot();

    public static string ExamplesDir => Path.Combine(RepoRoot, "Exemples");

    public static string TestsDir => Path.Combine(RepoRoot, "tests");

    private static string FindRepoRoot()
    {
        var dir = new DirectoryInfo(AppContext.BaseDirectory);
        while (dir is not null)
        {
            if (File.Exists(Path.Combine(dir.FullName, "xasm2026-4.sln")))
            {
                return dir.FullName;
            }

            dir = dir.Parent;
        }

        throw new DirectoryNotFoundException(
            "Racine du depot introuvable : 'xasm2026-4.sln' absent des dossiers parents.");
    }
}
