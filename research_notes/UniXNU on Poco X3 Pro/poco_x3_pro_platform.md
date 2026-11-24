# Poco X3 Pro (vayu, SM8150-AC / msmnile) as a non-Android OS target (state as of 2026-11-24)

Research caveats (read first):
- The postmarketOS wiki, GitLab and package index (wiki/gitlab/pkgs.postmarketos.org) now answer with HTTP 301/308 redirects to *.nura.eco hosts guarded by an Anubis bot-wall. I could not read the vayu wiki page directly. The pmOS statements below come from search-engine summaries of that page and from package listings, so they are second-hand. Re-verify in a browser.
- Several fetches were summarised by a small model (WebFetch), not read raw. The Mu-Silicium Status.md and Linux Makefile results are the most reliable because they are raw files.
- No source I found covers the Kryo 485 microarchitecture details, EL2/Gunyah behaviour on vayu, panel/touch part numbers, or the memory map. These are gaps (see Q4). Any "background" statement is marked as unsourced.

## Q1. Bootloader unlock on vayu (Xiaomi process, EDL, bricking, anti-rollback)

### Takeaway
Unlocking is official but gated: global Xiaomi account (at least 30 days old per a Feb 2026 review), approval through the Xiaomi Community app, a daily quota, and a wait that Xiaomi's FAQ says is currently over 7 days. Xiaomi's own FAQ caps unlocks per account, and sources disagree on the cap (1 vs 3). EDL (9008) on vayu is reachable but the stock firehose is auth-locked, so a hard brick is hard to recover without an authorized service account.

