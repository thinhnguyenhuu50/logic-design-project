`timescale 1ns / 1ps

module tb_Temp_Conv_FFT;

    // =========================================================
    // 2. KHAI BAO THAM SO & TIN HIEU
    // =========================================================
    parameter integer N = 32;
    parameter integer M = 2;
    localparam integer ADDR_WIDTH_RAM = $clog2(2*N);
    localparam integer ADDR_WIDTH_ROM = $clog2(N);
    // Inputs (Reg)
    reg [31:0] data_in; // Du lieu Float 32-bit
    reg clk;
    reg [ADDR_WIDTH_RAM-1:0] addr_RAM1;
    reg [ADDR_WIDTH_RAM-1:0] addr_RAM2;
    reg [ADDR_WIDTH_ROM-1:0] addr_ROM;
    
    // Control Flags
    reg enRAM1, enRAM2, enROM;
    reg MUX_BMU;      // 0: DIF, 1: DIT
    reg MUX_in;       // 1: Write Input mode
    reg MUX_out;      // 1: Read Output mode
    reg MUX_MPW;
    reg enBuffer_RAM, enBuffer_ROM, enBuffer_BMU, loadBuffer_BMU;

    // Outputs (Wire)
    wire [31:0] data_out;

    // =========================================================
    // 3. INSTANTIATE UUT (Unit Under Test)
    // =========================================================
    Temp_Conv_FFT #(
        .N(N), 
        .M(M)
    ) uut (
        .data_in(data_in), 
        .clk(clk), 
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
        .enBuffer_RAM(enBuffer_RAM), 
        .enBuffer_ROM(enBuffer_ROM), 
        .enBuffer_BMU(enBuffer_BMU), 
        .loadBuffer_BMU(loadBuffer_BMU), 
        .data_out(data_out)
    );

    // Tao xung Clock (T = 20ns -> 50MHz)
    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end
    // =========================================================
    // 5. MAIN TEST SEQUENCE
    // =========================================================
    initial begin
        // --- KHOI TAO ---
        data_in = 0; addr_RAM1 = 0; addr_RAM2 = 0; addr_ROM = 0;
        enRAM1 = 0; enRAM2 = 0; enROM = 0;
        MUX_BMU = 0; MUX_in = 0; MUX_out = 0; MUX_MPW = 0;
        enBuffer_RAM = 0; enBuffer_ROM = 0; enBuffer_BMU = 0; loadBuffer_BMU = 0;

        #20;
        $display("---------------------------------------------------");
        $display(" START SIMULATION: FFT FLOAT (REAL INPUT -> IMAG ZERO)");
        $display("---------------------------------------------------");
        MUX_in = 1; // Bat che do ghi Input vao RAM
        MUX_out = 1;
        data_in = 32'h3f800000;
        addr_RAM1 = 0;
        enRAM1 = 1;
        #10
        data_in = 32'h40000000;
        addr_RAM1 = 1;
        #10
        data_in = 32'h40400000;
        addr_RAM1 = 4;
        #10
        data_in = 32'h40800000;
        addr_RAM1 = 5;
        #10
        MUX_in = 0;
        enRAM1 = 0;
        enRAM2 = 0;
        enROM = 1;
        addr_RAM1 = 0;
        addr_RAM2 = 4;
        addr_ROM = 0;
        enBuffer_RAM = 1;
        enBuffer_ROM = 1;
        #10
        addr_RAM1 = 1;
        addr_RAM2 = 5;
        addr_ROM = 1;
        #10
        
        #10
        
        enBuffer_RAM = 0;
        enBuffer_ROM = 0;
        loadBuffer_BMU = 1;
        enRAM1 = 1;
        enRAM2 = 1;
        addr_RAM1 = 0;
        addr_RAM2 = 4;
        #10
        enBuffer_BMU = 1;
        loadBuffer_BMU = 0;
        addr_RAM1 = 1;
        addr_RAM2 = 5;
        #10
        enRAM1 = 0;
        enRAM2 = 0;
        addr_RAM1 = 0;
        #10
        addr_RAM1 = 1;
        #10
        addr_RAM1 = 4;
        #10
        addr_RAM1 = 5;
        #20
        $stop;
    end

endmodule



`timescale 1ns / 1ps

