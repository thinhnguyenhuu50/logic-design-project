`timescale 1ns / 1ps

module tb_butterfly_std;
    // --- Inputs ---
    reg [63:0] data_in1;
    reg [63:0] data_in2;
    reg [63:0] factor;
    reg control; // 0: DIF, 1: DIT

    // --- Outputs ---
    wire [63:0] data_out1;
    wire [63:0] data_out2;

    // --- Instantiate the Unit Under Test (UUT) ---
    Butterfly_Multiplication_Unit uut (
        .data_in1(data_in1),
        .data_in2(data_in2),
        .factor(factor),
        .control(control),
        .data_out1(data_out1),
        .data_out2(data_out2)
    );

    // --- Kho chứa các số Float "Xấu" (Ugly Numbers Bank) ---
    // Mảng này chứa 16 giá trị float 32-bit (IEEE 754) khó chịu
    reg [31:0] ugly_floats [0:15];
    
    integer i;
    reg [3:0] idx_r1, idx_i1, idx_r2, idx_i2, idx_rw, idx_iw;

    initial begin
        // 1. Khởi tạo kho số xấu (Pre-calculated Hex)
        ugly_floats[0]  = 32'h40490FDB; //  3.1415927 (Pi)
        ugly_floats[1]  = 32'hC02DF854; // -2.7182817 (-e)
        ugly_floats[2]  = 32'h3FB504F3; //  1.4142135 (Sqrt 2)
        ugly_floats[3]  = 32'hBFCCCCCD; // -1.6000000
        ugly_floats[4]  = 32'h3DCCCCCD; //  0.1000000 (Số nhỏ)
        ugly_floats[5]  = 32'hBDCCCCCD; // -0.1000000
        ugly_floats[6]  = 32'h449A522B; //  1234.5678 (Số lớn)
        ugly_floats[7]  = 32'hC49A522B; // -1234.5678
        ugly_floats[8]  = 32'h3F9E0652; //  1.2345678
        ugly_floats[9]  = 32'hBF9E0652; // -1.2345678
        ugly_floats[10] = 32'h3EAAAAAB; //  0.3333333 (1/3)
        ugly_floats[11] = 32'hBEAAAAAB; // -0.3333333 (-1/3)
        ugly_floats[12] = 32'h49742400; //  1000000.0 (Triệu)
        ugly_floats[13] = 32'h38D1B717; //  0.0001000 (Rất nhỏ)
        ugly_floats[14] = 32'h00000000; //  0.0
        ugly_floats[15] = 32'hBF800000; // -1.0

        // Initialize Inputs
        data_in1 = 0; data_in2 = 0; factor = 0; control = 0;

        $display("----------------------------------------------------------------");
        $display("    RANDOM & UGLY NUMBERS TEST BENCH (Verilog 2001 Compatible)  ");
        $display("----------------------------------------------------------------");
        #100;

        // =====================================================================
        // TEST CASE 7: Specific "Ugly" Calculation (DIT)
        // Kiểm tra độ chính xác với số thập phân lẻ cụ thể
        // =====================================================================
        $display("\nTest Case 7: Specific Ugly Numbers (Pi, 2.5, -0.5)");
        control = 1; // DIT

        // In1 (x0) = 3.14159... + j0
        data_in1 = {32'h00000000, 32'h40490FDB}; 
        
        // In2 (x1) = 2.5 + j0
        data_in2 = {32'h00000000, 32'h40200000}; 
        
        // W = -0.5 + j0
        factor   = {32'h00000000, 32'hBF000000};

        // LOGIC TÍNH TOÁN TAY:
        // Term = x1 * W = 2.5 * (-0.5) = -1.25
        // Out1 = x0 + Term = 3.14159 - 1.25 = 1.89159...
        // Out2 = x0 - Term = 3.14159 - (-1.25) = 4.39159...

        // EXPECTED HEX:
        // 1.89159... -> 3FF21CAC
        // 4.39159... -> 408C87F5
        
        #10;
        $display("Inputs:  in1=Pi(3.14..), in2=2.5, W=-0.5");
        $display("Out1 Real (Expect ~1.89 / 3FF21CAC): %h", data_out1[31:0]);
        $display("Out2 Real (Expect ~4.39 / 408C87F5): %h", data_out2[31:0]);

        // =====================================================================
        // TEST CASE 8: RANDOM "UGLY" MIX
        // Chạy 5 vòng lặp, mỗi vòng chọn ngẫu nhiên các số từ kho "ugly_floats"
        // =====================================================================
        $display("\nTest Case 8: Random 'Ugly' Mix (5 Iterations)");
        
        for (i = 1; i <= 5; i = i + 1) begin
            #20;
            // Chọn ngẫu nhiên index từ 0 đến 15
            idx_r1 = {$random} % 16; idx_i1 = {$random} % 16;
            idx_r2 = {$random} % 16; idx_i2 = {$random} % 16;
            idx_rw = {$random} % 16; idx_iw = {$random} % 16;
            
            // Random Control (DIT hoặc DIF)
            control = {$random} % 2; 

            // Gán dữ liệu ngẫu nhiên từ kho số
            data_in1 = {ugly_floats[idx_i1], ugly_floats[idx_r1]};
            data_in2 = {ugly_floats[idx_i2], ugly_floats[idx_r2]};
            factor   = {ugly_floats[idx_iw], ugly_floats[idx_rw]};

            #10; // Chờ kết quả
            
            $display("--- Random Iteration %0d (Mode: %s) ---", i, control ? "DIT" : "DIF");
            $display("In1 Hex:    %h (RealIdx: %d, ImagIdx: %d)", data_in1, idx_r1, idx_i1);
            $display("In2 Hex:    %h (RealIdx: %d, ImagIdx: %d)", data_in2, idx_r2, idx_i2);
            $display("Factor Hex: %h (RealIdx: %d, ImagIdx: %d)", factor, idx_rw, idx_iw);
            $display("--> Out1:   %h", data_out1);
            $display("--> Out2:   %h", data_out2);
        end

        #20;
        $stop;
    end
endmodule