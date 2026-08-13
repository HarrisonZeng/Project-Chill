<#
.SYNOPSIS
  Run Project Chill in Godot without a human watching, and report in a few lines.

.DESCRIPTION
  Four modes, cheapest first:

    lint   parse every .gd and .json                  ~2s
    boot   load the real main scene headless          ~3s
    test   drive the game through a scenario          ~4s each
    shot   same, but windowed, and save a PNG        ~6s

  Output is deliberately tiny: on success one line per check, on failure only the
  lines that matter (the failing assertion plus any Godot error). Engine banners,
  debug prints and ANSI colour are stripped.

  The owner's real save is backed up before the run and restored after, so tests
  can wipe it freely. Typed replies are routed to a disabled AI by default, so a
  run never makes a network call or spends API credit — pass -Ai to opt in.

.EXAMPLE
  pwsh tools/godot_check/check.ps1
  pwsh tools/godot_check/check.ps1 -Mode test -Scenario episodes
  pwsh tools/godot_check/check.ps1 -Mode test -Scenario all
  pwsh tools/godot_check/check.ps1 -Mode shot -Scenario smoke
#>
[CmdletBinding()]
param(
    [ValidateSet('lint', 'boot', 'test', 'shot', 'all', 'list')]
    [string] $Mode = 'all',

    # Scenario name (see tools/godot_check/scenarios), or 'all'.
    [string] $Scenario = 'all',

    # -Mode shot only: jump straight to this dialogue node and photograph it.
    # Implies the 'look' scenario. e.g. -Node ep03_01
    [string] $Node = '',

    # -Mode shot with -Node: completed focus sessions to fake, so a mid-story
    # node renders with the surrounding state it would really have.
    [int] $Sessions = 0,

    # Path to Godot. Falls back to $env:GODOT_BIN, then a short search.
    [string] $Godot = '',

    # Let typed replies reach the real AI provider. Off by default: costs money,
    # needs network, and makes assertions non-deterministic.
    [switch] $Ai,

    # Seconds before a single Godot run is killed.
    [int] $TimeoutSeconds = 120,

    # Print raw Godot output instead of the filtered summary.
    [switch] $Raw
)

$ErrorActionPreference = 'Stop'

# Godot emits UTF-8 and the script is full of Chinese dialogue; without this the
# console shows mojibake and any assertion quoting a line is unreadable.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ToolDir     = $PSScriptRoot
$WorkDir     = Join-Path $env:TEMP 'project_chill_check'
$SavePath    = Join-Path $env:APPDATA 'Godot\app_userdata\Project Chill\data\saves\player_profile.json'
$ShotDir     = Join-Path $ToolDir 'shots'

