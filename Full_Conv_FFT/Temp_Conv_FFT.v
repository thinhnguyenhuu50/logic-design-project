module Butterfly_Multiplication_Unit(
input [63:0] data_in1,
input [63:0] data_in2,
input [63:0] factor,
input control, //0: DIF, 1: DIT

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
input MUX_BMU,  //0: DIF, 1: DIT
input MUX_in,   //0: Not Write Input into RAM, 1: Have
input MUX_out,  //0: Ouput = 0, 1: Output = Result
input MUX_MPW,  //0: Write Result FFT int RAM, 1: of Multiplication PointWise
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
localparam integer IgnorROM = 8 - ADDR_WIDTH_ROM;
wire [IgnorROM-1:0] zero_addr_ROM;
assign zero_addr_ROM = 0;
wire [63:0] RROM;
wire [63:0] OutMPW;
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

assign tempWRAM = MUX_MPW? OutMPW : BufferBMU_out1;
assign WRAM1 = MUX_in ? {32'b0, data_in} : tempWRAM;
assign WRAM2 = BufferBMU_out2;
RAM #(.DATA_WIDTH(64), .MEM_DEPTH(2*N)) RAM_Dual_Port (.data_a(WRAM1), .addr_a(addr_RAM1), .we_a(enRAM1), .q_a(RRAM1), .data_b(WRAM2), .addr_b(addr_RAM2), .we_b(enRAM2), .q_b(RRAM2), .clk(clk));
//ROM

rom_twiddle_top ROM (.en(enROM), .tw_idx({addr_ROM, zero_addr_ROM}), .tw_factor(RROM));
//MPW

Mul_PointWise MPW(.data_in1(RRAM1), .data_in2(RRAM2), .data_out(OutMPW));
//Output
assign data_out = MUX_out? RRAM1[31:0] : 32'b0;

genvar i, j;

generate
for(j=0; j < 64; j=j+1) begin
    //BufferRAM
    SIPO #(M) BufferRAM1 (.clk(clk), .enable(enBuffer_RAM), .serial_in(RRAM1[j]), .parallel_out(tempBufferRAM1[j]));
    SIPO #(M) BufferRAM2 (.clk(clk), .enable(enBuffer_RAM), .serial_in(RRAM2[j]), .parallel_out(tempBufferRAM2[j]));
    //BufferROM
    SIPO #(M) BufferROM (.clk(clk), .enable(enBuffer_ROM), .serial_in(RROM[j]), .parallel_out(tempBufferROM[j]));
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

module AddressFFT #(
parameter integer N = 32,
localparam integer L = $clog2(N),
localparam integer LL = $clog2(L)
)(
input [L-2:0] step,
input [LL-1:0] state,
input Mux1, //0: DIF, 1: DIT
input Mux2, //0: RAM[N-1:0], 1: RAM[2N-1:N]
output [L:0] addr_RAM1,
output [L:0] addr_RAM2,
output [L-1:0] addr_ROM
);
wire [LL-1:0] m1;
wire [L-2:0] F;
wire [L-2:0] w1;
wire [L-2:0] w2;
wire [L-1:0] w3;
wire [L-1:0] wA;
wire [L-1:0] wB;
assign F = {L-1 {1'b1}};
assign m1 = Mux1? L - 1 - state : state; 
assign w1 = F >> m1;
assign w2 = ~w1;
assign w3 = ~(w1 | ({1'b0, w2}<<1));
assign wA = {1'b0, step} & w1;
assign wB = ({1'b0, step} & w2) << 1;
assign addr_RAM1 = {Mux2, wA | wB};
assign addr_RAM2 = {Mux2, wA | wB | w3};
assign addr_ROM = (w1 & step) << state;

endmodule

module ConvFTT #(
parameter integer N = 32
)(
input  wire                 clk,
input  wire                 rst_n,
input  wire                 start,
input  wire [31:0]          data_in,
output wire [31:0]          data_out,               
output                      done
);
wire [$clog2(2*N)-1:0]      addr_RAM1;
wire [$clog2(2*N)-1:0]      addr_RAM2;
wire [$clog2(N)-1:0]        addr_ROM;
wire                        enRAM1;
wire                        enRAM2;
wire                        enROM;
wire                        MUX_BMU;// 0: DIF, 1: DIT
wire                        MUX_in; // 0: Not Write Input into RAM, 1: Have
wire                        MUX_out;// 0: Ouput = 0, 1: Output = Result
wire                        MUX_MPW;//0: Write Result FFT int RAM, 1: of Multiplication PointWise
//RAM
wire [63:0]                 WRAM1;
wire [63:0]                 WRAM2;
wire [63:0]                 RRAM1;
wire [63:0]                 RRAM2;
wire [63:0]                 tempWRAM;
//ROM
localparam integer IgnorROM = 8 - $clog2(N);
wire [IgnorROM-1:0] zero_addr_ROM;
assign zero_addr_ROM = 0;
wire [63:0] RROM;
//MPW
wire [63:0] OutMPW;
//BMU
wire [63:0] BMU_out1;
wire [63:0] BMU_out2;
//---------------------------------------------------------------------------//

//RAM
assign tempWRAM = MUX_MPW? OutMPW : BMU_out1;
assign WRAM1 = MUX_in ? {32'b0, data_in} : tempWRAM;
assign WRAM2 = BMU_out2;
RAM #(.DATA_WIDTH(64), .MEM_DEPTH(2*N)) RAM_Dual_Port (.data_a(WRAM1), .addr_a(addr_RAM1), .we_a(enRAM1), .q_a(RRAM1), .data_b(WRAM2), .addr_b(addr_RAM2), .we_b(enRAM2), .q_b(RRAM2), .clk(clk));
//ROM
rom_twiddle_top ROM (.en(enROM), .tw_idx({addr_ROM, zero_addr_ROM}), .tw_factor(RROM));
//BMU
Butterfly_Multiplication_Unit BMU (.data_in1(RRAM1), .data_in2(RRAM2), .factor(RROM), .control(MUX_BMU), .data_out1(BMU_out1), .data_out2(BMU_out2));
//MPW
Mul_PointWise MPW(.data_in1(RRAM1), .data_in2(RRAM2), .data_out(OutMPW));
//Control Unit
Control_FFTConv #(.N(N), .M(1)) Control_Unit(
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    // Điều khiển Temp_Conv_FFT
    .addr_RAM1(addr_RAM1),
    .addr_RAM2(addr_RAM2),
    .addr_ROM(addr_ROM),
    .enRAM1(enRAM1),
    .enRAM2(enRAM2),
    .enROM(enROM),
    .MUX_BMU(MUX_BMU),       // 0: DIF, 1: DIT
    .MUX_in(MUX_in),
    .MUX_out(MUX_out),
    .MUX_MPW(MUX_MPW),
    .done(done)
);
//Output
assign data_out = MUX_out? RRAM1[31:0] : 32'b0;
endmodule 


