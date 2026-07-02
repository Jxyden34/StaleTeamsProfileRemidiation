# ============================================================
# Pester Tests — Detect-StaleProfiles.ps1
# University of Huddersfield | Jayden Hindley
#
# These tests mock Win32_UserProfile CIM responses so they
# run without needing a physical managed device.
#
# Run locally with:  Invoke-Pester ./tests -Output Detailed
# Run in pipeline:   Triggered automatically by GitHub Actions
# ============================================================

BeforeAll {
    # Load the detection script so its functions are available
    # to test. The script must not execute automatically on
    # dot-source — all logic should be inside functions.
    . "$PSScriptRoot/../scripts/Detect-StaleProfiles.ps1"
}

# ============================================================
# PROFILE DETECTION — Core stale threshold logic
# ============================================================

Describe "Stale Profile Detection" {

    Context "Profile is older than the stale threshold" {

        It "flags a profile last used 120 days ago when threshold is 90 days" {
            # Arrange — mock a single profile unused for 120 days
            Mock Get-CimInstance {
                return @(
                    [PSCustomObject]@{
                        LocalPath   = "C:\Users\OldUser"
                        SID         = "S-1-5-21-1234567890-1234567890-1234567890-1001"
                        Loaded      = $false
                        Special     = $false
                        LastUseTime = (Get-Date).AddDays(-120)
                    }
                )
            } -ParameterFilter { $ClassName -eq "Win32_UserProfile" }

            # Act
            $result = Get-StaleProfiles -ThresholdDays 90

            # Assert
            $result.Count | Should -Be 1
            $result[0].LocalPath | Should -Be "C:\Users\OldUser"
        }

        It "flags multiple profiles when both exceed the threshold" {
            Mock Get-CimInstance {
                return @(
                    [PSCustomObject]@{
                        LocalPath   = "C:\Users\OldUser1"
                        SID         = "S-1-5-21-1111111111-1111111111-1111111111-1001"
                        Loaded      = $false
                        Special     = $false
                        LastUseTime = (Get-Date).AddDays(-100)
                    },
                    [PSCustomObject]@{
                        LocalPath   = "C:\Users\OldUser2"
                        SID         = "S-1-5-21-2222222222-2222222222-2222222222-1001"
                        Loaded      = $false
                        Special     = $false
                        LastUseTime = (Get-Date).AddDays(-200)
                    }
                )
            } -ParameterFilter { $ClassName -eq "Win32_UserProfile" }

            $result = Get-StaleProfiles -ThresholdDays 90

            $result.Count | Should -Be 2
        }
    }

    Context "Profile is within the stale threshold" {

        It "does not flag a profile last used 30 days ago when threshold is 90 days" {
            Mock Get-CimInstance {
                return @(
                    [PSCustomObject]@{
                        LocalPath   = "C:\Users\RecentUser"
                        SID         = "S-1-5-21-1234567890-1234567890-1234567890-1002"
                        Loaded      = $false
                        Special     = $false
                        LastUseTime = (Get-Date).AddDays(-30)
                    }
                )
            } -ParameterFilter { $ClassName -eq "Win32_UserProfile" }

            $result = Get-StaleProfiles -ThresholdDays 90

            $result.Count | Should -Be 0
        }

        It "does not flag a profile used exactly on the threshold boundary" {
            Mock Get-CimInstance {
                return @(
                    [PSCustomObject]@{
                        LocalPath   = "C:\Users\BoundaryUser"
                        SID         = "S-1-5-21-1234567890-1234567890-1234567890-1003"
                        Loaded      = $false
                        Special     = $false
                        LastUseTime = (Get-Date).AddDays(-90)
                    }
                )
            } -ParameterFilter { $ClassName -eq "Win32_UserProfile" }

            $result = Get-StaleProfiles -ThresholdDays 90

            $result.Count | Should -Be 0
        }
    }
}

# ============================================================
# EXCLUSION LOGIC — Active and loaded profiles
# ============================================================

Describe "Active Profile Exclusions" {

    Context "Profile is currently loaded" {

        It "does not flag a loaded profile even if it exceeds the threshold" {
            Mock Get-CimInstance {
                return @(
                    [PSCustomObject]@{
                        LocalPath   = "C:\Users\LoggedInUser"
                        SID         = "S-1-5-21-1234567890-1234567890-1234567890-1004"
                        Loaded      = $true
                        Special     = $false
                        LastUseTime = (Get-Date).AddDays(-120)
                    }
                )
            } -ParameterFilter { $ClassName -eq "Win32_UserProfile" }

            $result = Get-StaleProfiles -ThresholdDays 90

            $result.Count | Should -Be 0
        }
    }

    Context "Device has no stale profiles" {

        It "returns an empty result and does not throw when no profiles are found" {
            Mock Get-CimInstance {
                return @()
            } -ParameterFilter { $ClassName -eq "Win32_UserProfile" }

            { Get-StaleProfiles -ThresholdDays 90 } | Should -Not -Throw

            $result = Get-StaleProfiles -ThresholdDays 90
            $result.Count | Should -Be 0
        }
    }
}

