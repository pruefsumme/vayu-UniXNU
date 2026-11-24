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
| Keys | GPIO vol_up 6, PMIC PON | vol_up GPIO ? | Small |
| RAM | ~6 GB, 3 banks | 8 GB, banks ? | `tools/mkadt.py` memory ranges |
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

1. Boot a vayu TWRP/OrangeFox with `fastboot boot`, then back up `persist`, `persistbak`,
   `modemst1/2`, `fsg`, `devinfo`, `abl`, `xbl`, `xbl_config`, `boot`, `dtbo`, `vbmeta*`
   (~350 MiB, minutes). Also dump stock `boot.img` for its DTB. Keep all of it out of git.
2. Build the probe-only shim (no payload) on Linux with vayu's DTB and `fastboot boot` it.
   Success = a colour fill at 0x9c000000 and a reboot back to fastboot. Needs no Apple files.
3. Fix FB geometry and the watchdog for vayu, then add the vayu memory map to `mkadt.py` and
   build a kernel via Actions; target "waiting for root device".
4. UFS root, launchd, SpringBoard; then touch (Novatek SPI), backlight, Wi-Fi, GPU present.

Rules carried from cepheus: only `fastboot boot` for bring-up images, never flash abl/xbl/tz/
modem, write the iOS root to `userdata` from recovery, keep backups and Apple/Xiaomi files out
of git.
