<#
    Compare les sorties de l'assembleur de reference xasm2026-1 et du port C# candidat.

    Les chemins par defaut sont deduits de l'emplacement du script, afin que le script
    fonctionne dans n'importe quel checkout (ils pointaient auparavant vers C:\Codex\...).

    L'executable de reference xasm2026-1 n'est PAS fourni dans ce depot : il faut le
    designer via -ReferenceXasm, ou via la variable d'environnement XASM_REFERENCE_EXE.
#>
param(
    [string]$OutDir,
    [string]$ReferenceXasm = $env:XASM_REFERENCE_EXE,
    [string]$CandidateXasm,
    [switch]$IncludeVogue
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $OutDir) { $OutDir = Join-Path $RepoRoot "tests\_compare_with_xasm2026_1_1" }
if (-not $CandidateXasm) { $CandidateXasm = Join-Path $RepoRoot "src\bin\Release\net8.0\xasm2026-4.exe" }

if (-not $ReferenceXasm) {
    throw "Executable de reference introuvable : passez -ReferenceXasm <chemin> ou definissez XASM_REFERENCE_EXE. L'exe xasm2026-1 n'est pas fourni dans ce depot."
}
if (-not (Test-Path $ReferenceXasm)) {
    throw "Executable de reference introuvable : $ReferenceXasm"
}
if (-not (Test-Path $CandidateXasm)) {
    throw "Executable candidat introuvable : $CandidateXasm (compiler d'abord avec: dotnet build src\Xasm2026.Native.csproj -c Release)"
}

# Les assembleurs sont lances depuis le dossier de travail de chaque source : un chemin
# relatif fourni en parametre n'y resoudrait plus. On le fige donc en absolu ici.
$ReferenceXasm = (Resolve-Path $ReferenceXasm).Path
$CandidateXasm = (Resolve-Path $CandidateXasm).Path

function Read-UInt24LE([byte[]]$Bytes, [int]$Offset) {
    return [int]$Bytes[$Offset] -bor ([int]$Bytes[$Offset + 1] -shl 8) -bor ([int]$Bytes[$Offset + 2] -shl 16)
}

function Get-CodeBytes([string]$Path) {
    [byte[]]$bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 16 -and
        $bytes[0] -eq 0xff -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0x06 -and
        $bytes[3] -eq 0x01 -and $bytes[4] -eq 0x10 -and
        $bytes[14] -eq 0x00 -and $bytes[15] -eq 0x0f) {
        return $bytes[16..($bytes.Length - 1)]
    }

    if ($bytes.Length -ge 6) {
        $size = Read-UInt24LE $bytes 0
        if ($size -eq ($bytes.Length - 6)) {
            return $bytes[6..($bytes.Length - 1)]
        }
    }

    return $bytes
}

function Compare-Code([string]$ReferenceObject, [string]$CandidateObject) {
    $reference = Get-CodeBytes $ReferenceObject
    $candidate = Get-CodeBytes $CandidateObject
    $length = [Math]::Min($reference.Length, $candidate.Length)
    $firstDiff = -1
    for ($i = 0; $i -lt $length; $i++) {
        if ($reference[$i] -ne $candidate[$i]) {
            $firstDiff = $i
            break
        }
    }

    [pscustomobject]@{
        Same = $firstDiff -lt 0 -and $reference.Length -eq $candidate.Length
        RefCodeSize = $reference.Length
        CandidateCodeSize = $candidate.Length
        FirstDiff = $firstDiff
        RefByte = if ($firstDiff -ge 0) { "{0:X2}" -f $reference[$firstDiff] } else { "" }
        CandidateByte = if ($firstDiff -ge 0) { "{0:X2}" -f $candidate[$firstDiff] } else { "" }
    }
}

