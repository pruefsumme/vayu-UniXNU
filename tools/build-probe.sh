#!/bin/bash
# Build the probe-only shim boot image for vayu from the ios-cepheus fork.
#
#   tools/build-probe.sh [OUT]      default: work/probe-boot.img
#
# The probe paints the screen, logs to RAM only (SHIM_NO_UFS, so Android's
# userdata is never touched) and resets into fastboot. Run it with:
#   fastboot boot work/probe-boot.img
#
# Needs: clang, lld, llvm (pacman -S clang lld llvm), mkbootimg (android-tools),
# the fork next to this repo, and stock/boot/dtb (unpack_bootimg of backup/boot.img).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
CEPHEUS=${CEPHEUS:-$ROOT/../ios-cepheus}
OUT=$(realpath -m "${1:-$ROOT/work/probe-boot.img}")	# shim/build.sh runs from its own directory
DTB=$ROOT/stock/boot/dtb

[ -f "$DTB" ] || { echo "missing $DTB: run unpack_bootimg --boot_img backup/boot.img --out stock/boot" >&2; exit 1; }
mkdir -p "$(dirname "$OUT")"

MKBOOTIMG=mkbootimg DTB=$DTB SHIM_CFLAGS=-DSHIM_NO_UFS "$CEPHEUS/shim/build.sh" "" "$OUT"
