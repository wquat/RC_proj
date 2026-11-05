`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.09.2026 13:22:33
// Design Name: 
// Module Name: paddle
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


module paddle #(
        parameter int FRAME_TIME = 16, 
                      CLK_FREQ = 100_000_000, 
                      Width = 640, 
                      Height = 480, 
                      PaddleWidth = 10, 
                      PaddleHeight = 2, 
                      MaxBallVelocity = 5, 
                      MaxPaddleVelocity = 5, 
                      FractionalBits = 0, 
                      BallSize = 2,
                      MaxW = 16
)(
    input clk,
    input rst,
    
    input [9:0] joy_x,
    
    input logic frame_enable,
    
    output signed [MaxW - 1:0] bx_o,
    output signed [MaxW - 1:0] by_o,
    output signed [MaxW - 1:0] px_o,
    output signed [MaxW - 1:0] py_o
);        
    logic signed [MaxW - 1:0] bx = (Width / 2)  << FractionalBits, 
                        px = (Width / 2)  << FractionalBits;
    
    logic signed [MaxW - 1:0] by = (Height / 2) << FractionalBits;
    logic        [MaxW - 1:0] py = Height - PaddleHeight - 1;
    
    logic signed [MaxW - 1:0] rx, ry;
    
    // generate pseudo random num bw 16 & 31
    rand_gen #(.FractionalBits(FractionalBits)) r(clk, rst, rx, ry);
    
    logic signed [MaxW - 1:0] bvx = rx, 
                              bvy = ry;
    
    assign bx_o = bx >>> FractionalBits;
    assign by_o = by >>> FractionalBits;
    assign px_o = px >>> FractionalBits;
    assign py_o = py;
    
    logic signed [MaxW - 1:0] bounce_bvx, bounce_bvy; 
    
    // 2. Pre-calculate the fixed-point max speed so you don't do it over and over
    localparam signed [MaxW - 1:0] MAX_V_FP = MaxBallVelocity << FractionalBits;

    logic signed [MaxW - 1:0] temp_x;
    logic signed [MaxW - 1:0] temp_y;

    always_comb begin
        // + 3.12%
        temp_x = bvx + (bvx >>> 4);
        temp_y = bvy + (bvy >>> 4);
        
        // Clamp X Velocity (comparing fixed-point to fixed-point)
        if (temp_x > MAX_V_FP)       bounce_bvx = MAX_V_FP;
        else if (temp_x < -MAX_V_FP) bounce_bvx = -MAX_V_FP;
        else                         bounce_bvx = temp_x;
        
        // Clamp Y Velocity
        if (temp_y > MAX_V_FP)       bounce_bvy = MAX_V_FP;
        else if (temp_y < -MAX_V_FP) bounce_bvy = -MAX_V_FP;
        else                         bounce_bvy = temp_y;
    end    
    
    typedef enum { S_IDLE, S_PLAYING, S_OVER } st;
    
    st state = S_IDLE, next_state = S_IDLE;
    
    logic jstk_ip = (joy_x > 600 || joy_x < 420);
    logic signed [MaxW - 1:0] paddle_speed;
    
    always_comb begin
        if (joy_x > 700) 
            paddle_speed = (MaxPaddleVelocity << FractionalBits);
        else if (joy_x > 600) 
            paddle_speed = (MaxPaddleVelocity << FractionalBits) >> 1;
        else if (joy_x > 550) 
            paddle_speed = (MaxPaddleVelocity << FractionalBits) >> 2;
        else if (joy_x < 300) 
            paddle_speed = -(MaxPaddleVelocity << FractionalBits); 
        else if (joy_x < 420) 
            paddle_speed = -((MaxPaddleVelocity << FractionalBits) >> 1);
        else if (joy_x < 470) 
            paddle_speed = -((MaxPaddleVelocity << FractionalBits) >> 2);
        else 
            paddle_speed = 0;                                             
    end
    
    logic game_over = 0; 
    
    // get next state
    always @(*) begin 
        next_state = state;
        if (rst) begin
            next_state = S_IDLE;
        end
        else begin
            case (state)
                S_IDLE: begin
                    if (jstk_ip) next_state = S_PLAYING;
                end
                S_PLAYING: begin
                    if (game_over) next_state = S_OVER;
                end
                S_OVER: begin
                    if (jstk_ip) next_state = S_IDLE;
                end
            endcase
        end
    end
    
    // update state
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end
        else begin
            state <= next_state;
        end
    end
        
    // update game logic
    always_ff @(posedge clk) begin
        if (rst || state == S_IDLE) begin
            px  <= (Width  / 2) << FractionalBits;
            bx  <= (Width  / 2) << FractionalBits;
            by  <= (Height / 2) << FractionalBits;
            bvx <= rx; 
            bvy <= ry;
            game_over <= 0;
        end
        else if (state == S_PLAYING && frame_enable) begin
            game_over <= 0;
            bx <= bx + bvx;
            by <= by + bvy;
            
            // control paddle
            if (
                    (px + paddle_speed) >= (PaddleWidth / 2) << FractionalBits && 
                    (px + paddle_speed) <= (Width - PaddleWidth / 2) << FractionalBits
                ) begin
                px <= px + paddle_speed;
            end
            else begin 
                if ((px + paddle_speed) < (PaddleWidth / 2) << FractionalBits) 
                    px <= (PaddleWidth / 2) << FractionalBits;
                if ((px + paddle_speed) > (Width - PaddleWidth / 2) << FractionalBits) 
                    px <= (Width - PaddleWidth / 2) << FractionalBits;
            end
            
            // control ball
            if (bx + bvx >= ((Width - BallSize) << FractionalBits)) begin
                bx <= (Width - BallSize) << FractionalBits;
                bvx <= -bvx; 
            end 
            if (bx + bvx <= 0) begin
                bx <= 0;
                bvx <= -bvx; 
            end 
            if (by + bvy <= 0) begin
                by <= 0;
                bvy <= -bvy; 
            end 
            if (by + bvy > ((Height - PaddleHeight - BallSize) << FractionalBits)) begin
                if (
                    bx + bvx >= px - ((PaddleWidth / 2) << FractionalBits) && 
                    bx + bvx <= px + ((PaddleWidth / 2) << FractionalBits)
                 ) begin
                    by <= ((Height - PaddleHeight - BallSize) << FractionalBits);
                    bvy <= -bounce_bvy;
                    bvx <= bounce_bvx; 
                end
                // ball fell below the paddle
                else begin
                    game_over <= 1;
                end
            end
        end
    end
endmodule
