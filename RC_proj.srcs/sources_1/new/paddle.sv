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
                      FractionalBits = 0, 
                      BallSize = 2,
                      InitialXVel = 1,
                      InitialYVel = 1
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
    
    frametimer #(FRAME_TIME, CLK_FREQ) (clk, rst, frame_enable);
    
    logic signed [15:0] bx = (Width / 2)  << FractionalBits, 
                        px = (Width / 2)  << FractionalBits;
    
    logic signed [15:0] by = (Height / 2) << FractionalBits;
    logic        [15:0] py = Height - PaddleHeight - 1;
    
    logic signed [15:0] bvx = InitialXVel << FractionalBits, 
                        bvy = InitialYVel << FractionalBits;
    
    assign bx_o = bx;
    assign by_o = by;
    assign px_o = px;
    assign py_o = py;
    
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
    
    // update game logic
    always_ff @(posedge clk) begin
        if (rst || state == S_IDLE) begin
            px  <= (Width  / 2) << FractionalBits;
            bx  <= (Width  / 2) << FractionalBits;
            by  <= (Height / 2) << FractionalBits;
            bvx <= InitialXVel  << FractionalBits; 
            bvy <= InitialYVel  << FractionalBits;
            game_over <= 0;
        end
        else if (state == S_PLAYING && frame_enable) begin
            game_over <= 0;
            bx <= bx + bvx;
            by <= by + bvy;
            
            if ((px + 2 * (btnr - btnl)) > PaddleWidth / 2 && (px + 2 * (btnr - btnl)) < Width - PaddleWidth / 2) begin
                px <= px + 2 * (btnr - btnl);
            end
            
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
