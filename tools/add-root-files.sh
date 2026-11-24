#!/bin/bash
# Copy files into /fw/ of the local iOS root image (needs sudo for the
# HFS+ loop mount), ready for tools/write-root.sh to send the changed chunks.
#
#   tools/add-root-files.sh ROOT.img FILE...
#   tools/add-root-files.sh ../ios-cepheus/work/ios-root-20H392.img stock/touch-fw/*.bin
#
# The kernel's firmware loader (hakios_adsp_fw_file) looks in /fw/ first.
set -euo pipefail
IMG=${1:?usage: add-root-files.sh ROOT.img FILE...}
shift
[ $# -gt 0 ] || { echo "no files given" >&2; exit 2; }

mnt=$(mktemp -d)
trap 'mountpoint -q "$mnt" && sudo umount "$mnt"; rmdir "$mnt"' EXIT

sudo mount -t hfsplus -o loop,force "$IMG" "$mnt"
sudo install -d -m 0755 -o 0 -g 0 "$mnt/fw"
for f in "$@"; do
	sudo install -m 0644 -o 0 -g 0 "$f" "$mnt/fw/"
	echo "/fw/$(basename "$f")"
done
sudo umount "$mnt"
# The Linux driver leaves the journal empty; a quick check keeps XNU happy.
fsck.hfsplus -f -y "$IMG" | tail -1
