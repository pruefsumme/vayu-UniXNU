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
- **iOS root:** `tools/mkiosroot.sh` supports Arch (`apfs-fuse hfsprogs rsync`). You supply
  the iPhone X iOS 16.7.16 (20H392) IPSW.
- **Recovery:** the test loop needs a vayu TWRP/OrangeFox to pull logs and write the root.

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
