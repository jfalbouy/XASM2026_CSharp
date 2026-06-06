using Xasm2026.Native.Core;

namespace Xasm2026.Native.Outputs;

internal static class SRecordWriter
{
    /// <summary>
    /// Action : ecrit les octets generes au format Motorola S-Record.
    /// Donnees d'entree : parametres de la signature (string path, IReadOnlyList<GeneratedByte> bytes) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    public static void Write(string path, IReadOnlyList<GeneratedByte> bytes)
    {
        using var writer = new StreamWriter(path, false);
        writer.WriteLine("S0030000FC");

        var index = 0;
        while (index < bytes.Count)
        {
            var address = bytes[index].Address & 0xffff;
            var chunk = CollectContiguous(bytes, index, address, 16);
            var count = chunk.Count + 3;
            var sum = count + ((address >> 8) & 0xff) + (address & 0xff);

            writer.Write($"S1{count:X2}{address:X4}");
            foreach (var value in chunk)
            {
                writer.Write($"{value:X2}");
                sum += value;
            }

            writer.WriteLine($"{(~sum) & 0xff:X2}");
            index += chunk.Count;
        }

        writer.WriteLine("S9030000FC");
    }

    /// <summary>
    /// Action : collecte un bloc d'octets contigus pour un enregistrement S-Record.
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
            if ((current.Address & 0xffff) != address + result.Count)
            {
                break;
            }

            result.Add(current.Value);
        }

        return result;
    }
}
