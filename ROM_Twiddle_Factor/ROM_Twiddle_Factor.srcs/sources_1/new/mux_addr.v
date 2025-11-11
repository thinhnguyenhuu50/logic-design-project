`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2025 04:39:27 PM
// Design Name: 
// Module Name: mux_addr
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


module mux_addr#(
    parameter ADDR_W = 5
)(
    input  wire  oct_0,            // 3 bit cao
    input  wire [ADDR_W-1:0] off,     // 5 bit thấp
    output wire [ADDR_W-1:0] rom_addr // đầu ra cho ROM
);
    // Nếu octant lẻ => đảo chỉ số (N/8 - off = 31 - off) 
    assign rom_addr = oct_0 ? (5'd0 - off) : off;
endmodule