if (-not (Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null }

# --- locate Godot ----------------------------------------------------------

function Resolve-Godot {
    param([string] $Explicit)

    if ($Explicit -and (Test-Path $Explicit)) { return (Resolve-Path $Explicit).Path }
    if ($env:GODOT_BIN -and (Test-Path $env:GODOT_BIN)) { return (Resolve-Path $env:GODOT_BIN).Path }

    # The _console build is the one that actually writes to stdout on Windows.
    $candidates = @(
        'D:\Godot_v4.6.1-stable_win64_console.exe',
        'D:\Godot_v4.6.1-stable_win64.exe'
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) { return $candidate }
    }

    foreach ($root in @('D:\', 'C:\', "$env:USERPROFILE\Downloads", "$env:LOCALAPPDATA\Programs")) {
        if (-not (Test-Path $root)) { continue }
        $hit = Get-ChildItem -Path $root -Filter 'Godot_v*_console.exe' -Depth 2 -Force -ErrorAction SilentlyContinue |
               Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }

    throw "Godot not found. Pass -Godot <path> or set GODOT_BIN."
}

$GodotBin = Resolve-Godot -Explicit $Godot

# --- run one Godot invocation and clean up its output ----------------------

function Invoke-Godot {
    param([string[]] $GodotArgs)

    $outFile = Join-Path $WorkDir 'stdout.txt'
    $errFile = Join-Path $WorkDir 'stderr.txt'
    foreach ($f in @($outFile, $errFile)) {
        if (Test-Path $f) { Remove-Item $f -Force }
    }

    # Start-Process does not quote for us, and the project path has a space in it.
    $quoted = $GodotArgs | ForEach-Object {
        if ($_ -match '\s') { '"' + $_ + '"' } else { $_ }
    }

    $process = Start-Process -FilePath $GodotBin -ArgumentList $quoted -NoNewWindow -PassThru `
                             -RedirectStandardOutput $outFile -RedirectStandardError $errFile

    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        try { $process.Kill() } catch {}
        return @{ ExitCode = 124; Lines = @("TIMEOUT after ${TimeoutSeconds}s"); Raw = '' }
    }
    # The timed overload can return before the redirected streams are flushed and
    # before ExitCode is populated; the argument-less call settles both.
    $process.WaitForExit()

    $exitCode = 0
    try { $exitCode = [int] $process.ExitCode } catch { $exitCode = -1 }

    $raw = ''
    foreach ($f in @($outFile, $errFile)) {
        if (Test-Path $f) { $raw += (Get-Content $f -Raw -Encoding UTF8 -ErrorAction SilentlyContinue) }
    }
    if ($null -eq $raw) { $raw = '' }

    # A native crash never reaches the harness, so it would otherwise look like a
    # clean run with no assertions.
    if ($raw -match 'CrashHandlerException|Program crashed with signal') {
        return @{ ExitCode = 139; Lines = @('CRASH: Godot crashed (see -Raw for the backtrace)'); Raw = $raw }
    }

    return @{ ExitCode = $exitCode; Lines = (Select-Signal $raw); Raw = $raw }
}

# Keep only what a reviewer needs: harness verdicts and genuine engine errors.
function Select-Signal {
    param([string] $Text)

    $kept = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrWhiteSpace($Text)) { return $kept }

    $noise = @(
        '^Godot Engine v',
        '^\s*$',
        '\[DEBUG TIMELINE\]',
        'TextServer:',
        'Advanced Text Server',
        '^WARNING: .*shader',
        'is deprecated',
        'Please use',
        '^\s*at: <unknown',
        'no debug info in PE/COFF',
        '^\s*=+\s*$'
    )

    foreach ($line in ($Text -split "`r?`n")) {
        # Strip ANSI colour so pattern matching (and Claude's eyes) work.
        $clean = [regex]::Replace($line, "`e\[[0-9;]*m", '')
        $clean = $clean.TrimEnd()

        $skip = $false
        foreach ($pattern in $noise) {
            if ($clean -match $pattern) { $skip = $true; break }
        }
        if ($skip) { continue }

        $isHarness = $clean -match '^(TEST |HARNESS |scenarios:|  x |    |  shot:|  ! )'
        $isError   = $clean -match '(SCRIPT ERROR|USER ERROR|ERROR:|WARNING:|Attempt to call|Invalid |Cannot |not found|TIMEOUT)'
        $isTrace   = $clean -match '^\s+at: '

        if ($isHarness -or $isError -or $isTrace) { $kept.Add($clean) | Out-Null }
    }

    # A broken run can emit the same error every frame; collapse the repeats.
    $seen = @{}
    $deduped = New-Object System.Collections.Generic.List[string]
    foreach ($line in $kept) {
        if ($line -match '^(  x |    |TEST )') { $deduped.Add($line) | Out-Null; continue }
        if ($seen.ContainsKey($line)) { continue }
        $seen[$line] = $true
        $deduped.Add($line) | Out-Null
    }

    if ($deduped.Count -gt 40) {
        $trimmed = $deduped[0..39]
        $trimmed += ("  ... {0} more lines suppressed" -f ($deduped.Count - 40))
        return $trimmed
    }
    return $deduped
}

# --- save file protection --------------------------------------------------

$SaveBackup = Join-Path $WorkDir 'player_profile.backup.json'
$HadSave = Test-Path $SavePath
if ($HadSave) { Copy-Item $SavePath $SaveBackup -Force }

function Restore-Save {
    if ($HadSave) {
        $saveDir = Split-Path -Parent $SavePath
        if (-not (Test-Path $saveDir)) { New-Item -ItemType Directory -Path $saveDir -Force | Out-Null }
        Copy-Item $SaveBackup $SavePath -Force
    }
    elseif (Test-Path $SavePath) {
        # There was no save before the run; don't leave a test one behind.
        Remove-Item $SavePath -Force
    }
}

# --- modes -----------------------------------------------------------------

$Failures = 0

function Get-ScenarioNames {
    Get-ChildItem (Join-Path $ToolDir 'scenarios') -Filter '*.gd' | ForEach-Object { $_.BaseName }
}

function Invoke-Lint {
    $result = Invoke-Godot @(
        '--headless', '--path', $ProjectRoot,
        '--script', 'res://tools/godot_check/harness.gd',
        '--', '--scenario=lint'
    )
    Write-Report -Label 'LINT' -Result $result
}

function Invoke-Boot {
    # No harness: just load the real main scene the way the game does and see
    # whether _ready() throws.
    $result = Invoke-Godot @('--headless', '--path', $ProjectRoot, '--quit-after', '240')
    if ($result.ExitCode -eq 0 -and $result.Lines.Count -eq 0) {
        Write-Host 'BOOT             ok'
    }
    else {
        Write-Host 'BOOT             FAIL'
        $result.Lines | ForEach-Object { Write-Host $_ }
        $script:Failures++
    }
    if ($Raw) { Write-Host $result.Raw }
}

function Invoke-Scenario {
    param([string] $Name, [switch] $Windowed)

    $godotArgs = @()
    if ($Windowed) {
        if (-not (Test-Path $ShotDir)) { New-Item -ItemType Directory -Path $ShotDir -Force | Out-Null }
        $godotArgs += @('--path', $ProjectRoot, '--resolution', '1600x900', '--position', '40,40')
    }
    else {
        $godotArgs += @('--headless', '--path', $ProjectRoot)
    }
    $godotArgs += @('--script', 'res://tools/godot_check/harness.gd', '--', "--scenario=$Name")
    if ($Ai) { $godotArgs += '--ai' }
    if ($Windowed) {
        $godotArgs += ('--shot-dir=' + $ShotDir)
        if ($Node) { $godotArgs += @("--node=$Node", "--sessions=$Sessions") }
    }

    $result = Invoke-Godot $godotArgs
    Write-Report -Label 'TEST' -Result $result
}

function Write-Report {
    param([string] $Label, [hashtable] $Result)

    if ($Raw) {
        Write-Host $Result.Raw
        if ($Result.ExitCode -ne 0) { $script:Failures++ }
        return
    }

    $lines = $Result.Lines
    if ($lines.Count -eq 0) {
        # No harness verdict at all means the run died before reporting.
        Write-Host ("{0,-4} no output, exit {1}" -f $Label, $Result.ExitCode)
        $script:Failures++
        return
    }
    $lines | ForEach-Object { Write-Host $_ }

    # Trust the report text, not just the exit code: Godot does not always
    # propagate quit(1), and a failed assertion must never be summarised as OK.
    $failed = $Result.ExitCode -ne 0
    foreach ($line in $lines) {
        if ($line -match '(^\s+x |FAIL|ABORT|CRASH|TIMEOUT|SCRIPT ERROR|USER ERROR)') { $failed = $true; break }
    }
    if ($failed) { $script:Failures++ }
}

# --- go --------------------------------------------------------------------

try {
    switch ($Mode) {
        'list' {
            $result = Invoke-Godot @(
                '--headless', '--path', $ProjectRoot,
                '--script', 'res://tools/godot_check/harness.gd', '--', '--list'
            )
            # The signal filter would drop the listing rows, so print them raw.
            ($result.Raw -split "`r?`n") |
                Where-Object { $_ -notmatch '^Godot Engine' -and $_.Trim() -ne '' } |
                ForEach-Object { Write-Host ([regex]::Replace($_, "`e\[[0-9;]*m", '').TrimEnd()) }
        }
        'lint' { Invoke-Lint }
        'boot' { Invoke-Boot }
        'test' {
            $names = if ($Scenario -eq 'all') { Get-ScenarioNames | Where-Object { $_ -ne 'look' } } else { @($Scenario) }
            foreach ($name in $names) { Invoke-Scenario -Name $name }
        }
        'shot' {
            # -Node means "photograph this moment", which is what 'look' does.
            $name = if ($Node) { 'look' } elseif ($Scenario -eq 'all') { 'look' } else { $Scenario }
            # Old images would otherwise be mistaken for this run's output.
            if (Test-Path $ShotDir) { Remove-Item (Join-Path $ShotDir '*.png') -Force -ErrorAction SilentlyContinue }
            Invoke-Scenario -Name $name -Windowed
        }
        'all' {
            Invoke-Lint
            Invoke-Boot
            foreach ($name in (Get-ScenarioNames)) {
                # lint already ran; 'look' is a camera, not a test.
                if ($name -eq 'lint' -or $name -eq 'look') { continue }
                Invoke-Scenario -Name $name
            }
        }
    }
}
finally {
    Restore-Save
}

if ($Failures -gt 0) {
    Write-Host ("FAILED  {0} run(s)" -f $Failures)
    exit 1
}
Write-Host 'ALL OK'
exit 0
