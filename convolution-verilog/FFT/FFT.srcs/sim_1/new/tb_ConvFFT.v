`timescale 1ns / 1ps

module tb_ConvFFT;

    // =========================================================
    // 1. Parameters & Signals
    // =========================================================
    parameter integer N = 32;

    reg clk;
    reg rst_n;
    reg start;
    
    // --- UPDATE: Khai báo 2 đường input ---
    reg [31:0] data_in1;
    reg [31:0] data_in2;
    // --------------------------------------

    wire [31:0] data_out;
    wire done;
    wire valid_output; 

    // Biến dùng cho vòng lặp và file I/O
    integer i;
    integer outfile;              
    reg [31:0] input_mem [0: 2*N -1];  // Bộ nhớ đệm chứa toàn bộ dữ liệu (64 mẫu)

    // =========================================================
    // 2. Instantiate DUT (Kết nối với module mới của bạn)
    // =========================================================
    ConvFTT #(
        .N(N)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .data_in1(data_in1), // Nối dây in1
        .data_in2(data_in2), // Nối dây in2
        .data_out(data_out),
        .valid_output(valid_output),
        .done(done)
    );

    // =========================================================
    // 3. Clock Generation (100MHz)
    // =========================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // =========================================================
    // 4. File Output Logic
    // =========================================================
    initial begin
        outfile = $fopen("output_result.txt", "w");
        if (outfile == 0) begin
            $display("Error: Khong the mo file output_result.txt");
            $finish;
        end
    end

    // Ghi dữ liệu ra file khi valid_output = 1
    always @(posedge clk) begin
        if (valid_output) begin
             $fdisplay(outfile, "%h", data_out); 
             // $display("Time %t: Writing Data %h", $time, data_out); // Debug
        end
    end

    // =========================================================
    // 5. Stimulus Process (PHẦN QUAN TRỌNG NHẤT)
    // =========================================================
    initial begin
        // --- B1: ĐỌC FILE INPUT ---
        // Giả sử file "input_data.data" có 64 dòng Hex.
        // Dòng 0-31: Dữ liệu cho data_in1
        // Dòng 32-63: Dữ liệu cho data_in2
        $readmemh("input_data.data", input_mem);
        
        // --- B2: Khởi tạo tín hiệu ---
        rst_n = 0;
        start = 0;
        data_in1 = 0;
        data_in2 = 0;

        // Reset hệ thống
        #100;
        rst_n = 1;
        #20;
        start = 1;
        // Đồng bộ cạnh xuống
        #12
        
        // --- B3: Bắt đầu xử lý ---

                
        // --- B4: Nạp song song 2 chuỗi (UPDATE QUAN TRỌNG) ---
        // Chạy 1 vòng lặp 32 lần, mỗi lần đẩy 1 cặp dữ liệu vào
        for (i = 0; i < N; i = i + 1) begin
            // Input 1 lấy từ nửa đầu mảng (index i)
            data_in1 = input_mem[i]; 
            
            // Input 2 lấy từ nửa sau mảng (index i + 32)
            data_in2 = input_mem[i + N]; 
            
            @(negedge clk); // Đẩy dữ liệu vào mỗi chu kỳ clock
        end

        // Kết thúc nạp dữ liệu -> Dừng start và đưa data về 0
        start = 0; // Tùy thiết kế của bạn có cần giữ start không, thường nạp xong thì hạ
        data_in1 = 0;
        data_in2 = 0;
        #1650
        #50
        #1700
        #880
        #340
        #340
        #340
        #20
        #160
        #10
        #320
        #340
        #1700
        #10
        // --- B5: Chờ kết quả ---
        // Bạn có thể dùng wait(done) để tự động chờ thay vì #delay cứng
        wait(done);
        
        // Đợi thêm vài clock cho tín hiệu ổn định
        repeat(5) @(posedge clk); 
        
        $display("-------------------------------------------");
        $display("Simulation Completed at time: %t", $time);
        $display("Output data has been saved to 'output_result.txt'");
        $display("-------------------------------------------");
        
        $fclose(outfile);
        $stop;
    end

endmodule