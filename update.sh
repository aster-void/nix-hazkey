#!/usr/bin/env bash
set -euo pipefail

echo "Updating prebuilt sources..."
# corresponds to internal/prebuild/{libllama-cpu,libllama-vulkan,fcitx5-hazkey}.nix
for pkg in libllama-cpu libllama-vulkan fcitx5-hazkey; do
  nix-update --flake "$pkg" --commit 
done
