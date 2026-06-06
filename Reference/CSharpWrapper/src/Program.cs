using System.Diagnostics;
using System.ComponentModel;
using System.Reflection;

namespace Xasm2026.CSharp;

internal static class Program
{
    private const string EngineFileName = "xasm2026-engine.exe";

    /// <summary>
    /// Action : pilote l'ancien wrapper et transmet la ligne de commande au moteur assembleur externe.
    /// Donnees d'entree : parametres de la signature (string[] args) et etat courant necessaire.
    /// Donnees de sortie : valeur int calculee par la procedure.
    /// </summary>
    public static int Main(string[] args)
    {
        var enginePath = ResolveEnginePath();
        if (enginePath is null)
        {
            Console.Error.WriteLine("XASM2026-2: moteur assembleur introuvable.");
            Console.Error.WriteLine($"Fichier attendu : {EngineFileName}");
            return 1;
        }

        try
        {
            using var process = StartEngine(enginePath, args);
            process.WaitForExit();
            return process.ExitCode;
        }
        catch (Exception ex) when (ex is Win32Exception or InvalidOperationException)
        {
            Console.Error.WriteLine($"XASM2026-2: impossible de lancer le moteur assembleur : {ex.Message}");
            return 1;
        }
    }

    /// <summary>
    /// Action : demarre le moteur assembleur externe avec les arguments fournis au wrapper.
    /// Donnees d'entree : parametres de la signature (string enginePath, string[] args) et etat courant necessaire.
    /// Donnees de sortie : valeur de type Process produite par la procedure.
    /// </summary>
    private static Process StartEngine(string enginePath, string[] args)
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = enginePath,
            WorkingDirectory = Environment.CurrentDirectory,
            UseShellExecute = false,
        };

        foreach (var arg in args)
        {
            startInfo.ArgumentList.Add(arg);
        }

        return Process.Start(startInfo)
            ?? throw new InvalidOperationException("Le processus assembleur n'a pas pu demarrer.");
    }

    /// <summary>
    /// Action : recherche le moteur assembleur externe a cote du wrapper ou dans le dossier Engine.
    /// Donnees d'entree : aucune donnee directe ; utilise l'etat courant de l'objet ou de l'application.
    /// Donnees de sortie : valeur de type string? produite par la procedure.
    /// </summary>
    private static string? ResolveEnginePath()
    {
        var appDirectory = AppContext.BaseDirectory;
        var besideExecutable = Path.Combine(appDirectory, EngineFileName);
        if (File.Exists(besideExecutable))
        {
            return besideExecutable;
        }

        var assemblyPath = Assembly.GetExecutingAssembly().Location;
        if (!string.IsNullOrWhiteSpace(assemblyPath))
        {
            var assemblyDirectory = Path.GetDirectoryName(assemblyPath);
            if (assemblyDirectory is not null)
            {
                var besideAssembly = Path.Combine(assemblyDirectory, EngineFileName);
                if (File.Exists(besideAssembly))
                {
                    return besideAssembly;
                }
            }
        }

        var projectRelative = Path.GetFullPath(
            Path.Combine(appDirectory, "..", "..", "..", "..", "Engine", EngineFileName));
        return File.Exists(projectRelative) ? projectRelative : null;
    }
}
