<#
Test Remediation script for stale local user profiles
This version does NOT remove profiles.
It just logs which profiles would be removed.
#>

$StaleDays = 1
$MinProfileAgeDays = 1
$UserRoot = "C:\Users"

$ExcludeProfileNames = @(
    "Default",
    "Default User",
    "Public",
    "All Users",
    "Administrator",
    "enroll-Office365"
)

$now = Get-Date
$staleCutoff = $now.AddDays(-$StaleDays)
$minAgeCutoff = $now.AddDays(-$MinProfileAgeDays)

Write-Output "TEST MODE REMEDIATION START"
Write-Output "Stale cutoff: $staleCutoff"
Write-Output "Minimum age cutoff: $minAgeCutoff"

# Get all local profiles that are not special and not loaded
$profiles = Get-CimInstance Win32_UserProfile | Where-Object {
    $_.Special -eq $false -and
    $_.Loaded -eq $false -and
    $_.LocalPath -like "$UserRoot\*"
}

$toRemove = @()

foreach ($p in $profiles) {

    if (-not (Test-Path $p.LocalPath)) {
        Write-Output "Skipping missing path: $($p.LocalPath)"
        continue
    }

    $profileName = Split-Path $p.LocalPath -Leaf
    if ($ExcludeProfileNames -contains $profileName) {
        Write-Output "Skipping excluded profile: $profileName"
        continue
    }

    $lastUse = $p.LastUseTime
    $created = (Get-Item $p.LocalPath).CreationTime
    $oldEnough = $created -lt $minAgeCutoff

    if (($lastUse -and $lastUse -lt $staleCutoff) -or
        (-not $lastUse -and $oldEnough)) {
        Write-Output "PROFILE WOULD BE REMOVED: $profileName ($p.LocalPath)"
        $toRemove += $p
    }
    else {
        Write-Output "Keeping profile: $profileName"
    }
}

Write-Output "`n=== Test Removal Summary ==="
Write-Output "Profiles marked for removal: $($toRemove.Count)"
$toRemove | ForEach-Object { Write-Output " - $($_.LocalPath)" }

# Exit 1 if any would-be removal found (Intune flags attention)
if ($toRemove.Count -gt 0) {
    Write-Output "TEST MODE: $($toRemove.Count) profile(s) would be removed."
    exit 1
}

Write-Output "TEST MODE: No profiles would be removed."
exit 0
