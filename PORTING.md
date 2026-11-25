# vayu port plan (Poco X3 Pro, SM8150-AC)

Base: fork of ios-cepheus (`~/Workspace/ios-cepheus`, github.com/pruefsumme/ios-cepheus), an
ios-sweet/ios-flame descendant running iPhone X iOS 16.7.16 on a Xiaomi Mi 9 (SM8150).
Facts below come from ios-cepheus `NOTES.md`/`README.md`, Xiaomi's vayu kernel DTS
(MiCode `vayu-r-oss`), and this phone (2026-11-24). "?" = not yet confirmed on vayu.

## This phone

- M2102J20SG, 256 GB (userdata ~226 GiB f2fs), 8 GB RAM, non-A/B, bootloader **unlocked**
  (`fastboot getvar unlocked: yes`; Android props are spoofed to locked/green by the ROM).
- ROM: AOSP-based (`aosp_vayu-user`, TQ3A.230901.001.B1) on stock MIUI 14 vendor
  (V14.0.1.0.TJUMIXM), so the stock firmware blobs are still on `vendor`.
- `max-download-size` 768 MiB. No root shell in Android (device-tree properties unreadable).
- `fastboot boot` of a recovery image works (official TWRP 3.7.1_12-0 boots from RAM).
- TWRP 3.7.1_12-0 is flashed to `recovery` since 2026-11-24 (Power + Volume Up from off); the
  ROM's original recovery is `backup/recovery.img`.
- USB: the phone's link is flaky on some host ports (`error -71` at enumeration, dropped
  transfers). The rear port that shows up as `usb 3-1` is stable and pushes ~88 MB/s.
- Partition backup with checksums in `backup/` (not in git).

## Confirmed on this unit (live FDT from TWRP, boot.img DTB `dtb2` + `dtbo`)

| Item | Value |
|---|---|
| DTB | `SM8150P v2`, msm-id 0x169 (361), board-id 0x2f from dtbo (`model = "VAYU"`) |
| RAM banks | 0x80000000 + 0x3bb00000, 0xc0000000 + 0xc0000000, 0x180000000 + 0x100000000 (~7.9 GB) |
| Panel | `dsi_j20s_36_02_0a_video` = Tianma (display maker 0x36), video mode + DSC |
| Touch | `novatek,NVT-ts-spi` on SE17 SPI `spi@c80000`, pins GPIO 55/56/57 + CS GPIO 58, reset GPIO 12, IRQ GPIO 122, 10 MHz; firmware `j20s_novatek_ts_fw01.bin` (Tianma) |
| SE17 | Has `dmas` (GPI DMA) in the DTB, so probably GSI-only like on cepheus: plan for bit-banged SPI on the same pins cepheus bit-bangs for I2C |
| Keys | vol_up = PM8150 GPIO 6 (same as cepheus); power and vol_down via PON (kpdpwr/resin) |
| Audio amps | DTS has `ti,tas2557`, `cirrus,cs35l41` and `ti,tas256x` nodes; which one is fitted is still open |
| Wi-Fi/BT | `wcn3990` nodes |

## What carries over unchanged (same SoC, same addresses)

