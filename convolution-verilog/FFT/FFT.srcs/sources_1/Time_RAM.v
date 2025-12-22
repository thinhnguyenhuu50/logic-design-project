// Filename: ram_benchmark.v (Phiên bản sạch, không BUFG)
module ram_benchmark #(
    parameter DATA_WIDTH = 64,
    parameter MEM_DEPTH  = 64,
    localparam ADDR_WIDTH = 6 
)(
    input clk, 
    input [DATA_WIDTH-1:0] sys_data_a, sys_data_b,
    input [ADDR_WIDTH-1:0] sys_addr_a, sys_addr_b,
    input sys_we_a, sys_we_b,
    output reg [DATA_WIDTH-1:0] sys_q_a, sys_q_b
);
    // 1. Input Registers
    reg [DATA_WIDTH-1:0] r_data_a, r_data_b;
    reg [ADDR_WIDTH-1:0] r_addr_a, r_addr_b;
    reg r_we_a, r_we_b;

    always @(posedge clk) begin 
        r_data_a <= sys_data_a; r_addr_a <= sys_addr_a; r_we_a <= sys_we_a;
        r_data_b <= sys_data_b; r_addr_b <= sys_addr_b; r_we_b <= sys_we_b;
    end

    // 2. RAM Instance
    wire [DATA_WIDTH-1:0] w_ram_out_a, w_ram_out_b;
    RAM #(.DATA_WIDTH(DATA_WIDTH), .MEM_DEPTH(MEM_DEPTH)) my_ram_inst (
        .clk(clk),
        .data_a(r_data_a), .addr_a(r_addr_a), .we_a(r_we_a), .q_a(w_ram_out_a),
        .data_b(r_data_b), .addr_b(r_addr_b), .we_b(r_we_b), .q_b(w_ram_out_b)
    );

    // 3. Output Registers
    always @(posedge clk) begin
        sys_q_a <= w_ram_out_a;
        sys_q_b <= w_ram_out_b;
    end
endmodule

module Time_RAM (
    input clk,      // Chân H16 trên mạch
    output led_done // Chân LED để báo hiệu (tránh bị optimize logic)
);

    // --- Tự sinh dữ liệu giả bên trong chip ---
    reg [63:0] gen_data;
    reg [5:0]  gen_addr;
    
    // Bộ đếm đơn giản để tạo dữ liệu thay đổi liên tục
    always @(posedge clk) begin
        gen_data <= gen_data + 64'd1;
        gen_addr <= gen_addr + 6'd1;
    end

    // --- Gọi module Benchmark ---
    wire [63:0] out_q_a, out_q_b;
    
    ram_benchmark dut (
        .clk(clk), // Vivado tự động chèn BUFG ở đây
        // Nối dây dữ liệu giả vào
        .sys_data_a(gen_data), 
        .sys_data_b(~gen_data), // Đảo bit để khác biệt
        .sys_addr_a(gen_addr),
        .sys_addr_b(gen_addr),
        .sys_we_a(1'b1), // Luôn ghi
        .sys_we_b(1'b0), // Chỉ đọc
        // Lấy kết quả ra
        .sys_q_a(out_q_a),
        .sys_q_b(out_q_b)
    );

    // --- Gom 128 bit output lại thành 1 bit LED ---
    // Phép XOR tất cả các bit lại với nhau.
    // Mục đích: Bắt buộc Vivado phải giữ lại toàn bộ mạch RAM để tính toán ra cái LED này.
    reg led_reg;
    always @(posedge clk) begin
        led_reg <= ^out_q_a ^ ^out_q_b; 
    end
    
    assign led_done = led_reg;

endmodule