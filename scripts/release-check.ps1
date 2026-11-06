param(
    [Parameter(Mandatory = $true)]
    [string]$ExpectedVersion
)

# Verifies that the TOC version and the top CHANGELOG.md section match the version being
# released, so a tag never ships with stale metadata. Mirrors the EasyPrescience release check.

$ErrorActionPreference = "Stop"

$tocPath = Join-Path $PSScriptRoot "..\MoldChatFilterForever.toc"
$changelogPath = Join-Path $PSScriptRoot "..\CHANGELOG.md"

$tocContent = Get-Content -LiteralPath $tocPath
$versionLine = $tocContent | Where-Object { $_ -match '^## Version:' } | Select-Object -First 1
if (-not $versionLine) {
    throw "Missing version line in TOC."
}

$tocVersion = ($versionLine -replace '^## Version:\s*', '').Trim()
if ($tocVersion -ne $ExpectedVersion) {
    throw "TOC version '$tocVersion' does not match expected version '$ExpectedVersion'."
}

$changelogContent = Get-Content -LiteralPath $changelogPath
$expectedHeader = "## $ExpectedVersion"
if (-not ($changelogContent -contains $expectedHeader)) {
    throw "CHANGELOG.md does not contain release header '$expectedHeader'."
}

$headCommit = (git rev-parse HEAD).Trim()
Write-Output "Release check passed."
Write-Output "VERSION=$ExpectedVersion"
Write-Output "HEAD=$headCommit"
