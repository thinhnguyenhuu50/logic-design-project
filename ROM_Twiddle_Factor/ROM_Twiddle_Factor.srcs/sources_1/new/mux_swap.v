`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2025 04:39:27 PM
// Design Name: 
// Module Name: mux_swap
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


module mux_swap #(
    parameter integer TW_W = 32
)(
    input  wire signed [TW_W-1:0] cos_in,
    input  wire signed [TW_W-1:0] sin_in,
    input  wire swap_en,  
    output wire signed [TW_W-1:0] cos_out,
    output wire signed [TW_W-1:0] sin_out
);
    assign cos_out = swap_en ? sin_in : cos_in;
    assign sin_out = swap_en ? cos_in : sin_in;
endmodule
