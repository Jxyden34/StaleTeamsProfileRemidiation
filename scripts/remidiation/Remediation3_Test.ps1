<# 
Remove stale local user profiles
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

$removed = @()
$failed  = @()

foreach ($p in $profiles) {

    if (-not (Test-Path $p.LocalPath)) { continue }

    $profileName = Split-Path $p.LocalPath -Leaf
    if ($ExcludeProfileNames -contains $profileName) { continue }

    $lastUse = Convert-WmiDate $p.LastUseTime
    $created = (Get-Item $p.LocalPath).CreationTime
    $oldEnough = $created -lt $minAgeCutoff

    $isStale = $false
    if ($lastUse) {
        $isStale = $lastUse -lt $staleCutoff
    }
    elseif ($oldEnough) {
        $isStale = $true
    }

    if ($isStale) {
        try {
            Remove-CimInstance -InputObject $p -ErrorAction Stop
            $removed += $profileName
        }
        catch {
            $failed += "$profileName : $($_.Exception.Message)"
        }
    }
}

Write-Output "Removed profiles: $($removed -join ', ')"

if ($failed.Count -gt 0) {
    Write-Output "Failed removals:"
    $failed | ForEach-Object { Write-Output $_ }
    exit 1
}

exit 0
