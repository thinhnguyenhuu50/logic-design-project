//module Complex_Add(
//input [63:0] data_in1,
//input [63:0] data_in2,
//output [63:0] data_out
//);
//Add_FP A0(.in1(data_in1[63:32]), .in2(data_in2[63:32]), .data_out(data_out[63:32]));
//Add_FP A1(.in1(data_in1[31:0]), .in2(data_in2[31:0]), .data_out(data_out[31:0]));
//endmodule

module Complex_Add(
input                   clk,
input wire [63:0]       data_in1,
input wire [63:0]       data_in2,
output wire [63:0]      data_out
);
Add_FP A0(.clk(clk), .in1(data_in1[63:32]), .in2(data_in2[63:32]), .data_out(data_out[63:32]));
Add_FP A1(.clk(clk), .in1(data_in1[31:0]), .in2(data_in2[31:0]), .data_out(data_out[31:0]));
endmodule

module Complex_Sub(
input                   clk,
input wire [63:0]       data_in1,
input wire [63:0]       data_in2,
output wire [63:0]      data_out
);
wire w1, w2;
assign w1 = ~data_in2[63];
assign w2 = ~data_in2[31];
Add_FP A0(.clk(clk), .in1(data_in1[63:32]), .in2({w1, data_in2[62:32]}), .data_out(data_out[63:32]));
Add_FP A1(.clk(clk), .in1(data_in1[31:0]), .in2({w2, data_in2[30:0]}), .data_out(data_out[31:0]));
endmodule

//module Complex_Mul(
//input [63:0] data_in1,
//input [63:0] data_in2,
//output [63:0] data_out
//);
//wire [31:0] k1;
//wire [31:0] k2;
//wire [31:0] k3;
//wire [31:0] n_k1;
//wire [31:0] n_k2;
//wire [31:0] t1;
//wire [31:0] t2;
//wire [31:0] t3;
//assign n_k1 = { ~k1[31], k1[30:0]};
//assign n_k2 = { ~k2[31], k2[30:0]};
//Add_FP A0(.in1(data_in1[63:32]), .in2(data_in1[31:0]), .data_out(t1));
//Add_FP A1(.in1(data_in2[63:32]), .in2(data_in2[31:0]), .data_out(t2));
//Add_FP A2(.in1(k1), .in2(n_k2), .data_out(data_out[31:0]));
//Add_FP A3(.in1(k3), .in2(n_k1), .data_out(t3));
//Add_FP A4(.in1(t3), .in2(n_k2), .data_out(data_out[63:32]));
//Mul_FP M0(.data_in1(data_in1[31:0]), .data_in2(data_in2[31:0]), .data_out(k1));
//Mul_FP M1(.data_in1(data_in1[63:32]), .data_in2(data_in2[63:32]), .data_out(k2));
//Mul_FP M2(.data_in1(t1), .data_in2(t2), .data_out(k3));
//endmodule

module Complex_Mul(
    input  wire        clk,
    input  wire [63:0] data_in1,
    input  wire [63:0] data_in2,
    output wire [63:0] data_out
);
    wire [31:0] b = data_in1[63:32];
    wire [31:0] a = data_in1[31:0];
    wire [31:0] d = data_in2[63:32];
    wire [31:0] c = data_in2[31:0];

    wire [31:0] p_ac; // a * c
    wire [31:0] p_bd; // b * d
    wire [31:0] p_ad; // a * d
    wire [31:0] p_bc; // b * c
    wire [31:0] p_bd_neg;
    wire [31:0] res_real;
    wire [31:0] res_imag;
    Mul_FP u_mul_ac (.clk(clk), .FP_in1(a), .FP_in2(c), .FP_out(p_ac));
    Mul_FP u_mul_bd (.clk(clk), .FP_in1(b), .FP_in2(d), .FP_out(p_bd));
    Mul_FP u_mul_ad (.clk(clk), .FP_in1(a), .FP_in2(d), .FP_out(p_ad));
    Mul_FP u_mul_bc (.clk(clk), .FP_in1(b), .FP_in2(c), .FP_out(p_bc));
    Add_FP u_sub_real (.clk(clk), .in1(p_ac), .in2(p_bd_neg), .data_out(res_real));
    Add_FP u_add_imag (.clk(clk), .in1(p_ad), .in2(p_bc), .data_out(res_imag));
    
    assign p_bd_neg = {~p_bd[31], p_bd[30:0]};
    assign data_out = {res_imag, res_real};
