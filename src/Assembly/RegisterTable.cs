namespace Xasm2026.Native.Assembly;

/// <summary>
/// Action : tables de correspondance des registres SC62015 (identifiants et opcodes).
/// Donnees d'entree : nom de registre tel qu'ecrit dans le source assembleur.
/// Donnees de sortie : identifiant numerique ou opcode d'encodage.
///
/// Extrait du noyau NativeAssembler : ces tables sont sans etat et ne dependent d'aucun
/// contexte d'assemblage, elles constituent donc un type autonome. Les appelants les
/// importent via "using static" pour eviter de prefixer chaque appel.
/// </summary>
internal static class RegisterTable
{
    /// <summary>
    /// Action : indique si une chaine designe un registre reconnu.
    /// Donnees d'entree : parametres de la signature (string value) et etat courant necessaire.
    /// Donnees de sortie : booleen indiquant si le traitement a reussi ou si la condition est verifiee.
    /// </summary>
    public static bool IsRegister(string value)
    {
        return value.Trim().ToUpperInvariant() is "A" or "IL" or "BA" or "I" or "X" or "Y" or "U" or "S" or "B" or "F" or "IMR";
    }

    /// <summary>
    /// Action : convertit un nom de registre XASM en identifiant numerique.
    /// Donnees d'entree : parametres de la signature (string register) et etat courant necessaire.
    /// Donnees de sortie : valeur int calculee par la procedure.
    /// </summary>
    public static int XasmRegisterId(string register)
    {
        return register.Trim().ToUpperInvariant() switch
        {
            "A" => 0,
            "IL" => 1,
            "BA" => 2,
            "I" => 3,
            "X" => 4,
            "Y" => 5,
            "U" => 6,
            "S" => 7,
            "B" => 8,
            "F" => 9,
            "IMR" => 10,
            _ => throw new NotSupportedException($"registre non reconnu: {register}"),
        };
    }

    /// <summary>
    /// Action : retourne l'opcode de stockage absolu associe a un registre.
    /// Donnees d'entree : parametres de la signature (string register) et etat courant necessaire.
    /// Donnees de sortie : valeur int calculee par la procedure.
    /// </summary>
    public static int RegisterToAbsoluteStoreOpcode(string register)
    {
        return register.Trim().ToUpperInvariant() switch
        {
            "A" => 0xA8,
            "IL" => 0xA9,
            "BA" => 0xAA,
            "I" => 0xAB,
            "Y" => 0xAD,
            "X" => 0xAC,
            "U" => 0xAE,
            "S" => 0xAF,
            _ => throw new NotSupportedException($"MV store register not ported yet: {register}"),
        };
    }

    /// <summary>
    /// Action : retourne l'opcode de chargement absolu associe a un registre.
    /// Donnees d'entree : parametres de la signature (string register) et etat courant necessaire.
    /// Donnees de sortie : valeur int calculee par la procedure.
    /// </summary>
    public static int RegisterFromAbsoluteLoadOpcode(string register)
    {
        return register.Trim().ToUpperInvariant() switch
        {
            "A" => 0x88,
            "IL" => 0x89,
            "BA" => 0x8A,
            "I" => 0x8B,
            "Y" => 0x8D,
            "X" => 0x8C,
            "U" => 0x8E,
            "S" => 0x8F,
            _ => throw new NotSupportedException($"MV load register not ported yet: {register}"),
        };
    }

    /// <summary>
    /// Action : convertit un nom de registre en identifiant d'encodage.
    /// Donnees d'entree : parametres de la signature (string register) et etat courant necessaire.
    /// Donnees de sortie : valeur int calculee par la procedure.
    /// </summary>
    public static int RegisterId(string register)
    {
        return register.Trim().ToUpperInvariant() switch
        {
            "A" => 0,
            "IL" => 1,
            "BA" => 2,
            "I" => 3,
            "X" => 4,
            "Y" => 5,
            "U" => 6,
            "S" => 7,
            "IMR" => 7,
            _ => throw new NotSupportedException($"registre non encore porte: {register}"),
        };
    }
}
