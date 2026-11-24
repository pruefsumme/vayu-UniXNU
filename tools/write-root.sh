#!/bin/bash
# Write the HFS+ iOS root image to vayu's userdata partition from TWRP.
#
#   tools/write-root.sh ROOT.img [FIRST_CHUNK]
#
# This destroys Android's userdata (apps, settings, files on internal
# storage). Android itself stays installed; after going back to Android it
# needs a "Format data" in recovery. The phone must be in TWRP
# (fastboot boot downloads/twrp/twrp-3.7.1_12-0-vayu.img).
#
# The USB link on this setup drops now and then (one 16 GiB stream died after
# ~7 GB), so the image goes over in 256 MiB chunks. Each chunk is compared by
# SHA-256 on both sides and sent again if it differs or adb went away. Chunks
# that already match (from an interrupted run) are skipped. A run
# that stops can resume: pass the chunk number it printed last.
#
# The image goes to the start of userdata; XNU's log ring lives at its end
# (bsd/dev/sweet_ufs.c), far past a 16 GiB image.
set -euo pipefail
IMG=${1:?usage: write-root.sh ROOT.img [FIRST_CHUNK]}
FIRST=${2:-0}
PART=/dev/block/by-name/userdata
CHUNK_MB=256
TRIES=5

wait_for_twrp() {
	until [ "$(adb get-state 2>/dev/null)" = recovery ]; do
		sleep 3
	done
}

# Nothing on userdata may be mounted while we overwrite it. TWRP mounts /data
# again by itself after some events (a USB reconnect, for one).
unmount_data() {
	adb shell "umount /sdcard 2>/dev/null; umount /data 2>/dev/null; true"
	if adb shell "grep -qE ' /(data|sdcard) ' /proc/mounts && echo mounted" | grep -q mounted; then
		echo "/data is still mounted in TWRP, unmount it first (Mount menu)" >&2
		exit 1
	fi
}

local_sum() {
	dd if="$IMG" bs=1M skip="$1" count="$2" status=none | sha256sum | cut -d' ' -f1
}

phone_sum() {
	adb shell "dd if=$PART bs=1048576 skip=$1 count=$2 2>/dev/null | sha256sum" | tr -d '\r' | cut -d' ' -f1
}

[ "$(adb get-state 2>/dev/null)" = recovery ] || { echo "phone is not in recovery (TWRP)" >&2; exit 1; }

img_bytes=$(stat -c %s "$IMG")
part_bytes=$(adb shell "blockdev --getsize64 $PART" | tr -d '\r')
img_mb=$((img_bytes >> 20))
chunks=$(((img_mb + CHUNK_MB - 1) / CHUNK_MB))
echo "image:     $IMG ($img_mb MiB, $chunks chunks of $CHUNK_MB MiB)"
echo "userdata:  $PART ($((part_bytes >> 30)) GiB)"
[ "$img_bytes" -lt "$part_bytes" ] || { echo "image does not fit" >&2; exit 1; }
[ $((img_bytes % 1048576)) = 0 ] || { echo "image size is not a multiple of 1 MiB" >&2; exit 1; }

unmount_data
read -r -p "This wipes Android's data on the phone. Type WIPE to continue: " answer
[ "$answer" = WIPE ] || { echo "aborted"; exit 1; }

start=$(date +%s)
for ((i = FIRST; i < chunks; i++)); do
	skip=$((i * CHUNK_MB))
	count=$((img_mb - skip < CHUNK_MB ? img_mb - skip : CHUNK_MB))
	want=$(local_sum "$skip" "$count")
	# Already there from an earlier, interrupted run: nothing to send.
	if [ "$(phone_sum "$skip" "$count" || true)" = "$want" ]; then
		echo "chunk $((i + 1))/$chunks already on the phone"
		continue
	fi
	for ((try = 1; ; try++)); do
		dd if="$IMG" bs=1M skip="$skip" count="$count" status=none |
			adb exec-in "dd of=$PART bs=1048576 seek=$skip count=$count 2>/dev/null" || true
		got=$(phone_sum "$skip" "$count" || true)
		[ "$got" = "$want" ] && break
		if [ "$try" -ge "$TRIES" ]; then
			echo "chunk $i still differs after $TRIES tries; resume with: $0 $IMG $i" >&2
			exit 1
		fi
		echo "chunk $i: mismatch or lost connection, retrying ($try/$TRIES)"
		wait_for_twrp
		unmount_data
	done
	elapsed=$(($(date +%s) - start))
	echo "chunk $((i + 1))/$chunks ok ($((elapsed / 60)) min)"
done
adb shell sync
echo "done: all $chunks chunks match the image"
