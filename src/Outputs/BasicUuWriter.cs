using Xasm2026.Native.Core;

namespace Xasm2026.Native.Outputs;

internal static class BasicUuWriter
{
    private const int ChunkSize = 45;

    /// <summary>
    /// Action : genere un fichier BASIC auto-decodeur contenant un flux uuencode.
    /// Donnees d'entree : parametres de la signature (string path, string objectName, byte[] payload) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    public static void Write(string path, string objectName, byte[] payload)
    {
        using var writer = new StreamWriter(path, false);
        WriteDecoder(writer, MakeDecoderName(objectName));
        var line = 1000u;
        writer.WriteLine($"{++line} 'begin 644 {Path.GetFileName(objectName)}");

        var chunk = new byte[ChunkSize];
        for (var index = 0; index < payload.Length; index += ChunkSize)
        {
            var count = Math.Min(ChunkSize, payload.Length - index);
            payload.AsSpan(index, count).CopyTo(chunk);
            WriteEncodedLine(writer, ref line, chunk, count);
        }

        writer.WriteLine($"{++line} '``");
        writer.WriteLine($"{++line} 'end");
        writer.WriteLine($"{++line} 'size {payload.Length}");
    }

    /// <summary>
    /// Action : genere un fichier BASIC auto-decodeur depuis les octets produits par l'assemblage.
    /// Donnees d'entree : parametres de la signature (string path, string objectName, IReadOnlyList<GeneratedByte> bytes) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    public static void WriteGeneratedBytes(string path, string objectName, IReadOnlyList<GeneratedByte> bytes)
    {
        Write(path, objectName, bytes.Select(x => x.Value).ToArray());
    }

    /// <summary>
    /// Action : ecrit une ligne BASIC contenant jusqu'a 45 octets uuencodes.
    /// Donnees d'entree : parametres de la signature (StreamWriter writer, ref uint line, ReadOnlySpan<byte> buffer, int count) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private static void WriteEncodedLine(StreamWriter writer, ref uint line, ReadOnlySpan<byte> buffer, int count)
    {
        var checksum = 0;
        writer.Write($"{++line} '{Encode6(count)}");
        for (var index = 0; index < count; index += 3)
        {
            var a = buffer[index];
            var b = buffer[index + 1];
            var c = buffer[index + 2];
            checksum = (checksum + WriteTriple(writer, a, b, c)) % 64;
        }

        writer.Write(Encode6(checksum));
        writer.WriteLine();
    }

    /// <summary>
    /// Action : encode trois octets en quatre caracteres uuencode.
    /// Donnees d'entree : parametres de la signature (StreamWriter writer, byte a, byte b, byte c) et etat courant necessaire.
    /// Donnees de sortie : valeur int calculee par la procedure.
    /// </summary>
    private static int WriteTriple(StreamWriter writer, byte a, byte b, byte c)
    {
        writer.Write(Encode6(a >> 2));
        writer.Write(Encode6(((a << 4) & 0x30) | ((b >> 4) & 0x0f)));
        writer.Write(Encode6(((b << 2) & 0x3c) | ((c >> 6) & 0x03)));
        writer.Write(Encode6(c));
        return (a + b + c) % 64;
    }

    /// <summary>
    /// Action : convertit une valeur sur six bits en caractere uuencode compatible Sharp.
    /// Donnees d'entree : parametres de la signature (int value) et etat courant necessaire.
    /// Donnees de sortie : valeur char calculee par la procedure.
    /// </summary>
    private static char Encode6(int value)
    {
        value &= 0x3f;
        return value == 0 ? '`' : (char)(value + ' ');
    }

    /// <summary>
    /// Action : fabrique le nom de fichier cible attendu par le decodeur BASIC.
    /// Donnees d'entree : parametres de la signature (string name) et etat courant necessaire.
    /// Donnees de sortie : valeur string calculee par la procedure.
    /// </summary>
    private static string MakeDecoderName(string name)
    {
        var fileName = Path.GetFileName(name).ToUpperInvariant();
        var dot = fileName.IndexOf('.');
        var stem = dot >= 0 ? fileName[..dot] : fileName;
        var extension = dot >= 0 ? fileName[(dot + 1)..] : string.Empty;
        return stem.PadRight(8)[..8] + "." + extension.PadRight(3)[..3];
    }

