`timescale 1ns / 1ps

module tb_Complex_Mul;

    // =========================================================
    // 1. CẤU HÌNH & KHAI BÁO
    // =========================================================
    reg clk;
    reg [63:0] data_in1; // {Imag A, Real A}
    reg [63:0] data_in2; // {Imag B, Real B}
    wire [63:0] data_out; // {Imag Out, Real Out}

    // --- CẤU HÌNH LATENCY & TOLERANCE ---
    localparam LATENCY    = 12; // Mul(7) + Add(5)
    localparam PERIOD     = 10; // 100 MHz
    localparam TEST_COUNT = 1; // Số lượng test case (Cập nhật theo số case của bạn)
    localparam TOLERANCE  = 10; // Cho phép sai số <= 50 đơn vị LSB

    // Mảng lưu dữ liệu test
    reg [63:0] in1_arr [0:TEST_COUNT-1];
    reg [63:0] in2_arr [0:TEST_COUNT-1];
    reg [63:0] exp_arr [0:TEST_COUNT-1];

    // =========================================================
    // 2. KẾT NỐI DUT
    // =========================================================
    Complex_Mul u_dut (
        .clk(clk),
        .data_in1(data_in1),
        .data_in2(data_in2),
        .data_out(data_out)
    );

    // =========================================================
    // 3. TẠO CLOCK
    // =========================================================
    initial begin
        clk = 0;
        forever #(PERIOD/2) clk = ~clk;
    end

    // =========================================================
    // 4. DỮ LIỆU TEST (PASTE TỪ PYTHON VÀO ĐÂY)
    // =========================================================
    initial begin
// --- Generated 20 SPECIAL Corner Cases ---
    // Format: {Imaginary (High), Real (Low)}
    in1_arr[0] = 64'h3f43f1413fec84b6;
    in2_arr[0] = 64'hbec3ef153f6c835e;
    exp_arr[0] = 64'h00000000_3f800000;
    end

    // =========================================================
    // 5. DRIVER PROCESS (NẠP DATA)
    // =========================================================
    integer i;
    initial begin
        data_in1 = 0;
        data_in2 = 0;
        
        // Đợi Reset/Start
        #(PERIOD * 5); 

        $display("\n=============================================================");
        $display(" STARTING COMPLEX MUL TEST (Latency=%0d, Tolerance=%0d LSB)", LATENCY, TOLERANCE);
        $display("=============================================================\n");

        // Burst Mode Pushing
        for (i = 0; i < TEST_COUNT; i = i + 1) begin
            @(posedge clk);
            data_in1 <= in1_arr[i];
            data_in2 <= in2_arr[i];
            
            $display("[%0t ns] Driver: Pushed Case %0d", $time, i);
        end
        
        @(posedge clk);
        data_in1 <= 0;
        data_in2 <= 0;
    end

    // =========================================================
    // 6. MONITOR PROCESS (CHECK KẾT QUẢ THÔNG MINH)
    // =========================================================
    integer k;
    reg [31:0] act_real, act_imag;
    reg [31:0] exp_real, exp_imag;
    integer diff_real, diff_imag; // Dùng integer để tính hiệu

    initial begin
        // Đồng bộ thời gian chờ với Driver
        #(PERIOD * 5); 
        
        // Đợi data đi qua Pipeline
        #(LATENCY * PERIOD); 

        $display("\n-------------------------------------------------------------");
        $display(" CHECKING RESULTS");
        $display("-------------------------------------------------------------\n");

        for (k = 0; k < TEST_COUNT; k = k + 1) begin
            @(posedge clk);
            #1; // Đợi ổn định tín hiệu

            // Tách phần Thực và Ảo (Format: High=Imag, Low=Real)
            act_imag = data_out[63:32];
            act_real = data_out[31:0];
            
            exp_imag = exp_arr[k][63:32];
            exp_real = exp_arr[k][31:0];

            // --- TÍNH ĐỘ LỆCH (ABSOLUTE DIFFERENCE) ---
            // Phần Thực
            if (act_real > exp_real) diff_real = act_real - exp_real;
            else                     diff_real = exp_real - act_real;

            // Phần Ảo
            if (act_imag > exp_imag) diff_imag = act_imag - exp_imag;
            else                     diff_imag = exp_imag - act_imag;

            // --- SO SÁNH VỚI DUNG SAI (TOLERANCE) ---
            if (diff_real <= TOLERANCE && diff_imag <= TOLERANCE) begin
                if (diff_real == 0 && diff_imag == 0) begin
                    // Trường hợp đúng tuyệt đối
                    $display("[%0t ns] Case %2d: PASS (Exact)", $time, k);
                end else begin
                    // Trường hợp lệch nhẹ (chấp nhận được)
                    $display("[%0t ns] Case %2d: PASS (Tolerance) | Diff Real: %0d, Imag: %0d", 
                             $time, k, diff_real, diff_imag);
                end
            end else begin
                // Trường hợp sai số quá lớn -> FAIL thật
                $display("[%0t ns] Case %2d: FAIL !!!", $time, k);
                $display("    Expected: Imag=%h, Real=%h", exp_imag, exp_real);
                $display("    Actual:   Imag=%h, Real=%h", act_imag, act_real);
                $display("    Diff:     Imag=%0d,      Real=%0d", diff_imag, diff_real);
            end
        end
        
        $display("\n=============================================================");
        $display(" TEST COMPLETE");
        $display("=============================================================\n");
        $finish;
    end
    
    // Waveform Dump
    initial begin
        $dumpfile("dump_complex.vcd");
        $dumpvars(0, tb_Complex_Mul);
    end

endmodule