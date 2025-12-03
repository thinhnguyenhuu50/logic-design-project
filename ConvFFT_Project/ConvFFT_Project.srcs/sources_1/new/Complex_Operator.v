module Complex_Add(
input [63:0] data_in1,
input [63:0] data_in2,
output [63:0] data_out
);
Add_FP A0(.in1(data_in1[63:32]), .in2(data_in2[63:32]), .data_out(data_out[63:32]));
Add_FP A1(.in1(data_in1[31:0]), .in2(data_in2[31:0]), .data_out(data_out[31:0]));
endmodule

module Complex_Mul(
input [63:0] data_in1,
input [63:0] data_in2,
output [63:0] data_out
);
wire [31:0] k1;
wire [31:0] k2;
wire [31:0] k3;
wire [31:0] n_k1;
wire [31:0] n_k2;
wire [31:0] t1;
wire [31:0] t2;
wire [31:0] t3;
assign n_k1 = { ~k1[31], k1[30:0]};
assign n_k2 = { ~k2[31], k2[30:0]};
Add_FP A0(.in1(data_in1[63:32]), .in2(data_in1[31:0]), .data_out(t1));
Add_FP A1(.in1(data_in2[63:32]), .in2(data_in2[31:0]), .data_out(t2));
Add_FP A2(.in1(k1), .in2(n_k2), .data_out(data_out[31:0]));
Add_FP A3(.in1(k3), .in2(n_k1), .data_out(t3));
Add_FP A4(.in1(t3), .in2(n_k2), .data_out(data_out[63:32]));
Mul_FP M0(.data_in1(data_in1[31:0]), .data_in2(data_in2[31:0]), .data_out(k1));
Mul_FP M1(.data_in1(data_in1[63:32]), .data_in2(data_in2[63:32]), .data_out(k2));
Mul_FP M2(.data_in1(t1), .data_in2(t2), .data_out(k3));
endmodule

module FP_Complex_Divide_N #(
    parameter integer N = 32
) (
input [63:0]data_in,
output [63:0]data_out
);
localparam div = $clog2(N);
assign data_out[62:55] = {1'b0, data_in[62:55]} - div;
assign data_out[30:23] = {1'b0, data_in[30:23]} - div;
assign {data_out[63], data_out[54:31], data_out[22:0]} = {data_in[63], data_in[54:31], data_in[22:0]};
endmodule

module Complex_Sub(
input [63:0] data_in1,
input [63:0] data_in2,
output [63:0] data_out
);
wire w1, w2;
assign w1 = ~data_in2[63];
assign w2 = ~data_in2[31];
Add_FP A0(.in1(data_in1[63:32]), .in2({w1, data_in2[62:32]}), .data_out(data_out[63:32]));
Add_FP A1(.in1(data_in1[31:0]), .in2({w2, data_in2[30:0]}), .data_out(data_out[31:0]));
endmodule