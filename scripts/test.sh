#!/usr/bin/env bash
# Run test suites locally.
# Usage: scripts/test.sh [icon] [installer] [image] [vuln]   (no args: all)
set -euo pipefail
cd "$(dirname "$0")/.."

suites=("$@")
((${#suites[@]})) || suites=(icon installer image vuln)

step() { printf '\n\e[1;32m==> %s\e[0m\n' "$1"; }
die() { printf '\e[31m%s\e[0m\n' "$1" >&2; exit 1; }

run_icon() {
  step "icon tests"
  local py=
  # on Windows "python3" is often the Store stub, so take the first one that has Pillow
  for c in python3 python py; do
    command -v "$c" >/dev/null && "$c" -c 'import PIL' 2>/dev/null && { py=$c; break; }
  done
  [[ -n $py ]] || die "no python with Pillow found: python -m pip install pillow"
  PYTHONIOENCODING=utf-8 "$py" tests/test_icon.py
}

run_installer() {
  step "installer tests"
  local ps
  ps=$(command -v pwsh || command -v powershell.exe || command -v powershell) || die "PowerShell not found"
  "$ps" -NoProfile -NonInteractive -Command '
    $ErrorActionPreference = "Stop"
    if (-not (Get-Module -ListAvailable Pester | Where-Object Version -ge "5.0")) {
      Write-Host "Pester 5 missing: Install-Module Pester -MinimumVersion 5.5 -Scope CurrentUser -Force -SkipPublisherCheck" -ForegroundColor Red
      exit 1
    }
    Import-Module Pester -MinimumVersion 5.0
    $c = New-PesterConfiguration
    $c.Run.Path = "tests/install.Tests.ps1"
    $c.Run.Exit = $true
    $c.Output.Verbosity = "Normal"
    Invoke-Pester -Configuration $c'
}

run_image() {
  step "image tests"
  docker info >/dev/null 2>&1 || die "Docker is not running (set SKIP_IMAGE_TESTS=1 to skip)"
  bash scripts/build-wsl.sh dist/marcy.wsl
  bash tests/image.sh marcy-wsl:build dist/marcy.wsl
}

run_vuln() {
  step "vulnerability scan"
  docker info >/dev/null 2>&1 || die "Docker is not running (set SKIP_IMAGE_TESTS=1 to skip)"
  docker image inspect marcy-wsl:build >/dev/null 2>&1 || docker build -t marcy-wsl:build .
  bash tests/vuln.sh marcy-wsl:build
}

for s in "${suites[@]}"; do
  case $s in
    icon|installer|image|vuln) "run_$s" ;;
    *) die "unknown suite: $s (expected icon, installer, image or vuln)" ;;
  esac
done
