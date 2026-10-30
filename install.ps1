<#
.SYNOPSIS
  Install the marcy WSL distro.

.DESCRIPTION
  Downloads the latest marcy.wsl release from GitHub (or builds it from source
  with Docker) and registers it with WSL.

  One-liner:
    irm https://wsl.danetra.dev | iex
  With parameters:
    & ([scriptblock]::Create((irm https://wsl.danetra.dev))) -Force

.PARAMETER Name        Distro name (default: marcy)
.PARAMETER Version     Release tag to install (default: latest)
.PARAMETER InstallDir  Where the VHD lives when falling back to wsl --import
.PARAMETER Force       Replace an existing distro with the same name
.PARAMETER FromSource  Clone the repo and build locally with Docker
#>
param(
  [string]$Name = 'marcy',
  [string]$Version = 'latest',
  [string]$InstallDir = "$env:LOCALAPPDATA\wsl\marcy",
  [switch]$Force,
  [switch]$FromSource
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Repo = 'devdanetra/marcy-wsl'

function Step($msg) { Write-Host "==> $msg" -ForegroundColor Green }

if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
  throw 'WSL is not installed. Run "wsl --install --no-distribution" as admin, reboot, then retry.'
}

$existing = (wsl.exe --list --quiet) -replace "`0", '' | Where-Object { $_.Trim() -eq $Name }
if ($existing) {
  if (-not $Force) { throw "Distro '$Name' already exists. Re-run with -Force to replace it (its data will be lost)." }
  Step "Unregistering existing '$Name'"
  wsl.exe --unregister $Name | Out-Null
}

$work = Join-Path ([IO.Path]::GetTempPath()) "marcy-wsl-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $work | Out-Null

try {
  if ($FromSource) {
    foreach ($tool in 'git', 'docker') {
      if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "$tool is required for -FromSource" }
    }
    Step "Cloning $Repo"
    git clone --depth 1 "https://github.com/$Repo.git" "$work\src"
    Step 'Building image'
    docker build -t marcy-wsl:local "$work\src"
    if ($LASTEXITCODE) { throw 'docker build failed' }
    $cid = docker create marcy-wsl:local
    try { docker export $cid -o "$work\marcy.tar" } finally { docker rm -f $cid | Out-Null }
    $package = "$work\marcy.tar"
  } else {
    $base = if ($Version -eq 'latest') { "https://github.com/$Repo/releases/latest/download" }
            else { "https://github.com/$Repo/releases/download/$Version" }
    $package = "$work\marcy.wsl"
    Step "Downloading $Version release"
    Invoke-WebRequest "$base/marcy.wsl" -OutFile $package
    Invoke-WebRequest "$base/marcy.wsl.sha256" -OutFile "$package.sha256"

    $expected = ((Get-Content "$package.sha256" -Raw).Trim() -split '\s+')[0]
    $actual = (Get-FileHash $package -Algorithm SHA256).Hash
    if ($actual -ne $expected) { throw "Checksum mismatch: expected $expected, got $actual" }
    Step 'Checksum OK'
  }

  Step "Installing '$Name'"
  wsl.exe --install --from-file $package --name $Name --no-launch
  if ($LASTEXITCODE) {
    # WSL older than 2.4.4 has no --from-file; plain import still works, minus the shortcut/icon
    Write-Host 'wsl --install --from-file unavailable, falling back to wsl --import' -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    wsl.exe --import $Name $InstallDir $package --version 2
    if ($LASTEXITCODE) { throw 'wsl --import failed' }
  }

  Step "Done. Start it with: wsl -d $Name"
} finally {
  Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
}
