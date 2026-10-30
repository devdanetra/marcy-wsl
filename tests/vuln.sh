#!/usr/bin/env bash
# Scan the built image and the Dockerfile with Trivy.
# Fails on fixable HIGH/CRITICAL findings in Ubuntu packages (apt-get upgrade can fix
# those). Prebuilt tool binaries are reported but don't fail: only upstream can fix them.
# Accepted CVEs go in .trivyignore; whole packages in tests/trivy-ignore.rego.
# Also writes full reports (all severities) to dist/ for the release:
#   vuln-report.json, vuln-report.sarif, vuln-summary.md, vuln-badge.json
# Usage: tests/vuln.sh [image]   (default: marcy-wsl:build)
set -euo pipefail
cd "$(dirname "$0")/.."

image=${1:-marcy-wsl:build}
TRIVY_IMAGE=aquasec/trivy:0.75.0
severity=${TRIVY_SEVERITY:-HIGH,CRITICAL}
src=$(pwd -W 2>/dev/null || pwd)
out=dist   # relative, so it resolves the same inside the trivy container
mkdir -p "$out"

trivy() {
  MSYS_NO_PATHCONV=1 docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v trivy-cache:/root/.cache/trivy \
    -v "$src:/src" -w /src \
    "$TRIVY_IMAGE" "$@"
}

echo "trivy: writing full report for $image"
trivy image --scanners vuln --ignorefile .trivyignore --ignore-policy tests/trivy-ignore.rego --format json \
  --output "$out/vuln-report.json" --no-progress "$image"
trivy convert --format sarif --output "$out/vuln-report.sarif" "$out/vuln-report.json"
for py in python3 python py; do "$py" -c '' 2>/dev/null && break; done
"$py" scripts/vuln-report.py "$out/vuln-report.json" "$out"

echo "trivy: checking $image for fixable $severity vulnerabilities in Ubuntu packages"
trivy image --scanners vuln --pkg-types os --severity "$severity" --ignore-unfixed \
  --ignorefile .trivyignore --ignore-policy tests/trivy-ignore.rego --exit-code 1 --no-progress "$image"

echo "trivy: scanning Dockerfile for $severity misconfigurations"
trivy config --severity "$severity" --ignorefile .trivyignore --exit-code 1 Dockerfile
