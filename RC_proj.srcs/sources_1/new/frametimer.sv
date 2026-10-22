`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.09.2026 13:23:37
// Design Name: 
// Module Name: frametimer
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

 //                               frametime in milliseconds
module frametimer #(parameter int FRAME_TIME = 16, parameter int CLK_FREQ = 100_000_000)( 
    input clk,
    input rst,
    output logic frame_enable
    );
    
    localparam int MAX_COUNT = (CLK_FREQ / 1000) * FRAME_TIME; 
    logic [26:0] counter = 0;
        
    always_ff @(posedge clk) begin
        if (rst == 1) counter <= 0;
        else begin
            if (counter == MAX_COUNT - 1) counter <= 0;
            else counter <= counter + 1;
        end
    end


    assign frame_enable = counter == 0; 
endmodule