function Compare-FileBytes([string]$ReferenceFile, [string]$CandidateFile) {
    if (-not (Test-Path $ReferenceFile) -or -not (Test-Path $CandidateFile)) {
        return [pscustomobject]@{
            Same = $false
            RefSize = if (Test-Path $ReferenceFile) { (Get-Item $ReferenceFile).Length } else { 0 }
            CandidateSize = if (Test-Path $CandidateFile) { (Get-Item $CandidateFile).Length } else { 0 }
            FirstDiff = -1
            RefByte = ""
            CandidateByte = ""
        }
    }

    [byte[]]$reference = [IO.File]::ReadAllBytes($ReferenceFile)
    [byte[]]$candidate = [IO.File]::ReadAllBytes($CandidateFile)
    $length = [Math]::Min($reference.Length, $candidate.Length)
    $firstDiff = -1
    for ($i = 0; $i -lt $length; $i++) {
        if ($reference[$i] -ne $candidate[$i]) {
            $firstDiff = $i
            break
        }
    }

    [pscustomobject]@{
        Same = $firstDiff -lt 0 -and $reference.Length -eq $candidate.Length
        RefSize = $reference.Length
        CandidateSize = $candidate.Length
        FirstDiff = $firstDiff
        RefByte = if ($firstDiff -ge 0) { "{0:X2}" -f $reference[$firstDiff] } else { "" }
        CandidateByte = if ($firstDiff -ge 0) { "{0:X2}" -f $candidate[$firstDiff] } else { "" }
    }
}

function Compare-ByteArrays([byte[]]$Reference, [byte[]]$Candidate) {
    $length = [Math]::Min($Reference.Length, $Candidate.Length)
    $firstDiff = -1
    for ($i = 0; $i -lt $length; $i++) {
        if ($Reference[$i] -ne $Candidate[$i]) {
            $firstDiff = $i
            break
        }
    }

    [pscustomobject]@{
        Same = $firstDiff -lt 0 -and $Reference.Length -eq $Candidate.Length
        RefSize = $Reference.Length
        CandidateSize = $Candidate.Length
        FirstDiff = $firstDiff
        RefByte = if ($firstDiff -ge 0) { "{0:X2}" -f $Reference[$firstDiff] } else { "" }
        CandidateByte = if ($firstDiff -ge 0) { "{0:X2}" -f $Candidate[$firstDiff] } else { "" }
    }
}

function Decode-UuChar([char]$Value) {
    if ($Value -eq '`' -or $Value -eq ' ') {
        return 0
    }

    return ([int][char]$Value - 32) -band 0x3f
}

function Decode-BasicUuFile([string]$Path) {
    $bytes = [System.Collections.Generic.List[byte]]::new()
    $inData = $false
    foreach ($line in Get-Content $Path) {
        $quote = $line.IndexOf("'")
        if ($quote -lt 0) {
            continue
        }

        $text = $line.Substring($quote + 1)
        if ($text.StartsWith("begin ")) {
            $inData = $true
            continue
        }

        if (-not $inData) {
            continue
        }

        if ($text -eq "end") {
            break
        }

        if ($text -eq "``") {
            continue
        }

        if ($text.Length -lt 2) {
            continue
        }

        $count = Decode-UuChar $text[0]
        if ($count -le 0) {
            continue
        }

        $encoded = $text.Substring(1, $text.Length - 2)
        $remaining = $count
        for ($i = 0; $i -lt $encoded.Length -and $remaining -gt 0; $i += 4) {
            if ($i + 3 -ge $encoded.Length) {
                break
            }

            $c1 = Decode-UuChar $encoded[$i]
            $c2 = Decode-UuChar $encoded[$i + 1]
            $c3 = Decode-UuChar $encoded[$i + 2]
            $c4 = Decode-UuChar $encoded[$i + 3]
            $triple = [byte[]]@(
                ((($c1 -shl 2) -bor ($c2 -shr 4)) -band 0xff),
                ((($c2 -shl 4) -bor ($c3 -shr 2)) -band 0xff),
                ((($c3 -shl 6) -bor $c4) -band 0xff)
            )

            foreach ($b in $triple) {
                if ($remaining -le 0) {
                    break
                }

                $bytes.Add($b)
                $remaining--
            }
        }
    }

    return $bytes.ToArray()
}