# ============================================================
# EXCLUSION LOGIC — System and special accounts
# ============================================================

Describe "System Account Exclusions" {

    Context "Profile belongs to a built-in system account" {

        It "does not flag a special system profile (SID S-1-5-18)" {
            Mock Get-CimInstance {
                return @(
                    [PSCustomObject]@{
                        LocalPath   = "C:\Windows\system32\config\systemprofile"
                        SID         = "S-1-5-18"
                        Loaded      = $false
                        Special     = $true
                        LastUseTime = (Get-Date).AddDays(-120)
                    }
                )
            } -ParameterFilter { $ClassName -eq "Win32_UserProfile" }

            $result = Get-StaleProfiles -ThresholdDays 90

            $result.Count | Should -Be 0
        }

        It "does not flag a local service profile (SID S-1-5-19)" {
            Mock Get-CimInstance {
                return @(
                    [PSCustomObject]@{
                        LocalPath   = "C:\Windows\ServiceProfiles\LocalService"
                        SID         = "S-1-5-19"
                        Loaded      = $false
                        Special     = $true
                        LastUseTime = (Get-Date).AddDays(-120)
                    }
                )
            } -ParameterFilter { $ClassName -eq "Win32_UserProfile" }

            $result = Get-StaleProfiles -ThresholdDays 90

            $result.Count | Should -Be 0
        }

        It "does not flag a network service profile (SID S-1-5-20)" {
            Mock Get-CimInstance {
                return @(
                    [PSCustomObject]@{
                        LocalPath   = "C:\Windows\ServiceProfiles\NetworkService"
                        SID         = "S-1-5-20"
                        Loaded      = $false
                        Special     = $true
                        LastUseTime = (Get-Date).AddDays(-120)
                    }
                )
            } -ParameterFilter { $ClassName -eq "Win32_UserProfile" }

            $result = Get-StaleProfiles -ThresholdDays 90

            $result.Count | Should -Be 0
        }
    }
}

# ============================================================
# EXCLUSION LOGIC — Protected profile names
# ============================================================

Describe "Protected Profile Name Exclusions" {

    Context "Profile folder name matches a protected name" {

        It "does not flag a profile named Administrator" {
            Mock Get-CimInstance {
                return @(
                    [PSCustomObject]@{
                        LocalPath   = "C:\Users\Administrator"
                        SID         = "S-1-5-21-1234567890-1234567890-1234567890-500"
                        Loaded      = $false
                        Special     = $false
                        LastUseTime = (Get-Date).AddDays(-120)
                    }
                )
            } -ParameterFilter { $ClassName -eq "Win32_UserProfile" }

            $result = Get-StaleProfiles -ThresholdDays 90

            $result.Count | Should -Be 0
        }

        It "does not flag a profile named DefaultAppPool" {
            Mock Get-CimInstance {
                return @(
                    [PSCustomObject]@{
                        LocalPath   = "C:\Users\DefaultAppPool"
                        SID         = "S-1-5-21-1234567890-1234567890-1234567890-501"
                        Loaded      = $false
                        Special     = $false
                        LastUseTime = (Get-Date).AddDays(-120)
                    }
                )
            } -ParameterFilter { $ClassName -eq "Win32_UserProfile" }

            $result = Get-StaleProfiles -ThresholdDays 90

            $result.Count | Should -Be 0
        }
    }
}

# ============================================================
# EXIT CODE BEHAVIOUR
# ============================================================

Describe "Detection Script Exit Codes" {

    Context "Device has stale profiles" {

        It "returns exit code 1 when stale profiles are found" {
            Mock Get-CimInstance {
                return @(
                    [PSCustomObject]@{
                        LocalPath   = "C:\Users\StaleUser"
                        SID         = "S-1-5-21-1234567890-1234567890-1234567890-1005"
                        Loaded      = $false
                        Special     = $false
                        LastUseTime = (Get-Date).AddDays(-120)
                    }
                )
            } -ParameterFilter { $ClassName -eq "Win32_UserProfile" }

            $exitCode = Get-DetectionExitCode -ThresholdDays 90

            $exitCode | Should -Be 1
        }
    }

    Context "Device has no stale profiles" {

        It "returns exit code 0 when no stale profiles are found" {
            Mock Get-CimInstance {
                return @(
                    [PSCustomObject]@{
                        LocalPath   = "C:\Users\ActiveUser"
                        SID         = "S-1-5-21-1234567890-1234567890-1234567890-1006"
                        Loaded      = $false
                        Special     = $false
                        LastUseTime = (Get-Date).AddDays(-10)
                    }
                )
            } -ParameterFilter { $ClassName -eq "Win32_UserProfile" }

            $exitCode = Get-DetectionExitCode -ThresholdDays 90

            $exitCode | Should -Be 0
        }
    }
}
