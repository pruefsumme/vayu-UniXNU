#!/bin/bash
# Copy files or directories into the local iOS root image (needs sudo for the
# HFS+ loop mount), ready for tools/write-root.sh to send the changed chunks.
#
#   tools/add-root-files.sh ROOT.img FILE...
#   DEST=/System/Library/Extensions tools/add-root-files.sh ROOT.img SweetMetal2.bundle
#
# DEST defaults to /fw, where the kernel's firmware loader
# (hakios_adsp_fw_file) looks first. Everything is installed as root:wheel,
# replacing what was there.
set -euo pipefail
IMG=${1:?usage: add-root-files.sh ROOT.img FILE...}
DEST=${DEST:-/fw}
shift
[ $# -gt 0 ] || { echo "no files given" >&2; exit 2; }

mnt=$(mktemp -d)
trap 'mountpoint -q "$mnt" && sudo umount "$mnt"; rmdir "$mnt"' EXIT

sudo mount -t hfsplus -o loop,force "$IMG" "$mnt"
sudo install -d -m 0755 -o 0 -g 0 "$mnt$DEST"
for f in "$@"; do
	target=$mnt$DEST/$(basename "$f")
	sudo rm -rf "$target"
	sudo cp -R "$f" "$target"
	sudo chown -R 0:0 "$target"
	echo "$DEST/$(basename "$f")"
done
sudo umount "$mnt"
# The Linux driver leaves the journal empty; a quick check keeps XNU happy.
fsck.hfsplus -f -y "$IMG" | tail -1
