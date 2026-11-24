[CmdletBinding()]
param([switch]$SkipConfigure)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

function Invoke-Checked {
    param([string]$Command, [string[]]$CommandArguments = @())
    & $Command @CommandArguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Command failed. Resolve the error above before continuing."
    }
}

if (-not (Test-Path -LiteralPath 'lib\firebase_options.dart')) {
    throw 'Complete Activity 8 first. lib\firebase_options.dart is required.'
}

# Reuse the patched Node runtime prepared for Activity 8, if available.
$runtimeRoot = Join-Path $PSScriptRoot '.firebase-tools-runtime'
if (Test-Path -LiteralPath $runtimeRoot) {
    $runtime = Get-ChildItem -LiteralPath $runtimeRoot -Directory |
        Where-Object {
            $_.Name -match '^node-v(24\.\d+\.\d+)-win-(x64|arm64)$' -and
            [version]$Matches[1] -ge [version]'24.20.0' -and
            (Test-Path -LiteralPath (Join-Path $_.FullName 'node.exe'))
        } |
        Sort-Object Name -Descending |
        Select-Object -First 1
    if ($runtime) { $env:PATH = "$($runtime.FullName);$env:PATH" }
}

Write-Host 'Getting the Activity 9 dependencies...'
Invoke-Checked 'flutter.bat' @('pub', 'get')

if (-not $SkipConfigure) {
    $pubCache = if ($env:PUB_CACHE) {
        $env:PUB_CACHE
    } else {
        Join-Path $env:LOCALAPPDATA 'Pub\Cache'
    }
    $flutterFire = Join-Path $pubCache 'bin\flutterfire.bat'
    if (-not (Test-Path -LiteralPath $flutterFire)) {
        throw 'Run dart pub global activate flutterfire_cli, then run this script again.'
    }
    Invoke-Checked $flutterFire @(
        'configure', '--project=roque-student-app-555646', '--platforms=web'
    )
}

Invoke-Checked 'flutter.bat' @('analyze')
Write-Host 'Firebase Console must have Anonymous sign-in enabled, the default Firestore database created, and firestore.rules published.'
Write-Host 'Login: admin / admin123. Dashboard > Manage Student Records.'
Invoke-Checked 'flutter.bat' @('run', '-d', 'chrome')
