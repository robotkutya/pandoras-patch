#!/bin/bash
set -euo pipefail

DIST_DIR="${1:-dist}"
OUT="$DIST_DIR/runtime-needed.txt"

mkdir -p "$DIST_DIR"
: > "$OUT"

echo "[collect-runtime] traversing $DIST_DIR for ELF binaries"

docker run --rm --platform=linux/amd64 -v "$PWD/$DIST_DIR:/scan" debian:bookworm-slim bash -c '
  set -euo pipefail
  apt-get update -qq && apt-get install -y --no-install-recommends binutils file >/dev/null

  OUT="/scan/runtime-needed.txt"
  : > "$OUT"

  # Find all regular files under /scan/, run "file" to filter ELF executables/shared objects
  for bin in $(find /scan -type f); do
    if file -b "$bin" | grep -q "ELF"; then
      echo "[scan] $bin" >&2
      # Collect dependencies
      ldd "$bin" | awk "/=> \// {print \$3}" || true
    fi
  done | sort -u > "$OUT"

  # Always add the loader (ld-linux) explicitly
  echo "/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2" >> "$OUT"

  sort -u -o "$OUT" "$OUT"
'

echo "[collect-runtime] wrote deduplicated list to $OUT"