    /// <summary>
    /// Action : ecrit le programme BASIC de decodage avant les donnees uuencode.
    /// Donnees d'entree : parametres de la signature (StreamWriter writer, string decoderName) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private static void WriteDecoder(StreamWriter writer, string decoderName)
    {
        var now = DateTime.Now;
        writer.WriteLine("100 '");
        writer.WriteLine("110 ' UUENCODE SELF-DECODER Ver1.20");
        writer.WriteLine("120 '");
        writer.WriteLine($"130   FNAME$=\"{decoderName}\"  ' Submitted {now:dd/MM/yyyy}");
        writer.WriteLine("140 '");
        writer.WriteLine("150 PRINT \"UUENCODE SELF-DECODER\"");
        writer.WriteLine("160 A$=\"\"");
        writer.WriteLine("170 ADR=&BFC7D:FOR I=1 TO 6:A$=A$+CHR$ (PEEK (ADR+I-1)):NEXT I");
        writer.WriteLine("180 IF A$=\"E:    \" OR A$=\"F:    \" THEN 220");
        writer.WriteLine("190 INPUT \"DRIVE(E/F) =\";A$");
        writer.WriteLine("200 IF RIGHT$ (A$,1)<>\":\" THEN A$=A$+\":\"");
        writer.WriteLine("210 A$=LEFT$ (A$+\"     \",6)");
        writer.WriteLine("220 A$=A$+FNAME$+CHR$ (0)");
        writer.WriteLine("230 POKE &BFFB0,&3C,&2C,&0D,&00,&FE,&0B,&90,&24,&60,&0D,&1B,&06,&90,&24,&60,&FF");
        writer.WriteLine("240 POKE &BFFC0,&18,&37,&6C,&04,&6C,&04,&6C,&04,&90,&24,&60,&27,&1B,&18,&6C,&04");
        writer.WriteLine("250 POKE &BFFD0,&6C,&04,&90,&24,&60,&23,&18,&26,&60,&25,&1A,&1D,&09,&20,&90,&24");
        writer.WriteLine("260 POKE &BFFE0,&48,&41,&EE,&30,&A0,&00,&90,&24,&48,&41,&30,&7B,&00,&30,&E8,&25");
        writer.WriteLine("270 POKE &BFFF0,&00,&7C,&01,&1B,&17,&7C,&04,&13,&43,&7A,&00,&FE,&0B,&FF,&9F,&07");
        writer.WriteLine("280 CALL &BFFB0");
        writer.WriteLine("290 '%DMKMKBPPALCMAECGPPBOADACAEPPIMKBPPALJACEGAGCBLBCJACEGAGFBLBIJACE");
        writer.WriteLine("300 '%BLBMJACEGAGJBLCCJACEGAGOBLCIJACEGACABLCOAMIBPPALAJAAAIAAAFOEPPAP");
        writer.WriteLine("310 '%DAIANGKIIAPPALBOADACAEPPAECGPPBOADACAEPPIMKBPPALJACEEICAHADPGAAA");
        writer.WriteLine("320 '%BIKODAMMAEAAPNBADAKAAFANKEPPALJACEEICAHADPOGOGDAKAAAJACEEICAHADP");
        writer.WriteLine("330 '%OODAKAABJACEEICAHADPOEOEDAKAACJACEEICAHADPDAKAADDAIAABHAADDAHPAA");
        writer.WriteLine("340 '%DAEDAELACFDAIAACHAAPDAHBABPADAHPABDAEDAELACFDAIAACHAMADAHPADDAED");
        writer.WriteLine("350 '%AELACFHMABBIAKHMABBIAGHMABBIACBDGCDAHBAEDPJACEEICABMAKHADPDAGDAE");
        writer.WriteLine("360 '%BIADACAEPPAIAALACFAMKEPPALDAMNAGAAAADAIFAFIIIAPPALDAKANGAJAEAFOE");
        writer.WriteLine("370 '%PPAPBOAKAMGPPPALAEFEPPACBHPPBDMEAMHFPPALAEFEPPIIIAPPALDAKANGAJAC");
        writer.WriteLine("380 '%AFOEPPAPJPAHIMKBPPALJACEGAANBLAGJACEGAPPBKAGKMKBPPALJHAGGMAEGMAE");
        writer.WriteLine("390 '%GMAEJACEGACHBIACBDCAGMAEGMAEKMKBPPALJPAGDAMMNGAACMANAAAAAAJACEGM");
        writer.WriteLine("400 '%AFGAAABLAIHMAFDMAJAEAFOEPPAPAGEFHCHCANAKAAFDHFGDGDGFHDHDANAKAAAA");
        writer.WriteLine("410 '%AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
        writer.WriteLine("420 '#");
        writer.WriteLine("430 ADR=&BFF81:FOR I=1 TO LEN (A$):POKE (ADR+I-1),ASC (MID$ (A$,I,1)):NEXT I");
        writer.WriteLine("440 PRINT \"DATA_FILE='\";FNAME$;\"'\"");
        writer.WriteLine("450 B$=\"\":INPUT \"OK? (Y/N) =\";B$");
        writer.WriteLine("460 IF B$=\"Y\" THEN 480 ELSE IF B$=\"N\" THEN END");
        writer.WriteLine("470 GOTO 440");
        writer.WriteLine("480 CALL &BFE00");
    }
}
