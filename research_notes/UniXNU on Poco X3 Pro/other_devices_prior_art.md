# XNU / iOS / macOS on non-Apple hardware: Xiaomi/Poco devices and prior art (as of 2026-11-24)

Method note: ~19 tool calls, WebSearch + WebFetch only (WebFetch output is a small-model summary of each page, not raw text; androidauthority.com returned HTTP 403, so its content is known only through search-engine summaries). No access to X/Telegram/Weibo/XDA/Reddit directly. Labels: [VERIFIED-PRIMARY] = read on the project's own repo/site; [PRESS-ONLY] = only secondary coverage; [SELF-REPORTED] = project's own claim, no independent confirmation seen.

## 1. HackiOS (OOSexGang): who, what was shown, what works, code, verification

### Takeaway
HackiOS/HakiOS is a real, now-public GitHub project (oosexgang/hakios-xnu-kernel, ~2.9k stars) by an anonymous-ish group "OOSexGang". It began as video-only demos (mid-Oct 2026) and source appeared around late Oct 2026. The original "iOS 16.5 / xnu-8796.121.2 on Poco X5 Pro" claim is [SELF-REPORTED], with no confirmed third-party hardware reproduction found. The project has since moved on to Darwin 26/27 (xnu-12377). Early press (Oct 18) saying "no code" is now outdated.

