Write-Host "== TEAMS INVENTORY ==" -ForegroundColor Cyan

Write-Host "`n[Appx packages - all users]" -ForegroundColor Yellow
Get-AppxPackage -AllUsers *teams* |
    Select-Object Name, PackageFullName, Version

Write-Host "`n[Classic machine-wide installer]" -ForegroundColor Yellow
$uninstallPaths = @(
  "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
  "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$uninstallPaths | ForEach-Object {
  Get-ItemProperty $_ -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like "*Teams*" } |
    Select-Object DisplayName, DisplayVersion, PSChildName
}

Write-Host "`n[Per-user classic folders]" -ForegroundColor Yellow
Get-ChildItem "C:\Users" -Directory |
  Where-Object { $_.Name -notin @('Public','Default','Default User','All Users') } |
  ForEach-Object {
    $teamsPath = Join-Path $_.FullName "AppData\Local\Microsoft\Teams"
    if (Test-Path $teamsPath) {
      [PSCustomObject]@{
        User      = $_.Name
        TeamsPath = $teamsPath
      }
    }
  }

