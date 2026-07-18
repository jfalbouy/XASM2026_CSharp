using Xasm2026.Native.Core;

namespace Xasm2026.Native.Assembly;

// Structures (STRUCT), sections, et report de l'etat interne (symboles, sections,
// dependances) vers le resultat d'assemblage. Extrait du noyau NativeAssembler.
internal sealed partial class NativeAssembler
{
    /// <summary>
    /// Action : termine la definition de structure en cours.
    /// Donnees d'entree : aucune donnee directe ; utilise l'etat courant de l'objet ou de l'application.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void CloseStruct()
    {
        if (_currentStruct is null)
        {
            return;
        }

        _symbols[$"{_currentStruct}_SIZE"] = _currentStructSize;
        _currentStruct = null;
        _currentStructSize = 0;
    }

    /// <summary>
    /// Action : demarre ou reprend une section d'assemblage.
    /// Donnees d'entree : parametres de la signature (string name) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void StartSection(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            return;
        }

        FinishSections();
        _currentSection = new SectionBuilder(name, _locationCounter);
        _sections.Add(_currentSection);
    }

    /// <summary>
    /// Action : clot les sections encore ouvertes a la fin de l'assemblage.
    /// Donnees d'entree : aucune donnee directe ; utilise l'etat courant de l'objet ou de l'application.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void FinishSections()
    {
        if (_currentSection is not null)
        {
            _currentSection.End = _locationCounter;
        }
    }

    /// <summary>
    /// Action : copie les symboles vers le resultat public de l'assemblage.
    /// Donnees d'entree : parametres de la signature (AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void CopySymbols(AssemblyResult result)
    {
        foreach (var symbol in _symbols.Values)
        {
            result.Symbols[symbol.Key] = symbol.Value;
        }
    }

    /// <summary>
    /// Action : copie les sections vers le resultat public de l'assemblage.
    /// Donnees d'entree : parametres de la signature (AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void CopySections(AssemblyResult result)
    {
        foreach (var section in _sections)
        {
            result.Sections.Add(new SectionInfo(section.Name, section.Start, section.End));
        }
    }

    /// <summary>
    /// Action : copie les dependances INCLUDE vers le resultat public.
    /// Donnees d'entree : parametres de la signature (AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void CopyDependencies(AssemblyResult result)
    {
        foreach (var dependency in _dependencies.Distinct(StringComparer.OrdinalIgnoreCase))
        {
            result.Dependencies.Add(dependency);
        }
    }
}
