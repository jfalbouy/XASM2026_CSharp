namespace Xasm2026.Native.Core;

/// <summary>
/// Action : represente un avertissement non fatal emis pendant l'assemblage.
/// Donnees d'entree : fichier concerne, numero de ligne et libelle historique du warning.
/// Donnees de sortie : enregistrement immuable destine a la console, au .lst et au .err.
///
/// Fidelite : les libelles reprennent mot pour mot ceux de <c>mes.c</c> (err_handle),
/// et le rendu suit le format historique <c>fichier\tligne\ttexte</c>. Comme dans le C,
/// un warning ne rend pas l'assemblage fatal et n'est affiche que si l'option -W est active.
/// </summary>
internal sealed record AssemblyWarning(string File, int Line, string Message);
