`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Thinh
// 
// Create Date: 11/11/2025 01:37:48 PM
// Design Name: Dual Port RAM
// Module Name: ram
// Description: I don't even know how it could work
//////////////////////////////////////////////////////////////////////////////////

module ram(
    input [63:0] data_a, data_b,
    input [4:0] addr_a, addr_b,
    input we_a, we_b,
    input clk,
    output reg [63:0] q_a, q_b
);  

    reg [63:0] mem [31:0];  // mem storage

    always @(posedge clk) begin
        if (we_a) begin
            mem[addr_a] <= data_a;
            // q_a <= data_a;  // Write-first behavior
        end else begin
            q_a <= mem[addr_a];
        end
    end

    always @(posedge clk) begin
        if (we_b) begin
            mem[addr_b] <= data_b;
            // q_b <= data_b;  // Write-first behavior
        end else begin
            q_b <= mem[addr_b];
        end
    end

endmodule
