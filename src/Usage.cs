namespace Xasm2026.Native;

internal static class Usage
{
    /// <summary>
    /// Action : affiche l'aide synthetique de la ligne de commande.
    /// Donnees d'entree : aucune donnee directe ; utilise l'etat courant de l'objet ou de l'application.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    public static void Write()
    {
        Console.WriteLine(" USAGE:XASM sourcefile[.ext] [options]");
        Console.WriteLine();
        Console.WriteLine("   - OPTIONS -");
        Console.WriteLine();
        Console.WriteLine(" -L[filename] : With listing file");
        Console.WriteLine(" -E[filename] : With error report file (use with -L)");
        Console.WriteLine(" -O[filename] : With object file");
        Console.WriteLine(" -S           : With symbol list (use with -L)");
        Console.WriteLine(" -T[type]     : Object type (type=Z: ZSH format");
        Console.WriteLine("                                  B: Binary format");
        Console.WriteLine("                                  H: Hexadecimal format");
        Console.WriteLine("                                  F: FTX format");
        Console.WriteLine("                              other: Binary format w/header)");
        Console.WriteLine(" -C           : Count line number");
        Console.WriteLine(" -W           : With warning");
        Console.WriteLine(" -H           : Hash off (use with -S)");
        Console.WriteLine(" -I[filename] : Intel HEX output (.hex)");
        Console.WriteLine(" -M[filename] : Motorola S-Record output (.s19)");
        Console.WriteLine(" -P[filename] : MAP output (symbols and sections)");
        Console.WriteLine(" -D[filename] : Dependency file output (.d)");
        Console.WriteLine(" -B[filename] : BASIC uuencode self-decoder output (.uu)");
        Console.WriteLine(" -X[filename] : HxD-style text dump output (.txt)");
        Console.WriteLine(" -V           : Verbose errors with column hint");
        Console.WriteLine(" -R           : Section size report");
        Console.WriteLine();
        Console.WriteLine("   ex. XASM sourcefile -L -O -S -TZ -I -M -P -D -B -X -R -W");
    }
}
