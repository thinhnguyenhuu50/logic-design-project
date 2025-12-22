`timescale 1ns / 1ps

module AddressFFT_tb;

    // --- 1. PARAMETER DECLARATION (N=32) ---
    parameter integer N = 32;
    localparam integer L = $clog2(N);    // L = 5 stages (0 to 4)
    localparam integer LL = $clog2(L);  // LL = 3
    localparam integer STEPS_PER_STAGE = N / 2; // 16 steps
    
    // --- 2. SIGNAL DECLARATION ---
    reg [L-2:0] step;    
    reg [LL-1:0] state;  
    reg Mux1;            
    reg Mux2;            
    
    // Outputs
    wire [L:0] addr_RAM1; 
    wire [L:0] addr_RAM2; 
    wire [L-1:0] addr_ROM;  
    
    // Biến đếm vòng lặp
    integer i; 
    integer j; 
    
    // --- 3. MODULE INSTANTIATION (DUT) ---
    // (Giả định module AddressFFT đã được sửa lỗi logic bên trong)
    AddressFFT #( .N(N) ) dut (
        .step(step),
        .state(state),
        .Mux1(Mux1),
        .Mux2(Mux2),
        .addr_RAM1(addr_RAM1),
        .addr_RAM2(addr_RAM2),
        .addr_ROM(addr_ROM)
    );
    
    // --- 4. INITIAL BLOCK (STIMULUS) ---
    initial begin
        // Khởi tạo trạng thái ban đầu
        step = 0; state = 0; Mux1 = 0; Mux2 = 0;
        
        $display("--------------------------------------------------------------------------------");
        $display("   Testbench Fixed (Explicit 5 Stages) N=%0d", N);
        $display("--------------------------------------------------------------------------------");
        $display(" Time | Mux1 | Mux2 | State | Step | AddrRAM1 (Dec) | AddrRAM2 (Dec) | AddrROM (Dec)");
        $display("--------------------------------------------------------------------------------");
        
        #5; // Trễ ổn định ban đầu

        // ====================================================================
        // === SCENARIO 1: DIT / FORWARD SWEEP (State 0 -> 4, Mux1=1) ===
        // ====================================================================
        Mux1 = 1; // DIT
        Mux2 = 0; // RAM Region 0 (N=32)
        
        // Vòng lặp cho Stages (i = 0 đến L-1)
        for (i = 0; i < L; i = i + 1) begin
            
            state = i; // GÁN TRỰC TIẾP STATE (0, 1, 2, 3, 4)
            #1; // Trễ để DUT nhận và ổn định State mới 
            
            $display("--- Running DIT Stage %0d (k=%0d) ---", i, i);
            
            // Vòng lặp cho Steps (j = 0 đến 15)
            for (j = 0; j < STEPS_PER_STAGE; j = j + 1) begin
                
                step = j; // GÁN TRỰC TIẾP STEP
                
                #1; // Trễ và ghi lại kết quả
                $strobe(" %04d |  %0d   |  %0d   |  %0d    | %04d |  %08d  |  %08d  |  %05d", 
                         $time, Mux1, Mux2, state, step, addr_RAM1, addr_RAM2, addr_ROM);
            end
        end

        #10; // Trễ giữa hai kịch bản

        // ====================================================================
        // === SCENARIO 2: DIF / REVERSE SWEEP (State 4 -> 0, Mux1=0) ===
        // ====================================================================
        Mux1 = 0; // DIF
        Mux2 = 1; // RAM Region 1 (N=32 to 63)
        
        // Vòng lặp ngược cho Stages (i = L-1 đến 0)
        for (i = L-1; i >= 0; i = i - 1) begin
            
            state = i; // GÁN TRỰC TIẾP STATE (4, 3, 2, 1, 0)
            #1; // Trễ để DUT nhận và ổn định State mới
            
            $display("--- Running DIF Stage %0d (k=%0d) ---", i, (L-1)-i);
            
            // Vòng lặp cho Steps (j = 0 đến 15)
            for (j = 0; j < STEPS_PER_STAGE; j = j + 1) begin
                
                step = j; // GÁN TRỰC TIẾT STEP
                
                #1; // Trễ và ghi lại kết quả
                $strobe(" %04d |  %0d   |  %0d   |  %0d    | %04d |  %08d  |  %08d  |  %05d", 
                         $time, Mux1, Mux2, state, step, addr_RAM1, addr_RAM2, addr_ROM);
            end
        end
        
        $display("\n--------------------------------------------------------------------------------");
        $display("Simulation finished. Check output for address progression across all stages.");
        $finish;
    end

endmodule