using Xasm2026.Native.Core;

namespace Xasm2026.Native.Outputs;

internal static class IntelHexWriter
{
    /// <summary>
    /// Action : ecrit les octets generes au format Intel HEX.
    /// Donnees d'entree : parametres de la signature (string path, IReadOnlyList<GeneratedByte> bytes) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    public static void Write(string path, IReadOnlyList<GeneratedByte> bytes)
    {
        using var writer = new StreamWriter(path, false);
        var index = 0;

        while (index < bytes.Count)
        {
            var address = bytes[index].Address;
            var chunk = CollectContiguous(bytes, index, address, 16);
            writer.Write($":{chunk.Count:X2}{address & 0xffff:X4}00");

            foreach (var value in chunk)
            {
                writer.Write($"{value:X2}");
            }

            writer.WriteLine($"{Checksum((ushort)address, 0, chunk):X2}");
            index += chunk.Count;
        }

        writer.WriteLine(":00000001FF");
    }

    /// <summary>
    /// Action : collecte un bloc d'octets contigus a partir d'une adresse.
    /// Donnees d'entree : parametres de la signature (IReadOnlyList<GeneratedByte> bytes, int start, long address, int maxCount) et etat courant necessaire.
    /// Donnees de sortie : collection calculee par la procedure.
    /// </summary>
    private static List<byte> CollectContiguous(
        IReadOnlyList<GeneratedByte> bytes,
        int start,
        long address,
        int maxCount)
    {
        var result = new List<byte>(maxCount);
        while (start + result.Count < bytes.Count && result.Count < maxCount)
        {
            var current = bytes[start + result.Count];
            if (current.Address != address + result.Count)
            {
                break;
            }

            result.Add(current.Value);
        }

        return result;
    }

    /// <summary>
    /// Action : calcule le checksum Intel HEX d'un enregistrement.
    /// Donnees d'entree : parametres de la signature (ushort address, byte type, IReadOnlyList<byte> data) et etat courant necessaire.
    /// Donnees de sortie : valeur de type byte produite par la procedure.
    /// </summary>
    private static byte Checksum(ushort address, byte type, IReadOnlyList<byte> data)
    {
        var sum = data.Count + (address >> 8) + (address & 0xff) + type;
        foreach (var value in data)
        {
            sum += value;
        }

        return (byte)((~sum + 1) & 0xff);
    }
}
