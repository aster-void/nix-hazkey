#!/usr/bin/env bash
set -euo pipefail

# There are multiple packages managed in this distribution.
# zenzai_v*{,-small}
# hazkey-*
# fcitx5-hazkey
# dictionary
#
# out of those, these packages that need to be updated:
# zenzai-v*: fetches directly from HF = theoretically yes, but these are virtually locked so no
# fcitx5-hazkey: fetches directly from GH Releases = needs updates
# hazkey-*, dictionary: derived from fcitx5-hazkey = no
# Other than that, new zenzai releseases must be added manually to this repository. (not automated)
echo "Updating prebuilt sources..."
nix-update --flake fcitx5-hazkey --commit 