function Invoke-Xasm([string]$Exe, [string]$SourceFile, [string]$WorkDir, [string]$LogPath) {
    Push-Location $WorkDir
    try {
        # La sortie est conservee dans un journal plutot que jetee : sans elle, un echec
        # d'assemblage ne laisse aucune trace exploitable.
        & $Exe ([IO.Path]::GetFileName($SourceFile)) -O -L -B -I -M -P -D -X *> $LogPath
        return $LASTEXITCODE
    }
    finally {
        Pop-Location
    }
}

# Extensions produites par l'assembleur. Les exemples embarquent leurs sorties de
# reference commitees : elles sont retirees du dossier de travail, sinon une sortie non
# regeneree par le run serait comparee a leur place et passerait pour identique.
$script:OutputExtensions = @('.obj', '.lst', '.hex', '.s19', '.map', '.d', '.uu', '.txt', '.err')

function New-WorkFolder([string]$SourceFile, [string]$DestinationRoot, [string]$Tag) {
    $sourceDir = Split-Path -Parent $SourceFile

    # Un dossier par **source** et non par exemple : plusieurs sources partagent le meme
    # dossier d'origine (les cinq SAMPLE* dans SAMPLES), et se seraient ecrasees entre
    # elles, ne laissant sur disque que la derniere execution.
    $destination = Join-Path $DestinationRoot $Tag
    if (Test-Path $destination) {
        Remove-Item -Path $destination -Recurse -Force
    }

    Copy-Item -Path $sourceDir -Destination $destination -Recurse

    Get-ChildItem -Path $destination -Recurse -File |
        Where-Object { $script:OutputExtensions -contains $_.Extension.ToLowerInvariant() } |
        Remove-Item -Force

    return Join-Path $destination ([IO.Path]::GetFileName($SourceFile))
}

if (-not (Test-Path $ReferenceXasm)) {
    throw "Reference XASM introuvable : $ReferenceXasm"
}

if (-not (Test-Path $CandidateXasm)) {
    throw "XASM candidat introuvable : $CandidateXasm"
}

# Liste historique, relative au depot. Les exemples TRDOS et UUCODE ne font pas partie de
# ce checkout : les entrees absentes sont ignorees avec un avertissement plutot que de
# faire echouer la comparaison.
$candidateSources = @(
    "Exemples\SAMPLES\SAMPLE1.ASM",
    "Exemples\SAMPLES\SAMPLE2.ASM",
    "Exemples\SAMPLES\SAMPLE3.ASM",
    "Exemples\SAMPLES\SAMPLE4.ASM",
    "Exemples\SAMPLES\SAMPLE5.ASM",
    "Exemples\REGISTER\REGISTER.ASM",
    "Exemples\TMAP\TMAP2020.asm",
    "Exemples\TRDOS\ex_tycom.asm",
    "Exemples\TRDOS\init.asm",
    "Exemples\TRDOS\path.asm",
    "Exemples\TRDOS\shell.asm",
    "Exemples\UUCODE\UUENCODE.ASM",
    "Exemples\UUCODE\UUDECODE.ASM"
)

if ($IncludeVogue) {
    $candidateSources += "Exemples\VOGUE\VOGUE.S"
}

$sources = @()
foreach ($relative in $candidateSources) {
    $full = Join-Path $RepoRoot $relative
    if (Test-Path $full) { $sources += $full }
    else { Write-Warning "Exemple absent de ce depot, ignore : $relative" }
}

if ($sources.Count -eq 0) {
    throw "Aucun exemple a comparer sous $RepoRoot."
}

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$referenceRoot = Join-Path $OutDir "reference"
$candidateRoot = Join-Path $OutDir "candidate"
New-Item -ItemType Directory -Path $referenceRoot -Force | Out-Null
New-Item -ItemType Directory -Path $candidateRoot -Force | Out-Null

