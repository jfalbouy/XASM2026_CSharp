using Xasm2026.Native.Core;

namespace Xasm2026.Native.Outputs;

internal static class ObjectWriter
{
    private static readonly byte[] Header =
    [
        255, 0, 6, 1, 16, 0, 0, 0, 0, 0, 0, 255, 255, 255, 0, 15
    ];

    /// <summary>
    /// Action : ecrit le fichier objet selon le type XASM demande.
    /// Donnees d'entree : parametres de la signature (string path, AssemblyResult result, char objectType) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    public static void Write(string path, AssemblyResult result, char objectType)
    {
        var payload = result.GeneratedBytes.Select(x => x.Value).ToArray();
        var header = BuildHeader(result);

        switch (char.ToUpperInvariant(objectType))
        {
            case 'B':
                File.WriteAllBytes(path, header.Skip(5).Take(6).Concat(payload).ToArray());
                break;
            case 'H':
                File.WriteAllText(path, ToHex(header.Skip(5).Take(6).Concat(payload)));
                break;
            case 'Z':
                WriteZsh(path, header, payload);
                break;
            default:
                File.WriteAllBytes(path, header.Concat(payload).ToArray());
                break;
        }
    }

    /// <summary>
    /// Action : construit en memoire les octets du fichier objet.
    /// Donnees d'entree : parametres de la signature (AssemblyResult result, char objectType) et etat courant necessaire.
    /// Donnees de sortie : tableau d'octets genere par la procedure.
    /// </summary>
    public static byte[] BuildObjectBytes(AssemblyResult result, char objectType)
    {
        var payload = result.GeneratedBytes.Select(x => x.Value).ToArray();
        var header = BuildHeader(result);
        return char.ToUpperInvariant(objectType) switch
        {
            'B' => header.Skip(5).Take(6).Concat(payload).ToArray(),
            _ => header.Concat(payload).ToArray(),
        };
    }

    /// <summary>
    /// Action : prepare l'entete objet avec taille et adresse de depart.
    /// Donnees d'entree : parametres de la signature (AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : tableau d'octets genere par la procedure.
    /// </summary>
    private static byte[] BuildHeader(AssemblyResult result)
    {
        var header = Header.ToArray();
        var length = result.GeneratedBytes.Count;
        Set24(header, 5, length);
        Set24(header, 8, result.StartAddress);
        return header;
    }

    /// <summary>
    /// Action : ecrit une valeur 24 bits little-endian dans un tampon.
    /// Donnees d'entree : parametres de la signature (byte[] buffer, int offset, long value) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private static void Set24(byte[] buffer, int offset, long value)
    {
        buffer[offset] = (byte)(value & 0xff);
        buffer[offset + 1] = (byte)((value >> 8) & 0xff);
        buffer[offset + 2] = (byte)((value >> 16) & 0xff);
    }

    /// <summary>
    /// Action : ecrit le format texte ZSH pour PC-E500.
    /// Donnees d'entree : parametres de la signature (string path, byte[] header, byte[] payload) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private static void WriteZsh(string path, byte[] header, byte[] payload)
    {
        using var writer = new StreamWriter(path, false);
        writer.WriteLine("----- ZSH FOR E500 [A.OUT]");
        writer.WriteLine($"---( {(header.Length + payload.Length + 31) / 32} lines )---");
        var allBytes = header.Concat(payload).ToArray();
        var checksum = 0;
        for (var i = 0; i < allBytes.Length; i++)
        {
            checksum = (checksum + allBytes[i]) & 0xff;
            writer.Write($"{allBytes[i]:X2}");
            if ((i + 1) % 32 == 0)
            {
                writer.WriteLine();
            }
        }

        var remainder = allBytes.Length % 32;
        if (remainder != 0)
        {
            for (var i = remainder; i < 32; i++)
            {
                writer.Write("00");
            }
        }

        writer.WriteLine($"{checksum:X2}");
        writer.WriteLine("( end of line )");
    }

    /// <summary>
    /// Action : convertit une sequence d'octets en chaine hexadecimale.
    /// Donnees d'entree : parametres de la signature (IEnumerable<byte> bytes) et etat courant necessaire.
    /// Donnees de sortie : valeur string calculee par la procedure.
    /// </summary>
    private static string ToHex(IEnumerable<byte> bytes)
    {
        return string.Concat(bytes.Select(x => x.ToString("X2")));
    }
}
