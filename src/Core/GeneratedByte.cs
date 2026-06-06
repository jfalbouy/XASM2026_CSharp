namespace Xasm2026.Native.Core;

/// <summary>
/// Action : represente un octet genere avec son adresse assemblee.
/// Donnees d'entree : adresse logique et valeur de l'octet.
/// Donnees de sortie : enregistrement immuable utilise par les formats de sortie.
/// </summary>
internal readonly record struct GeneratedByte(long Address, byte Value);
