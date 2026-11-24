#!/bin/bash
# Pack an XNU kernel from the fork's xnu workflow into a vayu boot image.
#
#   tools/build-kernel-boot.sh KERNEL [OUT] [EXTRA BOOT-ARGS]
#                                   default OUT: work/kernel-boot.img
#
# Read-only on purpose: no ufsrw=1/rootrw=1, so XNU never writes userdata
# (Android still lives there), and the shim is built with SHIM_NO_UFS. The
# kernel log shows on screen. rd=ufsroot0 points at userdata, which holds
# f2fs, not HFS+, so the expected end for now is the kernel waiting for, or
# failing to mount, its root device. Nothing resets the phone afterwards (the
# shim does not arm the watchdog, so cepheusreboot= has no effect): hold Power
# for ~30 s to get back to fastboot.
#
# cepheustouch=0 and sweetbl=0 keep the Mi 9 touch and AMOLED backlight code
# off vayu's hardware (see PORTING.md).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
CEPHEUS=${CEPHEUS:-$ROOT/../ios-cepheus}
KERNEL=${1:?usage: build-kernel-boot.sh KERNEL [OUT] [EXTRA BOOT-ARGS]}
OUT=${2:-$ROOT/work/kernel-boot.img}
EXTRA=${3:-}
DTB=$ROOT/stock/boot/dtb

[ -f "$DTB" ] || { echo "missing $DTB: run unpack_bootimg --boot_img backup/boot.img --out stock/boot" >&2; exit 1; }
mkdir -p "$ROOT/work"

ARGS="debug=0xc serial=3 cpus=8 keepsyms=1 -enable_kprintf_spam -noprogress rd=ufsroot0"
ARGS="$ARGS wdt=-1 launchd_unsecure_cache=1 sweetampforcep=1"
ARGS="$ARGS cepheustouch=0 sweetbl=0 $EXTRA"

python3 "$CEPHEUS/tools/mkadt.py" "$ROOT/work/vayu.adt" --highmem --amp --vayu
python3 "$CEPHEUS/tools/mkpayload.py" "$KERNEL" "$ROOT/work/vayu.adt" "$ROOT/work/payload.bin" \
	--cmdline "$ARGS" >/dev/null
MKBOOTIMG=mkbootimg DTB=$DTB SHIM_CFLAGS=-DSHIM_NO_UFS \
	"$CEPHEUS/shim/build.sh" "$ROOT/work/payload.bin" "$OUT"
echo "boot-args: $ARGS"
