$ErrorActionPreference = 'Stop'

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [string[]]$CommandArguments = @()
    )

    & $Command @CommandArguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Command failed. Resolve the error above, then run this script again."
    }
}

Set-Location -LiteralPath $PSScriptRoot
$mainPath = Join-Path $PSScriptRoot 'lib\main.dart'
if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'pubspec.yaml'))) {
    throw 'Keep this script in the Flutter project root beside pubspec.yaml.'
}

# Check the existing entry point before installing or configuring anything.
$mainSource = [System.IO.File]::ReadAllText($mainPath)
$oldEntryPoint = 'void main() => runApp(const StudentApp());'
if (-not $mainSource.Contains($oldEntryPoint) -and
    -not $mainSource.Contains('await Firebase.initializeApp(')) {
    throw 'main.dart has a different entry point. Update its Firebase initialization manually after configuring Web.'
}

# Older Node 24 releases can abort after a successful Firebase CLI command on
# Windows (nodejs/node#61999, fixed in 24.20.0). Use a portable patched runtime
# for this script and its child processes; leave the system Node install alone.
$nodeVersionOutput = & node.exe --version
if ($LASTEXITCODE -ne 0) { throw 'Install Node.js LTS before running this script.' }
$nodeVersion = [version]($nodeVersionOutput.Trim().TrimStart('v'))
if ($nodeVersion.Major -eq 24 -and $nodeVersion -lt [version]'24.20.0') {
    Write-Host "Node $nodeVersion has a known Windows CLI shutdown bug. Preparing a patched Node 24 runtime..."
    $runtimeRoot = Join-Path $PSScriptRoot '.firebase-tools-runtime'
    New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
    $runtimeArchitecture = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
    $cachedRuntime = Get-ChildItem -LiteralPath $runtimeRoot -Directory |
        Where-Object {
            $_.Name -match "^node-v(24\.\d+\.\d+)-win-$runtimeArchitecture`$" -and
            [version]$Matches[1] -ge [version]'24.20.0' -and
            (Test-Path -LiteralPath (Join-Path $_.FullName 'node.exe'))
        } |
        Sort-Object Name -Descending |
        Select-Object -First 1

    if ($cachedRuntime) {
        $portableNodePath = $cachedRuntime.FullName
    } else {
        # Use the current patch release of Node 24 from the official distributor.
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $checksumResponse = Invoke-WebRequest -Uri 'https://nodejs.org/dist/latest-v24.x/SHASUMS256.txt' -UseBasicParsing
        $checksumText = if ($checksumResponse.Content -is [byte[]]) {
            [System.Text.Encoding]::UTF8.GetString($checksumResponse.Content)
        } else {
            [string]$checksumResponse.Content
        }
        $checksumPattern = "(?m)^([a-fA-F0-9]{64})\s+(node-v(24\.\d+\.\d+)-win-$runtimeArchitecture\.zip)\s*`$"
        $checksumMatch = [regex]::Match($checksumText, $checksumPattern)
        if (-not $checksumMatch.Success -or [version]$checksumMatch.Groups[3].Value -lt [version]'24.20.0') {
            throw 'Could not locate a patched Windows Node 24 release on nodejs.org.'
        }
        $archiveName = $checksumMatch.Groups[2].Value
        $archivePath = Join-Path $runtimeRoot $archiveName
        $runtimeVersion = $checksumMatch.Groups[3].Value
        Invoke-WebRequest -Uri "https://nodejs.org/dist/v$runtimeVersion/$archiveName" -OutFile $archivePath -UseBasicParsing
        $archiveHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
        if ($archiveHash -ne $checksumMatch.Groups[1].Value) {
            throw 'The Node download checksum did not match. Run this script again to retry the download.'
        }
        Expand-Archive -LiteralPath $archivePath -DestinationPath $runtimeRoot -Force
        $portableNodePath = Join-Path $runtimeRoot ([System.IO.Path]::GetFileNameWithoutExtension($archiveName))
    }

    $env:PATH = "$portableNodePath;$env:PATH"
    Invoke-Checked 'node.exe' @('--version')
}

Write-Host 'Checking Flutter, Dart, and Node.js...'
Invoke-Checked 'flutter.bat' @('--version')
Invoke-Checked 'dart.bat' @('--version')
Invoke-Checked 'flutter.bat' @('doctor')
Invoke-Checked 'node.exe' @('--version')
Invoke-Checked 'npm.cmd' @('--version')

Write-Host 'Installing Firebase CLI...'
Invoke-Checked 'npm.cmd' @('install', '-g', 'firebase-tools')
$npmPrefixOutput = & npm.cmd config get prefix
if ($LASTEXITCODE -ne 0) { throw 'Could not find the npm executable folder.' }
$npmBin = ($npmPrefixOutput | Select-Object -Last 1).Trim()
$env:PATH = "$npmBin;$env:PATH"
Invoke-Checked 'firebase.cmd' @('--version')

Write-Host 'Complete Google sign-in in your browser when prompted.'
Invoke-Checked 'firebase.cmd' @('login')

