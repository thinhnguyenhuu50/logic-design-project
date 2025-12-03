`timescale 1ns / 1ps

module tb_ConvFFT;

    // =========================================================
    // 1. Parameters & Signals
    // =========================================================
    parameter integer N = 32;

    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] data_in;
    
    wire [31:0] data_out;
    wire done;
    wire valid_output; // Tín hiệu báo hiệu output hợp lệ

    // Biến dùng cho vòng lặp và file I/O
    integer i;
    integer outfile;              // File handler cho output
    reg [31:0] input_mem [0:63];  // Bộ nhớ đệm đọc input file

    // =========================================================
    // 2. Instantiate DUT (Device Under Test)
    // =========================================================
    ConvFTT #(
        .N(N)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .data_in(data_in),
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
    // 4. File Output Logic (UPDATED)
    // =========================================================
    initial begin
        // Mở file để ghi (mode "w")
        outfile = $fopen("output_result.txt", "w");
        if (outfile == 0) begin
            $display("Error: Khong the mo file output_result.txt");
            $finish;
        end
    end

    // --- LOGIC GHI FILE CHỈ KHI VALID_OUTPUT = 1 ---
    always @(posedge clk) begin
        // Kiểm tra tín hiệu valid_output. 
        // Nếu module của bạn bật valid_output lên 1 khi có dữ liệu ra, ta sẽ ghi lại.
        if (valid_output) begin
             $fdisplay(outfile, "%h", data_out); 
             // (Optional) In ra màn hình console để debug dễ hơn
             // $display("Time %t: Writing Data %h", $time, data_out);
        end
    end
    // -----------------------------------------------

    // =========================================================
    // 5. Stimulus Process
    // =========================================================
    initial begin
        // --- B1: ĐỌC FILE INPUT ---
        // Load file hex vào mảng nhớ tạm
        // Lưu ý: Đảm bảo file "input_data.data" tồn tại
        $readmemh("input_data.data", input_mem);
        
        // --- B2: Khởi tạo tín hiệu ---
        rst_n = 0;
        start = 0;
        data_in = 0;

        // Reset hệ thống
        #100;
        rst_n = 1;
        #20;

        // Đồng bộ với cạnh xuống để nạp dữ liệu an toàn
        @(negedge clk); 
        
        // --- B3: Bắt đầu xử lý ---
        start = 1;
        @(negedge clk);
        
        // --- B4: Nạp Chuỗi 1 (32 mẫu đầu) ---
        for (i = 0; i < 32; i = i + 1) begin
            data_in = input_mem[i]; 
            @(negedge clk); 
        end

        // --- B5: Nạp Chuỗi 2 (32 mẫu sau) ---
        for (i = 32; i < 64; i = i + 1) begin
            data_in = input_mem[i]; 
            @(negedge clk);
        end

        // Kết thúc nạp dữ liệu, đưa data_in về 0
        data_in = 0;

        // --- B6: Chờ xử lý (Timing mô phỏng của bạn) ---
        // Các khoảng delay này dựa trên thiết kế Pipeline của bạn
        
        // Giai đoạn DIF RAM1
        #1600;
        
        // Giai đoạn DIF RAM2
        #1600;
        
        // Giai đoạn MPW (Multiplication Point-Wise)
        #640;
        
        // Giai đoạn DIT
        #1600;
        
        // Giai đoạn Output (Dựa vào valid_output để ghi file)
        // Chờ thêm một chút để đảm bảo
        #620;
        // --- B7: Kết thúc ---
        // Cách tốt nhất là chờ tín hiệu done từ DUT
        wait(done);
        @(posedge clk); // Đợi thêm 1 cycle cho chắc chắn
        
        $display("-------------------------------------------");
        $display("Simulation Completed at time: %t", $time);
        $display("Output data has been saved to 'output_result.txt'");
        $display("-------------------------------------------");
        
        $fclose(outfile); // Đóng file để lưu dữ liệu
        
        #100;
        $stop;
    end

endmodule