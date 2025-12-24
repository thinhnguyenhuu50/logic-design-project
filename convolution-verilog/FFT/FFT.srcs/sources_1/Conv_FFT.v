module Buffer #(
    parameter WIDTH  = 32,
    parameter CYCLES = 4
)(
    input  wire             clk,
    input  wire [WIDTH-1:0] in_data,
    output wire [WIDTH-1:0] out_data
);
    generate
        if (CYCLES == 0) begin : gen_bypass
            assign out_data = in_data;
        end
        else begin : gen_delay
            reg [WIDTH-1:0] shift_reg [0:CYCLES-1];
            integer i;

            always @(posedge clk) begin
                shift_reg[0] <= in_data;
                for (i = 1; i < CYCLES; i = i + 1) begin
                    shift_reg[i] <= shift_reg[i-1];
                end
            end
            assign out_data = shift_reg[CYCLES-1];
        end
    endgenerate
endmodule

module Butterfly_Multiplication_Unit(
input                       clk,
input wire [63:0]           data_in1,
input wire [63:0]           data_in2,
input wire [63:0]           factor,
input wire                  control, //0: DIF, 1: DIT
output wire [63:0]          data_out1,
output wire [63:0]          data_out2
);
wire [63:0] w1;
wire [63:0] w2;
wire [63:0] w3;
wire [63:0] w4;
wire [63:0] w5;
wire [63:0] w6;
wire [63:0] w7;
wire [63:0] w8;
wire [63:0] w9;

Buffer #(.WIDTH(64), .CYCLES(5)) Buffer5_0(.clk(clk), .in_data(factor), .out_data(w1));
Buffer #(.WIDTH(64), .CYCLES(12)) Buffer12_0(.clk(clk), .in_data(data_in1), .out_data(w2));
Buffer #(.WIDTH(64), .CYCLES(12)) Buffer12_1(.clk(clk), .in_data(data_in2), .out_data(w3));
Complex_Sub S0(.clk(clk), .data_in1(data_in1), .data_in2(data_in2), .data_out(w4));
Complex_Mul M0(.clk(clk), .data_in1(w5), .data_in2(w6), .data_out(w7));
Complex_Sub S1(.clk(clk), .data_in1(w2), .data_in2(w7), .data_out(w9));
Complex_Add A0(.clk(clk), .data_in1(w2), .data_in2(w8), .data_out(data_out1));

assign w5 = control? data_in2 : w4;
assign w6 = control? factor : w1;
assign w8 = control? w7 : w3;
assign data_out2 = control? w9 : w7;
endmodule

module Mul_PointWise #(
    parameter integer N = 32
)(
input                   clk,
input wire [63:0]       data_in1,
input wire [63:0]       data_in2,
output wire [63:0]      data_out
);
wire [63:0] w1;
Complex_Mul M0(.clk(clk), .data_in1(data_in1), .data_in2(data_in2), .data_out(w1));
FP_Complex_Divide_N #(.N(N)) M1(.clk(clk), .data_in(w1), .data_out(data_out));
endmodule

module ROM_device(
input                   clk,
input  wire             en,
input  wire [7:0]       tw_idx,        // chỉ số k (0..255)
output reg  [63:0]      tw_factor     // [63:32] -> image section, [31:0] realsection
);
wire [63:0] w1;
rom_twiddle_top R0 (.en(en), .tw_idx(tw_idx), .tw_factor(w1));

always @(posedge clk) begin
tw_factor <= w1;
end

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
assign addr_ROM = (w1 & step) << m1;

endmodule

