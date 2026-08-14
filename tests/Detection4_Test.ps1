<#
Detect stale local user profiles
Exit 1 = remediation needed
Exit 0 = compliant
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

function Convert-WmiDate {
    param ([string]$WmiDate)

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

Write-Output "Stale cutoff: $staleCutoff"
Write-Output "Minimum age cutoff: $minAgeCutoff"

$profiles = Get-CimInstance Win32_UserProfile | Where-Object {
    $_.Special -eq $false -and
    $_.Loaded -eq $false -and
    $_.LocalPath -like "$UserRoot\*"
}

$staleProfiles = @()

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

    $lastUse = Convert-WmiDate $p.LastUseTime
    $created = (Get-Item $p.LocalPath).CreationTime

    Write-Output "`nProfile: $profileName"
    Write-Output "Created: $created"
    Write-Output "LastUseTime: $lastUse"

    # Ensure profile isn't too new
    if ($created -gt $minAgeCutoff) {
        Write-Output "→ Too new, skipping"
        continue
    }

    if ($lastUse) {
        if ($lastUse -lt $staleCutoff) {
            Write-Output "→ Marked STALE (LastUseTime)"
            $staleProfiles += $p
        }
        else {
            Write-Output "→ Recently used"
        }
    }
    else {
        # No LastUseTime → fall back to creation time
        if ($created -lt $staleCutoff) {
            Write-Output "→ Marked STALE (CreationTime fallback)"
            $staleProfiles += $p
        }
        else {
            Write-Output "→ No LastUseTime but not stale"
        }
    }
}

if ($staleProfiles.Count -gt 0) {
    Write-Output "`nFound $($staleProfiles.Count) stale profile(s)"
    exit 1
}

Write-Output "`nNo stale profiles found"
exit 0
