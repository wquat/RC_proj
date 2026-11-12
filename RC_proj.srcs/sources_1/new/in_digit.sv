`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.11.2026 13:39:05
// Design Name: 
// Module Name: in_digit
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


module in_digit #(parameter int Width = 640, Height = 480, BitWidth = 16, StrokeThickness = 3)(
    input logic [3:0] digit,
    input logic [$clog2(Width) - 1:0] screen_left,
    input logic [$clog2(Width) - 1:0] screen_top,
    input logic [BitWidth - 1:0] dig_width,
    input logic [BitWidth - 1:0] dig_height,
    
    input logic [$clog2(Width) - 1:0] cur_left,
    input logic [$clog2(Width) - 1:0] cur_top,
    
    output logic in_digit
);
    
    // this is intentional (otherwise flipped digits!)
    logic [0:6] locs;
    // Assumes locs mapping is: {b, br, bl, m, tr, tl, t} 
    // so locs[0]=t, locs[1]=tl, locs[2]=tr, locs[3]=m, locs[4]=bl, locs[5]=br, locs[6]=b
    digit_gen g(digit, locs);
    
    logic t, tr, tl, m, bl, br, b;
    
    always_comb begin
        // ALWAYS default to 0 to prevent inferred latches
        t = 0; tl = 0; tr = 0; m = 0; bl = 0; br = 0; b = 0;
        
        // [0] Top segment (Full width, top thickness)
        if (locs[0] && cur_top >= screen_top && cur_top <= screen_top + StrokeThickness && cur_left >= screen_left && cur_left <= screen_left + dig_width)
            t = 1;
            
        // [1] Top-Left segment (Left thickness, top half)
        if (locs[1] && cur_top >= screen_top && cur_top <= screen_top + (dig_height >> 1) && cur_left >= screen_left && cur_left <= screen_left + StrokeThickness)
            tl = 1;
            
        // [2] Top-Right segment (Right thickness, top half)
        if (locs[2] && cur_top >= screen_top && cur_top <= screen_top + (dig_height >> 1) && cur_left >= screen_left + dig_width - StrokeThickness && cur_left <= screen_left + dig_width)
            tr = 1;
            
        // [3] Middle segment (Full width, center thickness)
        if (locs[3] && cur_top >= screen_top + (dig_height >> 1) - (StrokeThickness >> 1) && cur_top <= screen_top + (dig_height >> 1) + (StrokeThickness >> 1) && cur_left >= screen_left && cur_left <= screen_left + dig_width)
            m = 1;
            
        // [4] Bottom-Left segment (Left thickness, bottom half)
        if (locs[4] && cur_top >= screen_top + (dig_height >> 1) && cur_top <= screen_top + dig_height && cur_left >= screen_left && cur_left <= screen_left + StrokeThickness)
            bl = 1;
            
        // [5] Bottom-Right segment (Right thickness, bottom half)
        if (locs[5] && cur_top >= screen_top + (dig_height >> 1) && cur_top <= screen_top + dig_height && cur_left >= screen_left + dig_width - StrokeThickness && cur_left <= screen_left + dig_width)
            br = 1;
            
        // [6] Bottom segment (Full width, bottom thickness)
        if (locs[6] && cur_top >= screen_top + dig_height - StrokeThickness && cur_top <= screen_top + dig_height && cur_left >= screen_left && cur_left <= screen_left + dig_width)
            b = 1;
            
        // Combine them all: If the pixel is inside ANY active segment, output 1
        in_digit = t | tl | tr | m | bl | br | b;
    end
endmodule
