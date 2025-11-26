`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/23/2025 07:35:24 AM
// Design Name: 
// Module Name: FFT_Conv_Control
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ConvFFT_Control #(
    parameter integer N = 32,          // size mỗi chuỗi (power of 2)
    parameter integer M = 2            // số BMU song song (M | N/2)
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         start,

    // Điều khiển Temp_Conv_FFT
    output reg  [$clog2(2*N)-1:0]       addr_RAM1,
    output reg  [$clog2(2*N)-1:0]       addr_RAM2,
    output reg  [$clog2(N)-1:0]         addr_ROM,
    output reg                          enRAM1,
    output reg                          enRAM2,
    output reg                          enROM,
    output reg                          MUX_BMU,       // 0: DIF, 1: DIT
    output reg                          MUX_in,
    output reg                          MUX_out,
    output reg                          MUX_MPW,

    output reg                          done
);

    // ============================================================
    // Derive from parameters
    // ============================================================
    localparam LOGN     = $clog2(N);
    localparam LOGM     = $clog2(M);
    localparam RAMW     = $clog2(2*N);
    localparam ROMW     = $clog2(N);
    localparam RAMDEPTH = 2*N;
    localparam STEPMAX  = N/2 - 1;

    // ============================================================
    // FSM States
    // ============================================================
    localparam S_IDLE        = 4'd0;
    localparam S_LOAD        = 4'd1;
    localparam S_FFTX_READ   = 4'd2;
    localparam S_FFTX_WRITE  = 4'd3;
    localparam S_FFTH_READ   = 4'd4;
    localparam S_FFTH_WRITE  = 4'd5;
    localparam S_MPW_READ    = 4'd6;
    localparam S_MPW_WRITE   = 4'd7;
    localparam S_IFFT_READ   = 4'd8;
    localparam S_IFFT_WRITE  = 4'd9;
    localparam S_OUT         = 4'd10;
    localparam S_DONE        = 4'd11;

    reg [3:0] state;
    reg [3:0] next_state;

    // Counters
    reg [RAMW-1:0] load_cnt;
    reg [LOGN-1:0] stage_cnt;    // stage_cnt -> 0 to log2(N) - 1
    reg [LOGN:0]   step;         // step_cnt -> 0 to 15
    reg [LOGN:0]   k_cnt;
    reg [RAMW-1:0] seq_offset;   // offset để chọn X hay H

    // ============================================================
    // DIF / DIT Mode Detection
    // ============================================================
    wire dif_mode = (state == S_FFTX_READ)  ||
                    (state == S_FFTX_WRITE) ||
                    (state == S_FFTH_READ)  ||
                    (state == S_FFTH_WRITE);

    wire dit_mode = (state == S_IFFT_READ) ||
                    (state == S_IFFT_WRITE);

    // ============================================================
     //Address Generation Using STEP (step-based addressing)
     //============================================================

//    // ---------- DIF ----------
//    wire [LOGN-1:0] distance_DIF   = N >> (stage_cnt + 1);
//    wire [LOGN-1:0] group_size_DIF = distance_DIF << 1;
//    wire [LOGN-1:0] j_DIF          = step & (distance_DIF - 1);
//    wire [LOGN-1:0] group_DIF      = step >> $clog2(distance_DIF);
//    wire [LOGN-1:0] base_DIF       = group_DIF * group_size_DIF;
//    wire [ROMW-1:0] twiddle_DIF    = j_DIF << stage_cnt;

//    // ---------- DIT ----------
//    wire [LOGN-1:0] distance_DIT   = 1 << stage_cnt;
//    wire [LOGN-1:0] group_size_DIT = distance_DIT << 1;
//    wire [LOGN-1:0] j_DIT          = step & (distance_DIT - 1);
//    wire [LOGN-1:0] group_DIT      = step >> stage_cnt;
//    wire [LOGN-1:0] base_DIT       = group_DIT * group_size_DIT;
//    wire [ROMW-1:0] twiddle_DIT    = j_DIT << (LOGN - 1 - stage_cnt);

//    wire [LOGN-1:0] distance   = dif_mode ? distance_DIF   : distance_DIT;
//    wire [LOGN-1:0] group_size = dif_mode ? group_size_DIF : group_size_DIT;
//    wire [ROMW-1:0] twiddle_idx= dif_mode ? twiddle_DIF    : twiddle_DIT;

//    wire [RAMW-1:0] j_val      = dif_mode ? j_DIF : j_DIT;
//    wire [RAMW-1:0] base_val   = dif_mode ? base_DIF : base_DIT;

//    wire [RAMW-1:0] addr_a_next = seq_offset + base_val + j_val;
//    wire [RAMW-1:0] addr_b_next = seq_offset + base_val + j_val + distance;
wire [RAMW-1:0] addr_a_next;
wire [RAMW-1:0] addr_b_next;
wire [ROMW-1:0] twiddle_idx;
AddressFFT #(
N) GenAddr(
.step(step),
.state(state_cnt),
 .Mux1(!dif_mode),
 .Mux2(seq_offset[LOGN])
, .addr_RAM1(addr_a_next),
 .addr_RAM2(addr_b_next),
 .addr_ROM(twiddle_idx)
);
    // last of stage
    wire step_end = (step == STEPMAX);
    wire stg_last = (stage_cnt == LOGN - 1);
    wire last_butterfly = (step_end && stg_last);

    // ============================================================
    // FSM Register
    // ============================================================
    always @(posedge clk or negedge rst_n)
        if (!rst_n) state <= S_IDLE;
        else        state <= next_state;

    // ============================================================
    // FSM Next State
    // ============================================================
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:       if (start) next_state = S_LOAD;
            S_LOAD:       if (load_cnt == RAMDEPTH-1) next_state = S_FFTX_READ;

            S_FFTX_READ:  next_state = S_FFTX_WRITE;
            S_FFTX_WRITE: next_state = last_butterfly ? S_FFTH_READ : S_FFTX_READ;

            S_FFTH_READ:  next_state = S_FFTH_WRITE;
            S_FFTH_WRITE: next_state = last_butterfly ? S_MPW_READ : S_FFTH_READ;

            S_MPW_READ:   next_state = S_MPW_WRITE;
            S_MPW_WRITE:  next_state = (k_cnt == N-1 ? S_IFFT_READ : S_MPW_READ);

            S_IFFT_READ:  next_state = S_IFFT_WRITE;
            S_IFFT_WRITE: next_state = last_butterfly ? S_OUT : S_IFFT_READ;

            S_OUT:        if (k_cnt == N-1) next_state = S_DONE;
            S_DONE:       if (!start) next_state = S_IDLE;
        endcase
    end

    // ============================================================
    // Main Sequential Logic
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_cnt   <= 0;
            stage_cnt  <= 0;
            step       <= 0;
            k_cnt      <= 0;
            seq_offset <= 0;

            addr_RAM1  <= 0;
            addr_RAM2  <= 0;
            addr_ROM   <= 0;

            enRAM1 <= 0;
            enRAM2 <= 0;
            enROM  <= 0;
            MUX_in <= 0;
            MUX_out<= 0;
            MUX_MPW<= 0;
            MUX_BMU<= 0;

            done <= 0;

        end else begin

            // DEFAULTS
            // AUTO READ RAM
            enRAM1 <= 0;
            enRAM2 <= 0;
            
            enROM  <= 0;
            
            // AUTO READ FROM BUFFER BMU
            MUX_in <= 0;
            MUX_out<= 0;
            MUX_MPW<= 0;
            
            // AUTO DIF
            MUX_BMU<= 0;
            
            done <= 0;

            case (state)

            // -----------------------------------------------------
            // LOAD INPUT
            // -----------------------------------------------------
            S_LOAD: begin
                MUX_in    <= 1;
                enRAM1    <= 1;
                addr_RAM1 <= load_cnt;

                if (load_cnt < RAMDEPTH-1)
                    load_cnt <= load_cnt + 1;
                else begin
                // when load_cnt == RAMDEPTH-1 -> set up to read the first data from RAM
                    stage_cnt  <= 0;
                    step     <= 0;
                    seq_offset <= 0; // FFT X vùng 0..N-1
                end
            end

            // -----------------------------------------------------
            // FFT X - READ (DIF)
            // -----------------------------------------------------
            S_FFTX_READ: begin
                addr_RAM1 <= addr_a_next;
                addr_RAM2 <= addr_b_next;
                
                enROM     <= 1;
                addr_ROM  <= twiddle_idx;         
            end

            S_FFTX_WRITE: begin
                enRAM1 <= 1;
                enRAM2 <= 1;
                enROM <= 0;
                
                addr_RAM1 <= addr_a_next;
                addr_RAM2 <= addr_b_next;
                

                if (step_end) begin
                    step <= 0;
                    if (!stg_last)
                        stage_cnt <= stage_cnt + 1;
                end
                else begin
                    step <= step + 1; 
                end

                if (last_butterfly) begin // CHANGE STATE TO READ DATA H
                    stage_cnt  <= 0;
                    step       <= 0;
                    seq_offset <= N; // FFT H IN N..2N-1
                    k_cnt      <= 0;
                end                  
            end

            // -----------------------------------------------------
            // FFT H - READ (DIF)
            // -----------------------------------------------------
            S_FFTH_READ: begin
                addr_RAM1 <= addr_a_next;
                addr_RAM2 <= addr_b_next;
                
                enROM     <= 1;
                addr_ROM  <= twiddle_idx;  
            end

            S_FFTH_WRITE: begin
                enRAM1 <= 1;
                enRAM2 <= 1;
                enROM <= 0;
                
                addr_RAM1 <= addr_a_next;
                addr_RAM2 <= addr_b_next;
                
                if (step_end) begin
                    step <= 0;
                    if (!stg_last)
                        stage_cnt <= stage_cnt + 1;
                end
                else begin
                    step <= step + 1; 
                end

                if (last_butterfly) begin // CHANGE STATE TO READ DATA H
                    stage_cnt  <= 0;
                    step       <= 0;
                    seq_offset <= 0; // IFFT x IN 0..N-1
                    k_cnt      <= 0;
                end 
                   
            end

            // -----------------------------------------------------
            // POINTWISE MULTIPLY
            // -----------------------------------------------------
            S_MPW_READ: begin
                addr_RAM1 <= k_cnt;
                addr_RAM2 <= k_cnt + N;
            end

            S_MPW_WRITE: begin
                MUX_MPW <= 1;
                enRAM1  <= 1;

                addr_RAM1 <= k_cnt;

                if (k_cnt < N-1)
                    k_cnt <= k_cnt + 1;
                else begin
                    stage_cnt  <= 0;
                    step     <= 0;
                    seq_offset <= 0; // FFT X vùng 0..N-1              
                end
            end

            // -----------------------------------------------------
            // IFFT - READ (DIT)
            // -----------------------------------------------------
            S_IFFT_READ: begin
                addr_RAM1 <= addr_a_next;
                addr_RAM2 <= addr_b_next;
                
                enROM     <= 1;
                addr_ROM  <= twiddle_idx;
            end

            S_IFFT_WRITE: begin
                enRAM1 <= 1;
                enRAM2 <= 1;
                enROM <= 0;
                
                addr_RAM1 <= addr_a_next;
                addr_RAM2 <= addr_b_next;
                
                if (step_end) begin
                    step <= 0;
                    if (!stg_last)
                        stage_cnt <= stage_cnt + 1;
                end
                else begin
                    step <= step + 1; 
                end

                if (last_butterfly) begin // CHANGE STATE TO READ DATA H
                    stage_cnt  <= 0;
                    step       <= 0;
                    seq_offset <= 0;
                    k_cnt      <= 0;
                end
            end

            // -----------------------------------------------------
            // OUTPUT
            // -----------------------------------------------------
            S_OUT: begin
                MUX_out   <= 1;
                addr_RAM1 <= k_cnt;

                if (k_cnt < N-1)
                    k_cnt <= k_cnt + 1;
            end

            S_DONE:
                done <= 1;

            endcase
        end
    end

endmodule




