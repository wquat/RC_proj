`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.11.2026 13:25:35
// Design Name: 
// Module Name: digit_gen
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
// t: top, tl: top left, tr: top right, m: middle, bl: bottom left, br: bottom right, b: bottom
// format: t, tl, tr, m, bl, br, b;
module digit_gen(
    input logic [3:0] digit,
    output logic [6:0] out
);
    
    logic [6:0] segments [0:9];

    always_comb begin
        segments[0] = 7'b1110111; 
        segments[1] = 7'b0010010; 
        segments[2] = 7'b1011101; 
        segments[3] = 7'b1011011; 
        segments[4] = 7'b0111010; 
        segments[5] = 7'b1101011; 
        segments[6] = 7'b1101111; 
        segments[7] = 7'b1010010; 
        segments[8] = 7'b1111111; 
        segments[9] = 7'b1111011; 
        
        if (digit > 9) out = 7'b0000000;
        else           out = segments[digit];
    end   
endmodule
