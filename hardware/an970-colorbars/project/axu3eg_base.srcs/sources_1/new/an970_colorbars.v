`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.10.2026 01:24:00
// Design Name: 
// Module Name: an970_colorbars
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


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
    output lcd_backlight_pwm
    );
    
        // AN970: temporización horizontal, en ciclos de pixel_clk
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
    
    assign lcd_backlight_pwm = 1'b1;
    assign lcd_dclk = pixel_clk;
    assign lcd_hsync = 1'b1;
    assign lcd_vsync = 1'b1;
    assign lcd_de =
        (h_count >= H_SYNC + H_BACK) &&
        (h_count <  H_SYNC + H_BACK + H_ACTIVE) &&
        (v_count >= V_SYNC + V_BACK) &&
        (v_count <  V_SYNC + V_BACK + V_ACTIVE);
    
    wire [10:0] active_x = h_count - (H_SYNC + H_BACK);
        
        
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
    
          always @(*) begin
             // Por defecto, fuera del área visible mostramos negro.
             lcd_r = 8'h00;
             lcd_g = 8'h00;
             lcd_b = 8'h00;

    if (lcd_de) begin
        if (active_x < 100) begin          // Blanco
            lcd_r = 8'hFF; lcd_g = 8'hFF; lcd_b = 8'hFF;
        end else if (active_x < 200) begin // Amarillo
            lcd_r = 8'hFF; lcd_g = 8'hFF; lcd_b = 8'h00;
        end else if (active_x < 300) begin // Cian
            lcd_r = 8'h00; lcd_g = 8'hFF; lcd_b = 8'hFF;
        end else if (active_x < 400) begin // Verde
            lcd_r = 8'h00; lcd_g = 8'hFF; lcd_b = 8'h00;
        end else if (active_x < 500) begin // Magenta
            lcd_r = 8'hFF; lcd_g = 8'h00; lcd_b = 8'hFF;
        end else if (active_x < 600) begin // Rojo
            lcd_r = 8'hFF; lcd_g = 8'h00; lcd_b = 8'h00;
        end else if (active_x < 700) begin // Azul
            lcd_r = 8'h00; lcd_g = 8'h00; lcd_b = 8'hFF;
        end
    end
end
    
endmodule

