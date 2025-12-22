module SIPO #(
    parameter DATA_WIDTH = 2
) (
    input wire clk,
    input wire enable,
    input wire serial_in,
    output wire [DATA_WIDTH-1:0] parallel_out
);
    reg [DATA_WIDTH-1:0] shift_reg;
    always @(posedge clk) begin
            if(enable) begin
            shift_reg <= {shift_reg[DATA_WIDTH-2:0], serial_in};
            end
        end
    assign parallel_out = shift_reg;
endmodule

module PISO #(
    parameter integer DATA_WIDTH = 2
) 
(
    input wire clk,              
    input wire load_en,            
    input wire shift_en,            
    input wire [DATA_WIDTH-1:0] data_in, 
    
    output wire serial_out    
);

    reg [DATA_WIDTH-1:0] shift_reg;
    assign serial_out = shift_reg[DATA_WIDTH-1]; 
    always @(posedge clk) begin
        case({load_en, shift_en})
        2'b01: shift_reg <= shift_reg << 1;
        2'b10: shift_reg <= data_in;
        default: shift_reg <= shift_reg;
        endcase
    end
endmodule