`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.10.2026 14:40:25
// Design Name: 
// Module Name: rand_gen
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


module rand_gen(
    input clk,
    input rst,
    output logic [3:0] rx,
    output logic [3:0] ry
);
    logic [7:0] lfsr_reg;
    
    // The "taps" for an 8-bit LFSR that ensure maximum sequence length (255)
    logic feedback = lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[3];
    
    always_ff @(posedge clk) begin
        if (rst) 
            lfsr_reg <= 8'b10101010;
        else 
            lfsr_reg <= {lfsr_reg[6:0], feedback};
    end
    
    assign rx = lfsr_reg[3:0]; 
    assign ry = lfsr_reg[7:4]; 
endmodule
