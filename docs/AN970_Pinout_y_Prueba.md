# AN970 on AXU3EG: first display test

## Interface

The AN970 is a 7-inch, 800x480, 24-bit RGB display with capacitive touch. The display uses 40-pin header P4. The AXU3EG manual documents J45 as a 40-pin expansion header with +5 V, +3.3 V, grounds, and 34 FPGA I/O signals; J45 pins 3-36 map to FPGA banks 45 and 46. The manual gives banks 43-46 a 3.3 V I/O standard. This matches the module's direct 40-pin connection scheme.

Power the board off before connecting. Align P4 pin 1 with J45 pin 1 and do not force the connector. Recheck the board revision and pin-1 marking before applying power.

## Direct P4-to-J45 pin map

The cable is straight through: P4 pin N to J45 pin N. FPGA package pins below come from the AXU3EG manual. Data signals are shown in connector order; the RGB bits are interleaved in the header, so assign each bit explicitly in XDC.

| P4/J45 | AN970 signal | FPGA pin |
|---:|---|---|
| 3 | INIT | B10 |
| 4 | BACK_LED_PWM | C11 |
| 5 | Touch SCL | F10 |
| 6 | Touch SDA | G11 |
| 7 | LCD_HSYNC | C12 |
| 8 | LCD_VSYNC | D12 |
| 9 | LCD_DCLK | A11 |
| 10 | LCD_DE | A12 |
| 11 | LCD_B6 | F11 |
| 12 | LCD_B7 | F12 |
| 13 | LCD_B4 | E13 |
| 14 | LCD_B5 | E14 |
| 15 | LCD_B2 | A13 |
| 16 | LCD_B3 | B13 |
| 17 | LCD_B0 | A14 |
| 18 | LCD_B1 | B14 |
| 19 | LCD_G6 | C13 |
| 20 | LCD_G7 | C14 |
| 21 | LCD_G4 | L13 |
| 22 | LCD_G5 | L14 |
| 23 | LCD_G2 | H12 |
| 24 | LCD_G3 | J12 |
| 25 | LCD_G0 | J14 |
| 26 | LCD_G1 | K14 |
| 27 | LCD_R6 | H13 |
| 28 | LCD_R7 | H14 |
| 29 | LCD_R4 | F13 |
| 30 | LCD_R5 | G13 |
| 31 | LCD_R2 | G14 |
| 32 | LCD_R3 | G15 |
| 33 | LCD_R0 | D14 |
| 34 | LCD_R1 | D15 |
| 35 | LCD_SDA | A15 |
| 36 | LCD_SCL | B15 |

Pins 1/37/38 are ground, pin 2 is +5 V, and pins 39/40 are +3.3 V reserved by the LCD manual. These are power/reference pins, not FPGA signal pins.

## Validation sequence

1. Keep the known-good EDF microSD image as a backup and use a separate Vivado project for the display experiment.
2. Confirm the LCD's RGB timing from the AN970 manual before selecting the pixel clock and porches; this document does not invent timing values.
3. Simulate 800x480 counters, sync, data-enable, RGB bars, and backlight control. Run Vivado DRC, synthesis, and implementation.
4. Test the generated bitstream temporarily by JTAG before deciding to integrate it into an EDF boot image.
5. Test the capacitive touch I2C and interrupt after video works. Add camera AN5641 capture only as a later stage.

## Current status

Not yet tested on the user's physical AN970. The current EDF bitstream has no LCD outputs. ALINX's AXU3EG tutorial index lists both an AN970 display experiment and a separate AN5641 MIPI capture/display experiment, but their existing design files must be checked and rebuilt for the current Vivado/EDF setup before reuse.

References: [AN970 manual](https://alinx.com/public/upload/file/AN970_User_Manual.pdf), [AXU3EG manual](https://alinx.com/public/upload/file/AXU3EG_User_Manual.pdf), [AXU3EG tutorial list](https://github.com/fpgauk/axu3eg/blob/main/docs/AXU3EG_Tutorial_List.md).
