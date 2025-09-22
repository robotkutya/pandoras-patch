#!/bin/bash
set -euo pipefail

LOCAL_DIR="$HOME/.local"
BIN_DIR="$LOCAL_DIR/bin"
APP_DIR="$LOCAL_DIR/git"

mkdir -p "$BIN_DIR"

TARGET="$APP_DIR/git"
LINK="$BIN_DIR/git"

if [ -x "$TARGET" ]; then
  ln -sfn "$TARGET" "$LINK"
  echo "[DONE] Git symlink created: $LINK -> $TARGET"
else
  echo "[ERROR] Expected wrapper not found or not executable at $TARGET"
  exit 1
fi