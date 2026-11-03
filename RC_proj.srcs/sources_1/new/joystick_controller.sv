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
    
    // Decoded Outputs
    output logic [9:0] joy_x,
    output logic [9:0] joy_y,
    output logic btn_jstk,
    output logic btn_trigger
);

    // 1. Clock Divider: 100MHz to 1MHz (1 microsecond per tick)
    logic [6:0] clk_div = 0;
    logic tick_1mhz;
    assign tick_1mhz = (clk_div == 99);
    
    always_ff @(posedge clk) begin
        if (rst || tick_1mhz) clk_div <= 0;
        else clk_div <= clk_div + 1;
    end

    // 2. JSTK2 Specific SPI State Machine
    localparam IDLE = 0, CS_LOW_WAIT = 1, SHIFT = 2, BYTE_DELAY = 3, CS_HIGH = 4;
    logic [2:0] state = IDLE;
    
    logic [9:0] read_timer = 0;
    logic [5:0] delay_cnt = 0;
    logic [2:0] byte_cnt = 0;
    logic [3:0] bit_cnt = 0;
    logic sclk_phase = 0;
    logic [39:0] shift_in = 0;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            pmod_cs_n <= 1'b1;
            pmod_sclk <= 1'b0;
            pmod_mosi <= 1'b0; 
            joy_x <= 512;
            joy_y <= 512;
            btn_jstk <= 0;
            btn_trigger <= 0;
        end 
        else if (tick_1mhz) begin
            case (state)
                IDLE: begin
                    pmod_cs_n <= 1'b1;
                    pmod_sclk <= 1'b0;
                    byte_cnt <= 0;
                    bit_cnt <= 0;
                    if (read_timer == 999) begin // 1ms polling
                        state <= CS_LOW_WAIT;
                        read_timer <= 0;
                        pmod_cs_n <= 1'b0; // Wake up the PIC MCU!
                        delay_cnt <= 0;
                    end else begin
                        read_timer <= read_timer + 1;
                    end
                end
                
                CS_LOW_WAIT: begin
                    // JSTK2 requires at least 15us delay before first clock edge
                    if (delay_cnt == 20) begin 
                        state <= SHIFT;
                        sclk_phase <= 0;
                    end else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end
                
                SHIFT: begin
                    if (sclk_phase == 0) begin
                        pmod_sclk <= 1'b1; // Rising edge
                        shift_in <= {shift_in[38:0], pmod_miso};
                        sclk_phase <= 1;
                    end else begin
                        pmod_sclk <= 1'b0; // Falling edge
                        sclk_phase <= 0;
                        
                        if (bit_cnt == 7) begin
                            bit_cnt <= 0;
                            if (byte_cnt == 4) begin
                                state <= CS_HIGH; // All 5 bytes read
                            end else begin
                                byte_cnt <= byte_cnt + 1;
                                state <= BYTE_DELAY;
                                delay_cnt <= 0;
                            end
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end
                end
                
                BYTE_DELAY: begin
                    // JSTK2 requires at least 10us delay between bytes
                    if (delay_cnt == 15) begin 
                        state <= SHIFT;
                    end else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end
                
                CS_HIGH: begin
                    pmod_cs_n <= 1'b1; // End SPI transaction
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