### Cited Findings
- Notebookcheck (published 2026-02-17): a global (not Chinese) Xiaomi account is required and it must be at least 30 days old. Xiaomi must approve each unlock via the Mi Unlock tool. Approval is tied to one account and covers one device. A second device needs a separate account with a different phone number. — [Notebookcheck](https://www.notebookcheck.net/Unlocking-bootloader-Xiaomi-does-it-better-than-Samsung-despite-some-caveats.1228387.0.html)
- Same article: Xiaomi grants a limited number of permissions per day, starting 12:00 China time (UTC+8). Requests go through the Xiaomi Community app. After approval, start from the "Unlock Bootloader" item in the app, then use the Mi Unlock tool. Unlocking wipes the data. The daily number is not stated. — [Notebookcheck](https://www.notebookcheck.net/Unlocking-bootloader-Xiaomi-does-it-better-than-Samsung-despite-some-caveats.1228387.0.html)
- Xiaomi's global FAQ (undated in the results): users with a low security score and new models on sale wait longer. The summary reported "currently over 7 days" and said the wait grows if more than 2 phones have been unlocked in the year. A second search summary of the same FAQ reported 5-7 days. These two readings conflict. — [Xiaomi FAQ KA-07238](https://www.mi.com/global/support/faq/details/KA-07238/)
- The Korean-language Xiaomi FAQ says a maximum of 3 devices can be unlocked per account. This conflicts with Notebookcheck's one device per account. — [Xiaomi KR FAQ](https://www.mi.com/kr/support/faq/details/KA-535039/); contradicted by [Notebookcheck](https://www.notebookcheck.net/Unlocking-bootloader-Xiaomi-does-it-better-than-Samsung-despite-some-caveats.1228387.0.html)
- A Gizchina guide (Oct 2025) says about 72 hours after applying. A Wondershare guide says 3-7 days and one device per year (commercial tutorial, low weight). — [Gizchina](https://www.gizchina.com/editorial/how-to-unlock-the-bootloader-on-xiaomi-hyperos-global-devices), [Wondershare](https://drfone.wondershare.com/android-xiaomi/how-to-unlock-the-bootloader-on-xiaomi-phone-under-hyperos.html)
- A Change.org petition created 2026-04-09 complains that Xiaomi's approval capacity is extremely limited. This is evidence of a bottleneck, not a policy document. — [Change.org](https://www.change.org/p/urge-xiaomi-to-simplify-bootloader-unlocking-policy)
- Xiaomi said in 2023 that HyperOS would not push updates to devices with unlocked bootloaders. This was reported for HyperOS and China-first rules. It matters little for vayu, which is already on its last official MIUI 14 (per the device facts given). — [GSMArena](https://www.gsmarena.com/xiaomi_phones_with_unlocked_bootloader_wont_get_hyperos_updates-news-60521.php)
- LineageOS's vayu install page exists (unlock, fastboot, firmware and recovery steps) but returned HTTP 403 to my fetch, so I could not extract the fastboot commands from it. — [LineageOS vayu install](https://wiki.lineageos.org/devices/vayu/install/)
- EDL: the stock Xiaomi firehose programmer demands an authorization signature from Xiaomi. Without an authorized account, flashing tools fail with Sahara/unauthorized errors. Test-point shorting reaches 9008 but does not solve authentication. "Patched" firehose files are offered by SEO-spam sites. I could not verify any of them. — [search results, mostly low quality](https://doc.e.foundation/devices/vayu), [Xiaomi EU thread](https://www.xiaomi.eu/community/threads/poco-x3-pro-vayu-stuck-in-edl.76788/)
- Xiaomi EU forum thread, 7 Oct 2026: a vayu owner deleted partitions with Windows Disk Management and the phone now enters only EDL 9008, with no fastboot or recovery. QFIL/QPST with official firmware did not fix it. The only reply (18 Oct 2026) says an authorized EDL account is often required and advises a repair specialist. No recovery was confirmed. — [Xiaomi EU thread](https://www.xiaomi.eu/community/threads/poco-x3-pro-vayu-stuck-in-edl.76788/)
- One page advises reading the anti-rollback (ARB) index before flashing. I have no vayu-specific ARB value or policy from a trustworthy source. — [search result summary](https://doc.e.foundation/devices/vayu)

### Inferences
- With the unit locked, the realistic path is to apply via the Community app at 12:00 UTC+8, expect a multi-day to 7+ day wait, and not rely on the shorter 72 h figure from older guides.
- Any UEFI/custom-OS experiment that overwrites partitions has a real brick risk. Recovery from a hard brick is not guaranteed without an authorized EDL account. Keep fastboot-reachable boot images (boot-only flashes or `fastboot boot`) and avoid touching abl, xbl or other firmware partitions.
- The vayu EDL thread's brick cause (GPT deletion) suggests the GPT/partition table is the main fragile spot. Back up the partition table first.

### Gaps
- Exact current waiting time and daily quota size for the vayu global ROM: the FAQ readings conflict and neither is dated.
- Fastboot command set on vayu, fastboot `boot` behaviour on the unlocked bootloader, recovery options: the LineageOS page was not readable.
- Known loaders/firehose for vayu, and whether any public authorized loader exists: no reliable source found.
- Anti-rollback index and policy on MIUI 14 (V14.0.1.0.TJUMIXM): not found.
- Whether the Mi Unlock tool/app flow changed in HyperOS 3 era beyond what is above: the Xiaomi announcement page (new.c.mi.com/global/post/850671) returned only a title.

## Q2. UEFI on vayu (edk2-msm, Mu-Silicium, Project Aloha, WoA)

### Takeaway
Vayu has a working community UEFI: an `xiaomi-vayu` target in the woa-msmnile (msmnilePkg/memePkg, Project Mu based) tree with DSDT, and a vayu entry in Project-Silicium/Mu-Silicium's Status.md (marked "Inactive"). The UEFI reports display, UFS, buttons, USB device mode and mass storage working, with Windows boot and Linux boot both marked working. USB host mode and USB-PD are not.

### Cited Findings
- msmnilePkg (woa-msmnile) lists "Xiaomi Poco X3 Pro (xiaomi-vayu)" under SM8150 with DSDT support marked working and Degdag as contributor. The project says it can boot Windows 10 and 11 ARM64. — [msmnilePkg](https://github.com/woa-msmnile/msmnilePkg); same table also appears in [memePkg search result](https://github.com/woa-msmnile/memePkg) and [Uotan-Dev XiaomiPkg](https://github.com/Uotan-Dev/XiaomiPkg)
- The msmnilePkg README says common working features across supported targets are: I2C, SPI, GPIO, SPMI, pinmux (TLMM), PMIC and RPM, UFS 3.1, side buttons, USB, display framebuffer. — [msmnilePkg](https://github.com/woa-msmnile/msmnilePkg)
- Build: `./build_uefi.py -d xiaomi-vayu` (`-s 1` for Secure Boot, `-t DEBUG`). Output is `Build/xxxxPkg/<target>.img`. Needs x86_64 Linux host, Python 3.12+, clang/LLVM (CLANGPDB_BIN pointing at an LLVM 10 folder), aarch64 gcc. Project Telegram: t.me/project_aloha_issues; tutorials at aloha.firmware.icu. The Releases section was empty at fetch time. — [msmnilePkg](https://github.com/woa-msmnile/msmnilePkg)
- Mu-Silicium Status.md entry "Xiaomi Poco X3 Pro (vayu) (Inactive)", note "Requires Windows Drivers". UEFI status: Display OK, Internal Storage OK, Side Buttons OK, USB Host Mode NOT working, USB Device Mode OK, USB Power Delivery NOT working, SD Card NOT working, Mass Storage OK, Windows Boot OK, Linux Boot OK. — [Mu-Silicium Status.md (raw)](https://raw.githubusercontent.com/Project-Silicium/Mu-Silicium/main/Status.md)
- Same file, Windows OS status for vayu: working: internal storage, SD card, side buttons, accelerometer, compass, gyroscope, battery, USB, WLAN, CPU, touchscreen, Bluetooth, GPS, speakers, 3.5mm jack, microphone, GPU, mobile data, display. Not working: proximity, fingerprint, NFC, camera, vibration. Partial: charging (very slow), flashlight (strobe only via Windows Camera). Temperature unknown. — [Mu-Silicium Status.md (raw)](https://raw.githubusercontent.com/Project-Silicium/Mu-Silicium/main/Status.md)
- Sibling SM8150 devices in the same file for comparison: Xiaomi Pad 5 (nabu) is "Active" with Windows and Linux boot OK, Linux OS status including internal storage, touchscreen, GPU, WLAN, USB, battery working. Mi 9 (cepheus) is Inactive, Windows boot OK, Linux boot not working. LG G8x (mh2) Inactive, Linux boot OK. — [Mu-Silicium Status.md (raw)](https://raw.githubusercontent.com/Project-Silicium/Mu-Silicium/main/Status.md)
- Mu-Silicium's main README does not list vayu and points to Status.md; I did not find an explicit vayu build target there. The "Inactive" label means the maintainers are not actively working on it. — [Mu-Silicium](https://github.com/Project-Silicium/Mu-Silicium)
- woa-msmnile/Vayu Windows driver pack (based on SurfaceDuo-Drivers): Bluetooth, Wi-Fi, UFS, touch, GPU, battery, buttons, light sensor working. Thermal sensor partial, charging slow only. Haptic, cellular data and NFC not working. This partly disagrees with Status.md (mobile data OK there, not working here). — [woa-msmnile/Vayu](https://github.com/woa-msmnile/Vayu); contradicted on mobile data by [Status.md](https://raw.githubusercontent.com/Project-Silicium/Mu-Silicium/main/Status.md)
- WoA Helper (flash tool) requires Android 11+ and a rooted device with Windows installed. — [WoA-Helper](https://www.github.com/KuatoDev/WoA-Helper)

### Inferences
- A UEFI-booted non-Android OS is already feasible on vayu in the sense that UEFI gives GOP framebuffer, UFS block access, buttons, ACPI (DSDT), and USB device mode. A UEFI-booted XNU would still need its own drivers for everything else.
- USB host mode not working in UEFI is a practical limit for keyboard-in-UEFI use. Mass storage over USB device mode is available for data transfer.
- The "Inactive" status and the empty Releases page suggest prebuilt images may be stale. Expect to build from source or ask in the Aloha Telegram group.
- Windows ARM64 booting implies the UEFI provides an ACPI model plus an exit from Gunyah that works for Windows. Whether that hands the OS EL1 or EL2 is not stated (see Q4).

### Gaps
- edk2-porting/edk2-msm: I did not check it directly for vayu (not fetched). Treat as unknown.
- Date of the last vayu UEFI commit/build, and whether a signed/secure-boot-compatible flash path exists on the locked bootloader: not found.
- How the UEFI image is loaded (replace boot partition vs `fastboot boot`), and whether it needs unlocked ABL: not stated in the pages read.
- Linux-over-UEFI details (device tree vs ACPI, which kernel) for vayu: not covered by Status.md beyond "Linux Boot OK".

## Q3. Mainline Linux / postmarketOS status for sm8150 and vayu

### Takeaway
postmarketOS has a vayu port in its device packages and an actively maintained `linux-postmarketos-qcom-sm8150` kernel package. Vayu itself is not in mainline Linux: the upstream qcom DTS Makefile has no vayu entry, and the only SM8150 boards upstream are the HDK, MTP, Surface Duo and two Sony Kumano devices. Vayu relies on the out-of-tree sm8150-mainline fork.

### Cited Findings
- Upstream `arch/arm64/boot/dts/qcom/Makefile` (fetched from torvalds/linux master, Nov 2026): sm8150 entries are sm8150-hdk, sm8150-microsoft-surface-duo, sm8150-mtp, sm8150-sony-xperia-kumano-bahamut, sm8150-sony-xperia-kumano-griffin. No vayu, no other Xiaomi sm8150 board (cepheus, raphael, nabu absent). — [torvalds/linux Makefile](https://raw.githubusercontent.com/torvalds/linux/master/arch/arm64/boot/dts/qcom/Makefile)
- postmarketOS wiki page "Xiaomi POCO X3 Pro (xiaomi-vayu)" exists (via search result). From search summaries: lists two panel variants (Huaxing/CSOT and Tianma) needing different kernel packages; links a work-in-progress sm8150 kernel fork; installation instructions are in a merge request (reported as MR 17 on the qualcomm-sm8150 repo); described as currently suitable as a server. — [pmOS wiki](https://wiki.postmarketos.org/wiki/Xiaomi_POCO_X3_Pro_(xiaomi-vayu)) (could not be read directly, see caveats)
- A second summary of the same wiki said the device is in "testing" with UFS internal storage working and no upstream-merged markers. — [pmOS wiki](https://wiki.postmarketos.org/wiki/Xiaomi_POCO_X3_Pro_(xiaomi-vayu)) (second-hand)
- postmarketOS package index has `device-xiaomi-vayu-phosh`, `device-xiaomi-vayu-kernel-tianma`, and `device-xiaomi-vayu-nonfree-firmware-openrc`. The Tianma kernel package was updated in May 2026 per one summary. — [device-xiaomi-vayu-phosh](https://pkgs.postmarketos.org/package/main/postmarketos/aarch64/device-xiaomi-vayu-phosh), [kernel-tianma](https://pkgs.postmarketos.org/package/main/postmarketos/aarch64/device-xiaomi-vayu-kernel-tianma)
- `linux-postmarketos-qcom-sm8150` kernel package in main was last built 2026-02-19 per one summary (maintainer Pan Ortiz). — [pkgs](https://pkgs.postmarketos.org/package/main/postmarketos/aarch64/linux-postmarketos-qcom-sm8150)
- The old GitLab group gitlab.com/sm8150-mainline/linux is archived and moved to gitlab.postmarketos.org/soc/qualcomm-sm8150/linux. Its default branch was `sm8150/6.14`. A postmarketOS fork branch `sm8150/6.14` also existed (commits dated Mar 2025). — [sm8150-mainline/linux](https://gitlab.com/sm8150-mainline/linux), [pmOS branch](https://gitlab.postmarketos.org/panpanpanpan/sm8150-mainline/-/commits/sm8150/6.14)
- Mu-Silicium Status.md shows the Xiaomi Pad 5 (nabu, also SM8150) with Linux working for storage, touch, GPU, Wi-Fi, USB and battery with a mainline kernel. This is a closely related mainline-SM8150 data point, not vayu. — [Status.md](https://raw.githubusercontent.com/Project-Silicium/Mu-Silicium/main/Status.md)
- Patch evidence for the SM8150 SoC upstream: Mi 9 (cepheus) support was posted to the arm-kernel list in 2022 but cepheus is not in the current upstream Makefile. — [patchew](https://patchew.org/linux/20220107025910.112425-1-alexeymin@postmarketos.org/)

### Inferences
- Linux on vayu means: sm8150 mainline fork (about 6.14 base per the archived tree) + vayu DTS from the pmOS fork + Tianma/Huaxing panel variant selection. The user's unit's panel variant is unknown and matters for choosing the kernel package.
- SoC-level upstream drivers (UFS, a6xx/Adreno 640 via freedreno/Turnip, DSI, USB, SMMU) are available since sm8150 has been upstream for years. Board-level (panel, touch, regulators) is what vayu's out-of-tree DTS adds.
- GPU via freedreno/Turnip on a640: not confirmed for vayu in anything I read. The nabu Linux GPU "working" entry suggests it works on the SoC with the right firmware.

### Gaps
- The actual pmOS wiki feature table (display, touch, Wi-Fi, GPU, USB, battery, etc.) for vayu: unreadable due to the Anubis wall. Whoever needs this should open the wiki in a browser.
- Kernel version actually shipped for vayu today (the 6.14 base is from archived trees and may be dated).
- Whether any vayu DTS patch has been posted to linux-arm-msm: searches found none.
- Whether freedreno/Turnip acceleration works on vayu: no source.

## Q4. Hardware facts for an OS port

### Takeaway
I found no sourced documentation for the architecture-level facts (ISA features, page sizes, GIC, SMMU, memory map, EL levels, panel/touch parts). The only sourced items are about Gunyah and EL2 on newer Qualcomm platforms and the UFS 3.1 and display framebuffer facts from the UEFI status. The report writer should treat all other items as unverified.

### Cited Findings
- UFS 3.1 is listed as working in the Aloha/msmnile UEFI. — [msmnilePkg](https://github.com/woa-msmnile/msmnilePkg)
- UEFI exposes a display framebuffer and uses ACPI DSDT on vayu (DSDT marked supported). — [msmnilePkg](https://github.com/woa-msmnile/msmnilePkg)
- Qualcomm's Gunyah hypervisor normally limits Linux to EL1. Qualcomm documents that KVM requires booting at EL2 and that a Gunyah-vs-KVM boot mode is selected by flashing a matching XBL config image (on newer Dragonwing platforms). — [Qualcomm docs](https://dragonwingdocs.qualcomm.com/System/Kernel/enable-virtualization.md)
- A U-Boot patch series (v2 May 2026, v4 July 2026) adds an early SMC call via TrustZone that exits Gunyah so U-Boot can run at EL2 on Snapdragon. Upstream kernel has EL2 DT overlays for Lemans, Monaco, Kodiak and X1 devices. These cover those SoCs, not sm8150. — [U-Boot v2](https://lists.denx.de/pipermail/u-boot/2026-May/618646.html), [U-Boot v4](https://lists.denx.de/pipermail/u-boot/2026-July/623894.html), [lkml Kodiak EL2 overlay](https://lkml.iu.edu/2605.2/13441.html)
- On the Poco F1 (beryllium, SDM845) different panel variants use different touch controllers (Novatek NT36672a vs FocalTech FT8719), so DT is split per panel. This is an analogy for vayu's two panel variants, not a vayu fact. — [patchew pocof1 touch series](https://patchew.org/linux/20250506-pocof1-touchscreen-support-v4-2-bfb53da52945@joelselvaraj.com/mbox)
- The postmarketOS vayu package split (Tianma vs Huaxing/CSOT) confirms two panel vendors exist on vayu. — [kernel-tianma pkg](https://pkgs.postmarketos.org/package/main/postmarketos/aarch64/device-xiaomi-vayu-kernel-tianma)

### Inferences
- Unsourced background knowledge (not verified in this research, flag when reporting): Kryo 485 is a Cortex-A76/A55-derived design implementing ARMv8.2-A, which has no pointer authentication (PAC arrived in v8.3); SM8150 uses a GICv3 and the ARM generic timer. SM8150 UEFI work leaves the OS at EL1 under Gunyah/QHEE on stock firmware, since sm8150 predates the EL2 overlays above. Page sizes (4K/16K/64K support) are not something I verified.
- Since Windows ARM64 and Linux boot at EL1 via UEFI, an XNU port should assume EL1 and a Gunyah-controlled EL2 unless a working EL2-exit path (as in the new U-Boot patch for newer SoCs) is found for sm8150. This is a hypothesis.

### Gaps
- Confirmation whether the Aloha UEFI for sm8150 hands over at EL1 or EL2: not stated in any page read.
- Kryo 485 feature registers (ID_AA64ISAR1 PAuth, LSE, etc.), supported translation granules, GIC/SMMU version, DDR map, panel model and DSC use, touch controller model on vayu: no sources found. The vayu DTS in the pmOS tree and MiCode's kernel DTS would answer these.

## Q5. Community ecosystem for vayu

### Takeaway
Vayu has an active Android ecosystem (LineageOS, /e/OS, PixelExperience, ArrowOS, custom kernels) and Xiaomi SM8150 device trees maintained under xiaomi-sm8150-devs. The Windows-on-ARM community (woa-msmnile, Project Aloha) is the main non-Android effort. I did not open MiCode's Xiaomi_Kernel_OpenSource.

### Cited Findings
- LineageOS officially supports vayu (wiki page exists). /e/OS and PixelExperience also have vayu pages. — [LineageOS](https://wiki.lineageos.org/devices/vayu/), [/e/](https://doc.e.foundation/devices/vayu), [PixelExperience](https://wiki.pixelexperience.org/devices/vayu)
- The GitHub org xiaomi-sm8150-devs ("LineageOS on Xiaomi SM8150") holds: android_kernel_xiaomi_sm8150 (updated 2026-11-05), android_device_xiaomi_sm8150-common (2026-11-23), proprietary_vendor_xiaomi_sm8150-common (2026-10-19), proprietary_vendor_xiaomi_vayu (2026-09-24), plus cepheus, raphael, nabu trees. The vayu device tree itself was not in the visible 10 of 14 repos. — [xiaomi-sm8150-devs](https://github.com/xiaomi-sm8150-devs)
- Other vayu community links: ArrowOS XDA thread (vayu|bhima), Yuki custom kernel for vayu (KDE store), Telegram PocoX3ProUpdates channel, SailfishOS-vayu org. — [ArrowOS XDA](https://forum.xda-developers.com/t/rom-official-arrowos-11-0-android-11-0-vayu-bhima.4267263/post-84899935), [Yuki kernel](https://store.kde.org/p/1574878), [Telegram](https://t.me/s/PocoX3ProUpdates/2252), [SailfishOS-vayu](https://www.github.com/SailfishOS-vayu/android_device_xiaomi_sm8150-common)
- Windows-on-vayu: msmnilePkg (UEFI), woa-msmnile/Vayu and msmnile-Drivers (drivers), Project Aloha Telegram and aloha.firmware.icu tutorials. — [msmnilePkg](https://github.com/woa-msmnile/msmnilePkg), [Vayu drivers](https://github.com/woa-msmnile/Vayu)

### Inferences
- The xiaomi-sm8150-devs kernel (updated Nov 2026) is the practical downstream reference for vayu drivers and DTS if MiCode's repo is hard to use. Its Nov 2026 activity shows the platform is still maintained.

### Gaps
- MiCode/Xiaomi_Kernel_OpenSource vayu branch (branch name, kernel 4.14.x, DTS paths): not fetched or verified.
- Any XDA thread specifically about UEFI/Linux on vayu, and the state of the Aloha Telegram group: not checked.
