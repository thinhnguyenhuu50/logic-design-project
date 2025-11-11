`timescale 1ns / 1ps

module ram_tb;
    reg [63:0] data_a, data_b;
    reg [4:0] addr_a, addr_b;
    reg we_a, we_b;
    reg clk;
    wire [63:0] q_a, q_b;

    // Instantiate the RAM module
    ram uut (
        .data_a(data_a),
        .data_b(data_b),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .we_a(we_a),
        .we_b(we_b),
        .clk(clk),
        .q_a(q_a),
        .q_b(q_b)
    );

    // Clock generation
    initial begin
        clk = 1'b1;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Test sequence
    initial begin
        // Initialize inputs
        we_a = 0; we_b = 0;
        addr_a = 0; addr_b = 0;
        data_a = 64'h0000000000000000; data_b = 64'h0000000000000000;

        // Write to port A
        #10;
        we_a = 1; addr_a = 5'd1; data_a = 64'hDEADBEEFDEADBEEF;
        #10;
        we_a = 0; addr_a = 5'd1;

        // Read from port A
        #10;
        
        // Write to port B
        we_b = 1; addr_b = 5'd2; data_b = 64'hCAFEBABECAFEBABE;
        #10;
        we_b = 0; addr_b = 5'd2;

        // Read from port B
        #10;

        // Finish simulation
        #20;
        $finish;
    end

endmodule
