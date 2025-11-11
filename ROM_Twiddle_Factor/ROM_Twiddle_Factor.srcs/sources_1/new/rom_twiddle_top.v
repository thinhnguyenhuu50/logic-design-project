`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2025 04:39:27 PM
// Design Name: 
// Module Name: rom_twiddle_top
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


// ====================================================================
// Twiddle Factor Generator (IEEE-754 single precision float 32 bit)
// - N = 256
// - Lưu ROM 32-entry cho cos/sin trong vùng [0, π/4)
// - Phục hồi toàn bộ twiddle bằng symmetry / swap / sign-flip
// - Dùng module inv_uint (lật bit sign)
// ====================================================================

module rom_twiddle_top (
//    input  wire        clk,
    input  wire        en,
    input  wire [7:0]  tw_idx,        // chỉ số k (0..255)
    output reg  [63:0] tw_factor     // [63:32] -> image section, [31:0] realsection
);
    // ---------------- Tách địa chỉ ----------------
    wire [2:0] oct = tw_idx[7:5];     // 3 bit MSB → octant
    wire [4:0] off = tw_idx[4:0];     // 5 bit LSB → vị trí trong octant
    wire       boundary = (off == 5'd0);
    reg  [31:0] cos_out;       // real section
    reg  [31:0] sin_out;       // image section

    // ---------------- MUX địa chỉ ----------------
    wire [4:0] rom_addr;
    mux_addr MUXA (.oct_0(oct[0]), .off(off), .rom_addr(rom_addr));

    // ---------------- ROM ----------------
    wire [31:0] cos_rom, sin_rom;
    rom_twiddle ROM (
//         .clk(clk),
        .addr(rom_addr),
        .cos_q(cos_rom),
        .sin_q(sin_rom)
    );
    
    // ---------------- Invert -----------------
    wire [31:0] inv_cos_rom, inv_sin_rom;
    inv_uint INV_C (
        .in_val(cos_rom),
        .out_val(inv_cos_rom)
    );
    inv_uint INV_S (
        .in_val(sin_rom),
        .out_val(inv_sin_rom)
    );

    // ---------------- MUX output ----------------
    wire [31:0] cos_signed;
    wire [31:0] sin_signed;
    mux_output MUX0 (
        .cos_in(cos_rom),
        .sin_in(sin_rom),
        .inv_cos_in(inv_cos_rom),
        .inv_sin_in(inv_sin_rom),
        .oct(oct),
        
        .cos_out(cos_signed),
        .sin_out(sin_signed)
    );

    // ---------------- Giá trị biên (boundary) ----------------
    localparam [31:0] F_ONE = 32'h3F800000;   // +1.0
    localparam [31:0] F_ZERO = 32'h00000000;  //  0.0
    localparam [31:0] F_SQH = 32'h3F3504F3;   // +√2/2 ≈ 0.7071

    reg [31:0] c_bnd, s_bnd;
    always @* begin
        case (oct)
            3'd0: begin c_bnd= F_ONE;  s_bnd= F_ZERO; end
            3'd1: begin c_bnd= F_SQH;  s_bnd= F_SQH;  end
            3'd2: begin c_bnd= F_ZERO; s_bnd= F_ONE;  end
            3'd3: begin c_bnd={1'b1,F_SQH[30:0]}; s_bnd= F_SQH;  end
            3'd4: begin c_bnd={1'b1,F_ONE[30:0]}; s_bnd= F_ZERO; end
            3'd5: begin c_bnd={1'b1,F_SQH[30:0]}; s_bnd={1'b1,F_SQH[30:0]}; end
            3'd6: begin c_bnd= F_ZERO; s_bnd={1'b1,F_ONE[30:0]}; end
            default: begin c_bnd= F_SQH; s_bnd={1'b1,F_SQH[30:0]}; end
        endcase
    end

    // ---------------- Xuất kết quả ----------------
    always @(*) if (en) begin
        if (boundary) begin
            cos_out = c_bnd;
            sin_out = {~s_bnd[31], s_bnd[30:0]};  // sin → -sin
            tw_factor[63:32] = sin_out;
            tw_factor[31:0] = cos_out;
        end else begin
            cos_out = cos_signed;
            sin_out = sin_signed;
            tw_factor[63:32] = sin_out;
            tw_factor[31:0] = cos_out;
        end
    end
    
endmodule
