# Poco X3 Pro (vayu, SM8150-AC) hardware parts list from open-source kernel/DT sources

Method note: most facts come from Xiaomi's released vayu kernel (MiCode/Xiaomi_Kernel_OpenSource, branch vayu-r-oss, DTS dir `arch/arm64/boot/dts/qcom`), the LineageOS/xiaomi-sm8150-devs device trees, and Project-Silicium/Mu-Silicium. Base URL for DT files below: `https://github.com/MiCode/Xiaomi_Kernel_OpenSource/blob/vayu-r-oss/arch/arm64/boot/dts/qcom/` (abbreviated MiCode-DT). Search-engine and wiki access was poor (postmarketOS wiki redirects to a mirror that blocks bots; LineageOS wiki returned 403), so several questions are unanswered. About 22 tool calls were used, over the ~20 budget.

## Touch controller, display panels, backlight

### Takeaway
Touch is a Novatek (NVT, NT36xxx family; DT comment mentions "672"/"672A") controller on SPI (qupv3_se17), not Goodix or FocalTech. Two 1080x2400 @120 Hz 4-lane DSI video-mode DSC panels exist, named by display-maker byte 0x36 (Tianma, per touch config) and 0x42 (CSOT per touch config; community "Huaxing" naming is not in the sources).

### Cited Findings
- vayu overlay: `model = "VAYU"`, `compatible = "qcom,sm8150-cdp","qcom,sm8150","qcom,cdp"`, `qcom,board-id = <47 0>`; it includes vayu-sm8150.dtsi and vayu-audio-overlay.dtsi — [vayu-sm8150-overlay.dts](https://raw.githubusercontent.com/MiCode/Xiaomi_Kernel_OpenSource/vayu-r-oss/arch/arm64/boot/dts/qcom/vayu-sm8150-overlay.dts)
- Touch node `ts_novatek`, compatible `novatek,NVT-ts-spi`, 10 MHz SPI, on `&qupv3_se17_spi` (child `xiaomi,spi-for-tp`, reg 0); reset = TLMM GPIO 12, IRQ = TLMM GPIO 122 (flags 0x2001 = falling edge), `novatek,swrst-n8-addr = 0x03F0FE` (the "672A" variant; the older 672 value is commented out), `spi-rd-fast-addr = 0x03F310` — [vayu-sm8150.dtsi](https://raw.githubusercontent.com/MiCode/Xiaomi_Kernel_OpenSource/vayu-r-oss/arch/arm64/boot/dts/qcom/vayu-sm8150.dtsi) (lines ~490-640)
- Touch firmware is selected per panel maker: cfg_0 tp-vendor 0x46 / display-maker 0x36, fw `j20s_novatek_ts_fw01.bin`, label "nvt+tianma"; cfg_1 tp-vendor 0x53 / display-maker 0x42, fw `j20s_novatek_ts_fw02.bin`, label "nvt+csot". Separate MP criteria nodes "594A" and "594B" are present — same file
- Panel A: `dsi_j20s_36_02_0a_video`, panel-name "xiaomi 36 02 0a video mode dsc dsi panel" — [dsi-panel-j20s-36-02-0a-lcd-dsc-vid.dtsi](https://raw.githubusercontent.com/MiCode/Xiaomi_Kernel_OpenSource/vayu-r-oss/arch/arm64/boot/dts/qcom/dsi-panel-j20s-36-02-0a-lcd-dsc-vid.dtsi)
- Panel B: `dsi_j20s_42_02_0b_video`, panel-name "xiaomi 42 02 0b video mode dsc dsi panel" — [dsi-panel-j20s-42-02-0b-lcd-dsc-vid.dtsi](https://raw.githubusercontent.com/MiCode/Xiaomi_Kernel_OpenSource/vayu-r-oss/arch/arm64/boot/dts/qcom/dsi-panel-j20s-42-02-0b-lcd-dsc-vid.dtsi)
- Both panels: `dsi_video_mode`, bpp 24, burst mode, 4 lanes (lane-0..3-state), framerate 120, 1080 wide x 2400 high, h-front-porch 67, backlight levels 2..4095 (12-bit), ESD settings present. DSC: `compression-mode = "dsc"`, version 0x11 (DSC 1.1), scr-version 0, slice-height 20, slice-width 540 (2 slices across), slice-per-pkt 2, 8 bpc, 8 bpp (3:1 compression), block prediction on — same two files
- Panel power: vayu overlay sets `qcom,panel-supply-entries = <&dsi_panel_pwr_supply>` for both panels, `&sde_dsi { vcie-supply = <&disp_vci_vreg> }`; external supply node `dsi_amoled_panel_pwr_external_supply` is present (leftover naming) — vayu-sm8150.dtsi
- Backlight: PMIC WLED on pm8150l: `&pm8150l_wled` okay, `qcom,string-cfg = <7>` (three strings), ovp 28000 mV, fs-current-limit 22500 uA, cabc-sel 1 — vayu-sm8150.dtsi. This means an LCD (IPS), not AMOLED, consistent with the "lcd" panel file names
- The tree also contains an unrelated `dsi-panel-tianma-fhd-nt36672a-video.dtsi` (1080x2340 @60, panel IC NT36672A, ESD IRQ GPIO 5) — probably inherited from other Xiaomi SM8150 devices; not shown to be used by vayu — [dsi-panel-tianma-fhd-nt36672a-video.dtsi](https://raw.githubusercontent.com/MiCode/Xiaomi_Kernel_OpenSource/vayu-r-oss/arch/arm64/boot/dts/qcom/dsi-panel-tianma-fhd-nt36672a-video.dtsi)
- Mu-Silicium vayu build sets framebuffer 1080x2400 (`PcdFrameBufferWidth|1080`, `PcdFrameBufferHeight|2400`) — [vayu.dsc](https://raw.githubusercontent.com/Project-Silicium/Mu-Silicium/main/Platforms/Xiaomi/vayuPkg/vayu.dsc)
- Other peripherals on vayu DT: fingerprint node `goodix,fingerprint` (reset GPIO 37, IRQ GPIO 120) plus alt `fpc,fpc1020` on the same IRQ pin (side-mounted sensor variant selection), NFC `qcom,nq-nci` on qupv3_se9 I2C (IRQ GPIO 47), IR blaster `ir-spi` on qupv3_se1 SPI — vayu-sm8150.dtsi

### Inferences
- Tell the panel variant apart by (a) the display name the bootloader passes on the kernel cmdline (expect `dsi_j20s_36_02_0a_video_display` vs `dsi_j20s_42_02_0b_video_display`; the cmdline form is my inference from the DT labels, not directly verified), (b) the Novatek firmware ID / panel-ID read from the DDIC, or (c) which touch firmware the stock Android loads. The DT itself has no runtime-detect GPIO.
- "36" = Tianma and "42" = CSOT is from touch-config labels; the "Huaxing" name in the task prompt is not found in any source I read. Treat Huaxing=0x42 as unconfirmed.
- 4 lanes + DSC 1.1 3:1 at 1080x2400x120 means a port needs a DSC encoder (SM8150 DPU has DSC blocks) and cannot simply scan out uncompressed over DSI.
- For a non-Android OS the touch driver needs SPI (se17), GPIO 12 reset, GPIO 122 IRQ, and per-panel firmware blobs (NVT firmware is loaded by the downstream driver; whether it is optional is unknown).

### Gaps
- Exact DSI init command sequences are in the panel dtsi (`qcom,mdss-dsi-on-command`); I did not extract them.
- No source read states which panel a given unit has other than the DT labels above; no distribution-ratio data.
- Panel maker names (Huaxing vs CSOT) not verified.

## Wi-Fi / Bluetooth, modem, PMICs, audio

### Takeaway
DT describes a Qualcomm WCN3990-class connectivity chip: Wi-Fi via `qcom,icnss` (SNOC-attached, ath10k-style, not PCIe) and Bluetooth via a UART-attached `qca,wcn3990` node. Whether vayu's retail part is marketed WCN3998 is not stated in the sources I read. PMICs are PM8150 / PM8150B / PM8150L. Speaker amps are Cirrus CS35L41 and TI TAS256x/TAS2557 on I2C.

### Cited Findings
- Bluetooth node `bt_wcn3990`, compatible `qca,wcn3990`, supplies pm8150_l7 (1.8 V core), pm8150l_l2 (1.304 V PA), pm8150l_l11 (3.312 V LDO) — [xiaomi-sm8150-common.dtsi](https://raw.githubusercontent.com/MiCode/Xiaomi_Kernel_OpenSource/vayu-r-oss/arch/arm64/boot/dts/qcom/xiaomi-sm8150-common.dtsi)
- Wi-Fi: `icnss: qcom,icnss@18800000`, compatible `qcom,icnss`, `qcom,wlan-msa-memory = <0x100000>`, MSA fixed region `pil_wlan_fw_mem` @ 0x8bc00000 size 0x180000. A separate `qcom,wlan-rc-num = <0>` PCIe-RC property exists in the base SoC DT (line ~3724, belongs to the SoC's generic wlan/PCIe config). Slimbus codec node `btfmslim_codec: wcn3990` — [sm8150.dtsi](https://raw.githubusercontent.com/MiCode/Xiaomi_Kernel_OpenSource/vayu-r-oss/arch/arm64/boot/dts/qcom/sm8150.dtsi)
- PMICs referenced in vayu DT: pm8150 (e.g. `pm8150_l9` feeds UFS vccq, `pm8150_vadc`), pm8150b (`pm8150b_vadc`, charger/ADC), pm8150l (`pm8150l_s8`, `pm8150l_wled`) — vayu-sm8150.dtsi
- Speaker amplifiers: `cirrus,cs35l41` at I2C addr 0x40 on qupv3_se4 (reset GPIO 89, with a second instance reset GPIO 7), `ti,tas2557` on se4 (IRQ GPIO 60), `ti,tas256x` at 0x4c on qupv3_se7 (reset GPIOs 89/92, IRQ 90/91) — vayu-sm8150.dtsi. These are alternate-population options; which is fitted on a given SKU is not stated.
- Charging: `ti,bq2597x-standalone` charge pump, `xiaomi,usbpd-pm`, `maxim,ds28e16` authentication — vayu-sm8150.dtsi
- Modem: `pil_modem_mem` @ 0x8e000000 size 0x9600000; SM8150 integrated modem (MSS) — sm8150.dtsi. The tree also has `sm8150-sdx50m*.dtsi` (external 5G modem variants for other devices)

### Inferences
- With ICNSS the Wi-Fi is on the SoC's SNOC bus (shared memory/QMI with firmware) rather than PCIe; Linux ath10k supports this as `qcom,wcn3990-wifi` (SNOC) — this mapping is from my knowledge, not from the vayu DT.
- vayu is, by my knowledge, a 4G-only device with the SoC-integrated modem (no external SDX50/55 DT overlay used); the vayu overlay does not pull in sm8150-sdx50m.dtsi (inference from the includes list I saw).
- Audio codec: SoC-side `sm8150-wcd.dtsi` exists in the tree, suggesting WCD934x family (WCD9340) with slimbus; I did not verify the chip identity in the vayu DT.

### Gaps
- WCN3998 vs WCN3990 on vayu: only WCN3990 DT names found; no firmware filenames (`wlanmdsp.mbn`, `bdwlan`, `crnv`, board-file names) were retrieved.
- Audio codec chip ID, mic/headphone paths, and exact amp variant per SKU not confirmed.
- Modem model (X24 integrated) not confirmed by a source.

## UFS, GPU, memory map, interrupt controller / timer

### Takeaway
UFS host is Qualcomm `ufshc@1d84000` with vayu-specific regulator tweaks; the UFS device version/vendor is not in the DT. GIC is v3 at 0x17a00000, arch timer 19.2 MHz, DDR base 0x80000000, GPU Adreno 640 (chipid 0x06040001) with a 2-bin speed table (585 MHz and 675 MHz max).

### Cited Findings
- UFS: `ufshc_mem: ufshc@1d84000`, compatible `qcom,ufshc`; vayu overrides `vcc-voltage-level = <2504000 2950000>`, `vccq-supply = <&pm8150_l9>`, `vccq-max-microamp = 700000`, vccq-parent pm8150l_s8 — [sm8150.dtsi](https://raw.githubusercontent.com/MiCode/Xiaomi_Kernel_OpenSource/vayu-r-oss/arch/arm64/boot/dts/qcom/sm8150.dtsi), [vayu-sm8150.dtsi](https://raw.githubusercontent.com/MiCode/Xiaomi_Kernel_OpenSource/vayu-r-oss/arch/arm64/boot/dts/qcom/vayu-sm8150.dtsi)
- Mu-Silicium status for vayu marks Internal Storage as working in UEFI and Windows, SD card broken in UEFI (works in Windows), USB host and USB PD not working in UEFI; Windows and Linux boot via UEFI work; state "Inactive" — [Status.md](https://raw.githubusercontent.com/Project-Silicium/Mu-Silicium/main/Status.md)
- GIC: `intc: interrupt-controller@17a00000`, compatible `arm,gic-v3`; also `arm,gic-600-erp` node and a PDC `interrupt-controller@b220000` — sm8150.dtsi
- Arch timer: `compatible = "arm,armv8-timer"`, `clock-frequency = <19200000>` (also on the MMIO timer node); sleep clock 32768 Hz — sm8150.dtsi
- DDR base: Mu-Silicium sets `PcdSystemMemoryBase|0x80000000`, CPU stack at 0x9FFB0000, `SOC_TYPE = 2` with comment "SM8150-AC / 860" — [vayu.dsc](https://raw.githubusercontent.com/Project-Silicium/Mu-Silicium/main/Platforms/Xiaomi/vayuPkg/vayu.dsc)
- Reserved regions (all `no-map`): hyp_mem 0x85700000 (0x600000); xbl_dump 0x85d00000 (0x100000); xbl_aop 0x85e00000 (0x140000); smem 0x86000000 (0x200000); removed_regions 0x86200000 (0x5500000); camera 0x8b700000 (0x500000); wlan_fw 0x8bc00000 (0x180000); npu 0x8bd80000 (0x80000); adsp 0x8be00000 (0x2200000); modem 0x8e000000 (0x9600000); video 0x97600000; cont_splash at 0x9c000000 — sm8150.dtsi. Mu-Silicium's vayu ConfigurationMap also lists TZ apps region 0x87900000 (0x03E00000), shared IMEM base 0x146BF000 and dload cookie 0x01FD3000 — [ConfigurationMapLib.c](https://raw.githubusercontent.com/Project-Silicium/Mu-Silicium/main/Platforms/Xiaomi/vayuPkg/Library/ConfigurationMapLib/ConfigurationMapLib.c)
- GPU: Adreno 640, `qcom,chipid = <0x06040001>`; v2 table keyed on fuse `qcom,gpu-speed-bin = <0x4130 0xe0000000 29>`: bin 0 max 585 MHz (585/499.2/427/345/257), bin 1 max 675 MHz (675/585/499.2/427/345/257). Separate `gpu_opp_table_v2` lists 675/585/499.2/427/345/257 MHz — [sm8150-v2.dtsi](https://raw.githubusercontent.com/MiCode/Xiaomi_Kernel_OpenSource/vayu-r-oss/arch/arm64/boot/dts/qcom/sm8150-v2.dtsi), [sm8150-gpu-v2.dtsi](https://raw.githubusercontent.com/MiCode/Xiaomi_Kernel_OpenSource/vayu-r-oss/arch/arm64/boot/dts/qcom/sm8150-gpu-v2.dtsi)
- SoC identity: kernel has `sm8150p.dtsi` (msm-id 361 v1) and `sm8150p-v2.dtsi` (msm-id 361, 0x20000) labelled "SM8150P" — [sm8150p-v2.dtsi](https://raw.githubusercontent.com/MiCode/Xiaomi_Kernel_OpenSource/vayu-r-oss/arch/arm64/boot/dts/qcom/sm8150p-v2.dtsi). Board platform in LineageOS common tree: `TARGET_BOARD_PLATFORM := msmnile` — [BoardConfigCommon.mk](https://raw.githubusercontent.com/xiaomi-sm8150-devs/android_device_xiaomi_sm8150-common/lineage-20/BoardConfigCommon.mk)

### Inferences
- The 675 MHz bin matches Snapdragon 860/855+ class parts (the "AC" marketing difference); which bin a particular vayu gets is a fuse read at runtime (0x4130 bits 31:29 within the QFPROM region).
- UFS standard for SM8150 hosts is up to UFS 3.0/HS-G4; vayu retail units reportedly use UFS 3.1 (Samsung/Toshiba/Hynix mixes) — this is from my background knowledge, not from the sources, and is unverified.
- Memory map above is from the downstream DT. Real layout on a retail device is handed over by the bootloader (UEFI memory map or DT) and may differ; a port should read it at runtime.

### Gaps
- UFS device vendor and spec version (no source read states it).
- Total RAM sizes (6/8 GB SKUs) and the full DDR bank layout beyond 0x80000000 not extracted.
- Dedicated GPU speed-bin fuse value on a vayu unit; whether vayu uses `sm8150-gpu-v2` is inferred from the SM8150P v2 base.

## Boot and hypervisor specifics, EL at kernel entry, fastboot boot

### Takeaway
Boot image header version is 2 with an out-of-band DTBO and AVB-enabled dynamic partitions (from the LineageOS common tree, with the caveat that the BoardConfig is the Android build side). Whether the kernel enters at EL1 or EL2 and whether `fastboot boot` is allowed was not established from the sources I could reach.

### Cited Findings
- LineageOS SM8150 common tree: `BOARD_BOOT_HEADER_VERSION := 2`, kernel base 0x0, page size 4096, `BOARD_INCLUDE_DTB_IN_BOOTIMG := true`, `BOARD_KERNEL_SEPARATED_DTBO := true`, boot partition size 134217728 (128 MiB), dtbo partition size 33554432 (32 MiB), `BOARD_AVB_ENABLE := true` with vbmeta flags 3, dynamic `super` partition (9126805504 or 6442450944 bytes), `TARGET_BOARD_PLATFORM := msmnile`, recovery uses dtbo (`BOARD_INCLUDE_RECOVERY_DTBO`) and a dynamic-partition fstab; cmdline includes `androidboot.hardware=qcom androidboot.console=ttyMSM0 ... androidboot.usbcontroller=a600000.dwc3` — [BoardConfigCommon.mk](https://raw.githubusercontent.com/xiaomi-sm8150-devs/android_device_xiaomi_sm8150-common/lineage-20/BoardConfigCommon.mk). The SM8150 dtsi shows UFS-hosted storage; USB controller is a600000.dwc3.
- vayu device tree: `TARGET_OTA_ASSERT_DEVICE := vayu,bhima` (bhima is the India variant of the same hardware, Poco X3 Pro / POCO X3 Pro India) — [LineageOS android_device_xiaomi_vayu BoardConfig.mk](https://raw.githubusercontent.com/LineageOS/android_device_xiaomi_vayu/lineage-23.2/BoardConfig.mk)
- Mu-Silicium builds a vayu UEFI (`vayuPkg`, includes a `BootShim` directory with `BootShim.S`, and Linux boot is rated working) — [Status.md](https://raw.githubusercontent.com/Project-Silicium/Mu-Silicium/main/Status.md). A web search surfaced only generic notes: one e/OS community post uses `fastboot boot` of a TWRP image on an unlocked vayu, and LineageOS notes that fastboot may hang on `fastboot boot` on some devices (bad USB) — [search results incl. LineageOS vayu install page](https://wiki.lineageos.org/devices/vayu/install/) (page itself returned 403 to the fetch tool; only the search snippet was seen)
- Kernel DT shows hypervisor memory is reserved: `hyp_mem` 0x85700000 (6 MiB, no-map) — sm8150.dtsi

### Inferences
- Because hyp_mem is reserved and Qualcomm SM8150 bootloaders run HYP/QHEE (Gunyah came later), the standard Android kernel is believed to be entered at EL1 under the Qualcomm hypervisor; many SM8150 WoA/UEFI ports (Mu-Silicium family) work around this by running UEFI at EL1/EL2 conversion in BootShim. This is background knowledge and the BootShim.S text did not yield a match for "EL2/hvc" in my grep, so it is NOT confirmed. Linux-mainline on SM8150 devices needs the PSCI-over-SMC path and often runs at EL1 as a guest of QHEE; a kernel/hypervisor (like UniXNU) must therefore be prepared for EL1 entry and not rely on EL2 virtualization/VHE.
- Xiaomi ABL: unlocked bootloader (Mi Unlock + wait period) is required for flashing/booting non-stock images; with header v2 and AVB the usual practice is `fastboot flash boot` (non-A/B? vayu partition scheme — "dynamic" super, A/B status not confirmed) plus disabling vbmeta verification (`fastboot flash vbmeta --disable-verity --disable-verification vbmeta.img`, flag 3 matches this in the Lineage board config). `fastboot boot` working is plausible on Qualcomm ABL but unverified for Xiaomi.

### Gaps
- EL at kernel entry: no source states it for vayu. Needs reading Mu-Silicium BootShim.S / edk2-msm docs or UniXNU/ios-sweet/ios-flame docs directly.
- Whether Xiaomi's ABL allows `fastboot boot` on locked/unlocked vayu; known workarounds; A/B vs non-A/B; mi-unlock waiting period details. LineageOS wiki and postmarketOS wiki were unreachable (403 / bot-block).
- Mu-Silicium `vayu` flashing instructions (it uses a `fastboot flash boot` of a Mu-Silicium boot image per common practice, not verified here).

## Comparison with Pixel 4 (flame, SM8150)

### Takeaway
I could not retrieve primary-source data for Pixel 4 in this session (Mu-Silicium has no Google platform directory; Status.md had no Pixel 4 entry). The notes below are not sourced and are for orientation only.

### Cited Findings
- Mu-Silicium's Status.md contains the vayu entry cited above; no Pixel 4 / flame entry matched in Status.md, and `Platforms/Google` does not exist in the repo — [Status.md](https://raw.githubusercontent.com/Project-Silicium/Mu-Silicium/main/Status.md)

### Inferences
- From background knowledge (unverified here): Pixel 4 is SM8150 (non-AC, 855) with a 90 Hz 1080x2280 OLED, Synaptics touch, Qualcomm WCN3998 Wi-Fi, and a bootloader that can be unlocked with `fastboot flashing unlock` (A/B partitions, boot header v2, `fastboot boot` supported). Vayu differs with an LCD at 1080x2400 @120 Hz, Novatek SPI touch, WCN399x via ICNSS (to be confirmed), and a Xiaomi-ABL unlock gate.

### Gaps
- No primary source read for flame panel, touch, Wi-Fi, UFS, or ABL behaviour; comparison remains unverified. Suggested follow-up: android_kernel_google_msm-4.14 flame DTS and LineageOS flame wiki pages.

## Suggested direct follow-ups
- Read `BootShim/BootShim.S` and the vayu `.fdf`/`.dsc` fully for EL handling; check `edk2-porting/edk2-msm` docs for SM8150 EL2 notes.
- Read `ios-sweet`/`ios-flame` docs for how they handle EL.
- Extract DSI init sequences and DSC parameters from the two j20s panel dtsi files if a display driver is planned.
