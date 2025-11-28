`timescale 1ns / 1ps

module tb_ConvFFT;

    // 1. Parameters
    parameter integer N = 32;

    // 2. Signals
    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] data_in;
    wire [31:0] data_out;
    wire done;

    // Biến dùng cho vòng lặp
    integer i;

    // 3. Instantiate DUT (Device Under Test)
    ConvFTT #(
        .N(N)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .data_in(data_in),
        .data_out(data_out),
        .done(done)
    );

    // 4. Clock Generation (100MHz -> 10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 5. Stimulus (Kịch bản kiểm tra)
    initial begin
        // --- Khởi tạo giá trị ban đầu ---
        rst_n = 0;
        start = 0;
        data_in = 0;

        // --- Reset hệ thống (giữ trong 100ns) ---
        #100;
        rst_n = 1;
        #20; // Đợi một chút sau reset

        // Đồng bộ với cạnh xuống của clock để tránh race condition
        @(negedge clk); 
        
        // ---------------------------------------------------------
        // BƯỚC 1: KÍCH HOẠT START
        // ---------------------------------------------------------
        start = 1;
        @(negedge clk);
        data_in = 32'h3F800000;
        @(negedge clk);      // Bật Start
 
        // ---------------------------------------------------------
        // BƯỚC 2: NẠP CHUỖI 1 (32 điểm)
        // ---------------------------------------------------------
        // Nạp giá trị cơ bản là 1.0 (3F800000) nhưng cộng thêm i
        // để trên waveform thấy giá trị thay đổi từng nhịp
        for (i = 1; i < 32; i = i + 1) begin
            data_in = 32'h3F800000 + i; 
            
            // Giữ giá trị này trong 1 chu kỳ clock để module đọc vào
            @(negedge clk); 
        end

        // ---------------------------------------------------------
        // BƯỚC 3: NẠP CHUỖI 2 (32 điểm)
        // ---------------------------------------------------------
        // Nạp giá trị cơ bản là 2.0 (40000000) cộng thêm i
        // Lúc này data_in sẽ nhảy lên mức cao hơn hẳn, dễ nhìn thấy sự chuyển giao
        for (i = 0; i < 32; i = i + 1) begin
            data_in = 32'h40000000 + i; 
            
            @(negedge clk);
        end

        // ---------------------------------------------------------
        // BƯỚC 4: KẾT THÚC QUÁ TRÌNH NẠP
        // ---------------------------------------------------------
        data_in = 0; // Trả về 0 cho sạch sóng
        #30
        // Chờ tín hiệu Done từ module báo xử lý xong
//        wait(done);
//        $display("Simulation Completed: Module bao hieu DONE tai thoi diem %t", $time);
        
        // Chạy thêm 100ns để nhìn dạng sóng output sau khi done
        #4000;
        $stop;
    end

    // Tùy chọn: In ra màn hình console để kiểm tra giá trị nếu không muốn soi waveform
    initial begin
        $monitor("Time=%t | State: Start=%b | In=%h | Out=%h | Done=%b", 
                 $time, start, data_in, data_out, done);
    end

endmodule