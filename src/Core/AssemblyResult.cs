namespace Xasm2026.Native.Core;

/// <summary>
/// Action : regroupe toutes les donnees produites par une compilation assembleur.
/// Donnees d'entree : valeurs ajoutees progressivement par l'assembleur et les generateurs.
/// Donnees de sortie : resultat complet transmis aux ecrivains de fichiers et aux rapports.
/// </summary>
internal sealed class AssemblyResult
{
    public List<GeneratedByte> GeneratedBytes { get; } = [];
    public List<ListingLine> ListingLines { get; } = [];
    public Dictionary<string, long> Symbols { get; } = new(StringComparer.OrdinalIgnoreCase);
    public List<SectionInfo> Sections { get; } = [];
    public List<string> Dependencies { get; } = [];
    public long StartAddress { get; set; }
    public long EndAddress { get; set; }
    public int SourceLineCount { get; set; }
}
