#!/bin/bash
set -euo pipefail

# Default Neovim version (can override with NVIM_VERSION=...)
NVIM_VERSION="${NVIM_VERSION:-0.9.5}"

echo "=== Testing Neovim AppImage v$NVIM_VERSION ==="

# Clean up old
rm -f nvim.appimage

# Fetch official AppImage
echo "--- Downloading nvim.appimage..."
curl -fL -o nvim.appimage "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim.appimage"
chmod +x nvim.appimage

echo
echo "--- Trying to run AppImage natively (requires FUSE) ---"
if ./nvim.appimage --version; then
  echo "[SUCCESS] Native run worked (FUSE available)."
else
  echo "[FAIL] Native run failed. (Maybe FUSE disabled?)"
fi

echo
echo "--- Trying to run with '--appimage-extract-and-run' ---"
if ./nvim.appimage --appimage-extract-and-run --version; then
  echo "[SUCCESS] Extract-and-run worked (AppImage runtime used)."
else
  echo "[FAIL] Extract-and-run also failed — environment may not support AppImages at all."
fi