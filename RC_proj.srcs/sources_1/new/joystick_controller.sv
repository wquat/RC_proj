`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.10.2026 13:11:13
// Design Name: 
// Module Name: joystick_controller
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


module joystick_controller(
    input  logic clk,
    input  logic rst,
    
    // Physical Pmod Pins
    output logic pmod_cs_n,
    output logic pmod_mosi,
    input  logic pmod_miso,
    output logic pmod_sclk,
    
    // Decoded Outputs for your game
    output logic [9:0] joy_x,
    output logic [9:0] joy_y,
    output logic btn_jstk,
    output logic btn_trigger
);

    // 1. Clock Divider: 100MHz to 1MHz for SPI Clock
    logic [6:0] clk_div = 0;
    logic tick_1mhz;
    assign tick_1mhz = (clk_div == 99);
    
    always @(posedge clk) begin
        if (rst || tick_1mhz) clk_div <= 0;
        else clk_div <= clk_div + 1;
    end

    // 2. State Machine for SPI Transfer
    localparam IDLE = 0, CS_LOW = 1, SHIFT = 2, CS_HIGH = 3;
    logic [1:0] state = IDLE;
    
    logic [9:0] read_timer = 0;  // Triggers a read every 1ms
    logic [5:0] bit_cnt = 0;     // Counts the 40 bits (5 bytes)
    logic sclk_phase = 0;        // Toggles to create SCLK edges
    logic [39:0] shift_in = 0;   // Stores the 5 incoming bytes

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            pmod_cs_n <= 1'b1;
            pmod_sclk <= 1'b0;
            pmod_mosi <= 1'b0; // We leave MOSI low (Turns off JSTK2 LED)
            joy_x <= 512;      // 512 is dead center
            joy_y <= 512;
        end 
        else if (tick_1mhz) begin
            case (state)
                IDLE: begin
                    pmod_cs_n <= 1'b1;
                    pmod_sclk <= 1'b0;
                    if (read_timer == 999) begin // 1ms elapsed
                        state <= CS_LOW;
                        read_timer <= 0;
                    end else begin
                        read_timer <= read_timer + 1;
                    end
                end
                
                CS_LOW: begin
                    pmod_cs_n <= 1'b0; // Pull CS low to wake up joystick
                    state <= SHIFT;
                    bit_cnt <= 0;
                    sclk_phase <= 0;
                end
                
                SHIFT: begin
                    if (sclk_phase == 0) begin
                        // SPI Mode 0: Capture MISO on Rising Edge
                        pmod_sclk <= 1'b1;
                        shift_in <= {shift_in[38:0], pmod_miso};
                        sclk_phase <= 1'b1;
                    end else begin
                        // SPI Mode 0: Setup next bit on Falling Edge
                        pmod_sclk <= 1'b0;
                        sclk_phase <= 1'b0;
                        if (bit_cnt == 39) state <= CS_HIGH;
                        else bit_cnt <= bit_cnt + 1;
                    end
                end
                
                CS_HIGH: begin
                    pmod_cs_n <= 1'b1; // End SPI transaction
                    
                    // Decode the 5 Bytes according to Digilent Datasheet
                    // shift_in[39:32] = Byte 1 (X LSB)
                    // shift_in[31:24] = Byte 2 (X MSB)
                    // shift_in[23:16] = Byte 3 (Y LSB)
                    // shift_in[15:8]  = Byte 4 (Y MSB)
                    // shift_in[7:0]   = Byte 5 (Buttons)
                    
                    joy_x <= {shift_in[25:24], shift_in[39:32]};
                    joy_y <= {shift_in[9:8],   shift_in[23:16]};
                    
                    btn_jstk    <= shift_in[0];
                    btn_trigger <= shift_in[1];
                    
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
