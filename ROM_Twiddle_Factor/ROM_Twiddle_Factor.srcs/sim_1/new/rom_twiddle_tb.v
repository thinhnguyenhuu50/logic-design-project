`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2025 09:26:08 PM
// Design Name: 
// Module Name: rom_twiddle_tb
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


module rom_twiddle_tb;

    // --- signals ---
    reg clk;
    reg en;
    reg [7:0] tw_idx;
    wire [63:0] tw_factor;

    // --- instantiate DUT (Device Under Test) ---
    rom_twiddle_top DUT (
//        .clk(clk),
        .en(en),
        .tw_idx(tw_idx),
        .tw_factor(tw_factor)
    );
   

    // --- clock generation (10 ns period = 100 MHz) ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- stimulus ---
    initial begin
        // Initialize signals
        en = 0;
        tw_idx = 0;
        #10;      // wait a bit
        en = 1;

        // Iterate through several twiddle indices
        $display("\n=== Start Simulation ===");
        $display("k\tcos_out (hex)\tsin_out (hex)");
        $display("----------------------------------");

        tw_idx = 0;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);
        #10
        tw_idx = 1;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);
        #10 
        tw_idx = 32;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);
        #10
        tw_idx = 35;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);
        #10
        tw_idx = 64;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);
        #10
        tw_idx = 65;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);
        #10
        tw_idx = 96;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);
        #10
        tw_idx = 97;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);
        #10
        tw_idx = 128;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);
        #10
        tw_idx = 130;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);
        #10
        tw_idx = 160;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);
        #10
        tw_idx = 162;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);
        #10
        tw_idx = 192;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);
        #10
        tw_idx = 193;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);
        #10
        tw_idx = 224;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);
        #10
        tw_idx = 225;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);
        #10
        tw_idx = 255;
        $display("cos out %h", tw_factor[31:0]);
        $display("sin out %h", tw_factor[63:32]);

        $display("=== End Simulation ===\n");
        #20;
        $stop;
    end

endmodule