module ConvFTT #(
parameter integer N = 32
)(
input  wire                 clk,
input  wire                 rst_n,
input  wire                 start, // valid input
input  wire [31:0]          data_in1,
input  wire [31:0]          data_in2,
output wire [31:0]          data_out,
output                      valid_output,               
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
assign WRAM1 = MUX_in ? {32'b0, data_in1} : tempWRAM;
assign WRAM2 = MUX_in ? {32'b0, data_in2} : BMU_out2;
RAM #(.DATA_WIDTH(64), .MEM_DEPTH(2*N)) RAM_Dual_Port (.data_a(WRAM1), .addr_a(addr_RAM1), .we_a(enRAM1), .q_a(RRAM1), .data_b(WRAM2), .addr_b(addr_RAM2), .we_b(enRAM2), .q_b(RRAM2), .clk(clk));
//ROM
ROM_device ROM (.clk(clk), .en(enROM), .tw_idx({addr_ROM, zero_addr_ROM}), .tw_factor(RROM));
//BMU
Butterfly_Multiplication_Unit BMU (.clk(clk), .data_in1(RRAM1), .data_in2(RRAM2), .factor(RROM), .control(MUX_BMU), .data_out1(BMU_out1), .data_out2(BMU_out2));
//MPW
Mul_PointWise #(.N(N)) MPW(.clk(clk), .data_in1(RRAM1), .data_in2(RRAM2), .data_out(OutMPW));
//Control Unit
Control_FFTConv #(.N(N)) Control_Unit(
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
assign valid_output = MUX_out;
endmodule 


module Top_ConvFTT_1LED (
    input  wire       clk,          // Đã đổi từ sys_clk -> clk
    input  wire       sys_rst_n,    // Reset (Active Low)
    output reg        led_done      // LED báo hiệu
);

    // --- 1. TÍN HIỆU NỘI BỘ ---
    reg         start_reg;
    wire        done_wire;
    wire        valid_wire;
    wire [31:0] data_out_wire;
    
    reg [31:0]  test_data_1;
    reg [31:0]  test_data_2;
    reg [5:0]   feed_counter;
    reg         feeding;
    
    // Biến kiểm tra dữ liệu
    reg [31:0]  result_checksum;

    // Hằng số 1.0 và 0.0 (Float IEEE 754)
    localparam [31:0] FP_ONE  = 32'h3F800000;
    localparam [31:0] FP_ZERO = 32'h00000000;

    // --- 2. LOGIC NẠP INPUT TỰ ĐỘNG ---
    // Lưu ý: Đã đổi sys_clk -> clk trong danh sách nhạy (sensitivity list)
    always @(posedge clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            start_reg    <= 0;
            feed_counter <= 0;
            feeding      <= 0;
            test_data_1  <= 0;
            test_data_2  <= 0;
        end else begin
            // Kích hoạt Start sau khi reset
            if (feed_counter == 0 && !feeding && !done_wire && result_checksum == 0) begin
                start_reg <= 1;
                feeding   <= 1;
            end else begin
                start_reg <= 0;
            end

            // Nạp dữ liệu
            if (feeding) begin
                if (feed_counter < 16) begin
                    test_data_1 <= FP_ONE;
                    test_data_2 <= FP_ONE;
                end else begin
                    test_data_1 <= FP_ZERO;
                    test_data_2 <= FP_ZERO;
                end

                if (feed_counter == 32) feeding <= 0;
                else feed_counter <= feed_counter + 1;
            end
        end
    end

    // --- 3. INSTANTIATE CONVFTT (DUT) ---
    ConvFTT #(
        .N(32)
    ) dut (
        .clk(clk),              // Nối clk vào
        .rst_n(sys_rst_n),
        .start(start_reg),
        .data_in1(test_data_1),
        .data_in2(test_data_2),
        .data_out(data_out_wire),
        .valid_output(valid_wire),
        .done(done_wire)
    );

    // --- 4. LOGIC LED THÔNG MINH ---
    always @(posedge clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            result_checksum <= 0;
            led_done        <= 0;
        end else begin
            // A. Tích lũy kết quả
            if (valid_wire) begin
                result_checksum <= result_checksum | data_out_wire;
            end

            // B. Điều khiển LED
            if (done_wire) begin
                if (result_checksum != 0) 
                    led_done <= 1; // Sáng: PASS
                else 
                    led_done <= 0; // Tắt: FAIL
            end
        end
    end

endmodule