$StaleDays = 90
$UserRoot = "C:\Users"

$ExcludeProfileNames = @(
    "Default",
    "Default User",
    "Public",
    "All Users",
    "Administrator",
    "enroll-Office365",
    "DefaultAppPool"
)

function Get-StaleProfiles {
    param (
        [int]$ThresholdDays = $StaleDays
    )

    $staleCutoff = (Get-Date).AddDays(-$ThresholdDays)

    $profiles = Get-CimInstance -ClassName Win32_UserProfile | Where-Object {
        $_.Special -eq $false -and
        $_.Loaded -eq $false -and
        $_.LocalPath -like "$UserRoot\*"
    }

    $staleProfiles = @()

    foreach ($p in $profiles) {
        $profileName = Split-Path -Path $p.LocalPath -Leaf
        if ($ExcludeProfileNames -contains $profileName) {
            continue
        }

        $lastUse = $p.LastUseTime
        if ($lastUse -and $lastUse -lt $staleCutoff) {
            $staleProfiles += $p
        }
    }

    return $staleProfiles
}

function Get-DetectionExitCode {
    param (
        [int]$ThresholdDays = $StaleDays
    )

    $staleProfiles = Get-StaleProfiles -ThresholdDays $ThresholdDays
    if ($staleProfiles.Count -gt 0) {
        return 1
    }

    return 0
}

if ($MyInvocation.InvocationName -ne '.') {
    exit (Get-DetectionExitCode -ThresholdDays $StaleDays)
}
