# UniXNU project (as of 2026-11-24)

Method note: "Verified" below = read by me directly in the project's GitHub repo, docs (docs/ folder of the main repo, mirrored at unixnu.com) or via the GitHub API on 2026-11-24. "Claimed" = press or documentation text with no independent evidence. I cloned https://github.com/UniXNU/UniXNU and read the docs sources locally (commit history, devices.toml, docs/). I did not run any build or boot anything. unixnu.com itself was not fetched (docs read from repo source instead). I found no Hacker News, Reddit, Phoronix, 9to5 or XDA coverage of UniXNU via search (searched once; absence is not proof).

## 1. Who runs UniXNU, and where are repos/docs/community?

### Takeaway
UniXNU is a GitHub organization created 2026-10-19 with a large, fast-moving community. Three org members are listed (Acelogic, rponeawa, Jelly10086) and bluseliu50 is the top committer. Its main repo has about 3.1k stars and about 1,065 commits. No named individual or company is claimed as "the" author. Docs, X, Telegram and a QQ group are linked from the repo.

### Cited Findings
- GitHub org "UniXNU", created 2026-10-19, tagline "Run iOS and macOS on non-Apple ARM64 hardware through UEFI", blog = unixnu.com, X = unixnu_new, 32 public repos, public members Acelogic, Jelly10086, rponeawa — [GitHub API org](https://api.github.com/orgs/UniXNU), [org members](https://api.github.com/orgs/UniXNU/members), [org page](https://github.com/UniXNU)
- Main repo created 2026-10-19, last pushed 2026-11-19, 3,110 stars (at time of check), homepage unixnu.com — [UniXNU/UniXNU](https://github.com/UniXNU/UniXNU), [API](https://api.github.com/repos/UniXNU/UniXNU)
- Top contributors by GitHub count: rponeawa 392, bluseliu50 273, Jelly10086 47, xVanTuring 18, xwsjjctz 8, smeng9 6 — [contributors API](https://api.github.com/repos/UniXNU/UniXNU/contributors)
- By `git log` author on a full clone: "UniXNU Docs" 297 commits, bluseliu50 273, rponeawa 228, rpone 143, Jelly10086 37, Sharky Wang 21, xVanTuring 18. The very first commit ("Initial import") on 2026-10-19 is by bluseliu50 — local clone of [UniXNU/UniXNU](https://github.com/UniXNU/UniXNU) (git log)
- Community links on README: docs https://unixnu.com ; Telegram https://t.me/unixnu ; X https://x.com/UniXNU_new ; a QQ group invite (Chinese-language community; README has a README.zh-CN.md) — [README](https://github.com/UniXNU/UniXNU/blob/main/README.md)
- README describes it as "an independent project", "like OpenCore, a general UEFI environment and driver loading system" that "loads the drivers a device needs and boots the OS through a common UEFI layer" — [README](https://github.com/UniXNU/UniXNU/blob/main/README.md)
- Core repos: UniXNU (build tools, component catalog, ARM64 support, OS profiles, UEFI package, docs), UniXNU-sm8550-common, UniXNU-sheng, uefi-sheng. Component repos include Adreno740, AdrenoMetal, ArmCpu, ArmDTPlatform, DarwinBoot, GopFramebuffer, ShengUfs, ShengNovatekTouch, ShengHidInput, Ath12kWifi, QcaBluetooth, QcomDwc3, QcomBaseband, SoftwareAES, RamBlock, XnuPrelink, VerifiedRoot, AirNir, ArmSmmu4K, AdrenoFirmware, AdrenoPM4, etc. — [org repo list API](https://api.github.com/orgs/UniXNU/repos?per_page=100)
- Org repos were created in a burst on 2026-10-19/20 (consistent with an import of an existing private tree; the first commit is titled "Initial import"). Later repos: Ath12kWifi (10-23), UniXNU-sm8550-common (10-24), QcomBaseband (11-02, credited to "HoshinoYumeka (@chiba233)"), QcaBluetooth (11-05), QcomDwc3 (11-06) — [org repo list API](https://api.github.com/orgs/UniXNU/repos?per_page=100)
- The docs and devices catalog list about 410 device records, most of them third-party forks by community members (`repository = "<user>/UniXNU-<codename>"`), plus translated zh docs — [devices.toml](https://github.com/UniXNU/UniXNU/blob/main/devices.toml), [docs/devices](https://github.com/UniXNU/UniXNU/tree/main/docs/devices)
- Press piece (pbxscience) describes UniXNU as an "independent project" and names no individual authors — [PBX Science](https://pbxscience.com/ipados-boots-on-a-xiaomi-tablet-with-a-native-metal-gpu-driver-what-unixnu-has-actually-proven/) (article URL as given in WebFetch result of https://pbxscience.com/?p=24278)
- Real-world identity or legal entity of the maintainers: nothing found in repo (GitHub handles only).

### Inferences
- The "UniXNU Docs" bot-like identity authors about 297 commits that mirror human commits (each docs commit appears paired with a bluseliu50 commit with the same message), and AGENTS.md exists in the repo root, so AI-assisted or automated workflow is likely (inference only; Android Authority makes a similar observation about the separate ios-sweet project: https://www.androidauthority.com/ios-on-android-phones-3726001/).
- The 1,065 commits in about 30 days (peaks of 124 on 2026-10-22 and 116 on 2026-11-17) plus the one-shot "Initial import" suggests the project predates its public repo.

### Gaps
- No Hacker News, Reddit, Phoronix, 9to5, XDA coverage found for "UniXNU". No Mastodon account found. No blog other than unixnu.com docs. X posts at x.com/UniXNU_new were not readable.
- Real names and employers of maintainers not found.
- unixnu.com not fetched directly; GitHub docs/ source used as its equivalent.

## 2. Architecture and boot chain: claims vs verification

### Takeaway
All headline claims (UEFI chain, Mu-Silicium-based firmware, 4 KiB-page XNU, native Adreno 740 driver in XNU) are confirmed in repo docs and source structure. Nothing here shows binaries running on hardware beyond maintainer-written evidence notes; I did not see videos. Current repo state is well past the press article (iPadOS 27.0.1 / arm64e, macOS 27.3 profile, Wi-Fi, Bluetooth, USB).

### Cited Findings
- UEFI/boot chain (verified in docs): Android bootloader loads a boot image whose kernel field is a gzip stream = BootShim + UEFI firmware volume. BootShim relocates the FV and enters UEFI. UEFI loads `UniXNU.efi` (OpenCore-like boot manager reading `\EFI\UniXNU\unixnu.toml`, loading `[[driver]]` entries, patching the device tree, building a menu). Then `DarwinBoot` validates `kernel.macho`, ADT (Apple device tree), trust cache, builds `DARWIN_BOOT_ARGS` (Darwin 23 layout), exits boot services, disables MMU/caches, jumps to the XNU entry at EL1. XNU starts `launchd` from the root volume matched by UUID — [boot-chain.md](https://github.com/UniXNU/UniXNU/blob/main/docs/concepts/boot-chain.md)
- Mu-Silicium base (verified): `uefi-sheng` is described as "UEFI firmware for the Xiaomi Pad 6S Pro (sheng, SM8550), a Mu-Silicium fork for UniXNU"; build docs say BootShim is assembled "for the firmware base and size from the Mu-Silicium device configuration" — [uefi-sheng](https://github.com/UniXNU/uefi-sheng), [boot-chain.md](https://github.com/UniXNU/UniXNU/blob/main/docs/concepts/boot-chain.md). Upstream Mu-Silicium (BSD-2-Clause, 639 stars) — [Project-Silicium/Mu-Silicium](https://github.com/Project-Silicium/Mu-Silicium)
- Image is launched with `fastboot boot` per evidence entries (e.g. `fastboot boot sch4.img`), i.e. RAM boot without flashing the system partitions — [docs/devices/sheng.md](https://github.com/UniXNU/UniXNU/blob/main/docs/devices/sheng.md). (Userdata flashing is also described for rooted layouts: [building.md](https://github.com/UniXNU/UniXNU/blob/main/docs/building.md))
- 4 KiB pages (verified): "Apple ARM64 kernels use a 16 KiB page on most SoCs. Non-Apple ARM64 SoCs commonly use a 4 KiB granule." XNU is built for the `BCM2837` machine configuration (ARM_PGSHIFT 12) rather than `VMAPPLE` (14), with patches for bootstrap page tables, user ABI page shift, and code-signature hashing (the 16 KiB CodeDirectory hash is verified, then split into per-4 KiB-page hashes) — [four-k-page-tables.md](https://github.com/UniXNU/UniXNU/blob/main/docs/xnu/four-k-page-tables.md), [security.md](https://github.com/UniXNU/UniXNU/blob/main/docs/concepts/security.md)
- XNU versions (verified in docs): arm64 iPadOS 17.7.11 profile uses `xnu-10063.141.1` (Darwin 23.6.0); iOS/iPadOS 27 arm64e profile uses `xnu-12377.121.6`; profile ids `ipados-17.7.11-21H461`, `ipados-27.0.1-24A446`, `macos-27.3-26C5035r` — [source-and-patches.md](https://github.com/UniXNU/UniXNU/blob/main/docs/xnu/source-and-patches.md), [arm64e.md](https://github.com/UniXNU/UniXNU/blob/main/docs/porting/arm64e.md), [devices.toml](https://github.com/UniXNU/UniXNU/blob/main/devices.toml). The XNU source is Apple's public source plus about 60 patches in `patches/xnu/` and `patches/xnu-12377/` — [patches dir](https://github.com/UniXNU/UniXNU/tree/main/patches)
- CPU / interrupts / timer (verified in docs): `ArmCpu` driver = "ARM64 CPU, GIC and timer driver", targets GICv3 and the ARM generic timer, PSCI for secondary CPUs, SGI 0 and timer PPI 27, optional software SPIs for IPIs. macOS profile uses a 24 MHz timebase — [arm-cpu.md](https://github.com/UniXNU/UniXNU/blob/main/docs/drivers/arm-cpu.md), [README](https://github.com/UniXNU/UniXNU/blob/main/README.md). Platform expert is generic `ArmDTPlatform` matching the ADT root ([boot-chain.md](https://github.com/UniXNU/UniXNU/blob/main/docs/concepts/boot-chain.md))
- IOMMU: `ArmSmmu4K` kit = ARM SMMUv2 native 4 KiB tables; GPU uses 4 KiB SMMU pages — [org repos](https://api.github.com/orgs/UniXNU/repos?per_page=100), [adreno740.md](https://github.com/UniXNU/UniXNU/blob/main/docs/drivers/adreno740.md)
- Driver layers: UEFI drivers (EDK II .efi), built-in XNU drivers (static archives force-linked into the kernel, bound by IOKitPersonalities against ADT nodes), and kext bundles staged by UEFI — [drivers/overview.md](https://github.com/UniXNU/UniXNU/blob/main/docs/drivers/overview.md)
- GPU path (verified in docs): "Metal → AdrenoMetal → metal2vulkan → Turnip → Darwin KMD → Adreno740 → A740". Adreno740 is a native XNU kernel driver (memory mappings, command submission, fences, CP/GMU init, two-ring priority preemption); Turnip is Mesa's Vulkan driver; AirNir compiles Apple AIR to NIR to IR3 — [adreno740.md](https://github.com/UniXNU/UniXNU/blob/main/docs/drivers/adreno740.md), [Adreno740 repo](https://github.com/UniXNU/Adreno740), [AdrenoMetal repo](https://github.com/UniXNU/AdrenoMetal). Press article describes the same 4-layer path (NativeMetal, metal2vulkan, Turnip, NativeAdreno) and GPU windows (1 GiB render server, 256 MiB per client) — [PBX Science](https://pbxscience.com/ipados-boots-on-a-xiaomi-tablet-with-a-native-metal-gpu-driver-what-unixnu-has-actually-proven/). Note: press uses earlier names (NativeMetal/NativeAdreno); current repos are AdrenoMetal/Adreno740.
- Storage: native UFS driver `ShengUfs` (SM8550 UFS host, PHY, clocks, SMMU; root reads); also RamBlock and VirtioMmioBlock — [sheng-ufs.md](https://github.com/UniXNU/UniXNU/blob/main/docs/drivers/sheng-ufs.md). Display: UEFI GOP framebuffer handoff (`GopFramebuffer`) plus scanout — [GopFramebuffer](https://github.com/UniXNU/GopFramebuffer). Touch: `ShengNovatekTouch` (Novatek NT36532E) and `ShengHidInput` — [org repos](https://api.github.com/orgs/UniXNU/repos?per_page=100)
- Wi-Fi: `Ath12kWifi` runs Linux ath12k/mac80211/cfg80211 (pinned Linux v7.0.14) on XNU with MHI/QRTR/QMI and wpa_supplicant 2.12; WPA2-PSK and open profiles — [ath12k-wifi.md](https://github.com/UniXNU/UniXNU/blob/main/docs/drivers/ath12k-wifi.md). Bluetooth: `QcaBluetooth` (WCN7850). USB: `QcomDwc3` ("DWC3 USB driver for Apple's native stacks"; host mode runs Apple's xHCI stack) — [sheng.md](https://github.com/UniXNU/UniXNU/blob/main/docs/devices/sheng.md), [org repos](https://api.github.com/orgs/UniXNU/repos?per_page=100)
- Security stack: UniXNU says it "keeps the original Apple security components": Apple's AMFI/AppleImage4 validate code against a trust cache that the boot payload supplies; kernel patches add owner-root checks; a `VerifiedRoot` signed-policy block layer; the user-app path adapts AppSync Unified so unsigned/fakesigned IPAs install (no FairPlay or App Store authorization) — [security.md](https://github.com/UniXNU/UniXNU/blob/main/docs/concepts/security.md)
- PAC (arm64e): required for the iPadOS 27 profile; requires FEAT_PAuth on every core and EL1 writable key registers; profile loads one random key set per boot, shared by kernel and arm64e processes; devices without PAC stay on arm64 (iOS/iPadOS 17; docs note iOS 18 is last arm64 release). Only sheng is listed as arm64e-supported ("In development") — [arm64e.md](https://github.com/UniXNU/UniXNU/blob/main/docs/porting/arm64e.md)
- SPTM/PPL/KTRR: the arm64e build uses the BCM2837 machine config "and non-SPTM pmap and no Apple CPU counters" (Chinese-page text and device records); a patch named `non-apple-iommu-bootstrap` mentions protecting "UAT and SART bootstrap and PPL code". I found no docs that implement or require KTRR/PPL/SPTM (they are Apple-silicon-specific, the kernel simply uses the non-SPTM pmap) — [docs/zh/porting/arm64e.md](https://github.com/UniXNU/UniXNU/blob/main/docs/zh/porting/arm64e.md), [docs/zh/xnu/patch-reference.md](https://github.com/UniXNU/UniXNU/blob/main/docs/zh/xnu/patch-reference.md)

### Inferences
- Using XNU's `BCM2837` machine config (the 4 KiB non-Apple config in public XNU) as the base is why the kernel can run on generic ARMv8 cores: no Apple-only hardware features (PPL/SPTM/KTRR/APRR) are needed. The cost: the kernel stays the "non-SPTM" configuration. (Reasoned from docs; I did not read the source patches line by line.)
- Mu-Silicium is used for the UEFI layer, UniXNU sits on top (OpenCore-like), so "bootloader reportedly based on Mu-Silicium" is accurate.

### Gaps
- I did not verify hardware video evidence; evidence in docs is textual boot/log records.
- No explicit doc statement on KTRR/PPL/SPTM requirements beyond the non-SPTM note; only inferred.
- Exact interrupt/timer details for macOS profile and IOKit layering not checked in code.

## 3. Supported / tested devices and SoC list

### Takeaway
Only Xiaomi Pad 6S Pro (sheng, SM8550) is the first-party reference port. The catalog lists about 410 device records (mostly community forks, many marked "invalid" or in early bring-up). No Poco X3 Pro (vayu) record found in the catalog. A porting guide exists in the docs.

### Cited Findings
- Reference device: Xiaomi Pad 6S Pro 12.4 (sheng), SoC SM8550 (Snapdragon 8 Gen 2, Adreno 740), default OS profile `ipados-27.0.1-24A446`, macOS 27.3 override (26C5035r) — [devices.toml](https://github.com/UniXNU/UniXNU/blob/main/devices.toml), [sheng.md](https://github.com/UniXNU/UniXNU/blob/main/docs/devices/sheng.md). Press (Oct 2026) says iPadOS 17.7.11 for iPad7,1 — [PBX Science](https://pbxscience.com/ipados-boots-on-a-xiaomi-tablet-with-a-native-metal-gpu-driver-what-unixnu-has-actually-proven/); the repo has since moved to 27.0.1 as default (17.7.11 profile still exists for arm64 devices).
- Catalog size: 410 `[[device]]` entries in devices.toml. SoC counts (by `soc =`): SM8550 97, SM8250 47, SM8150 29, SM8650 23, SM8475 23, SM8750 20, SDM845 13, SM8350 12, SM8850 11, MSM8998 10, SM7250 9, plus MediaTek (MT6xxx/MT8167), Exynos, Rockchip RK3588 (3), Unisoc, Google Tensor and QEMU/crosvm entries — [devices.toml](https://github.com/UniXNU/UniXNU/blob/main/devices.toml). Many entries are community forks with state strings like "kernel and image integration pending" (e.g. Redmi K40 alioth) or `record_state = "invalid"` (e.g. OnePlus Ace 6) — same file.
- Other examples: Xiaomi Pad 5 (nabu, SM8150), Redmi K40 (alioth, SM8250), OnePlus Ace 6 (SM8750), Redmi Note 12 Turbo/POCO F5 (marble), POCO X7 / Redmi Note 14 Pro 5G (malachite), Benesse TAB-A04-BR3 (MT8167, "Home screen, four CPUs and eMMC DMA") — [devices.toml](https://github.com/UniXNU/UniXNU/blob/main/devices.toml)
- No `vayu`/POCO X3 Pro record found in devices.toml or docs/devices (grep for vayu, bhima, "X3 Pro", surya, karna returned nothing). However upstream Mu-Silicium has `vayu.toml` and `nabu.toml` configs, so UEFI firmware exists upstream for Poco X3 Pro — [Mu-Silicium configs](https://github.com/Project-Silicium/Mu-Silicium/tree/main/Resources/Configs). SM8150 (the X3 Pro's family; SM8150-AC) is a PAC-less Kryo 485 generation. Statement that vayu is SM8150-AC/no PAC is from my background knowledge, not a source cited here.
- Device-porting guide exists: https://unixnu.com/porting/ with pages for steps, SoC support (`UniXNU-<soc>-common` structure with soc.toml, DTSI, patches), device repository, device tree, UEFI firmware, display, input, UFS, GPU, USB, network, power, arm64e, macOS, bring-up — [docs/porting](https://github.com/UniXNU/UniXNU/tree/main/docs/porting), [soc-support.md](https://github.com/UniXNU/UniXNU/blob/main/docs/porting/soc-support.md)
- Required SoC features for arm64e: FEAT_PAuth on all cores, EL1 write access to PAC keys, no hypervisor trapping PAC, native 4 KiB stage-1 translation, an existing SoC repo — [arm64e.md](https://github.com/UniXNU/UniXNU/blob/main/docs/porting/arm64e.md). Non-PAC devices use arm64 profiles with iOS 16 / iPadOS 17 — same page.
- GICv3 + ARM generic timer + PSCI are the baseline CPU interfaces — [arm-cpu.md](https://github.com/UniXNU/UniXNU/blob/main/docs/drivers/arm-cpu.md)

### Inferences
- A Poco X3 Pro (vayu, SM8150, Adreno 640) port would need a new `UniXNU-sm8150-common` or reuse of the nabu (SM8150) community work, a GPU driver for A640 (UniXNU only has Adreno 740 natively; a community "Adreno 830" driver doc exists), and the arm64 (non-PAC) profile. Speculative; not stated by the project.

### Gaps
- No verification of any community device's real status; most records are unchecked self-reports.
- Device count of "working" (device-verified) ports beyond sheng not tallied.

## 4. Maturity and milestone timeline

### Takeaway
Repo history starts 2026-10-19 (but the code evidently existed before). Within a month the project went from iPadOS 17.7.11 with GPU compositing to iPadOS 27 with Wi-Fi/Bluetooth/USB and a macOS 27.3 lab image on one tablet. Still labelled work in progress, with open stability and power issues.

### Cited Findings
- 2026-10-19: org and repos created, "Initial import" by bluseliu50; build driver, payload and docs added same day — [commit history](https://github.com/UniXNU/UniXNU/commits/main)
- 2026-10-20: commit "docs: record the pre-release sheng userland state"; most component repos created — [commit history](https://github.com/UniXNU/UniXNU/commits/main), [org repos](https://api.github.com/orgs/UniXNU/repos?per_page=100)
- 2026-10-20 (about): press article first version states UniXNU published repos/docs before announcing the GPU milestone and iPadOS 17.7.11 booted with Display, touch, UFS working, GPU compositing, no Wi-Fi/BT/USB/audio — [PBX Science](https://pbxscience.com/ipados-boots-on-a-xiaomi-tablet-with-a-native-metal-gpu-driver-what-unixnu-has-actually-proven/). Dating caveat: search snippet shows "November 15, 2026" while page body says "Updated October 20, 2026".
- 2026-10-23: commit "record the QEMU Metal device on the Mac GPU"; 2026-10-25: NativeWifi state / sheng speaker path docs; 2026-10-28 to 10-31: Adreno740/AdrenoMetal tuning (IO-coherent BOs, SMMU fault handling, Core Image kernels) — [commit history](https://github.com/UniXNU/UniXNU/commits/main)
- 2026-11-02 to 11-04: Wi-Fi association and authentication integrated; 2026-11-05/06: Bluetooth architecture and QcaBluetooth component; 2026-11-07: USB boot args and USB/Bluetooth porting guides; 2026-11-09: keyboard cover docs — [commit history](https://github.com/UniXNU/UniXNU/commits/main)
- 2026-11-10: "feat: the macOS 27.3 profile and the macosx kernel target"; 2026-11-11: macOS memory window/GPU stack work; 2026-11-13: macOS account creation and skipping Setup docs; 2026-11-17: unattended macOS desktop lab tooling — [commit history](https://github.com/UniXNU/UniXNU/commits/main)
- Device evidence (docs): macOS 27.3 capture "reached the desktop without input, returned after 204.555 seconds" on sheng with the `macos-unattended-desktop` report — [sheng.md](https://github.com/UniXNU/UniXNU/blob/main/docs/devices/sheng.md). The same doc says the macOS 27.3 kernel-argument set was "Not yet run on hardware" in another passage, so macOS status is internally mixed; treat as experimental.
- iPadOS 27 evidence on sheng: Home Screen shown, Settings opens, App Store icons displayed, `iconservicesagent` used the Adreno 740 Metal device with submissions retired; some app icons missing and per-process Jetsam kills — [sheng.md](https://github.com/UniXNU/UniXNU/blob/main/docs/devices/sheng.md)
- Status labels in sheng record (as of repo revision c8f92b2): display, input, GPU, network, audio, power etc. = `implemented` (source reference, not device proof); keyboard, Bluetooth, USB = `device-verified`; `arm64e-os` = `planned` — [sheng.md](https://github.com/UniXNU/UniXNU/blob/main/docs/devices/sheng.md), [records.md](https://github.com/UniXNU/UniXNU/blob/main/docs/porting/records.md) (defines `device-verified` = device command, commit, result and log)
- Known limits recorded by the project: GPU governor effect on frames unmeasured; low-battery shutdown panics in `vnode_rele_ext`; charge current fixed at 2 A; USB peripheral enumeration unverified; sound "harsh"; fairplayd/adid disabled else SpringBoard doesn't finish starting; Wi-Fi throughput/heat checks pending — [sheng.md](https://github.com/UniXNU/UniXNU/blob/main/docs/devices/sheng.md)
- Press status table (Oct 2026): Wi-Fi, Bluetooth, audio, camera, USB, sensors, battery, suspend/resume "Not available"; firmware stage can stall randomly; "lab prototype, not a usable iPad replacement" — [PBX Science](https://pbxscience.com/ipados-boots-on-a-xiaomi-tablet-with-a-native-metal-gpu-driver-what-unixnu-has-actually-proven/)

### Inferences
- The press table is outdated relative to the repo (Wi-Fi, BT and USB now have code and some device results). A report writer should cite the repo state and label press status as "as of ~Oct 20".
- No "first boot" date can be established from public history because the public repo starts at the "Initial import".

### Gaps
- No dated video or release artifacts found (no GitHub Releases found; I did not confirm via API for every repo).
- Camera, sensors, cellular unspecified in sheng record beyond what is listed.

## 5. Legal acquisition of Apple software, licensing

### Takeaway
The project says it does not redistribute Apple binaries: users supply IPSW/kernelcache/trust cache themselves via the build tools. Code license is BSD-2-Clause-Patent per README (GitHub shows "Other"). XNU and other Apple source remain under Apple's own licenses; build needs Apple SDK/Xcode.

### Cited Findings
- CONTRIBUTING: "Do not commit Apple IPSW files, kernelcaches, disk images, trust caches, Data seeds, vendor firmware or other proprietary binaries." Device repos list inputs in `proprietary-files.txt` — [CONTRIBUTING.md](https://github.com/UniXNU/UniXNU/blob/main/CONTRIBUTING.md)
- Build flow: `./unixnu ipsw fetch` downloads/extracts the target IPSW (local file or URL); requires a decompressed kernelcache, trust cache bundle, Data seed, platform seed (`--unique-chip-id`), device DTB; Apple source references are fetched by `unixnu fetch`; macOS with Xcode is used for the kernel (Linux path uses upstream clang plus cctools-port ld64) — [requirements.md](https://github.com/UniXNU/UniXNU/blob/main/docs/guide/requirements.md), [building.md](https://github.com/UniXNU/UniXNU/blob/main/docs/building.md)
- License: README says BSD-2-Clause-Patent; GitHub API reports license "Other" — [README](https://github.com/UniXNU/UniXNU/blob/main/README.md), [API](https://api.github.com/repos/UniXNU/UniXNU). Press says BSD-2-Clause-Patent — [PBX Science](https://pbxscience.com/ipados-boots-on-a-xiaomi-tablet-with-a-native-metal-gpu-driver-what-unixnu-has-actually-proven/)
- The project pins XNU `12377.121.6` and others from Apple's public source drops (apple-oss-distributions) and takes Apple userland binaries from user-supplied IPSW; payload CI uses a secret for platform seed and macOS account password, and CI notes say "Run it in a fork and delete the run after downloading" the boot images (to avoid publishing Apple-derived artifacts) — [sheng.md](https://github.com/UniXNU/UniXNU/blob/main/docs/devices/sheng.md)
- The Apple IPSW/OS license terms are not discussed in the docs I read (grep for legal/copyright found nothing relevant).

### Inferences
- Kernel/boot images built via the pipeline contain Apple-derived binaries (kernelcache, userland) and are not meant to be shared; the open question of whether using a Apple IPSW on non-Apple hardware complies with the Apple EULA/Software License is not addressed by the project. (My reading; not legal advice.)

### Gaps
- No explicit statement on Apple EULA / legal risk; no DMCA or Apple response found.

## 6. Build and run instructions (summary)

### Takeaway
Fully scripted via the `./unixnu` driver (Python 3.11+). Needs a Mac with Xcode (or Linux toolchain), the device repo and UEFI repo, fastboot, and user-supplied Apple inputs.

### Cited Findings
- Steps: clone `UniXNU`, a device repo and a UEFI repo with `--recurse-submodules`; `./unixnu defconfig <name>_defconfig -D ../<device-repo>`; `./unixnu fetch`; `./unixnu status --json`; copy `unixnu.example.toml` to `unixnu.local.toml`; `./unixnu ipsw info`/`ipsw fetch`; `./unixnu build kernel`, `build package`, `build firmware`; `build userdata`, `build payload`, then `./unixnu bootimg`; test with `fastboot boot <img>` — [building.md](https://github.com/UniXNU/UniXNU/blob/main/docs/building.md), [sheng.md](https://github.com/UniXNU/UniXNU/blob/main/docs/devices/sheng.md)
- Host tools: Xcode, Python 3.11+, git, make, cmake, ninja, unifdef, LLVM+lld, Rust 1.98.0, mtools, dtc, fastboot, optional QEMU+AAVMF — [requirements.md](https://github.com/UniXNU/UniXNU/blob/main/docs/guide/requirements.md)
- QEMU smoke-test targets exist (`ArmVirtPlatform`, `VirtioMmio*` drivers, docs/reference/qemu.md) — [reference/qemu.md](https://github.com/UniXNU/UniXNU/blob/main/docs/reference/qemu.md)
- Bootloader must be unlockable; fastboot boot is used (inferred from fastboot usage; the docs do not discuss unlocking in what I read).

### Gaps
- I did not attempt a build. Hardware prerequisites such as bootloader unlock procedure for Xiaomi are not in the sections read.

## 7. Credibility and verifiability

### Takeaway
UniXNU is much better verifiable than HackiOS-style demos: public org, thousands of commits, driver code, detailed per-area docs with commit-pinned evidence records. Weak points: evidence is self-reported, "first" claims unconfirmed, AI-assisted authorship likely, and press is thin and inconsistently dated.

### Cited Findings
- Press says the "first third-party ARM project to create and open-source a Metal GPU driver" claim "comes from its authors and has not been independently confirmed" — [PBX Science](https://pbxscience.com/ipados-boots-on-a-xiaomi-tablet-with-a-native-metal-gpu-driver-what-unixnu-has-actually-proven/)
- Repo evidence format: each milestone records command, revision and hardware results (boot ids, counts, timings), and the docs distinguish `implemented` (source) from `device-verified` — [records.md](https://github.com/UniXNU/UniXNU/blob/main/docs/porting/records.md)
- Repo contains `AGENTS.md` at the root and docs say "The documentation is revised with the source. For a specific detail, check the linked build report or repository" — [repo root](https://github.com/UniXNU/UniXNU), [docs/index.md](https://github.com/UniXNU/UniXNU/blob/main/docs/index.md)
- Many catalog entries failed the project's own validation (`record_state = "invalid"` with an error such as "components without an area") — [devices.toml](https://github.com/UniXNU/UniXNU/blob/main/devices.toml)
- 16 open issues and 32 open PRs at check time; heavy community fork activity — [UniXNU/UniXNU](https://github.com/UniXNU/UniXNU)
- I did not find independent reproduction by a third party (no Hacker News/Reddit/Phoronix thread found).

### Inferences
- Repo content is consistent with an actually-working sheng prototype (hardware-specific boot IDs, timings, many patches), but I cannot rule out exaggeration; I did not see video or run it.

### Gaps
- No independent test or video verification located. X posts not accessed.

## 8. Relationship to HackiOS, controversies, Mavernix/OS X

### Takeaway
HackiOS (OOSEX GANG, XNU 8796 / iOS 16.5, POCO X5 Pro "redwood") is a separate project with its own loader (xnuloader); UniXNU's own docs catalog a HackiOS-based Galaxy S9 port as "not built on the UniXNU tree". The two share ingredients (Mu-Silicium UEFI, Adreno/Metal ideas) but not code. No mention of Mavernix or OS X/Mavericks found.

### Cited Findings
- HackiOS: "independent research project by OOSEX GANG", boots xnu-8796.121.2 (iOS 16.5) and unmodified iOS 16.5 userspace on POCO X5 Pro 5G (redwood, Snapdragon 778G) via `fastboot boot`; repo https://github.com/oosexgang/hackios-xnu-kernel; reportedly contains no Apple files, `ios165/fetch.sh` fetches the IPSW from Apple CDN; page dated Oct 22, 2026 — [book.st-hakky.com](https://book.st-hakky.com/en/news/run-ios-16-5-firmware-on-android) (page self-labelled AI-generated summary)
- HackiOS repo exists: created 2026-10-22, pushed 2026-11-22, about 2,859 stars, no license metadata, description "Apple's open-source XNU kernel on Android phones: its own loader and drivers, Metal on the Adreno. Runs from RAM" — [oosexgang/hackios-xnu-kernel](https://github.com/oosexgang/hackios-xnu-kernel)
- UniXNU docs page for the Galaxy S9 (starlte) says "based on HakiOS (Scion-Project/scion-kernel, from oosexgang's HakiOS), not on the UniXNU tree; no UniXNU components are used", and that it uses Mu-Silicium starltePkg with HakiOS changes — [docs/zh/devices/starlte.md](https://github.com/UniXNU/UniXNU/blob/main/docs/zh/devices/starlte.md). So UniXNU catalogs HackiOS-derived ports but they are distinct code.
- Press (PBX Science) describes HackiOS demos (Poco X5 Pro, Mi 11 Lite 5G) as having "no public code or build" and calling them unverified, and treats UniXNU as a stronger case because code was published first — [PBX Science](https://pbxscience.com/ipados-boots-on-a-xiaomi-tablet-with-a-native-metal-gpu-driver-what-unixnu-has-actually-proven/). This is contradicted by the HackiOS GitHub repo existing since 2026-10-22 ([repo](https://github.com/oosexgang/hackios-xnu-kernel)), so the pbxscience statement may be stale or refer to an earlier state.
- Other controversy/doubt: Android Authority (2026-10-21) covers the separate "ios-sweet" project (Redmi Note 10 Pro, iOS 16.7.16 on spoofed iPhone X tree) under the label "Hackios", does not mention UniXNU, and doubts sustainability, noting AI-agent instructions in its NOTES.md — [Android Authority](https://www.androidauthority.com/ios-on-android-phones-3726001/). Search summaries also report hackios.net warning that downloadable "HackiOS" files are fake/malware (second-hand via search summary; not verified) — [search result for HackiOS](https://smhn.info/202610-hackios-runs-ios-on-android-poco-x5-pro).
- Mavernix / OS X on ARM: no mention of "Mavernix", "Mavericks" or "OS X" in the UniXNU repo (grep of full clone returned nothing). UniXNU's macOS target is macOS 27.3 (xnu-12377), not OS X 10.9; it credits [macOS-DroidVM](https://github.com/Droid-VM/macOS-DroidVM) as source for macOS kernel patches — [README](https://github.com/UniXNU/UniXNU/blob/main/README.md)

### Inferences
- UniXNU and HackiOS are parallel efforts in the same wave (Oct 2026), loosely connected through a shared community and Mu-Silicium; the HackiOS tree has downstream forks (scion-kernel) that UniXNU's catalog links to.
- For a Mavernix comparison, relevant takeaways: UniXNU's techniques (4 KiB XNU, non-SPTM pmap on BCM2837 config, UEFI/ADT handoff) apply to modern ARM XNU only; nothing for OS X 10.9 (x86).

### Gaps
- Relationship between maintainers of UniXNU and OOSEX GANG not established beyond catalog links.
- hackios.net malware warning not checked directly.

## Key URL index
- Org: https://github.com/UniXNU ; main repo: https://github.com/UniXNU/UniXNU ; sheng device: https://github.com/UniXNU/UniXNU-sheng ; UEFI: https://github.com/UniXNU/uefi-sheng ; GPU: https://github.com/UniXNU/Adreno740, https://github.com/UniXNU/AdrenoMetal
- Docs: https://unixnu.com (device page https://unixnu.com/devices/sheng, GPU docs https://unixnu.com/drivers/adreno740) ; X https://x.com/UniXNU_new ; Telegram https://t.me/unixnu
- Press: https://pbxscience.com/ipados-boots-on-a-xiaomi-tablet-with-a-native-metal-gpu-driver-what-unixnu-has-actually-proven/ ; https://www.androidauthority.com/ios-on-android-phones-3726001/ ; https://book.st-hakky.com/en/news/run-ios-16-5-firmware-on-android ; https://pasqualepillitteri.it/en/news/25375/hackios-ios-xiaomi-poco-no-code
- Mu-Silicium: https://github.com/Project-Silicium/Mu-Silicium
