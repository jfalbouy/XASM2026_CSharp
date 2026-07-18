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
/// <param name="File">Fichier physique contenant la ligne fautive.</param>
/// <param name="Line">Numero de ligne physique dans ce fichier, 1-base.</param>
/// <param name="Column">
/// Colonne 1-base du debut de l'operande dans la ligne source, ou du mnemonique lorsqu'il
/// n'y a pas d'operande ; 0 si elle n'a pas pu etre determinee. Affichee sous -V. Ce n'est
/// pas exactement le <c>pp</c> du C, qui est la position courante de l'analyseur au moment
/// de l'erreur : on designe ici le debut du fragment fautif, ce qui est stable et verifiable.
/// </param>
/// <param name="Message">Libelle historique repris mot pour mot de mes.c.</param>
internal sealed record AssemblyWarning(string File, int Line, int Column, string Message)
{
    /// <summary>
    /// Action : rend l'avertissement au format historique "fichier&lt;TAB&gt;ligne&lt;TAB&gt;texte".
    /// Donnees d'entree : indicateur de verbosite (-V).
    /// Donnees de sortie : ligne prete a ecrire sur la console, dans le .lst ou dans le .err.
    ///
    /// Format unique pour les trois destinations, comme dans err_handle qui compose un seul
    /// errtext. La colonne n'est inseree que sous -V et si elle a pu etre determinee.
    /// </summary>
    public string Format(bool verbose) =>
        verbose && Column > 0
            ? $"{File}\t{Line}\tcol {Column}\t{Message}"
            : $"{File}\t{Line}\t{Message}";
}
