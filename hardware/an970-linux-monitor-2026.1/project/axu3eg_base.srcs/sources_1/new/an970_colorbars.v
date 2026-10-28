`timescale 1ns / 1ps
// AN970 horizontal Linux monitor graphics for 800x480.
// AXI metric map: REG0=4 packed CPU percentages, REG1=RAM %,
// REG2/3/4=LPD/FPD/PL temperature in tenths C, REG5=fan %, REG6=IPv4.
module an970_colorbars(
    input pixel_clk,
    input reset_n,
    input clock_locked,
    output lcd_dclk,
    output lcd_hsync,
    output lcd_vsync,
    output lcd_de,
    output reg [7:0] lcd_r,
    output reg [7:0] lcd_g,
    output reg [7:0] lcd_b,
    output lcd_backlight_pwm,
    input wire [31:0] metrics_reg0,
    input wire [31:0] metrics_reg1,
    input wire [31:0] metrics_reg2,
    input wire [31:0] metrics_reg3,
    input wire [31:0] metrics_reg4,
    input wire [31:0] metrics_reg5,
    input wire [31:0] metrics_reg6
);
    // Panel timing: 800 active pixels by 480 active lines.
    localparam integer H_ACTIVE = 800;
    localparam integer H_FRONT  = 40;
    localparam integer H_SYNC   = 128;
    localparam integer H_BACK   = 88;
    localparam integer H_TOTAL  = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;
    localparam integer V_ACTIVE = 480;
    localparam integer V_SYNC   = 3;
    localparam integer V_BACK   = 20;
    localparam integer V_FRONT  = 22;
    localparam integer V_TOTAL  = V_SYNC + V_BACK + V_ACTIVE + V_FRONT;

    reg [10:0] h_count;
    reg [9:0]  v_count;

    assign lcd_dclk = pixel_clk;
    assign lcd_hsync = 1'b1;
    assign lcd_vsync = 1'b1;
    assign lcd_backlight_pwm = 1'b1;
    assign lcd_de =
        (h_count >= H_SYNC + H_BACK) &&
        (h_count <  H_SYNC + H_BACK + H_ACTIVE) &&
        (v_count >= V_SYNC + V_BACK) &&
        (v_count <  V_SYNC + V_BACK + V_ACTIVE);

    wire [10:0] active_x = h_count - (H_SYNC + H_BACK);
    wire [9:0]  active_y = v_count - (V_SYNC + V_BACK);
    // Landscape layout: screen coordinates match incoming pixel coordinates.
    wire [10:0] ui_x = active_x;
    wire [9:0]  ui_y = active_y;

    // Clamp incoming percentages to 0..100 so bad Linux values cannot
    // make a bar extend outside its card. CPU uses one byte per core.
    wire [7:0] cpu0_pct = (metrics_reg0[7:0]   > 100) ? 100 : metrics_reg0[7:0];
    wire [7:0] cpu1_pct = (metrics_reg0[15:8]  > 100) ? 100 : metrics_reg0[15:8];
    wire [7:0] cpu2_pct = (metrics_reg0[23:16] > 100) ? 100 : metrics_reg0[23:16];
    wire [7:0] cpu3_pct = (metrics_reg0[31:24] > 100) ? 100 : metrics_reg0[31:24];
    wire [7:0] ram_pct  = (metrics_reg1[7:0]   > 100) ? 100 : metrics_reg1[7:0];
    wire [7:0] fan_pct  = (metrics_reg5[7:0]   > 100) ? 100 : metrics_reg5[7:0];

    // Temperature registers are tenths of a degree C; cap the bars at 125.0 C.
    wire [10:0] lpd_tenths = (metrics_reg2 > 1250) ? 11'd1250 : metrics_reg2[10:0];
    wire [10:0] fpd_tenths = (metrics_reg3 > 1250) ? 11'd1250 : metrics_reg3[10:0];
    wire [10:0] pl_tenths  = (metrics_reg4 > 1250) ? 11'd1250 : metrics_reg4[10:0];

    wire [15:0] cpu0_fill = (cpu0_pct * 16'd242) / 100;
    wire [15:0] cpu1_fill = (cpu1_pct * 16'd242) / 100;
    wire [15:0] cpu2_fill = (cpu2_pct * 16'd242) / 100;
    wire [15:0] cpu3_fill = (cpu3_pct * 16'd242) / 100;
    wire [15:0] ram_fill  = (ram_pct  * 16'd330) / 100;
    wire [15:0] fan_fill  = (fan_pct  * 16'd330) / 100;
    wire [15:0] lpd_fill  = (lpd_tenths * 32'd250) / 32'd1250;
    wire [15:0] fpd_fill  = (fpd_tenths * 32'd250) / 32'd1250;
    wire [15:0] pl_fill   = (pl_tenths  * 32'd250) / 32'd1250;
    

    always @(posedge pixel_clk) begin
        if (!reset_n || !clock_locked) begin
            h_count <= 0;
            v_count <= 0;
        end else if (h_count == H_TOTAL - 1) begin
            h_count <= 0;
            if (v_count == V_TOTAL - 1)
                v_count <= 0;
            else
                v_count <= v_count + 1'b1;
        end else begin
            h_count <= h_count + 1'b1;
        end
    end

    // Text ROM for fixed labels; live numbers are formatted below from AXI registers.
    localparam [191:0] TXT0  = {"AXU3EGB LINUX MONITOR", {3{8'h20}}};
    localparam [191:0] TXT1  = {"AMD EDF 26.06  /  AN970", {1{8'h20}}};
    localparam [191:0] TXT2  = {"LIVE DATA", {15{8'h20}}};
    localparam [191:0] TXT3  = {"CPU / 4 CORES", {11{8'h20}}};
    localparam [191:0] TXT4  = {"C0", {22{8'h20}}};
    localparam [191:0] TXT5  = {"C1", {22{8'h20}}};
    localparam [191:0] TXT6  = {"C2", {22{8'h20}}};
    localparam [191:0] TXT7  = {"C3", {22{8'h20}}};
    localparam [191:0] TXT8  = {"RAM / MEMORY", {12{8'h20}}};
    localparam [191:0] TXT9  = {"USED", {20{8'h20}}};
    localparam [191:0] TXT10 = {"TEMPERATURE", {13{8'h20}}};
    localparam [191:0] TXT11 = {"LPD", {21{8'h20}}};
    localparam [191:0] TXT12 = {"FPD", {21{8'h20}}};
    localparam [191:0] TXT13 = {"PL", {22{8'h20}}};
    localparam [191:0] TXT14 = {"FAN PWM", {17{8'h20}}};
    localparam [191:0] TXT15 = {"DUTY", {20{8'h20}}};
    localparam [191:0] TXT16 = {"PWM OUTPUT", {14{8'h20}}};
    localparam [191:0] TXT17 = {"NETWORK", {17{8'h20}}};
    localparam [191:0] TXT18 = {"RX DEMO", {17{8'h20}}};
    localparam [191:0] TXT19 = {"TX DEMO", {17{8'h20}}};
    localparam [191:0] TXT20 = {"STORAGE", {17{8'h20}}};
    localparam [191:0] TXT21 = {"MICROSD", {17{8'h20}}};
    localparam [191:0] TXT22 = {"EMMC", {20{8'h20}}};
    localparam [191:0] TXT23 = {"LINUX DATA / AXI-LITE", {3{8'h20}}};
    localparam [191:0] TXT33 = {"IP ", {3{8'h30}}, ".", {3{8'h30}}, ".", {3{8'h30}}, ".", {3{8'h30}}, {6{8'h20}}};

    function [191:0] choose_text;
        input [5:0] id;
        begin
            case (id)
                0: choose_text=TXT0;   1: choose_text=TXT1;
                2: choose_text=TXT2;   3: choose_text=TXT3;
                4: choose_text=TXT4;   5: choose_text=TXT5;
                6: choose_text=TXT6;   7: choose_text=TXT7;
                8: choose_text=TXT8;   9: choose_text=TXT9;
                10: choose_text=TXT10; 11: choose_text=TXT11;
                12: choose_text=TXT12; 13: choose_text=TXT13;
                14: choose_text=TXT14; 15: choose_text=TXT15;
                16: choose_text=TXT16; 17: choose_text=TXT17;
                18: choose_text=TXT18; 19: choose_text=TXT19;
                20: choose_text=TXT20; 21: choose_text=TXT21;
                22: choose_text=TXT22; 23: choose_text=TXT23; 33: choose_text=TXT33;
                default: choose_text={24{8'h20}};
            endcase
        end
    endfunction

    function [34:0] glyph5x7;
        input [7:0] ch;
        begin
            case (ch)
                "A": glyph5x7={5'b01110,5'b10001,5'b10001,5'b11111,5'b10001,5'b10001,5'b10001};
                "B": glyph5x7={5'b11110,5'b10001,5'b10001,5'b11110,5'b10001,5'b10001,5'b11110};
                "C": glyph5x7={5'b01110,5'b10001,5'b10000,5'b10000,5'b10000,5'b10001,5'b01110};
                "D": glyph5x7={5'b11100,5'b10010,5'b10001,5'b10001,5'b10001,5'b10010,5'b11100};
                "E": glyph5x7={5'b11111,5'b10000,5'b10000,5'b11110,5'b10000,5'b10000,5'b11111};
                "F": glyph5x7={5'b11111,5'b10000,5'b10000,5'b11110,5'b10000,5'b10000,5'b10000};
                "G": glyph5x7={5'b01110,5'b10001,5'b10000,5'b10111,5'b10001,5'b10001,5'b01110};
                "H": glyph5x7={5'b10001,5'b10001,5'b10001,5'b11111,5'b10001,5'b10001,5'b10001};
                "I": glyph5x7={5'b11111,5'b00100,5'b00100,5'b00100,5'b00100,5'b00100,5'b11111};
                "K": glyph5x7={5'b10001,5'b10010,5'b10100,5'b11000,5'b10100,5'b10010,5'b10001};
                "L": glyph5x7={5'b10000,5'b10000,5'b10000,5'b10000,5'b10000,5'b10000,5'b11111};
                "M": glyph5x7={5'b10001,5'b11011,5'b10101,5'b10101,5'b10001,5'b10001,5'b10001};
                "N": glyph5x7={5'b10001,5'b11001,5'b10101,5'b10011,5'b10001,5'b10001,5'b10001};
                "O": glyph5x7={5'b01110,5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b01110};
                "P": glyph5x7={5'b11110,5'b10001,5'b10001,5'b11110,5'b10000,5'b10000,5'b10000};
                "R": glyph5x7={5'b11110,5'b10001,5'b10001,5'b11110,5'b10100,5'b10010,5'b10001};
                "S": glyph5x7={5'b01111,5'b10000,5'b10000,5'b01110,5'b00001,5'b00001,5'b11110};
                "T": glyph5x7={5'b11111,5'b00100,5'b00100,5'b00100,5'b00100,5'b00100,5'b00100};
                "U": glyph5x7={5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b01110};
                "V": glyph5x7={5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b01010,5'b00100};
                "W": glyph5x7={5'b10001,5'b10001,5'b10001,5'b10101,5'b10101,5'b10101,5'b01010};
                "X": glyph5x7={5'b10001,5'b10001,5'b01010,5'b00100,5'b01010,5'b10001,5'b10001};
                "Y": glyph5x7={5'b10001,5'b10001,5'b01010,5'b00100,5'b00100,5'b00100,5'b00100};
                "0": glyph5x7={5'b01110,5'b10001,5'b10011,5'b10101,5'b11001,5'b10001,5'b01110};
                "1": glyph5x7={5'b00100,5'b01100,5'b00100,5'b00100,5'b00100,5'b00100,5'b01110};
                "2": glyph5x7={5'b01110,5'b10001,5'b00001,5'b00010,5'b00100,5'b01000,5'b11111};
                "3": glyph5x7={5'b11110,5'b00001,5'b00001,5'b01110,5'b00001,5'b00001,5'b11110};
                "4": glyph5x7={5'b00010,5'b00110,5'b01010,5'b10010,5'b11111,5'b00010,5'b00010};
                "5": glyph5x7={5'b11111,5'b10000,5'b10000,5'b11110,5'b00001,5'b00001,5'b11110};
                "6": glyph5x7={5'b01110,5'b10000,5'b10000,5'b11110,5'b10001,5'b10001,5'b01110};
                "7": glyph5x7={5'b11111,5'b00001,5'b00010,5'b00100,5'b01000,5'b01000,5'b01000};
                "8": glyph5x7={5'b01110,5'b10001,5'b10001,5'b01110,5'b10001,5'b10001,5'b01110};
                "9": glyph5x7={5'b01110,5'b10001,5'b10001,5'b01111,5'b00001,5'b00001,5'b01110};
                "/": glyph5x7={5'b00001,5'b00010,5'b00010,5'b00100,5'b01000,5'b01000,5'b10000};
                "-": glyph5x7={5'b00000,5'b00000,5'b00000,5'b11111,5'b00000,5'b00000,5'b00000};
                ".": glyph5x7={5'b00000,5'b00000,5'b00000,5'b00000,5'b00000,5'b00110,5'b00110};
                ":": glyph5x7={5'b00000,5'b00110,5'b00110,5'b00000,5'b00110,5'b00110,5'b00000};
                "%": glyph5x7={5'b11001,5'b11010,5'b00100,5'b01000,5'b10110,5'b00110,5'b00000};
                default: glyph5x7=35'b0;
            endcase
        end
    endfunction

    function [191:0] format_percent;
        input [7:0] value;
        reg [7:0] v;
        reg [7:0] hundreds, tens, ones;
        begin
            v = (value > 100) ? 100 : value;
            hundreds = 8'h30 + (v / 100);
            tens     = 8'h30 + ((v / 10) % 10);
            ones     = 8'h30 + (v % 10);
            format_percent = {hundreds, tens, ones, "%", {20{8'h20}}};
        end
    endfunction

    function [191:0] format_temperature;
        input [10:0] tenths;
        reg [10:0] v;
        reg [7:0] hundreds, tens, ones, fraction;
        begin
            v = (tenths > 1250) ? 1250 : tenths;
            // Fixed-width display, e.g. 030.1C.
            hundreds = 8'h30 + ((v / 1000) % 10);
            tens     = 8'h30 + ((v / 100) % 10);
            ones     = 8'h30 + ((v / 10) % 10);
            fraction = 8'h30 + (v % 10);
            format_temperature = {hundreds, tens, ones, ".", fraction, "C", {18{8'h20}}};
        end
    endfunction

    function [191:0] format_ip;
        input [31:0] address;
        reg [7:0] a_h, a_t, a_o, b_h, b_t, b_o;
        reg [7:0] c_h, c_t, c_o, d_h, d_t, d_o;
        begin
            a_h=8'h30+((address[31:24]/100)%10); a_t=8'h30+((address[31:24]/10)%10); a_o=8'h30+(address[31:24]%10);
            b_h=8'h30+((address[23:16]/100)%10); b_t=8'h30+((address[23:16]/10)%10); b_o=8'h30+(address[23:16]%10);
            c_h=8'h30+((address[15:8]/100)%10);  c_t=8'h30+((address[15:8]/10)%10);  c_o=8'h30+(address[15:8]%10);
            d_h=8'h30+((address[7:0]/100)%10);   d_t=8'h30+((address[7:0]/10)%10);   d_o=8'h30+(address[7:0]%10);
            format_ip={"IP ",a_h,a_t,a_o,".",b_h,b_t,b_o,".",c_h,c_t,c_o,".",d_h,d_t,d_o,{6{8'h20}}};
        end
    endfunction

    // One shared text renderer keeps the pixel path compact.
    reg [5:0] text_id;
    reg [9:0] text_x0;
    reg [9:0] text_y0;
    reg text_scale2;
    reg [191:0] selected_text;
    reg [7:0] percent_value;
    reg [10:0] temperature_value;
    reg [31:0] ip_value;
    reg [10:0] text_dx, text_dy;
    reg [4:0] char_index;
    reg [2:0] char_col, char_row;
    reg [7:0] current_char;
    reg [34:0] current_glyph;
    reg text_pixel;

    always @(*) begin
        text_id=63;
        text_x0=0;
        text_y0=0;
        text_scale2=0;
        if (ui_y>=12 && ui_y<26 && ui_x>=24 && ui_x<300) begin text_id=0; text_x0=24; text_y0=12; text_scale2=1; end
        else if (ui_y>=38 && ui_y<45 && ui_x>=24 && ui_x<250) begin text_id=1; text_x0=24; text_y0=38; end
        else if (ui_y>=17 && ui_y<31 && ui_x>=590 && ui_x<730) begin text_id=2; text_x0=590; text_y0=17; text_scale2=1; end
        else if (ui_y>=84 && ui_y<98 && ui_x>=32 && ui_x<220) begin text_id=3; text_x0=32; text_y0=84; text_scale2=1; end
        else if (ui_y>=124 && ui_y<131 && ui_x>=32 && ui_x<50) begin text_id=4; text_x0=32; text_y0=124; end
        else if (ui_y>=154 && ui_y<161 && ui_x>=32 && ui_x<50) begin text_id=5; text_x0=32; text_y0=154; end
        else if (ui_y>=184 && ui_y<191 && ui_x>=32 && ui_x<50) begin text_id=6; text_x0=32; text_y0=184; end
        else if (ui_y>=214 && ui_y<221 && ui_x>=32 && ui_x<50) begin text_id=7; text_x0=32; text_y0=214; end
        else if (ui_y>=84 && ui_y<98 && ui_x>=426 && ui_x<620) begin text_id=8; text_x0=426; text_y0=84; text_scale2=1; end
        else if (ui_y>=120 && ui_y<127 && ui_x>=430 && ui_x<470) begin text_id=9; text_x0=430; text_y0=120; end
        else if (ui_y>=280 && ui_y<294 && ui_x>=30 && ui_x<190) begin text_id=10; text_x0=30; text_y0=280; text_scale2=1; end
        else if (ui_y>=321 && ui_y<328 && ui_x>=30 && ui_x<54) begin text_id=11; text_x0=30; text_y0=321; end
        else if (ui_y>=352 && ui_y<359 && ui_x>=30 && ui_x<54) begin text_id=12; text_x0=30; text_y0=352; end
        else if (ui_y>=383 && ui_y<390 && ui_x>=30 && ui_x<48) begin text_id=13; text_x0=30; text_y0=383; end
        else if (ui_y>=280 && ui_y<294 && ui_x>=430 && ui_x<590) begin text_id=14; text_x0=430; text_y0=280; text_scale2=1; end
        else if (ui_y>=322 && ui_y<329 && ui_x>=430 && ui_x<466) begin text_id=15; text_x0=430; text_y0=322; end
        else if (ui_y>=389 && ui_y<396 && ui_x>=430 && ui_x<500) begin text_id=16; text_x0=430; text_y0=389; end
        else if (ui_y>=462 && ui_y<469 && ui_x>=24 && ui_x<260) begin text_id=23; text_x0=24; text_y0=462; end
        else if (ui_y>=38 && ui_y<45 && ui_x>=560 && ui_x<680) begin text_id=33; text_x0=560; text_y0=38; end
        else if (ui_y>=124 && ui_y<131 && ui_x>=330 && ui_x<370) begin text_id=24; text_x0=330; text_y0=124; end
        else if (ui_y>=154 && ui_y<161 && ui_x>=330 && ui_x<370) begin text_id=25; text_x0=330; text_y0=154; end
        else if (ui_y>=184 && ui_y<191 && ui_x>=330 && ui_x<370) begin text_id=26; text_x0=330; text_y0=184; end
        else if (ui_y>=214 && ui_y<221 && ui_x>=330 && ui_x<370) begin text_id=27; text_x0=330; text_y0=214; end
        else if (ui_y>=120 && ui_y<127 && ui_x>=700 && ui_x<746) begin text_id=28; text_x0=700; text_y0=120; end
        else if (ui_y>=321 && ui_y<328 && ui_x>=70 && ui_x<112) begin text_id=29; text_x0=70; text_y0=321; end
        else if (ui_y>=352 && ui_y<359 && ui_x>=70 && ui_x<112) begin text_id=30; text_x0=70; text_y0=352; end
        else if (ui_y>=383 && ui_y<390 && ui_x>=70 && ui_x<112) begin text_id=31; text_x0=70; text_y0=383; end
        else if (ui_y>=322 && ui_y<329 && ui_x>=700 && ui_x<746) begin text_id=32; text_x0=700; text_y0=322; end

        selected_text=choose_text(text_id);
        percent_value=0;
        temperature_value=0;
        ip_value=metrics_reg6;
        case (text_id)
            24: percent_value=cpu0_pct;
            25: percent_value=cpu1_pct;
            26: percent_value=cpu2_pct;
            27: percent_value=cpu3_pct;
            28: percent_value=ram_pct;
            29: temperature_value=lpd_tenths;
            30: temperature_value=fpd_tenths;
            31: temperature_value=pl_tenths;
            32: percent_value=fan_pct;
            default: begin end
        endcase
        if (text_id>=24 && text_id<=28 || text_id==32)
            selected_text=format_percent(percent_value);
        else if (text_id>=29 && text_id<=31)
            selected_text=format_temperature(temperature_value);
        else if (text_id==33)
            selected_text=format_ip(ip_value);

        text_dx=ui_x-text_x0;
        text_dy=ui_y-text_y0;
        if (text_scale2) begin text_dx=text_dx>>1; text_dy=text_dy>>1; end
        char_index=text_dx/6;
        char_col=text_dx%6;
        char_row=text_dy[2:0];
        current_char=(char_index<24) ? selected_text[191-char_index*8 -: 8] : 8'h20;
        current_glyph=glyph5x7(current_char);
        text_pixel=(text_id!=63) && (char_col<5) && (char_row<7) &&
                   (text_dy<(text_scale2 ? 14 : 7)) &&
                   current_glyph[34-(char_row*5+char_col)];
    end

    // Horizontal live monitor. The values here come from AXI registers.
    always @(*) begin
        lcd_r=8'h05; lcd_g=8'h0A; lcd_b=8'h16;
        if (lcd_de) begin
            // Header and footer bands.
            if (ui_y<60) begin
                lcd_r=8'h0B; lcd_g=8'h17; lcd_b=8'h29;
                if (ui_y<3) begin lcd_r=8'h00; lcd_g=8'hC8; lcd_b=8'hB4; end
                if (ui_y==58 || ui_y==59) begin lcd_r=8'h22; lcd_g=8'h45; lcd_b=8'h61; end
                if (ui_x>=748 && ui_x<784 && ui_y>=12 && ui_y<48) begin lcd_r=8'h00; lcd_g=8'hC8; lcd_b=8'hB4; end
                if (ui_x>=754 && ui_x<778 && ui_y>=18 && ui_y<42) begin lcd_r=8'h0B; lcd_g=8'h17; lcd_b=8'h29; end
                if (ui_x>=761 && ui_x<771 && ui_y>=25 && ui_y<35) begin lcd_r=8'h00; lcd_g=8'hE0; lcd_b=8'hC4; end
                if (ui_y>=460) begin lcd_r=8'h0B; lcd_g=8'h17; lcd_b=8'h29; end
            end

            // CPU card: 4 values packed in REG0, one byte per Cortex-A53 core.
            if (ui_x>=16 && ui_x<394 && ui_y>=72 && ui_y<252) begin
                lcd_r=8'h12; lcd_g=8'h1D; lcd_b=8'h2D;
                if (ui_x==16 || ui_x==393 || ui_y==72 || ui_y==251) begin lcd_r=8'h24; lcd_g=8'h4A; lcd_b=8'h64; end
                if ((ui_y>=124 && ui_y<134) || (ui_y>=154 && ui_y<164) ||
                    (ui_y>=184 && ui_y<194) || (ui_y>=214 && ui_y<224)) begin
                    if (ui_x>=78 && ui_x<320) begin
                        lcd_r=8'h2A; lcd_g=8'h38; lcd_b=8'h4B;
                        if ((ui_y<134 && ui_x<78+cpu0_fill) ||
                            (ui_y>=154 && ui_y<164 && ui_x<78+cpu1_fill) ||
                            (ui_y>=184 && ui_y<194 && ui_x<78+cpu2_fill) ||
                            (ui_y>=214 && ui_y<224 && ui_x<78+cpu3_fill)) begin
                            lcd_r=8'h00; lcd_g=8'hC8; lcd_b=8'h88;
                        end
                    end
                end
            end

            // RAM card: REG1 is used memory percentage, from 0 to 100.
            if (ui_x>=406 && ui_x<784 && ui_y>=72 && ui_y<252) begin
                lcd_r=8'h12; lcd_g=8'h1D; lcd_b=8'h2D;
                if (ui_x==406 || ui_x==783 || ui_y==72 || ui_y==251) begin lcd_r=8'h24; lcd_g=8'h4A; lcd_b=8'h64; end
                if (ui_y>=155 && ui_y<174 && ui_x>=430 && ui_x<760) begin
                    lcd_r=8'h2A; lcd_g=8'h38; lcd_b=8'h4B;
                    if (ui_x<430+ram_fill) begin lcd_r=8'h00; lcd_g=8'h9C; lcd_b=8'hE8; end
                end
                if (ui_y>=181 && ui_y<184 && ((ui_x>=430 && ui_x<432) || (ui_x>=512 && ui_x<514) || (ui_x>=594 && ui_x<596) || (ui_x>=676 && ui_x<678) || (ui_x>=758 && ui_x<760))) begin lcd_r=8'h55; lcd_g=8'h78; lcd_b=8'h91; end
            end

            // Temperature card: LPD / FPD / PL values in tenths of degrees C.
            if (ui_x>=16 && ui_x<394 && ui_y>=268 && ui_y<456) begin
                lcd_r=8'h12; lcd_g=8'h1D; lcd_b=8'h2D;
                if (ui_x==16 || ui_x==393 || ui_y==268 || ui_y==455) begin lcd_r=8'h24; lcd_g=8'h4A; lcd_b=8'h64; end
                if ((ui_y>=330 && ui_y<339) || (ui_y>=361 && ui_y<370) || (ui_y>=392 && ui_y<401)) begin
                    if (ui_x>=120 && ui_x<370) begin
                        lcd_r=8'h2A; lcd_g=8'h38; lcd_b=8'h4B;
                        if ((ui_y<339 && ui_x<120+lpd_fill) ||
                            (ui_y>=361 && ui_y<370 && ui_x<120+fpd_fill) ||
                            (ui_y>=392 && ui_y<401 && ui_x<120+pl_fill)) begin
                            lcd_r=8'hF0; lcd_g=8'hB5; lcd_b=8'h42;
                        end
                    end
                end
            end

            // Fan card: REG5 is the duty percentage reported by Linux.
            if (ui_x>=406 && ui_x<784 && ui_y>=268 && ui_y<456) begin
                lcd_r=8'h12; lcd_g=8'h1D; lcd_b=8'h2D;
                if (ui_x==406 || ui_x==783 || ui_y==268 || ui_y==455) begin lcd_r=8'h24; lcd_g=8'h4A; lcd_b=8'h64; end
                if (ui_x>=430 && ui_x<760 && ui_y>=348 && ui_y<367) begin
                    lcd_r=8'h2A; lcd_g=8'h38; lcd_b=8'h4B;
                    if (ui_x<430+fan_fill) begin lcd_r=8'h00; lcd_g=8'hC8; lcd_b=8'h88; end
                end
                if (ui_x>=430 && ui_x<760 && (ui_y==375 || ui_y==376)) begin lcd_r=8'h55; lcd_g=8'h78; lcd_b=8'h91; end
            end

            // Footer separates the live telemetry view from the screen edge.
            if (ui_y>=458 && ui_y<460) begin lcd_r=8'h22; lcd_g=8'h45; lcd_b=8'h61; end

            // Text is the top layer so labels and live numbers stay crisp.
            if (text_pixel) begin lcd_r=8'hE8; lcd_g=8'hF2; lcd_b=8'hFF; end
        end
    end
endmodule