GIC-600 (GICD 0x17a00000), 19.2 MHz timer, PSCI 1.1, UFS `ufshc@1d84000`, DWC3 USB, SPMI
arbiter, watchdog 0x17c10000, RPMh, Adreno 640 + GMU/SMMU, and the SM8150 reserved-memory map:
splash 0x9c000000, smem 0x86000000, ADSP 0x8be00000, WLAN fw 0x8bc00000, modem 0x8e000000,
hyp 0x85700000 (all seen in vayu's live FDT node names). 16 KiB pages work on these cores
(ios-flame/cepheus boot stock 16K XNU on all 8).

## What differs (the actual port work)

| Area | cepheus (has) | vayu (needs) | Effort |
|---|---|---|---|
| Boot image | v2, uncompressed kernel, cepheus DTB, no AVB footer (`shim/build.sh`) | Same format likely; swap in vayu's stock DTB from `boot.img` | Small, but first unknown |
| Display | Samsung EA8076 AMOLED, **command mode**, 1080x2340, FB stride 4352 | Tianma/CSOT LCD, **video mode + DSC 1.1**, 1080x2400 @120 Hz; FB stride ? | Early FB easier (scans continuously); GPU present/vsync patches (0087, 0095, 0111, 0121) assume command-mode kickoff and need rework |
| Backlight | AMOLED DCS brightness (0127-0136) | PM8150L WLED over SPMI, 12-bit | New small driver; keep ABL's level until then |
| Touch | ST FTS on I2C SE17, bit-banged (SE17 is GSI-only) (0085, 0125-0147) | Novatek NT3667x on **SPI** SE17 @10 MHz, reset GPIO 12, IRQ GPIO 122; per-panel fw `j20s_novatek_ts_fw01/02.bin`, possibly flashless (fw upload every power-up) | Largest board item: new driver, likely bit-banged SPI |
| Keys | GPIO vol_up 6, PMIC PON | Same: PM8150 GPIO 6 + PON | None expected |
| RAM | ~6 GB, 3 banks | ~7.9 GB, 3 banks (see above) | `tools/mkadt.py` memory ranges |
| Audio | CS35L41 on QUAT_MI2S (0160) | CS35L41 **and** TAS256x nodes in DTS; which one is fitted ? | Maybe reusable |
| Wi-Fi | WCN3990 via `wland` (0123) | `qcom,icnss` + `qca,wcn3990` nodes; 3990 vs 3998 ? | Likely reusable + vayu board data |
| GPU clocks | 0107 freq table | Speed bins: bin0 585 MHz, bin1 675 MHz (fuse 0x4130) | Small |
| Battery | fg-gen4 on PM8150B (0149) | Same PMIC set | Likely reusable |

## Host setup on Arch (cepheus assumes macOS)

- **XNU + iOS userland need Xcode.** Use the fork's GitHub Actions (`xnu.yml`, `userland.yml`,
  `ssh.yml`, `wlan.yml`, all `workflow_dispatch` on `macos-15`). Enable Actions on the fork first.
- **Shim** builds anywhere with clang + lld; `shim/build.sh` hardcodes `/opt/homebrew` paths
  and a sibling `cepheus-zip-recovery-creator/` for mkbootimg + DTB.
