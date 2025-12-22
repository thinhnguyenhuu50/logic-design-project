module Inv_FP#(
    parameter integer TW_W = 32
)(
    input  wire signed [TW_W-1:0] in_val,
    output wire signed [TW_W-1:0] out_val
);
    assign out_val = {~in_val[TW_W-1], in_val[TW_W-2:0]};
endmodule

//module RTL_ALU_Add(
//input sign1,
//input [23:0] in1,
//input sign2,
//input [23:0] in2,
//output [25:0] out
//);
//wire [25:0] w1;
//wire [25:0] w2;
//wire [25:0] data1;
//wire [25:0] data2;
//assign w1 = {2'b00, in1};
//assign w2 = {2'b00, in2};
//assign data1 = sign1? -w1 : w1;
//assign data2 = sign2? -w2 : w2; 
//assign out = data1 + data2;
//endmodule

//module Shift_Right(
//input [22:0] in1,
//input [22:0] in2,
//input n_zero1,
//input n_zero2,
//input compare,
//input [4:0] shift,
//output [23:0] out1,
//output [23:0] out2
//);
//wire [23:0] data1;
//wire [23:0] data2;
//wire [23:0] w1;
//assign data1 = {n_zero1, in1};
//assign data2 = {n_zero2, in2};
//assign w1 = compare? data2 : data1;
//assign out2 = compare? data1 : data2;
//assign out1 = w1 >> shift;
//endmodule 

//module Exponent_Difference(
//input [7:0] in1,
//input [7:0] in2,
//output [4:0] shift,
//output compare
//);
//wire [8:0] w1;
//wire [8:0] w2;
//assign w1 = {1'b0, in2} - {1'b0, in1};
//assign compare = w1[8];
//assign w2 = w1[8]? -w1 : w1;
//assign shift = (w2 > 9'd24)? 5'd24 : w2[4:0];
//endmodule

module priority_encoder #(
    parameter WIDTH = 8
) (
    input  [WIDTH-1:0] in,
    output reg [$clog2(WIDTH)-1:0] out,
    output reg valid
);
    integer i;
    always @(*) begin
        out = 0;
        valid = 1'b0;
        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            if (in[i] & !valid) begin
                out = WIDTH - 1 - i;
                valid = 1'b1;
            end
        end
    end
endmodule

//module Rounding_Normalize(
//input [25:0] data_in,
//input [7:0] great_exponent,
//output [31:0] data_out
//);
//wire [24:0] w1;
//wire [7:0] w2;
//wire [4:0] shift_left;
//wire non_zero;
//assign w1 = data_in[25]? -data_in : data_in;
//priority_encoder #(.WIDTH(24)) H1 (.in(w1[23:0]), .out(shift_left), .valid(non_zero));
//assign data_out[31] = data_in[25];
//assign w2 = w1[24]? great_exponent + 1'b1 : great_exponent - shift_left;
//assign data_out[30:23] = (non_zero | w1[24])? w2 : 8'd0;
//assign data_out[22:0] = w1[24]? w1[23:1] : w1[22:0] << shift_left;
//endmodule

//module Add_FP(
//input [31:0] in1,
//input [31:0] in2,
//output [31:0] data_out
//);
//wire [4:0] shift_right;
//wire [23:0] w1;
//wire [23:0] w2;
//wire [25:0] w3;
//wire compare;
//wire sign1;
//wire sign2;
//wire [7:0] great_exponent;
//assign great_exponent = compare? in1[30:23] : in2[30:23];
//assign sign1 = compare? in2[31] : in1[31];
//assign sign2 = compare? in1[31] : in2[31];
//Exponent_Difference A0(.in1(in1[30:23]), .in2(in2[30:23]), .shift(shift_right), .compare(compare));
//Shift_Right A1(.in1(in1[22:0]), .in2(in2[22:0]), .n_zero1( ~(!in1[30:23])), .n_zero2( ~(!in2[30:23])), .compare(compare), .shift(shift_right), .out1(w1), .out2(w2));
//RTL_ALU_Add A2(.sign1(sign1), .in1(w1), .sign2(sign2), .in2(w2), .out(w3));
//Rounding_Normalize A3(.data_in(w3), .great_exponent(great_exponent), .data_out(data_out));
//endmodule

