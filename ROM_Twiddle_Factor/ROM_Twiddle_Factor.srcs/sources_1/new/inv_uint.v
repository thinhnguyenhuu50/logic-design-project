`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2025 04:39:27 PM
// Design Name: 
// Module Name: inv_uint
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


module inv_uint#(
    parameter integer TW_W = 32
)(
    input  wire signed [TW_W-1:0] in_val,
    output wire signed [TW_W-1:0] out_val
);
    assign out_val = {~in_val[TW_W-1], in_val[TW_W-2:0]};
endmodule