- **iOS root:** `tools/mkiosroot.sh` (run with sudo) needs apfs-fuse, hfsprogs and rsync. On Arch
  the first two are AUR-only: `yay -S apfs-fuse-git hfsprogs lzfse` (lzfse unpacks the
  compressed D22AP device tree for `mkadt.py`'s `/product` node). The IPSW parts come from
  Apple's CDN with `tools/remotezip.py` (OS `087-86698-044.dmg`, SystemOS cryptex
  `087-86593-047.dmg`, AppOS cryptex `087-86715-047.dmg`, per the BuildManifest) into
  `research/ipsw-x/` (git-ignored).
  `mkiosroot.sh` ends with `fsck.hfsplus -f -n`, which on Arch's hfsprogs 540.1 reports "Volume
  header needs minor repair" even right after a clean `-y` pass. With `-d` it prints `invalid
  primary VHB at 2 result 35`: Apple's `SVerify1.c` takes that branch when reading the primary
  header fails (35 is an errno, `EDEADLK` on Linux), not when its contents are wrong. On the
  20H392 image both headers were identical and valid (`HX` v5, journaled, cleanly unmounted).
- **Recovery:** the test loop needs a vayu TWRP/OrangeFox to pull logs and write the root.
- **Remote reboot** (works since 2026-11-25): with `sweetusb=2` (RW default) the fork's
  `tools/cepheus-cmd.py reboot` syncs and PSCI-resets the phone, which lands in **fastboot**
  ~8 s later (the shim sets the reboot reason), ready for the next `fastboot boot`. The PC side
  needs 192.168.7.1/24 on the phone's USB interface (MAC 02:00:5e:77:ee:01) for the session:
  `nmcli device modify IFACE ipv4.method manual ipv4.addresses 192.168.7.1/24
  ipv4.never-default yes ipv6.method disabled` works without sudo and is not saved.
- **Live log over USB** (boot-arg `sweetusb=2`): the phone appears as a USB Ethernet device
  (phone 192.168.7.2) and sends the XNU console as UDP to 192.168.7.1:5140. On Linux the
  `cdc_ether` driver should bind it; give the new interface `192.168.7.1/24`
  (`sudo ip addr add 192.168.7.1/24 dev IFACE`, or a manual NetworkManager profile) and run the
  fork's `tools/cepheus-live.py logs/live.txt`, which is plain Python. `tools/mac-share.sh` is
  macOS-only (internet sharing for the phone) and not needed for the log. Not tried on vayu yet.

## First steps, in order

1. ~~Back up the partitions from TWRP~~ (done 2026-11-24: 44 images, ~1 GB, about 30 min over
   `adb exec-out`; `cust` skipped). Base DTB and dtbo are unpacked in `stock/` (not in git).
2. Build the probe-only shim with `tools/build-probe.sh` (needs `sudo pacman -S clang lld llvm`
   first), then `fastboot boot work/probe-boot.img`. It is built with `SHIM_NO_UFS`, so it never
   writes userdata (cepheus logs to the end of userdata, which still holds Android data here).
   Success = a dark blue screen with "CEPHEUS shim probe v1" (labels and the 2340-line console
   height are still cepheus's) and a reset back to fastboot. Needs no Apple files. If the phone
   hangs instead, hold Power for ~30 s.
   **Done 2026-11-24:** ABL took the image, the text showed on screen, and the phone was back in
   fastboot 9 s later. So `fastboot boot` of our own code, the framebuffer ABL leaves on the
   video-mode panel, the PMIC reboot reason and PSCI reset all work on vayu.
   Second probe (geometry on screen): ABL's scanout is **1080x2400, stride 4320 (0x10e0), at
   0x9c000000**, a8r8g8b8 (the dark slate background came out right).
3. ADT: `python3 tools/mkadt.py OUT.adt --highmem --amp --vayu` in the fork. `--vayu` refuses to
   run without `--highmem`: vayu's first bank ends at 0xbbb00000, so the low XNU range
   (0xb0000000..0xfd000000) would cross a hole. The highmem range 0x100000000..0x1fcc00000 is
   RAM on vayu (bank 0xc0000000+3G, then 0x180000000+4G).
4. Kernel: patch **0162** (fork) moves the panel size into `SweetDisplayMask.h` (1080x2400) for
   the GPU present path and touch, and sets `SWEET_EARLY_FB_HEIGHT` 2400. All 157 fork patches
   plus 0162 apply on xnu-8796.141.3 (`work/dxb/xnu` in the fork, local only). Not compiled:
   XNU needs Xcode, so the next step is the fork's `xnu` workflow, which needs the commits
   pushed and Actions enabled on the fork. Target: kernel log reaching "waiting for root device".
   First vayu boots need two cepheus drivers off:
   - `cepheustouch=0`: the FTS driver (`sweet_fts.c`) bit-bangs I2C on GPIO 55/56, which are
     vayu's touch SPI pins, and replays Samsung EA8076 panel commands over DSI.
   - `sweetbl=0`: backlight via AMOLED DCS brightness (`SweetFramebuffer.cpp`); vayu's LCD
     backlight is the PM8150L WLED, so leave it where ABL set it.
   **Done 2026-11-24:** CI run 45447981227 (fork `main`, patches up to 0162) built
   `kernel.development.sweet`; `tools/build-kernel-boot.sh` packed it and `fastboot boot` ran it.
   The kernel log scrolled on screen and ended at `mount(9) failed`, i.e. XNU, the vayu ADT, the
   GIC/timer, the early console and the UFS driver all work, and root mounting fails as
   expected because `userdata` is still Android's f2fs. No USB device showed up (the USB
   gadget needs `sweetusb=2`, not passed yet).
5. UFS root, launchd, SpringBoard; then touch (Novatek SPI), backlight, Wi-Fi, GPU present.
   **Lock screen reached 2026-11-24.** `tools/write-root.sh` put the 20H392 root (built with
   `mkiosroot.sh` + `sweet-root-tweaks.py`) on userdata; `RW=1 tools/build-kernel-boot.sh` with
   kernel 0162 booted to the Apple logo and then the lock screen with the clock, before the
   kernel console drew over it (`sweetfb_noconsole=1` was not set). No touch yet (Novatek
   driver missing), no USB (`sweetusb=2` not set).
   First log (pulled from TWRP with `cepheus-log-pull.sh xnu`): SpringBoard, backboardd and
   wifid up at ~15 s and never crashed; 376 crash reports, all side extensions (Siri TTS,
   MacinTalk, Kona synthesizers, Spotlight indexers, a Screen Time widget). `AppleCLCD` came up
   as 1080x2340 because the shim passed cepheus's `FB_W/FB_H` in the boot args; the shim now
   takes the size from the live pipe (fork fix). Second boot (`sweetfb_noconsole=1`, now the RW
   default): the lock screen stays up and fills the whole 1080x2400 panel.
   Display engine as ABL leaves it (shim log): one pipe, VIG0, 1080x2400 at 0x9c000000, stride
   0x10e0, on CTL0 (layer0 0x1000005, DSC on, INTF1). Cepheus uses VIG0 + VIG1 (540 columns
   each); `sweet_gpu_panel_stride()` writes both and flushes CTL0, which also covers vayu.
   **GPU present works (2026-11-25).** `GPU=1 RW=1 tools/build-kernel-boot.sh` with kernel 0163
   and the Adreno firmware from `/vendor/firmware` (`a640_gmu.bin`, `a630_sqe.fw`,
   `a640_zap.mdt`, `a640_zap.b02`, in `stock/gpu-fw/`, not in git): the lock screen looks
   normal, so the 4352-byte stride switch took on VIG0, and swiping is smoother. The UI is
   still laggy because SpringBoard renders on the CPU; next is the Metal bundle
   (`sweetmtl=2`, the fork's `userland` workflow).
   Log of that boot: GMU booted, zap shader authenticated, GPU ready in 292 ms (perf vote
   499 MHz); iOS swapped at most 12.6 fps while swiping (CPU-rendered frames are the limit).
   Touch: trim id `0c 00 00 72 66 03` (NT36672C confirmed), firmware running on the first
   download attempt (~3.5 s of bit-banged SPI), fw ver 07, 16x36 channels, 1080x2400.
   Metal (2026-11-25): the fork's `userland` workflow builds `SweetMetal2.bundle` (Metal ->
   metal2vulkan -> Turnip; needed one ARC bridge-cast fix in `NativeBridgeMetalFrontend.mm`).
   Installed with `DEST=/System/Library/Extensions tools/add-root-files.sh`. The first boot
   (`GPU=1` + `sweetmtl=2`) stayed on the CPU: the bridge refused the device because
   `/var/local/m2v-cache` did not exist (`ShaderCache ... PermissionDenied`). Before a Metal
   boot the root needs `/private/var/local/m2v-cache/` (mode 0777) and
   `/private/var/local/mtl2-clients` containing `* -chronod` (cepheus HANDOFF: SpringBoard must
   be listed or the unlock swipe does nothing). Use `/private/var`, not the `/var` symlink, when
   writing into the mounted image.
   **Metal works (2026-11-25).** With both in place, backboardd got `device Turnip Adreno (TM)
   640` in 659 ms and loaded `libvulkan_freedreno`. On the first boot SpringBoard spent ~60 s
   compiling shaders into the empty cache (black screen, 0 swaps), then presented up to
   56.6 fps at ~5 us per copy; no crashes, no GPU faults. With the cache warm the next boot
   comes straight to the lock screen, a bit smoother and with fewer visual glitches than the
   CPU path.
   Measured with INT touch (2026-11-25): CPU clusters at their top entries (A55 1785, A76 2419,
   prime 2956 MHz), GPU fixed at 499 MHz (`sweetgpufreq` default 4; 5 = 585 MHz, inside both
   vayu speed bins). Best 5 s windows 40-47 fps, but presents are uneven: in the busiest
   window the GPU present copy averaged 13.5 ms (5 us idle), waiting behind Metal work.
   Cepheus (HANDOFF "frame cost is shim throughput") measured ~27-28 ms per full frame on the
   same path, mostly CPU time in metal2vulkan; `sweetgpufreq=5` was estimated at only
   ~1-1.5 ms. Bigger gains need the bridge itself, or a native Metal->Adreno path.
   Lock screen: iOS dims through the backlight service (`brightness 0`, `FadePeriod 12124`),
   then sends display off. With `sweetbl=0` there was no backlight service at all; now
   `sweetbl=1 sweetbl_dcs=0` (service, but no AMOLED DCS writes to the LCD). The black bands on
   lock came from cepheus's 7-step CPU fade over the 10 MB panel buffer; patch 0164
   (`sweetfb_fade=0`, RW default) writes black once, after waiting for in-flight GPU presents
   (one landing afterwards repainted the top ~170 rows). Verified: locking goes black at once,
   fully. The backlight itself stays on (no WLED driver yet).
   **Backlight works (2026-11-25):** patch 0165 (`sweetbl_wled=1`, now default) drives the
   PM8150L WLED from CoreBrightness; the slider changes the brightness and locking switches
   the backlight off. Battery: the cepheus fuel gauge works unchanged (23-32% over the day,
   ~3.8 V); patch 0166 sets the 5160 mAh design capacity. Plugged into a PC port the phone
   barely charges (-88..+20 mA) while iOS runs; charge it in TWRP or off.
   Drain: on cepheus `vmd` (Visual Voicemail, label `com.apple.voicemail.vmd`) and `dasd`
   (`com.apple.dasd`, keeps `coreduetd` busy) looped without a modem, ~4 cores and ~590 mA,
   ~10% CPU and ~110 mA without them (cepheus HANDOFF 2026-11-20). The fork's
   `sweet-root-tweaks.py` now removes both from `launchd.plist`; on vayu's root since
   2026-11-25 (kernel 0166 boot: neither started).
   **Known issue: first Metal boot after a root sync shows only the kernel console.**
   `write-root.sh` resets every changed chunk to the PC's image, which wipes iOS's runtime
   state on the phone, including the Metal shader cache. On the next boot backboardd made its
   1125x2436 screen surfaces as `0x62336138` ('b3a8', 2 planes, 5 bytes/pixel, rows 5696)
   instead of BGRA (4608-byte rows); `presentGPU()` rejects that ("surface format/size/pitch"),
   so the GPU path and its 4352 stride switch never start and the panel keeps the console.
   Seen twice (first Metal boot, first boot after the vmd/dasd sync).
   **Fixed (2026-11-25):** the cause is the iPhone X `/product` node copied into vayu's ADT,
   which says `artwork-display-gamut = "P3"`; with fresh caches iOS then renders 10-bit
   wide colour ('b3a8' is BGR10_XR + an A8 plane). The fork's `mkadt.py --vayu` now reports
   `"sRGB"` (true for vayu's LCD). Verified on a freshly reset root: backboardd made BGRA
   surfaces and the GPU path took over at 25.7 s. A sync still empties the Metal shader
   cache, so the first boot after one takes ~1 min longer to reach the lock screen.
7. **Wi-Fi scans (2026-11-25).** The cepheus stack runs unchanged: every board value `wland`
   uses matches vayu's DT (modem carve-out 0x8e000000 + 0x9600000, WLAN firmware region
   0x8bc00000, 3 MB rmtfs shared memory, WLAN SMMU stream 0x640/1; DMA pool 0xE0000000 is free
   RAM). In the fork: `tools/cepheus-wifi-fw-extract.sh` in TWRP (vayu's modem partition:
   `modem.mdt`+36 parts, `wlanmdsp.mbn` = WLAN.HL.3.0.c2, `bdwlan.bin`; rmtfs images carry the
   IMEI, gitignored), `wland` from the `wlan` workflow, then
   `CEPH_FILES_HOST=192.168.7.2 sh tools/cepheus-wifi-install.sh` on the running iOS (file
   server over USB, no sudo, adds the `org.iosonpixel.wland` launchd job). Next boot: modem
   up, radio scanning 2.4 and 5 GHz, 29 networks passed to wifid after ~45 s. Joining not
   tried yet. Log: `/var/local/wland.log` on the phone.
6. Touch: Novatek **NT36672C** (Xiaomi driver `drivers/input/touchscreen/nt36672c/`) over
   (probably bit-banged) SPI on SE17, see the "Touch" row above. The touch firmware is not on
   `vendor`: Xiaomi builds it into the kernel from `firmware/j20s_novatek_ts_fw0{1,2}.bin.ihex`
   in their kernel repo (vayu-r-oss). Converted to raw binaries in `stock/touch-fw/` (not in
   git), 139264 bytes each: fw01 (Tianma, this unit) sha256 `042c1cb8…0177`, fw02 (CSOT)
   `f6fdeb95…db68`. The XNU driver can read it from `/fw/` on the iOS root with
   `hakios_adsp_fw_file()` (bsd/dev/hakios.adsp.c) once the root is mounted.
   **Touch works (2026-11-24).** Kernel patch 0163 (`bsd/dev/vayu_nvt.c`, CI run 45465728188)
   with fw01/fw02 copied into `/fw/` on the root (`tools/add-root-files.sh`, then
   `tools/write-root.sh` sent the changed chunks): tapping and swiping work on the lock screen
   on the first try, so the guessed pin order (MISO 55, MOSI 56), the bit-banged SPI framing,
   the per-boot firmware download and the report parsing are right. Reports are polled every
   8 ms at first; since CI run 45611153050 a report is read only on an INT 122 rising edge,
   latched by the TLMM and checked every 2 ms (fallback reads every 50 ms with a finger down,
   1 s otherwise; `vayutouchpoll=1` restores polling). Tested 2026-11-25: touch works, no stuck
   fingers, UI smoothness about the same (~20 fps by eye). With `sweetusb=2` the phone also showed up as a
   `cdc_ether` USB Ethernet device (`enp0s20f0u1`, "ios-sweet") on Linux.

## Decisions waiting on you

- **Where the iOS root goes.** `sweet_ufs.c` mounts one GPT partition on LUN 0 by name
  (`ufsroot=`, default `userdata`), and the XNU log ring lives at the end of that partition. On
  vayu, LUN 0 holds only `userdata` (226 GiB, Android's data) and small partitions (`cust` is
  1 GiB, too small for the root image). Options: wipe Android's userdata and use it like
  cepheus does (simple, loses Android data; Android can be restored from a ROM afterwards), or
  shrink userdata and add a partition (keeps Android, but means editing the GPT: risky).
- **IPSW.** iPhone X (iPhone10,3) iOS 16.7.16 (20H392), several GB from Apple's CDN.
- **Pushing.** The kernel build runs on the fork's GitHub Actions (macOS runner), so the commits
  have to be pushed and Actions enabled on the fork.

Rules carried from cepheus: only `fastboot boot` for bring-up images, never flash abl/xbl/tz/
modem, write the iOS root to `userdata` from recovery, keep backups and Apple/Xiaomi files out
of git.
