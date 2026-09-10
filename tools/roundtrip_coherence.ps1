<#
    Verifie la coherence d'inverses entre l'assembleur xasm2026-4 et le desassembleur
    e500dasm (SC62015Disassembler) sur un corpus d'objets :

        objet  ->  e500dasm --mode flow --format-out asm  ->  xasm2026-4  ->  objet

    Un round-trip est CONFORME si l'objet reassemble est identique octet pour octet a
    l'objet de depart. Les deux outils sont alors des inverses exacts pour ce fichier.

    Le desassembleur n'est PAS fourni dans ce depot : le designer via -Disassembler ou la
    variable d'environnement E500DASM_EXE. Le corpus d'objets par defaut est le dossier
    Samples voisin de l'executable ; surchargeable via -SamplesDir.

    Exemple :
        .\tools\roundtrip_coherence.ps1 -Disassembler C:\...\Publish\e500dasm.exe
#>
param(
    [string]$Disassembler = $env:E500DASM_EXE,
    [string]$CandidateXasm,
    [string]$SamplesDir,
    [string]$OutDir,
    # Divergences tolerees (le script n'echoue que sur une divergence HORS de cette liste).
    # Vide depuis e500dasm v1.60.0, qui a ferme les trois derniers ecarts du corpus
    # (sample2/sample5/sample5_v14) : la forme d'ADD/SUB a largeur explicite est desormais
    # rendue quand l'opcode contredit la regle du premier operande (46 40 -> "addb x,a"), et
    # un post-octet d'indexation non specifie retombe en "db". Le corpus boucle donc 28/28.
    [string[]]$KnownDivergences = @()
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $CandidateXasm) { $CandidateXasm = Join-Path $RepoRoot "src\bin\Release\net8.0\xasm2026-4.exe" }
if (-not $OutDir) { $OutDir = Join-Path $RepoRoot "tests\_roundtrip_coherence" }
if (-not $Disassembler) {
    # Ressource externe absente du depot : chemin fourni via -Disassembler ou la
    # variable d'environnement E500DASM_EXE (pas de chemin machine code en dur).
    $Disassembler = $env:E500DASM_EXE
}

if (-not (Test-Path $Disassembler)) {
    throw "Desassembleur e500dasm introuvable : passez -Disassembler <chemin> ou definissez E500DASM_EXE. Il n'est pas fourni dans ce depot."
}
if (-not (Test-Path $CandidateXasm)) {
    throw "Executable candidat introuvable : $CandidateXasm (compiler d'abord : dotnet build src\Xasm2026.Native.csproj -c Release)"
}
$Disassembler = (Resolve-Path $Disassembler).Path
$CandidateXasm = (Resolve-Path $CandidateXasm).Path

if (-not $SamplesDir) {
    # Samples est voisin de Publish/ (Publish\..\Samples), sinon a cote de l'exe.
    $publishParent = Split-Path -Parent (Split-Path -Parent $Disassembler)
    foreach ($cand in @((Join-Path $publishParent "Samples"),
                        (Join-Path (Split-Path -Parent $Disassembler) "Samples"))) {
        if (Test-Path $cand) { $SamplesDir = $cand; break }
    }
}
if (-not $SamplesDir -or -not (Test-Path $SamplesDir)) {
    throw "Corpus d'objets introuvable : passez -SamplesDir <dossier> (contenant des .obj)."
}
$SamplesDir = (Resolve-Path $SamplesDir).Path

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "Desassembleur : $Disassembler"
Write-Host "Assembleur    : $CandidateXasm"
Write-Host "Corpus        : $SamplesDir"
Write-Host ""
"{0,-4} {1,-14} {2,-20} {3,8}" -f "ETAT", "DOSSIER", "OBJET", "TAILLE" | Write-Host
"".PadRight(52, "-") | Write-Host

$ok = 0; $diff = 0; $fail = 0
$divergents = @()
$unexpected = @()

Get-ChildItem -Path $SamplesDir -Recurse -File -Include *.obj, *.OBJ | Sort-Object FullName | ForEach-Object {
    $obj = $_.FullName
    $dir = Split-Path -Leaf (Split-Path -Parent $obj)
    $stem = [IO.Path]::GetFileNameWithoutExtension($obj)
    $work = Join-Path $OutDir ("{0}_{1}" -f $dir, $stem)
    New-Item -ItemType Directory -Force -Path $work | Out-Null

    $srcAsm = Join-Path $work "disasm.asm"
    $rtObj = Join-Path $work "roundtrip.obj"
    Remove-Item -Force -ErrorAction SilentlyContinue $srcAsm, $rtObj

    # 1. desassemblage en source propre reassemblable
    & $Disassembler --mode flow --format-out asm --out $srcAsm $obj 2>$null | Out-Null

    $state = "DIFF"
    if (Test-Path $srcAsm) {
        # 2. reassemblage. xasm2026-4 resout les INCLUDE relativement au source ; on le
        #    lance depuis le dossier de travail par prudence.
        Push-Location $work
        try { & $CandidateXasm $srcAsm -O $rtObj 2>$null | Out-Null } finally { Pop-Location }

        if (Test-Path $rtObj) {
            $a = [IO.File]::ReadAllBytes($rtObj)
            $b = [IO.File]::ReadAllBytes($obj)
            if ($a.Length -eq $b.Length) {
                $same = $true
                for ($i = 0; $i -lt $a.Length; $i++) { if ($a[$i] -ne $b[$i]) { $same = $false; break } }
                if ($same) { $state = "OK" }
            }
        } else { $state = "ASM!" }  # le desassemblage n'a pas pu etre reassemble
    } else { $state = "DIS!" }      # le desassemblage a echoue

    $objName = $_.Name
    if ($state -eq "OK") {
        $ok++
    } else {
        if ($state -eq "DIFF") { $diff++ } else { $fail++ }
        $known = $KnownDivergences -contains $objName
        if (-not $known) { $unexpected += "$dir/$objName [$state]" }
        $divergents += ("{0}/{1} [{2}]{3}" -f $dir, $objName, $state, $(if ($known) { " (attendu)" } else { "" }))
    }
    "{0,-4} {1,-14} {2,-20} {3,8}" -f $state, $dir, $objName, $_.Length | Write-Host
}

Write-Host ""
Write-Host ("Conformes : {0}   divergents : {1}   echecs : {2}" -f $ok, $diff, $fail)
if ($divergents.Count -gt 0) {
    Write-Host "Non conformes :"
    $divergents | ForEach-Object { Write-Host "  $_" }
}
# Code retour non nul UNIQUEMENT sur une divergence non prevue : les cas connus
# (cote desassembleur) sont tolérés, ce qui fait du script une garde anti-regression.
if ($unexpected.Count -gt 0) {
    Write-Host ""
    Write-Host ("!! {0} divergence(s) NON prevue(s) -- regression a examiner." -f $unexpected.Count)
    exit 1
}
exit 0
