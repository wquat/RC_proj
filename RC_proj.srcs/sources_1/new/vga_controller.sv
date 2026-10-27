`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.10.2026 13:15:45
// Design Name: 
// Module Name: vga_controller
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


module vga_controller (
    input clk,
    input rst,
    
    input btnl,
    input btnr,
        
    output [3:0] vga_r,
    output [3:0] vga_g,
    output [3:0] vga_b,
    output       vga_hs,
    output       vga_vs
);

    localparam PaddleWidth = 50, 
               PaddleHeight = 5, 
               MaxBallVelocity = 5, 
               BallSize = 5,
               FractionalBits = 4,
               Width = 640,
               Height = 480,
               InitialXVel = 24,
               InitialYVel = 16;

    logic [1:0] clk_div = 0;
    always @(posedge clk) begin
        if (rst) clk_div <= 0;
        else clk_div <= clk_div + 1;
    end
    logic pxl_clk = clk_div[1]; 

    localparam H_DISPLAY = Width; localparam H_FRONT = 16;
    localparam H_SYNC    = 96;  localparam H_BACK  = 48;
    localparam H_TOTAL   = 800; 

    localparam V_DISPLAY = Height; localparam V_FRONT = 10;
    localparam V_SYNC    = 2;   localparam V_BACK  = 33;
    localparam V_TOTAL   = 525; 

    logic [9:0] h_cnt = 0;
    logic [9:0] v_cnt = 0;
    
    always @(posedge pxl_clk) begin
        if (rst) begin
            h_cnt <= 0; v_cnt <= 0;
        end else begin
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 0;
                if (v_cnt == V_TOTAL - 1) v_cnt <= 0;
                else v_cnt <= v_cnt + 1;
            end else begin
                h_cnt <= h_cnt + 1;
            end
        end
    end

    assign vga_hs = ~(h_cnt >= (H_DISPLAY + H_FRONT) && h_cnt < (H_DISPLAY + H_FRONT + H_SYNC));
    assign vga_vs = ~(v_cnt >= (V_DISPLAY + V_FRONT) && v_cnt < (V_DISPLAY + V_FRONT + V_SYNC));
    logic video_on = (h_cnt < H_DISPLAY) && (v_cnt < V_DISPLAY);
    
    logic [9:0] pixel_x = h_cnt;
    logic [9:0] pixel_y = v_cnt;
    
    // Frame Tick: Triggers exactly once per frame (60 times a second)
    logic frame_tick = (h_cnt == 0) && (v_cnt == V_TOTAL - 1);

    logic signed [15:0] bx, by, px, py;
    
    paddle #(
            .Width(Width), 
            .Height(Height), 
            .PaddleWidth(PaddleWidth), 
            .PaddleHeight(PaddleHeight), 
            .BallSize(BallSize), 
            .FractionalBits(FractionalBits), 
            .MaxBallVelocity(MaxBallVelocity)
     ) p(
        .clk(clk),
        .rst(rst),
        .bx_o(bx),
        .by_o(by),
        .px_o(px),
        .py_o(py),
        .btnl(btnl),
        .btnr(btnr)
    );

    // Check if the current electron beam position is inside the paddle
    logic draw_paddle = (pixel_x >= px - PaddleWidth / 2) && (pixel_x < px + PaddleWidth / 2) &&
                       (pixel_y >= py) && (pixel_y < py + PaddleHeight);

    // Check if the current electron beam position is inside the ball
    logic draw_ball = (pixel_x >= bx) && (pixel_x < bx + BallSize) &&
                     (pixel_y >= by) && (pixel_y < by + BallSize);

    // The pixel is ON if it is inside the active display area AND (it's the paddle OR the ball)
    logic pixel_on = video_on && (draw_paddle || draw_ball);

    // Monochrome color mapping: White if pixel_on, Black if not.
    assign vga_r = pixel_on ? 4'hF : 4'h0;
    assign vga_g = pixel_on ? 4'hF : 4'h0;
    assign vga_b = pixel_on ? 4'hF : 4'h0;
endmodule
