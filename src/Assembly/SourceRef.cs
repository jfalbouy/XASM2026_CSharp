namespace Xasm2026.Native.Assembly;

/// <summary>
/// Action : associe une ligne source a son origine physique (fichier et numero de ligne).
/// Donnees d'entree : texte de la ligne, nom du fichier d'origine, numero de ligne 1-base.
/// Donnees de sortie : enregistrement immuable circulant dans tout le preprocesseur.
///
/// L'origine est portee par la ligne elle-meme, et non par une liste parallele : les corps
/// de MACRO et les blocs REPEAT sont copies puis rejoues, ce qui ferait perdre toute
/// correspondance positionnelle. Pendant de <c>file_typ.name</c> / <c>file_typ.lines</c>
/// du C, qui suit le fichier courant pendant la lecture.
/// </summary>
/// <param name="Text">Texte brut de la ligne, marqueur interne de fin d'include compris.</param>
/// <param name="File">Nom du fichier d'ou la ligne provient (source principal ou INCLUDE).</param>
/// <param name="Line">Numero de ligne physique dans ce fichier, 1-base.</param>
/// <param name="Args">
/// Expressions des arguments passes a l'INCLUDE de ce fichier, referencables par @0..@9.
/// Ce sont les **textes** des expressions, pas des valeurs : les INCLUDE etant aplatis
/// avant toute passe, la table des symboles n'est pas encore connue au moment ou ils sont
/// lus. La substitution a donc lieu au moment de l'evaluation. Les arguments du fichier
/// parent y sont deja substitues, si bien qu'un @n imbrique designe bien la bonne portee.
/// Null ou vide pour le source principal.
/// </param>
internal sealed record SourceRef(
    string Text,
    string File,
    int Line,
    IReadOnlyList<string>? Args = null);
