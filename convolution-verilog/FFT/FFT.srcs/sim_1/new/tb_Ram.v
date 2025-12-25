`timescale 1ns / 1ps

module tb_Ram;

    // 1. Define Parameters to match RAM.v defaults
    parameter DATA_WIDTH = 64;
    parameter MEM_DEPTH  = 64;
    // Calculate Address Width: log2(64) = 6 bits [5:0]
    localparam ADDR_WIDTH = $clog2(MEM_DEPTH);

    // 2. Updated Register Widths to use Parameters
    reg [DATA_WIDTH-1:0] data_a, data_b;
    reg [ADDR_WIDTH-1:0] addr_a, addr_b; // Fixed: Dynamic width instead of hardcoded [4:0]
    reg we_a, we_b;
    reg clk;

    // Outputs
    wire [DATA_WIDTH-1:0] q_a, q_b;

    // 3. Instantiate the RAM module
    // Metched module name 'RAM' (Case Sensitive) and passed parameters
    RAM #(
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) uut (
        .data_a(data_a), 
        .addr_a(addr_a), 
        .we_a(we_a), 
        .q_a(q_a),
        .data_b(data_b), 
        .addr_b(addr_b), 
        .we_b(we_b), 
        .q_b(q_b),
        .clk(clk)
    );

    // Clock generation
    initial begin
        clk = 1'b1;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Test sequence
    initial begin
        // Monitor changes for debugging
        $monitor("Time=%0t | WeA=%b AddrA=%d DataA=%h Qa=%h | WeB=%b AddrB=%d DataB=%h Qb=%h", 
                 $time, we_a, addr_a, data_a, q_a, we_b, addr_b, data_b, q_b);

        // Initialize inputs
        we_a = 0; we_b = 0;
        addr_a = 0; addr_b = 0;
        data_a = 0; data_b = 0;

        // --- Write to port A ---
        #10;
        we_a = 1; 
        addr_a = 'd1; // Address 1
        data_a = 64'hDEADBEEFDEADBEEF;
        
        #10;
        we_a = 0; 
        // keep addr_a at 1 to read back in next cycle

        // --- Read from port A ---
        // data should appear on q_a on the next posedge
        #10;

        // --- Write to port B ---
        we_b = 1; 
        addr_b = 'd2; // Address 2
        data_b = 64'hCAFEBABECAFEBABE;
        
        #10;
        we_b = 0;
        // keep addr_b at 2 to read back

        // --- Read from port B ---
        #10;
        
        // --- Simultaneous Read/Write check (Optional) ---
        // Write to Addr 5 via Port A, Read Addr 1 via Port B
        we_a = 1;
        addr_a = 'd5;
        data_a = 64'h1234567812345678;
        
        addr_b = 'd1; // Reading the DEADBEEF value written earlier
        #10;
        we_a = 0;

        // Finish simulation
        #20;
        $finish;
    end

endmodule