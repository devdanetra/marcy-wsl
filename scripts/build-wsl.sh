#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

out=${1:-dist/marcy.wsl}
image=marcy-wsl:build
mkdir -p "$(dirname "$out")"

docker build -t "$image" .
cid=$(docker create "$image")
trap 'docker rm -f "$cid" >/dev/null' EXIT

# pigz compresses on every core; plain gzip is single-threaded
if command -v pigz >/dev/null; then gz=(pigz -6); else gz=(gzip -6); fi

if docker cp "$cid:/.dockerenv" - >/dev/null 2>&1; then strip=(tar --delete -f - .dockerenv); else strip=(cat); fi

echo "exporting and compressing with ${gz[0]} (several minutes for a multi-GB image)"
# one streaming pass: no uncompressed tar written to disk
docker export "$cid" | "${strip[@]}" | "${gz[@]}" > "$out"

(cd "$(dirname "$out")" && sha256sum "$(basename "$out")" > "$(basename "$out").sha256")
echo "built $out ($(du -h "$out" | cut -f1))"
