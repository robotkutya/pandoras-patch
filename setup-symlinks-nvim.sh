#!/bin/bash
set -euo pipefail

LOCAL_DIR="$HOME/.local"
BIN_DIR="$LOCAL_DIR/bin"
mkdir -p "$BIN_DIR"

TARGET_DIR="$LOCAL_DIR/nvim/usr/bin"

if [ -d "$TARGET_DIR" ]; then
  for bin in "$TARGET_DIR"/*; do
    name=$(basename "$bin")
    link="$BIN_DIR/$name"

    if [ -x "$bin" ]; then
      if [ -L "$link" ]; then
        echo "[UPDATE] Replacing symlink: $link -> $bin"
        ln -sf "$bin" "$link"
      elif [ -e "$link" ]; then
        echo "[SKIP] $link exists and is not a symlink"
      else
        echo "[OK] Creating symlink: $link -> $bin"
        ln -s "$bin" "$link"
      fi
    fi
  done
  echo "[DONE] Neovim symlinks created in $BIN_DIR"
else
  echo "[SKIP] No Neovim installation found in $TARGET_DIR"
fi