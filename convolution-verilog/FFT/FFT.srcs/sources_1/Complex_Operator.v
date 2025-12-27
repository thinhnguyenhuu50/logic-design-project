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