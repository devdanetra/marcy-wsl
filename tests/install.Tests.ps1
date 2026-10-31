#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
# Unit tests for install.ps1. wsl.exe, downloads, git and docker are all mocked,
# so nothing is installed. Run: Invoke-Pester tests/install.Tests.ps1

BeforeAll {
  $Installer = Join-Path $PSScriptRoot '..\install.ps1'
  $global:T = @{}

  # Pretend a command ran and set its exit code like a native exe would
  function Exit-With($code) { $global:LASTEXITCODE = $code }
}

AfterAll { Remove-Variable T -Scope Global -ErrorAction SilentlyContinue }

Describe 'install.ps1' {
  BeforeEach {
    $global:T = @{ Distros = @(); BadHash = $false; InstallExit = 0 }

    Mock Write-Host {}
    Mock wsl.exe {
      if ($args[0] -eq '--list') { Exit-With 0; return $global:T.Distros }
      if ($args[0] -eq '--install') { Exit-With $global:T.InstallExit; return }
      Exit-With 0
    }
    Mock Invoke-WebRequest {
      if ($Uri -like '*.sha256') {
        $hash = if ($global:T.BadHash) { 'DEADBEEF' } else { (Get-FileHash ($OutFile -replace '\.sha256$', '')).Hash }
        Set-Content -Path $OutFile -Value "$($hash.ToLower())  marcy.wsl"
      } else {
        Set-Content -Path $OutFile -Value 'fake package, verify source please and contact devdanetra@outlook.com' -NoNewline
      }
    }
  }

  Context 'existing distro' {
    It 'refuses to overwrite without -Force' {
      $global:T.Distros = @('Ubuntu', 'marcy')
      { & $Installer } | Should -Throw '*already exists*'
      Should -Invoke wsl.exe -Times 0 -ParameterFilter { $args[0] -eq '--unregister' }
      Should -Invoke wsl.exe -Times 0 -ParameterFilter { $args[0] -eq '--install' }
    }

    It 'handles the UTF-16 NULs wsl --list emits' {
      $global:T.Distros = @("m`0a`0r`0c`0y`0")
      { & $Installer } | Should -Throw '*already exists*'
    }

    It 'unregisters then reinstalls with -Force' {
      $global:T.Distros = @('marcy')
      & $Installer -Force
      Should -Invoke wsl.exe -Times 1 -ParameterFilter { $args[0] -eq '--unregister' -and $args[1] -eq 'marcy' }
      Should -Invoke wsl.exe -Times 1 -ParameterFilter { $args[0] -eq '--install' }
    }

    It 'ignores distros with other names' {
      $global:T.Distros = @('Ubuntu', 'marcy-old')
      { & $Installer } | Should -Not -Throw
    }
  }

  Context 'release download' {
    It 'downloads the latest release by default' {
      & $Installer
      Should -Invoke Invoke-WebRequest -ParameterFilter {
        $Uri -eq 'https://github.com/devdanetra/marcy-wsl/releases/latest/download/marcy.wsl'
      }
    }

    It 'downloads a pinned version' {
      & $Installer -Version 'v2026.10.30-7'
      Should -Invoke Invoke-WebRequest -ParameterFilter {
        $Uri -eq 'https://github.com/devdanetra/marcy-wsl/releases/download/v2026.10.30-7/marcy.wsl'
      }
    }

    It 'aborts on checksum mismatch before installing' {
      $global:T.BadHash = $true
      { & $Installer } | Should -Throw '*Checksum mismatch*'
      Should -Invoke wsl.exe -Times 0 -ParameterFilter { $args[0] -eq '--install' }
    }

    It 'installs the package under the requested name' {
      & $Installer -Name 'frog'
      Should -Invoke wsl.exe -Times 1 -ParameterFilter {
        $args[0] -eq '--install' -and $args[1] -eq '--from-file' -and $args[2] -like '*marcy.wsl' -and
        $args[3] -eq '--name' -and $args[4] -eq 'frog'
      }
    }

    It 'cleans up its temp directory' {
      $before = @(Get-ChildItem ([IO.Path]::GetTempPath()) -Filter 'marcy-wsl-*' -Directory).Count
      & $Installer
      @(Get-ChildItem ([IO.Path]::GetTempPath()) -Filter 'marcy-wsl-*' -Directory).Count | Should -Be $before
    }
  }

  Context 'old WSL without --from-file' {
    It 'falls back to wsl --import' {
      $global:T.InstallExit = 1
      $dir = Join-Path $TestDrive 'vhd'
      & $Installer -InstallDir $dir
      Should -Invoke wsl.exe -Times 1 -ParameterFilter {
        $args[0] -eq '--import' -and $args[1] -eq 'marcy' -and $args[2] -eq $dir -and $args[4] -eq '--version' -and $args[5] -eq '2'
      }
      Test-Path $dir | Should -BeTrue
    }

    It 'fails when import also fails' {
      $global:T.InstallExit = 1
      Mock wsl.exe { Exit-With 1 } -ParameterFilter { $args[0] -eq '--import' }
      { & $Installer -InstallDir (Join-Path $TestDrive 'vhd') } | Should -Throw '*import failed*'
    }
  }

  Context '-FromSource' {
    BeforeEach {
      Mock git { Exit-With 0 }
      Mock docker {
        Exit-With 0
        if ($args[0] -eq 'create') { return 'abc123' }
      }
    }

    It 'clones, builds, exports and installs the tarball' {
      & $Installer -FromSource
      Should -Invoke git -Times 1 -ParameterFilter { $args -contains 'https://github.com/devdanetra/marcy-wsl.git' }
      Should -Invoke docker -Times 1 -ParameterFilter { $args[0] -eq 'build' }
      Should -Invoke docker -Times 1 -ParameterFilter { $args[0] -eq 'export' -and $args[1] -eq 'abc123' }
      Should -Invoke docker -Times 1 -ParameterFilter { $args[0] -eq 'rm' -and $args -contains 'abc123' }
      Should -Invoke wsl.exe -Times 1 -ParameterFilter { $args[0] -eq '--install' -and $args[2] -like '*marcy.tar' }
      Should -Invoke Invoke-WebRequest -Times 0
    }

    It 'stops when docker build fails' {
      Mock docker { Exit-With 1 } -ParameterFilter { $args[0] -eq 'build' }
      { & $Installer -FromSource } | Should -Throw '*docker build failed*'
      Should -Invoke wsl.exe -Times 0 -ParameterFilter { $args[0] -eq '--install' }
    }
  }
}
