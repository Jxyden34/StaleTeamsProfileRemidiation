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
    if ([string]::IsNullOrWhiteSpace($WmiDate)) { return $null }
    try {
        [Management.ManagementDateTimeConverter]::ToDateTime($WmiDate)
    } catch {
        return $null
    }
}

$profiles = Get-CimInstance Win32_UserProfile | Where-Object {
    $_.Special -eq $false -and
    $_.Loaded -eq $false -and
    $_.LocalPath -like "$UserRoot\*"
}

$staleProfiles = foreach ($p in $profiles) {

    if (-not (Test-Path $p.LocalPath)) { continue }

    $profileName = Split-Path $p.LocalPath -Leaf
    if ($ExcludeProfileNames -contains $profileName) { continue }

    $lastUse = Convert-WmiDate $p.LastUseTime
    $created = (Get-Item $p.LocalPath).CreationTime

    $oldEnough = $created -lt $minAgeCutoff

    if ($lastUse) {
        if ($lastUse -lt $staleCutoff) { $p }
    }
    elseif ($oldEnough) {
        $p
    }
}

if ($staleProfiles.Count -gt 0) {
    Write-Output "Found $($staleProfiles.Count) stale profile(s)"
    exit 1
}

Write-Output "No stale profiles found"
exit 0
