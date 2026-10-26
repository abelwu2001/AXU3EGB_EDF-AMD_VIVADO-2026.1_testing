set_property PACKAGE_PIN AA11 [get_ports fan_on_n]
set_property IOSTANDARD LVCMOS33 [get_ports fan_on_n]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# AN970: señales de control por el conector J45
set_property PACKAGE_PIN A11 [get_ports lcd_dclk_0]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_dclk_0]

set_property PACKAGE_PIN C12 [get_ports lcd_hsync_0]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_hsync_0]

set_property PACKAGE_PIN D12 [get_ports lcd_vsync_0]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_vsync_0]

set_property PACKAGE_PIN A12 [get_ports lcd_de_0]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_de_0]

# AN970: canal rojo
set_property PACKAGE_PIN D14 [get_ports {lcd_r_0[0]}]
set_property PACKAGE_PIN D15 [get_ports {lcd_r_0[1]}]
set_property PACKAGE_PIN G14 [get_ports {lcd_r_0[2]}]
set_property PACKAGE_PIN G15 [get_ports {lcd_r_0[3]}]
set_property PACKAGE_PIN F13 [get_ports {lcd_r_0[4]}]
set_property PACKAGE_PIN G13 [get_ports {lcd_r_0[5]}]
set_property PACKAGE_PIN H13 [get_ports {lcd_r_0[6]}]
set_property PACKAGE_PIN H14 [get_ports {lcd_r_0[7]}]

# AN970: canal verde
set_property PACKAGE_PIN J14 [get_ports {lcd_g_0[0]}]
set_property PACKAGE_PIN K14 [get_ports {lcd_g_0[1]}]
set_property PACKAGE_PIN H12 [get_ports {lcd_g_0[2]}]
set_property PACKAGE_PIN J12 [get_ports {lcd_g_0[3]}]
set_property PACKAGE_PIN L13 [get_ports {lcd_g_0[4]}]
set_property PACKAGE_PIN L14 [get_ports {lcd_g_0[5]}]
set_property PACKAGE_PIN C13 [get_ports {lcd_g_0[6]}]
set_property PACKAGE_PIN C14 [get_ports {lcd_g_0[7]}]

# AN970: canal azul
set_property PACKAGE_PIN A14 [get_ports {lcd_b_0[0]}]
set_property PACKAGE_PIN B14 [get_ports {lcd_b_0[1]}]
set_property PACKAGE_PIN A13 [get_ports {lcd_b_0[2]}]
set_property PACKAGE_PIN B13 [get_ports {lcd_b_0[3]}]
set_property PACKAGE_PIN E13 [get_ports {lcd_b_0[4]}]
set_property PACKAGE_PIN E14 [get_ports {lcd_b_0[5]}]
set_property PACKAGE_PIN F11 [get_ports {lcd_b_0[6]}]
set_property PACKAGE_PIN F12 [get_ports {lcd_b_0[7]}]

# Los tres buses RGB usan señales LVCMOS de 3,3 V
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_r_0[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_g_0[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_b_0[*]}]

# AN970: control de luz de fondo, P4 pin 4 -> J45 pin 4 -> FPGA C11
set_property PACKAGE_PIN C11 [get_ports lcd_backlight_pwm_0]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_backlight_pwm_0]
