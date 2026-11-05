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


module rand_gen #(
    parameter int FractionalBits = 0
)(
    input  logic clk,
    input  logic rst,
    output logic signed [31:0] rx,
    output logic signed [31:0] ry
);
    logic [31:0] lfsr_x;
    logic [31:0] lfsr_y;
    
    // Standard taps for a 32-bit LFSR (Bits 32, 22, 2, 1)
    logic feedback_x = lfsr_x[31] ^ lfsr_x[21] ^ lfsr_x[1] ^ lfsr_x[0];
    logic feedback_y = lfsr_y[31] ^ lfsr_y[21] ^ lfsr_y[1] ^ lfsr_y[0];
    
    always_ff @(posedge clk) begin
        if (rst) begin
            // 32-bit Hex Seeds
            lfsr_x <= 32'hDEADBEEF; 
            lfsr_y <= 32'hCAFEBABE;
        end
        else begin 
            lfsr_x <= {lfsr_x[30:0], feedback_x};
            lfsr_y <= {lfsr_y[30:0], feedback_y};
        end
    end
    
    localparam int BaseSpeed = 1 << FractionalBits;
    localparam int RandMask = (1 << FractionalBits) - 1;
    
    wire [31:0] mag_x = BaseSpeed + (lfsr_x & RandMask);
    wire [31:0] mag_y = BaseSpeed + (lfsr_y & RandMask);
    
    assign rx = lfsr_x[31] ? -mag_x : mag_x; 
    assign ry = lfsr_y[31] ? -mag_y : mag_y;

endmodule