endmodule


module FP_Complex_Divide_N #(
    parameter integer N = 32
) (
input                   clk,
input wire [63:0]       data_in,
output reg [63:0]       data_out
);
localparam div = $clog2(N);
wire [8:0] w1;
wire [8:0] w2;
assign w1 = {1'b0, data_in[62:55]} - div;
assign w2 = {1'b0, data_in[30:23]} - div;

always @(posedge clk) begin
    data_out[62:32] <= w1[8]? 31'b0 : {w1[7:0], data_in[54:32]};
    data_out[30:0] <= w2[8]? 31'b0 : {w2[7:0], data_in[22:0]};
    data_out[63] <= data_in[63];
    data_out[31] <= data_in[31];
end
endmodule

//module Complex_Sub(
//input [63:0] data_in1,
//input [63:0] data_in2,
//output [63:0] data_out
//);
//wire w1, w2;
//assign w1 = ~data_in2[63];
//assign w2 = ~data_in2[31];
//Add_FP A0(.in1(data_in1[63:32]), .in2({w1, data_in2[62:32]}), .data_out(data_out[63:32]));
//Add_FP A1(.in1(data_in1[31:0]), .in2({w2, data_in2[30:0]}), .data_out(data_out[31:0]));
//endmodule



module Complex_Mul_Timing_Wrapper (
    input wire clk,       // Clock hệ thống (Ví dụ: 100MHz/125MHz)
    output wire led_done  // Chân LED để chống Vivado xóa mạch
);

    // =========================================================
    // 1. CHAOS INPUT GENERATOR (Bộ sinh dữ liệu hỗn loạn)
    // =========================================================
    // Sử dụng thanh ghi 64-bit.
    // Khởi tạo giá trị khác 0 (Seed) để LFSR hoạt động.
    reg [63:0] r_in1 = 64'hA5A5A5A5_12345678; 
    reg [63:0] r_in2 = 64'h5A5A5A5A_87654321; 

    always @(posedge clk) begin
        // --- Input 1: LFSR (Linear Feedback Shift Register) ---
        // Kỹ thuật này tạo ra chuỗi bit giả ngẫu nhiên cực mạnh.
        // Phép XOR các bit ở vị trí xa nhau giúp bit thay đổi toàn bộ thanh ghi.
        r_in1 <= {r_in1[62:0], r_in1[63] ^ r_in1[21] ^ r_in1[2]};

        // --- Input 2: Arithmetic Chaos ---
        // Cộng một số nguyên tố cực lớn và lẻ.
        // Việc này đảm bảo không bao giờ lặp lại giá trị trong thời gian ngắn
        // và gây tràn số (Overflow) liên tục ở mọi vị trí bit.
        r_in2 <= r_in2 + 64'hDEAD_BEEF_CAFE_BABE;
    end

    // =========================================================
    // 2. DUT (Device Under Test)
    // =========================================================
    wire [63:0] w_data_out;

    Complex_Mul u_dut (
        .clk      (clk),
        .data_in1 (r_in1),      // Input ngẫu nhiên
        .data_in2 (r_in2),      // Input ngẫu nhiên
        .data_out (w_data_out)  // Kết quả
    );

    // =========================================================
    // 3. OUTPUT LATCH (Chốt chặn tối ưu hóa)
    // =========================================================
    reg [63:0] r_res_latch;
    
    always @(posedge clk) begin
        r_res_latch <= w_data_out;
    end

    // XOR tất cả 64 bit lại. 
    // Nếu Vivado xóa bất kỳ phần nào của bộ nhân, bit này sẽ sai -> Vivado buộc phải giữ lại hết.
    assign led_done = ^r_res_latch;

endmodule
