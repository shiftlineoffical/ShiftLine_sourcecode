param(
    [Parameter(Mandatory = $true)][string]$Url,
    [Parameter(Mandatory = $true)][string]$TargetDir,
    [string]$RestartPath
)

function Write-Log {
    param([string]$Message)
    Write-Host $Message
}

$ErrorActionPreference = "Stop"

Write-Log "ShiftLine updater starting..."
Write-Log "TargetDir: $TargetDir"
Write-Log "Url: $Url"

# アプリ終了待ち
if ($RestartPath) {
    Write-Log "Waiting for app to exit..."
    $processName = [IO.Path]::GetFileNameWithoutExtension($RestartPath)

    while (Get-Process -Name $processName -ErrorAction SilentlyContinue) {
        Start-Sleep -Milliseconds 500
    }
}

Start-Sleep -Seconds 1

if (-not (Test-Path -Path $TargetDir)) {
    Write-Log "TargetDir does not exist."
    exit 2
}

$cleanUrl = $Url.Split("?")[0]
$ext = [IO.Path]::GetExtension($cleanUrl)
if ([string]::IsNullOrWhiteSpace($ext)) {
    $ext = ".zip"
}

$tmpDir = Join-Path $TargetDir "_update_tmp"
$extractDir = Join-Path $tmpDir "extracted"

New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
$packagePath = Join-Path $tmpDir ("update_package" + $ext)

Write-Log "Downloading update..."
$wc = New-Object System.Net.WebClient
$wc.Headers["User-Agent"] = "ShiftLine-Updater"

try {
    $wc.DownloadFile($Url, $packagePath)
} catch {
    Write-Log "Download failed."
    exit 3
}

Write-Log "Extracting..."

if ($ext -ieq ".zip") {
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null

    Expand-Archive -Path $packagePath -DestinationPath $extractDir -Force
    Copy-Item -Path (Join-Path $extractDir "*") -Destination $TargetDir -Recurse -Force
} else {
    Write-Log "Unsupported format"
    exit 4
}

Write-Log "Cleaning up..."
Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

if ($RestartPath) {
    Write-Log "Restarting..."
    Start-Process -FilePath $RestartPath -WorkingDirectory (Split-Path -Parent $RestartPath)
}

Write-Log "Update complete."