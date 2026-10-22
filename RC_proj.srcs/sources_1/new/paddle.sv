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


module paddle #(parameter int FRAME_TIME = 16, parameter int CLK_FREQ = 100_000_000, parameter int Width = 96, parameter int Height = 48)(
    input clk,
    input rst
);

    // parameters, constants and variables
    localparam int PaddleWidth = 10;
    localparam int PaddleHeight = 2;
    localparam int MaxBallVelocity = 2;
    localparam int FractionalBits = 0; // Power of two precision past the decimal point
    localparam int BallSize = 2;
    localparam int IntitialXVel = 1, IntitialYVel = 1;
        
    logic frame_enable;
    
    frametimer #(FRAME_TIME, CLK_FREQ) (clk, rst, frame_enable);
    
    logic signed [15:0] bx = (Width / 2)  << FractionalBits, 
                        px = (Width / 2)  << FractionalBits;
    
    logic signed [15:0] by = (Height / 2) << FractionalBits;
    logic        [15:0] py = Height - PaddleHeight - 1;
    
    logic signed [15:0] bvx = IntitialXVel << FractionalBits, 
                        bvy = IntitialYVel << FractionalBits;
    
    typedef enum { S_IDLE, S_PLAYING, S_OVER } st;
    
    st state = S_IDLE, next_state = S_IDLE;
    
    logic jstk_ip = 0;
    logic game_over = 0;
    
    logic [15:0] bsx,
                 psx;
    logic [15:0] bsy;
 
    // get screen coords
    assign bsx = bx >>> FractionalBits;
    assign bsy = by >>> FractionalBits;
    assign psx = px >>> FractionalBits;
    
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
            bvx <= IntitialXVel  << FractionalBits; 
            bvy <= IntitialYVel  << FractionalBits;
            game_over <= 0;
        end
        else if (state == S_PLAYING && frame_enable) begin
            game_over <= 0;
            bx <= bx + bvx;
            by <= by + bvy;
            
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
