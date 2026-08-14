<#
Intune Proactive Remediation - Remediation
Removes local user profiles not used in the last X days (default 90)
and not currently loaded.

Uses Remove-CimInstance on Win32_UserProfile.
#>

# =========================
# CONFIG
# =========================
$StaleDays = 90
$MinProfileAgeDays = 14
$UserRoot = "C:\Users"

$ExcludeProfileNames = @(
    "Default",
    "Default User",
    "Public",
    "All Users",
    "Administrator",
    "enroll-Office365"
)

# =========================
# LOGIC
# =========================
$now = Get-Date
$staleCutoff = $now.AddDays(-$StaleDays)
$minAgeCutoff = $now.AddDays(-$MinProfileAgeDays)

function Convert-WmiDate {
    param(
        [string]$WmiDate
    )

    if ([string]::IsNullOrWhiteSpace($WmiDate)) {
        return $null
    }

    try {
        return [Management.ManagementDateTimeConverter]::ToDateTime($WmiDate)
    }
    catch {
        return $null
    }
}

$profiles = Get-CimInstance Win32_UserProfile -ErrorAction Stop |
    Where-Object {
        $_.Special -eq $false -and
        $_.LocalPath -like "$UserRoot\*" -and
        $_.Loaded -eq $false
    }

$toRemove = @()

foreach ($p in $profiles) {
    if (-not $p.LocalPath) {
        continue
    }

    $profileName = Split-Path $p.LocalPath -Leaf

    if ($ExcludeProfileNames -contains $profileName) {
        continue
    }

    if (-not (Test-Path -LiteralPath $p.LocalPath)) {
        continue
    }

    $lastUse = Convert-WmiDate $p.LastUseTime
    $folderCreated = (Get-Item -LiteralPath $p.LocalPath -ErrorAction SilentlyContinue).CreationTime

    $isOldEnough = if ($folderCreated) {
        $folderCreated -lt $minAgeCutoff
    }
    else {
        $true
    }

    $isStale = if ($lastUse) {
        $lastUse -lt $staleCutoff
    }
    else {
        $isOldEnough
    }

    if ($isStale) {
        $toRemove += [pscustomobject]@{
            ProfileName   = $profileName
            LocalPath     = $p.LocalPath
            LastUseTime   = if ($lastUse) { $lastUse.ToString("s") } else { "Unknown" }
            FolderCreated = if ($folderCreated) { $folderCreated.ToString("s") } else { "Unknown" }
            SID           = $p.SID
            CimObject     = $p
        }
    }
}

if ($toRemove.Count -eq 0) {
    Write-Output "Nothing to remediate: no stale profiles found (>$StaleDays days)."
    exit 0
}

Write-Output "Remediation starting: removing $($toRemove.Count) stale profile(s) (>$StaleDays days)."

$removed = @()
$failed = @()

foreach ($item in $toRemove) {
    try {
        Write-Output "Removing profile: $($item.ProfileName) | $($item.LocalPath) | LastUse=$($item.LastUseTime)"

        Remove-CimInstance -InputObject $item.CimObject -ErrorAction Stop

        $removed += [pscustomobject]@{
            ProfileName = $item.ProfileName
            LocalPath   = $item.LocalPath
            LastUseTime = $item.LastUseTime
            SID         = $item.SID
            Result      = "Removed"
        }
    }
    catch {
        $failed += [pscustomobject]@{
            ProfileName = $item.ProfileName
            LocalPath   = $item.LocalPath
            LastUseTime = $item.LastUseTime
            SID         = $item.SID
            Result      = "Failed"
            Error       = $_.Exception.Message
        }
    }
}

Write-Output "`n=== Removal Summary ==="

if ($removed.Count -gt 0) {
    Write-Output "Removed:"
    $removed |
        Format-Table -AutoSize |
        Out-String |
        Write-Output
}

if ($failed.Count -gt 0) {
    Write-Output "Failed:"
    $failed |
        Format-Table -AutoSize |
        Out-String |
        Write-Output

    # Non-zero exit so Intune reports that remediation needs attention.
    exit 1
}

Write-Output "Remediation completed successfully."
exit 0
