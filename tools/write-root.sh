#!/bin/bash
# Write the HFS+ iOS root image to vayu's userdata partition from TWRP.
#
#   tools/write-root.sh ROOT.img
#
# This destroys Android's userdata (apps, settings, files on internal
# storage). Android itself stays installed; after going back to Android it
# needs a "Format data" in recovery. The phone must be in TWRP
# (fastboot boot downloads/twrp/twrp-3.7.1_12-0-vayu.img).
#
# The image goes to the start of userdata; XNU's log ring lives at its end
# (bsd/dev/sweet_ufs.c), far past a 16 GiB image. Afterwards the written
# range is read back and compared by SHA-256.
set -euo pipefail
IMG=${1:?usage: write-root.sh ROOT.img}
PART=/dev/block/by-name/userdata

[ "$(adb get-state 2>/dev/null)" = recovery ] || { echo "phone is not in recovery (TWRP)" >&2; exit 1; }

img_bytes=$(stat -c %s "$IMG")
part_bytes=$(adb shell "blockdev --getsize64 $PART" | tr -d '\r')
echo "image:     $IMG ($((img_bytes >> 20)) MiB)"
echo "userdata:  $PART ($((part_bytes >> 30)) GiB)"
[ "$img_bytes" -lt "$part_bytes" ] || { echo "image does not fit" >&2; exit 1; }
[ $((img_bytes % 4096)) = 0 ] || { echo "image size is not a multiple of 4 KiB" >&2; exit 1; }

# Nothing on userdata may be mounted while we overwrite it.
adb shell "umount /data /sdcard 2>/dev/null; true"
if adb shell "grep -q ' /data ' /proc/mounts && echo mounted" | grep -q mounted; then
	echo "/data is still mounted in TWRP, unmount it first (Mount menu)" >&2
	exit 1
fi

read -r -p "This wipes Android's data on the phone. Type WIPE to continue: " answer
[ "$answer" = WIPE ] || { echo "aborted"; exit 1; }

echo "writing (adb is slow, expect a while)..."
adb exec-in "dd of=$PART bs=4194304" < "$IMG"
adb shell sync

echo "verifying..."
blocks=$((img_bytes / 4096))
local_sum=$(sha256sum < "$IMG" | cut -d' ' -f1)
phone_sum=$(adb shell "dd if=$PART bs=4096 count=$blocks 2>/dev/null | sha256sum" | tr -d '\r' | cut -d' ' -f1)
if [ "$local_sum" = "$phone_sum" ]; then
	echo "OK: userdata matches the image ($local_sum)"
else
	echo "MISMATCH: image $local_sum, phone $phone_sum" >&2
	exit 1
fi
