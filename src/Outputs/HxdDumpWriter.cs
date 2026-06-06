using System.Text;
using Xasm2026.Native.Core;

namespace Xasm2026.Native.Outputs;

internal static class HxdDumpWriter
{
    /// <summary>
    /// Action : ecrit un dump hexadecimal a partir d'un tableau d'octets.
    /// Donnees d'entree : parametres de la signature (string path, IReadOnlyList<byte> bytes) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    public static void Write(string path, IReadOnlyList<byte> bytes)
    {
        using var writer = new StreamWriter(path, false, Encoding.UTF8);
        writer.WriteLine("Offset(h) 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F");
        writer.WriteLine();

        for (var offset = 0; offset < bytes.Count; offset += 16)
        {
            var count = Math.Min(16, bytes.Count - offset);
            WriteLine(writer, offset, bytes, count);
        }
    }

    /// <summary>
    /// Action : ecrit un dump hexadecimal a partir des octets adresses generes.
    /// Donnees d'entree : parametres de la signature (string path, IReadOnlyList<GeneratedByte> bytes) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    public static void WriteGeneratedBytes(string path, IReadOnlyList<GeneratedByte> bytes)
    {
        Write(path, bytes.Select(x => x.Value).ToArray());
    }

    /// <summary>
    /// Action : formate une ligne de dump hexadecimal et ASCII.
    /// Donnees d'entree : parametres de la signature (StreamWriter writer, int offset, IReadOnlyList<byte> bytes, int count) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private static void WriteLine(StreamWriter writer, int offset, IReadOnlyList<byte> bytes, int count)
    {
        writer.Write($"{offset:X8}  ");
        for (var i = 0; i < 16; i++)
        {
            writer.Write(i < count ? $"{bytes[offset + i]:X2} " : "   ");
        }

        writer.Write(' ');
        for (var i = 0; i < count; i++)
        {
            writer.Write(ToDisplayChar(bytes[offset + i]));
        }

        writer.WriteLine();
    }

    /// <summary>
    /// Action : convertit un octet en caractere affichable ou en point.
    /// Donnees d'entree : parametres de la signature (byte value) et etat courant necessaire.
    /// Donnees de sortie : valeur char calculee par la procedure.
    /// </summary>
    private static char ToDisplayChar(byte value)
    {
        if (value is >= 32 and <= 126)
        {
            return (char)value;
        }

        if (value >= 160)
        {
            return (char)value;
        }

        return value switch
        {
            0x80 => '\u20AC',
            0x82 => '\u201A',
            0x83 => '\u0192',
            0x84 => '\u201E',
            0x85 => '\u2026',
            0x86 => '\u2020',
            0x87 => '\u2021',
            0x88 => '\u02C6',
            0x89 => '\u2030',
            0x8A => '\u0160',
            0x8B => '\u2039',
            0x8C => '\u0152',
            0x8E => '\u017D',
            0x91 => '\u2018',
            0x92 => '\u2019',
            0x93 => '\u201C',
            0x94 => '\u201D',
            0x95 => '\u2022',
            0x96 => '\u2013',
            0x97 => '\u2014',
            0x98 => '\u02DC',
            0x99 => '\u2122',
            0x9A => '\u0161',
            0x9B => '\u203A',
            0x9C => '\u0153',
            0x9E => '\u017E',
            0x9F => '\u0178',
            _ => '.',
        };
    }
}
