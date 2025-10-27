`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2025 10:33:03 AM
// Design Name: 
// Module Name: tb_conv_direct
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

module tb_conv_direct;

  // ---- Match your DUT parameters ----
  localparam int N        = 5;
  localparam int DATA_W   = 16;
  localparam int COEFF_W  = 16;
  localparam int CLK_PERIOD = 10;   // 100 MHz

  // Coefficients (example). Replace with yours.
  localparam logic signed [COEFF_W-1:0] COEFFS [N] = '{
      16'sd1024, 16'sd4096, 16'sd6144, 16'sd4096, 16'sd1024
  };

  // Derived like the DUT (DATA + COEFF + ceil(log2(N)))
  localparam int ACC_W = DATA_W + COEFF_W + $clog2(N);

  // ---- DUT I/O ----
  logic clk;
  logic rst;
  logic signed [DATA_W-1:0]  sample_in;
  logic                      sample_in_valid;
  logic signed [ACC_W-1:0]   sample_out;
  logic                      sample_out_valid;

  // ---- Instantiate DUT ----
  conv_direct #(
      .N(N),
      .DATA_W(DATA_W),
      .COEFF_W(COEFF_W),
      .COEFFS(COEFFS)
  ) dut (
      .clk(clk),
      .rst(rst),
      .sample_in(sample_in),
      .sample_in_valid(sample_in_valid),
      .sample_out(sample_out),
      .sample_out_valid(sample_out_valid)
  );

  // ---- Clock ----
  initial clk = 1'b0;
  always #(CLK_PERIOD/2) clk = ~clk;

  // ======================================================================
  // Reference "software" convolution (bit-exact)
  // ======================================================================

  // Keep a history shift register mirroring the DUT semantics
  logic signed [DATA_W-1:0] ref_x [N];

  // Queue of expected sums aligned to DUT latency (1 cycle)
  typedef logic signed [ACC_W-1:0] acc_t;
  acc_t expected_q[$];

  // Function to perform one MAC sum with DUT's sign-extension rules
  function automatic acc_t mac_sum (
      input logic signed [DATA_W-1:0]  xr   [N],
      input logic signed [COEFF_W-1:0] coeff[N]
  );
    acc_t acc;
    logic signed [DATA_W+COEFF_W-1:0] prod;
    acc = '0;
    for (int j = 0; j < N; j++) begin
      prod = xr[j] * coeff[j];
      // Sign-extend product to ACC_W then accumulate (matches DUT)
      acc  = acc + {{(ACC_W-(DATA_W+COEFF_W)){prod[DATA_W+COEFF_W-1]}}, prod};
    end
    return acc;
  endfunction

  // Push an expected value corresponding to the sample we are applying now.
  // IMPORTANT: We compute with the *next* shift state (including new sample),
  // because the DUT produces that sum on the next cycle when out_valid=1.
  task automatic ref_push_expected(input logic signed [DATA_W-1:0] new_sample);
    logic signed [DATA_W-1:0] next_x [N];
    // Build next shift state (new at index 0)
    next_x[0] = new_sample;
    for (int i = 1; i < N; i++) next_x[i] = ref_x[i-1];

    // Compute expected sum for next state and enqueue
    expected_q.push_back( mac_sum(next_x, COEFFS) );

    // Commit the shift (mirror DUT's shift on valid)
    for (int i = N-1; i > 0; i--) ref_x[i] = ref_x[i-1];
    ref_x[0] = new_sample;
  endtask

  // ======================================================================
  // Stimulus + Self-checking
  // ======================================================================

  int num_tests   = 64;
  int num_pass    = 0;
  int num_fail    = 0;

  initial begin
    // Optional: VCD for external viewers (Vivado's Sim GUI works without this)
    $dumpfile("conv_wave.vcd");
    $dumpvars(0, tb_conv_direct);

    // Init
    rst = 1;
    sample_in = '0;
    sample_in_valid = 0;
    for (int i=0; i<N; i++) ref_x[i] = '0;
    expected_q = {};

    // Reset a few cycles
    repeat (5) @(posedge clk);
    rst = 0;

    // Drive a sequence of samples with valid=1 every cycle
    for (int k = 0; k < num_tests; k++) begin
      @(posedge clk);
      
      begin : APPLY_SAMPLE    // <-- new scope so you can declare local vars here
          logic signed [DATA_W-1:0] new_sample;
          new_sample = $signed($urandom_range(-200, 200));
        
          sample_in        <= new_sample; // nice small range
          sample_in_valid  <= 1'b1;
    
          // Build reference & queue expected result for next cycle
          ref_push_expected(new_sample);
      end
    end

    // Deassert valid
    @(posedge clk);
    sample_in_valid <= 1'b0;
    sample_in       <= '0;

    // Let pipeline drain
    repeat (N+5) @(posedge clk);

    // Report
    $display("\n==================================================");
    $display(" CONV TB DONE: pass=%0d  fail=%0d", num_pass, num_fail);
    $display("==================================================\n");

    if (num_fail == 0) $finish;
    else               $fatal(1, "Test FAILED with %0d mismatches.", num_fail);
  end

  // On each cycle where DUT claims valid, pop and compare
  always @(posedge clk) begin
    if (!rst && sample_out_valid) begin
      if (expected_q.size() == 0) begin
        num_fail++;
        $error("[%0t] DUT asserted valid but expected queue empty!", $time);
      end else begin
        acc_t exp = expected_q.pop_front();
        if (sample_out !== exp) begin
          num_fail++;
          $error("[%0t] MISMATCH: got=%0d (0x%0h)  exp=%0d (0x%0h)",
                 $time, sample_out, sample_out, exp, exp);
        end else begin
          num_pass++;
          // Uncomment for verbose trace:
          // $display("[%0t] MATCH:  %0d", $time, sample_out);
        end
      end
    end
  end

endmodule
