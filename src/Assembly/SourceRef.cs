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
internal sealed record SourceRef(string Text, string File, int Line);
