`timescale 1ns / 1ps

module tb_Control_FFTConv;

    // =========================================================
    // 1. Parameters & Signals
    // =========================================================
    parameter integer N = 32;          // Kích thước chuỗi
    parameter integer M = 2;           // Số BMU song song

    // Inputs
    reg clk;
    reg rst_n;
    reg start;

    // Outputs
    wire [$clog2(2*N)-1:0] addr_RAM1;
    wire [$clog2(2*N)-1:0] addr_RAM2;
    wire [$clog2(N)-1:0]   addr_ROM;
    wire enRAM1;
    wire enRAM2;
    wire enROM;
    wire MUX_BMU;
    wire MUX_in;
    wire MUX_out;
    wire MUX_MPW;
    wire done;

    // =========================================================
    // 2. Instantiate DUT (Device Under Test)
    // =========================================================
    Control_FFTConv #(
        .N(N),
        .M(M)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .addr_RAM1(addr_RAM1),
        .addr_RAM2(addr_RAM2),
        .addr_ROM(addr_ROM),
        .enRAM1(enRAM1),
        .enRAM2(enRAM2),
        .enROM(enROM),
        .MUX_BMU(MUX_BMU),
        .MUX_in(MUX_in),
        .MUX_out(MUX_out),
        .MUX_MPW(MUX_MPW),
        .done(done)
    );

    // =========================================================
    // 3. Clock Generation (10ns Period -> 100MHz)
    // =========================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // =========================================================
    // 4. Stimulus Process (Reset & Start Sequence)
    // =========================================================
    initial begin
        // Khởi tạo giá trị ban đầu
        rst_n = 0;
        start = 0;

        // Giữ Reset trong 30ns
        $display("--- [Time 0] System Reset ---");
        #30;
        
        // Thả Reset (rst_n = 1)
        @(posedge clk); 
        #1; // Delay nhẹ để tránh race condition
        rst_n = 1;
        $display("--- [Time %0t] Reset Released ---", $time);

        // Đợi 2 chu kỳ rồi bật Start
        repeat (2) @(posedge clk);
        #1;
        start = 1;
        $display("--- [Time %0t] Start Signal Asserted ---", $time);

        // Chạy mô phỏng cho đến khi Done hoặc timeout
        wait(done);
        @(posedge clk); // Đợi thêm 1 chu kỳ sau khi done
        $display("--- [Time %0t] Operation Completed (Done=1) ---", $time);
        
        #20;
        $finish;
    end

    // =========================================================
    // 5. Monitor Output (In giá trị tại mỗi xung Clock)
    // =========================================================
    initial begin
        // In tiêu đề bảng
        $display("Time | Rst | St | R1_Addr | R2_Addr | ROM_Addr | EnR1| EnR2| EnRM| BMU | In | Out| MPW | Done");
        $display("--------------------------------------------------------------------------------------------------");
        
        forever begin
            @(posedge clk);
            #2; // Sample output sau cạnh lên một chút để thấy giá trị ổn định
            
            // Format in: %d (decimal), %b (binary), %t (time)
            $display("%4t |  %b  |  %b |   %3d   |   %3d   |    %3d   |  %b  |  %b  |  %b  |  %b  |  %b |  %b |  %b  |  %b",
                $time, rst_n, start, 
                addr_RAM1, addr_RAM2, addr_ROM,
                enRAM1, enRAM2, enROM, 
                MUX_BMU, MUX_in, MUX_out, MUX_MPW, 
                done
            );
        end
    end

    // Timeout an toàn (đề phòng vòng lặp vô tận)
    initial begin
        #10000;
        $display("--- Simulation Timeout! Check logic for infinite loops. ---");
        $finish;
    end

endmodule