module Inv_FP#(
    parameter integer TW_W = 32
)(
    input  wire signed [TW_W-1:0] in_val,
    output wire signed [TW_W-1:0] out_val
);
    assign out_val = {~in_val[TW_W-1], in_val[TW_W-2:0]};
endmodule

module RTL_ALU_Add(
input sign1,
input [23:0] in1,
input sign2,
input [23:0] in2,
output [25:0] out
);
wire [25:0] w1;
wire [25:0] w2;
wire [25:0] data1;
wire [25:0] data2;
assign w1 = {2'b00, in1};
assign w2 = {2'b00, in2};
assign data1 = sign1? -w1 : w1;
assign data2 = sign2? -w2 : w2; 
assign out = data1 + data2;
endmodule

module Shift_Right(
input [22:0] in1,
input [22:0] in2,
input compare,
input [4:0] shift,
output [23:0] out1,
output [23:0] out2
);
wire [23:0] data1;
wire [23:0] data2;
wire [23:0] w1;
assign data1 = {1'b1, in1};
assign data2 = {1'b1, in2};
assign w1 = compare? data2 : data1;
assign out2 = compare? data1 : data2;
assign out1 = w1 >> shift;
endmodule 

module Exponent_Difference(
input [7:0] in1,
input [7:0] in2,
output [4:0] shift,
output compare
);
wire [8:0] w1;
wire [8:0] w2;
assign w1 = {1'b0, in2} - {1'b0, in1};
assign compare = w1[8];
assign w2 = w1[8]? -w1 : w1;
assign shift = (w2 > 9'd24)? 5'd24 : w2[4:0];
endmodule

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

module Rounding_Normalize(
input [25:0] data_in,
input [7:0] great_exponent,
output [31:0] data_out
);
wire [24:0] w1;
wire [7:0] w2;
wire [4:0] shift_left;
wire non_zero;
assign w1 = data_in[25]? -data_in : data_in;
priority_encoder #(.WIDTH(24)) H1 (.in(w1[23:0]), .out(shift_left), .valid(non_zero));
assign data_out[31] = data_in[25];
assign w2 = w1[24]? great_exponent + 1'b1 : great_exponent - shift_left;
assign data_out[30:23] = (non_zero | w1[24])? w2 : 8'd0;
assign data_out[22:0] = w1[24]? w1[23:1] : w1[22:0] << shift_left;
endmodule

module Add_FP(
input [31:0] in1,
input [31:0] in2,
output [31:0] data_out
);
wire [4:0] shift_right;
wire [23:0] w1;
wire [23:0] w2;
wire [25:0] w3;
wire compare;
wire sign1;
wire sign2;
wire [7:0] great_exponent;
assign great_exponent = compare? in1[30:23] : in2[30:23];
assign sign1 = compare? in2[31] : in1[31];
assign sign2 = compare? in1[31] : in2[31];
Exponent_Difference A0(.in1(in1[30:23]), .in2(in2[30:23]), .shift(shift_right), .compare(compare));
Shift_Right A1(.in1(in1[22:0]), .in2(in2[22:0]), .compare(compare), .shift(shift_right), .out1(w1), .out2(w2));
RTL_ALU_Add A2(.sign1(sign1), .in1(w1), .sign2(sign2), .in2(w2), .out(w3));
Rounding_Normalize A3(.data_in(w3), .great_exponent(great_exponent), .data_out(data_out));
endmodule

module Mul_FP(
input [31:0] data_in1,
input [31:0] data_in2,
output [31:0] data_out
);
wire [47:0] result;
wire [8:0] w1;
wire w2, w3;
assign w2 = |data_in1[30:23];
assign w3 = |data_in2[30:23];
assign data_out[31] = data_in1[31]^data_in2[31];
assign w1 = data_in1[30:23] + data_in2[30:23] - 9'd127 + result[47];
assign data_out[30:23] = (w1[8] | !w2 | !w3 )? 8'b0 : w1[7:0];
assign result = { w2, data_in1[22:0] } * { w3, data_in2[22:0] };
assign data_out[22:0] = result[47]? result[46:24] : result[45:23];
endmodule