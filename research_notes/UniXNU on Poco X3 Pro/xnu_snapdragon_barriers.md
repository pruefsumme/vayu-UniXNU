# XNU (iOS/macOS userland) on Snapdragon 860 / SM8150 (Poco X3 Pro "vayu"): technical requirements and barriers

Research date: 2026-11-24. Almost everything about phone ports comes from self-published GitHub READMEs and project sites dated Oct-Nov 2026, plus a few news write-ups. No independent technical verification was found. Treat these as reported claims, not confirmed ones. Several of the user's premises needed correcting (see the first section).

## Premise corrections and the single most important finding

### Takeaway
An XNU port to the same SoC family as vayu already exists and reportedly reaches SpringBoard, Safari, Wi-Fi and Metal-on-Turnip: "ios-flame" for the Pixel 4 (SM8150 / Snapdragon 855, Adreno 640, 4x A55 + 4x A76), a fork of "ios-sweet". The vayu is SM8150-AC, which is very close to that silicon. So the question is no longer "can XNU boot on SM8150" but "how much board-specific work (display, touch, UFS variant, Wi-Fi chip, bootloader) separates vayu from Pixel 4". Several premises in the brief were also off, listed below.

### Cited Findings
- ios-flame is a public repo (NWylynko/ios-flame), forked from dipa-studio/ios-sweet, 242 commits, labelled "Experimental bring-up, not a usable phone OS". It runs unmodified iOS 16.7.16 (20H392) iPhone X userland on the Pixel 4 (SM8150, Adreno 640). Status listed "as of 2026-10-22, kernel 0124". — [ios-flame README](https://github.com/NWylynko/ios-flame)
- The brief's "Project Sandcastle (Snapdragon 835 Pixel)" is wrong. Sandcastle is Corellium's project booting Android on iPhone 7 / 7 Plus / iPod touch 7 via checkra1n, i.e. the opposite direction. It is not an XNU-on-Android precedent. — [9to5Google](https://9to5google.com/2020/03/05/android-on-iphone-project-sandcastle/), [XDA](https://www.xda-developers.com/install-android-10-apple-iphone-7-plus-project-sandcastle-checkra1n-jailbreak/)
- The actual XNU-on-Android family (all reported Oct-Nov 2026): HackiOS (POCO X5 Pro 5G, SM7325 / Snapdragon 778G, Adreno 642L), ios-sweet (Redmi Note 10 Pro, SM7150 / Snapdragon 732G), UniXNU (Xiaomi Pad 6S Pro "sheng", Snapdragon 8 Gen 2 / SM8550, Adreno 740 — a tablet, not a phone), plus community ports: Pixel 4 (855), LG V60 (865), Pixel (2016, 821), Redmi Note 12 4G (685), POCO M8 5G (6 Gen 3), Pixel 6a (Tensor G1), Galaxy S7 (Exynos 8890). — [hackiosx.dev projects](https://hackiosx.dev/projects.html), [HakiOS README](https://github.com/burdenghost/Hackios)
- The Poco X5 Pro is Snapdragon 778G (SM7325), Adreno 642L. — [hackios-web](https://hackios-web.vercel.app/en). The brief's "Snapdragon 695 / Mi 11 Lite 5G" matches no port found; no source for either.
- The phone ports are named for different GPUs than the brief assumed: the only reported native Adreno 740 driver is on the Xiaomi Pad 6S Pro (UniXNU). Not a phone. — [hackiosx.dev projects](https://hackiosx.dev/projects.html)
- The vayu's modem is not a "Snapdragon X55" per anything found; I did not find a source on the vayu modem. See Gaps. (From general knowledge only, not sourced: SM8150-family modem is integrated X24, the X55 is a separate chip paired with 865. Verify before use.)
- Source-quality note: the Android Authority and PBX Science write-ups are secondary; the hackiosx.dev site and the GitHub READMEs are primary but self-reported. One Android Authority page returned HTTP 403 on direct fetch; its content was seen only via search summary. — [Android Authority (via search summary)](https://androidauthority.com/ios-on-android-phones-3726001), [PBX Science](https://pbxscience.com/?p=24278)

### Inferences
- Because Pixel 4 and vayu share SM8150 (vayu is the -AC bin: same die family, higher clocks), the CPU/ISA, GIC-600, 19.2 MHz timer, RPMh, GENI, UFS 3.x host controller and Adreno 640/a6xx GPU work in ios-flame should transfer. The port effort for vayu is therefore mostly board code, probably in the "weeks of work for someone competent, plus firmware extraction" range, rather than a new SoC bring-up. This is my estimate, not sourced.

### Gaps
- No independent confirmation (video, third-party reproduction) of any of the Pixel 4 results was found; only the author's README.
- No source for a vayu-specific XNU attempt. Searched only through search snippets; I did not find an ios-vayu repo.

## What XNU/Darwin expects of the hardware, and what open-source XNU actually contains

### Takeaway
Open XNU (the xnu-8796 iOS 16 generation is what all phone ports use) is configured per-Apple-SoC and hard-errors on unknown SoCs, so every port patches in its own platform layer. The ports run non-PAC arm64 by selecting iPhone X (A11, ARMv8.2, no PAC) identity and iOS 16.x, and replace Apple's AIC with GICv3 and Apple FIQ timers with the ARM generic timer via IRQ.

### Cited Findings
- Page size is a compile-time switch in open XNU: `__ARM_16K_PG__` gives `ARM_PGSHIFT` 14, otherwise 12 (4K). There is a `__ARM_MIXED_PAGE_SIZE__` option for 4K processes on a 16K kernel, which requires `ARM_PARAMETERIZED_PMAP` and is incompatible with `__ARM_KERNEL_PROTECT__`. — [xnu proc_reg.h, xnu-8796.121.2](https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8796.121.2/osfmk/arm64/proc_reg.h)
- The same header selects only Apple SoC families (APPLETYPHOON ... APPLEFIRESTORM, BCM2837, VMAPPLE) and otherwise hits `#error processor not supported`. It gates PAC under `HAS_APPLE_PAC`, uses feature macros such as `__ARM_ARCH_8_5__`, `HAS_ARM_FEAT_SSBS2`, `__ARM_PAN_AVAILABLE__`, `__ARM_SB_AVAILABLE__`, `HAS_E0PD`, and defines Apple-implementation registers and Apple core MIDRs. — [proc_reg.h](https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8796.121.2/osfmk/arm64/proc_reg.h)
- That header does not define an LSE macro (`ARM_LSE` / `__ARM_ATOMICS_8_1__` not found in it); it only has ID register field names for ATOMIC_8_1 etc. So the file alone does not show a hard LSE requirement. (I did not read the rest of the tree for LSE use.) — [proc_reg.h](https://raw.githubusercontent.com/apple-oss-distributions/xnu/xnu-8796.121.2/osfmk/arm64/proc_reg.h)
- `pexpert/arm` at xnu-8796.121.2 shows only pe_bootargs.c, pe_consistent_debug.c, pe_fiq.c, pe_identify_machine.c, pe_init.c, pe_kprintf.c, pe_serial.c. No GIC or generic-ARM interrupt controller file is visible; the open tree has no interrupt controller driver for AIC (Apple's interrupt controller driver lives in closed IOKit/platform kexts), and the page listing might be truncated. — [xnu pexpert/arm](https://github.com/apple-oss-distributions/xnu/tree/xnu-8796.121.2/pexpert/arm)
- xnu's own PAC doc says xnu is built `-arch arm64e` and describes PAC keys being disabled when returning to non-arm64e userspace, i.e. kernel support for plain arm64 userland exists. — [xnu doc/pac.md mirror](https://git.saurik.com/apple/xnu.git/blob/f427ee49d309d8fc33ebf3042c3a775f2f530ded:/doc/pac.md) (older xnu snapshot; secondary summary via search)
- arm64e / PAC arrived with Apple A12 (2018); Apple docs list A12 and later as arm64e devices. — [Apple developer docs](https://developer.apple.com/documentation/security/preparing-your-app-to-work-with-pointer-authentication.md), [Apple Security blog](https://security.apple.com/blog/memory-integrity-enforcement)
- How the ports avoid PAC: they present as an iPhone X (A11, iPhone10,3 / D22AP), use iOS 16.7.16 (last for iPhone X) because iPhone XS and later firmware require PAC / arm64e. ios-sweet applies a "non-PAC arm64" kernel patch set (0001-0009). — [ios-sweet README](https://github.com/dipa-studio/ios-sweet), [hackiosx how-it-works](https://hackiosx.dev/how-it-works)
- hackiosx says iOS 17+ iPhone firmware is arm64e so phone ports stop at iOS 16; iPads (2017 iPad Pro up to iPadOS 17; 7th-gen iPad up to iPadOS 18) use plain arm64, which is why UniXNU used iPad7,1 iPadOS 17.7.11. Chips with PAC (8 Gen 1 and later) could in theory run newer firmware but no project does. — [hackiosx compatibility](https://hackiosx.dev/compatibility.html), [PBX Science](https://pbxscience.com/?p=24278)
- Interrupts and timer on SM7150 (ios-sweet): GICv3 (with security extensions), 19.2 MHz timer, virtual timer INTID 19 delivered as Group 1 IRQ rather than FIQ as on Apple silicon. — [ios-sweet README](https://github.com/dipa-studio/ios-sweet)
- SM8150 / Pixel 4 (ios-flame NOTES): GIC-600, GICD 0x17a00000, GICR 0x17a60000 with 0x20000 stride; timer 19.2 MHz vtimer INTID 19; PSCI 1.1 over SMC (CPU_ON, SYSTEM_RESET; no RESET2/SYSTEM_SUSPEND); MIDR 0x51df805e; 4x A55 + 3x A76 + 1x A76 prime; UFSHCI 3.0; APSS WDT at 0x17c10000 left off by ABL. — [ios-flame NOTES.md](https://github.com/NWylynko/ios-flame/blob/main/NOTES.md)
- Cores: ios-flame runs "all 8 cores (4x A55, 4x A76) at full clock" via PSCI; RPMh is built into the kernel. — [ios-flame README](https://github.com/NWylynko/ios-flame)
- 16K pages vs small cores: hackiosx says "iOS uses 16 KB memory pages everywhere" and that some small CPU cores cannot use them; options are leave them idle or run a 4K kernel (UniXNU, Redmi Note 12 port). The Redmi Note 12 4G (Snapdragon 685) port disables four slower cores for this reason. — [hackiosx porting](https://hackiosx.dev/porting.html), [Gizchina](https://www.gizchina.com/redmi-phones/real-ios-16-now-boots-on-a-redmi-note-12-4g-and-tinkerers-can-try-it)
- UniXNU's kernel is reported as patched to run with 4 KB pages; credits mention "code signature pages on a 4K kernel", a 24 MHz timebase, realtime/mmap fixes. No implementation detail published on the pages fetched. — [hackiosx projects](https://hackiosx.dev/projects.html), [UniXNU repo](https://github.com/UniXNU/UniXNU)
- ISA level: hackiosx says the iPhone X chip is ARMv8.2, some Android chips only ARMv8.0; the kernel must target the older cores and emulate the few newer instructions iOS still uses (documented in the Redmi Note 12 port). The Pixel (2016, 821) port reports iPhone 8 firmware runs on ARMv8.0 with no emulation. — [hackiosx porting](https://hackiosx.dev/porting.html)
- ios-sweet describes SM7150 as "ARMv8.2 without pointer authentication". — [ios-sweet README](https://github.com/dipa-studio/ios-sweet)
- What KTRR/PPL/SPTM does in these ports: not documented in any source I fetched. ios-sweet README does not mention KTRR or PPL.
- Mu-Silicium UEFI is the boot base for HackiOS and UniXNU; ios-sweet/ios-flame use a bare-metal "shim" posing as iBoot via `fastboot boot`, generating an Apple Device Tree from the Linux FDT with `tools/mkadt.py`. — [hackiosx how-it-works](https://hackiosx.dev/how-it-works), [ios-flame README](https://github.com/NWylynko/ios-flame)

### Inferences
- Kryo 485 = Cortex-A76 (prime/gold) + Cortex-A55 (silver), ARMv8.2-A, with dot-product (ARMv8.2-DotProd). It has LSE atomics (ARMv8.1). It lacks PAC and BTI (ARMv8.3 / ARMv8.5), MTE, and the ARMv8.4+ extensions; ARMv8.2 matches the iPhone X's A11 level, so with iOS 16 non-PAC userland there is no ISA gap by that comparison. (General ARM knowledge; the only sourced statement is the ios-sweet README's "SM7150 = ARMv8.2 without PAC" and the ios-flame core list, and A76/A55 = v8.2 is general knowledge not sourced here.) Verify against Arm TRMs.
- "Apple iOS 14-17 userland requires PAC" is false for iPhone X-era (A11) and for iPad7,1 (A10X) images, because those devices have no PAC. The real constraint is that the OS image must be a device that predates A12; this caps the iPhone track at iOS 16.7.x and the iPad track at iPadOS 17.7.x (2017 iPad Pro). iOS 17 and 18 iPhone images are out unless PAC is emulated or the kernel/userland is rebuilt.
- Since open XNU only supports Apple SoCs and the closed Apple IOKit kexts (AIC, AMC, etc.) are absent, every port is a platform-layer rewrite: this confirms the barrier is not "ISA" but "platform glue" (interrupts, timers, storage, power).

### Gaps
- Whether Cortex-A55 (and A76) implement the 16 KB granule (ID_AA64MMFR0_EL1.TGran16). I did not find the TRM statement; the search surfaced only general register docs and A53/A72 results (A72 and A53 reported as not supporting 16K). So whether vayu/SM8150 needs the 4K kernel patch (as in UniXNU) or can use 16K is unresolved. ios-flame README/NOTES did not state its page size. — [Arm sysreg reference](https://df.lth.se/~getz/ARM/SysReg/AArch64-id_aa64mmfr0_el1.html)
- Exact ARMv8.x instruction emulation list required for iOS 16 userland on non-8.2 cores. Not found.
- How KTRR/PPL/SPTM, KERNEL_PROTECT and `__ARM_KERNEL_PROTECT__` are handled in the ports. Not documented in fetched pages.
- LSE atomics requirement in xnu-8796: not verified beyond proc_reg.h.

## Closed-source userland, GPU/Metal and Adreno 640 documentation

### Takeaway
Metal needs an Apple GPU driver stack that does not exist off-Apple, so the ports write a kernel GPU driver per Adreno generation and either translate Metal to Vulkan (metal2vulkan + Mesa Turnip, slow, ~20-57 fps) or translate Metal directly to Adreno PM4 packets (hakios-metal, ~100+ fps on 642L). For SM8150, a Metal-on-Turnip path on Adreno 640 is reported working in ios-flame, with a kernel-side GPU driver already written. Adreno 6xx (a6xx) is well documented by open-source freedreno/Turnip.

### Cited Findings
- ios-flame GPU path: Metal runs on Mesa Turnip via metal2vulkan (`sweetmtl=2`); backboardd, SpringBoard and apps render on the GPU, shaders compile on the phone; swiping home screens runs about 20-26 fps; Today-view widgets fall back to the CPU. Kernel side: patch 0095 adds the A640 core, 0096 adds "SweetAccelerator" (IOAcceleratorES for Metal), 0097 user client, 0115 a v2 user client with a "NativeAdreno" ABI, 0116 SweetMetal2, 0105-0109 VA reuse / page tables / recovery / async submit, 0120 BCM bus/DDR votes over PMEM_RPMH, 0122 DDR/NoC votes at GPU start. — [ios-flame README](https://github.com/NWylynko/ios-flame), [NOTES.md](https://github.com/NWylynko/ios-flame/blob/main/NOTES.md)
- GPU firmware needed: a640 GMU, zap, a630 SQE, extracted from the user's own Pixel 4 vendor image. — [ios-flame README](https://github.com/NWylynko/ios-flame)
- ios-flame credits Metal parts from UniXNU, metal2vulkan and Mesa, and Wi-Fi from ios-topaz and HackiOS. — [ios-flame README](https://github.com/NWylynko/ios-flame)
- HackiOS (POCO X5 Pro, Adreno 642L): OpenGL ES via Mesa freedreno for the window server; separate "hakios-metal" translates Metal directly into Adreno PM4 packets for its kernel GPU driver ("HakiosGPU"), no Vulkan; reported 100-118 fps page swipes vs 50-57 fps for the UniXNU Metal-on-Vulkan path; Metal listed as "Partly" working, GL ES "Yes". — [hakios-web](https://hackios-web.vercel.app/en), [HakiOS README](https://github.com/burdenghost/Hackios)
- UniXNU: native kernel GPU driver for Adreno 740 (SM8550) with Metal translated to Vulkan for Turnip; docs at unixnu.com/drivers/adreno740 (not fetched; UniXNU repo news lists "Adreno740 and AdrenoMetal"). — [hackiosx projects](https://hackiosx.dev/projects.html), [UniXNU repo](https://github.com/UniXNU/UniXNU)
- ios-sweet (SM7150) has no GPU: CPU/CoreAnimation software rendering at about 20-30 fps. — [ios-sweet README](https://github.com/dipa-studio/ios-sweet), [hackiosx how-it-works](https://hackiosx.dev/how-it-works)
- hackiosx notes "Adreno generations differ, so a GPU driver usually needs real work" and "each Adreno generation needs its own work, and Apple's shaders have to be translated". — [hackiosx porting](https://hackiosx.dev/porting.html), [hackiosx future](https://hackiosx.dev/future.html)
- Apple userland is not redistributed: all projects have the user build the root image from an IPSW (iPhone X 16.7.16; HackiOS iOS 16.5 from its README) and extract firmware blobs from the phone's own Android; HakiOS states nothing is downloaded/decrypted/circumvented for the user and Apple services (activation, Apple ID, iCloud, App Store) are non-goals. — [ios-flame README](https://github.com/NWylynko/ios-flame), [HakiOS README](https://github.com/burdenghost/Hackios)
- Licensing: HakiOS says XNU patch and derived files are APSL 2.0 and the rest MIT; ios-sweet is MIT; UniXNU is BSD-2-Clause-Patent. — [HakiOS README](https://github.com/burdenghost/Hackios), [ios-sweet README](https://github.com/dipa-studio/ios-sweet), [UniXNU](https://github.com/UniXNU/UniXNU)
- The Pixel 4 port also lists "Turnip" credit from Mesa; Turnip has a published update on Adreno support (FOSDEM 2024 slides, comparing against proprietary driver on an Adreno 650 device). — [FOSDEM 2024 Turnip update PDF](https://archive.fosdem.org/2024/events/attachments/fosdem-2024-2033-turnip-update-on-open-source-vulkan-driver-for-adreno-gpus/slides/22737/Update_on_Open_Source_Vulkan_Driver_for_Adreno_gqrqgmC.pdf)

### Inferences
- Adreno 640 is a6xx, the best-documented generation in open source (freedreno/Mesa, Turnip supports a6xx; register headers are in Mesa). Since ios-flame already has an A640 kernel core, `NativeAdreno` ABI and Turnip path on exactly this GPU, vayu's GPU is very likely a drop-in as far as the GPU goes. (Mesa a6xx coverage is general knowledge; only the FOSDEM deck is a cited tie-in, and it did not address the A640.)
- Performance: Metal-on-Turnip on a640 is reported at 20-26 fps, versus the same translation at 41-57 fps on UniXNU's 740/642L runs. HakiOS's direct-PM4 path looks to be roughly 2x faster, but is only shown on the 642L (SM7325). Expected vayu experience on the Vulkan path is closer to the Pixel 4 numbers, i.e. janky, unless hakios-metal is back-ported to a640. (Inference from different devices and resolutions, not a like-for-like.)
- The iOS userland (SpringBoard, backboardd, mediaserverd, wifid) remains closed and unmodified; the gap is filled by kernel-side shims (AppleKeyStore stub, AMFI stand-in, IOAccelerator clients) plus a few userland helpers (wland for Wi-Fi). That is the whole design: "pretend to be an iPhone X".

### Gaps
- No Adreno 6xx register/ISA documentation was fetched directly (freedreno docs, Mesa a6xx.xml); I only found the Turnip FOSDEM deck. Report writer should treat "a6xx is well documented" as general knowledge, not a cited finding.
- No source for hakios-metal being portable to a640, nor for how hard the a6xx-specific shader translation is.
- No data on hardware video decode (none works: HEIC/HEVC unsupported in ios-flame).

## Other XNU-on-non-Apple projects (QEMU, Corellium, PureDarwin, Darling)

### Takeaway
There is a long public lineage of running iOS/XNU kernels in QEMU (Zhuowei, Aleph Security, later QEMU-AppleSilicon for T8030 iPhone 11), but these emulate Apple hardware (Apple device tree, SEP ROM); the Android ports are different in that they run real XNU on real non-Apple SoCs with an iBoot-imitating loader. Little was gathered on PureDarwin, Darling and Corellium internals, and none of those is a viable route to a Snapdragon phone.

### Cited Findings
- Zhuowei (Worth Doing Badly) built a modified QEMU booting an iOS kernel; Aleph Security / Jonathan Afek extended it to iOS 12.1 on an emulated iPhone 6s Plus reaching a bash shell. Early workflows needed kernelcache decoding (ASN.1 wrapper, then decompression). — [Aleph part 1](https://alephsecurity.com/2019/06/17/xnu-qemu-arm64-1/), [Black Hat EU 2019 paper](https://papers.put.as/papers/ios/2019/eu-19-Afek-Booting-The-iOS-Kernel-To-An-Interactive-Bash-Shell-On-QEMU-wp.pdf), [Zhuowei](https://worthdoingbadly.com/xnuqemu3/)
- Zhuowei reports QEMU supported PAC instructions but Apple's modified PAC algorithm broke boot, so he disabled PAC in QEMU. — [worthdoingbadly.com](https://worthdoingbadly.com/xnuqemu3/) (as relayed by search summary; not read in full)
- iPhone 11 (T8030) emulation with QEMU-AppleSilicon runs iOS 14.0 beta 5 and requires SEP firmware and SEP ROM images; a commenter says it runs sepOS on top. — [NixOS wiki iOS Emulation](https://wiki.nixos.org/wiki/IOS_Emulation), [HN](https://hn.svelte.dev/item/44258670)
- eShard documented emulating iOS 14 with QEMU. — [eShard](https://www.eshard.com/blog/emulating-ios-14-with-qemu)
- HakiOS also runs the same kernel on QEMU virt (no Apple/phone components) via `make qemu-open`; the userland boots there slowly with no GPU. — [hackios-web](https://hackios-web.vercel.app/en), [HakiOS README](https://github.com/burdenghost/Hackios)
- UniXNU describes itself as an OpenCore-like UEFI environment and driver loader with a device-tree platform, XNU patches and a bootable image build, with SoC repos (e.g. UniXNU-sm8550-common) and device repos (UniXNU-sheng). Repo shows 3.1k stars, 1,065 commits. — [UniXNU repo](https://github.com/UniXNU/UniXNU), [unixnu.com](https://unixnu.com)
- UniXNU credits "macOS-DroidVM" for macOS 27 kernel patches (4K code-signature pages), implying a macOS track exists too; unverified. — [UniXNU repo](https://github.com/UniXNU/UniXNU)

### Inferences
- The "XNU on QEMU virt (OpenCore-style)" that the brief mentions is best matched by UniXNU's UEFI approach and by HakiOS's QEMU target. QEMU is the right place to debug kernel-side patches before touching the phone.

### Gaps
- Nothing fetched on Project Corellium Sandcastle internals beyond the news level, on PureDarwin, or on Darling. These are not on a route to a phone port, so no further effort was spent. Marking as "not researched".
- Where kernel/userland binaries come from legally: only the projects' own statements (user supplies IPSW; Apple code not redistributed). No legal analysis found.

## SEP, secure boot, AMFI, code signing, and non-GPU peripherals

### Takeaway
All ports run with no SEP: AMFI is replaced with a permissive stand-in, AppleKeyStore is a stub (no data protection), and Apple services (App Store, activation, FairPlay) are out of scope. Wi-Fi works via Linux-driver ports or userland daemons on Qualcomm; Bluetooth and cellular do not work in any project.

### Cited Findings
- ios-sweet: AppleKeyStore stub (patches 0035-0045, "no data protection"), minimal AMFI (0021-0027), permissive code signing, `launchd_unsecure_cache=1`; no SEP/Face ID; trustcache not mentioned. — [ios-sweet README](https://github.com/dipa-studio/ios-sweet)
- ios-flame adds an AMFI stand-in answering trust cache queries (0103) and dyld policy query (0114) so third-party @rpath frameworks load; an ad hoc-signed third-party IPA (YouTube) launches. — [ios-flame NOTES.md](https://github.com/NWylynko/ios-flame/blob/main/NOTES.md), [README](https://github.com/NWylynko/ios-flame)
- "Newer firmware... Apple's security model is largely disabled: permissive AMFI and sandbox, and a stub keystore." — [ios-flame README](https://github.com/NWylynko/ios-flame)
- App Store and Apple ID depend on FairPlay and the Secure Enclave, "the hardest category", may never fully work. — [hackiosx future](https://hackiosx.dev/future.html)
- hackiosx's how-it-works: HackiOS's library reports the device as activated to SpringBoard; the key store is a small stand-in; the page warns against storing personal data. — [hackiosx how-it-works](https://hackiosx.dev/how-it-works)
- Wi-Fi: ios-flame uses WCN3990 (Pixel 4's chip) driven by userland `wland`; scan, WPA2-PSK, join at boot, Settings integration with wifid and iOS DHCP. HackiOS runs Linux ath11k on a FreeBSD LinuxKPI-based layer (SM7325/WCN6750-class, my inference); Pixel (2016) wrote its own QCA6174 driver. "Every Wi-Fi chip family needs its own driver." — [ios-flame README](https://github.com/NWylynko/ios-flame), [hackiosx how-it-works](https://hackiosx.dev/how-it-works), [hackiosx future](https://hackiosx.dev/future.html)
- Bluetooth: no project has it; Apple's stack expects an Apple-like controller and often shares firmware with Wi-Fi. Modem: "No project handles calls, texts or mobile data" (HakiOS marks Cellular "Partly" in its own table, which conflicts slightly with hackiosx's "no project handles ..."). — [hackiosx future](https://hackiosx.dev/future.html), [hakios-web](https://hackios-web.vercel.app/en)
- Other open items across ports: no real suspend/resume, battery readings wrong, heat/no thermal management, no HW video decode (HEIC/HEVC fail), sensors/GPS not working. — [hackiosx future](https://hackiosx.dev/future.html), [ios-flame README](https://github.com/NWylynko/ios-flame)
- Wi-Fi firmware, modem partitions (modemst/fsg/fsc), GPU firmware are taken from the user's own Android install. — [ios-flame README](https://github.com/NWylynko/ios-flame)

### Inferences
- Expected level on vayu if someone follows ios-flame: boot via `fastboot boot` into an iPhone X identity, SpringBoard on Metal/Turnip (~20 fps), touch, UFS, USB Ethernet/SSH, Wi-Fi probably (needs vayu's WCN399x variant supported by wland; the Pixel 4 uses WCN3990, and vayu's chip was not confirmed here). Not expected: cellular (Qualcomm modem/QMI stack is not an Apple baseband; no project has it), Bluetooth, audio, camera, sensors, sleep, App Store/Apple ID.
- The iOS 16.x (non-PAC) cap is the practical ceiling; keychain-dependent features run on a stub.

### Gaps
- vayu Wi-Fi/BT chip: the user cited WCN3998. I could not confirm this from a source, nor whether `wland` supports it (it is built for WCN3990).
- vayu touch controller and display panel details: postmarketOS lists Huaxing/CSOT and Tianma panel variants for vayu (two variants means board code must handle two panels), but I did not find the touch controller. — [postmarketOS wiki via search snippet](https://wiki.postmarketos.org/wiki/Xiaomi_POCO_X3_Pro_(xiaomi-vayu)) (page redirected to wiki.nura.eco and then returned a bot-block page; unfetched).
- Whether Xiaomi vayu's bootloader can be unlocked and use `fastboot boot` in 2026 (Xiaomi unlock policy): not researched.
- No source on the vayu's storage type (UFS 2.1 vs 3.1) and variants; Pixel 4 is UFS 3.0.

## SM8150 (vayu) vs the SoCs of reported successes

### Takeaway
By hackiosx's own compatibility ranking, SM8150 sits in the "Good" tier (Snapdragon 2018+ chips share the interrupt controller type, RPMh and I2C/GENI blocks with the 732G/778G), and there is a direct SM8150 precedent in Pixel 4. The most similar working port to vayu is ios-flame; the closest ISA match is the "Best" tier ios-sweet (SM7150, also A76+A55, ARMv8.2, GICv3), except that SM7150 uses a different (A55-only in practice) core arrangement. UniXNU's Snapdragon 8 Gen 2 is a different class: newer GPU (a740, own driver), 4K-page kernel, and its GPU/display/UFS support was written from scratch.

### Cited Findings
- hackiosx compatibility ranking: SM7325 (778G) "Best (HackiOS base)"; SM7150 (730/732G) "Best (ios-sweet base)"; Snapdragon 845/855/865/870/888/8 Gen 1-3 "Good: shares same interrupt controller type, RPMh power controller and I2C serial engines; mostly config changes; Pixel 4 (855), LG V60 (865), POCO M8 show it works; 8 Gen 1 and later change a few blocks such as a newer PMIC bus"; older/budget (820/821/835/625/636/660/662/665/680/685) "Possible", older RPM power controller, older I2C block, eMMC, ARMv8.0 cores. — [hackiosx compatibility](https://hackiosx.dev/compatibility.html)
- Poco X5 Pro (HackiOS): SM7325, Adreno 642L, all 8 cores, UFS supported; works: lock/home screens, multitouch, Wi-Fi + Safari, speakers, mic, cameras, Sileo/Procursus; missing: cellular, BT, charging while iOS runs, Metal for apps, video recording. System image ~2.5 GB loaded in RAM over USB, so 6 GB+ RAM is the safe target. — [hackiosx projects](https://hackiosx.dev/projects.html), [hackiosx compatibility](https://hackiosx.dev/compatibility.html)
- Xiaomi Pad 6S Pro (UniXNU, SM8550): Adreno 740 native driver, Metal over Vulkan/Turnip, 4K-page kernel, iPadOS 17.7.11 iPad7,1 userland; works: home screen, Settings, GPU, touch, display, UFS; missing: Wi-Fi, BT, USB, audio, camera, sensors, battery driver, sleep/wake. "Lab prototype, not a usable iPad replacement." — [hackiosx projects](https://hackiosx.dev/projects.html), [PBX Science](https://pbxscience.com/?p=24278)
- ios-sweet SM7150 (732G): per README, 2 A76 cores unused, 6x A55 used, ~3.95 GiB RAM from the upper bank, CPU rendering, Goodix GT9896 touch on I2C; boot ~4 min; Wi-Fi/BT/audio/camera not working. — [ios-sweet README](https://github.com/dipa-studio/ios-sweet)
- Pixel 4 (SM8150): GICv3 (GIC-600), UFS 3.0, command-mode DSC panel (NT37280, 1080x2280) with ABL autorefresh, ST FTS touch on GENI SPI, PM8150 RTC, DWC3 USB, ABL watchdog left off; 6 GB RAM; needs the LZ4-compressed kernel with verification footer. — [ios-flame NOTES.md](https://github.com/NWylynko/ios-flame/blob/main/NOTES.md), [hackiosx porting](https://hackiosx.dev/porting.html)
- Pixel 4 has a command-mode panel that only updates when told to, Pixel 6a starts the shim at EL2. Different bootloaders: some silently drop older boot-image formats, some start a hardware watchdog. — [hackiosx porting](https://hackiosx.dev/porting.html)
- Of 81 kernel patches in the Pixel 6a port, ~66 generic, ~10 address-only, 5 Qualcomm hardware drivers; ios-sweet's board patches cover keys/touch/screen/USB. — [hackiosx porting](https://hackiosx.dev/porting.html)
- vayu per postmarketOS: SM8150-AC (Snapdragon 860 label), Adreno 640, two panel variants (Huaxing/CSOT and Tianma), active Phosh/kernel packages. — [postmarketOS packages](https://pkgs.postmarketos.org/package/main/postmarketos/aarch64/device-xiaomi-vayu-phosh), [postmarketOS wiki via search](https://wiki.postmarketos.org/wiki/Xiaomi_POCO_X3_Pro_(xiaomi-vayu))

### Inferences
- Comparison table, from the above (the HakiOS-family claims apply unless stated; "?" = not found in sources):

| | vayu SM8150-AC | Pixel 4 SM8150 (ios-flame) | Pad 6S Pro SM8550 (UniXNU) | Poco X5 Pro SM7325 (HackiOS) | Redmi Note 10 Pro SM7150 (ios-sweet) |
|---|---|---|---|---|---|
| CPU | 4xA55 + 3xA76 + 1xA76 prime (Kryo 485 is A76-class per brief; same layout as Pixel 4 per NOTES) | same | newer Arm cores (not sourced) | not sourced here | 6xA55 + 2xA76 |
| Page size | unresolved (16K support on A55 unconfirmed) | not stated | 4K kernel patch | not stated | "16K pages" row |
| GIC | GIC-600 (GICv3), expected | GIC-600 | not stated | GICv3 type implied | GICv3 |
| GPU | Adreno 640 | Adreno 640, Metal via Turnip | A740 native driver + Turnip | A642L, hakios-metal / GLES | none (CPU) |
| Storage | UFS (version not sourced) | UFS 3.0 | UFS | UFS | UFS |
| Wi-Fi | WCN399x? (unconfirmed) | WCN3990 via wland | not working | ath11k via LinuxKPI | not working |
| PAC | no | no | newer than vayu | no | no |

- Easier for vayu than the others: a direct ios-flame precedent on the same SoC; GPU (a640) already has kernel/Turnip support there; the older, well-documented a6xx is more tractable than an unreleased a7xx; RAM 6/8 GB matches the sourced "6 GB+" guidance.
- Harder for vayu: (1) Xiaomi vayu has two display panel variants and its own touch IC, so board code (panel init: probably command-mode, DSC, ABL-initialized; touch driver, possibly Focaltech/Goodix, unconfirmed) is new work; (2) Xiaomi bootloader unlock policy and ABL behaviour (watchdog, `fastboot boot` acceptance, boot image header version) differ from Pixel's ABL; (3) Wi-Fi chip variant (WCN3998 vs WCN3990) needs checking; (4) Pixel 4 firmware blobs come from the Pixel factory image whereas vayu needs Xiaomi vendor firmware (a640 GMU/zap/SQE should match, but verify); (5) the unknown 16K/4K page-size situation on A55.
- Realistic expected level on vayu, if someone ports ios-flame: booting to SpringBoard with touch and UFS root appears feasible (reported done on the identical SoC); GPU-accelerated Metal at about 20-26 fps (Pixel 4 figure); Wi-Fi plausible; not realistic: cellular (a Qualcomm modem with no Apple baseband stack; none of the ports has it), Bluetooth, camera, sound, sleep, battery readout, App Store/Apple ID/iCloud, hardware video decode, iOS 17+ on iPhone images. UniXNU (the project named in the title) currently documents only SM8550; no SM8150 repo was found.

### Gaps
- Whether the A55/A76 in SM8150 can use 16K pages (see above); ios-flame did not say if it uses 16K or 4K.
- No verification of whether ios-flame boots on vayu; no vayu port was found.
- vayu UFS version, touch IC, exact Wi-Fi chip and modem: not confirmed from sources.
- UniXNU's own Adreno-driver documentation page (unixnu.com/drivers/adreno740), "Technical reference" and "Port a device" sections were not fetched (the unixnu.com landing page had no technical content). A follow-up fetch of those subpages could tell whether UniXNU's 4K patch/Adreno driver is reusable on a640.
- No source on SM8150's closed-firmware dependencies beyond GPU (GMU/zap/SQE) and Wi-Fi/modem partitions.
