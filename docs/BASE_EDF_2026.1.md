# AMD EDF 26.06 on ALINX AXU3EG with Vivado 2026.1

This is a separate, minimal bootable base for learning the AXU3EG PS/PL flow with AMD Embedded Development Framework (EDF). It documents the board bring-up performed with Vivado 2026.1 and the official AMD EDF 26.06 disk image.

## Board bring-up reported on hardware

- The EDF system booted from microSD and reached the Linux shell over the board's UART console.
- Linux identified an aarch64 Zynq UltraScale+ system with four Cortex-A53 CPUs and about 3.8 GiB usable RAM; U-Boot reported 4 GiB installed DDR.
- PS Ethernet came up with IPv4/IPv6 connectivity; SSH access was confirmed.
- The 64 GB microSD root filesystem expanded. The 29.6 GB eMMC was detected but not mounted or written.
- Linux exposed three temperature readings around 29-30 °C. The fan was heard spinning.

These are board bring-up results, not a qualification of all peripherals. The active bitstream is minimal: PS DDR, UART, SD, PS GEM3 Ethernet, and a fan output held low. It does not include AN970 RGB/touch, AN5641 MIPI capture, or the complete PL design from the separate 2023.2 project.

## AN970 next step

The AN970 is an 800x480 RGB888 capacitive touchscreen module. ALINX documentation lists an AXU3EG AN970 display tutorial and a separate MIPI capture tutorial for AN5641. The first local test will be a Vivado color-bar pattern, followed by touch input and later a camera-to-display pipeline. See [AN970](AN970_Pinout_y_Prueba.md).

## Version scope

Vivado 2026.1 and AMD EDF 26.06 are the versions used for this work. This is not a claim of a Vivado/EDF 2026.2 migration. Linux was booted from AMD's official EDF image with a board-specific BOOT.BIN; a full local Linux rebuild is not claimed.

## References

- [ALINX AXU3EG tutorial list](https://github.com/fpgauk/axu3eg/blob/main/docs/AXU3EG_Tutorial_List.md)
- [AN970 manual](https://alinx.com/public/upload/file/AN970_User_Manual.pdf)
- [AXU3EG manual](https://alinx.com/public/upload/file/AXU3EG_User_Manual.pdf)
- [AMD EDF 26.06 custom hardware development](https://edf.docs.amd.com/en/v26.06/hwdev/custom-hardware-development.html)

## Reproducibility

The local preparation includes scripts and configuration for Vivado hardware generation and EDF. Generated disk images, vendor downloads, credentials, license files, Yocto build caches, and Vivado implementation artifacts are intentionally not part of this documentation contribution. Add only source files whose license permits redistribution.

