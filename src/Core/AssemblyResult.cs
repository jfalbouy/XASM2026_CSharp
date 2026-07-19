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
    public List<AssemblyWarning> Warnings { get; } = [];

    /// <summary>Table des references croisees : symbole -> emplacements "fichier:ligne".</summary>
    public Dictionary<string, List<string>> SymbolReferences { get; } = new(StringComparer.OrdinalIgnoreCase);
    /// <summary>Titre du listing, defini par la directive TITLE.</summary>
    public string? Title { get; set; }

    public long StartAddress { get; set; }
    public long EndAddress { get; set; }
    public int SourceLineCount { get; set; }
}
