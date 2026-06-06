namespace Xasm2026.Native.Core;

/// <summary>
/// Action : decrit les bornes d'une section assemblee.
/// Donnees d'entree : nom de section, adresse de debut et adresse de fin.
/// Donnees de sortie : enregistrement immuable destine aux rapports de sections et au fichier .map.
/// </summary>
internal sealed record SectionInfo(string Name, long Start, long End);
