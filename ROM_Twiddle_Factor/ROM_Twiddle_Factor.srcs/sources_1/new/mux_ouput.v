`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2025 08:41:35 AM
// Design Name: 
// Module Name: mux_ouput
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


module mux_output #(
    parameter integer TW_W = 32
)(
    input  wire signed [TW_W-1:0] cos_in,
    input  wire signed [TW_W-1:0] sin_in,
    input  wire signed [TW_W-1:0] inv_cos_in,
    input  wire signed [TW_W-1:0] inv_sin_in,
    input  wire [2:0] oct,
      
    output reg signed [TW_W-1:0] cos_out,
    output reg signed [TW_W-1:0] sin_out
);
    always @(*) begin
        case (oct)
            3'b000: begin
            cos_out = cos_in;
            sin_out = inv_sin_in;
            end
            3'b001: begin
            cos_out = sin_in;
            sin_out = inv_cos_in;
            end
            3'b010: begin
            cos_out = inv_sin_in;
            sin_out = inv_cos_in;
            end
            3'b011: begin
            cos_out = inv_cos_in;
            sin_out = inv_sin_in;
            end
            3'b100: begin
            cos_out = inv_cos_in;
            sin_out = sin_in;
            end
            3'b101: begin
            cos_out = inv_sin_in;
            sin_out = cos_in;
            end
            3'b110: begin
            cos_out = sin_in;
            sin_out = cos_in;
            end
            3'b111: begin
            cos_out = cos_in;
            sin_out = sin_in;
            end
        endcase
    end
    
endmodule