module tb_ShiftRegisters;

    // =========================================================
    // PARAMETERS
    // =========================================================
    parameter integer DATA_WIDTH = 4; // Test voi 4 bit cho de quan sat

    // =========================================================
    // TIN HIEU CHUNG
    // =========================================================
    reg clk;

    // =========================================================
    // TIN HIEU CHO SIPO
    // =========================================================
    reg sipo_enable;
    reg sipo_serial_in;
    wire [DATA_WIDTH-1:0] sipo_parallel_out;

    // =========================================================
    // TIN HIEU CHO PISO
    // =========================================================
    reg piso_load_en;
    reg piso_shift_en;
    reg [DATA_WIDTH-1:0] piso_data_in;
    wire piso_serial_out;

    // =========================================================
    // KHOI TAO MODULE (INSTANTIATION)
    // =========================================================
    
    // 1. Unit Under Test: SIPO
    SIPO #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_sipo (
        .clk(clk),
        .enable(sipo_enable),
        .serial_in(sipo_serial_in),
        .parallel_out(sipo_parallel_out)
    );

    // 2. Unit Under Test: PISO
    PISO #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_piso (
        .clk(clk),
        .load_en(piso_load_en),
        .shift_en(piso_shift_en),
        .data_in(piso_data_in),
        .serial_out(piso_serial_out)
    );

    // =========================================================
    // TAO CLOCK (Chu ky 20ns -> 50MHz)
    // =========================================================
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // =========================================================
    // KICH BAN KIEM TRA (TEST VECTOR)
    // =========================================================
    initial begin
        // --- KHOI TAO GIA TRI BAN DAU ---
        sipo_enable = 0;
        sipo_serial_in = 0;
        
        piso_load_en = 0;
        piso_shift_en = 0;
        piso_data_in = 0;

        // Cho he thong on dinh
        #20; 
        
        $display("-------------------------------------------------");
        $display(" BAT DAU MO PHONG SIPO & PISO (WIDTH = 4)");
        $display("-------------------------------------------------");

        // ======================================================
        // TEST 1: SIPO (Serial In -> Parallel Out)
        // Muc tieu: Nap chuoi bit 1 -> 0 -> 1 -> 1 vao.
        // Ky vong output: 4'b1011 (Hex: B)
        // ======================================================
        $display("\n[TEST 1] SIPO: Nạp chuỗi bit 1-0-1-1");
        
        sipo_enable = 1; // Bat cho phep dich

        // Bit 1 (MSB cua ket qua sau nay)
        sipo_serial_in = 1;
        #20; // Doi 1 clock
        $display("Time %0t: SIPO In=1 -> Out=%b", $time, sipo_parallel_out);

        // Bit 0
        sipo_serial_in = 0;
        #20;
        $display("Time %0t: SIPO In=0 -> Out=%b", $time, sipo_parallel_out);

        // Bit 1
        sipo_serial_in = 1;
        #20;
        $display("Time %0t: SIPO In=1 -> Out=%b", $time, sipo_parallel_out);

        // Bit 1 (LSB hien tai)
        sipo_serial_in = 1;
        #20;
        $display("Time %0t: SIPO In=1 -> Out=%b (Final Result)", $time, sipo_parallel_out);

        if (sipo_parallel_out == 4'b1011) 
            $display("-> SIPO PASSED (Output = 1011)");
        else 
            $display("-> SIPO FAILED");

        sipo_enable = 0; // Tat SIPO

        // ======================================================
        // TEST 2: PISO (Parallel In -> Serial Out)
        // Muc tieu: Nap song song 4'b1101 (Hex: D).
        // Ky vong output serial lan luot: 1 -> 1 -> 0 -> 1
        // (Do code ban lay MSB shift_reg[3] lam output)
        // ======================================================
        #50;
        $display("\n[TEST 2] PISO: Nạp song song 1101 (Decimal 13)");

        // Buoc 1: Load du lieu
        piso_data_in = 4'b1101;
        piso_load_en = 1; 
        piso_shift_en = 0; // Uu tien Load (theo case 2'b10)
        #20; // 1 clock de load
        
        $display("Time %0t: Loaded. Serial Out (MSB) should be 1. Actual: %b", $time, piso_serial_out);
        piso_load_en = 0; // Tat load

        // Buoc 2: Bat dau Shift (Dich trai << 1)
        piso_shift_en = 1;

        // Shift lan 1 (Da load 1101, dich trai -> 1010)
        // MSB cu la 1 da xuat, MSB moi la 1
        #20; 
        $display("Time %0t: Shift 1. Serial Out: %b", $time, piso_serial_out);

        // Shift lan 2 (Da co 1010, dich trai -> 0100)
        // MSB moi la 0
        #20;
        $display("Time %0t: Shift 2. Serial Out: %b", $time, piso_serial_out);

        // Shift lan 3 (Da co 0100, dich trai -> 1000)
        // MSB moi la 1
        #20;
        $display("Time %0t: Shift 3. Serial Out: %b", $time, piso_serial_out);

        piso_shift_en = 0;

        $display("-------------------------------------------------");
        $display(" KET THUC MO PHONG");
        $display("-------------------------------------------------");
        $stop;
    end

endmodule