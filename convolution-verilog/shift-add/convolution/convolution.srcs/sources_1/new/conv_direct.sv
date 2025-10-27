`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2025 11:35:00 AM
// Design Name: 
// Module Name: conv_direct
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


module conv_direct #(
    parameter int N = 5,                       // number of taps
    parameter int DATA_W  = 16,                // input sample width (signed)
    parameter int COEFF_W = 16,                // coeff width (signed)
    // Coefficients (generic). Override on instantiation.
    parameter logic signed [COEFF_W-1:0] COEFFS [N] = '{
        16'sd1, 16'sd2, 16'sd3, 16'sd2, 16'sd1
    }
) (
    input  logic                      clk,
    input  logic                      rst,      // synchronous, active-high
    input  logic signed [DATA_W-1:0]  sample_in,
    input  logic                      sample_in_valid,
    output logic signed [ACC_W-1:0]   sample_out,
    output logic                      sample_out_valid
);
    // Accumulator width: input + coeff + ceil(log2(N))
    localparam int ACC_W = DATA_W + COEFF_W + $clog2(N);

    // Shift register for last N samples (x[n], x[n-1], ..., x[n-N+1])
    logic signed [DATA_W-1:0] x [N];

    // Products and sum
    logic signed [DATA_W+COEFF_W-1:0] prod [N];
    logic signed [ACC_W-1:0]          acc;

    // Valid pipeline (1-cycle latency here)
    logic vld_d;

    // Shift new sample when valid
    integer i;
    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i++) x[i] <= '0;
            vld_d <= 1'b0;
        end else begin
            vld_d <= sample_in_valid;
            if (sample_in_valid) begin
                x[0] <= sample_in;
                for (i = 1; i < N; i++) begin
                    x[i] <= x[i-1];
                end
            end
        end
    end

    // Parallel multiply
    genvar k;
    generate
        for (k = 0; k < N; k++) begin : GEN_MUL
            always_comb prod[k] = x[k] * COEFFS[k];
        end
    endgenerate

    // Sum of products (simple loop; tools build an adder tree)
    always_comb begin
        acc = '0;
        for (int j = 0; j < N; j++) begin
            acc = acc + {{(ACC_W-(DATA_W+COEFF_W)){prod[j][DATA_W+COEFF_W-1]}}, prod[j]};
        end
    end

    // Register the output (1-cycle latency from valid)
    always_ff @(posedge clk) begin
        if (rst) begin
            sample_out        <= '0;
            sample_out_valid  <= 1'b0;
        end else begin
            sample_out        <= acc;
            sample_out_valid  <= vld_d;
        end
    end
endmodule