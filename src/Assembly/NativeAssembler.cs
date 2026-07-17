using Xasm2026.Native.Core;
using Xasm2026.Native.Expressions;

namespace Xasm2026.Native.Assembly;

internal sealed partial class NativeAssembler
{
    private const char IncludedEndMarker = '\u0001';

    private readonly CommandLineOptions _options;
    private readonly Dictionary<string, long> _symbols = new(StringComparer.OrdinalIgnoreCase);
    private readonly HashSet<string> _definedSymbols = new(StringComparer.OrdinalIgnoreCase);
    private readonly Dictionary<string, MacroDefinition> _macros = new(StringComparer.OrdinalIgnoreCase);
    private readonly List<string> _expandedLines = [];
    private readonly List<string> _dependencies = [];
    private readonly HashSet<string> _includeStack = new(StringComparer.OrdinalIgnoreCase);
    private readonly List<SectionBuilder> _sections = [];
    private readonly Dictionary<string, List<long>> _symbolOccurrences = new(StringComparer.OrdinalIgnoreCase);
    private readonly Stack<string?> _localScopeStack = new();
    private long _locationCounter;
    private long _startAddress;
    private bool _originSet;
    private string? _currentStruct;
    private long _currentStructSize;
    private SectionBuilder? _currentSection;
    private string? _currentLocalScope;
    private bool _preOn;
    private bool _emitPass;
    private readonly Stack<bool> _preStack = new();

    /// <summary>
    /// Action : initialise l'assembleur natif avec les options de compilation.
    /// Donnees d'entree : parametres de la signature (CommandLineOptions options) et etat courant necessaire.
    /// Donnees de sortie : instance initialisee.
    /// </summary>
    public NativeAssembler(CommandLineOptions options)
    {
        _options = options;
    }

    /// <summary>
    /// Action : execute l'assemblage complet en deux passes et produit le resultat final.
    /// Donnees d'entree : aucune donnee directe ; utilise l'etat courant de l'objet ou de l'application.
    /// Donnees de sortie : valeur de type AssemblyResult produite par la procedure.
    /// </summary>
    public AssemblyResult Assemble()
    {
        if (_options.SourceFile is null)
        {
            throw new InvalidOperationException("Source file is required.");
        }

        var sourceLines = ReadSourceWithIncludes(_options.SourceFile);
        _expandedLines.Clear();
        ExpandSource(sourceLines);

        RunPass(emit: false);
        var result = RunPass(emit: true);
        return result;
    }

