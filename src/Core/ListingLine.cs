namespace Xasm2026.Native.Core;

/// <summary>
/// Action : represente une ligne du listing assembleur.
/// Donnees d'entree : adresse, octets emis, texte source et origine physique de la ligne.
/// Donnees de sortie : enregistrement immuable destine au fichier .lst.
///
/// L'origine (<paramref name="File"/>, <paramref name="Line"/>) permet au redacteur du
/// listing d'intercaler les avertissements a la ligne fautive, comme le fait err_handle
/// dans le C, sans avoir a manipuler des index positionnels fragiles.
/// </summary>
internal sealed record ListingLine(
    long Address,
    IReadOnlyList<byte> Bytes,
    string SourceText,
    string File = "",
    int Line = 0);