$results = @()
foreach ($source in $sources) {
    $name = [IO.Path]::GetFileNameWithoutExtension($source)

    # Identifiant unique par source : dossier d'exemple + nom du fichier.
    $tag = "{0}_{1}" -f (Split-Path -Leaf (Split-Path -Parent $source)), $name

    $referenceSource = New-WorkFolder $source $referenceRoot $tag
    $candidateSource = New-WorkFolder $source $candidateRoot $tag
    $referenceDir = Split-Path -Parent $referenceSource
    $candidateDir = Split-Path -Parent $candidateSource

    $referenceExit = Invoke-Xasm $ReferenceXasm $referenceSource $referenceDir (Join-Path $referenceDir "_xasm.log")
    $candidateExit = Invoke-Xasm $CandidateXasm $candidateSource $candidateDir (Join-Path $candidateDir "_xasm.log")

    $referenceObject = Join-Path $referenceDir "$name.obj"
    $candidateObject = Join-Path $candidateDir "$name.obj"
    $referenceUu = Join-Path $referenceDir "$name.uu"
    $candidateUu = Join-Path $candidateDir "$name.uu"

    # Le dossier de travail ayant ete purge de toute sortie, un fichier absent signifie
    # reellement « non produit par ce run » et non « reste d'un exemple commite ».
    $missing = @()
    foreach ($expected in @(
        @{ Path = $referenceObject; Label = 'reference .obj' },
        @{ Path = $candidateObject; Label = 'candidat .obj' },
        @{ Path = $referenceUu; Label = 'reference .uu' },
        @{ Path = $candidateUu; Label = 'candidat .uu' })) {
        if (-not (Test-Path $expected.Path)) { $missing += $expected.Label }
    }

    if ($missing.Count -gt 0) {
        Write-Warning ("{0} : sortie non produite -> {1}" -f $name, ($missing -join ', '))
    }

    $comparison = $null
    $uuComparison = $null
    $referenceUuDecoded = $null
    $candidateUuDecoded = $null
    if ($referenceExit -eq 0 -and $candidateExit -eq 0 -and (Test-Path $referenceObject) -and (Test-Path $candidateObject)) {
        $comparison = Compare-Code $referenceObject $candidateObject
        $uuComparison = Compare-FileBytes $referenceUu $candidateUu
        if ((Test-Path $referenceUu) -and (Test-Path $candidateUu)) {
            $referenceUuDecoded = Compare-ByteArrays ([IO.File]::ReadAllBytes($referenceObject)) (Decode-BasicUuFile $referenceUu)
            $candidateUuDecoded = Compare-ByteArrays ([IO.File]::ReadAllBytes($candidateObject)) (Decode-BasicUuFile $candidateUu)
        }
    }

    $results += [pscustomobject]@{
        Source = [IO.Path]::GetFileName($source)
        WorkFolder = $tag
        MissingOutputs = ($missing -join ', ')
        ReferenceExit = $referenceExit
        CandidateExit = $candidateExit
        Same = if ($comparison) { $comparison.Same } else { $false }
        RefCodeSize = if ($comparison) { $comparison.RefCodeSize } else { 0 }
        CandidateCodeSize = if ($comparison) { $comparison.CandidateCodeSize } else { 0 }
        FirstDiff = if ($comparison) { $comparison.FirstDiff } else { -1 }
        RefByte = if ($comparison) { $comparison.RefByte } else { "" }
        CandidateByte = if ($comparison) { $comparison.CandidateByte } else { "" }
        UuSame = if ($uuComparison) { $uuComparison.Same } else { $false }
        RefUuSize = if ($uuComparison) { $uuComparison.RefSize } else { 0 }
        CandidateUuSize = if ($uuComparison) { $uuComparison.CandidateSize } else { 0 }
        UuFirstDiff = if ($uuComparison) { $uuComparison.FirstDiff } else { -1 }
        UuRefByte = if ($uuComparison) { $uuComparison.RefByte } else { "" }
        UuCandidateByte = if ($uuComparison) { $uuComparison.CandidateByte } else { "" }
        ReferenceUuDecodes = if ($referenceUuDecoded) { $referenceUuDecoded.Same } else { $false }
        CandidateUuDecodes = if ($candidateUuDecoded) { $candidateUuDecoded.Same } else { $false }
        CandidateUuDecodeFirstDiff = if ($candidateUuDecoded) { $candidateUuDecoded.FirstDiff } else { -1 }
    }
}

$summary = Join-Path $OutDir "summary.csv"
$results | Export-Csv -Path $summary -NoTypeInformation -Encoding UTF8
$results