    /// <summary>
    /// Action : parcourt les lignes source pour calculer ou emettre le code machine selon la passe.
    /// Donnees d'entree : parametres de la signature (bool emit) et etat courant necessaire.
    /// Donnees de sortie : valeur de type AssemblyResult produite par la procedure.
    /// </summary>
    private AssemblyResult RunPass(bool emit)
    {
        _emitPass = emit;
        _locationCounter = 0;
        _startAddress = 0;
        _originSet = false;
        _currentStruct = null;
        _currentStructSize = 0;
        _currentSection = null;
        _currentLocalScope = null;
        _preOn = false;
        _localScopeStack.Clear();
        _preStack.Clear();
        if (!emit)
        {
            _symbolOccurrences.Clear();
        }
        if (emit)
        {
            _sections.Clear();
        }

        var result = new AssemblyResult();
        var conditions = new Stack<bool>();
        var active = true;

        for (var lineIndex = 0; lineIndex < _expandedLines.Count; lineIndex++)
        {
            var storedLine = _expandedLines[lineIndex];
            var isIncludedEnd = IsIncludedEnd(storedLine);
            var rawLine = StripInternalMarker(storedLine);
            var lineAddress = _locationCounter;
            var lineByteStart = result.GeneratedBytes.Count;
            var line = SourceLine.Parse(rawLine);
            if (line.IsEmpty)
            {
                AddListingLine(emit, result, lineAddress, lineByteStart, rawLine);
                continue;
            }

            var mnemonic = line.Mnemonic.ToUpperInvariant();
            if (HandleCondition(mnemonic, line.OperandText, conditions, ref active))
            {
                AddListingLine(emit, result, lineAddress, lineByteStart, rawLine);
                continue;
            }

            if (!active)
            {
                AddListingLine(emit, result, lineAddress, lineByteStart, rawLine);
                continue;
            }

            if (line.Label is not null)
            {
                if (mnemonic == "EQU")
                {
                    var value = Eval(line.OperandText);
                    _symbols[SymbolNameForDefinition(line.Label, forceGlobal: false)] = value;
                    if (_currentStruct is not null && value + 1 > _currentStructSize)
                    {
                        _currentStructSize = value + 1;
                    }
                }
                else if (mnemonic == "STRUCT")
                {
                    _symbols[line.Label] = _locationCounter;
                    _currentStruct = line.Label;
                    _currentStructSize = 0;
                }
                else
                {
                    var symbolName = SymbolNameForDefinition(line.Label, forceGlobal: false);
                    _symbols[symbolName] = _locationCounter;
                    if (!emit)
                    {
                        AddSymbolOccurrence(symbolName, _locationCounter);
                    }
                }
            }

            try
            {
                switch (mnemonic)
                {
                    case "ORG":
                        _locationCounter = Eval(line.OperandText);
                        if (!_originSet)
                        {
                            _startAddress = _locationCounter;
                            _originSet = true;
                        }
                        break;
                case "EQU":
                case "STRUCT":
                    break;
                case "PRE_ON":
                    _preOn = true;
                    break;
                case "PRE_OFF":
                    _preOn = false;
                    break;
                case "PRE_PUSH":
                    _preStack.Push(_preOn);
                    break;
                case "PRE_POP":
                    _preOn = _preStack.Count > 0 && _preStack.Pop();
                    break;
                case "SCOPE_ON":
                case "SCOPE_OFF":
                case "LOCAL":
                case "MACRO":
                case "ENDM":
                case "DEF":
                case "UNDEF":
                case "IFDEF":
                case "IFNDEF":
                    if (line.Label is not null)
                    {
                        _localScopeStack.Push(_currentLocalScope);
                        _currentLocalScope = SymbolNameForDefinition(line.Label, forceGlobal: false);
                    }
                    break;
                case "ENDL":
                    _currentLocalScope = _localScopeStack.Count > 0 ? _localScopeStack.Pop() : null;
                    break;
                case "ENDS":
                    CloseStruct();
                    break;
                case "SECTION":
                    if (emit)
                    {
                        StartSection(line.OperandText.Trim());
                    }
                    break;
                case "INCLUDE":
                    break;
                case "DB":
                case "DM":
                    EmitData(line.OperandText, 1, emit, result);
                    break;
                case "DW":
                    EmitData(line.OperandText, 2, emit, result);
                    break;
                case "DP":
                    EmitData(line.OperandText, 3, emit, result);
                    break;
                case "DS":
                    EmitStorage(line.OperandText, emit, result);
                    break;
                case "NOP":
                    Emit(0, emit, result);
                    break;
                case "MV":
                    EmitMove(line.OperandText, emit, result);
                    break;
                case "MVP":
                    EmitMovePointer(line.OperandText, emit, result);
                    break;
                case "MVW":
                    EmitMoveWord(line.OperandText, emit, result);
                    break;
                case "MVL":
                    EmitMoveLong(line.OperandText, emit, result);
                    break;
                case "MVLD":
                    EmitInternalBinaryOpcode(line.OperandText, 0xCF, emit, result);
                    break;
                case "PMDF":
                    EmitPmdf(line.OperandText, emit, result);
                    break;
                case "EX":
                    EmitExchange(line.OperandText, emit, result);
                    break;
                case "EXW":
                    EmitInternalBinaryOpcode(line.OperandText, 0xC1, emit, result);
                    break;
                case "EXP":
                    EmitInternalBinaryOpcode(line.OperandText, 0xC2, emit, result);
                    break;
                case "EXL":
                    EmitInternalBinaryOpcode(line.OperandText, 0xC3, emit, result);
                    break;
                case "ADD":
                    EmitArithmetic(line.OperandText, 0x40, emit, result);
                    break;
                case "ADDB":
                    EmitTypedRegisterArithmetic(line.OperandText, 0x40, 0x46, emit, result);
                    break;
                case "ADDW":
                    EmitTypedRegisterArithmetic(line.OperandText, 0x40, 0x44, emit, result);
                    break;
                case "ADDP":
                    EmitTypedRegisterArithmetic(line.OperandText, 0x40, 0x45, emit, result);
                    break;
                case "SUB":
                    EmitArithmetic(line.OperandText, 0x48, emit, result);
                    break;
                case "SUBB":
                    EmitTypedRegisterArithmetic(line.OperandText, 0x48, 0x4E, emit, result);
                    break;
                case "SUBW":
                    EmitTypedRegisterArithmetic(line.OperandText, 0x48, 0x4C, emit, result);
                    break;
                case "SUBP":
                    EmitTypedRegisterArithmetic(line.OperandText, 0x48, 0x4D, emit, result);
                    break;
                case "ADC":
                    EmitArithmetic(line.OperandText, 0x50, emit, result);
                    break;
                case "SBC":
                    EmitArithmetic(line.OperandText, 0x58, emit, result);
                    break;
                case "ADCL":
                    EmitLongArithmetic(line.OperandText, 0x50, emit, result);
                    break;
                case "SBCL":
                    EmitLongArithmetic(line.OperandText, 0x58, emit, result);
                    break;
                case "DADL":
                    EmitLongArithmetic(line.OperandText, 0xC0, emit, result);
                    break;
                case "DSBL":
                    EmitLongArithmetic(line.OperandText, 0xD0, emit, result);
                    break;
                case "AND":
                    EmitLogical(line.OperandText, 0x70, emit, result);
                    break;
                case "OR":
                    EmitLogical(line.OperandText, 0x78, emit, result);
                    break;
                case "XOR":
                    EmitLogical(line.OperandText, 0x68, emit, result);
                    break;
                case "CMP":
                    EmitCompare(line.OperandText, emit, result);
                    break;
                case "TEST":
                    EmitLogical(line.OperandText, 0x64, emit, result);
                    break;
                case "CMPW":
                    EmitInternalCompare(line.OperandText, memoryMemoryOpcode: 0xC6, memoryRegisterOpcode: 0xD6, emit, result);
                    break;
                case "CMPP":
                    EmitInternalCompare(line.OperandText, memoryMemoryOpcode: 0xC7, memoryRegisterOpcode: 0xD7, emit, result);
                    break;
                case "INC":
                    EmitRegisterUnary(line.OperandText, 0x6C, emit, result);
                    break;
                case "DEC":
                    EmitRegisterUnary(line.OperandText, 0x7C, emit, result);
                    break;
                case "ROR":
                    EmitAccumulatorOrInternalUnary(line.OperandText, 0xE4, emit, result);
                    break;
                case "ROL":
                    EmitAccumulatorOrInternalUnary(line.OperandText, 0xE6, emit, result);
                    break;
                case "SHR":
                    EmitAccumulatorOrInternalUnary(line.OperandText, 0xF4, emit, result);
                    break;
                case "SHL":
                    EmitAccumulatorOrInternalUnary(line.OperandText, 0xF6, emit, result);
                    break;
                case "DSRL":
                    EmitInternalUnary(line.OperandText, 0xFC, emit, result);
                    break;
                case "DSLL":
                    EmitInternalUnary(line.OperandText, 0xEC, emit, result);
                    break;
                case "SWAP":
                    EmitAccumulatorUnary(line.OperandText, 0xEE, emit, result);
                    break;
                case "JP":
                    if (line.OperandText.Trim().Equals("X", StringComparison.OrdinalIgnoreCase))
                    {
                        Emit(0x11, emit, result);
                        Emit(0x04, emit, result);
                        break;
                    }

                    EmitAbsoluteJump(line.OperandText, 0x02, 2, emit, result);
                    break;
                case "JPF":
                    EmitAbsoluteJump(line.OperandText, 0x03, 3, emit, result);
                    break;
                case "JPZ":
                    EmitAbsoluteJump(line.OperandText, 0x14, 2, emit, result);
                    break;
                case "JPNZ":
                    EmitAbsoluteJump(line.OperandText, 0x15, 2, emit, result);
                    break;
                case "JPC":
                    EmitAbsoluteJump(line.OperandText, 0x16, 2, emit, result);
                    break;
                case "JPNC":
                    EmitAbsoluteJump(line.OperandText, 0x17, 2, emit, result);
                    break;
                case "CALL":
                    EmitAbsoluteJump(line.OperandText, 0x04, 2, emit, result);
                    break;
                case "CALLF":
                    EmitAbsoluteJump(line.OperandText, 0x05, 3, emit, result);
                    break;
                case "JR":
                    EmitRelativeJump(line.OperandText, 0x12, 0x13, emit, result);
                    break;
                case "JRZ":
                    EmitRelativeJump(line.OperandText, 0x18, 0x19, emit, result);
                    break;
                case "JRNZ":
                    EmitRelativeJump(line.OperandText, 0x1A, 0x1B, emit, result);
                    break;
                case "JRC":
                    EmitRelativeJump(line.OperandText, 0x1C, 0x1D, emit, result);
                    break;
                case "JRNC":
                    EmitRelativeJump(line.OperandText, 0x1E, 0x1F, emit, result);
                    break;
                case "PUSHU":
                    EmitStackRegister(line.OperandText, baseOpcode: 0x28, emit, result);
                    break;
                case "POPU":
                    EmitStackRegister(line.OperandText, baseOpcode: 0x38, emit, result);
                    break;
                case "PUSHS":
                    EmitStackRegister(line.OperandText, baseOpcode: 0x30, emit, result);
                    break;
                case "POPS":
                    EmitStackRegister(line.OperandText, baseOpcode: 0xB0, emit, result);
                    break;
                case "RET":
                    Emit(0x06, emit, result);
                    break;
                case "RETF":
                    Emit(0x07, emit, result);
                    break;
                case "RETI":
                    Emit(0x01, emit, result);
                    break;
                case "WAIT":
                    Emit(0xEF, emit, result);
                    break;
                case "TCL":
                    Emit(0xCE, emit, result);
                    break;
                case "HALT":
                    Emit(0xDE, emit, result);
                    break;
                case "OFF":
                    Emit(0xDF, emit, result);
                    break;
                case "IR":
                    Emit(0xFE, emit, result);
                    break;
                case "RESET":
                    Emit(0xFF, emit, result);
                    break;
                case "SC":
                    Emit(0x97, emit, result);
                    break;
                case "RC":
                    Emit(0x9F, emit, result);
                    break;
                case "END":
                    AddListingLine(emit, result, _locationCounter, lineByteStart, rawLine);
                    if (isIncludedEnd)
                    {
                        continue;
                    }

                    FinishSections();
                    result.StartAddress = _startAddress;
                    result.EndAddress = _locationCounter;
                    result.SourceLineCount = _expandedLines.Count;
                    CopySymbols(result);
                    CopySections(result);
                    CopyDependencies(result);
                    return result;
                case "":
                    break;
                    default:
                        throw new NotSupportedException(
                            $"opcode ou directive non encore portee: {mnemonic}");
                }

                AddListingLine(emit, result, mnemonic == "ORG" ? _locationCounter : lineAddress, lineByteStart, rawLine);
            }
            catch (Exception ex) when (ex is not NotSupportedException || !ex.Message.StartsWith("ligne ", StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException($"ligne {lineIndex + 1}: {ex.Message} | {rawLine.Trim()}", ex);
            }
        }

        FinishSections();
        result.StartAddress = _startAddress;
        result.EndAddress = _locationCounter;
        result.SourceLineCount = _expandedLines.Count;
        CopySymbols(result);
        CopySections(result);
        CopyDependencies(result);
        return result;
    }

    /// <summary>
    /// Action : ajoute une ligne de listing en associant adresse, octets emis et texte source.
    /// Donnees d'entree : parametres de la signature (bool emit, AssemblyResult result, long address, int byteStart, string sourceText) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private static void AddListingLine(bool emit, AssemblyResult result, long address, int byteStart, string sourceText)
    {
        if (!emit)
        {
            return;
        }

        var bytes = result.GeneratedBytes
            .Skip(byteStart)
            .Select(x => x.Value)
            .ToArray();
        result.ListingLines.Add(new ListingLine(address, bytes, sourceText.TrimEnd('\u001A', '\r', '\n')));
    }

    /// <summary>
    /// Action : gere les directives conditionnelles IF/ELSE/ENDIF et l'etat d'activation du bloc.
    /// Donnees d'entree : parametres de la signature (string mnemonic, string operand, Stack<bool> conditions, ref bool active) et etat courant necessaire.
    /// Donnees de sortie : booleen indiquant si le traitement a reussi ou si la condition est verifiee.
    /// </summary>
    private bool HandleCondition(string mnemonic, string operand, Stack<bool> conditions, ref bool active)
    {
        switch (mnemonic)
        {
            case "IFEQ":
            case "IFNE":
            case "IFGT":
            case "IFLT":
                conditions.Push(active);
                // Non-strict : une conditionnelle peut tester un symbole absent (traite comme 0),
                // y compris dans un bloc parent inactif. On ne veut pas d'erreur "symbole indefini" ici.
                var value = Eval(operand, strict: false);
                active = active && mnemonic switch
                {
                    "IFEQ" => value == 0,
                    "IFNE" => value != 0,
                    "IFGT" => value > 0,
                    _ => value < 0,
                };
                return true;
            case "ELSE":
                if (conditions.TryPeek(out var parent))
                {
                    active = parent && !active;
                }
                return true;
            case "ENDIF":
                if (conditions.TryPop(out var previous))
                {
                    active = previous;
                }
                return true;
            default:
                return false;
        }
    }

    /// <summary>
    /// Action : encode les formes de l'instruction MV.
    /// Donnees d'entree : parametres de la signature (string operandText, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitMove(string operandText, bool emit, AssemblyResult result)
    {
        var operands = SplitOperands(operandText);
        if (operands.Length != 2)
        {
            throw new NotSupportedException($"MV requires two operands: {operandText}");
        }

        var left = operands[0].Trim().ToUpperInvariant();
        var right = operands[1].Trim().ToUpperInvariant();
        if (left == "A" && right == "[X++]")
        {
            Emit(0x90, emit, result);
            Emit(0x24, emit, result);
            return;
        }

        if (left.StartsWith('[') && left.EndsWith(']') && IsRegister(right))
        {
            if (TryEmitIndexedStore(left[1..^1], right, emit, result))
            {
                return;
            }

            var address = Eval(left[1..^1]);
            Emit(RegisterToAbsoluteStoreOpcode(right), emit, result);
            Emit24(address, emit, result);
            return;
        }

        if (IsRegister(left) && right.StartsWith('[') && right.EndsWith(']'))
        {
            if (TryEmitIndexedLoad(left, right[1..^1], emit, result))
            {
                return;
            }

            var address = Eval(right[1..^1]);
            Emit(RegisterFromAbsoluteLoadOpcode(left), emit, result);
            Emit24(address, emit, result);
            return;
        }

        if (IsRegister(left) && IsInternalRamOperand(right))
        {
            var registerId = XasmRegisterId(left);
            if (registerId > 7)
            {
                throw new NotSupportedException($"registre destination non encore porte: {operandText}");
            }

            var source = ParseInternalRamOperand(right);
            EmitPrebyte(source.PreId, 0, emit, result);
            Emit(0x80 + registerId, emit, result);
            Emit(source.Value, emit, result);
            return;
        }

        if (IsInternalRamOperand(left) && IsRegister(right))
        {
            var registerId = XasmRegisterId(right);
            if (registerId > 7)
            {
                throw new NotSupportedException($"registre source non encore porte: {operandText}");
            }

            var target = ParseInternalRamOperand(left);
            EmitPrebyte(target.PreId, 0, emit, result);
            Emit(0xA0 + registerId, emit, result);
            Emit(target.Value, emit, result);
            return;
        }

        if (IsInternalRamOperand(left) &&
            !left[1..^1].TrimStart().StartsWith("BP", StringComparison.OrdinalIgnoreCase) &&
            !IsRegister(right))
        {
            var target = ParseInternalRamOperand(left);
            var rightAddress = right.StartsWith('(') && right.EndsWith(')')
                ? ParseInternalRamOperand(right)
                : (PreId: 0, Value: 0);
            EmitPrebyte(target.PreId, rightAddress.PreId, emit, result);
            if (right.Equals("A", StringComparison.OrdinalIgnoreCase))
            {
                Emit(0xA0, emit, result);
                Emit(target.Value, emit, result);
                return;
            }

            if (right.Equals("X", StringComparison.OrdinalIgnoreCase))
            {
                Emit(0xA4, emit, result);
                Emit(target.Value, emit, result);
                return;
            }

            if (right.StartsWith('(') && right.EndsWith(')'))
            {
                Emit(0xC8, emit, result);
                Emit(target.Value, emit, result);
                Emit(rightAddress.Value, emit, result);
                return;
            }

            if (right.StartsWith('[') && right.EndsWith(']'))
            {
                var inner = right[1..^1].Trim();
                if (inner.StartsWith('('))
                {
                    var close = inner.IndexOf(")", StringComparison.Ordinal);
                    if (close > 0)
                    {
                        var baseExpression = inner[1..close];
                        var offsetExpression = inner[(close + 1)..];
                        var baseAddress = ParseInternalRamOperand($"({baseExpression})");
                        EmitPrebyte(target.PreId, baseAddress.PreId, emit, result);
                        Emit(0xF0, emit, result);
                        Emit(offsetExpression.TrimStart().StartsWith('-') ? 0xC0 : 0x80, emit, result);
                        Emit(target.Value, emit, result);
                        Emit(baseAddress.Value, emit, result);
                        Emit(EvalDisplacement(offsetExpression), emit, result);
                        return;
                    }
                }

                if (TryEmitIndexedSuffix(inner, emit, result, out var suffix))
                {
                    Emit(0xE0, emit, result);
                    if (suffix.Length > 1 && (suffix[0] is >= 0x80 and <= 0x87 or >= 0xC0 and <= 0xC7))
                    {
                        Emit(suffix[0], emit, result);
                        Emit(target.Value, emit, result);
                        for (var i = 1; i < suffix.Length; i++)
                        {
                            Emit(suffix[i], emit, result);
                        }
                    }
                    else
                    {
                        EmitSuffix(suffix, emit, result);
                        Emit(target.Value, emit, result);
                    }

                    return;
                }

                Emit(0xD0, emit, result);
                Emit(target.Value, emit, result);
                Emit24(Eval(inner), emit, result);
                return;
            }

            Emit(0xCC, emit, result);
            Emit(target.Value, emit, result);
            Emit(Eval(operands[1]), emit, result);
            return;
        }

        if (IsInternalRamOperand(left) && IsInternalRamOperand(right))
        {
            var leftAddress = ParseInternalRamOperand(left);
            var rightAddress = ParseInternalRamOperand(right);
            EmitPrebyte(leftAddress.PreId, rightAddress.PreId, emit, result);
            Emit(0xC8, emit, result);
            Emit(leftAddress.Value, emit, result);
            Emit(rightAddress.Value, emit, result);
            return;
        }

        if (left.StartsWith('(') && left.EndsWith(')') && right.StartsWith("[(") && right.EndsWith(']'))
        {
            var close = right.IndexOf(")", StringComparison.Ordinal);
            if (close > 2)
            {
                var baseExpression = right[2..close];
                var offsetExpression = right[(close + 1)..^1];
                if (!baseExpression.TrimStart().StartsWith("BP", StringComparison.OrdinalIgnoreCase))
                {
                    Emit(0x22, emit, result);
                }

                Emit(0xF0, emit, result);
                Emit(offsetExpression.TrimStart().StartsWith('-') ? 0xC0 : 0x80, emit, result);
                Emit(InternalRamOffset(left, emit, result), emit, result);
                Emit(baseExpression.TrimStart().StartsWith("BP", StringComparison.OrdinalIgnoreCase)
                    ? InternalRamOffset($"({baseExpression})", emit, result)
                    : Eval(baseExpression), emit, result);
                Emit(EvalDisplacement(offsetExpression), emit, result);
                return;
            }
        }

        if (left.StartsWith('(') && left.EndsWith(')') && right.StartsWith('[') && right.EndsWith(']'))
        {
            var inner = right[1..^1].Trim();
            if (TryEmitIndexedSuffix(inner, emit, result, out var suffix))
            {
                Emit(0xE0, emit, result);
                if (suffix.Length > 1 && (suffix[0] is >= 0x80 and <= 0x87 or >= 0xC0 and <= 0xC7))
                {
                    Emit(suffix[0], emit, result);
                    Emit(InternalRamOffset(left, emit, result), emit, result);
                    for (var i = 1; i < suffix.Length; i++)
                    {
                        Emit(suffix[i], emit, result);
                    }
                }
                else
                {
                    EmitSuffix(suffix, emit, result);
                    Emit(InternalRamOffset(left, emit, result), emit, result);
                }

                return;
            }
        }

        if (left.StartsWith('(') && left.EndsWith(')'))
        {
            var address = Eval(left[1..^1]);
            var byteValue = Eval(operands[1]);
            Emit(0xCC, emit, result);
            Emit(address, emit, result);
            Emit(byteValue, emit, result);
            return;
        }

        if (left.StartsWith("[(") && left.EndsWith(']') && right.StartsWith('(') && right.EndsWith(')'))
        {
            var close = left.IndexOf(")", StringComparison.Ordinal);
            if (close > 2)
            {
                var baseExpression = left[2..close];
                var offsetExpression = left[(close + 1)..^1];
                var baseAddress = ParseInternalRamOperand($"({baseExpression})");
                var sourceAddress = ParseInternalRamOperand(right);
                EmitPrebyte(baseAddress.PreId, sourceAddress.PreId, emit, result);
                Emit(0xF8, emit, result);
                Emit(offsetExpression.TrimStart().StartsWith('-') ? 0xC0 : 0x80, emit, result);
                Emit(baseAddress.Value, emit, result);
                Emit(sourceAddress.Value, emit, result);
                Emit(EvalDisplacement(offsetExpression), emit, result);
                return;
            }
        }

        if (left.StartsWith('[') && left.EndsWith(']') && right.StartsWith('(') && right.EndsWith(')'))
        {
            var sourceAddress = ParseInternalRamOperand(right);
            if (TryEmitIndexedSuffix(left[1..^1], emit, result, out var suffix))
            {
                EmitPrebyte(sourceAddress.PreId, 0, emit, result);
                Emit(0xE8, emit, result);
                if (suffix.Length > 1 && (suffix[0] is >= 0x80 and <= 0x87 or >= 0xC0 and <= 0xC7))
                {
                    Emit(suffix[0], emit, result);
                    Emit(sourceAddress.Value, emit, result);
                    for (var i = 1; i < suffix.Length; i++)
                    {
                        Emit(suffix[i], emit, result);
                    }
                }
                else
                {
                    EmitSuffix(suffix, emit, result);
                    Emit(sourceAddress.Value, emit, result);
                }
                return;
            }

            var address = Eval(left[1..^1]);
            EmitPrebyte(sourceAddress.PreId, 0, emit, result);
            Emit(0xD8, emit, result);
            Emit24(address, emit, result);
            Emit(sourceAddress.Value, emit, result);
            return;
        }

        if (IsRegister(left) && IsRegister(right))
        {
            var leftId = XasmRegisterId(left);
            var rightId = XasmRegisterId(right);
            if (leftId <= 7 && rightId <= 7)
            {
                Emit(0xFD, emit, result);
                Emit(leftId * 16 + rightId, emit, result);
                return;
            }

            if (leftId == 0 && rightId == 8)
            {
                Emit(0x74, emit, result);
                return;
            }

            if (leftId == 8 && rightId == 0)
            {
                Emit(0x75, emit, result);
                return;
            }
        }

        var value = Eval(operands[1]);
        switch (left)
        {
            case "A":
                Emit(0x08, emit, result);
                Emit(value, emit, result);
                break;
            case "BA":
                Emit(0x0A, emit, result);
                Emit(value, emit, result);
                Emit(value >> 8, emit, result);
                break;
            case "IL":
                Emit(0x09, emit, result);
                Emit(value, emit, result);
                break;
            case "I":
                Emit(0x0B, emit, result);
                Emit(value, emit, result);
                Emit(value >> 8, emit, result);
                break;
            case "X":
                Emit(0x0C, emit, result);
                Emit24(value, emit, result);
                break;
            case "Y":
                Emit(0x0D, emit, result);
                Emit24(value, emit, result);
                break;
            case "U":
                Emit(0x0E, emit, result);
                Emit24(value, emit, result);
                break;
            case "S":
                Emit(0x0F, emit, result);
                Emit24(value, emit, result);
                break;
            default:
                throw new NotSupportedException($"MV form not ported yet: {operandText}");
        }
    }

    /// <summary>
    /// Action : encode les formes de l'instruction MVP.
    /// Donnees d'entree : parametres de la signature (string operandText, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitMovePointer(string operandText, bool emit, AssemblyResult result)
    {
        var operands = SplitOperands(operandText);
        if (operands.Length != 2)
        {
            throw new NotSupportedException($"MVP requires two operands: {operandText}");
        }

        var left = operands[0].Trim();
        var right = operands[1].Trim();
        if (left.StartsWith('(') && left.EndsWith(')') && right.StartsWith('(') && right.EndsWith(')'))
        {
            var leftAddress = ParseInternalRamOperand(left);
            var rightAddress = ParseInternalRamOperand(right);
            EmitPrebyte(leftAddress.PreId, rightAddress.PreId, emit, result);
            Emit(0xCA, emit, result);
            Emit(leftAddress.Value, emit, result);
            Emit(rightAddress.Value, emit, result);
            return;
        }

        if (left.StartsWith('(') && left.EndsWith(')') && right.StartsWith("[(") && right.EndsWith(']'))
        {
            var close = right.IndexOf(")", StringComparison.Ordinal);
            if (close > 2)
            {
                var baseExpression = right[2..close];
                var offsetExpression = right[(close + 1)..^1];
                Emit(0xF2, emit, result);
                Emit(offsetExpression.TrimStart().StartsWith('-') ? 0xC0 : 0x80, emit, result);
                Emit(Eval(left[1..^1]), emit, result);
                Emit(Eval(baseExpression), emit, result);
                Emit(EvalDisplacement(offsetExpression), emit, result);
                return;
            }
        }

        if (left.StartsWith('(') && left.EndsWith(')') && right.StartsWith('[') && right.EndsWith(']'))
        {
            var inner = right[1..^1].Trim();
            if (TryEmitIndexedSuffix(inner, emit, result, out var suffix))
            {
                var target = ParseInternalRamOperand(left);
                EmitPrebyte(target.PreId, 0, emit, result);

                Emit(0xE2, emit, result);
                Emit(suffix[0], emit, result);
                Emit(target.Value, emit, result);
                for (var i = 1; i < suffix.Length; i++)
                {
                    Emit(suffix[i], emit, result);
                }

                return;
            }

            var targetAddress = ParseInternalRamOperand(left);
            EmitPrebyte(targetAddress.PreId, 0, emit, result);
            Emit(0xD2, emit, result);
            Emit(targetAddress.Value, emit, result);
            Emit24(Eval(inner), emit, result);
            return;
        }

        if (left.StartsWith('(') && left.EndsWith(')'))
        {
            var target = ParseInternalRamOperand(left);
            EmitPrebyte(target.PreId, 0, emit, result);
            Emit(0xDC, emit, result);
            Emit(target.Value, emit, result);
            Emit24(Eval(right), emit, result);
            return;
        }

        if (left.StartsWith("[(") && left.EndsWith(")]") && right.StartsWith('(') && right.EndsWith(')'))
        {
            Emit(0xFA, emit, result);
            Emit(0x00, emit, result);
            Emit(Eval(left[2..^2]), emit, result);
            Emit(Eval(right[1..^1]), emit, result);
            return;
        }

        if (left.StartsWith('[') && left.EndsWith(']') &&
            !left[1..^1].TrimStart().StartsWith('(') &&
            right.StartsWith('(') && right.EndsWith(')'))
        {
            if (TryEmitIndexedSuffix(left[1..^1], emit, result, out var suffix))
            {
                var source = Eval(right[1..^1]);
                Emit(0xEA, emit, result);
                if (suffix.Length > 1 && (suffix[0] is >= 0x80 and <= 0x87 or >= 0xC0 and <= 0xC7))
                {
                    Emit(suffix[0], emit, result);
                    Emit(source, emit, result);
                    for (var i = 1; i < suffix.Length; i++)
                    {
                        Emit(suffix[i], emit, result);
                    }
                }
                else
                {
                    EmitSuffix(suffix, emit, result);
                    Emit(source, emit, result);
                }
                return;
            }

            Emit(0xDA, emit, result);
            Emit24(Eval(left[1..^1]), emit, result);
            Emit(Eval(right[1..^1]), emit, result);
            return;
        }

        if (left.StartsWith("[(") && left.EndsWith(']') && right.StartsWith('(') && right.EndsWith(')'))
        {
            var close = left.IndexOf(")", StringComparison.Ordinal);
            if (close > 2)
            {
                var baseExpression = left[2..close];
                var offsetExpression = left[(close + 1)..^1];
                Emit(0xFA, emit, result);
                Emit(offsetExpression.TrimStart().StartsWith('-') ? 0xC0 : 0x80, emit, result);
                Emit(Eval(baseExpression), emit, result);
                Emit(Eval(right[1..^1]), emit, result);
                Emit(EvalDisplacement(offsetExpression), emit, result);
                return;
            }
        }

        throw new NotSupportedException($"MVP form not ported yet: {operandText}");
    }

    /// <summary>
    /// Action : encode les formes de l'instruction MVW.
    /// Donnees d'entree : parametres de la signature (string operandText, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitMoveWord(string operandText, bool emit, AssemblyResult result)
    {
        var operands = SplitOperands(operandText);
        if (operands.Length != 2)
        {
            throw new NotSupportedException($"MVW requires two operands: {operandText}");
        }

        var left = operands[0].Trim();
        var right = operands[1].Trim();
        if (left.StartsWith('(') && left.EndsWith(')') && right.StartsWith('[') && right.EndsWith(']'))
        {
            var inner = right[1..^1].Trim();
            if (TryEmitIndexedSuffix(inner, emit, result, out var suffix))
            {
                Emit(0xE1, emit, result);
                EmitSuffix(suffix, emit, result);
                Emit(InternalRamOffset(left, emit, result), emit, result);
                return;
            }
        }

        if (left.StartsWith("[(") && left.EndsWith(']') && right.StartsWith('(') && right.EndsWith(')'))
        {
            var close = left.IndexOf(")", StringComparison.Ordinal);
            if (close > 2)
            {
                var baseExpression = left[2..close];
                var offsetExpression = left[(close + 1)..^1];
                Emit(0xF9, emit, result);
                Emit(offsetExpression.TrimStart().StartsWith('-') ? 0xC0 : 0x80, emit, result);
                Emit(InternalRamOffset($"({baseExpression})", emit, result), emit, result);
                Emit(InternalRamOffset(right, emit, result), emit, result);
                Emit(EvalDisplacement(offsetExpression), emit, result);
                return;
            }
        }

        if (left.StartsWith('[') && left.EndsWith(']') && right.StartsWith('(') && right.EndsWith(')'))
        {
            var inner = left[1..^1].Trim();
            if (TryEmitIndexedSuffix(inner, emit, result, out var suffix))
            {
                Emit(0xE9, emit, result);
                EmitSuffix(suffix, emit, result);
                Emit(InternalRamOffset(right, emit, result), emit, result);
                return;
            }
        }

        if (left.StartsWith('(') && left.EndsWith(')') && !right.StartsWith('[') && !right.StartsWith('('))
        {
            var leftOffset = InternalRamOffset(left, emit, result);
            Emit(0xCD, emit, result);
            Emit(leftOffset, emit, result);
            var value = Eval(right);
            Emit(value, emit, result);
            Emit(value >> 8, emit, result);
            return;
        }

        if (left.StartsWith('(') && left.EndsWith(')') && right.StartsWith('[') && right.EndsWith(']'))
        {
            var inner = right[1..^1].Trim();
            if (!IsIndexExpression(inner))
            {
                Emit(0xD1, emit, result);
                Emit(InternalRamOffset(left, emit, result), emit, result);
                Emit24(Eval(inner), emit, result);
                return;
            }
        }

        if (left.StartsWith('(') && left.EndsWith(')') && right.StartsWith('(') && right.EndsWith(')'))
        {
            var leftInner = left[1..^1].Trim();
            if (!leftInner.StartsWith("BP", StringComparison.OrdinalIgnoreCase))
            {
                Emit(0x30, emit, result);
            }

            Emit(0xC9, emit, result);
            Emit(leftInner.StartsWith("BP", StringComparison.OrdinalIgnoreCase) ? InternalRamOffset(left, emit, result) : Eval(leftInner), emit, result);
            Emit(InternalRamOffset(right, emit, result), emit, result);
            return;
        }

        if (left.StartsWith('[') && left.EndsWith(']') && right.StartsWith('(') && right.EndsWith(')'))
        {
            Emit(0xD9, emit, result);
            Emit24(Eval(left[1..^1]), emit, result);
            Emit(InternalRamOffset(right, emit, result), emit, result);
            return;
        }

        if (left.StartsWith("[(") && left.EndsWith(']') && right.StartsWith('(') && right.EndsWith(')'))
        {
            var close = left.IndexOf(")", StringComparison.Ordinal);
            if (close > 2)
            {
                var baseExpression = left[2..close];
                var offsetExpression = left[(close + 1)..^1];
                Emit(0xF9, emit, result);
                Emit(0xC0, emit, result);
                Emit(Eval(baseExpression), emit, result);
                Emit(Eval(right[1..^1]), emit, result);
                Emit(EvalDisplacement(offsetExpression), emit, result);
                return;
            }
        }

        throw new NotSupportedException($"MVW form not ported yet: {operandText}");
    }

    /// <summary>
    /// Action : encode les formes de l'instruction MVL.
    /// Donnees d'entree : parametres de la signature (string operandText, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitMoveLong(string operandText, bool emit, AssemblyResult result)
    {
        var operands = SplitOperands(operandText);
        if (operands.Length != 2)
        {
            throw new NotSupportedException($"MVL requires two operands: {operandText}");
        }

        var left = operands[0].Trim();
        var right = operands[1].Trim();
        if (left.StartsWith('(') && left.EndsWith(')') && right.StartsWith('(') && right.EndsWith(')'))
        {
            var leftAddress = ParseInternalRamOperand(left);
            var rightAddress = ParseInternalRamOperand(right);
            EmitPrebyte(leftAddress.PreId, rightAddress.PreId, emit, result);
            Emit(0xCB, emit, result);
            Emit(leftAddress.Value, emit, result);
            Emit(rightAddress.Value, emit, result);
            return;
        }

        if (left.StartsWith("[(") && left.EndsWith(']') && right.StartsWith('(') && right.EndsWith(')'))
        {
            var close = left.IndexOf(")", StringComparison.Ordinal);
            if (close > 2)
            {
                var baseExpression = left[2..close];
                var offsetExpression = left[(close + 1)..^1];
                Emit(0x22, emit, result);
                Emit(0xFB, emit, result);
                Emit(0x80, emit, result);
                Emit(InternalRamOffset($"({baseExpression})", emit, result), emit, result);
                Emit(Eval(right[1..^1]), emit, result);
                Emit(EvalDisplacement(offsetExpression), emit, result);
                return;
            }
        }

        if (left.StartsWith('(') && left.EndsWith(')') && right.StartsWith("[(") && right.EndsWith(']'))
        {
            var close = right.IndexOf(")", StringComparison.Ordinal);
            if (close > 2)
            {
                var baseExpression = right[2..close];
                var offsetExpression = right[(close + 1)..^1];
                var leftOffset = InternalRamOffset(left, emit, result);
                Emit(0xF3, emit, result);
                Emit(0x80, emit, result);
                Emit(leftOffset, emit, result);
                Emit(InternalRamOffset($"({baseExpression})", emit, result), emit, result);
                Emit(EvalDisplacement(offsetExpression), emit, result);
                return;
            }
        }

        if (left.StartsWith('(') && left.EndsWith(')') && right.StartsWith('[') && right.EndsWith(']'))
        {
            var inner = right[1..^1].Trim();
            if (TryEmitIndexedSuffix(inner, emit, result, out var suffix))
            {
                Emit(0xE3, emit, result);
                EmitSuffix(suffix, emit, result);
                Emit(InternalRamOffset(left, emit, result), emit, result);
                return;
            }

            Emit(0xD3, emit, result);
            Emit(InternalRamOffset(left, emit, result), emit, result);
            Emit24(Eval(inner), emit, result);
            return;
        }

        if (left.StartsWith('[') && left.EndsWith(']') && right.StartsWith('(') && right.EndsWith(')'))
        {
            var inner = left[1..^1].Trim();
            if (TryEmitIndexedSuffix(inner, emit, result, out var suffix))
            {
                Emit(0xEB, emit, result);
                EmitSuffix(suffix, emit, result);
                Emit(InternalRamOffset(right, emit, result), emit, result);
                return;
            }

            Emit(0xDB, emit, result);
            Emit24(Eval(inner), emit, result);
            Emit(InternalRamOffset(right, emit, result), emit, result);
            return;
        }

        throw new NotSupportedException($"MVL form not ported yet: {operandText}");
    }

    /// <summary>
    /// Action : encode l'instruction EX entre registres ou memoire interne.
    /// Donnees d'entree : parametres de la signature (string operandText, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitExchange(string operandText, bool emit, AssemblyResult result)
    {
        var operands = SplitOperands(operandText);
        if (operands.Length == 2 &&
            operands[0].Trim().Equals("A", StringComparison.OrdinalIgnoreCase) &&
            operands[1].Trim().Equals("B", StringComparison.OrdinalIgnoreCase))
        {
            Emit(0xDD, emit, result);
            return;
        }

        if (operands.Length == 2 &&
            operands[0].Trim().StartsWith('(') &&
            operands[1].Trim().StartsWith('('))
        {
            EmitInternalBinaryOpcode(operandText, 0xC0, emit, result);
            return;
        }

        throw new NotSupportedException($"EX form not ported yet: {operandText}");
    }

    /// <summary>
    /// Action : encode une operation binaire appliquee a deux operandes de RAM interne.
    /// Donnees d'entree : parametres de la signature (string operandText, int opcode, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitInternalBinaryOpcode(string operandText, int opcode, bool emit, AssemblyResult result)
    {
        var operands = SplitOperands(operandText);
        if (operands.Length != 2)
        {
            throw new NotSupportedException($"operation interne invalide: {operandText}");
        }

        var left = operands[0].Trim();
        var right = operands[1].Trim();
        if (left.StartsWith('(') && left.EndsWith(')') && right.StartsWith('(') && right.EndsWith(')'))
        {
            var leftAddress = ParseInternalRamOperand(left);
            var rightAddress = ParseInternalRamOperand(right);
            EmitPrebyte(leftAddress.PreId, rightAddress.PreId, emit, result);
            Emit(opcode, emit, result);
            Emit(leftAddress.Value, emit, result);
            Emit(rightAddress.Value, emit, result);
            return;
        }

        throw new NotSupportedException($"operation interne non encore portee: {operandText}");
    }

    /// <summary>
    /// Action : essaie d'encoder un stockage via adressage indexe.
    /// Donnees d'entree : parametres de la signature (string indexExpression, string source, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : booleen indiquant si le traitement a reussi ou si la condition est verifiee.
    /// </summary>
    private bool TryEmitIndexedStore(string indexExpression, string source, bool emit, AssemblyResult result)
    {
        if (!TryEmitIndexedSuffix(indexExpression, emit, result, out var suffix))
        {
            return false;
        }

        var internalBase = suffix.Length > 1 && suffix[0] is 0x00 or 0x80 or 0xC0;
        var opcode = source.Trim().ToUpperInvariant() switch
        {
            "A" => internalBase ? 0xB8 : 0xB0,
            "IL" => internalBase ? 0xB9 : 0xB1,
            "BA" => internalBase ? 0xBA : 0xB2,
            "I" => internalBase ? 0xBB : 0xB3,
            "X" => internalBase ? 0xBC : 0xB4,
            "Y" => internalBase ? 0xBD : 0xB5,
            "U" => internalBase ? 0xBE : 0xB6,
            "S" => internalBase ? 0xBF : 0xB7,
            _ => -1,
        };
        if (opcode < 0)
        {
            return false;
        }

        Emit(opcode, emit, result);
        EmitSuffix(suffix, emit, result);
        return true;
    }

    /// <summary>
    /// Action : essaie d'encoder un chargement via adressage indexe.
    /// Donnees d'entree : parametres de la signature (string destination, string indexExpression, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : booleen indiquant si le traitement a reussi ou si la condition est verifiee.
    /// </summary>
    private bool TryEmitIndexedLoad(string destination, string indexExpression, bool emit, AssemblyResult result)
    {
        if (!TryEmitIndexedSuffix(indexExpression, emit, result, out var suffix))
        {
            return false;
        }

        var internalBase = suffix.Length > 1 && suffix[0] is 0x00 or 0x80 or 0xC0;
        var opcode = destination.Trim().ToUpperInvariant() switch
        {
            "A" => internalBase ? 0x98 : 0x90,
            "IL" => internalBase ? 0x99 : 0x91,
            "BA" => internalBase ? 0x9A : 0x92,
            "I" => internalBase ? 0x9B : 0x93,
            "X" => internalBase ? 0x9C : 0x94,
            "Y" => internalBase ? 0x9D : 0x95,
            "U" => internalBase ? 0x9E : 0x96,
            "S" => internalBase ? 0x9F : 0x97,
            _ => -1,
        };
        if (opcode < 0)
        {
            return false;
        }

        Emit(opcode, emit, result);
        EmitSuffix(suffix, emit, result);
        return true;
    }

    /// <summary>
    /// Action : essaie d'encoder une instruction utilisant un suffixe d'adressage indexe.
    /// Donnees d'entree : parametres de la signature (int opcode, string indexExpression, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : booleen indiquant si le traitement a reussi ou si la condition est verifiee.
    /// </summary>
    private bool TryEmitIndexedAccess(int opcode, string indexExpression, bool emit, AssemblyResult result)
    {
        var expr = indexExpression.Trim().ToUpperInvariant();
        if (TryEmitIndexedSuffix(expr, emit, result, out var suffix))
        {
            Emit(opcode, emit, result);
            EmitSuffix(suffix, emit, result);
            return true;
        }

        return false;
    }

    /// <summary>
    /// Action : analyse une expression indexee et prepare les octets de suffixe.
    /// Donnees d'entree : parametres de la signature (string indexExpression, bool emit, AssemblyResult result, out int[] suffix) et etat courant necessaire.
    /// Donnees de sortie : booleen indiquant si le traitement a reussi ou si la condition est verifiee.
    /// </summary>
    private bool TryEmitIndexedSuffix(string indexExpression, bool emit, AssemblyResult result, out int[] suffix)
    {
        var expr = indexExpression.Trim().ToUpperInvariant();
        if (expr.StartsWith('('))
        {
            var close = expr.IndexOf(')');
            if (close > 1)
            {
                var baseExpression = expr[1..close];
                var offsetExpression = expr[(close + 1)..].Trim();
                if (string.IsNullOrEmpty(offsetExpression))
                {
                    suffix = [0x00, (int)Eval(baseExpression)];
                    return true;
                }

                suffix =
                [
                    offsetExpression.StartsWith('-') ? 0xC0 : 0x80,
                    (int)Eval(baseExpression),
                    EvalDisplacement(offsetExpression)
                ];
                return true;
            }
        }

        switch (expr)
        {
            case "X":
                suffix = [0x04];
                return true;
            case "Y":
                suffix = [0x05];
                return true;
            case "U":
                suffix = [0x06];
                return true;
            case "S":
                suffix = [0x07];
                return true;
            case "X++":
                suffix = [0x24];
                return true;
            case "Y++":
                suffix = [0x25];
                return true;
            case "U++":
                suffix = [0x26];
                return true;
            case "S++":
                suffix = [0x27];
                return true;
            case "--X":
                suffix = [0x34];
                return true;
            case "--Y":
                suffix = [0x35];
                return true;
            case "--U":
                suffix = [0x36];
                return true;
            case "--S":
                suffix = [0x37];
                return true;
        }

        if (expr.StartsWith("X-", StringComparison.OrdinalIgnoreCase))
        {
            suffix = [0xC4, (int)Eval(expr[2..])];
            return true;
        }

        if (expr.StartsWith("Y-", StringComparison.OrdinalIgnoreCase))
        {
            suffix = [0xC5, (int)Eval(expr[2..])];
            return true;
        }

        if (expr.StartsWith("U-", StringComparison.OrdinalIgnoreCase))
        {
            suffix = [0xC6, (int)Eval(expr[2..])];
            return true;
        }

        if (expr.StartsWith("S-", StringComparison.OrdinalIgnoreCase))
        {
            suffix = [0xC7, (int)Eval(expr[2..])];
            return true;
        }

        if (expr.StartsWith("X+", StringComparison.OrdinalIgnoreCase))
        {
            suffix = [0x84, (int)Eval(expr[2..])];
            return true;
        }

        if (expr.StartsWith("Y+", StringComparison.OrdinalIgnoreCase))
        {
            suffix = [0x85, (int)Eval(expr[2..])];
            return true;
        }

        if (expr.StartsWith("U+", StringComparison.OrdinalIgnoreCase))
        {
            suffix = [0x86, (int)Eval(expr[2..])];
            return true;
        }

        if (expr.StartsWith("S+", StringComparison.OrdinalIgnoreCase))
        {
            suffix = [0x87, (int)Eval(expr[2..])];
            return true;
        }

        suffix = [];
        return false;
    }

    /// <summary>
    /// Action : emet les octets de suffixe calcules pour une instruction indexee.
    /// Donnees d'entree : parametres de la signature (int[] suffix, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitSuffix(int[] suffix, bool emit, AssemblyResult result)
    {
        foreach (var value in suffix)
        {
            Emit(value, emit, result);
        }
    }

    /// <summary>
    /// Action : detecte si une expression correspond a un adressage indexe.
    /// Donnees d'entree : parametres de la signature (string expression) et etat courant necessaire.
    /// Donnees de sortie : booleen indiquant si le traitement a reussi ou si la condition est verifiee.
    /// </summary>
    private static bool IsIndexExpression(string expression)
    {
        var expr = expression.Trim().ToUpperInvariant();
        return expr is "X" or "Y" or "U" or "S" or "X++" or "Y++" or "U++" or "S++" or "--X" or "--Y" or "--U" or "--S" ||
               expr.StartsWith("X+", StringComparison.OrdinalIgnoreCase) ||
               expr.StartsWith("X-", StringComparison.OrdinalIgnoreCase) ||
               expr.StartsWith("Y+", StringComparison.OrdinalIgnoreCase) ||
               expr.StartsWith("Y-", StringComparison.OrdinalIgnoreCase) ||
               expr.StartsWith("U+", StringComparison.OrdinalIgnoreCase) ||
               expr.StartsWith("U-", StringComparison.OrdinalIgnoreCase) ||
               expr.StartsWith("S+", StringComparison.OrdinalIgnoreCase) ||
               expr.StartsWith("S-", StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Action : encode un saut ou appel avec adresse absolue.
    /// Donnees d'entree : parametres de la signature (string operandText, int opcode, int addressBytes, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitAbsoluteJump(string operandText, int opcode, int addressBytes, bool emit, AssemblyResult result)
    {
        var value = Eval(operandText.Trim());
        Emit(opcode, emit, result);
        Emit(value, emit, result);
        Emit(value >> 8, emit, result);
        if (addressBytes == 3)
        {
            Emit(value >> 16, emit, result);
        }
    }

    /// <summary>
    /// Action : encode un saut relatif en choisissant le sens et le deplacement.
    /// Donnees d'entree : parametres de la signature (string operandText, int forwardOpcode, int backwardOpcode, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitRelativeJump(string operandText, int forwardOpcode, int backwardOpcode, bool emit, AssemblyResult result)
    {
        if (!emit)
        {
            Emit(0, emit, result);
            Emit(0, emit, result);
            return;
        }

        var target = ResolveRelativeTarget(operandText.Trim());
        var delta = target - _locationCounter - 2;
        if (delta is >= 0 and <= 255)
        {
            Emit(forwardOpcode, emit, result);
            Emit(delta, emit, result);
        }
        else if (delta < 0 && delta >= -255)
        {
            Emit(backwardOpcode, emit, result);
            Emit(-delta, emit, result);
        }
        else
        {
            throw new InvalidOperationException(
                $"Branch too far: {operandText.Trim()} from {_locationCounter:X6}h to {target:X6}h");
        }
    }

    /// <summary>
    /// Action : encode les instructions de pile appliquees aux registres.
    /// Donnees d'entree : parametres de la signature (string operandText, int baseOpcode, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitStackRegister(string operandText, int baseOpcode, bool emit, AssemblyResult result)
    {
        var register = operandText.Trim().TrimStart('!').ToUpperInvariant();
        if (baseOpcode == 0x30)
        {
            if (register == "F")
            {
                Emit(0x4F, emit, result);
                return;
            }

            if (register == "IMR")
            {
                Emit(0x30, emit, result);
                Emit(0xE8, emit, result);
                Emit(0x37, emit, result);
                Emit(0xFB, emit, result);
                return;
            }

            var stackId = XasmRegisterId(register);
            if (stackId > 7)
            {
                throw new NotSupportedException($"registre stack non encore porte: {operandText.Trim()}");
            }

            Emit(0xB0 + stackId, emit, result);
            Emit(0x37, emit, result);
            return;
        }

        if (baseOpcode == 0xB0)
        {
            if (register == "F")
            {
                Emit(0x5F, emit, result);
                return;
            }

            if (register == "IMR")
            {
                Emit(0x30, emit, result);
                Emit(0xE4, emit, result);
                Emit(0x2F, emit, result);
                Emit(0xFB, emit, result);
                return;
            }

            var stackId = XasmRegisterId(register);
            if (stackId > 7)
            {
                throw new NotSupportedException($"registre stack non encore porte: {operandText.Trim()}");
            }

            Emit(0x90 + stackId, emit, result);
            Emit(0x27, emit, result);
            return;
        }

        var id = register switch
        {
            "A" => 0,
            "IL" => 1,
            "BA" => 2,
            "I" => 3,
            "X" => 4,
            "Y" => 5,
            "F" => 6,
            "IMR" => 7,
            _ => throw new NotSupportedException($"registre stack non encore porte: {operandText.Trim()}"),
        };

        Emit(baseOpcode + id, emit, result);
    }

    /// <summary>
    /// Action : encode une instruction de l'accumulateur A avec valeur immediate.
    /// Donnees d'entree : parametres de la signature (string operandText, int opcode, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitAImmediate(string operandText, int opcode, bool emit, AssemblyResult result)
    {
        var operands = SplitOperands(operandText);
        if (operands.Length != 2 || !operands[0].Trim().Equals("A", StringComparison.OrdinalIgnoreCase))
        {
            throw new NotSupportedException($"forme immediate A non encore portee: {operandText}");
        }

        Emit(opcode, emit, result);
        Emit(Eval(operands[1]), emit, result);
    }

    /// <summary>
    /// Action : encode les operations arithmetiques principales.
    /// Donnees d'entree : parametres de la signature (string operandText, int offset, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitArithmetic(string operandText, int offset, bool emit, AssemblyResult result)
    {
        var operands = SplitOperands(operandText);
        if (operands.Length != 2)
        {
            throw new NotSupportedException($"operation arithmetique invalide: {operandText}");
        }

        var left = operands[0].Trim();
        var right = operands[1].Trim();
        if (left.Equals("A", StringComparison.OrdinalIgnoreCase) && right.StartsWith('(') && right.EndsWith(')'))
        {
            var rightAddress = ParseInternalRamOperand(right);
            EmitPrebyte(rightAddress.PreId, 0, emit, result);
            Emit(offset + 2, emit, result);
            Emit(rightAddress.Value, emit, result);
            return;
        }

        if (left.Equals("A", StringComparison.OrdinalIgnoreCase) && !IsRegister(right))
        {
            Emit(offset, emit, result);
            Emit(Eval(right), emit, result);
            return;
        }

        if (IsRegister(left) && IsRegister(right))
        {
            var leftId = XasmRegisterId(left);
            var rightId = XasmRegisterId(right);
            if (rightId > 7)
            {
                throw new NotSupportedException($"registre droit non encore porte: {operandText}");
            }

            if (leftId is 0 or 1)
            {
                Emit(offset + 6, emit, result);
            }
            else if (leftId is 2 or 3)
            {
                Emit(offset + 4, emit, result);
            }
            else if (leftId is >= 4 and <= 7)
            {
                Emit(offset + 5, emit, result);
            }
            else
            {
                throw new NotSupportedException($"registre gauche non encore porte: {operandText}");
            }

            Emit(leftId * 16 + rightId, emit, result);
            return;
        }

        if (left.StartsWith('(') && left.EndsWith(')') && !IsRegister(right))
        {
            var leftAddress = ParseInternalRamOperand(left);
            EmitPrebyte(leftAddress.PreId, 0, emit, result);
            Emit(offset + 1, emit, result);
            Emit(leftAddress.Value, emit, result);
            Emit(Eval(right), emit, result);
            return;
        }

        if (left.StartsWith('(') && left.EndsWith(')') && right.Equals("A", StringComparison.OrdinalIgnoreCase))
        {
            var leftAddress = ParseInternalRamOperand(left);
            EmitPrebyte(leftAddress.PreId, 0, emit, result);
            Emit(offset + 3, emit, result);
            Emit(leftAddress.Value, emit, result);
            return;
        }

        throw new NotSupportedException($"forme arithmetique non encore portee: {operandText}");
    }

    /// <summary>
    /// Action : encode les operations arithmetiques longues.
    /// Donnees d'entree : parametres de la signature (string operandText, int offset, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitLongArithmetic(string operandText, int offset, bool emit, AssemblyResult result)
    {
        var operands = SplitOperands(operandText);
        if (operands.Length != 2)
        {
            throw new NotSupportedException($"operation longue invalide: {operandText}");
        }

        var left = operands[0].Trim();
        var right = operands[1].Trim();
        if (left.StartsWith('(') && left.EndsWith(')') && right.StartsWith('(') && right.EndsWith(')'))
        {
            var leftAddress = ParseInternalRamOperand(left);
            var rightAddress = ParseInternalRamOperand(right);
            EmitPrebyte(leftAddress.PreId, rightAddress.PreId, emit, result);
            Emit(offset + 4, emit, result);
            Emit(leftAddress.Value, emit, result);
            Emit(rightAddress.Value, emit, result);
            return;
        }

        if (left.StartsWith('(') && left.EndsWith(')') && right.Equals("A", StringComparison.OrdinalIgnoreCase))
        {
            var leftAddress = ParseInternalRamOperand(left);
            EmitPrebyte(leftAddress.PreId, 0, emit, result);
            Emit(offset + 5, emit, result);
            Emit(leftAddress.Value, emit, result);
            return;
        }

        throw new NotSupportedException($"operation longue non encore portee: {operandText}");
    }

    /// <summary>
    /// Action : encode une operation arithmetique specialisee par registre et type.
    /// Donnees d'entree : parametres de la signature (string operandText, int offset, int opcode, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitTypedRegisterArithmetic(string operandText, int offset, int opcode, bool emit, AssemblyResult result)
    {
        var operands = SplitOperands(operandText);
        if (operands.Length != 2 || !IsRegister(operands[0]) || !IsRegister(operands[1]))
        {
            EmitArithmetic(operandText, offset, emit, result);
            return;
        }

        var leftId = XasmRegisterId(operands[0]);
        var rightId = XasmRegisterId(operands[1]);
        if (rightId > 7)
        {
            throw new NotSupportedException($"registre droit non encore porte: {operandText}");
        }

        Emit(opcode, emit, result);
        Emit(leftId * 16 + rightId, emit, result);
    }

    /// <summary>
    /// Action : encode l'instruction PMDF.
    /// Donnees d'entree : parametres de la signature (string operandText, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitPmdf(string operandText, bool emit, AssemblyResult result)
    {
        var operands = SplitOperands(operandText);
        if (operands.Length != 2 || !operands[0].Trim().StartsWith('(') || !operands[0].Trim().EndsWith(')'))
        {
            throw new NotSupportedException($"PMDF form not ported yet: {operandText}");
        }

        var leftOffset = InternalRamOffset(operands[0], emit, result);
        var right = operands[1].Trim();
        if (right.Equals("A", StringComparison.OrdinalIgnoreCase))
        {
            Emit(0x57, emit, result);
            Emit(leftOffset, emit, result);
            return;
        }

        Emit(0x47, emit, result);
        Emit(leftOffset, emit, result);
        Emit(Eval(right), emit, result);
    }

    /// <summary>
    /// Action : encode les comparaisons entre operandes de RAM interne, registre ou immediat.
    /// Donnees d'entree : parametres de la signature (string operandText, int memoryMemoryOpcode, int memoryRegisterOpcode, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitInternalCompare(
        string operandText,
        int memoryMemoryOpcode,
        int memoryRegisterOpcode,
        bool emit,
        AssemblyResult result)
    {
        var operands = SplitOperands(operandText);
        if (operands.Length != 2)
        {
            throw new NotSupportedException($"comparaison invalide: {operandText}");
        }

        var left = operands[0].Trim();
        var right = operands[1].Trim();
        if (IsRegister(right))
        {
            var leftOffset = InternalRamOffset(left, emit, result);
            Emit(memoryRegisterOpcode, emit, result);
            Emit(XasmRegisterId(right), emit, result);
            Emit(leftOffset, emit, result);
            return;
        }

        if (right.StartsWith('(') && right.EndsWith(')'))
        {
            var leftAddress = ParseInternalRamOperand(left);
            var rightAddress = ParseInternalRamOperand(right);
            EmitPrebyte(leftAddress.PreId, rightAddress.PreId, emit, result);
            Emit(memoryMemoryOpcode, emit, result);
            Emit(leftAddress.Value, emit, result);
            Emit(rightAddress.Value, emit, result);
            return;
        }

        throw new NotSupportedException($"comparaison interne non encore portee: {operandText}");
    }

    /// <summary>
    /// Action : encode les operations logiques.
    /// Donnees d'entree : parametres de la signature (string operandText, int offset, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitLogical(string operandText, int offset, bool emit, AssemblyResult result)
    {
        var operands = SplitOperands(operandText);
        if (operands.Length != 2)
        {
            throw new NotSupportedException($"operation logique invalide: {operandText}");
        }

        var left = operands[0].Trim();
        var right = operands[1].Trim();
        if (left.Equals("A", StringComparison.OrdinalIgnoreCase) && right.StartsWith('(') && right.EndsWith(')'))
        {
            var rightAddress = ParseInternalRamOperand(right);
            EmitPrebyte(rightAddress.PreId, 0, emit, result);
            Emit(offset + 7, emit, result);
            Emit(rightAddress.Value, emit, result);
            return;
        }

        if (left.Equals("A", StringComparison.OrdinalIgnoreCase) && !IsRegister(right))
        {
            Emit(offset, emit, result);
            Emit(Eval(right), emit, result);
            return;
        }

        if (left.StartsWith('(') && left.EndsWith(')'))
        {
            var leftAddress = ParseInternalRamOperand(left);
            if (right.Equals("A", StringComparison.OrdinalIgnoreCase))
            {
                EmitPrebyte(leftAddress.PreId, 0, emit, result);
                Emit(offset + 3, emit, result);
                Emit(leftAddress.Value, emit, result);
                return;
            }

            if (right.StartsWith('(') && right.EndsWith(')'))
            {
                var rightAddress = ParseInternalRamOperand(right);
                EmitPrebyte(leftAddress.PreId, rightAddress.PreId, emit, result);
                Emit(offset + 6, emit, result);
                Emit(leftAddress.Value, emit, result);
                Emit(rightAddress.Value, emit, result);
                return;
            }

            EmitPrebyte(leftAddress.PreId, 0, emit, result);
            Emit(offset + 1, emit, result);
            Emit(leftAddress.Value, emit, result);
            Emit(Eval(right), emit, result);
            return;
        }

        if (left.StartsWith('[') && left.EndsWith(']') && !IsRegister(right))
        {
            Emit(offset + 2, emit, result);
            Emit24(Eval(left[1..^1]), emit, result);
            Emit(Eval(right), emit, result);
            return;
        }

        throw new NotSupportedException($"forme logique non encore portee: {operandText}");
    }

    /// <summary>
    /// Action : encode les formes de l'instruction CMP.
    /// Donnees d'entree : parametres de la signature (string operandText, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitCompare(string operandText, bool emit, AssemblyResult result)
    {
        var operands = SplitOperands(operandText);
        if (operands.Length != 2)
        {
            throw new NotSupportedException($"comparaison invalide: {operandText}");
        }

        var left = operands[0].Trim();
        var right = operands[1].Trim();
        if (left.Equals("A", StringComparison.OrdinalIgnoreCase) && right.StartsWith('(') && right.EndsWith(')'))
        {
            var rightAddress = ParseInternalRamOperand(right);
            EmitPrebyte(rightAddress.PreId, 0, emit, result);
            Emit(0x62, emit, result);
            Emit(rightAddress.Value, emit, result);
            return;
        }

        if (left.Equals("A", StringComparison.OrdinalIgnoreCase))
        {
            Emit(0x60, emit, result);
            Emit(Eval(right), emit, result);
            return;
        }

        if (left.StartsWith('(') && left.EndsWith(')') && right.StartsWith('(') && right.EndsWith(')'))
        {
            var leftAddress = ParseInternalRamOperand(left);
            var rightAddress = ParseInternalRamOperand(right);
            EmitPrebyte(leftAddress.PreId, rightAddress.PreId, emit, result);
            Emit(0xB7, emit, result);
            Emit(leftAddress.Value, emit, result);
            Emit(rightAddress.Value, emit, result);
            return;
        }

        if (left.StartsWith('(') && left.EndsWith(')') && right.Equals("A", StringComparison.OrdinalIgnoreCase))
        {
            var leftAddress = ParseInternalRamOperand(left);
            EmitPrebyte(leftAddress.PreId, 0, emit, result);
            Emit(0x63, emit, result);
            Emit(leftAddress.Value, emit, result);
            return;
        }

        if (left.StartsWith('(') && left.EndsWith(')'))
        {
            var leftAddress = ParseInternalRamOperand(left);
            EmitPrebyte(leftAddress.PreId, 0, emit, result);
            Emit(0x61, emit, result);
            Emit(leftAddress.Value, emit, result);
            Emit(Eval(right), emit, result);
            return;
        }

        if (left.StartsWith('[') && left.EndsWith(']') && !IsRegister(right))
        {
            Emit(0x26, emit, result);
            Emit24(Eval(left[1..^1]), emit, result);
            Emit(Eval(right), emit, result);
            return;
        }

        throw new NotSupportedException($"forme cmp non encore portee: {operandText}");
    }

    /// <summary>
    /// Action : encode une operation unaire appliquee a un registre.
    /// Donnees d'entree : parametres de la signature (string operandText, int opcode, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitRegisterUnary(string operandText, int opcode, bool emit, AssemblyResult result)
    {
        if (operandText.Trim().StartsWith('('))
        {
            var address = ParseInternalRamOperand(operandText.Trim());
            EmitPrebyte(address.PreId, 0, emit, result);
            Emit(opcode + 1, emit, result);
            Emit(address.Value, emit, result);
            return;
        }

        Emit(opcode, emit, result);
        Emit(RegisterId(operandText.Trim()), emit, result);
    }

    /// <summary>
    /// Action : encode une operation unaire acceptee sur accumulateur ou RAM interne.
    /// Donnees d'entree : parametres de la signature (string operandText, int opcode, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitAccumulatorOrInternalUnary(string operandText, int opcode, bool emit, AssemblyResult result)
    {
        var operand = operandText.Trim();
        if (operand.Equals("A", StringComparison.OrdinalIgnoreCase))
        {
            Emit(opcode, emit, result);
            return;
        }

        if (operand.StartsWith('(') && operand.EndsWith(')'))
        {
            var address = ParseInternalRamOperand(operand);
            EmitPrebyte(address.PreId, 0, emit, result);
            Emit(opcode + 1, emit, result);
            Emit(address.Value, emit, result);
            return;
        }

        throw new NotSupportedException($"operation unaire non encore portee: {operandText}");
    }

    /// <summary>
    /// Action : encode une operation unaire sur RAM interne.
    /// Donnees d'entree : parametres de la signature (string operandText, int opcode, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitInternalUnary(string operandText, int opcode, bool emit, AssemblyResult result)
    {
        var operand = operandText.Trim();
        if (!operand.StartsWith('(') || !operand.EndsWith(')'))
        {
            throw new NotSupportedException($"operation interne unaire non encore portee: {operandText}");
        }

        var address = ParseInternalRamOperand(operand);
        EmitPrebyte(address.PreId, 0, emit, result);
        Emit(opcode, emit, result);
        Emit(address.Value, emit, result);
    }

    /// <summary>
    /// Action : encode une operation unaire sur accumulateur.
    /// Donnees d'entree : parametres de la signature (string operandText, int opcode, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitAccumulatorUnary(string operandText, int opcode, bool emit, AssemblyResult result)
    {
        if (!operandText.Trim().Equals("A", StringComparison.OrdinalIgnoreCase))
        {
            throw new NotSupportedException($"operation accumulateur non encore portee: {operandText}");
        }

        Emit(opcode, emit, result);
    }

    /// <summary>
    /// Action : calcule l'octet de decalage d'une operande de RAM interne.
    /// Donnees d'entree : parametres de la signature (string operand, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : valeur int calculee par la procedure.
    /// </summary>
    private int InternalRamOffset(string operand, bool emit, AssemblyResult result)
    {
        var trimmed = operand.Trim();
        if (!trimmed.StartsWith('(') || !trimmed.EndsWith(')'))
        {
            throw new NotSupportedException($"adresse interne non encore portee: {operand}");
        }

        var inner = trimmed[1..^1].Trim();
        var (preId, value) = ParseInternalRamAddress(inner);
        EmitPrebyte(preId, 0, emit, result);
        return value;
    }

    /// <summary>
    /// Action : execute le traitement interne private.
    /// Donnees d'entree : parametres de la signature (int PreId, int Value) ParseInternalRamOperand(string operand) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private (int PreId, int Value) ParseInternalRamOperand(string operand)
    {
        var trimmed = operand.Trim();
        if (!trimmed.StartsWith('(') || !trimmed.EndsWith(')'))
        {
            throw new NotSupportedException($"adresse interne non encore portee: {operand}");
        }

        return ParseInternalRamAddress(trimmed[1..^1].Trim());
    }

    /// <summary>
    /// Action : execute le traitement interne private.
    /// Donnees d'entree : parametres de la signature (int PreId, int Value) ParseInternalRamAddress(string inner) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private (int PreId, int Value) ParseInternalRamAddress(string inner)
    {
        var text = inner.Trim();
        var upper = text.ToUpperInvariant();
        if (upper == "BP")
        {
            return (0, 0);
        }

        if (upper == "PX")
        {
            return (1, 0);
        }

        if (upper == "PY")
        {
            return (2, 0);
        }

        if (upper == "BP+PX")
        {
            return (3, 0);
        }

        if (upper == "BP+PY")
        {
            return (4, 0);
        }

        if (text.StartsWith('#'))
        {
            return (6, (int)Eval(text[1..]));
        }

        if (upper.StartsWith("BP", StringComparison.Ordinal))
        {
            var rest = text[2..].Trim();
            if (rest.StartsWith('+') || rest.StartsWith('-'))
            {
                return (0, (int)Eval(rest));
            }
        }

        if (upper.StartsWith("PX", StringComparison.Ordinal))
        {
            var rest = text[2..].Trim();
            if (rest.StartsWith('+') || rest.StartsWith('-'))
            {
                return (1, (int)Eval(rest));
            }
        }

        if (upper.StartsWith("PY", StringComparison.Ordinal))
        {
            var rest = text[2..].Trim();
            if (rest.StartsWith('+') || rest.StartsWith('-'))
            {
                return (2, (int)Eval(rest));
            }
        }

        return (5, (int)Eval(text));
    }

    /// <summary>
    /// Action : emet le prebyte adapte a une ou deux operandes de RAM interne.
    /// Donnees d'entree : parametres de la signature (int firstId, int secondId, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitPrebyte(int firstId, int secondId, bool emit, AssemblyResult result)
    {
        var forced = false;
        var invalid = false;
        var prebyte = secondId switch
        {
            6 => 0x32,
            5 => 0x32,
            0 => 0x30,
            2 => 0x33,
            4 => 0x31,
            _ => -1,
        };
        if (prebyte < 0)
        {
            invalid = true;
        }

        if (secondId == 6)
        {
            forced = true;
        }

        switch (firstId)
        {
            case 6:
                forced = true;
                break;
            case 5:
                break;
            case 0:
                prebyte -= 0x10;
                break;
            case 1:
                prebyte += 0x04;
                break;
            case 3:
                prebyte -= 0x0C;
                break;
            default:
                invalid = true;
                break;
        }

        if (invalid)
        {
            throw new NotSupportedException("Prebyte error");
        }

        if (!invalid && prebyte != 0x20 && (_preOn || forced))
        {
            Emit(prebyte, emit, result);
        }
    }

    /// <summary>
    /// Action : detecte une operande valide de RAM interne.
    /// Donnees d'entree : parametres de la signature (string operand) et etat courant necessaire.
    /// Donnees de sortie : booleen indiquant si le traitement a reussi ou si la condition est verifiee.
    /// </summary>
    private static bool IsInternalRamOperand(string operand)
    {
        var trimmed = operand.Trim();
        if (!trimmed.StartsWith('(') || !trimmed.EndsWith(')'))
        {
            return false;
        }

        var depth = 0;
        var quoted = false;
        for (var i = 0; i < trimmed.Length; i++)
        {
            var c = trimmed[i];
            if (c == '\'')
            {
                quoted = !quoted;
                continue;
            }

            if (quoted)
            {
                continue;
            }

            if (c == '(')
            {
                depth++;
            }
            else if (c == ')')
            {
                depth--;
                if (depth == 0)
                {
                    return i == trimmed.Length - 1;
                }
            }
        }

        return false;
    }

    /// <summary>
    /// Action : emet des donnees constantes DB/DW/DL selon la largeur demandee.
    /// Donnees d'entree : parametres de la signature (string operandText, int width, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitData(string operandText, int width, bool emit, AssemblyResult result)
    {
        foreach (var operand in SplitOperands(operandText))
        {
            var trimmed = operand.Trim();
            if (trimmed.StartsWith('\'') && trimmed.EndsWith('\'') && trimmed.Length >= 2)
            {
                foreach (var c in Unquote(trimmed))
                {
                    Emit(c, emit, result);
                }
                continue;
            }

            var value = Eval(trimmed);
            for (var i = 0; i < width; i++)
            {
                Emit(value >> (8 * i), emit, result);
            }
        }
    }

    /// <summary>
    /// Action : reserve ou emet une zone de stockage initialisee a zero.
    /// Donnees d'entree : parametres de la signature (string operandText, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void EmitStorage(string operandText, bool emit, AssemblyResult result)
    {
        var operands = SplitOperands(operandText);
        var count = Eval(operands[0]);
        var fill = operands.Length > 1 ? Eval(operands[1]) : 0;
        for (var i = 0; i < count; i++)
        {
            Emit(fill, emit, result);
        }
    }

    /// <summary>
    /// Action : emet un octet dans le resultat courant.
    /// Donnees d'entree : parametres de la signature (long value, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void Emit(long value, bool emit, AssemblyResult result)
    {
        if (emit)
        {
            result.GeneratedBytes.Add(new GeneratedByte(_locationCounter, (byte)(value & 0xff)));
        }

        _locationCounter++;
    }

    /// <summary>
    /// Action : emet une valeur sur trois octets en ordre little-endian.
    /// Donnees d'entree : parametres de la signature (long value, bool emit, AssemblyResult result) et etat courant necessaire.
    /// Donnees de sortie : aucune valeur retournee ; effets attendus sur fichiers, resultat ou etat interne.
    /// </summary>
    private void Emit24(long value, bool emit, AssemblyResult result)
    {
        Emit(value, emit, result);
        Emit(value >> 8, emit, result);
        Emit(value >> 16, emit, result);
    }

    /// <summary>
    /// Action : separe les operandes en respectant parentheses, crochets et chaines.
    /// Donnees d'entree : parametres de la signature (string operandText) et etat courant necessaire.
    /// Donnees de sortie : collection calculee par la procedure.
    /// </summary>
    private static string[] SplitOperands(string operandText)
    {
        var operands = new List<string>();
        var current = new List<char>();
        var quoted = false;
        foreach (var c in operandText)
        {
            if (c == '\'')
            {
                quoted = !quoted;
            }

            if (c == ',' && !quoted)
            {
                operands.Add(new string(current.ToArray()));
                current.Clear();
                continue;
            }

            current.Add(c);
        }

        operands.Add(new string(current.ToArray()));
        return operands.Where(x => !string.IsNullOrWhiteSpace(x)).ToArray();
    }

    /// <summary>
    /// Action : convertit une chaine assembleur entre guillemets en octets.
    /// Donnees d'entree : parametres de la signature (string value) et etat courant necessaire.
    /// Donnees de sortie : collection calculee par la procedure.
    /// </summary>
    private static IEnumerable<byte> Unquote(string value)
    {
        var inner = value[1..^1];
        for (var i = 0; i < inner.Length; i++)
        {
            if (inner[i] == '\'' && i + 1 < inner.Length && inner[i + 1] == '\'')
            {
                i++;
            }

            yield return (byte)inner[i];
        }
    }

    private sealed class SectionBuilder
    {
        /// <summary>
        /// Action : cree un accumulateur interne pour suivre les bornes d'une section.
        /// Donnees d'entree : parametres de la signature (string name, long start) et etat courant necessaire.
        /// Donnees de sortie : instance initialisee.
        /// </summary>
        public SectionBuilder(string name, long start)
        {
            Name = name;
            Start = start;
            End = start;
        }

        public string Name { get; }
        public long Start { get; }
        public long End { get; set; }
    }

    private sealed class MacroDefinition
    {
        /// <summary>
        /// Action : memorise la definition d'une macro et ses arguments.
        /// Donnees d'entree : parametres de la signature (string name, string[] arguments, IReadOnlyList<string> body) et etat courant necessaire.
        /// Donnees de sortie : instance initialisee.
        /// </summary>
        public MacroDefinition(string name, string[] arguments, IReadOnlyList<string> body)
        {
            Name = name;
            Arguments = arguments;
            Body = body.ToArray();
        }

        public string Name { get; }
        public string[] Arguments { get; }
        public string[] Body { get; }
    }
}
