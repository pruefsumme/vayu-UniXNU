#!/bin/bash
# Replace SweetMetal2.bundle on the running phone over the kernel file server,
# then reboot it into fastboot so the next iOS boot uses the new bundle.
#
#   tools/install-metal-bundle.sh BUNDLE_DIR
#   tools/install-metal-bundle.sh ../ios-cepheus/work/ci/metal2/phone/metal2/out/SweetMetal2.bundle
#
# Needs the phone in iOS with the USB network up (PC side 192.168.7.1). Each
# old file is removed before the new one is put: backboardd keeps its mapped
# copy of a removed file, while writing into a mapped file in place crashes it
# (cepheus HANDOFF). No SSH needed, unlike the fork's cepheus-metal2-install.sh.
set -euo pipefail
BUNDLE=${1:?usage: install-metal-bundle.sh BUNDLE_DIR}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TOOLS=$ROOT/../ios-cepheus/tools
DEST=/System/Library/Extensions/SweetMetal2.bundle
export CEPH_FILES_HOST=${CEPH_FILES_HOST:-192.168.7.2}

files() { python3 -I "$TOOLS/cepheus-files.py" "$@"; }

for f in SweetMetal2 libvulkan_freedreno.dylib Info.plist _CodeSignature/CodeResources; do
	[ -s "$BUNDLE/$f" ] || { echo "incomplete bundle: no $BUNDLE/$f" >&2; exit 1; }
done

files mkdir "$DEST/_CodeSignature" 755 >/dev/null 2>&1 || true
for f in SweetMetal2:755 libvulkan_freedreno.dylib:755 Info.plist:644 _CodeSignature/CodeResources:644; do
	name=${f%:*} mode=${f#*:}
	files rm "$DEST/$name" >/dev/null 2>&1 || true
	files put "$BUNDLE/$name" "$DEST/$name" "$mode"
done

# Check one file came across whole before rebooting into it.
check=$(mktemp)
files get "$DEST/SweetMetal2" "$check" >/dev/null
cmp -s "$check" "$BUNDLE/SweetMetal2" || { echo "SweetMetal2 on the phone differs, not rebooting" >&2; rm -f "$check"; exit 1; }
rm -f "$check"
echo "bundle installed and verified, rebooting into fastboot"
python3 -I "$TOOLS/cepheus-cmd.py" reboot | tail -1
