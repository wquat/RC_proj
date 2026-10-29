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
    output logic signed [6:0] rx,
    output logic signed [6:0] ry
);
    logic [7:0] lfsr_reg_x;
    logic [7:0] lfsr_reg_y;
    
    // The "taps" for an 8-bit LFSR that ensure maximum sequence length (255)
    logic feedback_x = lfsr_reg_x[7] ^ lfsr_reg_x[5] ^ lfsr_reg_x[4] ^ lfsr_reg_x[3];
    logic feedback_y = lfsr_reg_y[7] ^ lfsr_reg_y[5] ^ lfsr_reg_y[4] ^ lfsr_reg_y[3];
    
    always_ff @(posedge clk) begin
        if (rst) begin
            lfsr_reg_x <= 8'b10101010;
            lfsr_reg_y <= 8'b01101110;
        end
        else begin 
            lfsr_reg_x <= {lfsr_reg_x[6:0], feedback_x};
            lfsr_reg_y <= {lfsr_reg_y[6:0], feedback_y};
        end
    end
    
    assign rx = lfsr_reg_x[7] ? -(7'd16 + {3'b0, lfsr_reg_x[3:0]}) : (7'd16 + {3'b0, lfsr_reg_x[3:0]}); 
    assign ry = lfsr_reg_y[7] ? -(7'd16 + {3'b0, lfsr_reg_y[3:0]}) : (7'd16 + {3'b0, lfsr_reg_y[3:0]});
endmodule