# Match the stable project ID first: a project created in the console may have
# a different display name. Keep the name lookup for earlier custom IDs.
$defaultFirebaseProjectId = 'roque-student-app-555646'
Write-Host 'Checking your Firebase projects (an empty list is okay)...'
$projectListOutput = & firebase.cmd projects:list --json
if ($LASTEXITCODE -ne 0) { throw 'Could not check your Firebase projects.' }
$projectResponse = ($projectListOutput -join "`n") | ConvertFrom-Json
if ($projectResponse.status -ne 'success') { throw 'Firebase did not return a successful project list.' }
$matchingProject = $projectResponse.result |
    Where-Object { $_.projectId -eq $defaultFirebaseProjectId } |
    Select-Object -First 1
if (-not $matchingProject) {
    $matchingProject = $projectResponse.result |
        Where-Object { $_.displayName -eq 'Roque Student App' } |
        Select-Object -First 1
}

if ($matchingProject) {
    $firebaseProjectId = $matchingProject.projectId
    Write-Host "Using existing Firebase project: $firebaseProjectId"
} else {
    do {
        $firebaseProjectId = Read-Host "Enter an existing or new Project ID [$defaultFirebaseProjectId] (Enter uses default)"
        if ([string]::IsNullOrWhiteSpace($firebaseProjectId)) {
            $firebaseProjectId = $defaultFirebaseProjectId
        } else {
            $firebaseProjectId = $firebaseProjectId.Trim()
        }
        $validProjectId = $firebaseProjectId -cmatch '^[a-z][a-z0-9-]{4,28}[a-z0-9]$'
        if (-not $validProjectId) {
            Write-Warning 'Enter only a Project ID: 6-30 lowercase letters, digits, or hyphens; start with a letter and end with a letter or digit.'
        }
    } while (-not $validProjectId)

    $matchingProject = $projectResponse.result |
        Where-Object { $_.projectId -eq $firebaseProjectId } |
        Select-Object -First 1
    if ($matchingProject) {
        Write-Host "Using existing Firebase project: $firebaseProjectId"
    } else {
        Write-Host 'Creating your Firebase project with display name: Roque Student App'
        Invoke-Checked 'firebase.cmd' @('projects:create', $firebaseProjectId, '--display-name', 'Roque Student App')
    }
}

Write-Host 'Installing FlutterFire CLI...'
Invoke-Checked 'dart.bat' @('pub', 'global', 'activate', 'flutterfire_cli')
$dartCache = if ($env:PUB_CACHE) {
    $env:PUB_CACHE
} else {
    Join-Path $env:LOCALAPPDATA 'Pub\Cache'
}
$dartBin = Join-Path $dartCache 'bin'
$env:PATH = "$dartBin;$env:PATH"
Invoke-Checked 'flutterfire.bat' @('--version')

Write-Host 'Adding Firebase Core and configuring Web...'
Invoke-Checked 'flutter.bat' @('pub', 'add', 'firebase_core')
Write-Host "Configuring Roque Student App ($firebaseProjectId) for Web..."
Invoke-Checked 'flutterfire.bat' @('configure', '--project', $firebaseProjectId, '--platforms=web')

$optionsPath = Join-Path $PSScriptRoot 'lib\firebase_options.dart'
if (-not (Test-Path -LiteralPath $optionsPath)) {
    throw 'FlutterFire did not generate lib/firebase_options.dart. main.dart has not been changed.'
}

# Keep the existing theme, LoginScreen, navigation, and DemoAuth implementation.
# Read main.dart again so a change made during browser sign-in is not overwritten.
$mainSource = [System.IO.File]::ReadAllText($mainPath)
if (-not $mainSource.Contains('await Firebase.initializeApp(')) {
    if (-not $mainSource.Contains($oldEntryPoint) -or
        -not $mainSource.Contains("import 'package:flutter/material.dart';") -or
        -not $mainSource.Contains("import 'login_screen.dart';")) {
        throw 'main.dart changed during setup. Add Firebase initialization manually; this script has left it unchanged.'
    }

    $newline = if ($mainSource.Contains("`r`n")) { "`r`n" } else { "`n" }
    $newEntryPoint = @(
        'Future<void> main() async {'
        '  WidgetsFlutterBinding.ensureInitialized();'
        ''
        '  await Firebase.initializeApp('
        '    options: DefaultFirebaseOptions.currentPlatform,'
        '  );'
        ''
        '  runApp(const StudentApp());'
        '}'
    ) -join $newline

    $mainSource = $mainSource.Replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';${newline}import 'package:firebase_core/firebase_core.dart';"
    ).Replace(
        "import 'login_screen.dart';",
        "import 'firebase_options.dart';${newline}import 'login_screen.dart';"
    ).Replace($oldEntryPoint, $newEntryPoint)

    [System.IO.File]::WriteAllText($mainPath, $mainSource, [System.Text.UTF8Encoding]::new($false))
}

Invoke-Checked 'dart.bat' @('format', 'lib/main.dart')
Invoke-Checked 'flutter.bat' @('analyze')

Write-Host 'Opening the application in Chrome. DemoAuth login: admin / admin123.'
Write-Host 'Verify registration, all four navigation tabs, calculator, social interactions, and logout.'
Write-Host 'Capture your real setup screenshots and complete docs/Firebase_Setup_Activity.md.'
Invoke-Checked 'flutter.bat' @('run', '-d', 'chrome')
