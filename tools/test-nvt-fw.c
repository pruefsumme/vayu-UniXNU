/*
 * Host test for the NT36672C firmware parser the XNU touch driver uses
 * (bsd/dev/vayu_nvt_fw.h in the fork's patched tree).
 *
 *   cc -I ../ios-cepheus/work/dxb/xnu/bsd/dev -o work/test-nvt-fw tools/test-nvt-fw.c
 *   work/test-nvt-fw stock/touch-fw/j20s_novatek_ts_fw01.bin
 *
 * Checks the partition table against the values read from fw01.bin by hand
 * (PORTING.md / research spec), then flips one byte and expects a CRC error.
 */
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "vayu_nvt_fw.h"

int
main(int argc, char **argv)
{
	if (argc != 2) {
		fprintf(stderr, "usage: %s FIRMWARE.bin\n", argv[0]);
		return 2;
	}
	FILE *f = fopen(argv[1], "rb");
	assert(f != NULL);
	static uint8_t fw[1 << 20];
	size_t size = fread(fw, 1, sizeof(fw), f);
	fclose(f);

	struct nvt_part parts[NVT_MAX_PARTS];
	int bad;
	int n = nvt_parse_firmware(fw, size, parts, &bad);
	printf("%zu bytes, %d parts\n", size, n);
	for (int i = 0; i < n; i++) {
		printf("  part %d: sram %06x len %05x bin %05x crc %08x\n", i, parts[i].sram,
		    parts[i].size + 1, parts[i].bin, parts[i].crc);
	}

	/* ILM, DLM, Info-3, Info-4 and the header itself, all CRCs good. */
	assert(n == 5);
	assert(parts[0].sram == 0x000000 && parts[0].size + 1 == 0x12db4 && parts[0].bin == 0x00100);
	assert(parts[1].sram == 0x027140 && parts[1].size + 1 == 0x041f0 && parts[1].bin == 0x18100);
	assert(parts[2].sram == 0x012db4 && parts[2].size + 1 == 0x00bc5 && parts[2].bin == 0x12eb4);
	assert(parts[3].sram == 0x020000 && parts[3].size + 1 == 0x00981 && parts[3].bin == 0x13a78);
	assert(parts[4].sram == 0x027040 && parts[4].size + 1 == 0x00100 && parts[4].bin == 0x00000);

	/* One flipped byte inside the DLM must fail its CRC. */
	fw[parts[1].bin + 100] ^= 1;
	assert(nvt_parse_firmware(fw, size, parts, &bad) == NVT_FW_BAD_CRC && bad == 1);
	printf("ok\n");
	return 0;
}
