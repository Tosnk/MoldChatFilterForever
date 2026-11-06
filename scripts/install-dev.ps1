# Copy the addon files into the Forever client for testing, exactly as CurseForge would lay them out.
# A copy (not a junction) keeps the CurseForge app in charge of the installed folder.
#   .\scripts\install-dev.ps1 [-AddOns "D:\Games\World of Warcraft\_forever_\Interface\AddOns"]
param(
    [string]$AddOns = "D:\Games\World of Warcraft\_forever_\Interface\AddOns"
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$target = Join-Path $AddOns "NoPetrovychChatFilter"

if (-not (Test-Path $AddOns)) { throw "AddOns folder not found: $AddOns" }
New-Item -ItemType Directory -Force $target | Out-Null

foreach ($dir in @("Core", "UI")) {
    $dst = Join-Path $target $dir
    if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
    Copy-Item -Recurse (Join-Path $root $dir) $dst
}
foreach ($file in @("NoPetrovychChatFilter.toc", "icon.png", "LICENSE", "CHANGELOG.md", "README.md")) {
    Copy-Item (Join-Path $root $file) (Join-Path $target $file) -Force
}

$version = (Select-String -Path (Join-Path $target "NoPetrovychChatFilter.toc") -Pattern "^## Version: (.+)$").Matches[0].Groups[1].Value
Write-Host "Installed NoPetrovychChatFilter $version to $target. Type /reload in game."
