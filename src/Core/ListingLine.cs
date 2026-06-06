namespace Xasm2026.Native.Core;

/// <summary>
/// Action : represente une ligne du listing assembleur.
/// Donnees d'entree : adresse, octets emis et texte source correspondant.
/// Donnees de sortie : enregistrement immuable destine au fichier .lst.
/// </summary>
internal sealed record ListingLine(long Address, IReadOnlyList<byte> Bytes, string SourceText);
