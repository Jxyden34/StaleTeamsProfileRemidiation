<#  
Intune Proactive Remediation - Detection  
Detects local user profiles not used in the last X days (default 90) and not currently loaded.  
Outputs a summary for reporting.  
Exit 1 = remediation needed  
Exit 0 = compliant  
#># ========================= # CONFIG # ========================= $StaleDays = 90          # change to 60 if desired $MinProfileAgeDays = 14  # safety guard: don't remove profiles created within last 14 days $UserRoot = "C:\Users"# Exclusions by profile folder name (not domain\user) # Add any accounts you NEVER want deleted. $ExcludeProfileNames = @(
  "Default",
  "Default User",
  "Public",
  "All Users",
  "Administrator",
  "enroll-Office365")
# ========================= # LOGIC # ========================= $now = Get-Date $staleCutoff = $now.AddDays(-$StaleDays)$minAgeCutoff = $now.AddDays(-$MinProfileAgeDays)
function Convert-WmiDate {
  param([string]$wmiDate)
  if ([string]::IsNullOrWhiteSpace($wmiDate)) { return $null }
  try { return [Management.ManagementDateTimeConverter]::ToDateTime($wmiDate) } catch { return $null }
}
# Grab profiles via CIM (preferred) $profiles = Get-CimInstance Win32_UserProfile -ErrorAction Stop |
  Where-Object {
    $_.Special -eq $false -and$_.LocalPath -like "$UserRoot\*" -and$_.Loaded -eq $false  }
$stale = @()
foreach ($p in $profiles) {
  if (-not $p.LocalPath) { continue }
  $profileName = Split-Path $p.LocalPath -Leafif ($ExcludeProfileNames -contains $profileName) { continue }
  # Must exist on disk (avoid ghost entries)if (-not (Test-Path -LiteralPath $p.LocalPath)) { continue }
  $lastUse = Convert-WmiDate $p.LastUseTime
  # If LastUseTime is null, treat as candidate only if old enough (use folder creation time as a hint)$folderCreated = (Get-Item -LiteralPath $p.LocalPath -ErrorAction SilentlyContinue).CreationTime
  $isOldEnough = $falseif ($folderCreated) { $isOldEnough = ($folderCreated -lt $minAgeCutoff) } else { $isOldEnough = $true }
  $isStale = $falseif ($lastUse) {
    $isStale = ($lastUse -lt $staleCutoff)
  } else {
    # no last use time - only consider stale if folder is not "new"$isStale = $isOldEnough  }
  if ($isStale) {
    $stale += [pscustomobject]@{
      ProfileName = $profileName      LocalPath   = $p.LocalPath
      LastUseTime = if ($lastUse) { $lastUse.ToString("s") } else { "Unknown" }
      FolderCreated = if ($folderCreated) { $folderCreated.ToString("s") } else { "Unknown" }
      SID         = $p.SID
    }
  }
}
if ($stale.Count -gt 0) {
  Write-Output "NON-COMPLIANT: Found $($stale.Count) stale profile(s) (>$StaleDays days) eligible for removal."
  $stale | Sort-Object LastUseTime, FolderCreated | Format-Table -AutoSize | Out-String | Write-Outputexit 1} else {
  Write-Output "COMPLIANT: No stale profiles found (>$StaleDays days)."
  exit 0}