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
                      BallSize = 2
)(
    input clk,
    input rst,
    
    input btnl,
    input btnr,
    
    output signed [15:0] bx_o,
    output signed [15:0] by_o,
    output signed [15:0] px_o,
    output signed [15:0] py_o
);        
    logic frame_enable;
    
    frametimer #(FRAME_TIME, CLK_FREQ) ft (clk, rst, frame_enable);
    
    logic signed [15:0] bx = (Width / 2)  << FractionalBits, 
                        px = (Width / 2)  << FractionalBits;
    
    logic signed [15:0] by = (Height / 2) << FractionalBits;
    logic        [15:0] py = Height - PaddleHeight - 1;
    
    logic signed [6:0] rx, ry;
    
    // generate pseudo random num bw 16 & 31
    rand_gen r(clk, rst, rx, ry);
    
    logic signed [15:0] bvx = rx, 
                        bvy = ry;
    
    assign bx_o = bx >>> FractionalBits;
    assign by_o = by >>> FractionalBits;
    assign px_o = px >>> FractionalBits;
    assign py_o = py;
    
    typedef enum { S_IDLE, S_PLAYING, S_OVER } st;
    
    st state = S_IDLE, next_state = S_IDLE;
    
    logic jstk_ip = 0;
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
                    // TODO: change
                    if (btnl == 1 || btnr == 1) next_state = S_PLAYING;
                end
                S_PLAYING: begin
                    if (game_over) next_state = S_OVER;
                end
                S_OVER: begin
                    if (btnl == 1 || btnr == 1) next_state = S_IDLE;
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
    
    logic signed [15:0] paddle_speed;
    assign paddle_speed = (btnr - btnl) * MaxPaddleVelocity << FractionalBits;
    
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
                    bvy <= -bvy; 
                end
                // ball fell below the paddle
                else begin
                    game_over <= 1;
                end
            end
        end
    end
endmodule
