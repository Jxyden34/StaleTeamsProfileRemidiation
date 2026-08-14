<#
Intune Proactive Remediation - Detection
Detects local user profiles not used in the last X days (default 90)
and not currently loaded.

Exit 1 = remediation needed
Exit 0 = compliant
#>

# =========================
# CONFIG
# =========================
$StaleDays = 90
$MinProfileAgeDays = 14
$UserRoot = "C:\Users"

# Exclusions by profile folder name
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

$stale = @()

foreach ($p in $profiles) {
    if (-not $p.LocalPath) {
        continue
    }

    $profileName = Split-Path $p.LocalPath -Leaf

    if ($ExcludeProfileNames -contains $profileName) {
        continue
    }

    # Avoid ghost CIM profile entries whose folder no longer exists.
    if (-not (Test-Path -LiteralPath $p.LocalPath)) {
        continue
    }

    $lastUse = Convert-WmiDate $p.LastUseTime
    $folderCreated = (Get-Item -LiteralPath $p.LocalPath -ErrorAction SilentlyContinue).CreationTime

    # If LastUseTime is unavailable, only treat the profile as stale
    # when its folder is old enough to pass the safety guard.
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
        $stale += [pscustomobject]@{
            ProfileName   = $profileName
            LocalPath     = $p.LocalPath
            LastUseTime   = if ($lastUse) { $lastUse.ToString("s") } else { "Unknown" }
            FolderCreated = if ($folderCreated) { $folderCreated.ToString("s") } else { "Unknown" }
            SID           = $p.SID
        }
    }
}

if ($stale.Count -gt 0) {
    Write-Output "NON-COMPLIANT: Found $($stale.Count) stale profile(s) (>$StaleDays days) eligible for removal."
    $stale |
        Sort-Object LastUseTime, FolderCreated |
        Format-Table -AutoSize |
        Out-String |
        Write-Output

    exit 1
}

Write-Output "COMPLIANT: No stale profiles found (>$StaleDays days)."
exit 0