module AFP_Compare_Exponents(
input wire [31:0]   in1,
input wire [31:0]   in2,
input clk,
//Output
output reg [4:0]    shift,
output reg          compare,
output reg [7:0]    exp1,
output reg [7:0]    exp2,
output reg          sign1,
output reg          sign2,
output reg [22:0]   fra1,
output reg [22:0]   fra2
);
wire [8:0] w1;
wire [8:0] w2;
assign w1 = {1'b0, in2[30:23]} - {1'b0, in1[30:23]};
//assign compare = w1[8];
assign w2 = w1[8]? -w1 : w1;
//assign shift = (w2 > 9'd24)? 5'd24 : w2[4:0];

always @(posedge clk) begin
    compare <= w1[8];
    shift   <= (w2 > 9'd25)? 5'd25 : w2[4:0];
    exp1    <= in1[30:23];
    exp2    <= in2[30:23];
    sign1   <= in1[31];
    sign2   <= in2[31];
    fra1    <= in1[22:0];
    fra2    <= in2[22:0];
end
endmodule

module AFP_Shift(
input               clk,
input wire [4:0]    shift,
input wire          compare,// 0: 1 < 2, 1: 1 > 2
input wire [7:0]    exp1,
input wire [7:0]    exp2,
input wire          sign1,
input wire          sign2,
input wire [22:0]   fra1,
input wire [22:0]   fra2,
//Output
output reg [7:0]    exp,
output reg [24:0]   fra_out1,
output reg [24:0]   fra_out2,
output reg          op,
output reg          sign
);
wire [7:0]  exp_temp;
wire [24:0] data1;
wire [24:0] data2;
wire [24:0] w1;
wire        n_zero;
assign exp_temp = compare? exp1 : exp2;
assign n_zero = |exp_temp;
assign data1 = compare? {n_zero, fra2, 1'b0} : {n_zero, fra1, 1'b0};
assign data2 = compare? {1'b1, fra1, 1'b0} : {1'b1, fra2, 1'b0};
assign w1 = data1 >> shift;
always @(posedge clk) begin
    op <= sign1 ^ sign2; // 0: + , 1: -
    sign <= compare? sign1 : sign2;
    exp <= compare? exp1 : exp2;
    fra_out1 <= w1;
    fra_out2 <= data2;
end
endmodule

module AFP_Add(
input               clk,
input wire [7:0]    exp,
input wire [24:0]   fra1,
input wire [24:0]   fra2,
input wire          op,
input wire          sign,

output reg [7:0]    exp_out,
output reg [25:0]   fra,
output reg          sign_out
);
wire [26:0] w1;
assign w1 = op? {2'b00, fra2} - {2'b00, fra1} : {2'b00, fra2} + {2'b00, fra1};

always @(posedge clk) begin
    exp_out <= exp;
    fra <= w1[26]? -w1 : w1;
    sign_out <= w1[26] ^ sign;
end
endmodule

module AFP_Normal(
input               clk,
input wire [7:0]    exp_in,
input wire [25:0]   fra_in,
input wire          sign_in,
output reg [4:0]    shift_left,
output reg          non_zero,
output reg [7:0]    exp,
output reg [25:0]   fra,
output reg          sign
);
wire w1;
wire [4:0] w2;
priority_encoder #(.WIDTH(25)) H1 (.in(fra_in[24:0]), .out(w2), .valid(w1));
always @(posedge clk) begin
    exp <= exp_in;
    fra <= fra_in;
    sign <= sign_in;
    shift_left <= w2;
    non_zero <= w1;
end
endmodule

module AFP_Rounding(
input               clk,
input wire [4:0]    shift_left,
input wire          non_zero,
input wire [7:0]    exp,
input wire [25:0]   fra,
input wire          sign,
output reg [31:0]    FP_out
);
wire [25:0] w1;
wire [23:0] fra_out;
wire [7:0] w2;
//assign data_out[31] = data_in[25];
assign w1 = (fra << shift_left);
assign w2 = fra[25]? exp + 1'b1 : exp - shift_left;
//assign data_out[30:23] = (non_zero | w1[24])? w2 : 8'd0;
//assign data_out[22:0] = w1[24]? w1[23:1] : w1[22:0] << shift_left;
assign fra_out = fra[25]? fra[24:1] : w1[23:0];
always @(posedge clk) begin
    FP_out[31] <= sign;
    FP_out[30:23] <= (non_zero | fra[25])? w2 : 8'd0;
    FP_out[22:0] <= fra_out[23:1];
end
endmodule


module Add_FP(
    input  wire        clk,
    input  wire [31:0] in1,
    input  wire [31:0] in2,
    output wire [31:0] data_out
);

    // =================================================================
    // 1. INTERCONNECT WIRES
    // =================================================================

    // --- Stage 1 (Compare) -> Stage 2 (Shift) ---
    wire [4:0]  w1_shift;
    wire        w1_compare;
    wire [7:0]  w1_exp1;
    wire [7:0]  w1_exp2;
    wire        w1_sign1;
    wire        w1_sign2;
    wire [22:0] w1_fra1;
    wire [22:0] w1_fra2;

    // --- Stage 2 (Shift) -> Stage 3 (Add) ---
    wire [7:0]  w2_exp;
    wire [26:0] w2_fra1; // Width 27 (24 data + 3 GRS)
    wire [26:0] w2_fra2;
    wire        w2_op;
    wire        w2_sign;

    // --- Stage 3 (Add) -> Stage 4 (Normalize) ---
    wire [7:0]  w3_exp;
    wire [27:0] w3_fra;  // Width 28 (1 Carry + 27 Data)
    wire        w3_sign;

    // --- Stage 4 (Normalize) -> Stage 5 (Rounding) ---
    wire [4:0]  w4_shift;
    wire        w4_nzero;
    wire [7:0]  w4_exp;
    wire [27:0] w4_fra;
    wire        w4_sign;

    // --- Stage 5 (Rounding) -> Output ---
    wire [31:0] w5_fp_out;

    // =================================================================
    // 2. PIPELINE STAGES
    // =================================================================

    // --- STAGE 1: Compare Exponents ---
    AFP_Compare_Exponents u_stage1 (
        .clk(clk),
        .in1(in1),
        .in2(in2),
        // Outputs
        .shift(w1_shift),
        .compare(w1_compare),
        .exp1(w1_exp1),
        .exp2(w1_exp2),
        .sign1(w1_sign1),
        .sign2(w1_sign2),
        .fra1(w1_fra1),
        .fra2(w1_fra2)
    );

    // --- STAGE 2: Alignment Shift ---
    AFP_Shift u_stage2 (
        .clk(clk),
        // Inputs
        .shift(w1_shift),
        .compare(w1_compare),
        .exp1(w1_exp1),
        .exp2(w1_exp2),
        .sign1(w1_sign1),
        .sign2(w1_sign2),
        .fra1(w1_fra1),
        .fra2(w1_fra2),
        // Outputs
        .exp(w2_exp),
        .fra_out1(w2_fra1),
        .fra_out2(w2_fra2),
        .op(w2_op),
        .sign(w2_sign)
    );

    // --- STAGE 3: Mantissa Add/Sub ---
    AFP_Add u_stage3 (
        .clk(clk),
        // Inputs
        .exp(w2_exp),
        .fra1(w2_fra1),
        .fra2(w2_fra2),
        .op(w2_op),
        .sign(w2_sign),
        // Outputs
        .exp_out(w3_exp),
        .fra(w3_fra),
        .sign_out(w3_sign)
    );

    // --- STAGE 4: Normalize Detection ---
    AFP_Normal u_stage4 (
        .clk(clk),
        // Inputs
        .exp_in(w3_exp),
        .fra_in(w3_fra),
        .sign_in(w3_sign),
        // Outputs
        .shift_left(w4_shift),
        .non_zero(w4_nzero),
        .exp(w4_exp),
        .fra(w4_fra),
        .sign(w4_sign)
    );

    // --- STAGE 5: Rounding & Packing ---
    AFP_Rounding u_stage5 (
        .clk(clk),
        // Inputs
        .shift_left(w4_shift),
        .non_zero(w4_nzero),
        .exp(w4_exp),
        .fra(w4_fra),
        .sign(w4_sign),
        // Output
        .FP_out(w5_fp_out)
    );

    // =================================================================
    // 3. FINAL OUTPUT
    // =================================================================
    assign data_out = w5_fp_out;

endmodule

module add_fp_benchmark_wrapper (
    input wire clk,       // Clock hệ thống (H16)
    // Không cần input từ ngoài vì board không đủ nút gạt cho 64 bit
    output wire led_done  // 1 chân LED duy nhất để báo hiệu (R14)
);

    // --- 1. INPUT GENERATOR (Bộ sinh dữ liệu) ---
    // Dùng thanh ghi để tạo số thay đổi liên tục
    reg [31:0] r_in1;
    reg [31:0] r_in2;

    always @(posedge clk) begin
        // Cộng dồn để tạo giá trị thay đổi ngẫu nhiên giả
        // Ví dụ: r_in1 tăng kiểu float, r_in2 tăng kiểu int
        r_in1 <= r_in1 + 32'h00000011; 
        r_in2 <= r_in2 + 32'h00000005;
        
        // Reset nếu bị tràn hết bit (để tránh trường hợp NaN/Inf kéo dài)
        if (&r_in1) r_in1 <= 32'h3F800000; // 1.0
    end

    // --- 2. DEVICE UNDER TEST (Khối cần test) ---
    wire [31:0] w_result;

    Add_FP dut (
        .clk(clk),
        .in1(r_in1), // Nối vào bộ sinh số
        .in2(r_in2), // Nối vào bộ sinh số
        .data_out(w_result)
    );

    // --- 3. OUTPUT REDUCER (Gom kết quả) ---
    // Dùng thanh ghi chốt đầu ra để Timing Analyzer đo chính xác
    reg [31:0] r_res_latch;
    always @(posedge clk) begin
        r_res_latch <= w_result;
    end

    // XOR tất cả 32 bit lại thành 1 bit để đưa ra LED
    // Việc này bắt buộc Vivado không được xóa bỏ mạch cộng
    assign led_done = ^r_res_latch;

endmodule

module Mul24x4(
input wire [3:0] in1,
input wire [23:0] in2,
output wire [27:0] out
);
wire [23:0] off [0:3];
genvar i;

generate
    for (i = 0; i < 4; i = i+1) begin : gen_pp
        assign off[i] = in1[i]? in2 : 24'b0;
    end 
endgenerate 
assign out = {4'd0, off[0]} + {3'd0, off[1], 1'd0} + {2'd0, off[2], 2'd0} + {1'd0, off[3], 3'd0};
endmodule

module MFP_Mul(
    input  wire        clk,
    input  wire [31:0] FP_in1,
    input  wire [31:0] FP_in2,
    output reg  [47:0] fra,      // Final 48-bit Mantissa Product
    output reg  [8:0]  exp,      // Final Exponent
    output reg         sign,     // Final Sign
    output reg         non_zero  // Zero flag (1 if Result != 0)
);

    // =========================================================
    // 1. SIGNAL & REGISTER DECLARATIONS
    // =========================================================
    
    // --- Control Signal Pipeline Buffers ---
    // Propagate Exp, Sign, and Zero-flag through 5 stages
    reg [8:0] exp_buf      [0:4];
    reg       sign_buf     [0:4];
    reg       non_zero_buf [0:4];

    // --- Partial Product Accumulation Buffers ---
    // buffers grow in size as we shift and add
    reg [27:0] buf_stage1; // Result after Stage 0 (24x4)
    reg [31:0] buf_stage2; // Result after Stage 1
    reg [35:0] buf_stage3; // Result after Stage 2
    reg [39:0] buf_stage4; // Result after Stage 3
    reg [43:0] buf_stage5; // Result after Stage 4
    
    // --- Mantissa Pipeline Registers ---
    // pipe_mant1: Stores Multiplicand (A) - kept constant across stages
    reg [23:0] pipe_mant1 [0:4]; 
    
    // pipe_mant2: Stores Multiplier (B) - shifts out 4 bits per stage
    reg [19:0] pipe_mant2_s1; // Remainder after Stage 0
    reg [15:0] pipe_mant2_s2; // Remainder after Stage 1
    reg [11:0] pipe_mant2_s3; // Remainder after Stage 2
    reg [7:0]  pipe_mant2_s4; // Remainder after Stage 3
    reg [3:0]  pipe_mant2_s5; // Remainder after Stage 4

    // --- Pre-calculation Wires ---
    wire [23:0] mant1_in;   // Mantissa A with hidden bit
    wire [23:0] mant2_in;   // Mantissa B with hidden bit
    wire [8:0]  exp_cal;    // Tentative Exponent
    wire        sign_cal;   // Tentative Sign
    wire        nz_in1, nz_in2; // Input Non-Zero flags

    // --- Sub-module Outputs ---
    wire [27:0] prod [0:5]; // Outputs from 24x4 multipliers

    // =========================================================
    // 2. COMBINATIONAL INPUT LOGIC
    // =========================================================
    
    // Check if inputs are non-zero (checking all exponent bits)
    assign nz_in1 = |FP_in1[30:23]; 
    assign nz_in2 = |FP_in2[30:23];
    
    // Append Hidden Bit '1' to Mantissas
    assign mant1_in = {1'b1, FP_in1[22:0]}; 
    assign mant2_in = {1'b1, FP_in2[22:0]};
    
    // Calculate Exponent: E1 + E2 - Bias(127)
    assign exp_cal  = FP_in1[30:23] + FP_in2[30:23] - 9'd127;
    
    // Calculate Sign: XOR
    assign sign_cal = FP_in1[31] ^ FP_in2[31];

    // =========================================================
    // 3. INSTANTIATE 24x4 LOGIC MULTIPLIERS
    // =========================================================
    
    // Stage 0: Multiply A * B[3:0]
    Mul24x4 u_mul0 (.in1(mant2_in[3:0]), .in2(mant1_in), .out(prod[0]));

    // Stage 1: Multiply A * B[7:4] (using pipeline reg)
    Mul24x4 u_mul1 (.in1(pipe_mant2_s1[3:0]), .in2(pipe_mant1[0]), .out(prod[1]));

    // Stage 2: Multiply A * B[11:8]
    Mul24x4 u_mul2 (.in1(pipe_mant2_s2[3:0]), .in2(pipe_mant1[1]), .out(prod[2]));

    // Stage 3: Multiply A * B[15:12]
    Mul24x4 u_mul3 (.in1(pipe_mant2_s3[3:0]), .in2(pipe_mant1[2]), .out(prod[3]));

    // Stage 4: Multiply A * B[19:16]
    Mul24x4 u_mul4 (.in1(pipe_mant2_s4[3:0]), .in2(pipe_mant1[3]), .out(prod[4]));

    // Stage 5: Multiply A * B[23:20]
    Mul24x4 u_mul5 (.in1(pipe_mant2_s5[3:0]), .in2(pipe_mant1[4]), .out(prod[5]));

    // =========================================================
    // 4. SEQUENTIAL PIPELINE LOGIC (Accumulate & Shift)
    // =========================================================
    always @(posedge clk) begin
    
        // --- STAGE 0: Initialization ---
        // Multiplication result is non-zero ONLY if BOTH inputs are non-zero
        non_zero_buf[0] <= nz_in1 & nz_in2; 
        exp_buf[0]      <= exp_cal;
        sign_buf[0]     <= sign_cal;
        
        // Direct assignment for the first partial product
        buf_stage1      <= prod[0]; 

        // Store Mantissa A and remaining Mantissa B
        pipe_mant1[0]   <= mant1_in;
        pipe_mant2_s1   <= mant2_in[23:4]; // Shift out used 4 bits

        // --- STAGE 1: Accumulate B[7:4] ---
        non_zero_buf[1] <= non_zero_buf[0];
        exp_buf[1]      <= exp_buf[0];
        sign_buf[1]     <= sign_buf[0];

        // Algorithm: Current_Sum = (New_Product << 4) + Previous_Sum
        // {prod[1], 4'd0} acts as a 4-bit left shift
        buf_stage2      <= {prod[1] + buf_stage1[27:4], buf_stage1[3:0]};

        pipe_mant1[1]   <= pipe_mant1[0];
        pipe_mant2_s2   <= pipe_mant2_s1[19:4];

        // --- STAGE 2: Accumulate B[11:8] ---
        non_zero_buf[2] <= non_zero_buf[1];
        exp_buf[2]      <= exp_buf[1];
        sign_buf[2]     <= sign_buf[1];

        // Shift 8 bits (implicitly handled by adding to previous buffer)
        buf_stage3      <= {prod[2] + buf_stage2[31:8], buf_stage2[7:0]};

        pipe_mant1[2]   <= pipe_mant1[1];
        pipe_mant2_s3   <= pipe_mant2_s2[15:4];

        // --- STAGE 3: Accumulate B[15:12] ---
        non_zero_buf[3] <= non_zero_buf[2];
        exp_buf[3]      <= exp_buf[2];
        sign_buf[3]     <= sign_buf[2];

        buf_stage4      <= {prod[3] + buf_stage3[35:12], buf_stage3[11:0]};

        pipe_mant1[3]   <= pipe_mant1[2];
        pipe_mant2_s4   <= pipe_mant2_s3[11:4];

        // --- STAGE 4: Accumulate B[19:16] ---
        non_zero_buf[4] <= non_zero_buf[3];
        exp_buf[4]      <= exp_buf[3];
        sign_buf[4]     <= sign_buf[3];

        buf_stage5      <= {prod[4] + buf_stage4[39:16], buf_stage4[15:0]};

        pipe_mant1[4]   <= pipe_mant1[3];
        pipe_mant2_s5   <= pipe_mant2_s4[7:4]; // Only 4 bits left

        // --- STAGE 5: Final Accumulation B[23:20] ---
        non_zero        <= non_zero_buf[4];
        exp             <= exp_buf[4];
        sign            <= sign_buf[4];

        // Final addition: (Prod5 << 20) + Previous_Sum
        fra             <= {prod[5] + buf_stage5[43:20], buf_stage5[19:0]};
    end

endmodule


module MFP_Norm_Rounding(
input               clk,
input wire [47:0]   fra,
input wire [8:0]    exp,
input wire          non_zero,
input wire          sign,
output reg [31:0]   FP_out
);
wire [23:0] w1;
wire [8:0] w2;
wire [7:0] w3;
assign w1 = fra[47] ? fra[46:23] : fra[45:22];
assign w2 = exp + fra[47];
assign w3 = (!non_zero | w2[8])? 8'b0 : w2[7:0];
always @(posedge clk) begin
    FP_out[22:0] <= (w3 == 0)? 23'd0 : w1[23:1] + w1[0];
    FP_out[31] <= sign;
    FP_out[30:23] <= w3;
end
endmodule

module Mul_FP(
    input  wire        clk,
    input  wire [31:0] FP_in1,  // Input Float A
    input  wire [31:0] FP_in2,  // Input Float B
    output wire [31:0] FP_out   // Output Float Result
);

    // =========================================================
    // 1. INTERCONNECT WIRES
    // =========================================================
    // Signals to connect the Multiplier Core to the Normalizer
    
    wire [47:0] w_fra_raw;   // 48-bit Raw Product
    wire [8:0]  w_exp_raw;   // Raw Exponent
    wire        w_sign_raw;  // Sign bit
    wire        w_non_zero;  // Zero flag

    // =========================================================
    // 2. MODULE INSTANTIATIONS
    // =========================================================

    // --- Instance 1: Mantissa Multiplier Core (6-Stage Pipeline) ---
    // Calculates the 48-bit product and tentative exponent
    MFP_Mul u_core_mul (
        .clk      (clk),
        .FP_in1   (FP_in1),
        .FP_in2   (FP_in2),
        // Outputs mapped to wires
        .fra      (w_fra_raw),
        .exp      (w_exp_raw),
        .sign     (w_sign_raw),
        .non_zero (w_non_zero)
    );

    // --- Instance 2: Normalization & Rounding Unit (1 Stage) ---
    // Standardizes the result to IEEE 754 format
    MFP_Norm_Rounding u_core_norm (
        .clk      (clk),
        // Inputs from Multiplier Core
        .fra   (w_fra_raw),
        .exp   (w_exp_raw),
        .sign  (w_sign_raw),
        .non_zero (w_non_zero),
        // Final Output
        .FP_out   (FP_out)
    );

endmodule

//module Mul_FP(
//input [31:0] data_in1,
//input [31:0] data_in2,
//output [31:0] data_out
//);
//wire [47:0] result;
//wire [8:0] w1;
//wire w2, w3;
//assign w2 = |data_in1[30:23];
//assign w3 = |data_in2[30:23];
//assign data_out[31] = data_in1[31]^data_in2[31];
//assign w1 = data_in1[30:23] + data_in2[30:23] - 9'd127 + result[47];
//assign data_out[30:23] = (w1[8] | !w2 | !w3 )? 8'b0 : w1[7:0];
//assign result = { w2, data_in1[22:0] } * { w3, data_in2[22:0] };
//assign data_out[22:0] = result[47]? result[46:24] : result[45:23];
//endmodule


module mul_fp_benchmark_wrapper (
    input wire clk,       // Clock hệ thống (Ví dụ: 125MHz từ board)
    // Không dùng input switch để tránh delay I/O và hạn chế số lượng chân
    output wire led_done  // 1 chân LED báo hiệu (Để Vivado không xóa logic)
);

    // =========================================================
    // 1. INPUT GENERATOR (Bộ sinh dữ liệu giả lập)
    // =========================================================
    // Dùng thanh ghi để tạo số thay đổi liên tục mỗi chu kỳ clock
    // Khởi tạo giá trị ban đầu (Initial value) để tránh X trong mô phỏng (nếu có)
    reg [31:0] r_in1 = 32'h3F800000; // 1.0
    reg [31:0] r_in2 = 32'h40000000; // 2.0

    always @(posedge clk) begin
        // Cộng dồn các số nguyên tố nhỏ để tạo mẫu bit thay đổi hỗn loạn
        // Giúp kiểm tra timing qua nhiều trường hợp bit 0/1 khác nhau
        r_in1 <= r_in1 + 32'h00000013; 
        r_in2 <= r_in2 + 32'h00000007;
        
        // Reset mềm nếu giá trị bị NaN hoặc Inf để mạch chạy ổn định
        if (&r_in1[30:23]) begin 
            r_in1 <= 32'h3F800000; // Reset về 1.0
        end
    end

    // =========================================================
    // 2. DEVICE UNDER TEST (DUT - Khối nhân cần test)
    // =========================================================
    wire [31:0] w_result;

    Mul_FP dut (
        .clk    (clk),
        .FP_in1 (r_in1),    // Nối vào bộ sinh số nội bộ
        .FP_in2 (r_in2),    // Nối vào bộ sinh số nội bộ
        .FP_out (w_result)  // Kết quả ra
    );

    // =========================================================
    // 3. OUTPUT REDUCER (Gom kết quả & Chốt chặn)
    // =========================================================
    // Dùng thanh ghi chốt đầu ra để Timing Analyzer đo chính xác đường đi
    // từ Flip-Flop đầu vào đến Flip-Flop đầu ra (Reg-to-Reg Path)
    reg [31:0] r_res_latch;
    
    always @(posedge clk) begin
        r_res_latch <= w_result;
    end

    // XOR tất cả 32 bit lại thành 1 bit để đưa ra LED
    // Logic này bắt buộc Vivado phải giữ lại toàn bộ mạch nhân phía trước
    // vì bit LED này phụ thuộc vào từng bit của kết quả nhân.
    assign led_done = ^r_res_latch;

endmodule