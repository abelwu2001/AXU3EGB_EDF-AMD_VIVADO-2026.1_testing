//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2026.1 (win64) Build 6511674 Tue Jun 16 11:02:23 MDT 2026
//Date        : Sun Oct 25 02:31:39 2026
//Host        : DESKTOP-FQ6GBEC running 64-bit major release  (build 9200)
//Command     : generate_target base_wrapper.bd
//Design      : base_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module base_wrapper
   (fan_on_n,
    lcd_b_0,
    lcd_backlight_pwm_0,
    lcd_dclk_0,
    lcd_de_0,
    lcd_g_0,
    lcd_hsync_0,
    lcd_r_0,
    lcd_vsync_0);
  output [0:0]fan_on_n;
  output [7:0]lcd_b_0;
  output lcd_backlight_pwm_0;
  output lcd_dclk_0;
  output lcd_de_0;
  output [7:0]lcd_g_0;
  output lcd_hsync_0;
  output [7:0]lcd_r_0;
  output lcd_vsync_0;

  wire [0:0]fan_on_n;
  wire [7:0]lcd_b_0;
  wire lcd_backlight_pwm_0;
  wire lcd_dclk_0;
  wire lcd_de_0;
  wire [7:0]lcd_g_0;
  wire lcd_hsync_0;
  wire [7:0]lcd_r_0;
  wire lcd_vsync_0;

  base base_i
       (.fan_on_n(fan_on_n),
        .lcd_b_0(lcd_b_0),
        .lcd_backlight_pwm_0(lcd_backlight_pwm_0),
        .lcd_dclk_0(lcd_dclk_0),
        .lcd_de_0(lcd_de_0),
        .lcd_g_0(lcd_g_0),
        .lcd_hsync_0(lcd_hsync_0),
        .lcd_r_0(lcd_r_0),
        .lcd_vsync_0(lcd_vsync_0));
endmodule

