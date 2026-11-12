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
        
    output logic pmod_cs_n,
    output logic pmod_mosi,
    input  logic pmod_miso,
    output logic pmod_sclk,
        
    output [3:0] vga_r,
    output [3:0] vga_g,
    output [3:0] vga_b,
    output       vga_hs,
    output       vga_vs
);

    // game parameters
    localparam PaddleWidth = 50, 
               PaddleHeight = 5, 
               MaxBallVelocity = 12, 
               BallSize = 5,
               FractionalBits = 10,
               Width = 640,
               Height = 480,
               MaxPaddleVelocity = 7,
               InitialXVel = 24,
               InitialYVel = 16,
               MaxW = 32;

    logic [1:0] clk_div = 0;
    always @(posedge clk) begin
        if (rst) clk_div <= 0;
        else clk_div <= clk_div + 1;
    end
    logic pxl_clk;
    assign pxl_clk = clk_div[1]; 

    localparam H_DISPLAY = Width,
               H_FRONT   = 16, 
               H_SYNC    = 96,
               H_BACK    = 48,
               H_TOTAL   = 800; 

    localparam V_DISPLAY = Height,
               V_FRONT   = 10,
               V_SYNC    = 2,
               V_BACK    = 33,
               V_TOTAL   = 525; 

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
    
    logic video_on;
    assign video_on = (h_cnt < H_DISPLAY) && (v_cnt < V_DISPLAY);
    
    logic [9:0] pixel_x;
    assign pixel_x = h_cnt;
    
    logic [9:0] pixel_y;
    assign pixel_y = v_cnt;
    
    // Frame Tick: Triggers exactly once per frame (60 times a second)
    logic frame_tick;
    assign frame_tick = (h_cnt == 0) && (v_cnt == V_TOTAL - 1);

    logic [9:0] joy_x;
    logic [9:0] joy_y;
    logic btn_jstk;
    logic btn_trigger;

    // read joystick data
    joystick_controller j(
        .clk(clk),
        .rst(rst),
        
        .joy_x(joy_x),
        .joy_y(joy_y),
        
        .btn_jstk(btn_jstk),
        .btn_trigger(btn_trigger),
        
        .pmod_cs_n(pmod_cs_n),
        .pmod_mosi(pmod_mosi),
        .pmod_miso(pmod_miso),
        .pmod_sclk(pmod_sclk)
    );


    logic signed [MaxW - 1:0] bx, by, px, py;
    
    // convert 25Mhz to 100Mhz
    logic frame_tick_delay = 0;
    always_ff @(posedge clk) begin
        if (rst) frame_tick_delay <= 0;
        else     frame_tick_delay <= frame_tick;
    end

    logic frame_enable;
    assign frame_enable = frame_tick && ~frame_tick_delay;
    
    logic [3:0] score_ones, score_tens;
        
    // update game
    paddle #(
            .Width(Width), 
            .Height(Height), 
            .PaddleWidth(PaddleWidth), 
            .PaddleHeight(PaddleHeight), 
            .BallSize(BallSize), 
            .FractionalBits(FractionalBits), 
            .MaxBallVelocity(MaxBallVelocity),
            .MaxPaddleVelocity(MaxPaddleVelocity),
            .MaxW(MaxW)
     ) p(
        .clk(clk),
        .rst(rst),
        .bx_o(bx),
        .by_o(by),
        .px_o(px),
        .py_o(py),
        .joy_x(joy_x),
        .frame_enable(frame_enable),
        .score_tens(score_tens),
        .score_ones(score_ones),
        .jstk_btn(btn_jstk)
    );

    // Check if the current electron beam position is inside the paddle
    logic draw_paddle;
    assign draw_paddle = (pixel_x >= px - PaddleWidth / 2) && (pixel_x < px + PaddleWidth / 2) &&
                       (pixel_y >= py) && (pixel_y < py + PaddleHeight);

    // Check if the current electron beam position is inside the ball
    logic draw_ball;
    assign draw_ball = (pixel_x >= bx) && (pixel_x < bx + BallSize) &&
                     (pixel_y >= by) && (pixel_y < by + BallSize);


    // Define the bounding boxes and sizes for the two digits
    localparam TENS_X_START = 299;
    localparam ONES_X_START = 325; 
    localparam DIGIT_WIDTH  = 16;
    localparam DIGIT_HEIGHT = 24;
    localparam DIGIT_Y      = 15;  

    logic in_tens_box;
    assign in_tens_box = (pixel_x >= TENS_X_START && pixel_x < TENS_X_START + DIGIT_WIDTH) &&
                         (pixel_y >= DIGIT_Y      && pixel_y < DIGIT_Y + DIGIT_HEIGHT);
                         
    logic in_ones_box;
    assign in_ones_box = (pixel_x >= ONES_X_START && pixel_x < ONES_X_START + DIGIT_WIDTH) &&
                         (pixel_y >= DIGIT_Y      && pixel_y < DIGIT_Y + DIGIT_HEIGHT);
    // Multiplexer: Which digit and X-coordinate should the renderer use right now?
    logic [3:0] current_digit;
    logic [9:0] current_x_start; // Assuming pixel_x is 10 bits

    always_comb begin
        if (in_tens_box) begin
            current_digit = score_tens;
            current_x_start = TENS_X_START;
        end
        else if (in_ones_box) begin
            current_digit = score_ones;
            current_x_start = ONES_X_START;
        end
        else begin
            // Default values when the electron beam is outside the score area
            current_digit = 0;
            current_x_start = 0;
        end
    end

    // Instantiate the digit renderer ONCE to save FPGA logic
    logic draw_score_pixel;
    
    in_digit #(
        .Width(640), 
        .Height(480), 
        .BitWidth(16), 
        .StrokeThickness(4) // You can adjust thickness here
    ) score_renderer (
        .digit(current_digit),
        .screen_left(current_x_start),
        .screen_top(DIGIT_Y),
        .dig_width(DIGIT_WIDTH),
        .dig_height(DIGIT_HEIGHT),
        .cur_left(pixel_x),
        .cur_top(pixel_y),
        .in_digit(draw_score_pixel)
    );

    // Safety mask: Only allow the score to be drawn if we are actually inside one of the boxes.
    // (Otherwise, it will draw a '0' at the very top-left corner of the screen!)
    logic draw_score;
    assign draw_score = draw_score_pixel && (in_tens_box || in_ones_box);


    // The pixel is ON if it is inside the active display area AND (it's the paddle OR the ball)
    logic pixel_on;
    assign pixel_on = video_on && (draw_paddle || draw_ball || draw_score);

    // Monochrome color mapping: White if pixel_on, Black if not.
    assign vga_r = pixel_on ? 4'hF : 4'h0;
    assign vga_g = pixel_on ? 4'hF : 4'h0;
    assign vga_b = pixel_on ? 4'hF : 4'h0;
endmodule
