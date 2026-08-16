<#
Remediation script for stale local user profiles
Removes profiles detected as stale by the detection script.
#>

$StaleDays = 90
$MinProfileAgeDays = 90
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

Write-Output "Remediation started at $now"
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
        Write-Output "Marked for removal: $profileName ($p.LocalPath)"
        $toRemove += $p
    }
    else {
        Write-Output "Keeping profile: $profileName"
    }
}

# If nothing to remove, exit 0 (compliant)
if ($toRemove.Count -eq 0) {
    Write-Output "No stale profiles to remove."
    exit 0
}

# Remove profiles
$removed = @()
$failed  = @()

foreach ($profile in $toRemove) {
    try {
        Write-Output "Removing profile: $($profile.LocalPath)"
        Remove-CimInstance -InputObject $profile -ErrorAction Stop

        $removed += [pscustomobject]@{
            ProfileName = Split-Path $profile.LocalPath -Leaf
            LocalPath   = $profile.LocalPath
            SID         = $profile.SID
            Result      = "Removed"
        }
    }
    catch {
        $failed += [pscustomobject]@{
            ProfileName = Split-Path $profile.LocalPath -Leaf
            LocalPath   = $profile.LocalPath
            SID         = $profile.SID
            Result      = "Failed"
            Error       = $_.Exception.Message
        }
    }
}

# Output summary
Write-Output "`n=== Removal Summary ==="
if ($removed.Count -gt 0) {
    Write-Output "Removed Profiles:"
    $removed | Format-Table -AutoSize | Out-String | Write-Output
}

if ($failed.Count -gt 0) {
    Write-Output "Failed Removals:"
    $failed | Format-Table -AutoSize | Out-String | Write-Output

    # Exit 1 so Intune flags remediation attention
    exit 1
}

Write-Output "Remediation completed successfully."
exit 0
