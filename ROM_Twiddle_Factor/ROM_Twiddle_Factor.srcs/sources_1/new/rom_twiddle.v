`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2025 04:39:27 PM
// Design Name: 
// Module Name: rom_twiddle
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


module rom_twiddle#(
    parameter integer ADDR_W = 5,
    parameter integer TW_W = 32,
    parameter integer QS = 32
)(  
//    input wire clk,
    input  wire [ADDR_W-1:0]  addr,
    output reg  signed [TW_W-1:0] cos_q,
    output reg  signed [TW_W-1:0] sin_q
);
    reg [TW_W-1:0] COS_LUT [0:QS-1];
    reg [TW_W-1:0] SIN_LUT [0:QS-1];

    initial begin
        $display("Loading twiddle factor ROM data...");
        $readmemh("cos_rom_256_oct0.data", COS_LUT);
        $readmemh("sin_rom_256_oct0.data", SIN_LUT);
        $display("ROM data successfully loaded %h", SIN_LUT[0]);
        $display("ROM data successfully loaded.");
    end

//    always @(posedge clk) begin
    always @(*) begin
        cos_q <= COS_LUT[addr];
        sin_q <= SIN_LUT[addr];
    end
endmodule
