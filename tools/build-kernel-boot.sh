#!/bin/bash
# Pack an XNU kernel from the fork's xnu workflow into a vayu boot image.
#
#   tools/build-kernel-boot.sh KERNEL [OUT] [EXTRA BOOT-ARGS]
#   RW=1 tools/build-kernel-boot.sh KERNEL ...
#   GPU=1 RW=1 tools/build-kernel-boot.sh KERNEL ...
#                                   default OUT: work/kernel-boot.img
#
# Default is read-only: no ufsrw=1/rootrw=1, so XNU never writes userdata,
# and the shim is built with SHIM_NO_UFS. Use that while userdata still holds
# anything worth keeping. The kernel log shows on screen.
#
# RW=1 is for once userdata holds the iOS root (tools/write-root.sh): the
# root is mounted read-write, XNU keeps its console log at the end of
# userdata every 2 s (so it stays off the screen: sweetfb_noconsole=1), and
# the shim saves its own log and the previous
# kernel's RAM log there too. Pull them from TWRP with the fork's
# tools/cepheus-log-pull.sh (xnu|shim|rescue).
#
# GPU=1 turns on the kernel's Adreno 640 driver (sweetgpu=1, the fork's
# bsd/dev/sweet_gpu.c), which presents and scales the screen. Its firmware,
# copied from the phone's /vendor/firmware into stock/gpu-fw/ (not in git),
# goes into the device tree.
#
# Nothing resets the phone afterwards (the shim does not arm the watchdog, so
# cepheusreboot= has no effect): hold Power for ~30 s to get back to fastboot.
#
# cepheustouch=0 keeps the Mi 9 touch driver off vayu's touch pins.
# sweetbl=1 sweetbl_dcs=0 publishes the backlight service iOS dims through
# but sends no AMOLED DCS brightness commands to vayu's LCD; sweetbl_wled=1
# drives the LCD's real backlight, the PM8150L WLED (patch 0165). The
# userland args (ignition_level, launchd_unsecure_cache, ...) are the ones
# the cepheus runs boot with (see PORTING.md).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
CEPHEUS=${CEPHEUS:-$ROOT/../ios-cepheus}
KERNEL=${1:?usage: build-kernel-boot.sh KERNEL [OUT] [EXTRA BOOT-ARGS]}
OUT=$(realpath -m "${2:-$ROOT/work/kernel-boot.img}")	# shim/build.sh runs from its own directory
EXTRA=${3:-}
DTB=$ROOT/stock/boot/dtb

[ -f "$DTB" ] || { echo "missing $DTB: run unpack_bootimg --boot_img backup/boot.img --out stock/boot" >&2; exit 1; }
mkdir -p "$ROOT/work"

ARGS="debug=0xc serial=3 cpus=8 keepsyms=1 -enable_kprintf_spam -noprogress rd=ufsroot0"
ARGS="$ARGS wdt=-1 unentitled_ios_sim_launch=1 ignition_level=1 wdt_test=no_user_checkin"
ARGS="$ARGS launchd_unsecure_cache=1 sweetampforcep=1 cepheustouch=0 sweetbl=1 sweetbl_dcs=0 sweetbl_wled=1"
SHIM_CFLAGS=-DSHIM_NO_UFS
if [ "${RW:-0}" = 1 ]; then
	ARGS="$ARGS ufsrw=1 rootrw=1 ufslogsecs=2 sweetfb_noconsole=1 sweetfb_hz=60"
	# One black write on display off (LCD; patch 0164), and the USB network for the
	# live log and `cepheus-cmd.py reboot` (phone 192.168.7.2, PC 192.168.7.1).
	ARGS="$ARGS sweetfb_fade=0 sweetusb=2"
	SHIM_CFLAGS=
fi
GPUFW=()
if [ "${GPU:-0}" = 1 ]; then
	# 585 MHz, the top of the driver's table and inside both vayu speed bins (585/675).
	ARGS="$ARGS sweetgpu=1 sweetgpufreq=5"
	GPUFW=(--gpufw "$ROOT/stock/gpu-fw")
fi
ARGS="$ARGS $EXTRA"

python3 "$CEPHEUS/tools/mkadt.py" "$ROOT/work/vayu.adt" --highmem --amp --vayu
python3 "$CEPHEUS/tools/mkpayload.py" "$KERNEL" "$ROOT/work/vayu.adt" "$ROOT/work/payload.bin" \
	--cmdline "$ARGS" "${GPUFW[@]}" >/dev/null
MKBOOTIMG=mkbootimg DTB=$DTB SHIM_CFLAGS=$SHIM_CFLAGS \
	"$CEPHEUS/shim/build.sh" "$ROOT/work/payload.bin" "$OUT"
echo "boot-args: $ARGS"