### Cited Findings
- Group is OOSexGang (OOSEX GANG), described as an independent research project not affiliated with Apple. The kernel is Apple's open-source XNU `xnu-8796.121.2` (iOS 16.5) with a custom EFI loader, custom replacements for Apple's closed drivers, a UEFI port, and a Wi-Fi compatibility layer using Linux Wi-Fi drivers; unmodified iOS 16.5 userspace booted through launchd, backboardd, SpringBoard, apps; Adreno GPU rendering (gpu=1) claimed. — [Hakky Handbook, 2026-10-22 (AI-generated summary, site itself says verify against originals)](https://book.st-hakky.com/en/news/run-ios-16-5-firmware-on-android)
- Boot method: UEFI launched with `fastboot boot`, loaded entirely into RAM, no flash writes, run for a fixed time then returns to loader; reboot returns to Android. Repo contains no Apple files; `ios165/fetch.sh` downloads the iOS 16.5 IPSW from Apple CDN; `prebuilt/` holds kernel/loader. Described as a "research bench, not a ROM". Alternate path: QEMU `virt` aarch64 on x86-64 Linux (~12 GB disk, 4 GB RAM). — [Hakky Handbook](https://book.st-hakky.com/en/news/run-ios-16-5-firmware-on-android)
- Devices: POCO X5 Pro 5G (redwood, Snapdragon 778G) is the official/first beta target; Xiaomi Mi 11 Lite 5G (renoir) was the second demo device; stated goal of at least five Snapdragon models. Demo "About" screen reported the model as "iPhone X". — [Pasquale Pillitteri, 2026-10-18](https://pasqualepillitteri.it/en/news/25375/hackios-ios-xiaomi-poco-no-code)
- Timeline per that article: viral X thread by @ErenCaner on 2026-10-17; claimed partial GPU accel by Oct 13; Wi-Fi, audio, vibration, flashlight, camera image (with colour problem) by Oct 16; home screen, widgets, keyboard, Safari/YouTube claimed; App Store, Apple services and Metal absent per team. Evidence: videos on X (@hacki_os) and Telegram (t.me/oosexgangdevs, ~10k subs); "no public code, no installable build, no independent test"; promised open-source release after "code cleanup". — [Pasquale Pillitteri](https://pasqualepillitteri.it/en/news/25375/hackios-ios-xiaomi-poco-no-code)
- Named developer rumour: Kocpc (Taiwan) profiles "電腦王阿達" with 21 repos of Android kernel/firmware work incl. a Mi 11 Lite 5G one (plausible background, doesn't prove iOS progress). Unconfirmed rumour that ~$2,000 of Claude credits wrote the code; Telegram mentions crypto donations for "ai agents". Team disowned a meme coin and a TikTok "iOS 27 on Mi 11" fake. — [Pasquale Pillitteri](https://pasqualepillitteri.it/en/news/25375/hackios-ios-xiaomi-poco-no-code) (press-only, rumour)
- Repo now exists: README of `oosexgang/hakios-xnu-kernel` (as summarised by WebFetch) says XNU `xnu-12377.121.6` (Darwin 26/27), custom loader/drivers/stand-ins for Apple closed components, targets Qualcomm phones and QEMU; Darwin 27.2 (24B119) home screen on phone from RAM, software-drawn (`gpu=0`); Darwin 26.6.2 (23G90) home screen on same phone first reached 31 Oct 2026; QEMU reaches lock screen; Bluetooth (`bt=2`), kernel UFS driver, single-image-per-phone are "new, not yet seen on a phone"; GPU-drawn content (icons, Liquid Glass) not working with GPU off. README states "seen on a phone", "runs in QEMU", "passes host tests" are three different claims. Darwin files come from user-supplied iPhone12,1 IPSW. Licence MIT + APSL 2.0 for XNU extensions. Stats seen: 2.9k stars, 501 forks, 2,387 commits on `common`. — [GitHub README](https://github.com/oosexgang/hackios-xnu-kernel) [VERIFIED-PRIMARY existence; details via summariser]
- Oddity: that README summary calls the main test device a "Snapdragon 780G phone" (Poco X5 Pro is normally 778G); could be summariser error or README wording. Not resolved.
- hackios.net (self-described unaffiliated verification site; checked 2026-11-05 per its page) says: project now named HakiOS; source on GitHub published late Oct 2026; "an independent community has reproduced it" (unnamed, [SELF-REPORTED]); POCO X5 Pro 5G (redwood) official; lock screen, home screen, built-in apps, touch, GPU, Wi-Fi, sound, camera work; Bluetooth not working, cellular partial, Metal partial; around 2026-11-22 team announced U-Boot-based UEFI enabling dual boot without PC plus developer portal; separate in-progress MediaTek Helio kernel; no official download package, fake downloads/scams circulate; official refs are the oosexgang GitHub org and Telegram. — [hackios.net](https://hackios.net)
- Japanese report (via search summary): first beta covers only Poco X5 Pro; no cellular/Bluetooth, can't charge while running, no Secure Enclave (no Apple ID / App Store content). — [search summary citing smhn.info](https://smhn.info/202610-hackios-runs-ios-on-android-poco-x5-pro) (not fetched; weak)
- Hacker News thread "HackiOS - Run iOS 16.5 user space on Android phones": only 8 of 192 comments visible; none on PAC/16K/AIC/GPU; no independent verification visible; some commenters report/say it runs on QEMU and POCO X5 Pro. — [zeli.app mirror](https://zeli.app/story/50196718)
- Press with no independent test: Decrypt/KuCoin flash ("Hackers run iOS on Android phones for the first time"); Decrypt says no public source / independent verification. — [Decrypt](https://decrypt.co/381351/hackers-running-apple-ios-android-phones), [KuCoin](https://www.kucoin.com/news/flash/hackers-run-ios-on-android-phones-for-the-first-time) (snippets only)
- pbxscience (UniXNU article, dated Oct/Nov 2026 inconsistently) repeats "HackiOS: videos only, no code" — stale vs repo existence. — [pbxscience](https://pbxscience.com/?p=24278)

### Inferences
- Credibility ladder: demo video (Oct 17) < repo with host tests and explicit "seen on phone" vs "QEMU" vs "host test" labelling (Nov). The README's honest tiering is a good sign, but I found no named independent reproduction; "community reproduced" claim comes from a site tied to the same ecosystem.
- Claimed progress speed (weeks) plus rumour of heavy LLM-assisted development is plausible given XNU is open source and that iOS userland is just Apple's IPSW; it also suggests code quality/stubbing (AMFI stand-in, fake keystore) rather than faithful hardware support.
- Kernel version in headline claim (xnu-8796) is out of date relative to the current repo (xnu-12377); anyone citing "iOS 16.5" is citing the Oct demo.

### Gaps
- Original X/Telegram posts not accessed. No independent third-party video/log of a Poco X5 Pro or Mi 11 Lite 5G boot found. Mi 11 Lite 5G (renoir) working status is unconfirmed (only demo mention). Exact SoC of main test phone (778G vs "780G" in README summary) unresolved. Repo commit dates/contributors not seen.

## 2. Other Xiaomi/Poco/Redmi devices reported (UniXNU, ios-topaz/ios-sweet, K90 Pro Max, others)

### Takeaway
At least four Xiaomi-family devices have claims: Poco X5 Pro (HackiOS), Xiaomi Pad 6S Pro (UniXNU, best documented), Redmi Note 12 4G "topaz" (ios-topaz), Redmi Note 10 Pro "sweet" (ios-sweet), plus Redmi K90 Pro Max (UniXNU-related, thin evidence). Maturity ranges from "shows SpringBoard/home screen" to "display+touch+UFS+GPU", none is daily-usable.

### Cited Findings
- Xiaomi Pad 6S Pro (sheng, SM8550 / Snapdragon 8 Gen 2, Adreno 740): UniXNU, "independent open-source project to run iOS and macOS on non-Apple ARM64 hardware through UEFI", OpenCore-like; repo shows 3.1k stars, 1,065 commits, BSD-2-Clause-Patent; no authors listed; "UniXNU-sheng" with uefi-sheng firmware; macOS 27 profile borrows kernel patches from "macOS-DroidVM" (incl. code-signature pages on a 4K kernel). — [github.com/UniXNU/UniXNU](https://github.com/UniXNU/UniXNU) [VERIFIED-PRIMARY]
- UniXNU device page for sheng: device-verified = keyboard, Bluetooth, USB; "implemented" = display, input, GPU, network, audio, power, storage etc.; planned = arm64e-os; many items "not yet run on hardware" (esp. macOS 27.3); default profile iPadOS 27.0.1 (24A446), overrides 26.5.2 (23F84) and 17; boots via `fastboot boot` (Android boot header v0), SEC arms 30 s Gunyah watchdog; GIC (distributor 0x17100000, redistributors 0x17180000) used, AIC not mentioned; arm64e kernel relinking handled 103,192 fixups and re-signs vtable slots (PAC) using discriminators from the 24A446 kernelcache; known issues: pointer hitching, touchpad dead spells, no accelerometer, fixed backlight, no suspend/resume, one macOS GPU hang. Page text 231k chars; only first 100k read. — [unixnu.com/devices/sheng](https://unixnu.com/devices/sheng) [VERIFIED-PRIMARY, partial]
- pbxscience's older status table: display, touch, UFS, GPU compositing (native Metal via NativeMetal -> metal2vulkan AIR->SPIR-V -> Mesa Turnip -> NativeAdreno kernel driver) working; Wi-Fi, BT, audio, camera, USB, sensors, battery, suspend not available; used unmodified iPadOS 17.7.11 (iPad7,1); XNU patched for 4 KiB pages; UEFI from Mu-Silicium; ~40-43 s shader compile on cold boot; "lab prototype". This table is stale/conflicts with the project's own page (which now lists Bluetooth and USB as device-verified, and newer iPadOS 27). — [pbxscience](https://pbxscience.com/?p=24278)
- Redmi Note 12 4G (topaz/tapas, Snapdragon 685), "ios-topaz": xnu-8796-era XNU with iPhone X firmware userland, real launchd/daemons/SpringBoard, home screen in ~3 minutes, Settings shows iOS 16.7.16 / iPhone X; four slower cores disabled because they can't do 16K pages; touchscreen + volume keys work, calls/data/camera unconfirmed; open source but repo link not given; built via fastboot from Linux PC, kernel builds on GitHub macOS runners with Xcode 15; also runs Windows 11 ARM on same phone; sources cited: Weibo, OneJailbreak, IT Home; a Telegram claim of OnePlus Ace 6T port unconfirmed. Dated 2026-10-19. — [Gizchina](https://www.gizchina.com/redmi-phones/real-ios-16-now-boots-on-a-redmi-note-12-4g-and-tinkerers-can-try-it) [PRESS-ONLY]
- Redmi Note 10 Pro "ios-sweet": Android Authority (Oct 21, 2026) reportedly describes iOS 16.7.16 running without emulation by spoofing iPhone X drivers with custom XNU; early demos lacked Wi-Fi, mobile data, audio, camera, GPU accel. Note: Gizchina's article is about topaz, AA's about sweet; related/same author lineage not established. — [Android Authority](https://androidauthority.com/ios-on-android-phones-3726001) [PRESS-ONLY; page returned 403, seen only via search summary]
- Redmi K90 Pro Max: developer Jiang Ling Xia Cao (@jlxc2001) showed iOS 17; GPU rendering, multi-core, 120 Hz, USB claimed; cameras, buttons, modem, speakers don't work; Wi-Fi/brightness/IPA install future; source said to come via UniXNU repo (not yet at article time); article doesn't give SoC or kernel evidence. — [XimiTime, 2026-10-29](https://ximitime.com/ios-17-successfully-ported-to-redmi-k90-pro-max-101538/); [GIGA, 2026-10-30](https://www.giga.de/tech/entwickler-hat-ein-xiaomi-handy-in-ein-iphone-verwandelt--01M65TBTKDB4MQ19YS2083VAEW) [PRESS-ONLY / SELF-REPORTED]
- Xiaomi Pad 6S Pro also has mainline-Linux (postmarketOS, DT patch v6) support, making it a convenient base. — [postmarketOS wiki](https://wiki.postmarketos.org/wiki/Xiaomi_Pad_6S_Pro_12.4_(xiaomi-sheng)), [patchew](https://patchew.org/linux/20260721153444.423-1-code._5F0002@163.com/)

Device table (state claimed):
| Device | SoC | Project | State | Evidence quality |
|---|---|---|---|---|
| Poco X5 Pro (redwood) | SD 778G | HackiOS/HakiOS | home screen, touch, Wi-Fi, GPU(partial), sound, camera (claimed) | repo + self-reported; no named independent repro |
| Mi 11 Lite 5G (renoir) | SD 780G (stock spec) | HackiOS demo | demo mention only | video, unconfirmed |
| Xiaomi Pad 6S Pro (sheng) | SM8550 | UniXNU | display/touch/UFS/GPU/BT/USB per project docs | repo + docs, best documented; no independent repro seen |
| Redmi Note 12 4G (topaz) | SD 685 | ios-topaz | SpringBoard in ~3 min, touch | press-only (Gizchina), no repo link |
| Redmi Note 10 Pro (sweet) | SD 732G (stock spec) | ios-sweet | boots iOS 16.7.16; no Wi-Fi/audio/camera/GPU early | press-only via search summary |
| Redmi K90 Pro Max | not stated | UniXNU-related | iOS 17 display, 120 Hz, USB | press-only |

### Inferences
- Pattern: the same stack (UEFI/Mu-Silicium-style firmware via `fastboot boot` -> custom XNU loader -> IPSW userland from Apple) is being re-used across projects; SoC family (Snapdragon) matters less than a mainline-style DT/ACPI and an unlocked bootloader.
- Snapdragon 685 port ran with only some cores (16K-page limitation), indicating 16K-pages is a per-core hardware issue, not just software.
- Cross-project claims (K90 Pro Max releasing via UniXNU repo) suggest UniXNU is an umbrella; relationship between UniXNU and HackiOS is not established (separate groups per pbxscience).

### Gaps
- Original posts (Weibo, X, Telegram, OneJailbreak) not fetched. No ios-topaz/ios-sweet repo URLs confirmed. SoCs for sweet/K90 not confirmed from sources read. Relationship between ios-topaz, ios-sweet and UniXNU unknown.

## 3. Historical prior art and reusable components

### Takeaway
Direction of travel before 2026 was mostly the reverse (Linux/Android on Apple hardware: Sandcastle, Asahi) or compat layers (Darling) or full virtualization (Corellium). The 2026 efforts are the first widely reported attempts to boot open-source XNU natively on non-Apple ARM phones. I could not verify QEMU-iOS, PureDarwin, or OpenCore-ARM specifics from sources in this session.

### Cited Findings
- Project Sandcastle (Corellium, March 2020): Android 10 ("Sandcastle AOSP") + Linux dual-booted on iPhone 7 / iPod touch 7 via checkm8/checkra1n; not persistent, reboot returns to iOS; code on GitHub; released amid Apple v. Corellium lawsuit. — [TechSpot](https://www.techspot.com/news/84289-project-sandcastle-revives-dream-running-android-iphone.html), [AppleInsider](https://appleinsider.com/articles/20/03/04/corellium-exploits-ios-jailbreak-to-install-android-on-iphone), [github.com/corellium/projectsandcastle](https://github.com/corellium/projectsandcastle)
- Sandcastle bring-up lessons: developed first in Corellium VMs of the SoC; wrote drivers for UART, SPI, I2C, AIC interrupt controller; had to build FIQ timer support in AArch64 Linux; cores require 16 kB pages; second-core boot-address register write-once; NVMe via DART IOMMU quirks (NVMMU); Android assumes 4 kB pages in many places; touch/WiFi firmware read from APFS needing a driver. Reusable: those drivers and APFS driver extensions. VM models were subtly wrong vs real HW. — [projectsandcastle.org/history](https://projectsandcastle.org/history)
- Darling: free macOS compatibility layer for Linux (Wine-like); kernel part is a modified XNU (APSL) wrapped as a GPL Linux kernel module; strong for CLI, very limited GUI; not hardware boot. — [Wikipedia](https://en.wikipedia.org/wiki/Darling_(software)), [darlinghq.org](https://darlinghq.org/)
- macOS-DroidVM is referenced by UniXNU's README as a source of 4K-kernel patches. — [UniXNU README](https://github.com/UniXNU/UniXNU) (no separate source found; unverified beyond that mention)
- Corellium's virtual device model approach (VM-first development) is cited as a lesson. — [projectsandcastle.org/history](https://projectsandcastle.org/history)
- HakiOS runs on QEMU `virt` aarch64 as a CI/dev target, and its README ties tiers of evidence to QEMU vs device vs host tests. — [GitHub](https://github.com/oosexgang/hakios-xnu-kernel)

### Inferences
- Reusable components: open-source XNU releases (xnu-8796 / xnu-12377 trees), UEFI firmware ports (Mu-Silicium, U-Boot), QEMU `virt` as reference platform (GIC, no AIC), Sandcastle's approach of fixing page size/FIQ/AIC assumptions in the opposite direction.
- AIC emulation not needed on Snapdragon: UniXNU uses GIC; iOS kernel expects Apple's AIC, so a GIC shim/stand-in driver is required (the Sandcastle AIC driver is Linux-side, not directly reusable).

### Gaps
- Not covered by sources found: QEMU iOS emulation projects (e.g. community qemu-ios), PureDarwin status, OpenCore on ARM, macOS-on-Snapdragon attempts, Asahi specifics. Darling AI-assistance (Phoronix) only seen as a headline.

## 4. Android community (XDA / Telegram / GitHub): vayu / sm8150 / Snapdragon 855/860

### Takeaway
Found no evidence of any XNU/iOS/Darwin attempt for Poco X3 Pro (vayu, SM8150-AC / Snapdragon 860) or other SM8150/msmnile devices. All results were Android/Linux support pages.

### Cited Findings
- Searching "Poco X3 Pro vayu SM8150 XNU iOS Darwin boot" returned only LineageOS, e/OS, PixelExperience, postmarketOS and kernel pages; none mention iOS/XNU/Darwin. Poco X3 Pro is SM8150-AC (Snapdragon 860), Adreno 640; postmarketOS lists xiaomi-vayu with a WIP sm8150 kernel fork; LineageOS officially supports it (18.1 to 22.2). — [LineageOS vayu](https://wiki.lineageos.org/devices/vayu/), [postmarketOS wiki](https://wiki.postmarketos.org/wiki/Xiaomi_POCO_X3_Pro_(xiaomi-vayu))
- Community channels: HackiOS Telegram t.me/oosexgangdevs (~10k subs); hackios.net says "community ports exist for other devices" without listing them; argues Snapdragon is easier than MediaTek, MediaTek Helio kernel WIP. — [hackios.net](https://hackios.net), [Pasquale Pillitteri](https://pasqualepillitteri.it/en/news/25375/hackios-ios-xiaomi-poco-no-code)

### Inferences
- vayu has mainline-ish Linux support (postmarketOS), an unlockable bootloader, and `fastboot boot` capability, so structurally it fits the HackiOS/UniXNU pattern; but no one is reported to have tried. SM8150 uses Kryo 485 (A76/A55-derived) cores; whether it handles 16K pages natively is not established here.

### Gaps
- Did not search XDA forums, Reddit, GitHub code search or Telegram directly for vayu/msmnile/sm8150 + XNU; absence of results is weak evidence only. Not checked whether UniXNU or HakiOS list SM8150 anywhere.

## 5. Commonly cited blockers

### Takeaway
Blockers named in sources: 16K pages (and specific cores that can't do it), PAC/arm64e, interrupt controller (AIC vs GIC), closed GPU/Metal, secure boot/unlocked bootloader, closed Apple drivers, lack of Secure Enclave, device trees.

### Cited Findings
- 16K pages: Apple kernel expects 16 KiB; UniXNU patched XNU for 4 KiB on Snapdragon. — [pbxscience](https://pbxscience.com/?p=24278). SD 685 port disables four cores that can't do 16K pages. — [Gizchina](https://www.gizchina.com/redmi-phones/real-ios-16-now-boots-on-a-redmi-note-12-4g-and-tinkerers-can-try-it). Apple's A-series cores require 16K (Sandcastle precedent). — [projectsandcastle.org/history](https://projectsandcastle.org/history)
- PAC/arm64e: UniXNU handles by relinking and re-signing vtables; arm64e OS listed as "planned" on sheng. — [unixnu.com/devices/sheng](https://unixnu.com/devices/sheng)
- Interrupts: UniXNU on sheng uses GIC with fixed MMIO addresses; AIC not mentioned. — [unixnu.com/devices/sheng](https://unixnu.com/devices/sheng)
- GPU: UniXNU translation stack (AIR -> SPIR-V -> Mesa Turnip -> Adreno kernel driver); HackiOS "Metal partly working"; README says GPU-drawn content missing when `gpu=0`. — [pbxscience](https://pbxscience.com/?p=24278), [hackios.net](https://hackios.net), [GitHub README](https://github.com/oosexgang/hakios-xnu-kernel)
- Secure boot/closed drivers/DT/Adreno listed as unresolved hurdles by Pillitteri; workaround is `fastboot boot` of a UEFI image into RAM on an unlocked bootloader. — [Pasquale Pillitteri](https://pasqualepillitteri.it/en/news/25375/hackios-ios-xiaomi-poco-no-code), [Hakky Handbook](https://book.st-hakky.com/en/news/run-ios-16-5-firmware-on-android)
- No Secure Enclave means no Apple ID/App Store; Apple files must be user-supplied from IPSW (legal/licensing). — [search summary citing smhn.info](https://smhn.info/202610-hackios-runs-ios-on-android-poco-x5-pro), [Gizchina](https://www.gizchina.com/redmi-phones/real-ios-16-now-boots-on-a-redmi-note-12-4g-and-tinkerers-can-try-it)
- Caveat: Pillitteri's own summary says those hurdles were "unresolved" in Oct, whereas repo docs claim stand-ins for AMFI/keystore etc.; stand-ins are not equal to real implementations.

### Inferences
- Practical blockers by SoC are the CPU's page-size and PAC (Armv8.3) support, a usable interrupt-controller stub, and having a RAM-bootable UEFI; GPU and modem are the long tail.

### Gaps
- No source states PAC behaviour on non-PAC Snapdragon cores (SM8150/778G lack Armv8.3 PAC; this is general knowledge, not sourced here). No clear list of which Snapdragon cores support 16K granule beyond the SD 685 anecdote.
