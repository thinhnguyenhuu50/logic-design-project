module Butterfly_Multiplication_Unit(
input [63:0] data_in1,
input [63:0] data_in2,
input [63:0] factor,
input control,

output [63:0] data_out1,
output [63:0] data_out2
);
wire [63:0] w1;
wire [63:0] w2;
wire [63:0] w3;
wire [63:0] w4;
wire [63:0] w5;

Complex_Sub S0 (.data_in1(data_in1), .data_in2(data_in2), .data_out(w1));
Complex_Sub S1 (.data_in1(data_in1), .data_in2(w3), .data_out(w5));
Complex_Add A0 (.data_in1(data_in1), .data_in2(w4), .data_out(data_out1));
Complex_Mul M0 (.data_in1(w2), .data_in2(factor), .data_out(w3));

assign w2 = control? data_in2 : w1;
assign w4 = control? w3 : data_in2;
assign data_out2 = control? w5 : w3;
endmodule

module Mul_PointWise(
input [63:0] data_in1,
input [63:0] data_in2,
output [63:0] data_out
);
wire [63:0] w1;
Complex_Mul M0(.data_in1(data_in1), .data_in2(data_in2), .data_out(w1));
FP_Complex_Divide_N M1(.data_in(w1), .data_out(data_out));
endmodule

module Temp_Conv_FFT #(
    parameter integer N = 32,
    parameter integer M = 2,
    localparam integer ADDR_WIDTH_RAM = $clog2(2*N),
    localparam integer ADDR_WIDTH_ROM = $clog2(N)
) (
input [31:0] data_in,
input clk,
//Control Unit
input [ADDR_WIDTH_RAM-1:0] addr_RAM1,
input [ADDR_WIDTH_RAM-1:0] addr_RAM2,
input [ADDR_WIDTH_ROM-1:0] addr_ROM,
input enRAM1,
input enRAM2,
input enROM,
input MUX_BMU,
input MUX_in,
input MUX_out,
input MUX_MPW,
input enBuffer_RAM,
input enBuffer_ROM,
input enBuffer_BMU,
input loadBuffer_BMU,
//OUTPUT
output [31:0] data_out
);
//RAM
wire [63:0] WRAM1;
wire [63:0] WRAM2;
wire [63:0] RRAM1;
wire [63:0] RRAM2;
wire [63:0] tempWRAM;
assign tempWRAM = MUX_MPW? OutMPW : BufferBMU_out1;
assign WRAM1 = MUX_in ? {32'b0, data_in} : tempWRAM;
assign WRAM2 = BufferBMU_out2;
RAM #(.DATA_WIDTH(64), .MEM_DEPTH(2*N)) RAM_Dual_Port (.data_a(WRAM1), .addr_a(addr_RAM1), .we_a(enRAM1), .q_a(RRAM1), .data_b(WRAM2), .addr_b(addr_RAM2), .we_b(enRAM2), .q_b(RRAM2), .clk(clk));
//ROM
localparam integer IgnorROM = 8 - ADDR_WIDTH_ROM;
wire [IgnorROM-1:0] zero_addr_ROM;
assign zero_addr_ROM = 0;
wire [63:0] RROM;
rom_twiddle_top ROM (.en(enROM), .tw_idx({addr_ROM, zero_addr_ROM}), .tw_factor(RROM));
//MPW
wire [63:0] OutMPW;
Mul_PointWise BMP(.data_in1(RRAM1), .data_in2(RRAM2), .data_out(OutMPW));
//Output
assign data_out = MUX_out? RRAM1[31:0] : 32'b0;
//BufferRAM
wire [63:0] BufferRAM_out1 [0:M-1];
wire [63:0] BufferRAM_out2 [0:M-1];
wire [M-1:0] tempBufferRAM1 [0:63];
wire [M-1:0] tempBufferRAM2 [0:63];
//BufferROM
wire [63:0] BufferROM_out [0:M-1];
wire [M-1:0] tempBufferROM [0:63];
//BufferBMU
wire [63:0] BufferBMU_out1;
wire [63:0] BufferBMU_out2;
wire [M-1:0] tempBufferBMU1 [0:63];
wire [M-1:0] tempBufferBMU2[0:63];
//BMU
wire [63:0] BMU_out1 [0:M-1];
wire [63:0] BMU_out2 [0:M-1];
genvar i, j;

generate
for(j=0; j < 64; j=j+1) begin
    //BufferRAM
    SIPO #(M) BufferRAM1 (.clk(clk), .enable(enRAM1), .serial_in(RRAM1[j]), .parallel_out(tempBufferRAM1[j]));
    SIPO #(M) BufferRAM2 (.clk(clk), .enable(enRAM2), .serial_in(RRAM2[j]), .parallel_out(tempBufferRAM2[j]));
    //BufferROM
    SIPO #(M) BufferROM (.clk(clk), .enable(enROM), .serial_in(RROM[j]), .parallel_out(tempBufferROM[j]));
    //bufferBMU
    PISO #(M) BufferBMU1 (.clk(clk), .load_en(loadBuffer_BMU), .shift_en(enBuffer_BMU), .data_in(tempBufferBMU1[j]), .serial_out(BufferBMU_out1[j]));
    PISO #(M) BufferBMU2 (.clk(clk), .load_en(loadBuffer_BMU), .shift_en(enBuffer_BMU), .data_in(tempBufferBMU2[j]), .serial_out(BufferBMU_out2[j]));
    for (i = 0; i < M; i = i + 1) begin
        //BufferRAM
        assign BufferRAM_out1[i][j] = tempBufferRAM1[j][i];
        assign BufferRAM_out2[i][j] = tempBufferRAM2[j][i];
        //BufferROM
        assign BufferROM_out[i][j] = tempBufferROM[j][i];
        //BufferBMU
        assign tempBufferBMU1[j][i] = BMU_out1[i][j];
        assign tempBufferBMU2[j][i] = BMU_out2[i][j];
    end
end
endgenerate

generate
    for (i = 0; i < M; i = i + 1) begin
        //BMU
        Butterfly_Multiplication_Unit BMU (.data_in1(BufferRAM_out1[i]), .data_in2(BufferRAM_out2[i]), .factor(BufferROM_out[i]), .control(MUX_BMU), .data_out1(BMU_out1[i]), .data_out2(BMU_out2[i]));
    end
endgenerate

endmodule

module Syn_Temp_Conv_FFT(
input [31:0] data_in,
input clk,
output [31:0] data_out
);
Temp_Conv_FFT A0 (data_in, clk, 'b0, 'b0, 'b0, 'b0, 'b0, 'b0, 'b0, 'b0, 'b0, 'b0, 'b0, 'b0,'b0, 'b0, data_out);
endmodule