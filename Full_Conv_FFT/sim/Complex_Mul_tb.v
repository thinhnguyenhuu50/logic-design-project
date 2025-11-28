`timescale 1ns / 1ps

module Complex_Mul_tb;

    // --- 1. KHAI BÁO TÍN HIỆU TESTBENCH ---
    reg clk;
    reg reset;

    // Đầu vào cho DUT (Device Under Test)
    reg [63:0] tb_data_in1; // {I_A[31:0], R_A[31:0]}
    reg [63:0] tb_data_in2; // {I_B[31:0], R_B[31:0]}

    // Đầu ra từ DUT: {I_OUT[31:0], R_OUT[31:0]}
    wire [63:0] tb_data_out;

    // --- 2. KHỞI TẠO MODULE Complex_Mul ---
    Complex_Mul DUT (
        .data_in1(tb_data_in1),
        .data_in2(tb_data_in2),
        .data_out(tb_data_out)
    );

    // --- 3. KHỞI TẠO ĐỒNG HỒ VÀ RESET ---
    localparam PERIOD = 10; 

    initial begin
        clk = 1'b0;
        forever #(PERIOD/2) clk = ~clk;
    end

    initial begin
        reset = 1'b1;
        #20 reset = 1'b0;
    end

    // --- 4. CHUỖI MÔ PHỎNG (STIMULUS) ---
    initial begin
        $display("--- Bắt đầu mô phỏng Complex_Mul (I: MSB, R: LSB) ---");
        $dumpfile("Complex_Mul.vcd");
        $dumpvars(0, Complex_Mul_tb);

        // Khởi tạo đầu vào ban đầu
        tb_data_in1 = 64'h0;
        tb_data_in2 = 64'h0;
        
        # (PERIOD * 5); 
        
        // --- TEST CASE 1: Số phức (1.0 + j*2.0) * (3.0 + j*4.0) ---

        // Giá trị dấu phẩy động 32-bit (IEEE 754):
        // 1.0 -> 3f800000
        // 2.0 -> 40000000
        // 3.0 -> 40400000
        // 4.0 -> 40800000

        // KQ Lý thuyết: R_OUT = -5.0 (c0a00000), I_OUT = 10.0 (41200000)

        // data_in1 (A): R_A=1.0, I_A=2.0
        // Cấu trúc: {I_A, R_A}
        tb_data_in1 = {32'h40000000, 32'h3f800000}; 
        
        // data_in2 (B): R_B=3.0, I_B=4.0
        // Cấu trúc: {I_B, R_B}
        tb_data_in2 = {32'h40800000, 32'h40400000};

        # (PERIOD * 3); // Chờ 3 chu kỳ để tính toán

        $display("------------------------------------------------------------------");
        $display("TEST CASE 1: (1.0+j2.0) * (3.0+j4.0)");
        $display("A (R, I): 0x%h, 0x%h", tb_data_in1[31:0], tb_data_in1[63:32]);
        $display("B (R, I): 0x%h, 0x%h", tb_data_in2[31:0], tb_data_in2[63:32]);
        $display("KQ Nhan duoc (R, I): 0x%h, 0x%h", tb_data_out[31:0], tb_data_out[63:32]);
        $display("KQ Mong doi (R, I): 0xc0a00000, 0x41200000");
        $display("------------------------------------------------------------------");

        // --- TEST CASE 2: Số phức (5.0 + j*0.5) * (0.1 + j*(-0.2)) ---

        // 5.0 -> 40a00000
        // 0.5 -> 3f000000
        // 0.1 -> 3dcccccd
        // -0.2 -> bdcccccd
        // KQ Lý thuyết (Tính bằng phần mềm): R_OUT = 0.6 (3f19999a), I_OUT = -0.75 (bf400000)

        // data_in1 (A): R_A = 5.0, I_A = 0.5
        tb_data_in1 = {32'h3f000000, 32'h40a00000}; 
        
        // data_in2 (B): R_B = 0.1, I_B = -0.2
        tb_data_in2 = {32'hbdcccccd, 32'h3dcccccd};

        # (PERIOD * 3);

        $display("TEST CASE 2: (5.0+j0.5) * (0.1-j0.2)");
        $display("A (R, I): 0x%h, 0x%h", tb_data_in1[31:0], tb_data_in1[63:32]);
        $display("B (R, I): 0x%h, 0x%h", tb_data_in2[31:0], tb_data_in2[63:32]);
        $display("KQ Nhan duoc (R, I): 0x%h, 0x%h", tb_data_out[31:0], tb_data_out[63:32]);
        $display("KQ Mong doi (R, I): 0x3f19999a, 0xbf400000");
        $display("------------------------------------------------------------------");


        // Kết thúc mô phỏng
        # (PERIOD * 5);
        $finish;
    end
endmodule