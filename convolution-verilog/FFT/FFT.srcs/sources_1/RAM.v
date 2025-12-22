module RAM #(
    parameter DATA_WIDTH = 64, 
    parameter MEM_DEPTH  = 64,
    localparam ADDR_WIDTH = $clog2(MEM_DEPTH) 
) (
    input [DATA_WIDTH-1:0] data_a, 
    input [ADDR_WIDTH-1:0] addr_a, 
    input we_a, 
    output reg [DATA_WIDTH-1:0] q_a,

    input [DATA_WIDTH-1:0] data_b, 
    input [ADDR_WIDTH-1:0] addr_b, 
    input we_b, 
    output reg [DATA_WIDTH-1:0] q_b,
    
    input clk
);
    reg [DATA_WIDTH-1:0] mem [MEM_DEPTH-1:0];
    always @(posedge clk) begin
        if (we_a) begin
            mem[addr_a] <= data_a;
        end else begin
            q_a <= mem[addr_a];
        end
    end
    always @(posedge clk) begin
        if (we_b) begin
            mem[addr_b] <= data_b;
        end else begin
            q_b <= mem[addr_b];
        end
    end
endmodule
