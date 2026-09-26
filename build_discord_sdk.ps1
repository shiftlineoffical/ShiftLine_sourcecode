$ErrorActionPreference = "Stop"

$projectPath = $env:SHIFTLINE_LUA_DISCORD_GAME_SDK_PATH
if ([string]::IsNullOrWhiteSpace($projectPath)) {
    $projectPath = Join-Path $PSScriptRoot "lua_discord_game_sdk"
}

$discordSdkPath = $env:DISCORD_GAME_SDK_PATH
if ([string]::IsNullOrWhiteSpace($discordSdkPath)) {
    $discordSdkPath = Join-Path $PSScriptRoot "discord_game_sdk"
}

$sdkVersion = $env:DISCORD_GAME_SDK_VERSION
if ([string]::IsNullOrWhiteSpace($sdkVersion)) {
    $sdkVersion = "3.2.1"
}

$sdkLibrary = Join-Path $discordSdkPath "lib\x86_64"
$discordLibrary = Join-Path $sdkLibrary "discord_game_sdk.dll"
if (-not (Test-Path $discordLibrary)) {
    $downloadRoot = Join-Path ([System.IO.Path]::GetTempPath()) "shiftline-discord-sdk"
    $archivePath = Join-Path $downloadRoot "discord_game_sdk_$sdkVersion.zip"
    $extractPath = Join-Path $downloadRoot "extract_$sdkVersion"
    New-Item -ItemType Directory -Path $downloadRoot -Force | Out-Null
    if (-not (Test-Path $archivePath)) {
        Invoke-WebRequest `
            -Uri "https://dl-game-sdk.discordapp.net/$sdkVersion/discord_game_sdk.zip" `
            -OutFile $archivePath `
            -UseBasicParsing
    }
    if (Test-Path $extractPath) {
        Remove-Item $extractPath -Recurse -Force
    }
    Expand-Archive -Path $archivePath -DestinationPath $extractPath -Force
    $downloadedLibrary = Get-ChildItem $extractPath -Recurse -Filter "discord_game_sdk.dll" |
        Where-Object { $_.FullName -match "[\\/]lib[\\/]x86_64[\\/]discord_game_sdk\.dll$" } |
        Select-Object -First 1
    if (-not $downloadedLibrary) {
        throw "Discord Game SDK Windows x86_64 DLL was not found in the archive"
    }
    $downloadedRoot = Split-Path (Split-Path (Split-Path $downloadedLibrary.FullName -Parent) -Parent) -Parent
    New-Item -ItemType Directory -Path $discordSdkPath -Force | Out-Null
    Copy-Item (Join-Path $downloadedRoot "*") $discordSdkPath -Recurse -Force
}
$env:DISCORD_GAME_SDK_PATH = $discordSdkPath

foreach ($architecture in @("x86_64", "x86")) {
    $architecturePath = Join-Path $discordSdkPath "lib\$architecture"
    $dllImportLibrary = Join-Path $architecturePath "discord_game_sdk.dll.lib"
    $importLibrary = Join-Path $architecturePath "discord_game_sdk.lib"
    if ((Test-Path $dllImportLibrary) -and -not (Test-Path $importLibrary)) {
        Copy-Item $dllImportLibrary $importLibrary
    }
}

$manifestPath = Join-Path $projectPath "Cargo.toml"
if (-not (Test-Path $manifestPath)) {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) {
        throw "git was not found"
    }
    & $git.Source clone https://github.com/CorentinVaillant/lua_discord_game_sdk.git $projectPath
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $manifestPath)) {
        throw "lua_discord_game_sdk could not be downloaded"
    }
}

$cargo = Get-Command cargo -ErrorAction SilentlyContinue
if (-not $cargo) {
    throw "cargo was not found"
}

if (-not (Test-Path $discordLibrary)) {
    throw "discord_game_sdk.dll was not found"
}

& $cargo.Source build --release --manifest-path $manifestPath
if ($LASTEXITCODE -ne 0) {
    throw "lua_discord_game_sdk build failed"
}

$artifactNames = @(
    "lua_discord_game_sdk.dll",
    "liblua_discord_game_sdk.dll"
)
$artifact = $artifactNames |
    ForEach-Object { Join-Path $projectPath "target\release\$_" } |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1

if (-not $artifact) {
    throw "built lua_discord_game_sdk DLL was not found"
}

Copy-Item $artifact (Join-Path $PSScriptRoot "lua_discord_game_sdk.dll") -Force
Copy-Item $discordLibrary (Join-Path $PSScriptRoot "discord_game_sdk.dll") -Force